//! Layer / placement structural validation.
//!
//! Parses ECS_NODE/layer UCFX containers to find Transform components,
//! then validates position floats and quaternions to catch un-swapped
//! big-endian data that would overflow the engine's spatial hash table.
//!
//! Also validates `flgs` chunks containing vz_state placement records.

use crate::consume::ConsumeResult;
use mercs2_formats::ffcs::read_u32_le;
use mercs2_formats::ucfx::extract_chunk_body;
use mercs2_formats::world::{is_valid_position, is_valid_quaternion};

/// Hard-coded 42-byte Transform record stride (documented exception: schm reports 52).
const TRANSFORM_RECORD_STRIDE: usize = 42;

/// Minimum readable bytes through quaternion w at +0x20..+0x24.
const TRANSFORM_MIN_READABLE: usize = 0x24;

const FLGS_RECORD_STRIDE: usize = 42;

/// 1.0f in little-endian bytes (boot_float sentinel).
const ONE_F_LE: [u8; 4] = [0x00, 0x00, 0x80, 0x3F];

pub fn consume_layer(container: &[u8], data_body: Option<&[u8]>, label: &str) -> ConsumeResult {
    let flgs_body = extract_chunk_body(container, b"flgs");
    let has_flgs = flgs_body.is_some();
    let has_data = data_body.is_some() || extract_chunk_body(container, b"data").is_some();

    let mut issues = Vec::new();
    let mut placements_validated = 0usize;
    let mut flgs_placements_validated = 0usize;
    let mut structural_violations = 0u32;

    if let Some(results) = validate_transform_components(container, label) {
        for r in results {
            placements_validated += r.records_checked;
            issues.extend(r.issues);
        }
    }

    // P2-10: ECS string component printable ASCII check
    structural_violations += validate_string_components(container, label, &mut issues);

    if let Some(ref flgs) = flgs_body {
        let flgs_result = validate_flgs_placements(flgs, label);
        flgs_placements_validated += flgs_result.records_checked;
        issues.extend(flgs_result.issues);
    }

    ConsumeResult {
        consumed: has_flgs || has_data || placements_validated > 0 || flgs_placements_validated > 0,
        issues,
        placements_validated,
        flgs_placements_validated,
        structural_violations,
        ..Default::default()
    }
}

struct ComponentValidation {
    records_checked: usize,
    issues: Vec<String>,
}

/// Walk the UCFX descriptor table to find COMP groups and validate Transforms.
fn validate_transform_components(container: &[u8], label: &str) -> Option<Vec<ComponentValidation>> {
    if container.len() < 20 || &container[0..4] != b"UCFX" {
        return None;
    }
    let data_area_off = read_u32_le(container, 4) as usize;
    let n_desc = read_u32_le(container, 16) as usize;
    let max_desc = container.len().saturating_sub(20) / 20;
    if n_desc > max_desc || n_desc == 0 {
        return None;
    }

    let mut results = Vec::new();

    let mut i = 0;
    while i < n_desc {
        let row_off = 20 + i * 20;
        if row_off + 20 > container.len() {
            break;
        }
        let tag = &container[row_off..row_off + 4];
        let row_offset = read_u32_le(container, row_off + 4);

        if tag == b"COMP" && row_offset == 0xFFFF_FFFF {
            if let Some(val) = try_validate_comp_group(container, data_area_off, n_desc, i + 1, label) {
                results.push(val);
            }
        }
        i += 1;
    }

    if results.is_empty() {
        None
    } else {
        Some(results)
    }
}

/// Attempt to parse info/data children of a COMP group starting at `start_idx`.
fn try_validate_comp_group(
    container: &[u8],
    data_area_off: usize,
    n_desc: usize,
    start_idx: usize,
    label: &str,
) -> Option<ComponentValidation> {
    let mut info_body: Option<&[u8]> = None;
    let mut data_body: Option<&[u8]> = None;

    let end = (start_idx + 6).min(n_desc);
    for j in start_idx..end {
        let row_off = 20 + j * 20;
        if row_off + 20 > container.len() {
            break;
        }
        let tag = &container[row_off..row_off + 4];
        let row_u0 = read_u32_le(container, row_off + 4);

        if tag == b"COMP" {
            break;
        }

        if row_u0 == 0xFFFF_FFFF {
            continue;
        }
        let row_u0 = row_u0 as usize;
        let body_size = read_u32_le(container, row_off + 8) as usize;
        let body_start = if data_area_off > 0 {
            data_area_off + row_u0
        } else {
            8 + row_u0
        };
        let body_end = body_start + body_size;
        if body_end > container.len() {
            continue;
        }

        let body = &container[body_start..body_end];
        match tag {
            b"info" => info_body = Some(body),
            b"data" => data_body = Some(body),
            _ => {}
        }
    }

    let info = info_body?;
    let data = data_body?;

    let comp_name = extract_null_terminated_str(info);
    if !is_transform_component(&comp_name) {
        return None;
    }

    let stride = TRANSFORM_RECORD_STRIDE;
    if data.len() < stride {
        return None;
    }

    let record_count = data.len() / stride;
    let mut issues = Vec::new();
    let mut records_checked = 0usize;

    for rec_idx in 0..record_count {
        let rec_off = rec_idx * stride;
        if rec_off + TRANSFORM_MIN_READABLE > data.len() {
            break;
        }

        let x = f32::from_le_bytes(data[rec_off + 4..rec_off + 8].try_into().unwrap());
        let y = f32::from_le_bytes(data[rec_off + 8..rec_off + 12].try_into().unwrap());
        let z = f32::from_le_bytes(data[rec_off + 12..rec_off + 16].try_into().unwrap());

        let qx = f32::from_le_bytes(data[rec_off + 0x14..rec_off + 0x18].try_into().unwrap());
        let qy = f32::from_le_bytes(data[rec_off + 0x18..rec_off + 0x1C].try_into().unwrap());
        let qz = f32::from_le_bytes(data[rec_off + 0x1C..rec_off + 0x20].try_into().unwrap());
        let qw = f32::from_le_bytes(data[rec_off + 0x20..rec_off + 0x24].try_into().unwrap());

        records_checked += 1;

        if !x.is_finite() || !y.is_finite() || !z.is_finite() || !is_valid_position(x, y, z) {
            let detail = if !x.is_finite() || !y.is_finite() || !z.is_finite() {
                format!(
                    "{label}: Transform[{rec_idx}] \"{comp_name}\" position NaN/Inf: ({x}, {y}, {z}) — \
                     would overflow cvttss2si → spatial hash corruption"
                )
            } else {
                format!(
                    "{label}: Transform[{rec_idx}] \"{comp_name}\" position out of world bounds: ({x}, {y}, {z})"
                )
            };
            issues.push(detail);
        }

        if !is_valid_quaternion(qx, qy, qz, qw) {
            let mag_sq = qx * qx + qy * qy + qz * qz + qw * qw;
            let detail = if !qx.is_finite() || !qy.is_finite() || !qz.is_finite() || !qw.is_finite() {
                format!(
                    "{label}: Transform[{rec_idx}] \"{comp_name}\" quaternion NaN/Inf: ({qx}, {qy}, {qz}, {qw})"
                )
            } else {
                format!(
                    "{label}: Transform[{rec_idx}] \"{comp_name}\" quaternion not unit: ({qx}, {qy}, {qz}, {qw}) mag²={mag_sq:.4}"
                )
            };
            issues.push(detail);
        }
    }

    Some(ComponentValidation {
        records_checked,
        issues,
    })
}

/// Validate flgs vz_state placement records (42 bytes each).
fn validate_flgs_placements(flgs: &[u8], label: &str) -> ComponentValidation {
    let mut issues = Vec::new();
    let mut records_checked = 0usize;

    let start = match find_bytes(flgs, &ONE_F_LE) {
        Some(off) if off >= 4 => off - 4,
        _ => return ComponentValidation { records_checked: 0, issues },
    };

    let remaining = &flgs[start..];
    let record_count = remaining.len() / FLGS_RECORD_STRIDE;

    for rec_idx in 0..record_count {
        let rec_off = rec_idx * FLGS_RECORD_STRIDE;
        if rec_off + FLGS_RECORD_STRIDE > remaining.len() {
            break;
        }
        let rec = &remaining[rec_off..];

        let px = f32::from_le_bytes(rec[0x12..0x16].try_into().unwrap());
        let py = f32::from_le_bytes(rec[0x16..0x1A].try_into().unwrap());
        let pz = f32::from_le_bytes(rec[0x1A..0x1E].try_into().unwrap());

        if px == 0.0 && py == 0.0 && pz == 0.0 {
            continue;
        }

        let r0 = f32::from_le_bytes(rec[0x1E..0x22].try_into().unwrap());
        let r1 = f32::from_le_bytes(rec[0x22..0x26].try_into().unwrap());
        let ry = f32::from_le_bytes(rec[0x26..0x2A].try_into().unwrap());

        records_checked += 1;

        if !px.is_finite() || !py.is_finite() || !pz.is_finite() || !is_valid_position(px, py, pz) {
            if !px.is_finite() || !py.is_finite() || !pz.is_finite() {
                issues.push(format!(
                    "{label}: flgs[{rec_idx}] position NaN/Inf: ({px}, {py}, {pz})"
                ));
            } else {
                issues.push(format!(
                    "{label}: flgs[{rec_idx}] position out of world bounds: ({px}, {py}, {pz})"
                ));
            }
        }

        for (name, val) in [("rotation_0", r0), ("rotation_1", r1), ("rotation_y_sin", ry)] {
            if !val.is_finite() {
                issues.push(format!(
                    "{label}: flgs[{rec_idx}] {name} NaN/Inf: {val}"
                ));
            } else if val.abs() > 1.0 {
                issues.push(format!(
                    "{label}: flgs[{rec_idx}] {name} out of range: {val} (expected |v| <= 1.0)"
                ));
            }
        }
    }

    ComponentValidation { records_checked, issues }
}

fn find_bytes(haystack: &[u8], needle: &[u8]) -> Option<usize> {
    haystack.windows(needle.len()).position(|w| w == needle)
}

fn extract_null_terminated_str(data: &[u8]) -> String {
    let end = data.iter().position(|&b| b == 0).unwrap_or(data.len());
    String::from_utf8_lossy(&data[..end]).to_string()
}

fn is_transform_component(name: &str) -> bool {
    let lower = name.to_ascii_lowercase();
    lower == "transform"
        || lower.starts_with("transform")
        || lower.contains("position")
        || lower.contains("placement")
}

/// P2-10: Validate ECS string component bodies contain only printable ASCII.
/// Returns the number of structural violations found.
fn validate_string_components(container: &[u8], label: &str, issues: &mut Vec<String>) -> u32 {
    if container.len() < 20 || &container[0..4] != b"UCFX" {
        return 0;
    }
    let data_area_off = read_u32_le(container, 4) as usize;
    let n_desc = read_u32_le(container, 16) as usize;
    let max_desc = container.len().saturating_sub(20) / 20;
    if n_desc > max_desc || n_desc == 0 {
        return 0;
    }

    let mut violations = 0u32;
    let mut i = 0;
    while i < n_desc {
        let row_off = 20 + i * 20;
        if row_off + 20 > container.len() {
            break;
        }
        let tag = &container[row_off..row_off + 4];
        let row_offset = read_u32_le(container, row_off + 4);

        if tag == b"COMP" && row_offset == 0xFFFF_FFFF {
            if let Some(v) = check_string_comp_group(container, data_area_off, n_desc, i + 1, label, issues) {
                violations += v;
            }
        }
        i += 1;
    }
    violations
}

fn check_string_comp_group(
    container: &[u8],
    data_area_off: usize,
    n_desc: usize,
    start_idx: usize,
    label: &str,
    issues: &mut Vec<String>,
) -> Option<u32> {
    let mut info_body: Option<&[u8]> = None;
    let mut data_body: Option<&[u8]> = None;

    let end = (start_idx + 6).min(n_desc);
    for j in start_idx..end {
        let row_off = 20 + j * 20;
        if row_off + 20 > container.len() {
            break;
        }
        let tag = &container[row_off..row_off + 4];
        let row_u0 = read_u32_le(container, row_off + 4);

        if tag == b"COMP" {
            break;
        }
        if row_u0 == 0xFFFF_FFFF {
            continue;
        }
        let row_u0 = row_u0 as usize;
        let body_size = read_u32_le(container, row_off + 8) as usize;
        let body_start = if data_area_off > 0 {
            data_area_off + row_u0
        } else {
            8 + row_u0
        };
        let body_end = body_start + body_size;
        if body_end > container.len() {
            continue;
        }

        let body = &container[body_start..body_end];
        match tag {
            b"info" => info_body = Some(body),
            b"data" => data_body = Some(body),
            _ => {}
        }
    }

    let info = info_body?;
    let data = data_body?;

    let comp_name = extract_null_terminated_str(info);
    if !is_string_component(&comp_name) {
        return None;
    }

    let non_printable = data
        .iter()
        .filter(|&&b| b != 0x00 && !(0x20..=0x7E).contains(&b))
        .count();
    if non_printable > 0 {
        issues.push(format!(
            "{label}: ECS \"{comp_name}\" has {non_printable} non-printable bytes (byte-swap corruption?)"
        ));
        Some(1)
    } else {
        None
    }
}

fn is_string_component(name: &str) -> bool {
    name == "Name" || name == "ModelName"
}

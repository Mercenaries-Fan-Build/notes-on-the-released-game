//! Layer / placement structural validation.
//!
//! Parses ECS_NODE/layer UCFX containers to find Transform components,
//! then validates position floats and quaternions to catch un-swapped
//! big-endian data that would overflow the engine's spatial hash table.

use crate::consume::ConsumeResult;
use crate::ffcs::read_u32_le;
use crate::ucfx::extract_chunk_body;
use crate::world::{is_valid_position, is_valid_quaternion};

/// Minimum bytes for a Transform record (3 floats pos + 4 floats quat).
const TRANSFORM_MIN_STRIDE: usize = 28;

pub fn consume_layer(container: &[u8], data_body: Option<&[u8]>, label: &str) -> ConsumeResult {
    let has_flgs = extract_chunk_body(container, b"flgs").is_some();
    let has_data = data_body.is_some() || extract_chunk_body(container, b"data").is_some();

    let mut issues = Vec::new();
    let mut placements_validated = 0usize;

    // Walk UCFX descriptor table looking for COMP → info → schm → data triplets
    if let Some(results) = validate_transform_components(container, label) {
        for r in results {
            placements_validated += r.records_checked;
            issues.extend(r.issues);
        }
    }

    ConsumeResult {
        consumed: has_flgs || has_data || placements_validated > 0,
        issues,
        placements_validated,
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

    // Scan for COMP → info → schm → data pattern.
    // COMP descriptor has offset 0xFFFFFFFF (group header), followed by
    // info/schm/data child descriptors.
    let mut i = 0;
    while i < n_desc {
        let row_off = 20 + i * 20;
        if row_off + 20 > container.len() {
            break;
        }
        let tag = &container[row_off..row_off + 4];
        let row_offset = read_u32_le(container, row_off + 4);

        // COMP group header has offset 0xFFFFFFFF
        if tag == b"COMP" && row_offset == 0xFFFF_FFFF {
            // Look for info, schm, data children following this COMP
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

/// Attempt to parse info/schm/data children of a COMP group starting at `start_idx`.
fn try_validate_comp_group(
    container: &[u8],
    data_area_off: usize,
    n_desc: usize,
    start_idx: usize,
    label: &str,
) -> Option<ComponentValidation> {
    let mut info_body: Option<&[u8]> = None;
    let mut schm_body: Option<&[u8]> = None;
    let mut data_body: Option<&[u8]> = None;

    // Scan up to 6 children (info, schm, data, possibly others)
    let end = (start_idx + 6).min(n_desc);
    for j in start_idx..end {
        let row_off = 20 + j * 20;
        if row_off + 20 > container.len() {
            break;
        }
        let tag = &container[row_off..row_off + 4];
        let row_u0 = read_u32_le(container, row_off + 4);

        // Stop if we hit another COMP (next group)
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
            b"schm" => schm_body = Some(body),
            b"data" => data_body = Some(body),
            _ => {}
        }
    }

    // We need at least info + data to validate
    let info = info_body?;
    let data = data_body?;

    // info body starts with a null-terminated component name
    let comp_name = extract_null_terminated_str(info);
    if !is_transform_component(&comp_name) {
        return None;
    }

    // Determine record stride from schm or fall back to minimum
    let stride = if let Some(schm) = schm_body {
        determine_stride_from_schm(schm)
    } else {
        TRANSFORM_MIN_STRIDE
    };

    if stride < TRANSFORM_MIN_STRIDE || data.is_empty() {
        return None;
    }

    let record_count = data.len() / stride;
    let mut issues = Vec::new();
    let mut records_checked = 0usize;

    for rec_idx in 0..record_count {
        let rec_off = rec_idx * stride;
        if rec_off + TRANSFORM_MIN_STRIDE > data.len() {
            break;
        }

        let x = f32::from_le_bytes(data[rec_off..rec_off + 4].try_into().unwrap());
        let y = f32::from_le_bytes(data[rec_off + 4..rec_off + 8].try_into().unwrap());
        let z = f32::from_le_bytes(data[rec_off + 8..rec_off + 12].try_into().unwrap());

        let qx = f32::from_le_bytes(data[rec_off + 12..rec_off + 16].try_into().unwrap());
        let qy = f32::from_le_bytes(data[rec_off + 16..rec_off + 20].try_into().unwrap());
        let qz = f32::from_le_bytes(data[rec_off + 20..rec_off + 24].try_into().unwrap());
        let qw = f32::from_le_bytes(data[rec_off + 24..rec_off + 28].try_into().unwrap());

        records_checked += 1;

        if !is_valid_position(x, y, z) {
            let detail = if x.is_nan() || y.is_nan() || z.is_nan()
                || x.is_infinite() || y.is_infinite() || z.is_infinite()
            {
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

/// Extract record stride from schm body.
/// The schm typically has: field_count(u32), then per-field entries describing
/// offset/type. The total stride is derivable, but as a heuristic we look for
/// common patterns or fall back to scanning the data.
fn determine_stride_from_schm(schm: &[u8]) -> usize {
    if schm.len() < 4 {
        return TRANSFORM_MIN_STRIDE;
    }
    // Common layout: first u32 is field count, then field descriptors.
    // For a Transform component with pos(3f) + quat(4f) = 28 bytes minimum.
    // Some have additional scale(3f) = 40 bytes, or flags.
    // Try to read the stride from the last field offset + size if available.
    //
    // Heuristic: if schm has >= 8 bytes, try reading the second u32 as stride.
    // Many ECS containers store stride at schm+4.
    if schm.len() >= 8 {
        let candidate = read_u32_le(schm, 4) as usize;
        if candidate >= TRANSFORM_MIN_STRIDE && candidate <= 256 {
            return candidate;
        }
    }
    // Another pattern: total_size at offset 0
    let candidate = read_u32_le(schm, 0) as usize;
    if candidate >= TRANSFORM_MIN_STRIDE && candidate <= 256 {
        return candidate;
    }
    TRANSFORM_MIN_STRIDE
}

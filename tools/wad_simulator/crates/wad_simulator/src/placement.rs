//! Layer / placement structural validation.
//!
//! Parses ECS_NODE/layer UCFX containers to find Transform components,
//! then validates position floats and quaternions to catch un-swapped
//! big-endian data that would overflow the engine's spatial hash table.
//!
//! Also validates `flgs` chunks containing vz_state placement records.

use crate::consume::ConsumeResult;
use mercs2_formats::ffcs::read_u32_le;
use mercs2_formats::schema::{ComponentSchema, SchemaFieldType};
use mercs2_formats::ucfx::extract_chunk_body;
use mercs2_formats::world::{is_valid_position, is_valid_quaternion};

/// Hard-coded 42-byte Transform record stride (documented exception: schm reports 52).
const TRANSFORM_RECORD_STRIDE: usize = 42;

/// Minimum readable bytes through quaternion w at +0x20..+0x24.
const TRANSFORM_MIN_READABLE: usize = 0x24;

const FLGS_RECORD_STRIDE: usize = 42;

/// Compact-format `info` bodies use this hash instead of an ASCII name.
const TRANSFORM_COMP_HASH: u32 = 0x753E_B623;

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
    let mut ecs_float_violations = 0usize;
    // Advisory (NON-fatal): flgs uses a heuristic 42-byte stride guess.
    let mut position_advisory = 0usize;

    if let Some(results) = validate_transform_components(container, label) {
        for r in results {
            placements_validated += r.records_checked;
            issues.extend(r.issues);
        }
    }

    // Schema-driven float/position scan across ALL components with a schm
    // (the spatial-hash crash source — positions feed an unclamped cell index).
    let schema_scan = validate_ecs_component_schemas(container, label);
    placements_validated += schema_scan.records_checked;
    ecs_float_violations += schema_scan.violations;
    issues.extend(schema_scan.issues);

    // P2-10: ECS string component printable ASCII check
    structural_violations += validate_string_components(container, label, &mut issues);

    // CHDR stride-gate check (decompile-grounded, spatial_hash_crash_analysis §2026-06-01b):
    // engine dispatcher 0x654940 reads CHDR as {u16 fieldA; u16 stride@+2; u32 flags},
    // writes u16@+2 to [0x01176078]; Transform builder 0x0063D7C0 strides 42 iff that
    // gate >= 0x2A, else 40 → 2-byte/record drift → spatial-hash AV 0x0248BBE2. Retail
    // oracle gate = 0x38 (56); a CHDR header swapped as u32 zeroes it. Verified clean on
    // retail vz.wad (0 hits) → fatal, not advisory.
    structural_violations += check_chdr_stride_gate(container, label, &mut issues);

    // Buffer-too-small: a texture EMBEDDED in this layer container (uppercase
    // INFO/BODY) never gets its own consume_texture dispatch, so check it here.
    // Headline signal — routed to texture_buffer_issues, NOT structural_violations.
    let (texture_buffer_issues, _) =
        crate::texture::check_embedded_texture_buffers(container, label);

    if let Some(ref flgs) = flgs_body {
        let flgs_result = validate_flgs_placements(flgs, label);
        flgs_placements_validated += flgs_result.records_checked;
        // flgs violations are advisory (heuristic stride); the simulate.rs matcher
        // only counts `Transform[...]` strings toward fatal position_violations.
        position_advisory += flgs_result.issues.len();
        issues.extend(flgs_result.issues);
    }

    ConsumeResult {
        consumed: has_flgs || has_data || placements_validated > 0 || flgs_placements_validated > 0,
        issues,
        placements_validated,
        flgs_placements_validated,
        structural_violations,
        ecs_float_violations,
        texture_buffer_issues,
        position_advisory,
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

    if !is_transform_info(info) {
        return None;
    }
    let comp_name = extract_component_name(info);

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

/// Result of the schema-driven ECS float/position scan.
struct SchemaScan {
    records_checked: usize,
    violations: usize,
    issues: Vec<String>,
}

/// Coordinate magnitude that is unambiguously byte-swap garbage for any float
/// field (legit scales/velocities/normals never approach this). Used for
/// non-Transform `Vec3` fields where we can't be sure the field is a world
/// position, to keep false positives near zero.
const ABSURD_COORD: f32 = 1.0e6;

/// Max issue lines emitted per component (violations are still fully counted).
const MAX_ISSUES_PER_COMP: usize = 6;

/// Schema-driven scan: walk every COMP group's info/schm/data triplet, parse the
/// `schm` field layout, and validate float fields across all records. This catches
/// position-bearing components the name-matched Transform heuristic skips — the
/// likely source of the unclamped garbage cell index in the spatial-hash crash.
///
/// - Any float (`F32`/`Vec3`/`Blob32`) that is NaN/Inf → byte-swap corruption.
/// - `Blob32` (Transform pos+quat blob): position bounds + quaternion unit check.
/// - `Vec3`: flagged only when a component is clearly corrupt (NaN/Inf or |coord|
///   beyond `ABSURD_COORD`) to avoid mislabeling scale/velocity vectors.
fn validate_ecs_component_schemas(container: &[u8], label: &str) -> SchemaScan {
    let mut scan = SchemaScan {
        records_checked: 0,
        violations: 0,
        issues: Vec::new(),
    };
    if container.len() < 20 || &container[0..4] != b"UCFX" {
        return scan;
    }
    let data_area_off = read_u32_le(container, 4) as usize;
    let n_desc = read_u32_le(container, 16) as usize;
    let max_desc = container.len().saturating_sub(20) / 20;
    if n_desc == 0 || n_desc > max_desc {
        return scan;
    }

    let mut i = 0;
    while i < n_desc {
        let row_off = 20 + i * 20;
        if row_off + 20 > container.len() {
            break;
        }
        let tag = &container[row_off..row_off + 4];
        let row_offset = read_u32_le(container, row_off + 4);
        if tag == b"COMP" && row_offset == 0xFFFF_FFFF {
            scan_comp_group_schema(container, data_area_off, n_desc, i + 1, label, &mut scan);
        }
        i += 1;
    }
    scan
}

/// Collect the info/schm/data triplet for one COMP group and validate its floats.
fn scan_comp_group_schema(
    container: &[u8],
    data_area_off: usize,
    n_desc: usize,
    start_idx: usize,
    label: &str,
    scan: &mut SchemaScan,
) {
    let mut info_body: Option<&[u8]> = None;
    let mut schm_body: Option<&[u8]> = None;
    let mut data_body: Option<&[u8]> = None;

    let end = (start_idx + 8).min(n_desc);
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
        let body_size = read_u32_le(container, row_off + 8) as usize;
        let body_start = if data_area_off > 0 {
            data_area_off + row_u0 as usize
        } else {
            8 + row_u0 as usize
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

    let (info, schm, data) = match (info_body, schm_body, data_body) {
        (Some(i), Some(s), Some(d)) => (i, s, d),
        _ => return,
    };

    let comp_name = extract_component_name(info);
    // Transform is covered by validate_transform_components (42-byte special case).
    if comp_name.eq_ignore_ascii_case("transform") {
        return;
    }

    // Validator runs on converted LE blocks → parse schema little-endian.
    let schema = match ComponentSchema::from_schm_body(schm, false) {
        Some(s) => s,
        None => return,
    };
    // Record = 4-byte entity key + payload (docs/ecs_components.md).
    let stride = 4 + schema.payload_stride as usize;
    if stride <= 4 || stride > data.len() {
        return;
    }
    let record_count = (data.len() / stride).min(200_000);

    let mut comp_issue_count = 0usize;
    for rec_idx in 0..record_count {
        let payload = rec_idx * stride + 4;
        for field in &schema.fields {
            let off = payload + field.byte_offset as usize;
            match field.field_type {
                SchemaFieldType::F32 => {
                    if let Some(v) = read_f32_le(data, off) {
                        if !v.is_finite() {
                            scan.violations += 1;
                            push_capped(&mut scan.issues, &mut comp_issue_count, format!(
                                "{label}: ECS \"{comp_name}\" field+0x{:X} record[{rec_idx}] float NaN/Inf: {v}",
                                field.byte_offset
                            ));
                        }
                    }
                }
                SchemaFieldType::Vec3 => {
                    if let (Some(x), Some(y), Some(z)) = (
                        read_f32_le(data, off),
                        read_f32_le(data, off + 4),
                        read_f32_le(data, off + 8),
                    ) {
                        let non_finite = !x.is_finite() || !y.is_finite() || !z.is_finite();
                        let absurd = x.abs() > ABSURD_COORD
                            || y.abs() > ABSURD_COORD
                            || z.abs() > ABSURD_COORD;
                        if non_finite || absurd {
                            scan.violations += 1;
                            let kind = if non_finite { "position NaN/Inf" } else { "position out of world bounds" };
                            push_capped(&mut scan.issues, &mut comp_issue_count, format!(
                                "{label}: ECS \"{comp_name}\" Vec3+0x{:X} record[{rec_idx}] {kind}: ({x}, {y}, {z}) — \
                                 unclamped cell index → spatial hash corruption",
                                field.byte_offset
                            ));
                        }
                    }
                }
                SchemaFieldType::Blob32 => {
                    // pos(3) + pad(1) + quat(4) — same layout as Transform.
                    if let (Some(x), Some(y), Some(z)) = (
                        read_f32_le(data, off),
                        read_f32_le(data, off + 4),
                        read_f32_le(data, off + 8),
                    ) {
                        if !x.is_finite() || !y.is_finite() || !z.is_finite() {
                            scan.violations += 1;
                            push_capped(&mut scan.issues, &mut comp_issue_count, format!(
                                "{label}: ECS \"{comp_name}\" Blob32+0x{:X} record[{rec_idx}] position NaN/Inf: ({x}, {y}, {z})",
                                field.byte_offset
                            ));
                        } else if !is_valid_position(x, y, z) {
                            scan.violations += 1;
                            push_capped(&mut scan.issues, &mut comp_issue_count, format!(
                                "{label}: ECS \"{comp_name}\" Blob32+0x{:X} record[{rec_idx}] position out of world bounds: ({x}, {y}, {z})",
                                field.byte_offset
                            ));
                        }
                    }
                    if let (Some(qx), Some(qy), Some(qz), Some(qw)) = (
                        read_f32_le(data, off + 16),
                        read_f32_le(data, off + 20),
                        read_f32_le(data, off + 24),
                        read_f32_le(data, off + 28),
                    ) {
                        if !is_valid_quaternion(qx, qy, qz, qw) {
                            scan.violations += 1;
                            let kind = if !qx.is_finite() || !qy.is_finite() || !qz.is_finite() || !qw.is_finite() {
                                "quaternion NaN/Inf"
                            } else {
                                "quaternion not unit"
                            };
                            push_capped(&mut scan.issues, &mut comp_issue_count, format!(
                                "{label}: ECS \"{comp_name}\" Blob32+0x{:X} record[{rec_idx}] {kind}: ({qx}, {qy}, {qz}, {qw})",
                                field.byte_offset
                            ));
                        }
                    }
                }
                _ => {}
            }
        }
        scan.records_checked += 1;
    }
}

fn read_f32_le(data: &[u8], off: usize) -> Option<f32> {
    data.get(off..off + 4)
        .map(|b| f32::from_le_bytes([b[0], b[1], b[2], b[3]]))
}

fn push_capped(issues: &mut Vec<String>, count: &mut usize, msg: String) {
    if *count < MAX_ISSUES_PER_COMP {
        issues.push(msg);
    } else if *count == MAX_ISSUES_PER_COMP {
        issues.push("    (… additional violations in this component suppressed)".to_string());
    }
    *count += 1;
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

fn extract_component_name(info: &[u8]) -> String {
    let nul = info.iter().position(|&b| b == 0).unwrap_or(info.len());
    let candidate = &info[..nul];
    if !candidate.is_empty() && candidate.iter().all(|&b| (32..=126).contains(&b)) {
        return String::from_utf8_lossy(candidate).to_string();
    }
    if info.len() >= 4 {
        let hash = read_u32_le(info, 0);
        if hash == TRANSFORM_COMP_HASH {
            return "Transform".to_string();
        }
        return format!("__hash_0x{hash:08X}");
    }
    extract_null_terminated_str(info)
}

fn is_transform_info(info: &[u8]) -> bool {
    let name = extract_component_name(info);
    is_transform_component(&name)
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

/// CHDR stride-gate: the engine reads u16@+2 of the CHDR body as the Transform
/// stride gate (>= 0x2A → 42, else 40). A gate < 0x2A drifts every Transform
/// record by 2 bytes → spatial-hash AV. Only meaningful when the container holds
/// a Transform COMP (the only consumer of the gate). Returns 1 on violation.
fn check_chdr_stride_gate(container: &[u8], label: &str, issues: &mut Vec<String>) -> u32 {
    let chdr = match extract_chunk_body(container, b"CHDR") {
        Some(b) if b.len() >= 4 => b,
        _ => return 0,
    };
    // Engine reads u16 @ +2 → process-global stride gate [0x01176078].
    let gate = u16::from_le_bytes([chdr[2], chdr[3]]);
    if gate >= 0x2A {
        return 0;
    }
    // Gate only matters if a Transform COMP is present in this container.
    if validate_transform_components(container, label).is_none() {
        return 0;
    }
    issues.push(format!(
        "{label}: CHDR stride gate u16@+2={gate} < 0x2A — engine strides Transform 40 not 42 \
         → 2-byte/record drift → spatial-hash AV 0x0248BBE2 (CHDR header swapped as u32?)"
    ));
    1
}

#[cfg(test)]
mod chdr_gate_tests {
    use super::*;

    /// Build a minimal ECS UCFX container with a CHDR chunk (given body) and a
    /// Transform COMP group, so `check_chdr_stride_gate` has both inputs.
    fn container_with_chdr(chdr_body: &[u8]) -> Vec<u8> {
        // Transform info: the compact-form hash 0x753EB623 marks a Transform COMP.
        let info: [u8; 4] = TRANSFORM_COMP_HASH.to_le_bytes();
        // One 42-byte Transform data record (zeros decode as origin — valid enough).
        let data = [0u8; 42];

        let n_desc: u32 = 4; // CHDR, COMP(sentinel), info, data
        let header = 20usize;
        let table = n_desc as usize * 20;
        let data_area_off = (header + table) as u32;

        let mut bodies = Vec::new();
        let chdr_off = bodies.len() as u32;
        bodies.extend_from_slice(chdr_body);
        let info_off = bodies.len() as u32;
        bodies.extend_from_slice(&info);
        let data_off = bodies.len() as u32;
        bodies.extend_from_slice(&data);

        let mut c = Vec::new();
        c.extend_from_slice(b"UCFX");
        c.extend_from_slice(&data_area_off.to_le_bytes()); // +4 data_area_off
        c.extend_from_slice(&[0u8; 8]); // +8..16 pad
        c.extend_from_slice(&n_desc.to_le_bytes()); // +16 n_desc
        let row = |tag: &[u8], off: u32, size: u32| {
            let mut r = Vec::new();
            r.extend_from_slice(tag);
            r.extend_from_slice(&off.to_le_bytes());
            r.extend_from_slice(&size.to_le_bytes());
            r.extend_from_slice(&[0u8; 8]);
            r
        };
        c.extend_from_slice(&row(b"CHDR", chdr_off, chdr_body.len() as u32));
        c.extend_from_slice(&row(b"COMP", 0xFFFF_FFFF, 0)); // group sentinel
        c.extend_from_slice(&row(b"info", info_off, info.len() as u32));
        c.extend_from_slice(&row(b"data", data_off, data.len() as u32));
        c.extend_from_slice(&bodies);
        c
    }

    #[test]
    fn retail_oracle_gate_passes() {
        // Retail layers_static block 29 CHDR = 00 00 38 00 02 00 00 00 (gate u16@+2 = 56).
        let c = container_with_chdr(&[0x00, 0x00, 0x38, 0x00, 0x02, 0x00, 0x00, 0x00]);
        let mut issues = Vec::new();
        assert_eq!(check_chdr_stride_gate(&c, "t", &mut issues), 0);
        assert!(issues.is_empty());
    }

    #[test]
    fn u32_swapped_gate_flags() {
        // Whole-u32 swap of the BE source yields 38 00 00 00 ... → gate u16@+2 = 0 < 0x2A.
        let c = container_with_chdr(&[0x38, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00]);
        let mut issues = Vec::new();
        assert_eq!(check_chdr_stride_gate(&c, "t", &mut issues), 1);
        assert_eq!(issues.len(), 1);
    }
}

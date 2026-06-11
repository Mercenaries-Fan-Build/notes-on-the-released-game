//! Model / mesh UCFX consumption (GEOM, STRM, IBUF, BNDS, HIER, PRMG).

use crate::consume::ConsumeResult;
use mercs2_formats::chunk_validate::validate_skin_containers;
use mercs2_formats::ffcs::{read_f32_le, read_u32_le};
use mercs2_formats::ucfx::extract_chunk_body;

fn read_u16_le(data: &[u8], off: usize) -> u16 {
    u16::from_le_bytes([data[off], data[off + 1]])
}

pub fn consume_model(container: &[u8], _data_body: Option<&[u8]>, label: &str) -> ConsumeResult {
    let mut issues = Vec::new();
    let mut meshes_validated = 0usize;
    let mut xref_hashes = Vec::new();
    let mut bounds_violations = 0usize;
    // Advisory (NON-fatal): heuristic checks with unverified offsets/strides that
    // false-positive on WADs that load fine in-game. Reported but excluded from
    // the verdict (mirrors ecs_float_violations).
    let mut vertex_advisory = 0usize;
    let mut bounds_advisory = 0usize;
    let mut structural_advisory = 0u32;
    // FATAL: counts a converter defect the engine cannot survive (e.g. an MTRL
    // texture-count that overruns the engine's fixed 10-slot array → heap
    // corruption / AV 0x0084DD5B). Routed into the verdict.
    let mut structural_violations = 0u32;

    if let Some(geom) = extract_chunk_body(container, b"GEOM") {
        if geom.len() >= 8 {
            let n_groups = read_u32_le(&geom, 0);
            if n_groups > 10_000 {
                issues.push(format!("{label}: GEOM n_groups={n_groups} implausible"));
            } else {
                meshes_validated += 1;
            }
        }
    }

    // STRM vertex validation (container-based) — also yields vertex_count and sampled positions
    let strm_vertex_count: Option<usize>;
    let sampled_positions: Vec<[f32; 3]>;
    {
        let (found, vv, vc, positions, strm_issues) = validate_strm_vertices(container, label);
        vertex_advisory += vv;
        strm_vertex_count = vc;
        sampled_positions = positions;
        issues.extend(strm_issues);
        if found {
            meshes_validated += 1;
        } else if let Some(strm) = extract_chunk_body(container, b"STRM") {
            if strm.len() < 4 {
                issues.push(format!("{label}: STRM too small"));
            } else {
                meshes_validated += 1;
            }
        }
    }

    // IBUF: index count validation + P2-3 max(index) < vertex_count
    if let Some(ibuf) = extract_chunk_body(container, b"IBUF") {
        if ibuf.len() < 4 {
            issues.push(format!("{label}: IBUF too small"));
        } else {
            let index_count = read_u32_le(&ibuf, 0);
            let needed = 4 + index_count as usize * 2;
            if needed > ibuf.len() && index_count < 10_000_000 {
                issues.push(format!(
                    "{label}: IBUF index_count={index_count} needs ~{needed} bytes, have {}",
                    ibuf.len()
                ));
            } else {
                meshes_validated += 1;

                if let Some(vert_count) = strm_vertex_count {
                    let actual_indices = ((ibuf.len() - 4) / 2).min(index_count as usize);
                    let mut max_idx: u16 = 0;
                    for i in 0..actual_indices {
                        let idx = read_u16_le(&ibuf, 4 + i * 2);
                        if idx > max_idx {
                            max_idx = idx;
                        }
                    }
                    if actual_indices > 0 && (max_idx as usize) >= vert_count {
                        issues.push(format!(
                            "{label}: IBUF max index {max_idx} >= STRM vertex_count {vert_count}"
                        ));
                        structural_advisory += 1;
                    }
                }
            }
        }
    }

    // BNDS: 40-byte structure (center_xyz + radius + min_xyz + max_xyz)
    if let Some(bnds) = extract_chunk_body(container, b"BNDS") {
        if bnds.len() >= 40 {
            let cx = read_f32_le(&bnds, 0);
            let cy = read_f32_le(&bnds, 4);
            let cz = read_f32_le(&bnds, 8);
            let radius = read_f32_le(&bnds, 12);
            let min_x = read_f32_le(&bnds, 16);
            let min_y = read_f32_le(&bnds, 20);
            let min_z = read_f32_le(&bnds, 24);
            let max_x = read_f32_le(&bnds, 28);
            let max_y = read_f32_le(&bnds, 32);
            let max_z = read_f32_le(&bnds, 36);

            let all = [cx, cy, cz, radius, min_x, min_y, min_z, max_x, max_y, max_z];
            if all.iter().any(|f| !f.is_finite()) {
                issues.push(format!("{label}: BNDS contains NaN/Inf"));
                bounds_violations += 1;
            } else {
                let mut ok = true;
                if min_x > max_x || min_y > max_y || min_z > max_z {
                    issues.push(format!(
                        "{label}: BNDS AABB inverted: min=({min_x}, {min_y}, {min_z}) max=({max_x}, {max_y}, {max_z})"
                    ));
                    ok = false;
                }
                if radius <= 0.0 {
                    issues.push(format!("{label}: BNDS radius non-positive: {radius}"));
                    ok = false;
                }
                if cx < min_x || cx > max_x || cy < min_y || cy > max_y || cz < min_z || cz > max_z {
                    issues.push(format!(
                        "{label}: BNDS center ({cx}, {cy}, {cz}) outside AABB"
                    ));
                    ok = false;
                }
                if !ok {
                    bounds_violations += 1;
                }

                // P2-4: BNDS envelope must contain sampled STRM vertices
                if ok && !sampled_positions.is_empty() {
                    let ext_x = (max_x - min_x).max(1.0);
                    let ext_y = (max_y - min_y).max(1.0);
                    let ext_z = (max_z - min_z).max(1.0);
                    let eps_x = (0.01 * ext_x).max(1.0);
                    let eps_y = (0.01 * ext_y).max(1.0);
                    let eps_z = (0.01 * ext_z).max(1.0);

                    let mut oob_count = 0usize;
                    for pos in &sampled_positions {
                        let [vx, vy, vz] = *pos;
                        if vx < min_x - eps_x || vx > max_x + eps_x
                            || vy < min_y - eps_y || vy > max_y + eps_y
                            || vz < min_z - eps_z || vz > max_z + eps_z
                        {
                            oob_count += 1;
                        }
                    }
                    if oob_count > 0 {
                        issues.push(format!(
                            "{label}: BNDS envelope does not contain {oob_count}/{} sampled vertices",
                            sampled_positions.len()
                        ));
                        structural_advisory += 1;
                    }
                }
            }
            meshes_validated += 1;
        }
    }

    // HIER: 176-byte node validation
    if let Some(hier) = extract_chunk_body(container, b"HIER") {
        if hier.len() >= 176 {
            if hier.len() % 176 != 0 {
                issues.push(format!(
                    "{label}: HIER body len {} not a multiple of 176",
                    hier.len()
                ));
                bounds_advisory += 1;
            } else {
                let node_count = hier.len() / 176;
                let mut hier_ok = true;
                for ni in 0..node_count {
                    let base = ni * 176;
                    let mut mat_ok = true;
                    for fi in 0..16 {
                        let f = read_f32_le(&hier, base + 16 + fi * 4);
                        if !f.is_finite() {
                            issues.push(format!(
                                "{label}: HIER node[{ni}] local matrix float[{fi}] NaN/Inf"
                            ));
                            mat_ok = false;
                            hier_ok = false;
                            break;
                        }
                    }
                    if !mat_ok {
                        continue;
                    }
                    let bmin = [
                        read_f32_le(&hier, base + 144),
                        read_f32_le(&hier, base + 148),
                        read_f32_le(&hier, base + 152),
                    ];
                    let bmax = [
                        read_f32_le(&hier, base + 160),
                        read_f32_le(&hier, base + 164),
                        read_f32_le(&hier, base + 168),
                    ];
                    if bmin.iter().chain(bmax.iter()).any(|f| !f.is_finite()) {
                        issues.push(format!("{label}: HIER node[{ni}] tail bbox NaN/Inf"));
                        hier_ok = false;
                    } else if bmin[0] > bmax[0] || bmin[1] > bmax[1] || bmin[2] > bmax[2] {
                        issues.push(format!(
                            "{label}: HIER node[{ni}] tail bbox inverted: min=({}, {}, {}) max=({}, {}, {})",
                            bmin[0], bmin[1], bmin[2], bmax[0], bmax[1], bmax[2]
                        ));
                        hier_ok = false;
                    }
                }
                if !hier_ok {
                    bounds_advisory += 1;
                }
            }
            meshes_validated += 1;
        }
    }

    // PRMG INFO validation (container-based)
    {
        let (prmg_v, prmg_issues) = validate_prmg_info(container, label);
        bounds_advisory += prmg_v;
        issues.extend(prmg_issues);
    }

    if let Some(mtrl) = extract_chunk_body(container, b"MTRL") {
        // MTRL layout (decompile FUN_00858790, spatial/streaming docs):
        // [u32/f32 × 26 = 104B][u16 flags @104][u16 count @106][u32 hash × count @108][u32×2].
        // The texture hashes the engine resolves live at +108 (count @106), NOT at +0
        // (+0 is the first material param). Reading +0 produced garbage that resolved to
        // nothing. The engine writes into a fixed 10-slot array, so cap the count at 10.
        if mtrl.len() >= 108 {
            // The engine (FUN_00858790) writes `raw_count` texture records into a
            // FIXED 10-slot array at material+0xAC. A raw count > 10 overruns it →
            // heap corruption → world-load AV (0x0084DD5B / downstream 0x004CF58B).
            // We must FLAG the raw count (fatal); the clamp below is only so our
            // own xref read stays in-bounds — it must NOT hide the overrun.
            let raw_count = read_u16_le(&mtrl, 106) as usize;
            if raw_count > 10 {
                issues.push(format!(
                    "{label}: MTRL texture-count {raw_count} > 10 — overruns engine's \
                     fixed 10-slot array (heap corruption / AV 0x0084DD5B)"
                ));
                structural_violations += 1;
            }
            let count = raw_count.min(10);
            if std::env::var("MTRL_DEBUG").is_ok() {
                let raw_count = read_u16_le(&mtrl, 106);
                eprintln!(
                    "[MTRL/model] {label}: len={} flags@104=0x{:04X} raw_count@106={} (cap {}) off0=0x{:08X}",
                    mtrl.len(),
                    read_u16_le(&mtrl, 104),
                    raw_count,
                    count,
                    read_u32_le(&mtrl, 0),
                );
                let hi = mtrl.len().min(160);
                let hex: String = mtrl[96..hi]
                    .iter()
                    .enumerate()
                    .map(|(i, b)| {
                        if (96 + i) % 4 == 0 { format!(" |{:3}| {:02x}", 96 + i, b) }
                        else { format!("{:02x}", b) }
                    })
                    .collect();
                eprintln!("    bytes[96..{hi}]:{hex}");
            }
            for i in 0..count {
                let off = 108 + i * 4;
                if off + 4 > mtrl.len() {
                    break;
                }
                let tex_hash = read_u32_le(&mtrl, off);
                if tex_hash != 0 && tex_hash != 0xFFFF_FFFF {
                    if std::env::var("MTRL_DEBUG").is_ok() {
                        eprintln!("    hash[{i}] @+{off} = 0x{tex_hash:08X}");
                    }
                    xref_hashes.push(tex_hash);
                }
            }
        }
    }

    // Skin-container and DEPS checks are heuristic (unverified offsets); they
    // fire on retail-shipped models too, so they are advisory, not fatal.
    for skin_msg in validate_skin_containers(container) {
        issues.push(format!("{label}: {skin_msg}"));
        structural_advisory += 1;
    }

    if let Some(deps) = extract_chunk_body(container, b"DEPS") {
        if let Some(msg) = mercs2_formats::chunk_validate::validate_deps_body(&deps) {
            issues.push(format!("{label}: {msg}"));
            structural_advisory += 1;
        }
    }

    // Buffer-too-small: a texture EMBEDDED in this model container (uppercase
    // INFO/BODY) never gets its own consume_texture dispatch, so check it here.
    // Headline signal — routed to texture_buffer_issues, NOT structural_violations.
    let (texture_buffer_issues, _) =
        crate::texture::check_embedded_texture_buffers(container, label);

    ConsumeResult {
        consumed: true,
        issues,
        xref_hashes,
        meshes_validated,
        bounds_violations,
        structural_violations,
        texture_buffer_issues,
        vertex_advisory,
        bounds_advisory,
        structural_advisory,
        ..Default::default()
    }
}

struct ContainerChild {
    tag: [u8; 4],
    body_start: usize,
    body_size: usize,
}

/// Find a container descriptor (u0 == 0xFFFFFFFF) by tag and return its
/// immediate children (descriptors up to the next container header).
fn find_container_children(container: &[u8], target_tag: &[u8; 4]) -> Vec<ContainerChild> {
    if container.len() < 20 || &container[0..4] != b"UCFX" {
        return Vec::new();
    }
    let data_area_off = read_u32_le(container, 4) as usize;
    let n_desc = read_u32_le(container, 16) as usize;
    let max_desc = container.len().saturating_sub(20) / 20;
    if n_desc > max_desc || n_desc == 0 {
        return Vec::new();
    }

    let mut found = false;
    let mut children = Vec::new();

    for i in 0..n_desc {
        let row_off = 20 + i * 20;
        if row_off + 20 > container.len() {
            break;
        }
        let tag = &container[row_off..row_off + 4];
        let row_u0 = read_u32_le(container, row_off + 4);

        if tag == target_tag && row_u0 == 0xFFFF_FFFF {
            found = true;
            continue;
        }

        if found {
            if row_u0 == 0xFFFF_FFFF {
                break;
            }
            let row_u0 = row_u0 as usize;
            let body_size = read_u32_le(container, row_off + 8) as usize;
            let body_start = if data_area_off > 0 {
                data_area_off + row_u0
            } else {
                8 + row_u0
            };
            if body_start + body_size > container.len() {
                continue;
            }
            let mut child_tag = [0u8; 4];
            child_tag.copy_from_slice(tag);
            children.push(ContainerChild {
                tag: child_tag,
                body_start,
                body_size,
            });
        }
    }

    children
}

/// Validate STRM vertex buffer via container descriptor walk.
/// Returns (found, vertex_violations, vertex_count, sampled_positions, issues).
fn validate_strm_vertices(container: &[u8], label: &str) -> (bool, usize, Option<usize>, Vec<[f32; 3]>, Vec<String>) {
    let children = find_container_children(container, b"STRM");
    if children.is_empty() {
        return (false, 0, None, Vec::new(), Vec::new());
    }

    let mut decl_body: Option<&[u8]> = None;
    let mut data_body: Option<&[u8]> = None;

    for child in &children {
        match &child.tag {
            b"decl" => {
                decl_body = Some(&container[child.body_start..child.body_start + child.body_size])
            }
            b"data" => {
                data_body = Some(&container[child.body_start..child.body_start + child.body_size])
            }
            _ => {}
        }
    }

    let decl = match decl_body {
        Some(d) if d.len() >= 8 => d,
        _ => return (true, 0, None, Vec::new(), Vec::new()),
    };
    let data = match data_body {
        Some(d) if !d.is_empty() => d,
        _ => return (true, 0, None, Vec::new(), Vec::new()),
    };

    let stride = read_u32_le(decl, 4) as usize;
    if stride < 8 || stride > 256 {
        return (
            true,
            0,
            None,
            Vec::new(),
            vec![format!(
                "{label}: STRM decl stride {stride} out of range [8, 256]"
            )],
        );
    }

    if stride < 12 {
        let vertex_count = data.len() / stride;
        return (true, 0, Some(vertex_count), Vec::new(), Vec::new());
    }

    let vertex_count = data.len() / stride;
    let check_count = vertex_count.min(128);
    let mut violations = 0usize;
    let mut issues = Vec::new();
    let mut positions = Vec::with_capacity(check_count);

    for vi in 0..check_count {
        let off = vi * stride;
        if off + 12 > data.len() {
            break;
        }
        let vx = read_f32_le(data, off);
        let vy = read_f32_le(data, off + 4);
        let vz = read_f32_le(data, off + 8);

        if !vx.is_finite() || !vy.is_finite() || !vz.is_finite() {
            violations += 1;
            if issues.len() < 5 {
                issues.push(format!(
                    "{label}: STRM vertex[{vi}] NaN/Inf: ({vx}, {vy}, {vz})"
                ));
            }
        } else {
            positions.push([vx, vy, vz]);
        }
    }

    (true, violations, Some(vertex_count), positions, issues)
}

/// Validate PRMG INFO sub-descriptors (60-byte bounding records).
/// Returns (violations, issues).
fn validate_prmg_info(container: &[u8], label: &str) -> (usize, Vec<String>) {
    let children = find_container_children(container, b"PRMG");
    if children.is_empty() {
        return (0, Vec::new());
    }

    let mut violations = 0usize;
    let mut issues = Vec::new();

    for child in &children {
        if &child.tag != b"INFO" {
            continue;
        }
        let body = &container[child.body_start..child.body_start + child.body_size];
        if body.len() < 60 {
            continue;
        }

        let cx = read_f32_le(body, 20);
        let cy = read_f32_le(body, 24);
        let cz = read_f32_le(body, 28);
        let radius = read_f32_le(body, 32);
        let min_x = read_f32_le(body, 36);
        let min_y = read_f32_le(body, 40);
        let min_z = read_f32_le(body, 44);
        let max_x = read_f32_le(body, 48);
        let max_y = read_f32_le(body, 52);
        let max_z = read_f32_le(body, 56);

        let all = [cx, cy, cz, radius, min_x, min_y, min_z, max_x, max_y, max_z];
        if all.iter().any(|f| !f.is_finite()) {
            issues.push(format!("{label}: PRMG INFO contains NaN/Inf"));
            violations += 1;
            continue;
        }

        let mut ok = true;
        if radius <= 0.0 {
            issues.push(format!("{label}: PRMG INFO radius non-positive: {radius}"));
            ok = false;
        }
        if min_x > max_x || min_y > max_y || min_z > max_z {
            issues.push(format!(
                "{label}: PRMG INFO bbox inverted: min=({min_x}, {min_y}, {min_z}) max=({max_x}, {max_y}, {max_z})"
            ));
            ok = false;
        }
        if cx < min_x || cx > max_x || cy < min_y || cy > max_y || cz < min_z || cz > max_z {
            issues.push(format!(
                "{label}: PRMG INFO center ({cx}, {cy}, {cz}) outside bbox"
            ));
            ok = false;
        }
        if !ok {
            violations += 1;
        }
    }

    (violations, issues)
}

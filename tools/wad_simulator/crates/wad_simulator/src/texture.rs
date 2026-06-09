//! Texture UCFX consumption (INFO + BODY/DDS).

use crate::consume::ConsumeResult;
use mercs2_formats::ffcs::read_u32_le;
use mercs2_formats::texsize::{dxt_format, dxt_mip_count, linear_mip_chain_size};
use mercs2_formats::ucfx::extract_chunk_body;

fn read_u16_le(data: &[u8], off: usize) -> u16 {
    u16::from_le_bytes([data[off], data[off + 1]])
}

pub fn consume_texture(container: &[u8], _data_body: Option<&[u8]>, label: &str) -> ConsumeResult {
    let mut issues = Vec::new();
    let mut textures_validated = 0usize;
    let mut structural_violations = 0u32;

    let body = extract_chunk_body(container, b"BODY")
        .or_else(|| extract_chunk_body(container, b"DXT1"))
        .or_else(|| extract_chunk_body(container, b"data"));

    if let Some(ref b) = body {
        if b.len() >= 128 && &b[0..4] == b"DDS " {
            let header_size = read_u32_le(b, 4);
            if header_size != 124 {
                issues.push(format!("{label}: DDS header_size={header_size} (expected 124)"));
            }
            textures_validated += 1;
        }
    }

    if let Some(info) = extract_chunk_body(container, b"INFO") {
        textures_validated += 1;

        if info.len() >= 34 {
            let width = read_u16_le(&info, 0) as u32;
            let height = read_u16_le(&info, 2) as u32;
            let total_size = read_u32_le(&info, 22);

            if let Some(ref b) = body {
                // Primary check: INFO.total_size == BODY.len()
                if total_size > 0 && total_size as usize != b.len() {
                    issues.push(format!(
                        "{label}: texture INFO total_size={total_size} != BODY len={}",
                        b.len()
                    ));
                    structural_violations += 1;
                }

                // Secondary check: format-based minimum size
                if width > 0 && height > 0 {
                    let fourcc = &info[14..22];
                    let expected_base = compute_base_mip_size(width, height, fourcc);
                    if let Some(exp) = expected_base {
                        if b.len() < exp {
                            issues.push(format!(
                                "{label}: texture BODY len {} < expected base mip {exp} ({}x{})",
                                b.len(), width, height
                            ));
                            structural_violations += 1;
                        }
                    }

                    // Buffer-too-small / streaming-livelock check (see texture_buffer_too_small).
                    if let Some(msg) = texture_buffer_too_small(&info, b.len(), label) {
                        issues.push(msg);
                        structural_violations += 1;
                    }
                }
            }
        }
    }

    ConsumeResult {
        consumed: true,
        issues,
        textures_validated,
        structural_violations,
        ..Default::default()
    }
}

/// Core buffer-too-small test for one texture's INFO + BODY length.
///
/// Live x32dbg (dlc01_dlccon002 roads, then dlc01_dlccon003_spawns) proved the
/// engine instantiates the FULL DXT mip chain from the texture's DIMENSIONS
/// (`dxt_mip_count`, down to the 4x4 minimum) regardless of the header mip field,
/// then reads that many bytes out of BODY. A BODY shorter than that chain makes
/// the streaming worker over-read → `STATUS_BUFFER_TOO_SMALL` (0xC0000023) → the
/// page never reaches ready state 4 → world-load livelock. A correctly converted
/// texture has BODY == this chain (`convert.rs::apply_texture_untile` builds
/// exactly that via the SAME `texsize` helpers), so a shorter BODY is a converter
/// coverage gap. Gated on a valid DXT FourCC, so it returns `None` (no-op) for
/// any non-texture INFO chunk (PRMG/fxdict/ECS-component info).
pub fn texture_buffer_too_small(info: &[u8], body_len: usize, label: &str) -> Option<String> {
    if info.len() < 34 {
        return None;
    }
    let width = read_u16_le(info, 0) as u32;
    let height = read_u16_le(info, 2) as u32;
    if width == 0 || height == 0 {
        return None;
    }
    let mut fcc = [0u8; 4];
    fcc.copy_from_slice(&info[14..18]);
    dxt_format(&fcc)?; // not a DXT texture INFO → skip
    let engine_mips = dxt_mip_count(width as usize, height as usize);
    let engine_chain = linear_mip_chain_size(width as usize, height as usize, &fcc, engine_mips);
    if body_len < engine_chain {
        Some(format!(
            "{label}: texture BODY len {body_len} < engine mip-chain {engine_chain} \
             ({width}x{height} {} {engine_mips}mip) — engine over-reads → \
             STATUS_BUFFER_TOO_SMALL (streaming livelock)",
            String::from_utf8_lossy(&fcc)
        ))
    } else {
        None
    }
}

/// Scan a UCFX container's descriptor table for embedded DXT texture `INFO`+`BODY`
/// pairs and flag any whose BODY is too small (`texture_buffer_too_small`).
///
/// For layer/model containers that EMBED a texture (uppercase `INFO`/`BODY`,
/// distinct from the lowercase `info`/`data` of ECS components/STRM, so no
/// false-positive pairing with component data). Such embedded textures never get
/// their own `consume_texture` dispatch (only the parent's ASET hash is walked),
/// so without this they'd skip the buffer check entirely. Returns
/// `(issues, violation_count)`; a no-op on containers with no embedded texture.
pub fn check_embedded_texture_buffers(container: &[u8], label: &str) -> (Vec<String>, u32) {
    let mut issues = Vec::new();
    let mut violations = 0u32;
    if container.len() < 20 || &container[0..4] != b"UCFX" {
        return (issues, violations);
    }
    let data_area_off = read_u32_le(container, 4) as usize;
    let n_desc = read_u32_le(container, 16) as usize;
    let max_desc = container.len().saturating_sub(20) / 20;
    if n_desc == 0 || n_desc > max_desc {
        return (issues, violations);
    }

    // Pair each texture INFO with the next BODY/DXT1 body in descriptor order.
    let mut pending_info: Option<&[u8]> = None;
    for i in 0..n_desc {
        let row_off = 20 + i * 20;
        if row_off + 20 > container.len() {
            break;
        }
        let tag = &container[row_off..row_off + 4];
        let row_u0 = read_u32_le(container, row_off + 4);
        if row_u0 == 0xFFFF_FFFF {
            continue;
        }
        let body_size = read_u32_le(container, row_off + 8) as usize;
        let body_start = if data_area_off > 0 {
            data_area_off + row_u0 as usize
        } else {
            8 + row_u0 as usize
        };
        if body_start + body_size > container.len() {
            continue;
        }
        let body = &container[body_start..body_start + body_size];
        match tag {
            b"INFO" => pending_info = Some(body),
            b"BODY" | b"DXT1" => {
                if let Some(info) = pending_info.take() {
                    if let Some(msg) = texture_buffer_too_small(info, body.len(), label) {
                        issues.push(msg);
                        violations += 1;
                    }
                }
            }
            _ => {}
        }
    }
    (issues, violations)
}

fn compute_base_mip_size(width: u32, height: u32, fourcc: &[u8]) -> Option<usize> {
    let tag = &fourcc[0..4];
    if tag == b"DXT1" {
        let bw = (width.max(1) + 3) / 4;
        let bh = (height.max(1) + 3) / 4;
        Some((bw * bh * 8) as usize)
    } else if tag == b"DXT3" || tag == b"DXT5" {
        let bw = (width.max(1) + 3) / 4;
        let bh = (height.max(1) + 3) / 4;
        Some((bw * bh * 16) as usize)
    } else if fourcc.iter().all(|&b| b == 0) {
        // Uncompressed RGBA
        Some((width * height * 4) as usize)
    } else {
        None
    }
}

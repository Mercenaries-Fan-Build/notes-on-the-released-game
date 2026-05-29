//! Texture UCFX consumption (INFO + BODY/DDS).

use crate::consume::ConsumeResult;
use mercs2_formats::ffcs::read_u32_le;
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

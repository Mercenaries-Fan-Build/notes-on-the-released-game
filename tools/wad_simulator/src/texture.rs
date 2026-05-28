//! Texture UCFX consumption (INFO + BODY/DDS).

use crate::consume::ConsumeResult;
use crate::ffcs::read_u32_le;
use crate::ucfx::extract_chunk_body;

pub fn consume_texture(container: &[u8], _data_body: Option<&[u8]>, label: &str) -> ConsumeResult {
    let mut issues = Vec::new();
    let mut textures_validated = 0usize;

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

    if extract_chunk_body(container, b"INFO").is_some() {
        textures_validated += 1;
    }

    ConsumeResult {
        consumed: true,
        issues,
        textures_validated,
        ..Default::default()
    }
}

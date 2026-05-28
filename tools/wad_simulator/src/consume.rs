//! Per-asset-type consumption dispatch.

#[derive(Debug, Default, Clone, serde::Serialize)]
pub struct ConsumeResult {
    pub consumed: bool,
    pub issues: Vec<String>,
    pub xref_hashes: Vec<u32>,
    pub placements_validated: usize,
    pub meshes_validated: usize,
    pub textures_validated: usize,
}

pub trait AssetConsumer {
    fn consume(&self, container: &[u8], data_body: Option<&[u8]>, label: &str) -> ConsumeResult;
}

/// Structural-only validation: UCFX already verified in walk; data chunk bounds.
pub struct StructuralConsumer;

impl AssetConsumer for StructuralConsumer {
    fn consume(&self, container: &[u8], data_body: Option<&[u8]>, label: &str) -> ConsumeResult {
        let mut issues = Vec::new();
        if container.len() < 20 || &container[0..4] != b"UCFX" {
            issues.push(format!("{label}: not a UCFX container"));
        }
        if let Some(body) = data_body {
            if body.is_empty() {
                issues.push(format!("{label}: empty data chunk"));
            }
        }
        ConsumeResult {
            consumed: true,
            issues,
            ..Default::default()
        }
    }
}

pub fn consume_structural(container: &[u8], data_body: Option<&[u8]>, label: &str) -> ConsumeResult {
    StructuralConsumer.consume(container, data_body, label)
}

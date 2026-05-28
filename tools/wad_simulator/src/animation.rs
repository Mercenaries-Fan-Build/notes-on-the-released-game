//! Animation / Havok packfile structural validation.

use crate::consume::ConsumeResult;

pub fn consume_animation(_container: &[u8], data_body: Option<&[u8]>, _label: &str) -> ConsumeResult {
    let body = data_body.unwrap_or(&[]);
    let consumed = !body.is_empty();

    ConsumeResult {
        consumed,
        ..Default::default()
    }
}

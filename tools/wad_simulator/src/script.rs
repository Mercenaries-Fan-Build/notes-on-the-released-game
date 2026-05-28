//! Script UCFX consumption (LuaQ / BINN).

use crate::consume::ConsumeResult;

const LUAQ_MAGIC: &[u8] = b"\x1BLua";
const BINN_MAGIC: &[u8; 4] = b"BINN";

pub fn consume_script(_container: &[u8], data_body: Option<&[u8]>, label: &str) -> ConsumeResult {
    let mut issues = Vec::new();
    let Some(body) = data_body else {
        issues.push(format!("{label}: no data chunk"));
        return ConsumeResult {
            consumed: true,
            issues,
            ..Default::default()
        };
    };

    if body.len() >= 5 && body.starts_with(LUAQ_MAGIC) {
        if body.len() >= 12 {
            let version = body[4];
            if version != 0x51 {
                issues.push(format!("{label}: Lua bytecode version 0x{version:02X} (expected 0x51)"));
            }
        }
    } else if body.len() >= 4 && &body[0..4] == BINN_MAGIC {
        // BINN script container — OK
    } else if body.len() < 8 {
        issues.push(format!("{label}: data too small for LuaQ/BINN"));
    } else {
        issues.push(format!(
            "{label}: unknown script header {:?}",
            &body[..body.len().min(8)]
        ));
    }

    ConsumeResult {
        consumed: true,
        issues,
        ..Default::default()
    }
}

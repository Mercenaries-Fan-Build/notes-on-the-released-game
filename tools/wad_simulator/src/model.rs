//! Model / mesh UCFX consumption (GEOM, STRM, IBUF, BNDS bounds).

use crate::consume::ConsumeResult;
use crate::ffcs::read_u32_le;
use crate::ucfx::extract_chunk_body;
use crate::world::{WORLD_X_MAX, WORLD_X_MIN, WORLD_Y_MAX, WORLD_Y_MIN, WORLD_Z_MAX, WORLD_Z_MIN};

pub fn consume_model(container: &[u8], _data_body: Option<&[u8]>, label: &str) -> ConsumeResult {
    let mut issues = Vec::new();
    let mut meshes_validated = 0usize;
    let mut xref_hashes = Vec::new();

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
    if let Some(strm) = extract_chunk_body(container, b"STRM") {
        if strm.len() < 4 {
            issues.push(format!("{label}: STRM too small"));
        } else {
            meshes_validated += 1;
        }
    }
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
            }
        }
    }

    // BNDS: bounding box (6 floats: min_x, min_y, min_z, max_x, max_y, max_z)
    if let Some(bnds) = extract_chunk_body(container, b"BNDS") {
        if bnds.len() >= 24 {
            let floats: Vec<f32> = (0..6)
                .map(|i| f32::from_le_bytes(bnds[i * 4..i * 4 + 4].try_into().unwrap()))
                .collect();

            let any_nan_inf = floats.iter().any(|f| !f.is_finite());
            if any_nan_inf {
                issues.push(format!(
                    "{label}: BNDS contains NaN/Inf — mesh bounds corrupt: [{}, {}, {}, {}, {}, {}]",
                    floats[0], floats[1], floats[2], floats[3], floats[4], floats[5]
                ));
            } else {
                let (min_x, min_y, min_z) = (floats[0], floats[1], floats[2]);
                let (max_x, max_y, max_z) = (floats[3], floats[4], floats[5]);
                if min_x < WORLD_X_MIN * 2.0
                    || max_x > WORLD_X_MAX * 2.0
                    || min_y < WORLD_Y_MIN * 2.0
                    || max_y > WORLD_Y_MAX * 2.0
                    || min_z < WORLD_Z_MIN * 2.0
                    || max_z > WORLD_Z_MAX * 2.0
                {
                    issues.push(format!(
                        "{label}: BNDS implausibly large: min=({min_x}, {min_y}, {min_z}) max=({max_x}, {max_y}, {max_z})"
                    ));
                }
            }
            meshes_validated += 1;
        }
    }

    if let Some(mtrl) = extract_chunk_body(container, b"MTRL") {
        if mtrl.len() >= 4 {
            let tex_hash = read_u32_le(&mtrl, 0);
            if tex_hash > 0x1000 && tex_hash != 0xFFFF_FFFF {
                xref_hashes.push(tex_hash);
            }
        }
    }

    ConsumeResult {
        consumed: true,
        issues,
        xref_hashes,
        meshes_validated,
        ..Default::default()
    }
}

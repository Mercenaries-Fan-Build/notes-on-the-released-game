//! Texture mip-chain sizing — the single source of truth for how the engine
//! instantiates a DXT texture's surfaces from its dimensions.
//!
//! Used by BOTH the converter (`ucfx_byteswap::convert`, which builds the BODY
//! to match) and the `wad_simulator` validator (which flags a BODY too short for
//! the chain the engine will read). Keeping ONE copy avoids the Rust/Python-style
//! drift that previously mis-sized mip counts and caused the `dlc01_dlccon002`
//! roads world-load livelock (see docs / memory `converter-rust-python-drift`).
//!
//! Live x32dbg proved the engine reads the FULL mip chain derived from the
//! texture's dimensions (`dxt_mip_count`, down to the 4x4 DXT minimum) regardless
//! of the header's mip field. A BODY shorter than that chain makes the streaming
//! worker over-read → `STATUS_BUFFER_TOO_SMALL` → the page never reaches ready
//! state 4 → the load livelocks. So the converter sizes the BODY to exactly
//! `linear_mip_chain_size(w, h, fourcc, dxt_mip_count(w, h))`, and the validator
//! flags any texture whose BODY is shorter than that.

/// `(block_px, texel_pitch_bytes, log2_bytes_per_block)` for a DXT FourCC.
/// `None` for non-DXT (uncompressed) formats.
pub fn dxt_format(fourcc: &[u8; 4]) -> Option<(usize, usize, usize)> {
    match fourcc {
        b"DXT1" => Some((4, 8, 3)),
        b"DXT3" => Some((4, 16, 4)),
        b"DXT5" => Some((4, 16, 4)),
        _ => None,
    }
}

/// Number of mip levels in a full chain down to 1x1.
pub fn tex_mip_levels(width: usize, height: usize) -> usize {
    let m = width.max(height).max(1) as u32;
    (32 - m.leading_zeros()) as usize
}

/// PC DXT mip-chain length: levels down to the 4x4 DXT block minimum, governed
/// by the SMALLER dimension. This is the retail vz.wad convention (verified
/// against base vz.wad: 64x64->5, 256->7, 512->8, 1024->9, 512x256->7), NOT the
/// full chain to 1x1 (`tex_mip_levels`, which overshoots by 2 — the engine never
/// instantiates the sub-4x4 levels, so claiming them mismatches its surface
/// count). A reduced count (a DLC stub's 3) undershoots -> BUFFER_TOO_SMALL.
pub fn dxt_mip_count(width: usize, height: usize) -> usize {
    let m = width.min(height).max(1) as u32;
    ((32 - m.leading_zeros()) as usize).saturating_sub(2).max(1)
}

/// Total bytes of a PC-linear DXT mip chain (no tile padding) for `mips` levels.
/// When `mips == 0`, falls back to the full chain to 1x1. Returns 0 for a
/// non-DXT FourCC (caller should gate on `dxt_format`).
pub fn linear_mip_chain_size(width: usize, height: usize, fourcc: &[u8; 4], mips: usize) -> usize {
    let (block_px, texel_pitch, _) = match dxt_format(fourcc) {
        Some(v) => v,
        None => return 0,
    };
    let n = if mips > 0 { mips } else { tex_mip_levels(width, height) };
    let mut total = 0;
    for m in 0..n {
        let wpx = (width >> m).max(1);
        let hpx = (height >> m).max(1);
        let wb = ((wpx + block_px - 1) / block_px).max(1);
        let hb = ((hpx + block_px - 1) / block_px).max(1);
        total += wb * hb * texel_pitch;
    }
    total
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn mip_count_matches_retail_convention() {
        // Ground truth from base vz.wad (memory: worldload-livelock-dxt1-buffer-too-small).
        assert_eq!(dxt_mip_count(64, 64), 5);
        assert_eq!(dxt_mip_count(256, 256), 7);
        assert_eq!(dxt_mip_count(512, 512), 8);
        assert_eq!(dxt_mip_count(1024, 1024), 9);
        assert_eq!(dxt_mip_count(512, 256), 7); // governed by the smaller dim (256)
    }

    #[test]
    fn chain_size_matches_roads_ground_truth() {
        // 64x64 DXT1 resident tail = 2728 bytes (mips 64,32,16,8,4 = 2048+512+128+32+8).
        assert_eq!(linear_mip_chain_size(64, 64, b"DXT1", 5), 2728);
        // 32x32 DXT5 = 1360 bytes (mips 32,16,8,4 = 1024+256+64+16).
        assert_eq!(linear_mip_chain_size(32, 32, b"DXT5", dxt_mip_count(32, 32)), 1360);
    }

    #[test]
    fn non_dxt_fourcc_is_zero() {
        assert_eq!(linear_mip_chain_size(64, 64, b"\0\0\0\0", 5), 0);
        assert!(dxt_format(b"\0\0\0\0").is_none());
    }
}

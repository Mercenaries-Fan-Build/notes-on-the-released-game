// DDS (DXT1/DXT3/DXT5) decode -> RGBA8, and a minimal PNG encoder (RGBA8 -> PNG via flate2 zlib).
use std::io::Write;

fn u32le(b: &[u8], o: usize) -> u32 {
    u32::from_le_bytes([b[o], b[o + 1], b[o + 2], b[o + 3]])
}

pub struct Rgba {
    pub w: u32,
    pub h: u32,
    pub px: Vec<u8>, // RGBA8, w*h*4
}

// Decode the top mip of a DDS (DXT1/BC1, DXT3/BC2, DXT5/BC3). Returns None if unsupported.
pub fn dds_to_rgba(b: &[u8]) -> Option<Rgba> {
    if b.len() < 128 || &b[0..4] != b"DDS " {
        return None;
    }
    let h = u32le(b, 12);
    let w = u32le(b, 16);
    let fourcc = &b[84..88];
    let (block_bytes, mode) = match fourcc {
        b"DXT1" => (8usize, 1u8),
        b"DXT3" => (16, 3),
        b"DXT5" => (16, 5),
        _ => return None, // uncompressed / other formats not handled here
    };
    let mut px = vec![0u8; (w * h * 4) as usize];
    let bw = (w as usize + 3) / 4;
    let bh = (h as usize + 3) / 4;
    let mut off = 128usize;
    for by in 0..bh {
        for bx in 0..bw {
            if off + block_bytes > b.len() {
                return None;
            }
            let blk = &b[off..off + block_bytes];
            off += block_bytes;
            // alpha
            let mut alpha = [255u8; 16];
            let color = match mode {
                3 => {
                    // BC2: 4-bit alpha in first 8 bytes
                    for i in 0..16 {
                        let a4 = (blk[i / 2] >> (4 * (i % 2))) & 0xF;
                        alpha[i] = a4 * 17;
                    }
                    &blk[8..16]
                }
                5 => {
                    // BC3: interpolated alpha in first 8 bytes
                    let a0 = blk[0] as u16;
                    let a1 = blk[1] as u16;
                    let mut ac = [0u16; 8];
                    ac[0] = a0;
                    ac[1] = a1;
                    if a0 > a1 {
                        for i in 2..8 {
                            ac[i] = ((8 - i as u16) * a0 + (i as u16 - 1) * a1) / 7;
                        }
                    } else {
                        for i in 2..6 {
                            ac[i] = ((6 - i as u16) * a0 + (i as u16 - 1) * a1) / 5;
                        }
                        ac[6] = 0;
                        ac[7] = 255;
                    }
                    let bits = (blk[2] as u64)
                        | (blk[3] as u64) << 8
                        | (blk[4] as u64) << 16
                        | (blk[5] as u64) << 24
                        | (blk[6] as u64) << 32
                        | (blk[7] as u64) << 40;
                    for i in 0..16 {
                        let idx = ((bits >> (3 * i)) & 7) as usize;
                        alpha[i] = ac[idx] as u8;
                    }
                    &blk[8..16]
                }
                _ => &blk[0..8], // BC1 (DXT1)
            };
            // color block (BC1 color part)
            let c0 = u16::from_le_bytes([color[0], color[1]]);
            let c1 = u16::from_le_bytes([color[2], color[3]]);
            let rgb = |c: u16| -> [u16; 3] {
                let r = ((c >> 11) & 0x1F) as u16;
                let g = ((c >> 5) & 0x3F) as u16;
                let bl = (c & 0x1F) as u16;
                [(r * 255 / 31), (g * 255 / 63), (bl * 255 / 31)]
            };
            let e0 = rgb(c0);
            let e1 = rgb(c1);
            let mut pal = [[0u16; 3]; 4];
            pal[0] = e0;
            pal[1] = e1;
            if mode == 1 && c0 <= c1 {
                for k in 0..3 {
                    pal[2][k] = (e0[k] + e1[k]) / 2;
                    pal[3][k] = 0;
                }
            } else {
                for k in 0..3 {
                    pal[2][k] = (2 * e0[k] + e1[k]) / 3;
                    pal[3][k] = (e0[k] + 2 * e1[k]) / 3;
                }
            }
            let cbits = u32::from_le_bytes([color[4], color[5], color[6], color[7]]);
            for i in 0..16 {
                let ci = ((cbits >> (2 * i)) & 3) as usize;
                let x = bx * 4 + i % 4;
                let y = by * 4 + i / 4;
                if x < w as usize && y < h as usize {
                    let p = (y * w as usize + x) * 4;
                    px[p] = pal[ci][0] as u8;
                    px[p + 1] = pal[ci][1] as u8;
                    px[p + 2] = pal[ci][2] as u8;
                    px[p + 3] = alpha[i];
                }
            }
        }
    }
    Some(Rgba { w, h, px })
}

// CRC32 (PNG polynomial) for chunk checksums.
fn crc32(bytes: &[u8]) -> u32 {
    let mut crc: u32 = 0xFFFF_FFFF;
    for &b in bytes {
        crc ^= b as u32;
        for _ in 0..8 {
            crc = if crc & 1 != 0 { (crc >> 1) ^ 0xEDB8_8320 } else { crc >> 1 };
        }
    }
    crc ^ 0xFFFF_FFFF
}

pub fn rgba_to_png(img: &Rgba) -> Vec<u8> {
    let mut out = Vec::new();
    out.extend_from_slice(&[0x89, b'P', b'N', b'G', 0x0D, 0x0A, 0x1A, 0x0A]);
    let mut chunk = |out: &mut Vec<u8>, tag: &[u8; 4], data: &[u8]| {
        out.extend_from_slice(&(data.len() as u32).to_be_bytes());
        out.extend_from_slice(tag);
        out.extend_from_slice(data);
        let mut crc_in = Vec::with_capacity(4 + data.len());
        crc_in.extend_from_slice(tag);
        crc_in.extend_from_slice(data);
        out.extend_from_slice(&crc32(&crc_in).to_be_bytes());
    };
    // IHDR
    let mut ihdr = Vec::new();
    ihdr.extend_from_slice(&img.w.to_be_bytes());
    ihdr.extend_from_slice(&img.h.to_be_bytes());
    ihdr.extend_from_slice(&[8, 6, 0, 0, 0]); // 8-bit, RGBA, deflate, no filter, no interlace
    chunk(&mut out, b"IHDR", &ihdr);
    // IDAT: filtered scanlines (filter byte 0) then zlib
    let mut raw = Vec::with_capacity((img.w * img.h * 4 + img.h) as usize);
    let row = (img.w * 4) as usize;
    for y in 0..img.h as usize {
        raw.push(0);
        raw.extend_from_slice(&img.px[y * row..y * row + row]);
    }
    let mut enc = flate2::write::ZlibEncoder::new(Vec::new(), flate2::Compression::fast());
    enc.write_all(&raw).unwrap();
    let comp = enc.finish().unwrap();
    chunk(&mut out, b"IDAT", &comp);
    chunk(&mut out, b"IEND", &[]);
    out
}

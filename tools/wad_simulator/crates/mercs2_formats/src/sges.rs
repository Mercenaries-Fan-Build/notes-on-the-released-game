//! sges block decompression.

use flate2::Decompress;
use std::fs::File;
use std::io::{Read, Seek, SeekFrom};

use crate::ffcs::{read_u32_le, IndxEntry, PAGE_SIZE};

const DEFAULT_SEGMENT_SIZE: usize = 65536;

fn read_u16_le(data: &[u8], offset: usize) -> u16 {
    u16::from_le_bytes([data[offset], data[offset + 1]])
}

pub fn decompress_sges(block_data: &[u8]) -> Result<Vec<u8>, String> {
    if block_data.len() < 16 {
        return Err("Block too small for sges header".into());
    }
    if &block_data[0..4] != b"sges" {
        return Err(format!(
            "Bad sges magic: {:02X} {:02X} {:02X} {:02X}",
            block_data[0], block_data[1], block_data[2], block_data[3]
        ));
    }

    let segment_count = read_u16_le(block_data, 6) as usize;
    let total_uncompressed = read_u32_le(block_data, 8) as usize;
    let table_start = 16usize;
    let table_size = segment_count * 8;
    if block_data.len() < table_start + table_size {
        return Err("Block too small for segment table".into());
    }

    struct Segment {
        compressed_size: usize,
        uncompressed_size: usize,
        data_offset: usize,
        is_compressed: bool,
    }

    let mut segments = Vec::with_capacity(segment_count);
    for i in 0..segment_count {
        let base = table_start + i * 8;
        let compressed_size = read_u16_le(block_data, base) as usize;
        let raw_uncomp = read_u16_le(block_data, base + 2) as usize;
        let uncompressed_size = if raw_uncomp == 0 {
            DEFAULT_SEGMENT_SIZE
        } else {
            raw_uncomp
        };
        let offset_with_flag = read_u32_le(block_data, base + 4);
        let is_compressed = (offset_with_flag & 1) != 0;
        let data_offset = (offset_with_flag & 0xFFFFFFFE) as usize;
        segments.push(Segment {
            compressed_size,
            uncompressed_size,
            data_offset,
            is_compressed,
        });
    }

    // Mirror tools/sges_decompress.py: the per-segment u16 `compressed_size` is
    // unreliable for incompressible/large segments (it can wrap or be 0), so for
    // COMPRESSED segments we feed the inflater the byte span from this segment's
    // offset up to the next segment's offset (capped at 128 KB) and let it consume
    // exactly the deflate stream. Output is capped at the header's total_uncompressed.
    let target = total_uncompressed;
    let end = block_data.len();
    let mut output = Vec::with_capacity(total_uncompressed);
    for (i, seg) in segments.iter().enumerate() {
        if output.len() >= target {
            break;
        }
        let pos = seg.data_offset;
        if pos >= end {
            break;
        }
        if seg.is_compressed {
            let next_off = if i + 1 < segments.len() {
                segments[i + 1].data_offset
            } else {
                end
            };
            let read_end = next_off.min(pos + 131072).min(end);
            if read_end <= pos {
                break;
            }
            let chunk = &block_data[pos..read_end];
            let mut decompressor = Decompress::new(false);
            let mut buf = vec![0u8; seg.uncompressed_size];
            match decompressor.decompress(chunk, &mut buf, flate2::FlushDecompress::Finish) {
                Ok(_) => {
                    let written = decompressor.total_out() as usize;
                    buf.truncate(written);
                    output.extend_from_slice(&buf);
                }
                // Match the Python reference: stop on a corrupt stream rather than
                // failing the whole block (the page_count check flags truncation).
                Err(_) => break,
            }
        } else {
            let actual_sz = if seg.compressed_size > 0 {
                seg.compressed_size
            } else {
                seg.uncompressed_size
            };
            let remaining = target - output.len();
            let read_sz = actual_sz.min(remaining);
            let read_end = (pos + read_sz).min(end);
            if read_end > pos {
                output.extend_from_slice(&block_data[pos..read_end]);
            }
        }
    }
    if output.len() > target {
        output.truncate(target);
    }
    Ok(output)
}

pub fn decompress_block(
    file: &mut File,
    indx_entries: &[IndxEntry],
    block_index: u16,
) -> Result<Vec<u8>, String> {
    let idx = block_index as usize;
    if idx >= indx_entries.len() {
        return Err(format!(
            "block_index {idx} >= INDX count {}",
            indx_entries.len()
        ));
    }
    let indx = &indx_entries[idx];
    let file_offset = indx.page_index as u64 * PAGE_SIZE;
    let compressed_pages = indx.compressed_page_count();
    let compressed_size = compressed_pages as usize * PAGE_SIZE as usize;

    file.seek(SeekFrom::Start(file_offset))
        .map_err(|e| format!("seek error: {e}"))?;
    let mut compressed_data = vec![0u8; compressed_size];
    file.read_exact(&mut compressed_data)
        .map_err(|e| format!("read error: {e}"))?;

    if compressed_data.len() >= 4 && &compressed_data[0..4] == b"sges" {
        decompress_sges(&compressed_data)
    } else if compressed_data.len() >= 4 && &compressed_data[0..4] == b"UCFX" {
        let decomp_pages = indx.decompressed_page_count();
        let decomp_size = decomp_pages as usize * PAGE_SIZE as usize;
        compressed_data.truncate(decomp_size);
        Ok(compressed_data)
    } else {
        let decomp_pages = indx.decompressed_page_count();
        let decomp_size = decomp_pages as usize * PAGE_SIZE as usize;
        compressed_data.truncate(decomp_size);
        Ok(compressed_data)
    }
}

//! ASET sub_entry OOB resolution (heap crash diagnostic).

use colored::*;
use std::collections::HashMap;
use std::fs::File;

use mercs2_formats::ffcs::load_ffcs_archive;
use mercs2_formats::sges::decompress_block;
use mercs2_formats::ucfx::{parse_block_entry_table, BlockTableEntry};

#[derive(Debug)]
pub struct OobDetail {
    pub aset_index: usize,
    pub asset_hash: u32,
    pub type_id: u32,
    pub block_index: u16,
    pub sub_entry: u16,
    pub entry_count: u32,
    pub garbage_entry: BlockTableEntry,
}

#[derive(Debug, Default)]
pub struct AsetStats {
    pub total_aset: usize,
    pub primary_count: usize,
    pub sub_entry_count: usize,
    pub in_bounds: usize,
    pub out_of_bounds: usize,
    pub oob_beyond_buffer: usize,
    pub decompression_failures: usize,
    pub garbage_alloc_total: u64,
    pub xbox_pattern_count: usize,
    pub oob_details: Vec<OobDetail>,
}

fn read_garbage_entry(decompressed: &[u8], sub_entry: u16) -> Option<BlockTableEntry> {
    let offset = 4 + (sub_entry as usize) * 16;
    if offset + 16 > decompressed.len() {
        return None;
    }
    Some(BlockTableEntry {
        name_hash: mercs2_formats::ffcs::read_u32_le(decompressed, offset),
        type_hash: mercs2_formats::ffcs::read_u32_le(decompressed, offset + 4),
        field_c: mercs2_formats::ffcs::read_u32_le(decompressed, offset + 8),
        chunk_size: mercs2_formats::ffcs::read_u32_le(decompressed, offset + 12),
    })
}

pub fn run_aset_oob(
    wad_path: &std::path::Path,
    oob_only: bool,
    limit: usize,
) -> Result<AsetStats, Box<dyn std::error::Error>> {
    let mut file = File::open(wad_path)?;
    let file_size = file.metadata()?.len();
    let arch = load_ffcs_archive(&mut file, file_size)?;
    let aset_entries = arch.aset;
    let indx_entries = arch.indx;

    let mut block_cache: HashMap<u16, Result<Vec<u8>, String>> = HashMap::new();
    let mut stats = AsetStats {
        total_aset: aset_entries.len(),
        ..Default::default()
    };

    let process_count = if limit > 0 {
        limit.min(aset_entries.len())
    } else {
        aset_entries.len()
    };

    for (i, aset) in aset_entries.iter().enumerate().take(process_count) {
        let block_idx = aset.block_index();
        let sub_entry = aset.sub_entry();

        if aset.is_primary() {
            stats.primary_count += 1;
            if !oob_only {
                println!(
                    "  ASET[{i:5}] hash=0x{:08X} type={:2} block={block_idx:4} → {}",
                    aset.asset_hash,
                    aset.type_id,
                    "OK".green()
                );
            }
            continue;
        }

        stats.sub_entry_count += 1;

        if !block_cache.contains_key(&block_idx) {
            let result = decompress_block(&mut file, &indx_entries, block_idx);
            block_cache.insert(block_idx, result);
        }

        match block_cache.get(&block_idx).unwrap() {
            Err(_) => {
                stats.decompression_failures += 1;
            }
            Ok(decompressed) => {
                let (entry_count, _) = parse_block_entry_table(decompressed);
                if (sub_entry as u32) < entry_count {
                    stats.in_bounds += 1;
                } else {
                    stats.out_of_bounds += 1;
                    if sub_entry == block_idx {
                        stats.xbox_pattern_count += 1;
                    }
                    if let Some(g) = read_garbage_entry(decompressed, sub_entry) {
                        stats.garbage_alloc_total += g.chunk_size as u64;
                        stats.oob_details.push(OobDetail {
                            aset_index: i,
                            asset_hash: aset.asset_hash,
                            type_id: aset.type_id,
                            block_index: block_idx,
                            sub_entry,
                            entry_count,
                            garbage_entry: g,
                        });
                    } else {
                        stats.oob_beyond_buffer += 1;
                    }
                    if !oob_only {
                        println!(
                            "  ASET[{i:5}] hash=0x{:08X} → {}",
                            aset.asset_hash,
                            "OOB ACCESS".red().bold()
                        );
                    }
                }
            }
        }
    }

    Ok(stats)
}

pub fn print_aset_summary(stats: &AsetStats) {
    println!(
        "  Total ASET: {}  Primary: {}  OOB: {}",
        stats.total_aset,
        stats.primary_count,
        stats.out_of_bounds
    );
    if stats.out_of_bounds > 0 {
        println!(
            "  {} Heap corruption risk from OOB sub_entry indices",
            "WARNING:".red().bold()
        );
    } else {
        println!("  {} No OOB sub_entry accesses", "OK:".green().bold());
    }
}

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

// ── ASET hash ownership validation ──────────────────────────────────

#[derive(Debug)]
pub struct GhostDetail {
    pub aset_index: usize,
    pub asset_hash: u32,
    pub type_id: u32,
    pub block_index: u16,
    pub block_hashes: Vec<u32>,
}

#[derive(Debug, Default)]
pub struct HashValidationStats {
    pub total_aset: usize,
    pub verified: usize,
    pub ghost_entries: usize,
    pub decompression_failures: usize,
    pub ghost_details: Vec<GhostDetail>,
}

/// Check that every ASET entry's `asset_hash` actually exists in the
/// block entry table it claims to own.  Entries whose hash is absent
/// from the block are "false ownership" / ghost entries — the engine
/// will load wrong data from this block instead of falling through to
/// the base WAD.
pub fn run_aset_hash_validation(
    wad_path: &std::path::Path,
    limit: usize,
) -> Result<HashValidationStats, Box<dyn std::error::Error>> {
    let mut file = File::open(wad_path)?;
    let file_size = file.metadata()?.len();
    let arch = load_ffcs_archive(&mut file, file_size)?;
    let aset_entries = arch.aset;
    let indx_entries = arch.indx;

    let mut block_hash_cache: HashMap<u16, Result<Vec<u32>, String>> = HashMap::new();
    let mut stats = HashValidationStats {
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

        if !block_hash_cache.contains_key(&block_idx) {
            let result = decompress_block(&mut file, &indx_entries, block_idx);
            let hash_result = match result {
                Ok(decompressed) => {
                    let (entry_count, entries) = parse_block_entry_table(&decompressed);
                    let hashes: Vec<u32> = entries
                        .iter()
                        .take(entry_count as usize)
                        .map(|e| e.name_hash)
                        .collect();
                    Ok(hashes)
                }
                Err(e) => Err(e),
            };
            block_hash_cache.insert(block_idx, hash_result);
        }

        match block_hash_cache.get(&block_idx).unwrap() {
            Err(_) => {
                stats.decompression_failures += 1;
            }
            Ok(block_hashes) => {
                if block_hashes.contains(&aset.asset_hash) {
                    stats.verified += 1;
                } else {
                    stats.ghost_entries += 1;
                    if stats.ghost_details.len() < 100 {
                        stats.ghost_details.push(GhostDetail {
                            aset_index: i,
                            asset_hash: aset.asset_hash,
                            type_id: aset.type_id,
                            block_index: block_idx,
                            block_hashes: block_hashes.clone(),
                        });
                    }
                }
            }
        }
    }

    Ok(stats)
}

pub fn print_hash_validation_summary(stats: &HashValidationStats) {
    println!(
        "  Total ASET: {}  Verified: {}  Ghost: {}",
        stats.total_aset, stats.verified, stats.ghost_entries
    );
    if stats.ghost_entries > 0 {
        println!(
            "  {} {} ASET entries claim ownership of assets not in their block",
            "WARNING:".red().bold(),
            stats.ghost_entries
        );
        let show = stats.ghost_details.len().min(10);
        for d in &stats.ghost_details[..show] {
            println!(
                "    ASET[{:5}] hash=0x{:08X} type={:2} block={:4} — block has {} entries, none match",
                d.aset_index, d.asset_hash, d.type_id, d.block_index,
                d.block_hashes.len()
            );
        }
        if stats.ghost_details.len() > 10 {
            println!("    ... and {} more", stats.ghost_details.len() - 10);
        }
        if stats.ghost_entries > stats.ghost_details.len() {
            println!(
                "    (detail capped at {}; {} total ghost entries)",
                stats.ghost_details.len(),
                stats.ghost_entries
            );
        }
    } else {
        println!(
            "  {} All ASET entries verified against block content",
            "OK:".green().bold()
        );
    }
}

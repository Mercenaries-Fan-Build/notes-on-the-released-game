//! End-to-end engine consumption simulation.

use std::collections::{HashMap, HashSet};
use std::path::Path;

use colored::*;

use crate::animation::consume_animation;
use crate::blocks::{
    block_key_for_entry, collect_block_keys, merge_block_issues, parse_blocks_parallel,
    prefetch_blocks_parallel, BlockKey, ParsedBlockCache,
};
use crate::audio::{
    consume_soundbank, consume_wavebank_with_options, LoadedWavebank, WavebankConsumeOptions,
};
use crate::audio::{TYPE_HASH_SOUNDBANK, TYPE_HASH_WAVEBANK, TYPE_ID_SOUNDBANK, TYPE_ID_WAVEBANK};
use crate::consume::{consume_structural, ConsumeResult};
use crate::model::consume_model;
use crate::overlay::{overlay_stats, ResolvedAset, VirtualDisk};
use crate::placement::consume_layer;
use crate::progress::{log, log_every};
use crate::pws::audit_audios_dir;
use crate::safe_slice::SafeSlice;
use crate::script::consume_script;
use crate::texture::consume_texture;
use crate::types::{
    type_hash_for_type_id, type_name, TYPE_ID_ANIMATION, TYPE_ID_LAYER, TYPE_ID_MODEL,
    TYPE_ID_SCRIPT, TYPE_ID_TEXTURE,
};
use crate::ucfx::{
    extract_data_chunk, get_container_by_type_hash, ParsedBlock,
};

#[derive(Debug, Default, Clone, serde::Serialize)]
pub struct TypeStats {
    pub type_id: u32,
    pub type_name: String,
    pub consumed: usize,
    pub issues: usize,
}

#[derive(Debug, Default, serde::Serialize)]
pub struct SimulateReport {
    pub access_violations: Vec<String>,
    pub decode_errors: Vec<String>,
    pub unresolved_hashes: Vec<String>,
    pub ucfx_issues: Vec<String>,
    pub wavebanks_loaded: usize,
    pub soundbanks_loaded: usize,
    pub overlay_total_aset: usize,
    pub assets_by_type: HashMap<u32, TypeStats>,
    pub total_assets_consumed: usize,
    pub xref_checks: usize,
    pub xref_unresolved: usize,
    pub pws_files_found: usize,
    pub pws_files_validated: usize,
    pub streaming_clips: usize,
    pub has_base_wad: bool,
    pub placements_checked: usize,
    pub position_violations: usize,
}

pub struct SimulateOptions<'a> {
    pub audios_dir: Option<&'a Path>,
    /// Optional clip_hash → .pws filename map (from dlc_audio_manifest.json).
    pub clip_pws_map: Option<std::collections::HashMap<u32, String>>,
    pub skip_audio: bool,
    /// Skip pass-1 mesh/texture/layer consumption (audio + PWS only).
    pub audio_only: bool,
    /// Max non-audio assets to process (0 = unlimited).
    pub asset_limit: usize,
    /// How often to print pass-1 progress (every N assets).
    pub progress_interval: usize,
    /// Parallel threads for block prefetch (0 = auto).
    pub jobs: usize,
}

impl Default for SimulateOptions<'_> {
    fn default() -> Self {
        Self {
            audios_dir: None,
            clip_pws_map: None,
            skip_audio: false,
            audio_only: false,
            asset_limit: 0,
            progress_interval: 100,
            jobs: 0,
        }
    }
}

pub fn run_simulate(
    base_wad: Option<&Path>,
    patch_wad: Option<&Path>,
) -> Result<SimulateReport, Box<dyn std::error::Error>> {
    run_simulate_with_options(base_wad, patch_wad, SimulateOptions::default())
}

pub fn run_simulate_with_options(
    base_wad: Option<&Path>,
    patch_wad: Option<&Path>,
    opts: SimulateOptions<'_>,
) -> Result<SimulateReport, Box<dyn std::error::Error>> {
    log("  Loading virtual disk overlay...");
    if let Some(p) = base_wad {
        log(format!("    base: {}", p.display()));
    }
    if let Some(p) = patch_wad {
        log(format!("    patch: {}", p.display()));
    }
    let vd = VirtualDisk::load(base_wad, patch_wad)?;
    let (base_n, patch_n, total) = overlay_stats(&vd);
    log(format!(
        "  Overlay ready: {total} resolved ASET entries (base {base_n}, patch-only overrides {patch_n})"
    ));
    let mut report = SimulateReport {
        overlay_total_aset: total,
        has_base_wad: base_wad.is_some(),
        ..Default::default()
    };

    if let Some(dir) = opts.audios_dir {
        log(format!("  Auditing PWS files in {}...", dir.display()));
        let audit = audit_audios_dir(dir);
        log(format!(
            "  PWS audit: {}/{} files validated",
            audit.files_validated, audit.files_found
        ));
        report.pws_files_found = audit.files_found;
        report.pws_files_validated = audit.files_validated;
        for iss in audit.issues {
            report.ucfx_issues.push(format!("pws: {iss}"));
        }
    }

    let all_entries: Vec<_> = vd.resolved.values().cloned().collect();
    let mut wavebanks: HashMap<u32, LoadedWavebank> = HashMap::new();
    let mut xref_targets: HashSet<u32> = HashSet::new();
    let loaded_hashes: HashSet<u32> = vd.resolved.keys().copied().collect();

    let progress_every = opts.progress_interval.max(1);
    let non_audio_total = all_entries
        .iter()
        .filter(|e| e.type_id != TYPE_ID_WAVEBANK && e.type_id != TYPE_ID_SOUNDBANK)
        .count();
    let audio_total = all_entries.len() - non_audio_total;

    let prefetch_entries = entries_for_prefetch(&all_entries, &opts);
    let block_keys = collect_block_keys(&prefetch_entries, base_wad, patch_wad);
    let raw_blocks = prefetch_blocks_parallel(block_keys, &vd, opts.jobs, progress_every);
    let parsed_cache = parse_blocks_parallel(&raw_blocks, opts.jobs, progress_every);
    merge_block_issues(&parsed_cache, &mut report.ucfx_issues);

    // Pass 1: non-audio asset consumption
    let mut asset_processed = 0usize;
    if !opts.audio_only {
        let limit_note = if opts.asset_limit > 0 {
            format!(" (limit {})", opts.asset_limit)
        } else {
            String::new()
        };
        log(format!(
            "  Pass 1: consuming up to {non_audio_total} non-audio assets{limit_note}..."
        ));
    }
    for entry in &all_entries {
        if opts.audio_only {
            break;
        }
        if opts.asset_limit > 0 && asset_processed >= opts.asset_limit {
            break;
        }
        if entry.type_id == TYPE_ID_WAVEBANK || entry.type_id == TYPE_ID_SOUNDBANK {
            continue;
        }
        let Some((parsed, label)) = get_parsed_for_entry(
            entry,
            base_wad,
            patch_wad,
            &raw_blocks,
            &parsed_cache,
            &mut report,
        ) else {
            continue;
        };

        let type_hash = resolve_type_hash(parsed, entry);
        let container = match get_container_by_type_hash(&parsed, type_hash, Some(entry.asset_hash))
        {
            Some(c) => c,
            None => continue,
        };

        let data_body = extract_data_chunk(&container);
        let result = dispatch_consume(entry.type_id, &container, data_body.as_deref(), &label);
        record_type_stats(&mut report, entry.type_id, &result);
        report.placements_checked += result.placements_validated;
        for h in &result.xref_hashes {
            xref_targets.insert(*h);
        }
        for iss in &result.issues {
            if iss.contains("position NaN/Inf")
                || iss.contains("position out of world bounds")
                || iss.contains("quaternion NaN/Inf")
                || iss.contains("quaternion not unit")
            {
                report.position_violations += 1;
            }
            report.ucfx_issues.push(format!("{}: {iss}", label));
        }
        report.total_assets_consumed += 1;
        asset_processed += 1;
        log_every(asset_processed, progress_every, || {
            format!(
                "  Pass 1: {asset_processed}/{non_audio_total} non-audio assets ({} blocks parsed)",
                parsed_cache.blocks.len()
            )
        });
    }
    if !opts.audio_only {
        log(format!(
            "  Pass 1 complete: {asset_processed} assets, {} blocks in cache",
            parsed_cache.blocks.len()
        ));
    }

    // Pass 2: audio (wavebank then soundbank)
    if !opts.skip_audio {
        log(format!(
            "  Pass 2: loading {audio_total} audio assets (wavebank + soundbank)..."
        ));
        let wb_opts = WavebankConsumeOptions {
            audios_dir: opts.audios_dir,
            clip_pws_map: opts.clip_pws_map.as_ref(),
        };
        let audio_entries: Vec<_> = all_entries
            .iter()
            .filter(|e| e.type_id == TYPE_ID_WAVEBANK || e.type_id == TYPE_ID_SOUNDBANK)
            .collect();

        let mut audio_done = 0usize;
        for entry in audio_entries {
            let Some((parsed, label)) = get_parsed_for_entry(
                entry,
                base_wad,
                patch_wad,
                &raw_blocks,
                &parsed_cache,
                &mut report,
            ) else {
                continue;
            };

            let type_hash = if entry.type_id == TYPE_ID_WAVEBANK {
                TYPE_HASH_WAVEBANK
            } else {
                TYPE_HASH_SOUNDBANK
            };

            let container =
                match get_container_by_type_hash(&parsed, type_hash, Some(entry.asset_hash)) {
                    Some(c) => c,
                    None => continue,
                };

            let body_bytes = match extract_data_chunk(&container) {
                Some(b) => b,
                None => {
                    report.ucfx_issues.push(format!(
                        "{label}: no data chunk for type_hash 0x{type_hash:08X}"
                    ));
                    continue;
                }
            };

            let body = SafeSlice::new(body_bytes, format!("{label}/data"));

            if entry.type_id == TYPE_ID_WAVEBANK {
                match consume_wavebank_with_options(&body, wb_opts) {
                    Ok(wb) => {
                        report.streaming_clips += wb.streaming_clip_count;
                        for iss in &wb.issues {
                            report
                                .ucfx_issues
                                .push(format!("wavebank 0x{:08X}: {iss}", wb.self_hash));
                        }
                        wavebanks.insert(wb.self_hash, wb);
                        report.wavebanks_loaded += 1;
                        record_type_stats(
                            &mut report,
                            TYPE_ID_WAVEBANK,
                            &ConsumeResult {
                                consumed: true,
                                ..Default::default()
                            },
                        );
                    }
                    Err(crate::audio::wavebank::ConsumeError::Access(v)) => {
                        report.access_violations.push(v.to_string());
                    }
                    Err(crate::audio::wavebank::ConsumeError::Decode { clip_index, detail }) => {
                        report.decode_errors.push(format!(
                            "wavebank 0x{:08X} clip[{clip_index}]: {detail}",
                            entry.asset_hash
                        ));
                    }
                }
            } else {
                let resolve = |h: u32| -> bool {
                    wavebanks
                        .values()
                        .any(|wb| crate::audio::wavebank::clip_by_hash(wb, h).is_some())
                        || vd.lookup(h).is_some()
                };
                match consume_soundbank(&body, &resolve) {
                    Ok(sb) => {
                        for iss in &sb.issues {
                            report
                                .ucfx_issues
                                .push(format!("soundbank 0x{:08X}: {iss}", sb.self_hash));
                        }
                        if !sb.unresolved_hashes.is_empty() {
                            for h in &sb.unresolved_hashes {
                                report
                                    .unresolved_hashes
                                    .push(format!("0x{h:08X} (soundbank)"));
                            }
                        }
                        report.soundbanks_loaded += 1;
                        record_type_stats(
                            &mut report,
                            TYPE_ID_SOUNDBANK,
                            &ConsumeResult {
                                consumed: true,
                                ..Default::default()
                            },
                        );
                    }
                    Err(v) => report.access_violations.push(v.to_string()),
                }
            }
            report.total_assets_consumed += 1;
            audio_done += 1;
            log_every(audio_done, progress_every.min(10), || {
                format!(
                    "  Pass 2: {audio_done}/{audio_total} audio assets ({} wavebanks, {} soundbanks)",
                    report.wavebanks_loaded, report.soundbanks_loaded
                )
            });
        }
        log(format!(
            "  Pass 2 complete: {} wavebanks, {} soundbanks",
            report.wavebanks_loaded, report.soundbanks_loaded
        ));
    }

    // Pass 3: cross-reference resolution (placement/model/texture refs → ASET)
    if !xref_targets.is_empty() {
        log(format!(
            "  Pass 3: checking {} cross-references...",
            xref_targets.len()
        ));
    }
    for h in &xref_targets {
        report.xref_checks += 1;
        if !loaded_hashes.contains(h) {
            report.xref_unresolved += 1;
            report
                .unresolved_hashes
                .push(format!("0x{h:08X} (xref)"));
        }
    }

    if report.xref_checks > 0 {
        log(format!(
            "  Pass 3 complete: {} resolved, {} unresolved",
            report.xref_checks - report.xref_unresolved,
            report.xref_unresolved
        ));
    }

    Ok(report)
}

/// Entries whose blocks we prefetch before consumption passes.
fn entries_for_prefetch(
    all_entries: &[ResolvedAset],
    opts: &SimulateOptions<'_>,
) -> Vec<ResolvedAset> {
    let mut out = Vec::new();
    if !opts.audio_only {
        let mut n = 0usize;
        for entry in all_entries {
            if entry.type_id == TYPE_ID_WAVEBANK || entry.type_id == TYPE_ID_SOUNDBANK {
                continue;
            }
            if opts.asset_limit > 0 && n >= opts.asset_limit {
                break;
            }
            out.push(entry.clone());
            n += 1;
        }
    }
    if !opts.skip_audio {
        for entry in all_entries {
            if entry.type_id == TYPE_ID_WAVEBANK || entry.type_id == TYPE_ID_SOUNDBANK {
                out.push(entry.clone());
            }
        }
    }
    out
}

fn get_parsed_for_entry<'a>(
    entry: &ResolvedAset,
    base_wad: Option<&Path>,
    patch_wad: Option<&Path>,
    raw_blocks: &HashMap<BlockKey, Result<Vec<u8>, String>>,
    parsed_cache: &'a ParsedBlockCache,
    report: &mut SimulateReport,
) -> Option<(&'a ParsedBlock, String)> {
    let key = block_key_for_entry(entry, base_wad, patch_wad)?;
    let block_idx = key.block_idx;

    if let Some(Err(e)) = raw_blocks.get(&key) {
        report
            .access_violations
            .push(format!("block {block_idx} decompress: {e}"));
        return None;
    }

    let parsed = parsed_cache.blocks.get(&key)?;
    let label = format!("block[{block_idx}] hash=0x{:08X}", entry.asset_hash);
    Some((parsed, label))
}

fn resolve_type_hash(parsed: &ParsedBlock, entry: &ResolvedAset) -> u32 {
    for e in &parsed.entries {
        if e.name_hash == entry.asset_hash {
            return e.type_hash;
        }
    }
    type_hash_for_type_id(entry.type_id).unwrap_or(0)
}

fn dispatch_consume(
    type_id: u32,
    container: &[u8],
    data_body: Option<&[u8]>,
    label: &str,
) -> ConsumeResult {
    match type_id {
        TYPE_ID_MODEL => consume_model(container, data_body, label),
        TYPE_ID_TEXTURE => consume_texture(container, data_body, label),
        TYPE_ID_LAYER => consume_layer(container, data_body, label),
        TYPE_ID_SCRIPT => consume_script(container, data_body, label),
        TYPE_ID_ANIMATION => consume_animation(container, data_body, label),
        _ => consume_structural(container, data_body, label),
    }
}

fn record_type_stats(report: &mut SimulateReport, type_id: u32, result: &ConsumeResult) {
    let stats = report
        .assets_by_type
        .entry(type_id)
        .or_insert_with(|| TypeStats {
            type_id,
            type_name: type_name(type_id).to_string(),
            ..Default::default()
        });
    if result.consumed {
        stats.consumed += 1;
    }
    stats.issues += result.issues.len();
}

pub fn print_simulate_report(report: &SimulateReport) {
    println!(
        "{}",
        "╔══════════════════════════════════════════════════════════════╗".bright_cyan()
    );
    println!(
        "{}",
        "║              ENGINE CONSUMPTION SIMULATION                   ║".bright_cyan()
    );
    println!(
        "{}",
        "╚══════════════════════════════════════════════════════════════╝".bright_cyan()
    );
    println!();
    println!(
        "  Overlay ASET entries: {}",
        report.overlay_total_aset.to_string().bright_white()
    );
    println!(
        "  Assets consumed:      {}",
        report.total_assets_consumed.to_string().bright_white()
    );
    println!(
        "  Wavebanks loaded:     {}",
        report.wavebanks_loaded.to_string().bright_white()
    );
    println!(
        "  Soundbanks loaded:    {}",
        report.soundbanks_loaded.to_string().bright_white()
    );
    if report.streaming_clips > 0 {
        println!(
            "  Streaming clips:      {}",
            report.streaming_clips.to_string().bright_white()
        );
    }
    if report.pws_files_found > 0 {
        println!(
            "  PWS files:            {} validated / {}",
            report.pws_files_validated.to_string().bright_white(),
            report.pws_files_found
        );
    }
    if report.xref_checks > 0 {
        println!(
            "  Cross-refs:           {} resolved, {} unresolved",
            (report.xref_checks - report.xref_unresolved).to_string().bright_white(),
            report.xref_unresolved
        );
    }
    if report.placements_checked > 0 || report.position_violations > 0 {
        println!(
            "  Placements checked:   {}",
            report.placements_checked.to_string().bright_white()
        );
        if report.position_violations > 0 {
            println!(
                "  Position violations:  {}",
                report.position_violations.to_string().red().bold()
            );
        } else {
            println!(
                "  Position violations:  {}",
                "0".green()
            );
        }
    }
    println!();

    if !report.assets_by_type.is_empty() {
        println!("  {}", "ASSETS BY TYPE:".bright_white().bold());
        let mut types: Vec<_> = report.assets_by_type.values().collect();
        types.sort_by_key(|t| t.type_id);
        for t in types.iter().take(20) {
            println!(
                "    type_id {:2} {:16} consumed={:5} issues={}",
                t.type_id, t.type_name, t.consumed, t.issues
            );
        }
        if types.len() > 20 {
            println!("    ... and {} more types", types.len() - 20);
        }
        println!();
    }

    let xref_fatal = report.has_base_wad && !report.unresolved_hashes.is_empty();
    let has_issues = !report.access_violations.is_empty()
        || !report.decode_errors.is_empty()
        || report.position_violations > 0
        || xref_fatal;

    if !report.access_violations.is_empty() {
        println!(
            "  {} {}",
            "ACCESS VIOLATIONS:".red().bold(),
            report.access_violations.len()
        );
        for v in report.access_violations.iter().take(20) {
            println!("    {}", v.red());
        }
        if report.access_violations.len() > 20 {
            println!("    ... and {} more", report.access_violations.len() - 20);
        }
        println!();
    }

    if !report.decode_errors.is_empty() {
        println!(
            "  {} {}",
            "DECODE ERRORS:".red().bold(),
            report.decode_errors.len()
        );
        for e in report.decode_errors.iter().take(20) {
            println!("    {}", e.red());
        }
        if report.decode_errors.len() > 20 {
            println!("    ... and {} more", report.decode_errors.len() - 20);
        }
        println!();
    }

    if !report.unresolved_hashes.is_empty() {
        if report.has_base_wad {
            println!(
                "  {} {}",
                "UNRESOLVED HASHES:".red().bold(),
                report.unresolved_hashes.len()
            );
        } else {
            println!(
                "  {} {} (no --base-wad; these likely resolve in vz.wad)",
                "UNRESOLVED HASHES:".yellow().bold(),
                report.unresolved_hashes.len()
            );
        }
        for h in report.unresolved_hashes.iter().take(15) {
            println!("    {}", h.yellow());
        }
        if report.unresolved_hashes.len() > 15 {
            println!("    ... and {} more", report.unresolved_hashes.len() - 15);
        }
        println!();
    }

    if !report.ucfx_issues.is_empty() {
        println!(
            "  {} {}",
            "UCFX / FORMAT:".yellow().bold(),
            report.ucfx_issues.len()
        );
        for u in report.ucfx_issues.iter().take(15) {
            println!("    {}", u.dimmed());
        }
        if report.ucfx_issues.len() > 15 {
            println!("    ... and {} more", report.ucfx_issues.len() - 15);
        }
        println!();
    }

    if has_issues {
        println!(
            "  {} Engine would likely fault or misbehave loading this WAD.",
            "VERDICT:".red().bold()
        );
    } else {
        println!(
            "  {} Full consumption path completed without violations.",
            "VERDICT:".green().bold()
        );
    }
    println!();
}

pub fn simulate_exit_code(report: &SimulateReport) -> i32 {
    let has_fatal_ucfx = report.ucfx_issues.iter().any(|u| {
        u.contains("codec 0x05")
            || u.contains("codec 0x01")
            || u.contains("XMA")
            || u.contains("streaming clip")
    });
    let xref_fatal = report.has_base_wad && !report.unresolved_hashes.is_empty();
    if report.access_violations.is_empty()
        && report.decode_errors.is_empty()
        && report.position_violations == 0
        && !xref_fatal
        && !has_fatal_ucfx
    {
        0
    } else {
        1
    }
}

/// Load clip_hash → pws filename from manifest JSON (first candidate per clip).
pub fn load_clip_pws_map(manifest_path: &Path) -> Option<std::collections::HashMap<u32, String>> {
    let text = std::fs::read_to_string(manifest_path).ok()?;
    let root: serde_json::Value = serde_json::from_str(&text).ok()?;
    let clips = root.get("clips")?.as_array()?;
    let mut map = std::collections::HashMap::new();
    for clip in clips {
        let hash = clip.get("clip_hash")?.as_u64()? as u32;
        if let Some(cands) = clip.get("pws_candidates").and_then(|c| c.as_array()) {
            if let Some(first) = cands.first().and_then(|v| v.as_str()) {
                map.entry(hash).or_insert_with(|| first.to_string());
            }
        }
    }
    if map.is_empty() {
        None
    } else {
        Some(map)
    }
}

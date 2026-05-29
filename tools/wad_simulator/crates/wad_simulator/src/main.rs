//! Mercenaries 2 WAD engine consumption simulator.

mod animation;
mod aset_validate;
mod audio;
mod blocks;
mod consume;
mod model;
mod overlay;
mod placement;
mod progress;
mod pws;
mod simulate;
mod script;
mod texture;

use clap::Parser;
use colored::*;
use std::fs::File;
use std::io::Write;
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "wad_simulator")]
#[command(about = "Engine-accurate WAD consumption simulator (ASET + full asset load path)")]
struct Cli {
    /// Primary WAD (patch or single-WAD analysis)
    #[arg(long, default_value = "output/data/vz-patch.wad")]
    wad: PathBuf,

    /// Base game WAD for overlay simulation (vz.wad)
    #[arg(long)]
    base_wad: Option<PathBuf>,

    /// External streaming audio directory (PC Data/Audios)
    #[arg(long)]
    audios_dir: Option<PathBuf>,

    /// Only show OOB entries in ASET section
    #[arg(long, default_value_t = false)]
    oob_only: bool,

    #[arg(long, default_value_t = 0)]
    limit: usize,

    #[arg(long, default_value_t = false)]
    skip_aset: bool,

    #[arg(long, default_value_t = false)]
    skip_audio: bool,

    /// Only run audio + PWS validation (skip mesh/texture/layer scan)
    #[arg(long, default_value_t = false)]
    audio_only: bool,

    /// Max non-audio assets to consume (0 = all)
    #[arg(long, default_value_t = 0)]
    asset_limit: usize,

    /// Progress log interval for asset/block steps (default 100)
    #[arg(long, default_value_t = 100)]
    progress_interval: usize,

    /// Parallel worker threads for block prefetch (0 = auto)
    #[arg(long, default_value_t = 0)]
    jobs: usize,

    /// Skip full asset consumption (ASET-only mode)
    #[arg(long, default_value_t = false)]
    skip_assets: bool,

    /// Write simulation report as JSON to path
    #[arg(long)]
    json_output: Option<PathBuf>,

    /// Path to dlc_audio_manifest.json for streaming clip → .pws mapping
    #[arg(long)]
    audio_manifest: Option<PathBuf>,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli = Cli::parse();

    println!(
        "{}",
        "╔══════════════════════════════════════════════════════════════╗".bright_cyan()
    );
    println!(
        "{}",
        "║   Mercenaries 2 WAD Engine Consumption Simulator           ║".bright_cyan()
    );
    println!(
        "{}",
        "╚══════════════════════════════════════════════════════════════╝".bright_cyan()
    );
    println!();
    println!("WAD: {}", cli.wad.display().to_string().yellow());
    if let Some(ref base) = cli.base_wad {
        println!("Base WAD: {}", base.display().to_string().yellow());
    }
    if let Some(ref audios) = cli.audios_dir {
        println!("Audios: {}", audios.display().to_string().yellow());
    }
    println!();

    let mut exit_code = 0i32;

    if !cli.skip_aset {
        println!("{}", "=== ASET OOB Validation ===".bright_white().bold());
        match aset_validate::run_aset_oob(&cli.wad, cli.oob_only, cli.limit) {
            Ok(stats) => {
                aset_validate::print_aset_summary(&stats);
                if stats.out_of_bounds > 0 {
                    exit_code = 1;
                }
            }
            Err(e) => {
                eprintln!("ASET validation failed: {e}");
                exit_code = 1;
            }
        }
        println!();
    }

    if !cli.skip_assets {
        println!(
            "{}",
            "=== Engine Asset Consumption ===".bright_white().bold()
        );
        let base = cli.base_wad.as_deref();
        let patch = Some(cli.wad.as_path());
        let manifest_path = cli.audio_manifest.clone().or_else(|| {
            Some(PathBuf::from("output/analysis/dlc_audio_manifest.json"))
        });
        let clip_pws_map = manifest_path
            .as_ref()
            .and_then(|p| simulate::load_clip_pws_map(p));
        let opts = simulate::SimulateOptions {
            audios_dir: cli.audios_dir.as_deref(),
            clip_pws_map,
            skip_audio: cli.skip_audio,
            audio_only: cli.audio_only,
            asset_limit: cli.asset_limit,
            progress_interval: cli.progress_interval,
            jobs: cli.jobs,
        };
        match simulate::run_simulate_with_options(base, patch, opts) {
            Ok(report) => {
                simulate::print_simulate_report(&report);
                let sim_code = simulate::simulate_exit_code(&report);
                if sim_code != 0 {
                    exit_code = sim_code;
                }
                if let Some(ref json_path) = cli.json_output {
                    let json = serde_json::to_string_pretty(&report)?;
                    let mut f = File::create(json_path)?;
                    f.write_all(json.as_bytes())?;
                    println!("Wrote JSON report to {}", json_path.display());
                }
            }
            Err(e) => {
                eprintln!("Simulation failed: {e}");
                exit_code = 1;
            }
        }
        println!();
    }

    std::process::exit(exit_code);
}

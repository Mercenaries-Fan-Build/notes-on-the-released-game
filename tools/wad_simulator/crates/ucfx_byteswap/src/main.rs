mod convert;
mod report;
mod validate;

use clap::Parser;
use std::io::{self, Read, Write};
use std::path::PathBuf;

use report::SchemaCoverageReport;

#[derive(Parser)]
#[command(name = "ucfx_byteswap", about = "Convert Xbox 360 BE UCFX blocks to PC LE format")]
struct Cli {
    /// Input decompressed BE block file (omit when using --stdin)
    input: Option<PathBuf>,

    /// Output LE block file (omit when using --stdout)
    #[arg(short, long)]
    output: Option<PathBuf>,

    /// Read input from stdin instead of a file
    #[arg(long)]
    stdin: bool,

    /// Write output to stdout instead of a file
    #[arg(long)]
    stdout: bool,

    /// Dry-run: parse and report without writing output
    #[arg(long)]
    dry_run: bool,

    /// Skip validation checks on converted output
    #[arg(long)]
    no_validate: bool,

    /// Treat validation errors as fatal (non-zero exit, skip writing)
    #[arg(long)]
    strict: bool,

    /// Print a schema field coverage report after conversion
    #[arg(long)]
    report_schema_coverage: bool,
}

fn main() {
    let cli = Cli::parse();

    let pipe_mode = cli.stdin || cli.stdout;

    if !cli.stdin && cli.input.is_none() {
        eprintln!("Error: provide an input file or use --stdin");
        std::process::exit(1);
    }

    let input_data = if cli.stdin {
        let mut buf = Vec::new();
        if let Err(e) = io::stdin().lock().read_to_end(&mut buf) {
            eprintln!("Error reading stdin: {}", e);
            std::process::exit(1);
        }
        buf
    } else {
        let path = cli.input.as_ref().unwrap();
        match std::fs::read(path) {
            Ok(d) => d,
            Err(e) => {
                eprintln!("Error reading {}: {}", path.display(), e);
                std::process::exit(1);
            }
        }
    };

    if !pipe_mode {
        println!("ucfx_byteswap: processing ({} bytes)", input_data.len());
    }

    let mut report = if cli.report_schema_coverage {
        Some(SchemaCoverageReport::default())
    } else {
        None
    };

    match convert::convert_block(&input_data, cli.dry_run, report.as_mut()) {
        Ok(output) => {
            if let Some(rpt) = &report {
                rpt.print_report();
            }

            if cli.dry_run {
                if !pipe_mode {
                    println!("Dry run complete.");
                }
                return;
            }

            let validate = !cli.no_validate;
            let validation_failed = if validate {
                let issues = validate::validate_converted_block(&output);
                if issues.is_empty() {
                    if !pipe_mode {
                        println!("  Validation: OK (all checks passed)");
                    }
                    false
                } else {
                    let error_count = issues.len();
                    eprintln!("  Validation: {} issue(s) found:", error_count);
                    for issue in &issues {
                        eprintln!("    WARN: {}", issue);
                    }
                    true
                }
            } else {
                false
            };

            if cli.strict && validation_failed {
                eprintln!("Strict mode: aborting due to validation errors");
                std::process::exit(2);
            }

            if cli.stdout {
                let stdout = io::stdout();
                let mut handle = stdout.lock();
                if let Err(e) = handle.write_all(&output) {
                    eprintln!("Error writing to stdout: {}", e);
                    std::process::exit(1);
                }
            } else if let Some(out_path) = cli.output {
                if let Err(e) = std::fs::write(&out_path, &output) {
                    eprintln!("Error writing {}: {}", out_path.display(), e);
                    std::process::exit(1);
                }
                if !pipe_mode {
                    println!("Wrote {} bytes to {}", output.len(), out_path.display());
                }
            } else {
                eprintln!("No output path specified (use --output, --stdout, or --dry-run)");
                std::process::exit(1);
            }
        }
        Err(e) => {
            eprintln!("Conversion error: {}", e);
            std::process::exit(1);
        }
    }
}

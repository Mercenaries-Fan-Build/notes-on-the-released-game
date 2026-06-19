//! Comprehensive integration tests for loadprobe.
//!
//! Tests log parsing, phase detection, crash classification, report generation,
//! and edge cases using both synthetic logs and real fixtures (if available).

use std::path::PathBuf;
use std::process::Command;

fn storage(name: &str) -> PathBuf {
    let mut p = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    for _ in 0..4 {
        p.pop();
    }
    p.push("storage");
    p.push(name);
    p
}

fn run_json(log: &str) -> (i32, String) {
    let bin = env!("CARGO_BIN_EXE_loadprobe");
    let path = storage(log);
    if !path.exists() {
        eprintln!("skip: fixture {} not found", path.display());
        return (-1, String::new());
    }
    let out = Command::new(bin)
        .arg("--json")
        .arg("--no-color")
        .arg(&path)
        .output()
        .expect("run loadprobe");
    let code = out.status.code().unwrap_or(-1);
    (code, String::from_utf8_lossy(&out.stdout).to_string())
}

fn field<'a>(json: &'a str, key: &str) -> Option<&'a str> {
    let pat = format!("\"{}\"", key);
    let i = json.find(&pat)? + pat.len();
    let rest = json[i..].trim_start_matches(|c: char| c == ':' || c.is_whitespace());
    if let Some(s) = rest.strip_prefix('"') {
        let end = s.find('"')?;
        Some(&s[..end])
    } else {
        let end = rest.find(|c: char| c == ',' || c == '}' || c.is_whitespace()).unwrap_or(rest.len());
        Some(&rest[..end])
    }
}

// ========== REAL FIXTURE TESTS ==========

#[test]
fn vanilla_boots_into_game_postload_crash() {
    let (code, json) = run_json("pmc_blackbox-vanilla-boot-into-game.log");
    if code < 0 {
        return;
    }
    assert_eq!(field(&json, "kind"), Some("ReachedWorld"), "vanilla reached the world");
    assert_eq!(field(&json, "pct"), Some("100"), "vanilla loaded 100%");
    assert_eq!(code, 0, "REACHED-WORLD exit code");
    assert!(json.contains("874E7D") || json.contains("874"), "crash captured in report");
}

#[test]
fn most_recent_is_hang_not_crash() {
    let (code, json) = run_json("pmc_blackbox-most-recent-run.log");
    if code < 0 {
        return;
    }
    assert_eq!(
        field(&json, "kind"),
        Some("Hang"),
        "most-recent is a hang (then hard-closed), not a crash"
    );
    assert_eq!(code, 11, "HANG exit code");
    assert_eq!(field(&json, "pct"), Some("50"), "wedged at world-load start");
}

#[test]
fn never_finished_is_hang() {
    let (code, json) = run_json("pmc_blackbox-more-recent-log-never-finished-loading.log");
    if code < 0 {
        return;
    }
    assert_eq!(field(&json, "kind"), Some("Hang"), "never-finished is a hang");
    assert_eq!(code, 11, "HANG exit code");
    assert_eq!(field(&json, "steady_free"), Some("4805"), "steady pool free at the wedge");
}

#[test]
fn old_old_parses_and_reports() {
    let (code, _json) = run_json("pmc_blackbox-old-old-run.log");
    if code < 0 {
        return;
    }
    assert!(code == 0 || code == 12, "old-old classifies without error (got {})", code);
}

// ========== UNIT TESTS FOR PARSE MODULE ==========

#[cfg(test)]
mod parse_tests {
    use loadprobe::parse::parse_log;

    #[test]
    fn parse_basic_log_line() {
        let text = "[21:02:43.033] [lua] some message";
        let lines = parse_log(text);
        assert_eq!(lines.len(), 1);
        assert_eq!(lines[0].source, "lua");
        assert_eq!(lines[0].msg, "some message");
        assert_eq!(lines[0].raw_ts, "21:02:43.033");
    }

    #[test]
    fn parse_lua_script_tag() {
        let text = "[21:02:43.033] [lua] player loaded  @player:42";
        let lines = parse_log(text);
        assert_eq!(lines.len(), 1);
        assert_eq!(lines[0].msg, "player loaded");
        assert_eq!(lines[0].script, Some("player".to_string()));
        assert_eq!(lines[0].line, Some(42));
    }

    #[test]
    fn parse_world_echo_prefix() {
        let text = "[21:02:43.033] [world] >>> player created";
        let lines = parse_log(text);
        assert_eq!(lines.len(), 1);
        assert!(lines[0].world_echo);
        assert_eq!(lines[0].msg, "player created");
    }

    #[test]
    fn parse_raw_continuation_line() {
        let text = "[21:02:43.033] [crash] VEH EXCEPTION\n  extra hex data";
        let lines = parse_log(text);
        assert_eq!(lines.len(), 2);
        assert_eq!(lines[0].source, "crash");
        assert_eq!(lines[1].source, "raw");
        assert_eq!(lines[1].msg, "  extra hex data");
    }

    #[test]
    fn parse_empty_lines_skipped() {
        let text = "[21:02:43.033] [lua] line1\n\n[21:02:43.034] [lua] line2";
        let lines = parse_log(text);
        assert_eq!(lines.len(), 2);
    }

    #[test]
    fn parse_midnight_wrap_correction() {
        let text = "[23:59:50.000] [lua] before midnight\n[00:00:10.000] [lua] after midnight";
        let lines = parse_log(text);
        assert_eq!(lines.len(), 2);
        // second line should have ts_ms > first line (day offset applied)
        assert!(lines[1].ts_ms > lines[0].ts_ms);
        assert!(lines[1].ts_ms - lines[0].ts_ms > 10000); // > 10s elapsed
    }

    #[test]
    fn parse_malformed_timestamp() {
        let text = "[invalid] [lua] bad timestamp";
        let lines = parse_log(text);
        assert_eq!(lines.len(), 1);
        assert_eq!(lines[0].source, "raw");
    }

    #[test]
    fn parse_no_space_after_source() {
        let text = "[21:02:43.033] [lua]message";
        let lines = parse_log(text);
        assert_eq!(lines.len(), 1);
        assert_eq!(lines[0].msg, "message");
    }

    #[test]
    fn parse_script_tag_no_line_number() {
        let text = "[21:02:43.033] [lua] msg  @script_only";
        let lines = parse_log(text);
        assert_eq!(lines[0].script, Some("script_only".to_string()));
        assert_eq!(lines[0].line, None);
    }

    #[test]
    fn parse_multiple_script_tags_uses_last() {
        let text = "[21:02:43.033] [lua] msg  @first:1  @second:2";
        let lines = parse_log(text);
        assert_eq!(lines[0].script, Some("second".to_string()));
        assert_eq!(lines[0].line, Some(2));
    }

    #[test]
    fn parse_preserves_line_numbers() {
        let text = "[21:02:43.033] [lua] line1\n[21:02:43.034] [lua] line2";
        let lines = parse_log(text);
        assert_eq!(lines[0].lineno, 1);
        assert_eq!(lines[1].lineno, 2);
    }

    #[test]
    fn parse_carriage_return_stripped() {
        let text = "[21:02:43.033] [lua] message\r\n[21:02:43.034] [lua] next";
        let lines = parse_log(text);
        assert_eq!(lines.len(), 2);
        assert_eq!(lines[0].msg, "message");
    }

    #[test]
    fn parse_large_log_performance() {
        let mut text = String::new();
        for i in 0..10000 {
            let ts = 43033 + (i as u64);
            let h = ts / 3600000;
            let m = (ts % 3600000) / 60000;
            let s = (ts % 60000) / 1000;
            let ms = ts % 1000;
            text.push_str(&format!("[{:02}:{:02}:{:02}.{:03}] [lua] message {}\n", h, m, s, ms, i));
        }
        let lines = parse_log(&text);
        assert_eq!(lines.len(), 10000);
        // ensure monotonic timestamps
        for i in 1..lines.len() {
            assert!(lines[i].ts_ms >= lines[i - 1].ts_ms);
        }
    }
}

// ========== UNIT TESTS FOR PHASES MODULE ==========

#[cfg(test)]
mod phases_tests {
    use loadprobe::phases::{eip_label, is_job_module, is_known_source, is_teardown_eip};

    #[test]
    fn eip_known_crash() {
        let label = eip_label(0x00874E7D);
        assert!(label.is_some());
        assert!(label.unwrap().contains("teardown"));
    }

    #[test]
    fn eip_unknown_crash() {
        let label = eip_label(0xDEADBEEF);
        assert!(label.is_none());
    }

    #[test]
    fn teardown_eip_recognized() {
        assert!(is_teardown_eip(0x00874E7D));
        assert!(!is_teardown_eip(0x0061981F)); // this one is real
    }

    #[test]
    fn job_module_patterns() {
        assert!(is_job_module("OilJob004"));
        assert!(is_job_module("ChiCon033"));
        assert!(is_job_module("PmcJob001"));
        assert!(is_job_module("MrxTaskObjective_01"));
        assert!(!is_job_module("RandomDll"));
        assert!(!is_job_module("OilSomething"));
    }

    #[test]
    fn known_sources_registered() {
        assert!(is_known_source("lua"));
        assert!(is_known_source("crash"));
        assert!(is_known_source("pool"));
        assert!(!is_known_source("unknown_new_source"));
    }
}

// ========== UNIT TESTS FOR REPORT MODULE ==========

#[cfg(test)]
mod report_tests {
    use loadprobe::parse::parse_log;
    use loadprobe::report::analyze;

    #[test]
    fn analyze_minimal_log() {
        let text = "[21:02:43.033] [lua] PMC Blackbox v3";
        let lines = parse_log(text);
        let report = analyze("test.log", String::new(), &lines, &[], &[], 10, 5);
        assert_eq!(report.records, 1);
        assert_eq!(report.furthest_idx, 0); // phase 0: Process init
    }

    #[test]
    fn analyze_full_load() {
        let text = r#"[21:02:43.033] [lua] PMC Blackbox v3
[21:02:43.100] [pool] render-instance pool initialized
[21:02:43.200] [lua] SoundShellBootstrap.Init
[21:02:43.300] [lua] Top of ShellBootstrap::Init()
[21:02:43.400] [lua] Attempting to play movie
[21:02:43.500] [lua] All movies complete
[21:02:43.600] [lua] StartPrecache()
[21:02:43.700] [lua] Shell music started
[21:02:43.800] [lua] Shell exited
[21:02:43.900] [lua] GameBootstrap - bailing because finished shell
[21:02:44.000] [lua] Loading vz level with vz masterscript
[21:02:44.100] [lua] CreatePlayerCharacter
[21:02:44.200] [lua] STATE_WAITFORGAME (refcount=1)
[21:02:44.300] [lua] GlobalEnter - Begin
[21:02:44.400] [lua] Staging Act
[21:02:44.500] [lua] Setting flow data (
[21:02:44.600] [lua] STATE_WAITFORSTREAMING (refcount=1)
[21:02:44.700] [lua] GlobalEnter - Complete
[21:02:44.800] [lua] Enabling portal
[21:02:44.900] [lua] Dynamically imported module
[21:02:45.000] [lua] GlobalExit - Complete
"#;
        let lines = parse_log(text);
        let report = analyze("test.log", String::new(), &lines, &[], &[], 10, 5);
        assert_eq!(report.furthest_idx, 20); // World fully loaded
        assert_eq!(report.pct, 100);
    }

    #[test]
    fn analyze_crash_before_load() {
        let text = r#"[21:02:43.033] [lua] PMC Blackbox v3
[21:02:43.100] [pool] render-instance pool initialized
[21:02:44.000] [lua] Loading vz level with vz masterscript
[21:02:44.100] [crash] VEH EXCEPTION=ACCESS_VIOLATION EIP=61981F
[21:02:44.200] [crash] AV READ target=12345678
"#;
        let lines = parse_log(text);
        let report = analyze("test.log", String::new(), &lines, &[], &[], 10, 5);
        assert_eq!(report.furthest_idx, 10); // Only reached WORLD LOAD START
        assert!(report.crash.is_some());
        let crash = report.crash.unwrap();
        assert_eq!(crash.eip, 0x0061981F);
    }

    #[test]
    fn analyze_hang_detection() {
        let text = r#"[21:02:43.033] [lua] PMC Blackbox v3
[21:02:43.100] [pool] render-instance pool initialized
[21:02:44.000] [lua] Loading vz level with vz masterscript
[21:02:44.100] [lua] CreatePlayerCharacter
[21:02:54.100] [pool] free=5000
[21:02:54.200] [pool] free=5000
[21:02:54.300] [pool] free=5000
"#;
        let lines = parse_log(text);
        let report = analyze("test.log", String::new(), &lines, &[], &[], 3, 5);
        // Should detect hang: 10+ seconds elapsed with no lua/world progress
        assert!(matches!(report.verdict, loadprobe::report::Verdict::Hang { .. }));
    }

    #[test]
    fn analyze_truncated_log() {
        let text = r#"[21:02:43.033] [lua] PMC Blackbox v3
[21:02:43.100] [pool] render-instance pool initialized
[21:02:44.000] [lua] Loading vz level with vz masterscript
[21:02:44.100] [lua] CreatePlayerCharacter
[21:02:44.200] [lua] STATE_WAITFORGAME (refcount=1)
"#;
        let lines = parse_log(text);
        let report = analyze("test.log", String::new(), &lines, &[], &[], 10, 5);
        assert!(matches!(report.verdict, loadprobe::report::Verdict::Truncated { .. }));
    }

    #[test]
    fn analyze_high_signal_markers() {
        let text = r#"[21:02:43.033] [lua] PMC Blackbox v3
[21:02:43.100] [lua] ### Loading module
[21:02:43.200] [lua] !!! Error detected
[21:02:43.300] [lua] normal message
"#;
        let lines = parse_log(text);
        let signals = vec!["###".to_string(), "!!!".to_string()];
        let report = analyze("test.log", String::new(), &lines, &[], &signals, 10, 5);
        assert_eq!(report.signals.len(), 2);
    }

    #[test]
    fn analyze_pool_health_extraction() {
        let text = r#"[21:02:43.033] [lua] PMC Blackbox v3
[21:02:43.100] [cc] DISTINCT texture hashes inserted: 512, pool cap 1024, fits
[21:02:43.200] [cc] total_inserts=1024
[21:02:43.300] [pool] free 1024 -> 1023 (-1)
"#;
        let lines = parse_log(text);
        let report = analyze("test.log", String::new(), &lines, &[], &[], 10, 5);
        assert_eq!(report.pool.distinct, Some(512));
        assert_eq!(report.pool.cap, Some(1024));
        assert_eq!(report.pool.total_inserts, Some(1024));
    }

    #[test]
    fn analyze_build_artifacts() {
        let text = r#"[21:02:43.033] [lua] PMC Blackbox v3
[21:02:43.100] [blackbox] BUILD wad=vz.wad sha256=deadbeef size=1000000
"#;
        let lines = parse_log(text);
        let report = analyze("test.log", String::new(), &lines, &[], &[], 10, 5);
        assert_eq!(report.build.len(), 1);
        assert_eq!(report.build[0].name, "vz.wad");
        assert_eq!(report.build[0].sha256, "deadbeef");
    }

    #[test]
    fn analyze_unknown_sources() {
        let text = r#"[21:02:43.033] [lua] PMC Blackbox v3
[21:02:43.100] [newstuff] Some new instrumentation
"#;
        let lines = parse_log(text);
        let report = analyze("test.log", String::new(), &lines, &[], &[], 10, 5);
        assert!(report.unknown_sources.iter().any(|(s, _)| s == "newstuff"));
    }

    #[test]
    fn analyze_json_serialization() {
        let text = "[21:02:43.033] [lua] PMC Blackbox v3";
        let lines = parse_log(text);
        let report = analyze("test.log", String::new(), &lines, &[], &[], 10, 5);
        let json = serde_json::to_string(&report).expect("serialize");
        assert!(json.contains("\"kind\""));
        assert!(json.contains("test.log"));
    }
}

// ========== EDGE CASE TESTS ==========

#[cfg(test)]
mod edge_cases {
    use loadprobe::parse::parse_log;
    use loadprobe::report::analyze;

    #[test]
    fn empty_log() {
        let text = "";
        let lines = parse_log(text);
        assert_eq!(lines.len(), 0);
        let report = analyze("empty.log", String::new(), &lines, &[], &[], 10, 5);
        assert_eq!(report.records, 0);
    }

    #[test]
    fn single_line_log() {
        let text = "[21:02:43.033] [lua] PMC Blackbox v3";
        let lines = parse_log(text);
        let report = analyze("single.log", String::new(), &lines, &[], &[], 10, 5);
        assert_eq!(report.records, 1);
    }

    #[test]
    fn very_large_timestamps() {
        let text = "[23:59:59.999] [lua] last second of day";
        let lines = parse_log(text);
        assert_eq!(lines.len(), 1);
        assert_eq!(lines[0].raw_ts, "23:59:59.999");
    }

    #[test]
    fn source_with_special_chars() {
        let text = "[21:02:43.033] [prmg-bw] message";
        let lines = parse_log(text);
        assert_eq!(lines[0].source, "prmg-bw");
    }

    #[test]
    fn message_with_brackets() {
        let text = "[21:02:43.033] [lua] [important] data";
        let lines = parse_log(text);
        assert_eq!(lines[0].msg, "[important] data");
    }

    #[test]
    fn very_long_message() {
        let long_msg = "x".repeat(10000);
        let text = format!("[21:02:43.033] [lua] {}", long_msg);
        let lines = parse_log(&text);
        assert_eq!(lines[0].msg.len(), 10000);
    }

    #[test]
    fn many_consecutive_raw_lines() {
        let mut text = String::from("[21:02:43.033] [crash] header\n");
        for i in 0..100 {
            text.push_str(&format!("  continuation line {}\n", i));
        }
        let lines = parse_log(&text);
        assert_eq!(lines.len(), 101);
        assert_eq!(lines[0].source, "crash");
        for i in 1..=100 {
            assert_eq!(lines[i].source, "raw");
        }
    }

    #[test]
    fn script_tag_with_special_chars() {
        let text = "[21:02:43.033] [lua] msg  @my-script_name:99";
        let lines = parse_log(text);
        assert_eq!(lines[0].script, Some("my-script_name".to_string()));
        assert_eq!(lines[0].line, Some(99));
    }

    #[test]
    fn multiple_midnight_wraps() {
        // Only one wrap should be corrected; second wrap ignored
        let text = "[23:59:50.000] [lua] before\n[00:00:10.000] [lua] after first\n[23:00:00.000] [lua] invalid second";
        let lines = parse_log(text);
        assert_eq!(lines.len(), 3);
        assert!(lines[1].ts_ms > lines[0].ts_ms);
    }

    #[test]
    fn empty_report_fields() {
        let text = "";
        let lines = parse_log(text);
        let report = analyze("test.log", String::new(), &lines, &[], &[], 10, 5);
        assert_eq!(report.records, 0);
        assert_eq!(report.first_ts, "");
        assert_eq!(report.last_ts, "");
    }
}

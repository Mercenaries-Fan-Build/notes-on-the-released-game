//! Parser for `pmc_blackbox.log` lines.
//!
//! This module reads and parses the timestamped diagnostic stream emitted by `pmc_bb.dll`.
//! Every line follows the format `[HH:MM:SS.mmm] [source] message`, where:
//! - **timestamp** is wall-clock time (millisecond precision)
//! - **source** is a diagnostic tag: `lua`, `crash`, `world`, `pool`, `mtrl`, `cc`, etc.
//! - **message** is the diagnostic content
//!
//! Special cases:
//! - Lua lines carry a trailing `  @script:line` suffix (script location in game Lua)
//! - `[world]` echoes are prefixed `>>> ` (mirrored from game console)
//! - Continuation hexdumps don't start with a timestamp; kept as `source == "raw"`
//! - Midnight wraps are corrected by detecting backward jumps > 1 hour
//!
//! The main entry point is [`parse_log`], which returns a `Vec<LogLine>` with
//! monotonic, midnight-corrected timestamps and parsed metadata (script, line number, etc.).

/// One parsed log line. `script`/`line`/`world_echo`/`lineno` are retained for
/// completeness and potential consumers (JSON, future call-site reporting) even
/// where the current text dump doesn't print them.
#[derive(Clone, Debug)]
#[allow(dead_code)]
pub struct LogLine {
    /// Monotonic milliseconds (midnight-wrap corrected, see `parse_log`).
    pub ts_ms: u64,
    /// Original `HH:MM:SS.mmm` text (empty for `raw` continuation lines).
    pub raw_ts: String,
    /// Source tag without brackets: `lua`, `pool`, `crash`, ... or `raw`.
    pub source: String,
    /// Message with the `@script:line` suffix and leading `>>> ` stripped.
    pub msg: String,
    /// Lua caller script (without the `@`), if present.
    pub script: Option<String>,
    /// Lua caller line, if present.
    pub line: Option<u32>,
    /// True when the original line was a `>>> `-prefixed `[world]` echo.
    pub world_echo: bool,
    /// 1-based line number in the file.
    pub lineno: usize,
}

impl LogLine {
    /// A signal-prefixed Lua marker (starts with one of the given prefixes).
    pub fn signal_prefix<'a>(&self, prefixes: &[&'a str]) -> Option<&'a str> {
        let m = self.msg.trim_start();
        prefixes.iter().copied().find(|p| m.starts_with(p))
    }
}

/// Parse a log line timestamp in format `HH:MM:SS.mmm` into milliseconds-since-midnight.
///
/// Returns `None` if the timestamp has invalid shape or out-of-range values.
///
/// # Example
/// ```ignore
/// assert_eq!(parse_ts("21:02:43.033"), Some(75763033));
/// ```
fn parse_ts(s: &str) -> Option<u64> {
    // s like "21:02:43.033"
    let (hms, ms) = s.split_once('.')?;
    let mut it = hms.split(':');
    let h: u64 = it.next()?.parse().ok()?;
    let m: u64 = it.next()?.parse().ok()?;
    let sec: u64 = it.next()?.parse().ok()?;
    let mil: u64 = ms.parse().ok()?;
    if it.next().is_some() || h > 23 || m > 59 || sec > 59 || mil > 999 {
        return None;
    }
    Some(((h * 3600 + m * 60 + sec) * 1000) + mil)
}

/// Split a `  @script:line` Lua location suffix from a message.
///
/// Returns a tuple of `(cleaned_msg, optional_script_name, optional_line_number)`.
/// Only recognizes suffixes if they match the pattern: two spaces, `@`, then alphanumeric/colon.
///
/// # Example
/// ```ignore
/// let (msg, script, line) = split_script("some message  @myScript:42");
/// assert_eq!(msg, "some message");
/// assert_eq!(script, Some("myScript".to_string()));
/// assert_eq!(line, Some(42));
/// ```
fn split_script(msg: &str) -> (String, Option<String>, Option<u32>) {
    // The hook emits "  @name:123" or "  @name"; find the LAST "  @".
    if let Some(at) = msg.rfind("  @") {
        let body = &msg[at + 3..];
        // Guard: only treat as a script tag if it looks like name[:line] with no spaces.
        if !body.is_empty() && !body.contains(' ') {
            let (name, line) = match body.rsplit_once(':') {
                Some((n, l)) if l.chars().all(|c| c.is_ascii_digit()) && !l.is_empty() => {
                    (n.to_string(), l.parse::<u32>().ok())
                }
                _ => (body.to_string(), None),
            };
            return (msg[..at].to_string(), Some(name), line);
        }
    }
    (msg.to_string(), None, None)
}

/// Parse a full `pmc_blackbox.log` into ordered `LogLine`s with monotonic timestamps.
///
/// Automatically corrects up to one midnight wrap (if timestamps jump backward by > 1 hour,
/// assumes a new calendar day has started and applies a +86.4M ms offset).
///
/// # Arguments
/// - `text`: The full log file content (may be large)
///
/// # Returns
/// A `Vec<LogLine>` with timestamps corrected, metadata extracted (script/line/world_echo flags),
/// and continuation lines (`raw` source) properly attached to their preceding timestamped line.
///
/// # Edge Cases
/// - Empty lines are skipped
/// - Lines without a valid `[ts] [source] msg` format are kept as raw continuations
/// - Malformed timestamps fall through to raw continuation
pub fn parse_log(text: &str) -> Vec<LogLine> {
    let mut out = Vec::new();
    let mut day_offset: u64 = 0;
    let mut prev_raw: u64 = 0;
    let mut last_ts_ms: u64 = 0;

    for (i, line) in text.lines().enumerate() {
        let lineno = i + 1;
        let line = line.trim_end_matches('\r');
        if line.is_empty() {
            continue;
        }

        // Expect "[ts] [source] rest". A non-matching line is a continuation.
        let parsed = parse_prefix(line);
        match parsed {
            Some((ts_str, source, rest)) => {
                let raw_ms = match parse_ts(ts_str) {
                    Some(v) => v,
                    None => {
                        push_raw(&mut out, line, last_ts_ms, lineno);
                        continue;
                    }
                };
                // Midnight wrap: if the raw ms goes backwards by > 1h, assume a new day.
                if raw_ms + 3_600_000 < prev_raw {
                    day_offset += 86_400_000;
                }
                prev_raw = raw_ms;
                let ts_ms = raw_ms + day_offset;
                last_ts_ms = ts_ms;

                let world_echo = rest.starts_with(">>> ");
                let body = if world_echo { &rest[4..] } else { rest };
                let (msg, script, line_no) = split_script(body);
                out.push(LogLine {
                    ts_ms,
                    raw_ts: ts_str.to_string(),
                    source: source.to_string(),
                    msg,
                    script,
                    line: line_no,
                    world_echo,
                    lineno,
                });
            }
            None => push_raw(&mut out, line, last_ts_ms, lineno),
        }
    }
    out
}

fn push_raw(out: &mut Vec<LogLine>, line: &str, ts_ms: u64, lineno: usize) {
    out.push(LogLine {
        ts_ms,
        raw_ts: String::new(),
        source: "raw".to_string(),
        msg: line.to_string(),
        script: None,
        line: None,
        world_echo: false,
        lineno,
    });
}

/// Parse the prefix of a log line: `[ts] [source] rest`.
///
/// Returns `(timestamp_str, source_tag, message_body)` or `None` if the line
/// doesn't match the expected format.
fn parse_prefix(line: &str) -> Option<(&str, &str, &str)> {
    let rest = line.strip_prefix('[')?;
    let (ts, after) = rest.split_once(']')?;
    let after = after.strip_prefix(' ')?;
    let after = after.strip_prefix('[')?;
    let (source, rest) = after.split_once(']')?;
    let rest = rest.strip_prefix(' ').unwrap_or(rest);
    Some((ts, source, rest))
}

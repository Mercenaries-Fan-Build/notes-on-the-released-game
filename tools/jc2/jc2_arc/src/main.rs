// jc2_arc — Just Cause 2 Avalanche ARC/TAB reader.
// Session detour from the mercs2 RE work. Naming per jc2_* convention.
//
// TAB (table of contents): 16-byte header, then 12-byte entries {u32 nameHash, u32 offset, u32 size}.
// Offsets are 2048-aligned into the sibling ARC. Entry payloads are often per-file
// zlib-compressed (0x78 0x01). Some payloads are "SARC" small-archives that carry real names.
use std::collections::BTreeMap;
use std::fs::File;
use std::io::{Read, Seek, SeekFrom, Write};

fn u32le(b: &[u8], o: usize) -> u32 {
    u32::from_le_bytes([b[o], b[o + 1], b[o + 2], b[o + 3]])
}

struct Entry {
    hash: u32,
    off: u64,
    size: u64,
}

fn read_tab(path: &str) -> Vec<Entry> {
    let d = std::fs::read(path).unwrap();
    let n = (d.len() - 16) / 12;
    (0..n)
        .map(|i| {
            let o = 16 + i * 12;
            Entry {
                hash: u32le(&d, o),
                off: u32le(&d, o + 4) as u64,
                size: u32le(&d, o + 8) as u64,
            }
        })
        .collect()
}

fn read_payload(f: &mut File, e: &Entry) -> Vec<u8> {
    let mut raw = vec![0u8; e.size as usize];
    f.seek(SeekFrom::Start(e.off)).unwrap();
    f.read_exact(&mut raw).unwrap();
    // zlib? try to inflate; on failure keep raw.
    if raw.len() >= 2 && raw[0] == 0x78 {
        let mut out = Vec::new();
        let mut dec = flate2::read::ZlibDecoder::new(&raw[..]);
        if dec.read_to_end(&mut out).is_ok() && !out.is_empty() {
            return out;
        }
    }
    raw
}

// Classify a decompressed blob by content.
fn classify(b: &[u8]) -> &'static str {
    if b.len() < 4 {
        return "tiny";
    }
    let m4 = &b[0..4];
    if m4 == b"DDS " {
        return "dds-texture";
    }
    if m4 == b"FSB4" {
        return "fsb-samplebank";
    }
    if m4 == b"FEV1" {
        return "fev-fmodevent";
    }
    if b.len() >= 5 && &b[0..5] == b"RBMDL" {
        return "rbm-model";
    }
    // SARC small-archive: u32 nameLen(=4) then "SARC"
    if b.len() >= 8 && u32le(b, 0) == 4 && &b[4..8] == b"SARC" {
        return "sarc-bundle";
    }
    if m4 == b"AAF\0" || &b[0..3] == b"AAF" {
        return "aaf-audio";
    }
    // Avalanche binary property container: bytes 01 04 00 01 (typed node tree, hashed keys)
    if b.len() >= 4 && &b[0..4] == &[0x01, 0x04, 0x00, 0x01] {
        return "property-container";
    }
    if b.len() >= 4 && (u32le(b, 0) == 0x0000000C) {
        return "wrap-0c";
    }
    if b.len() >= 4 && (u32le(b, 0) == 0x00000004) {
        return "wrap-04";
    }
    // ADF / instance
    if m4 == b" FDA" || m4 == b"ADF\0" {
        return "adf";
    }
    "unknown"
}

fn ext_for(kind: &str) -> &'static str {
    match kind {
        "dds-texture" => "dds",
        "fsb-samplebank" => "fsb",
        "fev-fmodevent" => "fev",
        "rbm-model" => "rbm",
        "sarc-bundle" => "sarc",
        "container-0104" => "pc0104",
        _ => "bin",
    }
}

// Walk a SARC small-archive, return (name, offset, size) of embedded files.
fn parse_sarc(b: &[u8]) -> Vec<(String, u32, u32)> {
    let mut out = Vec::new();
    if b.len() < 12 || u32le(b, 0) != 4 || &b[4..8] != b"SARC" {
        return out;
    }
    let _version = u32le(b, 8);
    let data_len = u32le(b, 12) as usize;
    let mut p = 16usize;
    let end = (16 + data_len).min(b.len());
    while p + 12 <= end {
        let name_len = u32le(b, p) as usize;
        // valid records have a sane, non-zero name length; anything else is tail padding
        if name_len == 0 || name_len > 256 || p + 4 + name_len + 8 > end {
            break;
        }
        let raw = &b[p + 4..p + 4 + name_len];
        if !raw.iter().all(|&c| (0x20..0x7f).contains(&c)) {
            break; // hit non-printable -> not a real name record
        }
        let name = String::from_utf8_lossy(raw).to_string();
        p += 4 + name_len;
        let off = u32le(b, p);
        let sz = u32le(b, p + 4);
        p += 8;
        out.push((name, off, sz));
    }
    out
}

fn main() {
    let a: Vec<String> = std::env::args().collect();
    if a.len() < 2 {
        eprintln!("usage: jc2_arc <list|extract|names|dump> <tab> <arc> [args]");
        return;
    }
    let cmd = a[1].as_str();
    match cmd {
        "list" => {
            let entries = read_tab(&a[2]);
            let mut f = File::open(&a[3]).unwrap();
            let mut hist: BTreeMap<&str, (u32, u64, u32)> = BTreeMap::new();
            let mut comp = 0u32;
            for e in &entries {
                let payload = read_payload(&mut f, e);
                if e.size >= 2 {
                    let mut b0 = [0u8; 1];
                    f.seek(SeekFrom::Start(e.off)).unwrap();
                    let _ = f.read_exact(&mut b0);
                    if b0[0] == 0x78 {
                        comp += 1;
                    }
                }
                let k = classify(&payload);
                let en = hist.entry(k).or_insert((0, 0, e.hash));
                en.0 += 1;
                en.1 += e.size;
            }
            println!(
                "entries: {}  zlib-compressed: {}  ({:.0}%)",
                entries.len(),
                comp,
                100.0 * comp as f64 / entries.len() as f64
            );
            println!("--- real content types (count, on-disk MB) ---");
            let mut v: Vec<_> = hist.into_iter().collect();
            v.sort_by(|x, y| y.1 .0.cmp(&x.1 .0));
            for (k, (c, s, ex)) in v {
                println!("{:>16}  {:>6}  {:>8.2} MB   e.g. {:08x}", k, c, s as f64 / 1048576.0, ex);
            }
        }
        "names" => {
            // walk every SARC bundle, print embedded file names (recovers real paths)
            let entries = read_tab(&a[2]);
            let mut f = File::open(&a[3]).unwrap();
            let mut total = 0u32;
            for e in &entries {
                let payload = read_payload(&mut f, e);
                if classify(&payload) == "sarc-bundle" {
                    for (name, _o, sz) in parse_sarc(&payload) {
                        println!("{:08x}\t{}\t{}", e.hash, sz, name);
                        total += 1;
                    }
                }
            }
            eprintln!("recovered {} embedded names", total);
        }
        "unpack" => {
            // extract the real NAMED files out of every SARC bundle to <outdir>/<name>
            let entries = read_tab(&a[2]);
            let mut f = File::open(&a[3]).unwrap();
            let outdir = &a[4];
            // optional substring filter: `unpack <tab> <arc> <out> --filter <substr>`
            let filter: Option<String> = a.iter().position(|s| s == "--filter").and_then(|i| a.get(i + 1).cloned());
            // --names <file>: unpack only entries whose lowercased basename is listed (one per line)
            let name_set: Option<std::collections::HashSet<String>> = a
                .iter()
                .position(|s| s == "--names")
                .and_then(|i| a.get(i + 1))
                .and_then(|p| std::fs::read_to_string(p).ok())
                .map(|txt| {
                    txt.lines()
                        .map(|l| l.trim().to_lowercase())
                        .filter(|l| !l.is_empty())
                        .collect()
                });
            // --vehicles: match any vehicle asset (name like vNNN- or vNNN_ where NNN are digits)
            let vehicles = a.iter().any(|s| s == "--vehicles");
            let is_vehicle = |name: &str| -> bool {
                let b = name.as_bytes();
                b.len() > 4 && b[0] == b'v' && b[1].is_ascii_digit() && b[2].is_ascii_digit() && b[3].is_ascii_digit() && (b[4] == b'-' || b[4] == b'_')
            };
            let limit: usize = a.get(5).filter(|s| s.parse::<usize>().is_ok()).and_then(|s| s.parse().ok()).unwrap_or(usize::MAX);
            std::fs::create_dir_all(outdir).unwrap();
            let mut wrote = 0usize;
            for e in &entries {
                if wrote >= limit {
                    break;
                }
                let payload = read_payload(&mut f, e);
                if classify(&payload) != "sarc-bundle" {
                    continue;
                }
                for (name, off, sz) in parse_sarc(&payload) {
                    if let Some(sub) = &filter {
                        if !name.contains(sub.as_str()) {
                            continue;
                        }
                    }
                    if vehicles && !is_vehicle(&name) {
                        continue;
                    }
                    if let Some(set) = &name_set {
                        let base = name.rsplit(['/', '\\']).next().unwrap_or(&name).to_lowercase();
                        if !set.contains(&base) {
                            continue;
                        }
                    }
                    let (off, sz) = (off as usize, sz as usize);
                    if off + sz > payload.len() || sz == 0 || name.is_empty() {
                        continue;
                    }
                    // sanitize name (strip any leading path, keep basename dirs safe)
                    let safe: String = name
                        .chars()
                        .map(|c| if c == '/' || c == '\\' { '_' } else { c })
                        .filter(|c| c.is_ascii_graphic() || *c == '.' || *c == '_')
                        .collect();
                    if safe.is_empty() {
                        continue;
                    }
                    let mut inner = payload[off..off + sz].to_vec();
                    // inner entries may themselves be zlib-compressed
                    if inner.len() >= 2 && inner[0] == 0x78 {
                        let mut out = Vec::new();
                        let mut dec = flate2::read::ZlibDecoder::new(&inner[..]);
                        if dec.read_to_end(&mut out).is_ok() && !out.is_empty() {
                            inner = out;
                        }
                    }
                    let path = format!("{}/{}", outdir, safe);
                    if File::create(&path).and_then(|mut fh| fh.write_all(&inner)).is_ok() {
                        wrote += 1;
                        if wrote >= limit {
                            break;
                        }
                    }
                }
            }
            eprintln!("unpacked {} named files to {}", wrote, outdir);
        }
        "extract" => {
            let entries = read_tab(&a[2]);
            let mut f = File::open(&a[3]).unwrap();
            let outdir = &a[4];
            let limit: usize = a.get(5).and_then(|s| s.parse().ok()).unwrap_or(usize::MAX);
            std::fs::create_dir_all(outdir).unwrap();
            for (i, e) in entries.iter().enumerate() {
                if i >= limit {
                    break;
                }
                let payload = read_payload(&mut f, e);
                let kind = classify(&payload);
                let path = format!("{}/{:08x}.{}", outdir, e.hash, ext_for(kind));
                File::create(&path).unwrap().write_all(&payload).unwrap();
            }
            eprintln!("extracted {} files to {}", entries.len().min(limit), outdir);
        }
        "dump" => {
            // hex+ascii of the decompressed payload for one hash
            let entries = read_tab(&a[2]);
            let mut f = File::open(&a[3]).unwrap();
            let want = u32::from_str_radix(a[4].trim_start_matches("0x"), 16).unwrap();
            for e in &entries {
                if e.hash == want {
                    let p = read_payload(&mut f, e);
                    println!("hash {:08x}  raw {} -> inflated {}  kind={}", e.hash, e.size, p.len(), classify(&p));
                    let n = p.len().min(256);
                    for row in p[..n].chunks(16) {
                        let hex: String = row.iter().map(|b| format!("{:02x} ", b)).collect();
                        let asc: String = row.iter().map(|&b| if (0x20..0x7f).contains(&b) { b as char } else { '.' }).collect();
                        println!("{:<48}{}", hex, asc);
                    }
                    return;
                }
            }
            eprintln!("hash not found");
        }
        _ => eprintln!("unknown command {}", cmd),
    }
}

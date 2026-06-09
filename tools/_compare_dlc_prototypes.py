"""Compare DLC prototypes vs release: ASET coverage + block inventory.
Reads STFS directly from zips in-memory (no extraction). Uses current
StfsReader/parse_be_* path, not old fixed-offset assumptions."""
import sys, zipfile, tempfile
from pathlib import Path
sys.path.insert(0, 'tools')
from x360_dlc_io import (StfsReader, parse_be_ffcs, parse_be_indx,
                         parse_be_pths, parse_be_aset, extract_stfs_from_rar)

TARGETS = {0x57131D20, 0x569D8800, 0x468870E0, 0x474CF400, 0x58DE5A80}
def swp(h): return int.from_bytes(h.to_bytes(4,'big'),'little')
TARGETS_BOTH = TARGETS | {swp(h) for h in TARGETS}

def doh_from_stfs_bytes(b):
    r = StfsReader(b)
    e = next((e for e in r.file_table if "doh" in e["name"].lower()), None)
    if e is None: raise ValueError("no DOH")
    return r.read(0, e["file_size"])

def inventory(doh):
    _, rows = parse_be_ffcs(doh)
    indx = next((r for r in rows if r.tag=="INDX"), None)
    pths = next((r for r in rows if r.tag=="PTHS"), None)
    aset = next((r for r in rows if r.tag=="ASET"), None)
    n = indx.meta
    entries = parse_be_indx(doh, indx.offset, n)
    paths = parse_be_pths(doh, pths.offset, pths.meta)
    asets = parse_be_aset(doh, aset.offset, aset.meta) if aset else []
    return entries, paths, asets

def get_doh_zip(zpath):
    with zipfile.ZipFile(zpath) as zf:
        member = max(zf.infolist(), key=lambda i: i.file_size)
        with zf.open(member) as f:
            return doh_from_stfs_bytes(f.read())

GF = Path("game-files")
SRC = {
  "RELEASE": ("rar", GF/"Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar"),
  "Nov6":    ("zip", GF/"Mercenaries 2 World in Flames (Nov 6, 2008 DLC Blow It Up Again Pack prototype).zip"),
  "Nov25":   ("zip", GF/"Mercenaries 2 World in Flames (Nov 25, 2008 DLC Blow It Up Again Pack prototype).zip"),
  "PackB":   ("zip", GF/"Mercenaries 2 World in Flames (DLC Blow It Up Again Pack B prototype).zip"),
}

data = {}
for name,(kind,p) in SRC.items():
    if not p.exists():
        print(f"{name}: MISSING {p}"); continue
    try:
        if kind=="rar":
            r = extract_stfs_from_rar(p, Path(tempfile.mkdtemp(prefix="rel_")))
            e = next(e for e in r.file_table if "doh" in e["name"].lower())
            doh = r.read(0, e["file_size"])
        else:
            doh = get_doh_zip(p)
        entries, paths, asets = inventory(doh)
        ahash = {a.asset_hash for a in asets}
        data[name] = dict(entries=entries, paths=paths, asets=asets, ahash=ahash)
        hits = TARGETS_BOTH & ahash
        print(f"=== {name}: {len(paths)} blocks, {len(asets)} ASET rows, {len(ahash)} unique hashes ===")
        print(f"    MISSING-TARGET hashes present in ASET: {[hex(h) for h in hits] if hits else 'NONE'}")
    except Exception as ex:
        import traceback; print(f"{name}: ERROR {ex}"); traceback.print_exc()

# Cross-source ASET diff vs RELEASE
if "RELEASE" in data:
    rel = data["RELEASE"]["ahash"]
    for name in ("Nov6","Nov25","PackB"):
        if name not in data: continue
        extra = data[name]["ahash"] - rel
        print(f"\n{name}: {len(extra)} asset hashes NOT in RELEASE")
        # which TARGETS are in extra
        t = TARGETS_BOTH & extra
        if t: print(f"   includes missing targets: {[hex(h) for h in t]}")

# ── Follow-up: block-path diffs + type breakdown of unique assets ──
print("\n" + "="*60)
print("BLOCK-PATH diffs vs RELEASE (basename sets):")
def basenames(paths): return {p.split("\\")[-1].lower() for p in paths}
rel_bn = basenames(data["RELEASE"]["paths"]) if "RELEASE" in data else set()
for name in ("Nov6","Nov25","PackB"):
    if name not in data: continue
    bn = basenames(data[name]["paths"])
    only = bn - rel_bn
    tex_only = {b for b in only if "texture" in b}
    print(f"\n{name}: {len(only)} block-basenames NOT in release; {len(tex_only)} are TEXTURE blocks")
    for b in sorted(only)[:20]: print(f"   {'<TEX>' if 'texture' in b else '     '} {b}")

# Type-id breakdown of release ASET (map hash->type) to classify unique assets
print("\n" + "="*60)
print("TYPE-ID of prototype-unique assets (u3 = type_id):")
if "RELEASE" in data:
    rel_h = data["RELEASE"]["ahash"]
    for name in ("Nov6","PackB"):
        if name not in data: continue
        from collections import Counter
        tc = Counter()
        for a in data[name]["asets"]:
            if a.asset_hash not in rel_h:
                tc[a.u3]+=1
        print(f"\n{name} unique-asset type_ids: {dict(tc.most_common())}")

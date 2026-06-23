# Mercenaries 2 — `.pdata` Function Inventory (Xbox 360 prototype PE)

**Scope:** Parse the `.pdata` (PowerPC RUNTIME_FUNCTION / exception-unwind) table of the recovered
Jul 11 2008 preview executable to produce a *complete* function inventory of `.text` — including
functions that carry no symbol/string evidence.
**Provenance:** `output/jul08_prototype/mercs2_xenon_p.pe_full.bin` (PE32, machine 0x01F2 PowerPC,
13 sections, 32,374,784 B; ImageBase **0x82000000**), recovered per
[../reverse_engineer/jul08_prototype_iso.md](../reverse_engineer/jul08_prototype_iso.md). All numbers
below are emitted by re-running the parser on that file — commands are inline.

Related: [README.md](README.md) (symbol-name map, **3,480** named symbols),
[pangea-engine-core.md](pangea-engine-core.md).

---

## TL;DR

| Metric | Value |
|---|---|
| `.pdata` section | file/RVA **0x118400**, size **0x4c400** (312,320 B) |
| Record format | fixed **8-byte** big-endian RUNTIME_FUNCTION: `BeginAddress`(u32) + packed unwind word(u32) |
| Non-zero records = **functions** | **39,013** |
| Trailing zero-padding records | 27 (table uses 0x4c328 of 0x4c400; 216 B pad) |
| Functions in `.text` (RVA 0x170000–0xb25200) | **38,919** |
| Functions in `BINK` section (RVA ≥ 0xb25200) | **94** |
| Code bytes covered in `.text` | **9,493,404** (0x90db9c) of the 0x9b5200 (10.18 MB) span |
| Begin-address monotonic / 4-byte aligned | yes / yes |
| Computed function ranges that overlap the next function | **0** of 39,012 |

The unwind table gives the **authoritative total function count for this PPC build: 39,013**, the vast
majority of which are unnamed. The named-symbol evidence base (the rest of this doc set) covers at most
~3,480 symbols, so `.pdata` proves the build contains roughly **an order of magnitude more functions
than we have names for**.

---

## 1. Record format (derived empirically)

A raw hex dump of the first records (8-byte stride, big-endian, ImageBase 0x82000000):

```
$ python3 -c "import struct;d=open('output/jul08_prototype/mercs2_xenon_p.pe_full.bin','rb').read();
pd=d[0x118400:0x118400+0x4c400]
for i in range(8):
    a,b=struct.unpack('>II',pd[i*8:i*8+8]); print(f'{hex(a)} rva={hex(a-0x82000000)} word2={hex(b)}')"
0x82170000 rva=0x170000 word2=0x40001104
0x82170048 rva=0x170048 word2=0x40002103
0x82170160 rva=0x170160 word2=0x40001104
0x821701a8 rva=0x1701a8 word2=0x40001104
...
```

- **Stride = 8 bytes.** `BeginAddress` is a full virtual address; `RVA = BeginAddress − 0x82000000`.
  The first entry → RVA 0x170000 = the `.text` start, confirming the record layout.
- **Big-endian** (PowerPC/Xenon): begins decode as strictly monotonic only when read BE.
- The first `.text` instructions at 0x170000 are `7d8802a6 9181fff8 fbe1fff0 9421ffa0`
  = `mflr r12; stw r12,…; std…; stwu r1,-0x60(r1)` — a textbook PPC prologue, confirming
  `BeginAddress` points at real function entry points.

### Packed unwind word (word2)

`word2` decodes as a Xenon bit-packed RUNTIME_FUNCTION descriptor:

| Bits | Field | Meaning |
|---|---|---|
| `[31:30]` | Flags | unwind-data form (see §4) |
| `[29:8]` | **FunctionLength** | length in **instructions**; ×4 = byte size |
| `[7:0]` | PrologLength | prolog length in instructions |

This decode is **validated structurally**: computing `end = BeginAddress + FunctionLength*4` for every
function yields **0 overlaps** with the following `BeginAddress` (median gap 4 B = alignment padding).
That zero-overlap result is what proves the bitfield split is correct, not assumed.

```python
def funclen_bytes(word2): return ((word2 >> 8) & 0x3FFFFF) * 4   # 22-bit field, instr→bytes
def flags(word2):         return (word2 >> 30) & 0x3
```

---

## 2. Parser (the command that produced every number here)

```python
import struct, statistics, collections
PE='output/jul08_prototype/mercs2_xenon_p.pe_full.bin'
data=open(PE,'rb').read()
pd=data[0x118400:0x118400+0x4c400]          # .pdata section
IMGBASE=0x82000000; TEXT_LO=0x170000; TEXT_HI=0xb25200   # .text span
recs=[struct.unpack('>II', pd[i*8:i*8+8]) for i in range(len(pd)//8)]
nz=[(a-IMGBASE, b) for a,b in recs if a!=0]   # drop trailing zero padding
assert all(nz[i][0] < nz[i+1][0] for i in range(len(nz)-1))   # strictly monotonic
flen = lambda b: ((b>>8)&0x3FFFFF)*4
```

- Total 8-byte slots in section: **39,040**; non-zero (real functions): **39,013**; zero-pad: **27**.
- `nz` is strictly monotonic in `BeginAddress` and every begin is 4-byte aligned.

---

## 3. Function inventory & size distribution

```
Total functions (non-zero records)            : 39,013
  in .text  (0x170000 ≤ rva < 0xb25200)        : 38,919
  in BINK   (rva ≥ 0xb25200, executable codecs): 94
.text code bytes covered                       : 9,493,404 (0x90db9c)
.text section span                             : 10,179,072 (0x9b5200)
```

The 94 functions past 0xb25200 land in the `BINK`/`BINKDATA` region — the RAD Bink video codec ships its
own unwind records; they are real functions, just not part of the game's `.text`.

### `.text` size histogram (bytes = FunctionLength×4)

| Size bucket (B) | Count |
|---|---|
| ≤ 16 | 10 |
| 17–32 | 1 |
| 33–64 | 1,769 |
| 65–128 | **20,080** |
| 129–256 | 8,514 |
| 257–512 | 5,063 |
| 513–1024 | 2,267 |
| 1025–4096 | 1,154 |
| > 4096 | 61 |

- Median function size **116 B** (29 instructions); mean **243.9 B** (9,493,404 / 38,919). The mass sits at 65–256 B —
  consistent with a heavily inlined C++ engine (many small accessors/wrappers).
- **Largest functions in `.text`** (RVA → size): `0x4fdb80`→25,904 B · `0x506110`→24,976 B ·
  `0x7a8390`→22,504 B · `0x27cac0`→12,884 B · `0x301b88`→12,712 B · `0x55aae8`→12,512 B.
  These are candidate "god functions" (likely the main update loop / a Havok solver / a Lua VM
  dispatch) for future targeted disassembly — *(which exactly is inferred; not yet named)*.
- No zero-length functions; smallest is 12 B (3 instructions).

---

## 4. Unwind flag breakdown

```
flags = (word2 >> 30) & 3   over all 39,013 functions
  flag 1 : 38,899   (standard packed unwind — the overwhelming majority)
  flag 3 :    108
  flag 0 :      3
  flag 2 :      3
```

Nearly all functions use the same compact form (flag 1). The 108 flag-3 and the handful of flag-0/2
entries are the functions with larger/out-of-line unwind descriptors (big stack frames, complex
prologs). *(Exact semantics of each flag value are inferred from the distribution, not from a spec
in-hand.)*

---

## 5. Cross-reference with the named functions — and an important caveat

**The existing pairing data is for a *different* binary.** `output/jul08_prototype/pairing/functions.json`
and `symbol_map.json` use `FUN_<addr>` names whose addresses span **0x401080 – 0x3700545** with ImageBase
**0x400000** — i.e. they are the **retail x86 PC** decompilation, not this PowerPC prototype PE
(ImageBase 0x82000000). Verified:

```
$ python3 -c "import json;d=json.load(open('output/jul08_prototype/pairing/functions.json'));
a=sorted(int(k.split('_')[1],16) for k in d if k.startswith('FUN_'));
print(len(a),hex(a[0]),hex(a[-1]))"
25448 0x401080 0x3700545
```

Therefore a **direct address-equality** cross-reference (PPC `.pdata` RVA ↔ `FUN_<x86addr>`) is **not
valid** — the two binaries have independent layouts. What we *can* state quantitatively:

| Inventory | Count | Binary |
|---|---|---|
| PPC `.pdata` functions (this doc) | **39,013** | Xbox 360 prototype (authoritative total) |
| x86 PC functions decompiled (`functions.json`) | 25,448 | retail PC |
| x86 PC functions anchored to a symbol/string name (`symbol_map` + `string_func_map`) | **2,591** unique | retail PC |
| Named *symbols* scraped from the PPC PE ([README.md](README.md)) | 3,480 | Xbox 360 prototype |

**Bottom line:** the PPC build has **39,013 functions**; the name evidence we possess (≤ 3,480 PPC
symbols, or 2,591 string-anchored PC funcs) covers at most **~7–9 %** of them. The `.pdata` table is the
only source that enumerates the **other ~91 %** (the unnamed functions) with exact entry points and
sizes. To actually attach the PC names to PPC addresses would require a structural/string-anchored
diff between the two binaries (future work), not the `.pdata` table alone.

---

## 6. What this enables

- A complete `BeginAddress → size` map for **all 38,919 `.text` functions** is recoverable in one pass
  with the §2 parser — a ready-made function database for a disassembler (e.g. seeding IDA/Ghidra
  PPC function bounds without relying on heuristic recovery).
- The 61 functions > 4 KB and the named top-6 are the highest-value disassembly targets.
- Coverage check: 9.49 MB of the 10.18 MB `.text` span is inside a declared function range; the ~0.69 MB
  remainder is inter-function alignment padding + any leaf functions the compiler omitted from `.pdata`
  (PPC leaf functions with no prolog can legally be absent) — *(that omission is inferred; the table
  itself is exhaustive for non-leaf code)*.

---

*All figures regenerated from `output/jul08_prototype/mercs2_xenon_p.pe_full.bin` on parse; re-run the
§2 snippet to reproduce.*

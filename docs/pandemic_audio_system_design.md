# Mercenaries 2 Audio System — Inferred Engine Design (2006 Pandemic)

**Purpose:** Spec for `wad_simulator` engine-accurate consumption. Reasoned from binary evidence, cross-platform WAD comparison, and Mercs 1→2 evolution — not a line-for-line port of Mercs 1 `RedSoundSystem`.

**Status:** Living document; refine when Mercs 1 `RedSoundSystem.cpp` or deeper Ghidra on `LoadSoundBank`/`LoadWaveBank` becomes available.

---

## 1. Architectural shift (Mercs 1 → Mercs 2)

| Mercs 1 | Mercs 2 |
|---------|---------|
| `RedSoundSystem` + XACT-style external banks | `PalSoundEngine` + embedded UCFX `soundbank`/`wavebank` |
| Flat Lua: `Audio_PlaySound` | Table API: `Sound.LoadSoundBank`, `Sound.CueSound` |
| Assets in flat `.dsk` | FFCS WAD → sges block → UCFX `data` chunk |
| Platform I/O via `PblStreamManager` | Same virtual-disk idea: stacked WADs, last-opened wins |

**What they kept:** Hash-based asset lookup (`pandemic_hash_m2`), multi-library overlay, async block read then parse.

**What they replaced:** Container format, compression, bank file layout, mixer implementation, per-platform codec in wavebank records.

---

## 2. Asset resolution path (load time)

```
Sound.LoadWaveBank("bank_name")  [Lua]
  → pandemic_hash_m2("bank_name")
  → RedVirtualDisk / FFCS: ASET lookup (asset_hash, type_id=6 wavebank)
  → block_index = packed_block_ref >> 16; sub_entry = low16 (0xFFFF = primary)
  → INDX[block_index] → read compressed pages → decompress sges
  → Block: count + entry_table[] + sequential UCFX chunks
  → Find entry with type_hash 0xF753F6D0 (and/or name_hash match)
  → UCFX container → descriptor "data" → wavebank body bytes
  → Parse header, records, retain blob; for each record follow data_offset+data_size
  → Register clips in runtime wavebank table keyed by clip_hash
```

Soundbank (`type_id=21`, `type_hash=0x9F8BCA10`) follows the same path with a 32-byte header and four body sections.

**Simulator must:** Overlay patch over base ASET, decompress block, walk UCFX, extract `data` body, then fully parse and dereference every offset.

---

## 3. LoadWaveBank — inferred behavior

### 3.1 On-disk layout (PC)

| Region | Size | Fields |
|--------|------|--------|
| Header | 24 | `count(u32)`, `self_hash(u32)`, `flags(u16)`, `more_flags(u16)`, `hash2(u32)`, `records_offset(u32)=24`, pad |
| Records | `count × 36` | See below |
| Audio blob | rest | Raw codec frames |

**Per record (36 bytes):**

| Off | Type | Role |
|-----|------|------|
| 0 | u32 | `clip_hash` — FNV name id for cue lookup |
| 4 | u8×4 | `[pad, channels, codec, pad]` — **codec is dispatch key** |
| 8 | u32 | `sample_rate` |
| 12 | u32 | **`data_offset`** — byte offset into body (pointer) |
| 16 | u32 | **`data_size`** — byte length |
| 20 | 16 | Extra metadata (often zero) |

### 3.2 Runtime structures (inferred)

```c
struct PalWaveBank {
    uint32_t bank_hash;
    uint32_t clip_count;
    PalWaveClip* clips;      // array[populated_count]
    uint8_t* blob;           // owns decompressed body tail
    size_t blob_size;
};

struct PalWaveClip {
    uint32_t clip_hash;
    uint8_t channels;
    uint8_t codec;
    uint32_t sample_rate;
    uint8_t* data;           // = blob + data_offset
    uint32_t data_size;
    // decoded PCM cache optional
};
```

### 3.3 Load algorithm

1. Validate `records_offset + count*36 <= body_len`.
2. For each record `i` where `clip_hash != 0` or `data_size != 0`:
   - `ptr = body + data_offset`; require `data_offset + data_size <= body_len`.
   - Select decoder from `codec` (PC: `0x02` IMA ADPCM mono blocks 36B, stereo 72B).
3. Store clip in hash table by `clip_hash`.

**Failure modes:** OOB `data_offset` → heap read AV (same class as MixSources if corrupt metadata poisons mixer state earlier). Wrong codec → decode error path may destroy `PalSoundEngine` without clearing `g_pPalSoundEngine`.

---

## 4. LoadSoundBank — inferred behavior

### 4.1 Header (32 bytes)

| Off | Type | Role |
|-----|------|------|
| 0 | u8×4 | Format/version constant (`0x1D` typical) — **do not treat as u32 for endian swap** |
| 4 | u32 | `self_hash` |
| 8 | u16 | `sub_count` — primary event count |
| 10 | u16 | `sub_count2` — secondary parameter count |
| 12 | u32 | `self_hash2` |
| 16 | u32 | `data_start` (= 32) |
| 20–28 | u32×3 | `section_off1`, `section_off2`, `section_off3` |

### 4.2 Body sections

| Section | Range | Content |
|---------|-------|---------|
| A | `[data_start, section_off1)` | `sub_count` fixed-size **event records** (hashes, f32 params, u8×4 flags) |
| B | `[section_off1, section_off2)` | `sub_count` × u32 — **indices** into wavebank clips or internal voice slots |
| C | `[section_off2, section_off3)` | `sub_count2` parameter records |
| D | `[section_off3, end)` | `sub_count2` × u32 index table |

**Known u8×4 flag offsets within record stride** (from cross-platform diff; per-record base + offset mod record_size): `0x2C`, `0x34`, `0x4C`, `0xA0`, `0xA8`, `0xC0` when record base is 0x20.

### 4.3 Load algorithm

1. Parse header; assert monotonic section offsets ≤ body_len.
2. `record_size = (section_off1 - data_start) / sub_count` when divisible.
3. For each event record in section A: read u32 hashes; **resolve hash via loaded wavebank clip table or ASET**.
4. Section B: each u32 is index into wavebank clip array or hash — engine validates index < clip_count.
5. Build `PalSoundBank` event map: `event_hash → { clip_hash, volume, flags, ... }`.

**CueSound(name)** → hash event name → lookup event → find clip in loaded wavebank → queue voice on mixer.

---

## 5. CueSound dispatch chain

```
CueSound("explosion_small")
  → hash(event_name)
  → soundbank->FindEvent(hash)  // section A/B
  → clip_hash from event record
  → wavebank->FindClip(clip_hash)
  → decoder(codec, data_ptr, data_size)
  → PalSoundVoice::Play() → mixer buffer
```

Simulator validates every link: event exists, clip_hash exists in paired wavebank, blob slice valid, decoder succeeds.

---

## 6. Mixer thread lifecycle

From `docs/audio_crash_analysis.md`:

| Global | VA | Role |
|--------|-----|------|
| `g_pPalSoundEngine` | `0x01176404` | Singleton; must be non-null and valid vtable |
| `g_shutdownFlag` | `0x01175FFF` | Non-zero stops mix loop |
| Phase flags | `0x019C6694` | Init state for two-phase mixer setup |

**Thread loop:** `WaitForSingleObject(5ms)` → if not shutdown → `EnterCriticalSection` → `MixSources` (vtable[1]) → `LeaveCriticalSection` → `Sleep(45)`.

**Observed crash:** Fatal error during bank load zeros/frees engine object but does not set shutdown flag or null global → mixer dereferences freed vtable.

**Simulator implication:** After consuming corrupt banks, model "engine fatally errored" if any load step would OOB or decode-fail on required clips.

---

## 7. Audio group descriptor (`type_hash 0xE5273C14`)

28-byte header + 12-byte records (`entry_hash`, `parent_hash`, `index u16`). Co-located in blocks with banks — likely **block-level manifest** listing which soundbank/wavebank hashes belong to one logical audio package (vehicle, weapon, shell).

Load order inference: parse group → load listed banks in dependency order (wavebank before soundbank).

---

## 8. PWS streaming (parallel path)

Standalone files under `data/Audios/*.pws` — **not** UCFX. PC retail: raw IMA ADPCM frames (36B mono / 72B stereo blocks). Small LE header prefix (`u16` param + `version=1`) then ADPCM stream.

`OpenStreamFile` / music / VO use PWS; embedded wavebanks use same codec bytes in `format_bytes[2]`.

---

## 9. Error modes checklist (simulator must detect)

| Condition | Engine likely behavior |
|-----------|------------------------|
| ASET block_index out of range | Lookup failure or garbage block |
| sub_entry OOB in block table | Heap corruption (documented) |
| UCFX descriptor OOB | Parse failure |
| wavebank `data_offset + data_size > body` | Buffer overread |
| codec `0x05` on PC | Unsupported → fatal audio error |
| soundbank u8×4 flags byte-swapped | Wrong routing → subtle corruption or crash at mix |
| section_off out of order / past EOF | Parse abort or OOB |
| soundbank clip hash not in loaded wavebank | Silent no-op or assert |
| CSUM mismatch | May reject chunk (if checked) |

---

## 10. Simulator mapping

| Engine step | Simulator module |
|-------------|------------------|
| Virtual disk overlay | `overlay.rs` |
| Block decompress | `sges.rs` |
| UCFX walk + CSUM | `ucfx.rs` |
| LoadWaveBank | `audio/wavebank.rs` + `ima.rs` |
| LoadSoundBank | `audio/soundbank.rs` |
| CueSound chain | `simulate.rs` cross-ref pass |
| ASET OOB | existing `aset` pass |

**Principle:** Every offset used as a pointer is exercised via `SafeSlice::slice()`; every codec payload is decoded; every hash is resolved against the overlay ASET table.

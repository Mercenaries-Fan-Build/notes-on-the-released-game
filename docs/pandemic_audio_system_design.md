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

Measured on every wavebank in retail `vz.wad`, `English.wad` and `shell.wad`; the full specification
is [`reverse_engineer/audio_code_map.md` §11.5](reverse_engineer/audio_code_map.md). The earlier table
here had `+0x00` as a count and the data offset/size at `+12`/`+16`; both were wrong.

| Region | Size | Fields |
|--------|------|--------|
| Header | 24 (40 streamed) | `version(u32)=0x1D`, `bank_hash(u32)`, `record_count(u16)`, `kind(u16)` 0 embedded / 1 streamed, `bank_hash(u32)` again, `records_offset(u32)` 24 / 40, `0(u32)`; streamed banks add the 16-byte NUL-padded `.pws` name |
| Records | `count × 36` | See below |
| Blob area | rest (embedded only) | PCM16 blobs in record order, each 16-byte aligned, zero fill between and after; the body ends on a 16-byte boundary |

**Per record (36 bytes):**

| Off | Type | Role |
|-----|------|------|
| 0 | u32 | `clip_hash` |
| 4 | u8×4 | `[0, channels, format, 0]` — format is bytes per sample (`2`, PCM16) when embedded, `4` when streamed |
| 8 | u32 | `sample_rate` |
| 12 | u32 | `data_size` in bytes (= frames × channels × 2 when embedded) |
| 16 | u32 | `frames` (samples per channel) |
| 20 | 8 | zero |
| 28 | u32 | zero when embedded; unknown when streamed |
| 32 | u32 | `data_offset` — **relative to the record's own start** when embedded; the offset in the `.pws` when streamed |

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

Measured on every soundbank in retail `vz.wad`, `English.wad` and `shell.wad`; the full specification
is [`reverse_engineer/audio_code_map.md` §11.4](reverse_engineer/audio_code_map.md). The header's
`sub_count`/`sub_count2` are the **group** and **cue** counts, and the four sections are:

| Section | Range | Content |
|---------|-------|---------|
| Groups | `[0x20, +0x14)` | the groups back to back: 64-byte single-wave groups and `0x68 + 12 × waves`-byte multi-wave groups (form word at `+0x0C`); each names its category and its `{wavebank, wave index, weight}` wave(s) |
| Group offsets | `[+0x14, +0x18)` | group count × u32, each group's offset relative to `0x20` |
| Cues | `[+0x18, +0x1C)` | the cues back to back: 24-byte single-track cues `{guid, flags, gain, length, soundbank, group index}` and variable-size multi-track cues (tracks of timed sounds, each picking one of several groups; audit map §11.7) |
| Cue offsets | `[+0x1C, end)` | cue count × u32, each cue's offset relative to the cue section |

There is no fixed record stride: the "stride" of earlier notes was the average of variable-size
groups. A cue plays a group, a group plays one of its waves; the sounddb routes a cue name to the cue.

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

## 7. Sound database (`sounddb`, `type_hash 0xE5273C14`)

Not a package manifest and not load-order data: a **cue routing table**. Specification:
[`reverse_engineer/audio_code_map.md` §11.3](reverse_engineer/audio_code_map.md).

28-byte header (`version 0x1D`, bank hash, u16 cue count, u16 category count, u32 parameter count,
three table offsets), then 12-byte cue entries `{cue guid, soundbank hash, soundbank cue index}`
sorted by guid. A per-bank sounddb has one entry per cue of the same-named soundbank; the third field
is that cue's index **in the soundbank** (not a wave index, and not a u16 "index" with a parent hash).
The global `Mercs2Globals` sounddb instead carries the 19-entry category tree
`{category, parent}` and two parameter hashes.

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

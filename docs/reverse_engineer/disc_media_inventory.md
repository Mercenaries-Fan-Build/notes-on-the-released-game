# Mercenaries 2 — "Jul 11 2008" X360 Preview: disc media inventory (movies / audio / system-update)

**Scope:** the *non-executable* media on the preview disc — Bink cinematics (`movies/*.bik`),
the PAL streaming-audio containers (`audios/*.pws`), and the `$systemupdate/` package.
**Provenance:** Mercenaries 2 World in Flames, Jul 11 2008 X360 preview ("Profile" devkit build,
Pandemic "Pangea" engine). Source image:
`game-files/Mercenaries 2 World in Flames (Jul 11, 2008 prototype)/Mercenaries 2 Preview X360 (Jul 11 2008).iso`
(XDVDFS, partition base 0). Inventory from `output/jul08_prototype/iso_filelist.txt`; every header
below was read directly from the ISO at `file_sector * 0x800`.

Related: `docs/reverse_engineer/jul08_prototype_iso.md` (the executables/WADs side of the same disc).

---

## 1. Inventory (from `iso_filelist.txt`)

The media accounts for the bulk of the disc. By raw byte size: `movies/` ≈ 3.08 GB (2.87 GiB;
`Σ 43 .bik = 3,083,594,428 B`) across 43 `.bik`, `audios/` ≈ 1.06 GB across 4 `.pws`, and
`$systemupdate/` one 8.26 MB LIVE package.

### 1.1 movies/ — 43 Bink files

Grouped by the prototype naming scheme (numeric prefix = cinematic slot; trailing letter = variant):

| Group | Files | Notes (inferred from names) |
|---|---|---|
| Boot/branding | `EA.bik`, `Pandemic.bik`, `attract.bik` | publisher/dev logos + attract-mode loop |
| Shell / main menu | `shell_mainmenu.bik`, `shell_chris.bik`, `shell_jennifer.bik`, `shell_mattias.bik` | menu backdrop + the 3 selectable PCs (Chris, Jennifer, Mattias) |
| `01_AOA_*` | `_C _J _M` | mission cinematic, 3 variants |
| `01_VIK_01` | `_01` | single variant |
| `02_AOB_*` | `_C _J _M` | the **three largest files on the disc** (C=391.9 MB, M=386.4 MB, J=381.9 MB) |
| `06_YNH_*`, `07_RHE_*`, `08_RME_*`, `09_RJE_*`, `10_BRV_*`, `12_CAR_*`, `13_AVI_*`, `14_CVI_*`, `15_ACK_*` | each `_C _J _M` | story cinematics |
| `11_SR1_S`, `11_SR2_S` | `_S` | only `_S` variant present |

**Prototype-specific observations (grounded in the file list):**
- The numbering jumps **03,04,05 are absent** and slots **06–15** are present — the `01…15`
  cinematic table is **incomplete** in this preview (missing 03/04/05 entirely; `01` exists only as
  `AOA` + a one-off `VIK_01`). (Inference from the name set in `iso_filelist.txt`.)
- The recurring `_C` / `_J` / `_M` suffixes are **per-character variants** (the same cinematic shot
  for the **C**hris / **J**ennifer / **M**attias player choice) — consistent with the three
  `shell_<name>.bik` menu files naming the same three protagonists. `11_*` and `01_VIK` carry only
  the `_S`/`_01` single variant. (Inference; the suffix↔character mapping is supported by, not proven
  by, the headers.)

### 1.2 audios/ — 4 PAL streams (`.pws`)

| File | Size (bytes) | Sector | Role |
|---|---|---|---|
| `ambience.pws` | 49,229,824 | 2579358 | world ambience bed |
| `music.pws` | 279,425,024 | 2603396 | music |
| `vo_stream.english.pws` | 385,513,472 | 2739834 | streamed VO, English |
| `vo_stream.french.pws` | 347,899,904 | 2928073 | streamed VO, French |

**Only two VO languages ship here: English and French** (matching the game XEX name
`mercs2_xenon_p_EN_FR.xex`). Retail Mercenaries 2 shipped additional localizations; this preview is
**EN+FR-only**. (Grounded: the `audios/` listing has exactly these two `vo_stream.*` files.)

### 1.3 $systemupdate/

| File | Size | Sector |
|---|---|---|
| `$systemupdate/su2008d200_00000000` | 8,257,536 | 1510972 |

First bytes (read at `1510972*0x800`):
```
4c 49 56 45 2c 53 c1 63 55 bc d1 3a f6 f3 a4 54 …   →  "LIVE,S.cU..:..T"
```
Magic `LIVE` ⇒ an **Xbox 360 LIVE-signed system-update package** (the `su2008d200` dashboard/title
update shipped on the disc so a devkit/retail box can flash to the required system version). The
`2008d200` token is a system-update build identifier. (Grounded on the `LIVE` magic; the build-token
meaning is inference.)

---

## 2. Bink video headers (read directly from the ISO)

Reading 80 bytes at `sector*0x800` and parsing the Bink container header
(`sig[3] ver[1]`, filesize@4, frames@8, largest-frame@12, width@20, height@24,
fps_num@28, fps_den@32, video-flags@36, n_audio_tracks@40):

| File | sig | frames | WxH | fps (num/den) | largest frame | audio tracks |
|---|---|---|---|---|---|---|
| `EA.bik` | `BIK` **i** | 150 | 1280×720 | 30.000 (30/1) | 95,888 | 4 |
| `Pandemic.bik` | `BIK` **i** | 720 | 1280×720 | 59.940 (2997/50) | 114,500 | 4 |
| `attract.bik` | `BIK` **i** | 2902 | 1280×720 | 29.975 (4348647/145075) | 111,888 | 1 |
| `shell_mainmenu.bik` | `BIK` **i** | 2851 | **600×720** | 30.000 | 55,160 | **0** |
| `shell_chris.bik` | `BIK` **i** | 1035 | **600×720** | 30.000 | 55,140 | 0 |
| `shell_jennifer.bik` | `BIK` **i** | 965 | 600×720 | 30.000 | 55,272 | 0 |
| `shell_mattias.bik` | `BIK` **i** | 1099 | 600×720 | 30.000 | 54,264 | 0 |
| `01_VIK_01.bik` | `BIK` **i** | 675 | 1280×720 | 29.970 (2997/100) | 106,516 | 0 |
| `01_AOA_C.bik` | `BIK` **i** | 3203 | 1280×720 | 30.000 | 168,012 | 9 |
| `02_AOB_C.bik` | `BIK` **i** | 7264 | 1280×720 | 30.000 | 196,016 | 8 |
| `11_SR1_S.bik` | `BIK` **i** | 851 | 1280×720 | 30.000 | 76,824 | 9 |
| `11_SR2_S.bik` | `BIK` **i** | 1064 | 1280×720 | 29.970 | 88,976 | 9 |
| `13_AVI_C.bik` | `BIK` **i** | 1679 | 1280×720 | 29.970 | 114,712 | 9 |

Header `filesize` field tracks `disc_size − 8` in every case (e.g. `EA.bik` hdr=9,367,648 vs
disc=9,367,656), i.e. clean intact Bink files (the 8-byte delta is Bink's standard
"size excludes sig+size words" convention).

**Codec/version:** all are `BIK` + version byte **`i`** (0x69) = **Bink1 "BIKi"** (the RAD Bink
generation, not the later "KB2" Bink2). HD **720p** throughout. (Grounded on the literal `BIKi` magic.)

**The shell movies are 600×720** (a narrow vertical strip, not 16:9) and carry **0 audio tracks** —
consistent with silent looping menu/character art panes rather than full cinematics. (Resolution +
track count grounded; the "menu art pane" use is inference.)

### 2.1 Bink audio-track tables (the multilingual mix)

Parsing the per-file track table (after the 44-byte header: `max_buffer[]`, `audio_flag[]`,
`track_id[]`; sample-rate = low 16 bits of the flag word, stereo bit `0x20000000`):

`01_AOA_C.bik` (9 tracks, all 48000 Hz, DCT-coded):
```
track0 id=0    stereo   (main mix)
track1 id=2    stereo
track2 id=3    stereo
track3 id=2001 mono
track4 id=2005 mono
track5 id=2004 mono
track6 id=2002 mono
track7 id=2003 mono
track8 id=2009 mono
```
`02_AOB_C.bik` (8 tracks, 48000 Hz): `id = 0(stereo),2,2001,2005,2004,2002,2003,2009`.

`EA.bik` (4 tracks, 48000 Hz): `id=0(st),1,2,3(st)`.
`Pandemic.bik` (4 tracks, **44100 Hz** — `flags low16 = 0xac44`): `id=0(st),1,2,3(st)`.
`attract.bik` (1 track, 48000 Hz stereo).

The story cinematics embed **8–9 audio tracks** with high `id` values in the **2000-series**
(2001–2009) plus low ids 0/2/3 — i.e. one shared stereo mix (id 0) plus a bank of mono
language/positional sub-tracks selected at runtime. The two branding clips and `attract` use the
simple 1–4 track layout. (Track ids/rates grounded; the "language sub-track bank" reading is
inference, but the 2000-series ids appearing only in the story `.bik` is concrete.)

---

## 3. `.pws` (PAL stream) format

The `.pws` files have **no RIFF/WAVE/XMA2 ASCII magic** (a scan of the first 4 KB for
`RIFF/WAVE/XMA2/fmt /data/XWB/…` found nothing). They are the **Pandemic Audio Library** streaming
container — the recovered game PE contains the literal string **`ambience.pws`** and a full `Pal*`
symbol family (`PalSoundEngineXenon`, `PalSoundMixerXenon`, `PalSoundWaveXenon`,
`PalSoundXenonVoiceManager`, `PalMusic`, `PalSoundBank`, `PalSoundWave`, …) plus the
extension string `.pws`. (Grounded: `mercs2_xenon_p.pe_full_strings.txt`.)

### 3.1 Header layout (read from the ISO)

All four share a small fixed header `u16 hdr_size`, `u16 version=1`, then a compact table; the
remainder of the file is high-entropy encoded audio:

| File | hdr_size | version | first table u16s (after size/ver) |
|---|---|---|---|
| `ambience.pws` | **28** | 1 | 27405, **508, 448, 770**, … |
| `music.pws` | **32** | 1 | 29454, **508, 448, 770**, … |
| `vo_stream.english.pws` | **52** | 1 | 64260, **1020, 128, 2580**, … |
| `vo_stream.french.pws` | **52** | 1 | 29440, **1020, 128**, … |

Observations (grounded on the parsed values):
- `version = 1` for all four.
- `ambience`/`music` share the table prefix `508, 448, 770`; the two `vo_stream` files share
  `1020, 128` and use a larger 52-byte header — i.e. **two header sub-variants**: a bed/music form
  and a VO form. (Inference from the shared constants.)
- The u16 after size/version (27405 / 29454 / 64260 / 29440) reads like a per-file
  checksum/count — high, file-specific, no obvious unit. (Marked **unconfirmed**.)

### 3.2 Payload is encoded/compressed (not plain PCM)

Shannon entropy of a 64 KB window at `+0x100` past the header:

| File | entropy (bits/byte) |
|---|---|
| `ambience.pws` | 7.907 |
| `music.pws` | 7.912 |
| `vo_stream.english.pws` | 7.816 |
| `vo_stream.french.pws` | 7.850 |
| (`01_AOA_C.bik`, for comparison) | 7.760 |

≈7.8–7.9 bits/byte ⇒ the body is **compressed/perceptually-coded audio** (on Xenon almost
certainly **XMA**, given `PalSoundWaveXenon`/`PalSoundMixerXenon` and the Bink tracks' 48000/44100
rates), **not** raw PCM. (Entropy grounded; "XMA specifically" is inference — `grep` for `xma` in
the PE strings gives only 7 case-sensitive / 18 case-insensitive hits, all noise (`*Map` symbols,
`/xmatch/*.ashx` URLs, garbage like `xmaJsg`), and there is no `XMA2` magic inside the `.pws`, so
the codec id lives inside the PAL table, not as ASCII.)

---

## 4. Most notable, concrete findings

1. **43 Bink1 720p cinematics, ≈3.08 GB** (2.87 GiB; `Σ = 3,083,594,428 B`). All are `BIKi`
   (Bink1), 1280×720 (shell movies 600×720), 30/29.97 fps; largest = `02_AOB_C.bik` =
   391,883,984 B (≈392 MB) / 7,264 frames (`02_AOB_M.bik` = 386,392,020 B / 7,139 frames is 2nd).
2. **Story cinematics carry 8–9 embedded audio tracks** (48 kHz, DCT) with a 2000-series id bank
   (2001–2009) on top of the id-0 stereo mix — a multilingual/positional track set baked into each
   `.bik`; branding/attract clips use only 1–4 tracks.
3. **VO is English + French only** (`vo_stream.english.pws` 385 MB, `vo_stream.french.pws` 348 MB),
   matching the `mercs2_xenon_p_EN_FR.xex` name — fewer languages than retail.
4. **`.pws` = Pandemic Audio Library streams** (string `ambience.pws` + `Pal*Xenon` symbols in the
   PE), `version=1`, tiny 28/32/52-byte header, then ~7.9-bit-entropy XMA-class payload — no
   RIFF/WAVE wrapper.
5. **Cinematic table is incomplete for a preview**: slots `03/04/05` are absent, only `06–15` plus
   `01` exist; `$systemupdate/su2008d200_00000000` is an Xbox-360 **`LIVE`-magic** system-update
   package bundled on the disc.

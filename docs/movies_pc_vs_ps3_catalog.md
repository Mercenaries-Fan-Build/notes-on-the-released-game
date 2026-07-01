# PC vs PS3 Movie (Bink) Catalog

Comparison of `game-files/PC-Movies/*.bik` against `game-files/PS3-Movies/*.BIK`.
Probed with `tools/ffmpeg/bin/ffprobe.exe` (Bink demuxer). Generated 2026-06-30.

## Verdict

**The rumor is true.** For the 36 story cutscenes the PS3 assets are substantially
higher quality than PC on every axis:

| Axis            | PC                 | PS3                | PS3 advantage         |
|-----------------|--------------------|--------------------|-----------------------|
| Resolution      | 1024×576 (0.59 MP) | 1280×720 (0.92 MP) | true 720p, +56% pixels|
| Video bitrate   | ~3.9 Mbps          | ~17 Mbps           | ~4.4× the bitrate     |
| Audio sample rate | 22 050 Hz        | 48 000 Hz          | 2.18× (CD-ish → DVD)  |
| Audio tracks    | 8                  | 9                  | +1 track              |
| File size (set) | 1.2 GB total       | 4.4 GB total       | ~3.9× on disk         |

Duration, frame rate (30 fps), and edit are identical per scene — same footage,
re-encoded much larger for PS3. Codec revision is `BIKi` (Bink 1, rev *i*) on both
platforms, so this is an encode-settings difference, not a format-generation one.

## Categories

### 1. Story cutscenes — PS3 clearly higher quality (36 files)

Scenes `01_AOA, 02_AOB, 06_YNH, 07_RHE, 08_RME, 09_RJE, 10_BRV, 11_SR1/SR2,
12_CAR, 13_AVI, 14_CVI, 15_ACK`, each in three variants `_C / _J / _M`
(the three playable mercs — Chris / Jennifer / Mattias — who appear in-scene).

- PC: **1024×576**, ~3.9 Mbps video, **22 050 Hz** audio, **8** audio tracks.
- PS3: **1280×720**, ~17 Mbps video, **48 000 Hz** audio, **9** audio tracks.
- Same duration / 30 fps / edit in both. PS3 files are ~4.4× larger.
- Audio track layout is the same shape on both (stereo, mono, stereo, then
  mono commentary/language stems); PS3 carries one extra mono track.

### 2. `attract` (attract-mode reel) — PS3 higher resolution

- PC: 1024×576, 3.5 Mbps, 1 audio track, 96.8 s.
- PS3: 1280×720, 8.2 Mbps, 1 audio track, 96.8 s (same length).

### 3. `EA` logo — both 720p, different encode

- PC: 1280×720, **15 fps**, 10.0 s, 12.8 Mbps, 4 audio tracks.
- PS3: 1280×720, **30 fps**, 5.0 s, 15.0 Mbps, 4 audio tracks.
- Same 720p resolution; PC is a 15 fps / 10 s encode, PS3 a 30 fps / 5 s encode
  (visually the same logo sting). PS3 bitrate slightly higher.

### 4. Menu / shell character videos — nearly matched (600×720, portrait)

`shell_chris, shell_mainmenu, shell_mattias`: **600×720** on both, ~30 fps.
PS3 bitrate ~4.19 Mbps vs PC ~3.6 Mbps — a small PS3 edge, both 0 audio tracks.

- **Anomaly — `shell_jennifer`:** PC ships a truncated stub: **2.77 s / 2.2 MB**
  (1280×720 fragment) versus PS3's full **32.2 s / 16.9 MB** (600×720) clip.
  The PC menu file is effectively a placeholder, not a downscale of the PS3 one.

### 5. Byte-identical across platforms (not re-encoded per platform)

Confirmed by SHA-256 (identical hash on both):

| File        | Res       | Notes                                   | sha256 (prefix) |
|-------------|-----------|-----------------------------------------|-----------------|
| `01_VIK_01` | 1280×720  | 29.97 fps, 0 audio, 23,619,212 bytes    | `00075073…`     |
| `Pandemic`  | 1280×720  | 59.94 fps, 4 audio, 22,380,996 bytes    | `0574408d…`     |

These two were authored once at 720p and shipped verbatim to both platforms.

### 6. PC-only files (absent from the PS3 set)

- `title_esrb.bik` — 1280×720, 4.0 s, ~149 kbps (ESRB rating card).
- `title_logo.bik` — 1280×720, 4.0 s, ~717 kbps (title logo).

PS3 has no unique-to-platform movies; every PS3 file has a PC counterpart.

## Interpretation

The PS3 disc had the room (Blu-ray, ~25–50 GB) to ship the cutscenes at native
720p and ~4.4× bitrate with 48 kHz audio. The PC release re-encoded the same
36 story scenes down to 1024×576 at ~3.9 Mbps / 22 kHz — likely to fit the DVD
footprint and to keep Bink software-decode cheap on 2008-era CPUs. Everything
that was *already* small or resolution-independent (`01_VIK_01`, `Pandemic`,
the shell menus, the EA/logo stings) is either identical or only marginally
different; the quality gap lives entirely in the pre-rendered story cutscenes.

If the goal is to upgrade the PC release's cutscenes, the PS3 `.BIK` files are
drop-in higher-quality replacements for the 36 story movies + `attract` (same
Bink rev, same durations/fps) — subject to the PC engine accepting 720p Bink
and the extra audio track / 48 kHz streams.

## PC engine compatibility (verified 2026-06-30)

**Result: the PS3 `.BIK` files are a working drop-in on PC.** Copying the full PS3
movie set into `Data\Movies\` (PC names) plays with no crash. This was expected:

- Runtime is **`binkw32.dll` v1.9a (Bink 1)**; both PC and PS3 files are Bink 1
  (`BIKi`), so same format generation.
- The engine already plays 1280×720 Bink (`EA`, `Pandemic`, `VIK`, `title_logo`
  are all 720p in the PC set; `d3d.log` shows them play). Resolution is a non-issue.
- 48 kHz / stereo audio is fine (EA/Pandemic already use it).
- Movie audio is selected **by track ID**, not by count: `PgMoviePlayer` calls
  `BinkSetSoundTrack(4, tracks)` where the language track ID comes from a switch
  (`FUN_00709d70` @ 0x00709d70): default `0x7d1`, case1 `0x7d5`, case2 `0x7d6`,
  case3 `0x7d4`, case4 `0x7d3`. Extra/missing tracks don't crash — a missing
  requested track just plays silence.

### One caveat — audio track-ID layout differs between platforms

| | Audio track IDs |
|---|---|
| PC (story) | `0x0, 0x2, 0x3, 0x7d1, 0x7d3, 0x7d4, 0x7d5, 0x7d6` (8 tracks) |
| PS3 (story)| `0x0, 0x2, 0x3, 0x7d1, 0x7d2, 0x7d3, 0x7d4, 0x7d5, 0x7d9` (9 tracks) |

PS3 **omits `0x7d6`** (a language the engine requests via case 2) and adds
`0x7d2`/`0x7d9` the engine never asks for. **English (`0x7d1`) is present and
correct on both platforms**, so English dialogue plays. A localized language that
maps to `0x7d6` would get silent/wrong dialogue with raw PS3 files (no crash).

The Ghidra decomp agent's initial "9>4-track buffer overflow" theory was WRONG:
`FUN_00873140` is the global texture registry (not audio), and PC ships working
8-track files, so >4 tracks does not crash. `BinkSetSoundTrack(4,…)` is track
*selection*, not allocation.

### If a fix is wanted (localized-audio remap or size reduction)

ffmpeg **cannot** write `.bik` (decode-only; no Bink encoder/muxer). Use **RAD
Video Tools** (free, radgametools.com) set to **Bink 1** output — it reads the PS3
`.BIK` directly. Only reasons to bother, since drop-in works:
1. Remap/rebuild audio tracks to PC's exact 8-track ID set so *localized* dialogue
   maps correctly (keep the 720p video).
2. Shrink the set (PS3 is 4.4 GB vs PC 1.2 GB) by re-encoding at a lower bitrate.
Otherwise, no conversion is needed.

## Raw per-file data

`platform | file | WxH | fps | duration_s | codec | video_bitrate | audio_tracks | a0 sr/ch`
See scratchpad `pc.txt` / `ps3.txt` for the full 42+43-row dump used above.

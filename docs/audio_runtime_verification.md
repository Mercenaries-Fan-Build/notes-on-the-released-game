# Audio Runtime Verification (Post-Transcode)

After `make dlc-port` and `make audio-verify-dlc`, confirm the game no longer hits
`PalSoundEngine::MixSources` at `0x83664E` (see [audio_crash_analysis.md](audio_crash_analysis.md)).

## Prerequisites

1. Rebuild patch with full audio transcode:
   ```bash
   make dlc-port SOURCE_WAD=<retail-vz.wad> OUTPUT=./output
   ```
2. Static gate passes:
   ```bash
   make audio-verify-dlc OUTPUT=./output SOURCE_WAD=<retail-vz.wad>
   ```
3. Deploy to game install:
   - `output/data/vz-patch.wad` → `<game>/data/`
   - `output/data/Audios/*.pws` → `<game>/Data/Audios/`
   - `output/scripts/dlc_enable.asi` → `<game>/scripts/` (if using ASI path)

**XMA note:** Standalone `.pws` and embedded XMA clips require `ffmpeg` on PATH during
`dlc_port --extract-audio` and wavebank conversion. Install ffmpeg before porting.

## x32dbg acceptance checklist

| Step | Action | Pass criterion |
|------|--------|----------------|
| 1 | Launch retail EXE under x32dbg with `output/data/` deployed | Reaches main menu without AV |
| 2 | Breakpoint on `0x0083664E` (`MixSources` vtable read) | Not hit during 60s menu idle |
| 3 | At boot, read `[0x01176404]` (`g_pPalSoundEngine`) | Non-null; `MemoryIsValidPtr` true |
| 4 | Read 32 bytes at `ECX` from global | First dword is valid vtable (non-zero `.rdata` ptr) |
| 5 | Read `[0x01175FFF]` (`g_shutdownFlag`) | Stays `0` during normal play |
| 6 | Load DLC / trigger VO stream | No crash; audio may be silent if banks empty |

## Automated crash classifier

`tools/_dbg_check.py` classifies EIP against known audio vs script crash sites.

## Failure triage

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| AV at `0x83664E` | Xbox codec or XMA still in WAD/PWS | Re-run `make dlc-port`; verify manifest has no `XMA`/`XBOX_ADPCM` |
| AV before menu | Script/ASET (unrelated) | See `dlc_pc_activation_checklist.md` |
| Silent DLC | PWS not copied to `Data/Audios` | Deploy `output/data/Audios/` |
| `ffmpeg` error during port | XMA in DLC `.pws` | Install ffmpeg; re-run `make dlc-port` |

## Related tools

| Tool | Role |
|------|------|
| `tools/dlc_audio_manifest.py` | Per-clip codec/streaming inventory |
| `tools/audio_verify_dlc.py` | CI/local gate |
| `tools/pws_xbox_to_pc.py` | ADPCM + XMA→IMA transcode |
| `tools/wad_simulator` | Engine consumption dry-run |

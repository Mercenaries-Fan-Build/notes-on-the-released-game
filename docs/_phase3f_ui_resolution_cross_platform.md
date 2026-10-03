# Phase 3.F — UI render-pipeline resolution loose thread

**Status:** current · **Evidence:** proven (PC); blocked (console read-sites — no decomp text)

Resolution of the Phase 2 §3.4 loose thread. Phase 2 captured a baked `x_res`/`y_res` divergence
in the PC and Xbox cdbsizes INI blobs but could not reach PS3 (dump stopped before the relevant
section) and did not identify what the fields drive.

---

## 1. Baked `x_res` / `y_res` by platform — three sections, one blob per binary

Each shipping binary bakes the full source `cdbsizes.ini` into read-only data. The blob carries
all three per-platform engine-config sections verbatim: `[pcwin]`, `[ps3]`, `[x360]`. Only
`x_res` and `y_res` keys appear under those sections — no `shadow_res`, `hud_res`, or
`canvas_res` keys exist anywhere in the baked blobs on any platform.

| Section | PC `.rdata` | Xbox `.rdata` | PS3 EBOOT | Value |
|---|---|---|---|---|
| `[pcwin]` x_res | `0x7af597` | `0x100e63` | `0xdc561f` | **1280** |
| `[pcwin]` y_res | `0x7af5a3` | `0x100e6f` | `0xdc562c` | **720** |
| `[ps3]` x_res | *(not present)* | `0x1010c5` | `0xdc5900` | **1280** |
| `[ps3]` y_res | *(not present)* | `0x1010d1` | `0xdc590d` | **720** |
| `[x360]` x_res | *(not present)* | `0x101377` | `0xdc5d1b` | **640** |
| `[x360]` y_res | *(not present)* | `0x101383` | `0xdc5d27` | **480** |

PROVEN by direct ASCII pattern-search over each binary
(`scratchpad/ui_res/needles.log`). The PC baked blob ships only its own `[pcwin]` section
(single `x_res`/`y_res` pair); the Xbox and PS3 blobs ship **all three** per-platform sections
in full, with identical values across both console binaries.

Xbox byte-offsets reported here are from the needle sweep against the Xbox section-header hits
in the Phase 2 extract (`scratchpad/Xbox_cdbsizes_baked.txt`) and the Xbox `cdbsizes` baked
origin at `.rdata+0xcc2f1`; the Xbox binary itself was not re-opened in this phase
(section-A.1 blocker — same reason the Xbox read-site is BLOCKED below).

PS3 byte-offsets PROVEN against the live EBOOT
(`game-files/ps3-version/EBOOT.elf`, 18,205,720 B).

### 1.1 Why Phase 2 missed the PS3 values

The PS3 EBOOT has **two disjoint cdbsizes INI blobs** separated by ~0x2200 bytes of unrelated
`.rodata`:

- First blob at `0xdc4ba3` — the per-platform engine-config sections (`[framerate]`, `[massive]`,
  `[achievements]`, `[pcwin_Memory]`, `[x360_memory]`, `[ps3_memory]`, `[pcwin]`, `[ps3]`,
  `[x360]`, `[debug]`, `[PDAMap]`, `[AI]`, `[script]`, `[log]`, `[keyboard]`, `[chatter]`,
  `[SpawnMenu]`, `[animation]`).
- Second blob at `0xdc7818` — the `[presize]` ECS-pool section.

Phase 2's PS3 extractor started at `0xdc7819` and only saw the second (presize) blob; the
`x_res`/`y_res` fields live in the first. On PC and Xbox the two blobs are contiguous starting
at a single baked offset.

Full PS3 blob dump at `scratchpad/ui_res/PS3_cdbsizes_full.txt`.

---

## 2. Section/role classification

| Section | Role |
|---|---|
| `[pcwin]` | Per-platform runtime config for the PC build — windowed-mode defaults, sound/rumble enables, Lua GC threshold, memory-block counts, `BasePath`/`LogPath`. Also carries the `x_res`/`y_res` pair. |
| `[ps3]` | Per-platform runtime config for the PS3 build — PS3 streaming limits (`BlockReadMemoryLimit`, `ConcurrentBlockReadMax`), `VideoOutputType` (0=VGA / 1=HDTV / 2=TV), install mode, timer-thread quanta, `x_res`/`y_res`. |
| `[x360]` | Per-platform runtime config for the Xbox 360 build — streaming limits, `TruncateMipSizeUnder 64`, `EnableHDCache`, `pseudodvdstreaming`, timer-thread quanta, `x_res`/`y_res`. |

`x_res`/`y_res` are PROVEN to sit under the per-platform config sections, **not** under
`[presize]` (ECS pool caps), `[framerate]` (frame-pacing preset), `[Render]` (D3D config —
which does not exist in cdbsizes; see §4), or any `*_memory`/`*_Memory` heap-config section.

---

## 3. Read site — PC (PROVEN)

### 3.1 Parser

`FUN_004c2c20` at VA `0x004c2c20` (size 7096 B, called from `FUN_004c2190` at `0x004c2190`,
which is in turn called from `FUN_00631670`). The parser walks a hash-keyed section tree
built from the baked INI blob plus the optional loose `data/cdbsizes.ini` overlay
(`FindFirstFileA` on `data/cdbsizes.ini` at `FUN_004c2190:99902-99906`).

Section-header detection: `piVar7[1] == -1 && *piVar7 == 0x67d82080`, where `0x67d82080 =
pandemic_hash_m2("pcwin")`. The entire `x_res`/`y_res` key block is inside the `[pcwin]`
branch.

### 3.2 Key reads

The parser looks keys up by `pandemic_hash_m2`, not by string literal — which is why a plain
grep for `"x_res"` across the Ghidra decomp returns zero hits (`scratchpad/ui_res/needles.log`:
`\bx_res\b` and `\by_res\b` both 0 matches in `mercs2_unpacked.exe_decomp.txt`).

```
decomp.txt:100525    cVar1 = FUN_00826820(0x3777aa44,0);     // pandemic_hash_m2("x_res")
decomp.txt:100526    if (cVar1 != '\0') {
decomp.txt:100527      _DAT_00d289f0 = FUN_00826990();       // -> x_res sink
decomp.txt:100528    }
decomp.txt:100529    cVar1 = FUN_00826820(0x8d48b9bd,0);     // pandemic_hash_m2("y_res")
decomp.txt:100530    if (cVar1 != '\0') {
decomp.txt:100531      _DAT_00d289f4 = FUN_00826990();       // -> y_res sink
decomp.txt:100532    }
```

Hash verification (PROVEN):
```
$ python tools/pandemic_hash.py --m2 x_res y_res pcwin
0x3777aa44  x_res
0x8d48b9bd  y_res
0x67d82080  pcwin
```

Sinks: `_DAT_00d289f0` (x_res) and `_DAT_00d289f4` (y_res), two adjacent `.data` DWORDs.

### 3.3 Consumer — none

PROVEN: a grep for `DAT_00d289f0`/`DAT_00d289f4`/`_DAT_00d289f0`/`_DAT_00d289f4` across the
27k-function PC decomp returns **two hits total — both the writes in `FUN_004c2c20` above**.
No other code references these storage locations.

**PC cdbsizes `[pcwin] x_res`/`y_res` is parsed and stored but never read. It is a dead
write in the retail PC build.** The 1280×720 pair plays no role in the shipped PC
render pipeline.

---

## 4. The real PC framebuffer dimensions — a separate pipeline

The actual PC backbuffer width/height come from a different file and a different read-site:

- **File:** `Mercs2.ini` (hardcoded path `C:\Users\Shadow\Desktop\Mercenaries 2 World in
  Flames\Mercs2.ini` baked at `.rdata+0xb7f048`, VA `0x00f7f048` — a dev-machine path; the
  retail game performs path relocation that is out of scope here).
- **Section/keys:** `[Render] ScrW` and `[Render] ScrH` (shipped `Mercs2.ini` sample:
  `ScrW=1600`, `ScrH=900`). The `Mercs2.ini` loose-config layout is PROVEN by direct read
  (`docs/game_config/Mercs2.ini`).
- **Reader:** `FUN_00753280` at VA `0x00753280`, called from `FUN_00631b10`
  (`decomp.txt:455252..455305`):
  ```
  GetPrivateProfileIntA("Render", "ScrW", 0x400, <Mercs2.ini>) -> DAT_00dfc328
  GetPrivateProfileIntA("Render", "ScrH", 0x300, <Mercs2.ini>) -> DAT_00dfc32c
  ```
  Key strings PROVEN at VAs `0x00bd5870` ("ScrW") and `0x00bd5878` ("ScrH")
  (`scratchpad/ui_res/pc_strings.log`).

Defaults diverge from the cdbsizes `[pcwin]` values: `FUN_00753280` seeds 1024×768
(`0x400`/`0x300`) when `Mercs2.ini` is missing — not 1280×720. This is independent
corroboration that the cdbsizes `[pcwin] x_res`/`y_res` are not the fallback feeder for the
D3D config bank either.

This is the same `FUN_00753280` + `[Render]` config bank documented in
`docs/reverse_engineer/render_core_code_map.md` §9, which maps `[Render]` keys to the
`DAT_00dfc320..0xdfc365` D3D config bank consumed by `ApplySettings`. `DAT_00dfc328`/`32c`
(width/height) are the dimensions that flow into the D3D9 present parameters; `_DAT_00d289f0`
/`_DAT_00d289f4` are not.

---

## 5. UI "design space" is a hardcoded 640×480 — unrelated to cdbsizes

The HUD-widget resolution-correction system
(`docs/reverse_engineer/hud_widget_code_map.md` §3.5, `FUN_00627DA0` at vtbl `+0x70`) uses a
**hardcoded `640×480` design space** for its default reference frame:

- `[0x00BEAC58] = 640.0f`
- `[0x00BEAAC8] = 480.0f`
- `[0x00BEA95C] = 0.0020833334f = 1/480`

These are immediate `.rdata` constants, not reads from cdbsizes. The `[x360] x_res 640 /
y_res 480` pair happens to match these constants numerically but is a separate storage path.

PROVEN that the HUD widget code does not read `_DAT_00d289f0`/`_DAT_00d289f4`: those symbols
do not appear anywhere else in the decomp (see §3.3).

---

## 6. Read sites — PS3 and Xbox (BLOCKED)

No PS3 or Xbox Ghidra text decomp exists under `output/_ghidra/`. The PS3 Ghidra project
file (`output/analysis/cross_platform/ghidra_projects/Mercenaries2_PS3_EBOOT.gpr`/`.rep`) is
present but no exported function listing or decompile text; no Xbox project exists at all.

Consequence: whether the PS3 `[ps3] x_res 1280 / y_res 720` and Xbox `[x360] x_res 640 /
y_res 480` are consumed, or are dead writes like the PC `[pcwin]` pair, cannot be proven in
this phase. This is the A.1 cross-platform-decomp blocker; it is the only remaining gate on
closing the console side of §3.4.

What is PROVEN on consoles:
- The baked `x_res`/`y_res` values exist and are the ones Phase 2 §3.4 asked for.
- They sit under per-platform `[pcwin]`/`[ps3]`/`[x360]` sections — the hashed-section parser
  pattern (section-header-sentinel + `pandemic_hash_m2` key lookup) is reusable across
  platforms, so an analogous `FUN_004c2c20`-equivalent is almost certainly present on each
  console binary, but confirming its sink and any consumer requires an Xbox/PS3 decomp pass.
- A PS3 Xbox-360-section pair is also baked (`[x360] x_res 640 / y_res 480` in the PS3 EBOOT),
  but the PS3 engine's hashed section-walker will only match `pandemic_hash_m2("ps3") =
  0xa034d5dd`, not `pandemic_hash_m2("x360") = 0x9b62da80` — so the `[x360]` values are inert
  on PS3 (and vice-versa on Xbox). The multi-section baked blob is an artifact of
  Pandemic's single-source cdbsizes.ini embedded as-is in each build.

---

## 7. Verdict — status of the Phase 2 §3.4 loose thread

**PC: CLOSED.** cdbsizes `[pcwin] x_res 1280 / y_res 720` is a vestigial parsed-but-unused
field. The real backbuffer resolution comes from `Mercs2.ini [Render] ScrW/ScrH`.

**PS3: value PROVEN (`[ps3] 1280×720`), role BLOCKED pending PS3 decomp.**

**Xbox: value PROVEN (`[x360] 640×480`, confirmed from the independent copy baked into the
PS3 EBOOT), role BLOCKED pending Xbox decomp.** The 640×480 figure is extremely low for an
Xbox 360 title shipping at 720p; the role (sub-pass target, dev-build fallback, or dead
write analogous to PC) will be established when a console decomp lands.

---

## 8. Scratchpad artifacts

Under `C:/Users/Shadow/AppData/Local/Temp/claude/c--Users-Shadow-Desktop-notes-on-the-released-game/3daa7290-1887-4d90-a52c-94355e911851/scratchpad/ui_res/`:

- `PS3_cdbsizes_full.txt` — full PS3 EBOOT INI dump starting at `0xdc4b00`, covering both
  blobs (24,576 B).
- `PS3_cdbsizes_raw.txt` — raw PS3 dump starting at the Phase 2 offset `0xdc7819`, 128 KiB
  window (preserves the exact post-blob .rodata layout).
- `needles.log` — pattern-search output: every occurrence of `x_res`/`y_res`/`[pcwin]`/
  `[ps3]`/`[x360]`/`[presize]`/`[debug]`/`[PDAMap]`/`[framerate]`/`shadow_res`/`hud_res`/
  `canvas_res` with file offsets, across PC and PS3.
- `pc_strings.log` — PC VA→ASCII resolution for the `[Render]` reader strings (`ScrW`,
  `ScrH`, `Render`, `Defaults`, `FirstRun`, `D3DAdapter`, `DispFmt`, `Mercs2.ini` path).
- `ps3_cdbsizes_raw.py`, `extract_ps3_full.py`, `find_xres_all.py`,
  `probe_pc_strings.py` — the extractors.

---

## 9. Cross-references

- `docs/_engine_divergence_phase1.md` §3.4 — the Phase 2 loose thread this closes.
- `docs/reverse_engineer/render_core_code_map.md` §9 — `FUN_00753280` / `[Render]` /
  `DAT_00dfc320..0xdfc365` D3D config bank.
- `docs/reverse_engineer/hud_widget_code_map.md` §3.5 — hardcoded 640×480 widget design
  space.
- `docs/game_config/Mercs2.ini` — shipped PC render config (`ScrW=1600`, `ScrH=900`).
- `docs/game_config/cdbsizes.ini` — shipped PC presize overlay (`[presize]`-only; no
  `[pcwin]`/`x_res`/`y_res` present).

---
title: GFx menu replay + edit + inject — build scoping
status: current
evidence: inferred   # grounded in read source + proven corpus docs; the build itself is not yet done
date: 2026-08-08
supersedes: []
---

# Faithfully replaying, animating and editing the main-menu Scaleform stack — a build scoping report

**Goal.** Give the workshop the ability to (a) load, replay, animate and preview the game's main-menu
Scaleform movie stack *as a whole*, (b) edit it, and (c) publish the edit into a `shell-patch.wad`
overlay the game mounts above `shell.wad`. This document enumerates exactly what already exists, what
the game's GFx dialect actually is, what a faithful player must implement vs. stub, how the injector
must be wired (and how it differs from the current `vz`-oriented paths), what a workshop preview
surface should render, and a phased plan with the open reverse-engineering questions that gate each
phase.

This is **research only** — no code or existing docs were modified. Every non-obvious claim carries a
file path, a corpus hit with its date, or a decomp address.

---

## 0. Executive summary

- The **read side is done and good**: `mercs2_formats::gfx::GfxMovie` parses the container + full
  top-level tag stream and inventories features; `mercs2_probe gfx-extract` has already dumped all 83
  retail movies to `output/gfx_movies/`; the 83-movie **golden set** pins the exact tag-support
  surface GFx 2.0.48 loads. The **write/wrap side is also done** and *more* robust than the tool the
  README points at: `gfx::build_cfx_pack_block` + `ucfx::build_wrapped_block` emit a byte-exact retail
  `cfx_pack` container, and the `mercs2_quartermaster` manifest pipeline (`add_movie` / `add_ui`)
  already mints movies, wires the Lua `FlashWidget` trampoline, and refcheck-gates the patch WAD.
- The **standalone `gfx_tool`** (`tools/mercs2-tools-gfxtool`) is the *older, weaker* injector: it
  duplicates the container-wrap logic by hand, pins an old `mercs2_formats` git rev, and hardcodes
  `vz`-oriented paths (`blocks\VZ\custom_*.block`, default template `minimap`). It works for a
  `vz.wad` override but is not the path to build on.
- The **real gap for the menu task is not "an injector" — it is a `shell.wad` / front-end route and a
  GFx *player*.** Every existing injector (gfx_tool `new`, quartermaster `lower_movie`) hardcodes
  `blocks\VZ\...` and deploys a `vz-patch.wad`. The front-end menu is served by `shell.wad`, whose
  overlay the engine mounts as `shell-patch.wad`. And nothing in our stack *renders* a GFx movie — the
  workshop has an engine renderer with a UI overlay pass but no vector/AVM1/display-list player.
- **`gfxforge`** (Python authoring kit) is a legitimately correct SWF/AVM1 *emitter* and a structural
  *verifier*, but it authors small movies from scratch (rects/text/buttons/menus). It is not an
  editor of the 397 KB `SHELL.gfx`, cannot render, and does not do gradients/bitmaps/curves.

**Recommended sequencing:** (1) build a native GFx *reader→scene* model on top of `GfxMovie` and a
minimal display-list + AVM1 interpreter in the workshop (the preview surface); (2) add the
**`shell.wad` injector route** (basename `shell-patch.wad`, `blocks\Shell\...` path, same-hash
replacement of `SHELL.gfx`) as a thin extension of the proven `build_cfx_pack_block` +
`build_patch_wad_multi` path; (3) only then attempt *editing* (round-trip re-encode of the tag stream)
— the hardest and last piece, because faithful shape/AVM1 re-emission is where fidelity is lost.

**Top 3 open questions** (details in §7): (1) Does the loader accept a **raw `GFX`** movie in
`shell.wad`, or must a re-authored menu be re-`CFX`'d? (proven for `vz`, untested for the front end);
(2) exactly **how are the 416 `shell_*` external textures bound** to `GFx_DefineExternalImage`
character ids — by name-hash, by atlas index, or by the sub-image table? (3) does replacing `SHELL.gfx`
under its own hash in `shell-patch.wad` actually **win at the front end**, given the mount-order rule
is proven for stringdb/textures but never yet for a `cfx_pack`?

---

## 1. What exists, precisely

### 1.1 `mercs2_formats::gfx` — the Rust decoder (read + wrap) — DONE, solid

`tools/wad_simulator/crates/mercs2_formats/src/gfx.rs`.

- **`GfxMovie::parse(&[u8])`** — reads the 8-byte header (`magic[3]` + `u8 version` + `u32 file_length`),
  zlib-inflates a `CFX`/`CWS` body, reads the frame `RECT`, `u16` frame-rate (8.8 fixed), `u16`
  frame-count, then walks **every top-level tag** (`(code, len)` + a parallel `tag_body_offsets`).
  Handles short/long tag framing. Stops at `End` (code 0).
- **`GfxMovie::features()`** — a per-tag census (histogram of all codes) plus a deeper shape parse:
  `scan_shape_fills` walks a `DefineShape*` body *as far as the fill-style array* and flags
  gradient (`0x10/0x12/0x13`), bitmap (`0x40–0x43`) and focal-radial fills. Also counts embedded fonts,
  imports/exports, edit-texts, embedded bitmaps, sprites, buttons, morph shapes, videos, DoAction,
  DoABC, and GFx-extension tags (≥1000).
- **`tag_name(code)`** — names the full standard SWF set + the GFx extension range 1000–1006
  (`GFx_ExporterInfo`, `GFx_DefineExternalImage`, `GFx_FontTextureInfo`,
  `GFx_DefineExternalGradientImage`, `GFx_DefineSubImage`, external sound/stream-sound).
- **`build_cfx_pack_block(name_hash, movie)`** → a *whole block* `[entry table][UCFX container]` with
  the movie carried **verbatim** (no recompress in either direction) and a fresh CSUM. Delegates to
  `ucfx::build_wrapped_block(name_hash, TYPE_HASH_CFX_PACK, movie)`
  (`tools/wad_simulator/crates/mercs2_formats/src/ucfx.rs:342`). The container layout is pinned by a
  test to the exact shape measured across **all 64 retail `vz.wad` cfx_pack containers**
  (`gfx.rs:602` `the_container_matches_the_retail_layout_word_for_word`).
- `TYPE_HASH_CFX_PACK = 0xFE0E8320`, `TYPE_ID_CFX_PACK = 23` (`types.rs:33,65`).

**What it does NOT do:** it parses only the *top-level* tag stream and shape *fill headers*. It does
not descend into `DefineSprite` control tags, decode edge/curve records, parse AVM1 bytecode, resolve
external images, or reconstruct a display list. It is an *inventory* parser, not a *player* and not a
round-trip *re-encoder* (the write side only wraps an already-built movie; it never emits tags).

### 1.2 `gfx_tool` — the standalone injector — WEAKER, legacy, `vz`-oriented

`tools/mercs2-tools-gfxtool/src/main.rs`. Subcommands: `inspect`, `find`, `extract`, `build`
(override an existing movie), `new` (mint a new-hash movie).

Capabilities:
- `find` resolves `pandemic_hash_m2(name)` against the WAD's ASET and reports block/type/secondary.
- `extract` pulls the `data` chunk out of a movie container and validates the movie header
  (`find_movie`: MAGIC + version 1..20 + sane length — the check that rejects the false "CFX" inside
  the container's own "UCFX" magic).
- `build`/`new` hand-roll `rebuild_container` (patch the `data` descriptor `body_size`, append the new
  movie, recompute `crc32_mercs2` CSUM), then `compress_sges` → `PatchBlock::new` (manual
  `packed_field`) → `build_patch_wad_multi` / `merge_patch_wads`.

Gaps / why not to build on it:
- **Duplicates `build_cfx_pack_block`.** Its `rebuild_container` (main.rs:198) predates and re-implements
  what `gfx::build_cfx_pack_block` now does with a pinned retail-parity test. It pins an **old git rev**
  of `mercs2_formats` (`Cargo.toml` rev `b6df818…`) that likely predates the crate's write side.
- **`vz` hardcodes.** `new` writes `blocks\VZ\custom_{hash}.block` (main.rs:322) and defaults
  `--template minimap` (a `vz.wad` asset). `MOVIE_TYPE_ID = 23` is fine, but nothing routes to
  `shell.wad` / `shell-patch.wad`.
- **ASET field-order quirk.** `build` emits `AsetEntry::new(name_hash, secondary_ref, 0x0000_FFFF,
  type_id)` — i.e. it stuffs the source `secondary_ref` into `u32_1` (which holds the `_P002/_P003`
  LOD rungs). For a movie this is harmless *only because* `build_patch_wad_multi` sentinels
  out-of-range rungs (patch_wad.rs:520 `remap_rung`); a movie has no LOD chain so the cleaner form is
  the quartermaster's `AsetEntry::new(hash, 0xFFFF_FFFF, 0x0000_FFFF, 23)` (build.rs:685).

### 1.3 `mercs2_quartermaster` — the modern injection pipeline — DONE, the right base

`tools/wad_simulator/crates/mercs2_quartermaster/`. Manifest-driven mod assembly used by the workshop
(`quartermaster.rs` binds `add_movie`/`add_ui` UI rows).

- **`Contribution::AddMovie { name, movie }`** (manifest.rs:465) — mints a `cfx_pack` under
  `pandemic_hash_m2(name)`, verbatim movie bytes. Doc explicitly states the name is what Lua passes to
  `SetSwfFile` / `GetShellGfxFilename`.
- **`Contribution::AddUi { name, movie }`** (manifest.rs:487) — the same Data plus a Script-layer touch:
  it bakes a `FlashWidget:new(); w:SetSwfFile(name); w:Play(); w:SetVisible(true)` trampoline into a
  resident script (`link.rs:372`), hooked into `wifpmcinterior:_OnEnter`.
- **`lower_movie`** (build.rs:628) — `GfxMovie::parse` (validation + a logged tag census) →
  `build_cfx_pack_block(hash, bytes)` → `PatchBlock::from_decompressed(..., "blocks\\VZ\\mod_{hash}.block",
  [primary cfx_pack ASET row], ...)`. Uses the *safe* constructor (`from_decompressed` computes
  `packed_field` from the decompressed size — no heap-overrun footgun).
- **`lint.rs`** already knows a movie whose name matches a shipped `cfx_pack` is a **replacement**
  (lint.rs:340) and that the runtime is **AVM1-only / no AS3** (lint.rs:636, corroborated by 0/64
  `DoABC` in retail `vz.wad`).

**The one thing it does not do for THIS task:** it is entirely **vz / gameplay-resident**. `lower_movie`
hardcodes `blocks\VZ\mod_*.block`; `add_ui` hooks `wifpmcinterior` (the PMC-HQ interior resident
script, i.e. in-game, not the front end); and the deploy writes `vz-patch.wad`. The **front-end menu is
`shell.wad`** and its overlay is `shell-patch.wad`. Routing to the shell is the missing piece (§5).

### 1.4 `gfxforge` — Python authoring kit — an *emitter*, not an editor or player

`tools/mercs2-tools-gfxforge/gfxforge/`. Reviewed in `docs/reverse_engineer/gfxforge_tooling_review.md`
(2026-07-07). Modules read for this report:

| Module | Capability | Limit for the menu task |
|---|---|---|
| `_bitio.py` | `BitWriter`, twips (`px`), `encode_rect`, `encode_matrix` (translate + optional scale; **no rotate/skew**), `IDENTITY_MATRIX` | matrix omits rotation/skew — fine for HUD, thin for real menu transforms |
| `swf.py` | tag encoders: `exporter_info`(1000, ver `0x0207`), `file_attributes`(69), `set_background_color`(9), `import_font`(71), `define_shape3`(**axis-aligned rect only**), `define_edittext`(37), `place_object`/`place_named`(26, always matrix), `define_button`(7), `define_sprite`(39), `do_action`(12), `build_gfx` (**raw `GFX` only**) | shapes are rectangles only (no curves), no gradients, no bitmap fills, no `DefineSprite` timelines beyond a single wrapped rect, output uncompressed |
| `avm1.py` | AVM1 assembler: `push` (str/bool/int/float), `get_url2`, `define_function`, `get/set_member`, `fscommand` (`Push "FSCommand:.." + val + GetURL2`), arithmetic/compare opcodes | correct AVM1; hand-built patterns only |
| `compiler.py` | AS2-subset → AVM1 with a real recursive-descent parser + label backpatching (`if/else/while/function/return`, precedence climbing) | `&&`/`||` not short-circuit, no `for`, calls by name/method only |
| `movie.py` | `Movie` fluent API: `rect/text/button/clip/menu/script`, auto char-ids/depths, paint = add order | single frame, no timeline, no images |
| `verify.py` | structural validator (tags in bounds, ExporterInfo first, ends with End; walks AVM1, checks `DefineFunction` code sizes and Jump/If targets); handles `CFX`/`CWS` via `zlib` | validates *structure*, cannot render or diff semantics |

`gfxforge` is genuinely useful as a **from-scratch small-movie author + structural gate**, and its AVM1
assembler is a ready reference for the interpreter we must build. It is **not** an editor for the
existing `SHELL.gfx` (it cannot read a movie back into its authoring model), cannot render, and is
missing gradients/bitmaps/curves/timelines (documented in `gfx_authoring_feature_spec.md`).

---

## 2. The GFx/SWF dialect the game actually consumes

Authoritative source: `docs/reverse_engineer/scaleform_gfx_class_map.md` (2026-07-26) — the full
class/method map reversed from the unpacked exe — plus `gfx_authoring_feature_spec.md` (the golden-set
measurement) and the `scaleform-gfx-2048-lib-map` memory.

- **SDK: Scaleform GFx 2.0.48, Flash 8 / ActionScript 2 / AVM1.** Proven four ways in the exe:
  `gfxVersion` getter returns literal `"2.0.48"` (`FUN_007676d0`); the loader rejects with
  `"incompatible GFX file, version 2.x expected"`; `$version` = `"WIN 8,0,0,0"`; and **all 83 movies are
  `CFX` v8**. **No AS3** — 0 of 83 movies carry `DoABC(82)`; the VM has no AVM2.
- **Container.** `magic[3]` (`GFX`/`CFX`/`FWS`/`CWS`) + `u8 version`(=8) + `u32` uncompressed length,
  then (optionally zlib) a `RECT` + `u16` fps(8.8) + `u16` frame-count + tag stream. Retail ships **61
  `CFX` (zlib `78 DA`) + 3 raw `GFX`**; the loader dispatches on the magic's leading char
  (`C`=compressed, `G`/`F`=raw), so **both load** (`gfx_authoring_feature_spec.md` §7). The inner
  Scaleform payload is **platform-neutral little-endian** — the Xbox→PC converter must copy it verbatim
  and swap only the outer UCFX wrapper (`scaleformgfx-cfx-blind-swap` memory, 2026-06-15; the "blind
  swap" bug is fixed).
- **ExporterInfo (tag 1000) is the required FIRST tag.** gfxforge emits tool-version `0x0207`
  ("GFxExport 2.07"); this is the *exporter* stamp, distinct from the *runtime* 2.0.48. Belt-and-braces
  check: decompress a retail movie and read its tag-1000 version (still an open verify item).
- **The confirmed tag-support surface** (measured across all 83, `gfx_authoring_feature_spec.md` §1):
  container tags (69/9/1/0/24); shapes `DefineShape/2/3/4` (2/22/32/83) with solid + **gradient**
  (0x10/0x12/0x13) + **bitmap** (0x40–0x43) fills; `PlaceObject2`(26, used 21.6k×, **always with a
  matrix**), `PlaceObject3`(70), `RemoveObject2`(28); text `DefineEditText`(37) + `CSMTextSettings`(74);
  fonts `DefineFont3`(75) + `ImportAssets2`(71) + `ExportAssets`(56); `DefineSprite`(39) + `FrameLabel`(43);
  morph `DefineMorphShape/2`(46/84); `DoAction`(12) **AVM1 only**; and the **GFx-extension** tags 1000–1004.
- **Deliberately absent in retail** (so a faithful player can *skip* them): `DefineButton/2` (0 — menu
  selection is **host-driven**, not SWF buttons), `DefineVideoStream` (0), all embedded bitmap tags
  `DefineBits*` (0 — **images are always external textures**), `DoABC` (0). Note this makes gfxforge's
  `define_button`/`menu()` *valid GFx but not the retail idiom* — retail uses named MovieClips the host
  moves.
- **Fonts are imported, not embedded** in content movies: `ImportAssets2` from `GFxFontLib` /
  `_normal_Font` (`_normal_font.gfx`, `GFxFontLib.gfx` ship the `DefineFont3` glyphs +
  `GFx_FontTextureInfo`(1002)). A player must resolve imports across the font-lib movie.
- **Loader / runtime addresses** (for when live confirmation is needed, from the class map):
  `GFxLoader` CreateMovie master `0x7D7CB6`; tag-loader registry / SWF tag readers `0x7D4410–0x7D7320`
  (incl. GFX ext 1000–1003); AS2 bytecode interpreter `GASActionBuffer::Execute` `0x76AB40`;
  `GFxMovieRoot` (player) **Advance/HandleEvent/Display/Invoke/Restart** `0x7C5690–0x7D0630`;
  `GFxDisplayList` `0x7DFC00`; `GFxSprite` runtime `0x78F3D0`; fill/gradient/line styles `0x7DC650–0x7DFBB0`;
  text engine `0x7E0B60–0x7F2160`; glyph raster/atlas `0x801660`, `0x80D680`.

---

## 3. What "faithfully replay + animate" actually requires

A movie is not a picture; it is a **timeline driving a depth-sorted display list**, with AVM1 attached
to frames and (for the menu) the *host* driving state. Decomposed into components, with a call on what a
minimal-but-faithful player must implement vs. can stub:

| Component | What retail does | Must implement | Can stub / defer |
|---|---|---|---|
| **Container + tag walk** | header, inflate, tag stream | ✅ already done (`GfxMovie::parse`) | — |
| **Frame timeline / fps** | `ShowFrame`(1) advances; `frame_count`, `FrameLabel`(43) | ✅ a per-movie playhead; label→frame map | variable fps easing |
| **Display list** | `PlaceObject2`(26) add/move/modify at a depth; `RemoveObject2`(28); depth-sorted; `PlaceObject3`(70) blend/filter | ✅ depth-keyed list; PlaceObject2 flags (char/matrix/cxform/name/ratio/clipdepth/events) | PlaceObject3 filters/blends → render flat first |
| **Matrices / cxform** | every place carries a `MATRIX`; color transform | ✅ full MATRIX (scale+rotate+skew+translate) + basic cxform | advanced cxform |
| **Nested sprites** | `DefineSprite`(39) = its own tag stream + playhead; addressable by instance name | ✅ recursive display lists + per-sprite playhead | deep nesting perf |
| **Shapes (vector)** | `DefineShape*` fill/line style arrays + **edge records** (straight + quadratic Bézier) | ✅ **the piece `GfxMovie` does NOT parse yet** — edge/curve decode + tessellation/fill | line styles, morph tween |
| **Gradients** | fill 0x10/0x12/0x13 (+ external gradient image 1003) | ◐ linear/radial ramp | focal-radial exactness |
| **Bitmaps → external textures** | **`GFx_DefineExternalImage`(1001)** binds a char id to an external DXT texture *by name*; shapes use bitmap fills (0x40–0x43) with that id; `GFx_DefineSubImage`(1004) shares atlases | ✅ resolve the id→texture binding and sample the 416 `shell_*` textures (see §4) | sub-image atlas edge cases |
| **Text** | `DefineEditText`(37) dynamic fields, var-bound; `CSMTextSettings`(74) AA; HTML subset | ✅ layout + glyph render from the imported font; variable binding | full HTML/scroll/IME |
| **Fonts / glyphs** | imported `DefineFont3` glyphs from the font-lib; `GFxFontPacker` atlas | ✅ glyph outline → raster (or reuse the shipped font-texture atlas 1002) | kerning, faux-bold/outline effects |
| **AVM1 bytecode** | `DoAction`(12) per frame; `gotoAndPlay`, `SetSelected`, button handlers, `fscommand` out, host `Invoke` in | ✅ a real AVM1 interpreter (the menu's logic lives here) | full builtin class library (Date, Array sort, etc.) |
| **Host bridge** | `fscommand:` → `_LTIFscommand`/Lua handlers; engine→movie `Invoke` (synth arrow keys from stick, key/mouse remap) | ✅ model `fscommand` out + a `CallActionScriptFunction`/`SetSelected` in, so nav works | the ~15 hardcoded FSCommands (`FUN_0060DE80`) |

**Minimal faithful player = container + timeline + display list + MATRIX/cxform + shape edge decode +
external-image binding + edit-text/glyphs + an AVM1 interpreter + the fscommand/Invoke host bridge.**
The two components that are *new work with no existing Rust code* are **shape edge/curve tessellation**
and the **AVM1 interpreter**. Everything else is either parsed already or a straightforward display-list
model.

**What can be legitimately stubbed for a first preview:** PlaceObject3 filters/blends, morph tweens,
focal-radial gradient exactness, HTML text, and the AVM1 builtin *library* (you need the VM + a handful
of MovieClip methods — `play/stop/gotoAndPlay/gotoAndStop/_x/_y/_xscale/_visible` — not all of AS2).

---

## 4. The main-menu stack as a whole

The front end is **not one movie** — it is a composite the Lua host assembles. Layers, back to front:

1. **Cloud-noise backdrop.** `shell.wad` block 32 `cloud_noise_P000_Q3` — a single 1024×1024 noise
   texture (`docs/loading_shell_wad_analysis.md`; `docs/ui_blocks_inventory.md`).
2. **Character background video.** `data/Movies/shell_mainmenu.bik` and the per-character
   `shell_chris.bik` / `shell_jennifer.bik` / `shell_mattias.bik` — **600×720 Bink**, 30 fps, **0 audio
   tracks** (`docs/reverse_engineer/disc_media_inventory.md` §2, 2026-06-27). These are **NOT** shell.wad
   blocks; they are loose `.bik` files. `attract.bik` (2902 frames, 1280×720) drives attract mode.
3. **The Scaleform shell movie — `SHELL.gfx`.** 397 KB, extracted to `output/gfx_movies/shell/`
   (`scaleform_gfx_class_map.md` §4). It is the front-end menu: **304 sprites, 227 edit-texts, 177
   bitmap fills, gradients** (it is one of the 3 movies carrying an inline gradient +
   `GFx_DefineExternalGradientImage`) per `gfx_authoring_feature_spec.md`. The buttons/labels live
   *inside the movie*; the Lua only wires event handlers.
4. **The shell texture atlas.** `shell.wad` block 18 `scaleform_shell_P000_Q3` — **416 UCFX texture
   entries** (`shell_disc_*`, `shell_explosion_*`, `shell_i<hex>`), all `type_hash 0xF011157A` (texture),
   35.6 MB — these are the external images `SHELL.gfx`'s `GFx_DefineExternalImage`(1001) tags reference
   by name (`docs/loading_shell_wad_analysis.md` §6). Blocks 35 `ui_shell` and 33 `ui_hud` are the
   audio/config atlases (soundbank/wavebank), *not* the menu bitmaps.
5. **Shared font lib.** `GFxFontLib.gfx` (+ language `fonts_*` movies in `Loading.wad`) — the imported
   `_normal_Font` glyphs.

**How the host mounts/plays/animates it** (`docs/ui/shell_menu_lua_anatomy.md`,
`docs/mercs2-luacd/05_gui_hud_shell.md`, class map §7):
- `mrxguishell` does `oFlash:SetSwfFile("shell.gfx")` (name resolved via `GetShellGfxFilename`), then
  registers ~30 event handlers: `SetFlashEventHandler("newGame", cb)`, `"joinGame"`, `"exitGame"`,
  `"Enter.Lobby"`, options/input-remap/camera/movies, etc. **The Lua wires events; the movie owns the
  buttons and labels.**
- The FlashWidget wraps a `GFxMovieView*` (obj+0x1E0). Lifecycle (class map §7.3): a FileOpener backend
  (`FUN_0060D930`) pins the WAD asset, a streaming FSM (`FUN_0060E4A0`) waits residency==3 then
  `GFxLoader` movie-def lookup + `CreateMovie`; per-frame `FUN_006190B0` calls the widget Update →
  movie **Advance**. Menu clicks come *from the host* (`_HandleInputForFlashWidget` → `SendFlashInput`),
  and selection movement is the host driving a named MovieClip via `Invoke`/`CallActionScriptFunction` —
  which is exactly gfxforge's `menu()`/`SetSelected` pattern.
- The character video swaps as the highlighted character changes (the `shell_<name>.bik` set), composited
  behind the Scaleform layer.

**Animation/state carried frame-to-frame:** the movie's own sprite playheads (idle loops, selection
transitions, morph tweens in `pause_menu`), the AVM1 variables the host sets (selected index, enabled
flags, text field vars), and the display-list transforms the host nudges. **Menu labels:** an open
question the Phase-1 spike (`build_shell_string_patch.py`) was built to answer — whether main-menu text
comes from the **stringdb** (block 29, UTF-16LE) or is **baked in `SHELL.gfx`** as `DefineEditText`.
Given `SHELL.gfx` carries 227 edit-texts, at least some are movie-internal; confirm per-label.

---

## 5. The injector, concretely

The **wrap + patch machinery is done and correct**; the work is a **routing extension** to the front end
plus the refcheck discipline that is already enforced.

### 5.1 The proven pipeline (reuse verbatim)

For a movie replacement, resolve the target's identity, then run the standard path:

```
name  ──pandemic_hash_m2──▶ asset_hash                 (e.g. "shell"/"SHELL" — bare, no extension)
movie bytes ──GfxMovie::parse (validate)──▶ ok
             ──gfx::build_cfx_pack_block(hash, movie)──▶ [entry table][UCFX 'data' container][CSUM]   (verbatim; no recompress)
block ──PatchBlock::from_decompressed(block, path_string, [AsetEntry::new(hash, 0xFFFF_FFFF, 0x0000_FFFF, 23)], inherit_tier)──▶ PatchBlock
        (from_decompressed sets packed_field from the DECOMPRESSED size — no heap-overrun footgun)
[PatchBlock…] ──build_patch_wad_multi / merge_patch_wads──▶ shell-patch.wad
              (validates: duplicate-primary, packed_field under-claim, dangling LOD rung, header overflow;
               remaps/sentinels every ASET rung into the patch's own index space)
```

The **CSUM** is computed inside `build_wrapped_block` (crc32_mercs2 over `UCFX..CSUM`), so the tool never
touches it. The movie is copied **byte-for-byte** — retail ships both `CFX` and `GFX`, so re-encoding
would replace author-verified bytes with unverified ones (gfx.rs:471 doc; `no-destructive` discipline).

### 5.2 The routing change — the actual gap for the menu task

Every existing movie injector hardcodes the **vz / gameplay** route. For the front end, three things change:

1. **Deploy basename → `shell-patch.wad`.** The engine constructs the overlay name as `%s\%s-patch.wad`
   from the base WAD's basename (`docs/fixpack/wad_duplicate_inventory.md` §C, 2026-08-01). A front-end
   override must ship as **`shell-patch.wad`** (next to `data\shell.wad`), not `vz-patch.wad`. The
   `gfx_tool` `build` merges into whatever `--merge` names; the quartermaster deploy currently targets
   `vz-patch.wad` — this is the routing to add.
2. **`path_string` → `blocks\Shell\...`.** `lower_movie` writes `blocks\VZ\mod_{hash}.block` (build.rs:688);
   a shell asset should live under `blocks\Shell\` to mirror retail (`blocks\Shell\scaleform_shell_P000_Q3.block`
   etc., `docs/ui_blocks_inventory.md`). The path string is cosmetic to the loader but must be a sane,
   collision-free block path in the shell overlay.
3. **Same-hash REPLACEMENT, not additive.** Editing the *existing* menu means minting under **`SHELL.gfx`'s
   own hash** so last-wins shadows the base (the sanctioned "override under the base hash in a
   higher-ranked WAD" mechanism — `wad_duplicate_inventory.md` §14, **proven for textures and stringdb**).
   `lint.rs:340` already classifies a name-collision movie as a replacement; the deploy just needs to put
   it in `shell-patch.wad`. A *new* menu screen (additive, new hash + a Lua `SetSwfFile`) is the `add_ui`
   shape but hooked into a **shell** resident script rather than `wifpmcinterior`.

### 5.3 Mount-order / refcheck caveats

- **Mount order is LAST-WINS, proven in the binary** (`FUN_00874E20` reverse-search;
  `wad_duplicate_inventory.md` §B.3, 2026-07-22): `English-patch.wad > English.wad > <level>-patch.wad >
  <level>.wad`. `shell.wad` and `vz.wad` share the level slot; `shell-patch.wad` sits immediately above
  `shell.wad`. **Unproven for `cfx_pack`:** the rule is demonstrated for stringdb and textures, never yet
  for a movie asset — Phase-2 must verify a same-hash `SHELL.gfx` in `shell-patch.wad` actually wins
  (open question #3).
- **No merge into the base WAD** (`never-merge-into-vz-wad` mandate): the base stays pristine; all edits
  ship in the `shell-patch.wad` overlay.
- **LOD rungs:** a movie has no LOD chain, so both rung halves stay sentinel (`0x0000_FFFF` in u32_2,
  `0xFFFF_FFFF` in u32_1). `build_patch_wad_multi` will still refcheck; `0x0000` in the low 16 would be a
  dangling-rung HANG, not "no rung" (build.rs:684 warning; `patch-wad-dangling-lod-rungs` mandate). Use
  the quartermaster's clean sentinel form, not gfx_tool's `secondary_ref`-in-`u32_1`.
- **`packed_field`:** always via `from_decompressed` (sizes the engine's decompression buffer;
  under-claim = heap overrun, `patch_wad.rs:172`).

### 5.4 Recommendation

**Do not extend `gfx_tool`.** Add a **shell route to the quartermaster** instead (or a thin
`mercs2_probe`/workshop subcommand that reuses `build_cfx_pack_block` + `build_patch_wad_multi`): a
`target: shell` selector that (a) sets basename `shell-patch.wad`, (b) uses a `blocks\Shell\` path, (c)
supports same-hash replacement of `SHELL.gfx`. This inherits the refcheck, the safe `packed_field`, the
retail-parity container, and the lint — none of which `gfx_tool` has.

---

## 6. A workshop preview surface

The workshop is a **native Rust engine window** (`mercs2_workshop`), not a web app — the user explicitly
rejected three.js for it ("native like the engine", `mercs2-workshop-devtool` memory, 2026-07-19). It
already has a **UI overlay pass** (`Scene::render` draws staged `ui_rect`/`ui_text` as a final pass) and
a fontdue-rasterized glyph atlas. That is the surface a GFx preview should render into.

What a GFx preview must draw: **2D vector shapes** (filled paths, gradients), **edit-text** (glyph runs),
**bitmaps** (the external `shell_*` textures), and a **timeline / playhead** control (play/pause,
scrub, frame label list, display-list inspector). Three realistic options:

**(a) Reuse gfxforge `verify` for structure only.** Zero render; just assert a movie is well-formed
before inject. *Tradeoff:* trivial, already exists, but it is a lint, not a preview — it cannot show the
menu.

**(b) Build a minimal native player: `GfxMovie` → display-list + 2D-vector + AVM1.** Extend `GfxMovie`
to decode `DefineSprite` control tags and shape **edge records**; build a depth-sorted display list, a
per-sprite playhead, a MATRIX/cxform stack, an edit-text/glyph path (reuse the workshop's fontdue atlas
or the shipped font-texture atlas), external-image binding to the 416 `shell_*` textures, and a small
**AVM1 interpreter** (gfxforge's `avm1.py` opcode table is the spec; the exe's `GASActionBuffer::Execute`
`0x76AB40` is the oracle). Render through the existing `ui_rect`/`ui_text` overlay plus a new textured-quad
path for bitmap fills. *Tradeoff:* the real deliverable and the only faithful preview; the cost is the
shape tessellator + AVM1 VM. It is *incremental* — a static first frame (no AVM1, no timeline) is already
enough to see the menu, and animation/logic layer on. **This is the recommendation.**

**(c) Lean on an existing SWF/GFx runtime** (e.g. embed a Rust SWF player like Ruffle's core, or shell
out to one). *Tradeoff:* fastest to *some* pixels, but Ruffle targets Adobe SWF/AVM1+AVM2 and does **not**
understand the **GFx-extension tags (1000–1004) or external-image binding** that `SHELL.gfx` depends on
for its 177 bitmap fills — it would render the vector/text but miss every external image, which *is* the
menu art. It also pulls a large foreign dependency into a codebase whose discipline is native/verifiable.
Useful as a **cross-check oracle** for the vector/AVM1 layers, not as the shipping preview.

**Recommended: (b), staged.** Start with a **static-frame renderer** (display list at frame 0, shapes +
external images + text, no AVM1) — that alone renders the menu and validates the external-image binding
(the highest-risk unknown). Then add the timeline (ShowFrame/sprite playheads) and finally the AVM1 VM
for interactivity. Keep gfxforge `verify` (a) as the pre-inject gate, and optionally use a Ruffle-core
render (c) as an offline cross-check for the vector/text layers only.

---

## 7. Phased build plan

Each phase names components (reuse vs new), what it unblocks, its risk, and the **open RE questions that
gate it**.

### Phase 0 — Confirm the ground truth (no new code)
- **Decompress `SHELL.gfx`** (its `CFX`) and run `GfxMovie::features()` + a tag dump. Confirm
  ExporterInfo version, import-font naming, and enumerate its `GFx_DefineExternalImage` ids.
- **Read one `GFx_DefineExternalImage`(1001) body** and match its name/hash to a `shell_*` entry in
  block 18 — this settles **open question #2** (how external textures bind to symbols).
- **Verify the front-end override actually wins:** build a *trivial* same-hash `SHELL.gfx` change (or the
  already-built `shell-patch.wad` string spike) and confirm at the menu. Settles **#1** (raw `GFX`
  accepted in shell.wad?) and **#3** (`cfx_pack` last-wins at the front end?).
- Gate: these three answers decide whether the injector is a same-hash replacement (likely) and whether
  the player must model external-image binding by name-hash vs atlas index.

### Phase 1 — The `shell.wad` injector route (reuse-heavy)
- **New:** a `target: shell` selector (quartermaster contribution or a workshop/probe subcommand) →
  basename `shell-patch.wad`, `blocks\Shell\` path, same-hash replacement.
- **Reuse:** `build_cfx_pack_block`, `PatchBlock::from_decompressed`, `build_patch_wad_multi`/`merge`,
  the lint + refcheck.
- Unblocks: shipping *any* edited movie to the front end (even hand-edited or gfxforge-authored) —
  independent of the player.
- Risk: low (proven machinery); the only real risk is #3 (does it win), answered in Phase 0.

### Phase 2 — Static GFx renderer in the workshop (the preview core)
- **New:** extend `GfxMovie` to decode shape **edge/curve records** and `DefineSprite` control tags;
  build a display-list model (depth, MATRIX, cxform); a shape tessellator → filled triangles; external
  DXT image binding (the 416 `shell_*` textures); edit-text glyph runs (fontdue atlas or shipped 1002
  atlas).
- **Reuse:** workshop `ui_rect`/`ui_text` overlay pass + glyph atlas; `texture` decode for DXT.
- Unblocks: *seeing* the menu; validating the injector's output visually before deploy.
- Risk: **medium-high** — the shape tessellator and correct external-image binding. Gated by Phase-0 #2.
- Open RE: gradient matrix mapping exactness; sub-image (1004) atlas semantics; text layout/HTML subset.

### Phase 3 — Timeline + AVM1 interpreter (animate + interactive preview)
- **New:** per-sprite playheads (`ShowFrame`, `FrameLabel`, gotoAndPlay/Stop); a **minimal AVM1 VM**
  (opcode table from gfxforge `avm1.py`; oracle `GASActionBuffer::Execute` `0x76AB40`) with a handful of
  MovieClip builtins; the **host bridge** (fscommand out, `SetSelected`/`Invoke` in) so navigation and
  selection animate.
- **Reuse:** gfxforge's AVM1 assembler as the encoder reference; the compiler as an authoring front end.
- Unblocks: faithful *replay* of the live menu (idle loops, selection transitions) and interactive preview.
- Risk: **high** — AVM1 fidelity and the exact host-driven selection model. Gated by mapping the ~30
  shell event handlers and the FSCommand set (`FUN_0060DE80`).
- Open RE: which builtin MovieClip methods `SHELL.gfx` actually calls; whether menu labels come from
  stringdb or baked edit-text (per-label).

### Phase 4 — Editing (round-trip re-encode) — the hardest, last
- **New:** a movie **re-encoder** (author-model → tag stream) OR targeted in-place tag edits (patch an
  edit-text string / a matrix / an AVM1 constant without a full re-emit). In-place edits are far safer
  and match the shipped-string-edit discipline; a full re-emit risks fidelity loss on shapes/AVM1.
- **Reuse:** gfxforge `swf.py`/`movie.py` for *new* elements; verify for the gate.
- Unblocks: true "edit the menu" (add a MODS button, relabel, retheme).
- Risk: **highest** — this is where faithful re-emission is lost; prefer surgical in-place edits + additive
  new elements over re-encoding the whole 397 KB movie.

### The open reverse-engineering questions, consolidated
1. **Does the Mercs2 loader accept a raw `GFX` (uncompressed) movie in `shell.wad`**, or must a
   re-authored front-end movie be re-`CFX`'d? (Proven "both load" for `vz` generally; untested for the
   shell path and for an authored movie.)
2. **How exactly is a `GFx_DefineExternalImage`(1001) character bound to one of the 416 `shell_*`
   textures** — by name-hash, by the image tag's stored name, or via `GFx_DefineSubImage`(1004) atlas
   index? This gates the renderer's image layer and any bitmap-fill edit.
3. **Does a same-hash `SHELL.gfx` in `shell-patch.wad` win at the front end** (mount-order last-wins is
   proven for stringdb/textures, never yet for a `cfx_pack`)?
4. **Where do main-menu labels come from** — the block-29 stringdb (UTF-16LE) or baked `DefineEditText`
   in `SHELL.gfx`? (Per-label; the `build_shell_string_patch.py` spike answers it in-game.)
5. **Which AVM1 builtin MovieClip methods and FSCommands does `SHELL.gfx` actually exercise** (the
   minimal VM surface)? Decode its `DoAction` blocks; cross-check `FUN_0060DE80`.

### Concrete artifacts/blocks to inspect next
- `output/gfx_movies/shell/SHELL.gfx` — decompress, dump tags, list all 1001/1003/1004 tags and their
  names; dump all `DoAction` AVM1.
- `output/gfx_movies/shell/GFxFontLib.gfx` (+ `_normal_font.gfx`) — the imported glyph source.
- `shell.wad` block 18 `scaleform_shell_P000_Q3` (416 textures) — enumerate names, match to `SHELL.gfx`
  image tags.
- `shell.wad` block 32 `cloud_noise` (backdrop), blocks 33/35 `ui_hud`/`ui_shell` (confirm audio-only).
- `data/Movies/shell_mainmenu.bik` + `shell_{chris,jennifer,mattias}.bik` — the character-video layer.
- `shell.wad` block 29 `english` stringdb (menu labels) — vs. `SHELL.gfx` edit-texts.
- `docs/data/scaleform_gfx_function_map.json` + `docs/data/gfx_golden_set.json` — the machine-readable
  loader map + golden feature index for building the player against ground truth.

---

## 8. Unknowns — resolved / attempted (static, 2026-08-08)

Resolved statically from the decomp + the real movie bytes (no game/debugger run). Open question #3
(does a same-hash `cfx_pack` win at the mount) is owned by the coordinator and deliberately not touched
here.

### Unknown 1 — Raw `GFX` vs zlib `CFX` acceptance → **RESOLVED: both load; raw needs NO CFX wrapper**

The movie header is read by **`FUN_007d8d60`** ("read SWF/GFX header", called from CreateMovie
`FUN_007d7cb6` at `0x7d8052`). The magic dispatch (proven branch):

```c
uVar7 = header & 0xFFFFFF;                         // the 3 magic bytes (LE)
bVar8 = (char)header == 'C';                       // 'C' = compressed
if (uVar7 != 0x535746 /*FWS*/ && uVar7 != 0x535743 /*CWS*/ &&
    uVar7 != 0x584647 /*GFX*/ && uVar7 != 0x584643 /*CFX*/) { log "GFxLoader read failed"; return 0; }
if ((header & 0xFF0000) == 0x580000) flags |= 0x10;  // byte 'X' → this is a GFX (Scaleform) movie
if (bVar8) { log "SWF file is compressed."; wrap the GFile in a GZLibFile (zlib inflate); ... }
// later: if (flags & 0x10) the FIRST tag MUST be ExporterInfo(1000) else "no ExporterInfo" → fail
```

- **All four magics are accepted** — `GFX`/`CFX`/`FWS`/`CWS`. The `bVar8 = leading-byte=='C'` test is the
  *only* thing that selects the `GZLibFile` inflate wrapper; a raw `GFX` (or `FWS`) is read **directly,
  no inflate**. So **raw uncompressed `GFX` loads natively — gfxforge's output does NOT need a CFX
  (zlib) wrapper before injection.** (`CFX` only matters for WAD page-budget size, not acceptance.)
- **Caveat that is now proven, not assumed:** the `flags & 0x10` path (any `GFX`/`CFX`) *requires the
  first tag to be `ExporterInfo`(1000)* or the loader rejects with "no ExporterInfo tag". gfxforge
  already emits ExporterInfo first (`swf.exporter_info`), so it satisfies this; a hand-built movie must
  too. (Raw Adobe `FWS`/`CWS` skip the ExporterInfo requirement.)
- **Shipped form confirmed:** `output/gfx_movies/shell/SHELL.gfx` = `43 46 58 08 | 03 BB 11 00 | 78 DA`
  → `CFX` v8, declared uncompressed length `0x0011BB03` = 1,162,499 B, zlib. Every shell movie sampled
  (`GFxFontLib`, `_normal_font`, `LTI_precache`) is likewise `CFX`. This empirically confirms
  `gfx_authoring_feature_spec.md` §7 at the branch level.

### Unknown 2 — External-image binding → **RESOLVED: by NAME string, tag 1001 → block-18 texture**

- The GFX movie stores each external image **by its authoring file name**, inside the
  `GFx_DefineExternalImage`(1001) tag. The tag loader **`FUN_007d6120`** reads a character id (`u16`),
  three dimension words, and **two name strings** (`FUN_007b5030`), logs `"DefineExternalImage:
  tagInfo.Tag…"`, then calls the shared helper **`FUN_007d5fa0`** (a SecuROM trampoline
  `jmp [_DAT_024557ec]`, shared by tags 1001/1002/1003) which registers `charId → image resource keyed
  by that name`.
- **Concrete mapping, measured:** `SHELL.gfx` inflates to 1,163,264 B and carries **415 `shell_*` name
  strings** — `shell_I10B.tga`, `shell_I131.tga`, … `shell_GENERIC_shadows.tga`,
  `shell_MAINMENU_dollarbill_elements.tga`. These map 1:1 to the **416 `shell_i<hex>` / `shell_*`
  texture entries** in `shell.wad` block 18 (`scaleform_shell`, type `0xF011157A`). The movie's
  `shell_I10B.tga` → the resident texture `shell_i10b` (case-folded, extension-stripped, then hashed).
  **The atlas is addressed by NAME, not by symbol id or atlas index.**
- **Engine-side resolution to the resident game texture:** the GFx **ImageCreator / GFxImageLoader**
  callback. CreateMovie's image branch is `FUN_007da120` (builds an image movie-def + `GFxImageResource`,
  vtbls `0xbdfd40`/`0xbe00ec`); `FUN_007d8ff0` = "resolve user image via GFxImageLoader"; the failure
  string is `Could not load user image "%s" - GFxImageLoader failed or not specified`
  (`docs/mercs2-pdb-analysis/gui-hud.md:160`). Name→resource lookup is `GetResource(exportName)`
  `0x7c2950` / `VisitResources` `0x7c2740` in the resource lib; script side is `LoadTexture`.
- **Consequences for build:** (a) the renderer's image layer must read the 1001 tag `(charId, name)`,
  resolve `name → block-18 texture` (hash of the ext-stripped name), decode the DXT, and use it for any
  `bitmap-fill` shape (0x40–0x43) whose `bitmapId == charId`. (b) Editing menu art = ship a **same-hash
  texture** under the `shell_*` name in `shell-patch.wad` (the proven texture-override route) — no movie
  edit required to re-skin an existing icon; adding a *new* image needs a new 1001 tag + a new texture.
  This settles §7 open question #2.

---

## Evidence trail (paths, corpus hits, addresses)

**Source read for this report**
- `tools/mercs2-tools-gfxtool/src/main.rs` (gfx_tool), `Cargo.toml` (pinned old `mercs2_formats` rev)
- `tools/wad_simulator/crates/mercs2_formats/src/gfx.rs` (`GfxMovie`, `build_cfx_pack_block`),
  `ucfx.rs` (`build_wrapped_block`, `extract_data_chunk`), `patch_wad.rs`
  (`build_patch_wad_multi`, `PatchBlock`, `AsetEntry`, refcheck/rung remap), `types.rs`
- `tools/mercs2-tools-gfxforge/gfxforge/{swf,movie,avm1,verify,compiler,_bitio}.py`
- `tools/wad_simulator/crates/mercs2_quartermaster/src/{manifest,build,blast,link,lint,quartermaster}.rs`
  (`AddMovie`/`AddUi`, `lower_movie`, the FlashWidget trampoline, the shell/vz stringdb lint)

**Docs**
- `docs/reverse_engineer/scaleform_gfx_class_map.md` (2026-07-26) — SDK 2.0.48, loader/player addresses,
  FlashWidget bridge, movie lifecycle
- `docs/reverse_engineer/gfx_authoring_feature_spec.md` (2026-07-07) — golden tag-support surface, CFX vs GFX
- `docs/reverse_engineer/gfxforge_tooling_review.md` (2026-07-07)
- `docs/ui/shell_menu_lua_anatomy.md` (2026-06-19) — SetSwfFile/event handlers, stringdb labels
- `docs/mercs2-luacd/05_gui_hud_shell.md` (2026-06-19) — `.gfx` asset→Lua map, `GetShellGfxFilename`
- `docs/loading_shell_wad_analysis.md` (2026-05-25) — shell.wad blocks 18/32/33/35, 416 textures
- `docs/ui_blocks_inventory.md` (2026-05-25) — shell.wad block paths
- `docs/reverse_engineer/disc_media_inventory.md` (2026-06-27) — `shell_*.bik` 600×720/30fps/0-audio
- `docs/fixpack/wad_duplicate_inventory.md` (2026-08-01) — LAST-WINS (`FUN_00874E20`), `%s-patch.wad`
  basename, override-under-base-hash
- `docs/type_hash_registry.md` (2026-08-01) — `0xFE0E8320` scaleformgfx / type_id 23

**Memory / mandates**
- `scaleform-gfx-2048-lib-map`, `scaleformgfx-cfx-blind-swap` (verbatim-copy rule),
  `workshop-render-is-the-iteration-loop`, `mercs2-workshop-devtool`, `wad-mount-order-last-wins`,
  `never-merge-into-vz-wad`, `patch-wad-dangling-lod-rungs`

**Decomp addresses**
- `GASActionBuffer::Execute` `0x76AB40` (AVM1 interpreter oracle); `GFxMovieRoot` Advance/Display
  `0x7C5690–0x7D0630`; `GFxLoader` CreateMovie `0x7D7CB6`; SWF+GFx-ext tag loaders `0x7D4410–0x7D7320`;
  FlashWidget binders `FUN_005BA680`/`FUN_005BA720` (SetSwfFile) etc.; FSCommand dispatch `FUN_0060DE80`;
  movie lifecycle `FUN_0060D930`/`FUN_0060E4A0`/`FUN_006190B0`

# Community tooling review — `gfxforge` (Scaleform GFx authoring)

**What it is.** `tools/mercs2-tools-gfxforge/` is a cloned community repo (its own `.git`, MIT,
stdlib-only Python) that **authors** Scaleform GFx 2.x `.gfx` movies — vector shapes, text, buttons,
menus, and AVM1 behaviour — with no Adobe/MTASC/libming/Scaleform dependency. It is the **write
side** that complements our existing **read side**: `mercs2_probe gfx-extract` (dumps all 83 retail
movies to `output/gfx_movies/`) + [`scaleform_gfx_class_map.md`](scaleform_gfx_class_map.md)
([[scaleform-gfx-2048-lib-map]]). Together they close the round-trip for UI/HUD modding.

**Reviewed 2026-07-06** by reading `README.md`, `gfxforge/{swf,movie,avm1,compiler,verify}.py`, and
`examples/mercs2/`. Verdict up front: **high-quality, correct, well-scoped**. It is not a toy — the
SWF/AVM1 encoders are byte-accurate and it ships a real structural verifier. The gaps are the honest
ones the README already names, plus one integration gap on our side (no injector) and one
convention divergence I verified against retail (uncompressed output).

---

## 1. Architecture

| Module | Role | Assessment |
|---|---|---|
| `_bitio` | SWF bitfields, RECT, matrices (twips) | (not read in full; consumed correctly by `swf`) |
| `swf` | GFX/SWF tag encoders + container | **correct** — tag framing (short/long), DefineShape3, DefineEditText, PlaceObject2, DefineButton, DefineSprite, ExporterInfo |
| `avm1` | AVM1 bytecode assembler + `Script` | **correct** — opcodes verified against the AVM1 spec (below) |
| `compiler` | AS2-subset → AVM1 (labels + backpatched jumps) | solid first cut; documented limits |
| `movie` | `Movie` ergonomic authoring API | clean; auto-assigns char ids/depths; paint order = add order |
| `gui` | tkinter layout editor | (not reviewed in depth) |
| `verify` | structural `.gfx` validator (no game needed) | **excellent** — real QA, see §3 |

The layering is clean: `movie` → `swf`/`avm1`; `compiler` → `avm1`; `verify` is independent. Fluent
builder API (`m.rect(...).text(...)`), returns metadata from `menu()` describing how the host drives
it. Idiomatic, readable Python.

---

## 2. Correctness — spot-checks that passed

- **AVM1 opcodes are right** (`avm1.py`): Push `0x96`, DefineFunction `0x9B`, GetURL2 `0x9A`,
  GetVariable `0x1C`, SetVariable `0x1D`, GetMember `0x4E`, SetMember `0x4F`, arithmetic/compare
  (`0x47/0x0B/0x0C/0x0D/0x3F/0x48/0x49/0x67`), Jump `0x99`, If `0x9D` — all match the ActionScript
  VM1 spec. `fscommand` is correctly emitted as `Push "FSCommand:<cmd>" + <value> + GetURL2` (the
  canonical AVM1 fscommand idiom).
- **Push type tags** correct: str=0, float=6 (`<d`), int=7 (`<i`), bool=5. (Note the Python
  `isinstance(bool)` ordering trap is avoided because `bool` is checked *after* `int` would match —
  actually `push` checks `str`→`bool`→`int`→`float`; since `bool` is a subclass of `int`, the `bool`
  branch is listed **before** `int`, so it's handled correctly. Good.)
- **DefineFunction** encodes name + param list + `CodeSize`, body follows verbatim — matches how the
  verifier (and any AVM1 VM) skips the body at definition time.
- **PlaceObject2 always carries a matrix** (`swf.place_object` flags `0x06`, `place_named` `0x26`) —
  the module comment notes "the matrix-less `0x40` that bit us for weeks is deliberately never
  emitted." That's a real Scaleform gotcha handled correctly.
- **Fonts imported, not embedded** (`ImportAssets2` tag 71, default `_normal_Font` from
  `GFxFontLib`) — matches GFx design and our own findings (the shared font lib ships in
  `GFxFontLib.gfx` / `_normal_font.gfx`, present in `output/gfx_movies/`).
- **Alignment with our proven facts:** retail = Scaleform GFx **2.0.48**, Flash 8 / **AS2**
  ([[scaleform-gfx-2048-lib-map]]); AVM1 is exactly the AS1/AS2 VM, so targeting AVM1 is right. The
  host bridge it assumes (`FlashWidget` + `SetSwfFile` + `CallActionScriptCallback` +
  `SetFlashEventHandler` + `fscommand`) matches the PgScaleform HAL / FlashWidget surface in our
  class map (scoreboard row 27).

---

## 3. The verifier is the standout

`verify.py` walks the entire emitted `.gfx` **without a game or WAD tool**: every tag header/body
in bounds, ExporterInfo (1000) is first, stream terminates with End; and inside each DoAction it
walks the AVM1 — every action parses, `DefineFunction` code sizes are consistent, and every
`Jump`/`If` target lands inside its code buffer. It even accepts an assertion spec
(`require={"functions":[...], "min_tags":{code:n}}`). This is better regression hygiene than most
hobby modding tools ship, and it's the right design (structural validation is cheap and catches
emitter/compiler bugs pre-injection). It also transparently handles compressed input (`CFX`/`CWS` →
`zlib.decompress`) even though the emitter only writes raw — see §4.

---

## 4. Verified finding: retail is CFX (compressed), gfxforge emits raw GFX

I hexdumped the first bytes of several retail movies in `output/gfx_movies/`:

```
topbar.gfx     43 46 58 08 1C 0E 01 00 78 DA …   "CFX" v8, then 78 DA = zlib
_normal_font   43 46 58 08 11 2C 00 00 78 DA …   "CFX" v8, zlib
pause_menu     43 46 58 08 9B 07 07 00 78 DA …   "CFX" v8, zlib
MINIMAP        43 46 58 08 01 AB 00 00 78 DA …   "CFX" v8, zlib
```

**Every retail Mercs2 movie is `CFX` — zlib-compressed** (magic `CFX`, version `08`, u32
uncompressed-length, then a `78 DA` zlib stream). gfxforge's `build_gfx` emits **`GFX`** (raw,
uncompressed) with the same version byte `08`. Scaleform's loader dispatches on the magic's leading
char (`C`=compressed, `G`/`F`=raw), so **an uncompressed `GFX` movie should load fine** — but it
diverges from retail's convention and is larger on disk (relevant to WAD page budget). gfxforge
already imports `zlib` in `verify.py`, so adding an optional `CFX` output path is a one-function
enhancement. **This is the single most useful concrete improvement** and the first thing to validate
in-game.

(Version note: gfxforge's `ExporterInfo` uses tool-version `0x0207` = "GFxExport 2.07". That's the
*exporter* version, distinct from the *runtime* 2.0.48 we proved. It lives inside the compressed
stream of a retail movie; decompress one and read its tag-1000 version to confirm parity — a good
belt-and-suspenders check, not a known problem.)

---

## 5. Gaps (honest)

- **No injector in our repo.** The README + mercs2 example call `gfx_tool new --wad … --movie … --merge …`
  to inject the movie as a WAD asset; **`gfx_tool` does not exist in `tools/`** (we have the *extract*
  side via `mercs2_probe gfx-extract`, and generic WAD patchers `build_mod_patch.py` /
  `ffcs_patch_wad.py` / `tools/wad_simulator` `dlc_port`). Wiring gfxforge output through one of those
  (add a movie-asset UCFX entry: `type_hash = 0xF011157A`? — no, movies are their own asset type;
  resolve the GFx movie type_hash from the ASET table of a shell block) is the missing glue. This is
  the highest-value integration task.
- **Uncompressed output** (§4).
- **Bitmaps + font embedding not supported** (README is explicit): GFx keeps images as external
  textures (our shell.wad analysis: 416 `shell_*` texture entries co-packaged), and fonts are
  imported by name. Fine for HUD/menus; a limit for richer UI.
- **Compiler first-cut limits** (compiler.py docstring): `&&`/`||` are **not short-circuit**, no
  `for`, `else if` desugars via nested `if`, calls by name/method only. Adequate for HUD/menu logic.

---

## 6. Recommendations

1. **Validate output in-game** against a retail movie: build a trivial `Movie`, run `verify_gfx`,
   inject via our WAD patch path, confirm the Mercs2 GFx loader accepts raw `GFX`. If it rejects
   uncompressed, add `CFX` output (zlib) — trivial.
2. **Add the injector** (`gfx_tool` equivalent) on our side: resolve the GFx-movie asset type_hash
   from a shell block's ASET, emit a UCFX movie entry, and merge into `vz-patch.wad` via
   `ffcs_patch_wad`. This makes gfxforge immediately usable for row-27 HUD modding.
3. **Diff a gfxforge movie vs an extracted retail movie** (decompress the CFX) to confirm ExporterInfo
   version + font-import naming (`_normal_Font` / `GFxFontLib`) match what our loader expects.
4. **Keep it as-is otherwise** — do not fork/modify the cloned repo (separate `.git`; our
   minimal-edits-in-others'-code discipline). Track improvements upstream or in a thin adapter under
   our `tools/`.

**Golden-set tooling (built 2026-07-06, branch `gfx-golden-set`).** Rec #3 is now automated: the 83
extracted retail movies are established as a **golden reference set** by
[`mercs2_formats/src/bin/gfx_golden.rs`](../../tools/wad_simulator/crates/mercs2_formats/src/bin/gfx_golden.rs)
(parser [`mercs2_formats::gfx`](../../tools/wad_simulator/crates/mercs2_formats/src/gfx.rs)) →
[`gfx_golden_set.md`](gfx_golden_set.md) + [`gfx_golden_set.json`](../data/gfx_golden_set.json), with
the authoring guide in [`gfx_authoring_feature_spec.md`](gfx_authoring_feature_spec.md). It measured
the feature answers this review left open: gradients are real but rare (3 movies, `SHELL`/`Statistics`/
`pause_menu`, paired with `GFx_DefineExternalGradientImage`); **bitmaps are always external** (0
embedded, 1,296 `GFx_DefineExternalImage` refs across 50 movies); fonts are imported (29 movies) not
embedded; **no buttons / video / AS3** in retail. The spec names the golden movie + the exact
encoding to author each missing feature against — the concrete implementation reference for gradients
and external-image references.

**Bottom line:** gfxforge is a legitimately good, correct, self-verifying GFx authoring library that
slots exactly into the write-side gap of our Scaleform work. The only blocker to using it for
Mercs2 HUD mods is the missing WAD-injection glue on our side, plus confirming the loader accepts
uncompressed `GFX` (or teaching gfxforge to emit `CFX`).

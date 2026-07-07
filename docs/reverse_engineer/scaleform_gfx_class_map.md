# Scaleform GFx 2.0.48 — full class/method map of the embedded UI middleware

**Scope:** the complete Scaleform GFx static library linked into `Mercenaries2.exe` (PC retail,
unpacked image `output/_ghidra/securom_dump/mercs2_unpacked.exe`, base 0x400000), reversed from the
27k-function Ghidra decomp (`output/_ghidra/mercs2_unpacked.exe_decomp.txt`), plus the Pandemic
engine integration layer that drives it.

## 1. SDK version — settled

The SDK is **Scaleform GFx 2.0.48**, targeting **Flash 8 / ActionScript 2**. Proof (all in the
unpacked exe):

| Evidence | Where |
|---|---|
| `gfxVersion` AS property returns literal `"2.0.48"` | `FUN_007676d0` (System/capabilities getter) |
| `Error: GFxLoader read failed - incompatible GFX file, version 2.x expected` | .rdata (loader version check) |
| `$version` = `"WIN 8,0,0,0"`, AS2-only builtin classes (`ExternalInterface`, `MovieClip`, `LoadVars`, `AsBroadcaster`, no AVM2) | builtin registrar `FUN_007677f0` + class table @~0xBDD800 |
| Movie files are `CFX` (compressed GFx) with SWF version byte 0x08 | all 83 extracted movies |

`docs/ui/main_menu_structure.md` previously said "confirmed GFx 3.x SDK" — that was wrong
(GFx 3.0 shipped in 2009, after the game's Aug 2008 release) and has been corrected.

## 2. Library layout in the exe

- **Code region:** `0x75F000 – ~0x812000` (contiguous static lib, **2,493 functions**), bracketed
  by exported anchors: `GRefCountBaseImpl` ctors @0x75F430/0x75F470 at the bottom, `GColor`
  HSV/HSI methods @0x806240–0x806BD0 near the top.
- **String table:** .rdata VA ≈ `0xBD8000 – 0xBDF000` (= file offset + 0x400000): AS2 opcode
  disassembler templates, blend-mode names, TextField/filter property names, GFxLoader/import
  errors, builtin class names.
- **No RTTI** for any G* class (392 RTTI descriptors in the exe, none Scaleform) — the lib was
  compiled without RTTI; attribution relies on exports, strings, and object-file contiguity.
- **63 DLL exports** (below) carry real names in the decomp; everything else was `FUN_`.
- **COMDAT folding:** identical bodies were merged by the linker, some landing far outside the
  region: `GZLibFile::Write` == `CopyFromStream` @0x63FEA0, `GMatrix2D::Swap` @0x402C20,
  `GMatrix2D::GetX` @0x6E72F0, `GZLibFile::ChangeSize` @0x96DB90.
- Pandemic implemented Scaleform's renderer interface as its own HAL, **`PgScaleform`**
  (shader objects `PgScaleformStripVP.sho`, `PgScaleformGlyphVP.sho`, `PgScaleformStripFP.sho`,
  `PgScaleformTextTextureFP.sho`, `PgScaleformCxformTexMultiplyFP.sho`,
  `PgScaleformSolidColorFP.sho`; strings @0xBACFBC–0xBAD0DC, class name @0xD2892C).

## 3. The 63 exports (ordinal → VA → demangled)

| # | VA | Method |
|---|---|---|
| 1 | 0x00776BF0 | `GImage::GImage(GImageBase const&)` |
| 2 | 0x00776CF0 | `GImage::GImage(GImageBase::ImageFormat, ulong, ulong)` |
| 3 | 0x00776B50 | `GImage::GImage()` |
| 4 | 0x0075F470 | `GRefCountBaseImpl::GRefCountBaseImpl(GRefCountImpl*, GRefCountImpl*)` |
| 5 | 0x0075F430 | `GRefCountBaseImpl::GRefCountBaseImpl()` |
| 6 | 0x007FD9D0 | `GZLibFile::GZLibFile(GFile*)` |
| 7 | 0x00779740 | `GFxLoader::~GFxLoader()` |
| 8 | 0x00776DD0 | `GImage::~GImage()` |
| 9 | 0x0075F4C0 | `GRefCountBaseImpl::~GRefCountBaseImpl()` |
| 10 | 0x007FDA40 | `GZLibFile::~GZLibFile()` |
| 11 | 0x007C55D0 | `GZLibFile::`vector deleting dtor closure (`??_F`) |
| 12 | 0x0075F860 | `GMatrix2D::Append` |
| 13 | 0x00806270 | `GColor::Blend` (static) |
| 14 | 0x007FDBC0 | `GZLibFile::BytesAvailable` |
| 15 | 0x0096DB90 | `GZLibFile::ChangeSize` (folded) |
| 16 | 0x007FDCB0 | `GZLibFile::Close` |
| 17 | 0x00806BD0 | `GColor::ConvertHSIToRGB` |
| 18 | 0x00806AB0 | `GColor::ConvertRGBToHSI` |
| 19 | 0x0063FEA0 | `GZLibFile::CopyFromStream` (folded, == Write) |
| 20 | 0x0075FD40 | `GMatrix2D::DoesFlip` |
| 21 | 0x0075FE50 | `GMatrix2D::EncloseTransform` |
| 22 | 0x00772570 | `GZLibFile::Flush` (folded) |
| 23 | 0x00806240 | `GColor::Format` |
| 24 | 0x0075F9E0 | `GMatrix2D::Format` |
| 25 | 0x0075FD70 | `GMatrix2D::GetDeterminant` |
| 26 | 0x007FDB70 | `GZLibFile::GetErrorCode` |
| 27 | 0x007FDAD0 | `GZLibFile::GetFilePath` |
| 28 | 0x008068E0 | `GColor::GetHSI(int*,int*,int*)` |
| 29 | 0x008069F0 | `GColor::GetHSI(float*,float*,float*)` |
| 30 | 0x008065B0 | `GColor::GetHSV(int*,int*,int*)` |
| 31 | 0x00806730 | `GColor::GetHSV(float*,float*,float*)` |
| 32 | 0x007FDB20 | `GZLibFile::GetLength` |
| 33 | 0x0075FD80 | `GMatrix2D::GetMaxScale` |
| 34 | 0x0075FE30 | `GMatrix2D::GetRotation` |
| 35 | 0x006E72F0 | `GMatrix2D::GetX` (folded) |
| 36 | 0x0075FDF0 | `GMatrix2D::GetXScale` |
| 37 | 0x0075FDE0 | `GMatrix2D::GetY` |
| 38 | 0x0075FE10 | `GMatrix2D::GetYScale` |
| 39 | 0x0075F6F0 | `GMatrix2D::IsValid` |
| 40 | 0x007FDAF0 | `GZLibFile::IsValid` |
| 41 | 0x007FDB60 | `GZLibFile::LGetLength` |
| 42 | 0x007FDC90 | `GZLibFile::LSeek` |
| 43 | 0x007FDB10 | `GZLibFile::LTell` |
| 44 | 0x0075F7A0 | `GMatrix2D::Prepend` |
| 45 | 0x007FDB80 | `GZLibFile::Read` |
| 46 | 0x007FDC00 | `GZLibFile::Seek` |
| 47 | 0x00806890 | `GColor::SetHSI(int,int,int)` |
| 48 | 0x00806950 | `GColor::SetHSI(float,float,float)` |
| 49 | 0x00806340 | `GColor::SetHSV(int,int,int)` |
| 50 | 0x008064A0 | `GColor::SetHSV(float,float,float)` |
| 51 | 0x0075F770 | `GMatrix2D::SetIdentity` |
| 52 | 0x0075FC30 | `GMatrix2D::SetInverse` |
| 53 | 0x0075F930 | `GMatrix2D::SetLerp` |
| 54 | 0x0075F4F0 | `GRefCountBaseImpl::SetRefCountMode` |
| 55 | 0x007FDBA0 | `GZLibFile::SkipBytes` |
| 56 | 0x00402C20 | `GMatrix2D::Swap` (folded) |
| 57 | 0x007FDB00 | `GZLibFile::Tell` |
| 58 | 0x0075FA70 | `GMatrix2D::Transform` |
| 59 | 0x0075FB10 | `GMatrix2D::TransformByInverse` |
| 60 | 0x0075FAC0 | `GMatrix2D::TransformVector` |
| 61 | 0x0063FEA0 | `GZLibFile::Write` (== CopyFromStream) |
| 62–63 | — | unnamed export slots (name pointers empty in the table) |

Why the exports exist at all: these six classes (`GFxLoader`, `GImage`, `GMatrix2D`, `GColor`,
`GZLibFile`, `GRefCountBaseImpl`) are the GFx *public utility* surface — the game links GFx
statically but re-exports them, likely a build-system artifact of Scaleform's own `GFx*.dll`
project settings.

## 4. Movie inventory (all .gfx extracted)

`mercs2_probe gfx-extract [outdir] [--wad <path>]` walks every block entry table for the
`scaleformgfx` type hash `0xFE0E8320`, locates the Scaleform magic (a constant **40-byte engine
prefix** precedes it in every chunk) and writes the movie **verbatim** (they are platform-neutral
little-endian; see the CFX blind-swap RCA). Extracted set (83 movies):

| WAD | Count | Contents |
|---|---|---|
| vz.wad | 64 → `output/gfx_movies/` | MINIMAP, Map, Credits, every `*Con*_briefing`, fanfare_*, POI_*_Introduction, snatch_moment, … |
| shell.wad | 16 → `output/gfx_movies/shell/` | **SHELL.gfx** (397 KB front-end menu), **GFxFontLib.gfx** (shared font-library movie — the GFxFontLib mechanism), pause/dialog movies (some hash-only names) |
| Loading.wad | 3 → `output/gfx_movies/loading/` | loadingscreen_standalone, fonts_enext, fonts_ru |
| English.wad, vz-patch.wad | 0 | — |

All verify as `CFX` v8 + zlib (`78 DA`). File header: `CFX` `08` + u32-LE uncompressed length,
then one deflate stream to EOF (trailing UCFX bytes after the stream are ignored by readers).

## 5. Per-function class map

Reversed by an 11-agent fan-out over `0x75F000–0x812000` (10 slices) plus the engine integration
layer. **2,596 functions classified** (2,494 in the GFx lib region — essentially every function in
the band — plus 102 engine-side). Full machine-readable table (addr, ghidra_name, class, role,
confidence, evidence, trampoline): **`docs/data/scaleform_gfx_function_map.json`**. Region
confidence skews medium; low-confidence rows are SecuROM-mangled stubs and thin-evidence template
COMDATs.

### 5.1 Subsystem address map (GFx library)

Object files link contiguously, so each subsystem is a clean address band:

| Span | Subsystem |
|---|---|
| 0x75F040–0x7600CF | **GKernel utilities** — GRefCountBaseImpl (exports), GRenderer::Cxform, GMatrix2D (14 exports) |
| 0x7600D0–0x763FDF | **AS2 VM value/environment core** — GASValue (ToString/ToNumber/arith/relational opcodes), GASObject helpers, GASLocalFrame, the Invoke family (GFxMovieRoot::Invoke/InvokeParsed) |
| 0x763FE0–0x76745F | **AS2 global builtins** — GASMath (18 natives), GASKey/GASKeyAsObject, GASGlobalContext globals (trace/parseInt/escape/ASSetPropFlags) |
| 0x7676D0–0x76A2BF | **GASGlobalContext** — `gfxVersion`→"2.0.48", the 10.6 KB builtin-class registrar (FUN_007677f0), class-registry lookup |
| 0x76A2C0–0x772280 | **GASActionBuffer** — the AS2 bytecode interpreter (Execute @0x76AB40), ProcessDeclDict, DoAction/DoInitAction, the disassembler (Disasm @0x771B80), and GASEnvironment variable/path resolution |
| 0x772290–0x776330 | **GTL templates + GASStringManager** — ghash/garray member-table COMDATs, string interning (const-flag 0x40000000, leak reporter) |
| 0x7763C0–0x777C90 | **GImage + codecs** — pixel/mip accessors, exported ctors, ReadTga, ReadDDS (header + swizzle) |
| 0x777CA0–0x778FD0 | **GFxString / GFxWStringBuffer** — UTF-8 refcounted string (ASCII-flag bit31, ToUpper/CompareNoCase, HTML escape) |
| 0x7790D0–0x77A960 | **GFxLoader front + GFxFontMap** — tag-loader registry, OpenFile/URLBuilder, ~GFxLoader, GFxResource refcounting, GFxFontMap |
| 0x77A9D0–0x77BB60 | **GFxResourceLib / GFxResourceWeakLib** — ResourceSlot lifecycle, BindResourceKey FSM (Waiting/Resolved/Added/Error), lock-free AddRef CAS |
| 0x77BBD0–0x77C300 | **GAllocator (GMemory)** — binned engine allocator; *heap pages are `PAGE_EXECUTE_READWRITE`* |
| 0x77C410–0x780210 | **GFxCharacter / GFxASCharacter** — the display-object base + AS side: matrix/cxform/world-transform, Set/GetStandardMember, clip-event hash, OnEvent/ExecuteEvent, GFxCharacterHandle |
| 0x780A90–0x78B5D0 | **AS2 builtins (batch 2)** — GFxGenericCharacter, GASAsFunctionObject::Invoke (function2 preload), Function.apply/call, Number, GASObject core (SetMemberRaw/GetMemberRaw/watch/registerClass), Stage, AsBroadcaster, Boolean |
| 0x78B6B0–0x78F130 | **GASArrayObject** — sort/sortOn/splice/concat + quicksort cores, GASArrayProto/CtorFunction |
| 0x78F3D0–0x793F30 | **GFxSprite runtime** — GFxSpriteDef, dtor/GetBounds/hit-test/frame-advance/GotoLabeledFrame/Display/AddDisplayObject/OnEvent (instance size 0x19C) |
| 0x794300–0x7994C0 | **GASMovieClipObject** — every AS2 MovieClip method (play/gotoAndPlay/attachMovie/duplicateMovieClip/createTextField/…) + the Flash 8 drawing API (moveTo/curveTo/beginGradientFill/…) |
| 0x799540–0x79E0B0 | **GASTextFormatObject, GASCapabilities** ("Scaleform Windows", "WIN 8,0,0,0"), **GASColorObject** |
| 0x79F0B0–0x7A01F0 | **GASMatrixObject** (flash.geom.Matrix ↔ GMatrix2D) |
| 0x7A01F0–0x7B4B70 | **AS2 builtins (batch 3) + text/blend** — GASString/GASDate helpers, TextFormat/StyledText, flash.geom (Point/Rectangle/ColorTransform), blend-mode table |
| 0x7B4C80–0x7BE7A0 | **GFxStream (SWF reader), GASBitmapData, GASColorTransform, GASDate, GFxKeyboardState, Button** (GASButtonObject + GFxButtonCharacterDef readers) |
| 0x7BE7B0–0x7C14B0 | **GASExternalInterface + GFxMovieDataDef / GFxMovieDefImpl** — resource binding, tag-loop Read, GFxMovieBindProcess |
| 0x7C1510–0x7C4DC0 | **GFxMovieBindProcess::BindNextFrame** — import resolution (gfxfontlib.swf/FontMap/FontLib), CreateInstance (GFxMovieRoot 0x204, root sprite 0x19C), + GTL COMDAT farm |
| 0x7C5690–0x7D0630 | **GFxMovieRoot** (GFxPlayerImpl) — ctor/dtor, load-queue, action queue, **Advance/HandleEvent/Display/Invoke/Restart**, Get/SetVariable + path resolver, keyboard focus navigation |
| 0x7CDF80–0x7CF3E0 | **GFxSwfEvent, GFxPlaceObject2/RemoveObject2** + GFx_PlaceObject2Loader |
| 0x7D1110–0x7D434D | **GASLoadVars, GASPoint (flash.geom.Point), GUTF8Util** |
| 0x7D4410–0x7D7320 | **SWF tag loaders** — InflateWrapper, DefineBitsLossless2, DefineShape, DefineFont, DefineSprite, Export/Import, GFX-extension tags 1000–1003 |
| 0x7D7640–0x7DAB30 | **GFxLoaderImpl / GFxLoadStates** — CreateMovie master (0x7D7CB6), header reader (builds GZLibFile for CWS), .tga image-movie path, public GFxLoader ctor |
| 0x7DACC0–0x7DC580 | **GCompoundShape, GFxFontManager, GFxDisplayContext** (mask stack) |
| 0x7DC650–0x7DFBB0 | **GFxDrawingContext** (MovieClip draw API), **GFxGradientData** (color-ramp/gradient images), **GFxFillStyle/GFxLineStyle** (GFxStyles) |
| 0x7DFC00–0x7E0B20 | **GFxDisplayList** (depth-sorted, mask layers, event visitors) + GFxTextLineBuffer accessors |
| 0x7E0B60–0x7E8C90 | **Text engine** — GFxTextFormat/ParagraphFormat/Allocator, GFxTextParagraph, GFxStyledText, **GFxTextDocView** (HTML parse, formatter, wordwrap/align/scroll/hit-test) |
| 0x7E8D00–0x7F2160 | **GFxStyledText HTML/SGML parser** (parallel char/wchar_t ParseHtml) + text-doc cursor/line queries |
| 0x7F2160–0x7F5540 | **GFxShapeCharacterDef + GFxPathAllocator/Packer** — bit-packed paths, Display/cull, Tessellate, CRC32 glyph hash |
| 0x7F55A0–0x7F86B1 | **GFxTextLineBuffer::Display** (8 KB glyph-quad batcher via GRenderer vcalls) |
| 0x7F8ED0–0x7FCE90 | **GFxFont / GFxFontData / GFxFontResource** (DefineFont/2/3, kerning, code tables) + **GFxFontPacker** (glyph atlas GImage generation) |
| 0x7FD670–0x7FDCB0 | **GZLibFileImpl + GZLibFile** (15 exports) — zlib stream over a GFile |
| 0x7FDD30–0x800130 | **GFxMorphCharacterDef** (DefineMorphShape, ratio-lerp) |
| 0x800200–0x801500 | **GFxTextCharacterDef / GFxStaticTextCharacter** (DefineText) |
| 0x801660–0x805FC0 | **GFxFontCacheManager** — 1024×1024 atlas config, batch builder, raster + vector glyph caches |
| 0x806240–0x806BD0 | **GColor** (8 exports — HSV/HSI conversions) |
| 0x806D80–0x80BA30 | **GFxMeshSet / GFxMesh** (tessellation driver, Display) + **GStroker** (joins/caps/arcs) |
| 0x80BDE0–0x80D4C0 | **Scanline rasterizer** (AGG-style cell accumulation + coverage sweep, gamma LUT) |
| 0x80D680–0x811FE0 | **GFxGlyphRasterCache** — texture slot/band rect-packer + LRU, rasterize-with-effects (outline/faux-bold/blur/knockout), texture upload; ends with 5 lazy static GRenderer vertex formats |

### 5.2 Coverage gap — the library extends past 0x812000

The upper bound of the fan-out (0x812000) is **not** the end of the GFx library. Code in the top
slice calls forward into more GFx bodies past 0x812000: **GTessellator** (~0x818EE0/0x819590),
**GFxEdgeAA** (~0x81DE20/0x81E300), shape/array helpers (~0x81E910), glyph outline (~0x81EA50),
curve subdivision (~0x820280), paged cells (~0x821000). The Pandemic engine boundary lies beyond
~0x821000. **~0x812000–0x821000 (the tessellation/edge-AA/curve tail) is not yet in this map** —
a follow-up slice should cover it.

## 6. SecuROM trampolines are fully resolvable (not a dead end)

Every naming agent flagged the same obstacle: dozens of GFx-region "functions" are tiny stubs that
jump into the `0x004xxxxx`/`0x024xxxxx` range, with the real body re-entering at an odd address —
SecuROM's stolen-instruction obfuscation. **Because the analysis runs on the *unpacked* image
(`mercs2_unpacked.exe`, the decompiled SecuROM partition — 4,633 functions in `0x02xxxxxx`, 1,166
of them in `0x024xxxxx`), every hop is present as a named `FUN_` with intact caller/callee edges.**
The obfuscation is a mechanical indirection, one mapping away from a clean callgraph.

Worked example (a GHash lookup):

```
FUN_00788830 (13 B, GFx region)  →  FUN_004b760c (10 B, reloc island)  →  FUN_0078883d (80 B, real body)
  void f(){ FUN_004b760c(); }        void f(){ FUN_0078883d(); }           uint __fastcall f(int,uint){ ...GHash probe loop... }
```

I resolved all **56 pure-forwarder stubs** in the GFx region by chain-following the decomp
(`scratchpad/gfx/trampoline_resolution.txt`, folded into the JSON's `trampoline` field): 53 land
back inside the GFx region after 1–3 hops, and 3 terminate in a reloc island that itself performs a
single stolen instruction then jumps to `body+0x1A` (e.g. `FUN_00409E26` = `mov byte,0` →
`FUN_0078B77A`). None are unrecoverable. Split-body functions (a stub + an odd-address continuation
that Ghidra listed separately, e.g. `Execute` @0x76AB40 + FSCommand tail @0x76F252) are the same
phenomenon and are stitched the same way.

**Practical rule for anyone extending this map or hooking these functions:** target the *stub entry*
address, and to read real behaviour follow the single `FUN_` call through the island(s) to the body
— `docs/data/scaleform_gfx_function_map.json` already records the resolved target for the 56 pure
forwarders.

## 7. Engine integration layer (Pandemic ⇄ GFx)

The engine side (102 functions mapped, `layer=engine_integration` in the JSON) has four parts:

**7.1 PgScaleform renderer HAL** — Pandemic's implementation of Scaleform's `GRenderer` interface.
Class object 0x6D0C0 bytes, main vtable **0xBAD188**, embedded interface vtable **0xBAD0F4** (sits
right after the `PgScaleform*.sho` shader-name block, which is why the shader names never appear as
inline `s_` refs — they're consumed from a static table). Ctor `FUN_004ADFF0` builds the quad→triangle
index pattern (0,1,2,2,1,3) for batched glyph/quad drawing; singleton via `FUN_0060E840` (stored in
`DAT_01175A58`, guarded by the global Scaleform critical section `DAT_01175FB4`). DrawIndexedTriList
master `FUN_004AFDB0`; all drawing funnels into the LTI layer (PgLtiBufferPc / PgPrimitive) and the
six `.sho` shaders.

**7.2 FlashWidget / GUI bridge** — the Lua-facing widget wraps a `GFxMovieView*` at obj+0x1E0
(WAD asset handle +0x1E8, name hash +0x1D8). The `_GuiInternal.CreateFlashWidget/SetFlashSwfFile/
SendFlashInput/SetFlashCallback/CallFlashScriptFunction` Lua binders are **absent from the Ghidra
export** (registered by hash via binding tables; bodies in export gaps 0x60A281–0x60ADF0 and
0x61B540–0x61B8C0 — the same gap class as the 6 missing profile binders, a candidate for another
`DecompileProfileAccessors.java` pass). Observed `GFxMovieView` vtable: +0x20 SetPlayState, +0x28
IsAvailable, +0x48 Invoke, +0x50 SetViewport, +0x6C Restart, +0x84 HandleEvent, +0x9C shutdown.

**7.3 Movie lifecycle** — `.gfx` assets (type hash 0xFE0E8320) load via a FileOpener backend
`FUN_0060D930` (pins the WAD asset, wraps ptr+size in a 0x9C GFile) → streaming FSM `FUN_0060E4A0`
(polls residency==3, then GFxLoader movie-def lookup + CreateMovie) → per-frame `FUN_006190B0`
(widget Update → movie Advance); teardown `FUN_0061B330`. Asset-type handler `FUN_004CA9C0`
returns the 0xFE0E8320 type hash.

**7.4 FSCommand / ExternalInterface** — movie→engine `FSCommand:` strings (matched in the
interpreter `FUN_0076AB40`) dispatch through `FUN_0060DE80` (~15 hard-coded commands) then the Lua
`_LTIFscommand` path; engine→movie `Invoke` calls (EA account screens, PC key/mouse remap, analog
stick → synthesized arrow-key GFxKeyEvents) always guard on `IsAvailable` under the global lock.

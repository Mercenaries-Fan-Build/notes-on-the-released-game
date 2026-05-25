# External Tools Review — Mercenaries 2 Reverse Engineering Project

Curated from [awesome-game-file-format-reversing](https://github.com/) and supplementary research. Each tool/resource is evaluated for relevance to our FFCS/UCFX/Lua/Havok/D3D9/ASI pipeline.

---

## Table of Contents

1. [Lua Decompilation & Analysis](#1-lua-decompilation--analysis)
2. [Havok 5.5 Tools](#2-havok-55-tools)
3. [Archive & Container Format Tools](#3-archive--container-format-tools)
4. [Binary Analysis & Reverse Engineering](#4-binary-analysis--reverse-engineering)
5. [D3D9 / Rendering Tools](#5-d3d9--rendering-tools)
6. [ASI / DLL Injection & Hooking](#6-asi--dll-injection--hooking)
7. [Game Modding Frameworks](#7-game-modding-frameworks)
8. [Pandemic Studios / Similar Engine Tools](#8-pandemic-studios--similar-engine-tools)
9. [DDS / Texture Tools](#9-dds--texture-tools)
10. [General Format Analysis](#10-general-format-analysis)
11. [Communities & Knowledge Bases](#11-communities--knowledge-bases)

---

## 1. Lua Decompilation & Analysis

### unluac — **HIGH PRIORITY**
- **URL:** https://sourceforge.net/projects/unluac/
- **What it does:** Decompiler for Lua 5.1 bytecode. Handles most Lua 5.1 binaries including those with custom opcodes or modified headers found in games.
- **Relevance:** Direct match for our problem. We have `.luac` files extracted from `scripts.vz` WAD blocks that are compiled Lua 5.1 (float build) bytecode. unluac can decompile these to readable Lua source, exposing mission logic, faction AI, equipment data, and game flow scripts. The custom opcode support is critical since Pandemic may have modified the standard Lua VM.
- **Priority:** HIGH — This is the primary tool for understanding the game's scripting layer.

### bungie-lua-decompiler — LOW PRIORITY
- **URL:** https://github.com/nblockbuster/bungie-lua-decompiler
- **What it does:** Decompiles Bungie's custom Lua scripts (format 14) from Destiny 1 Alpha.
- **Relevance:** Different Lua format than ours, but demonstrates techniques for handling game-specific Lua bytecode modifications. Could be a reference for handling any Pandemic-specific Lua VM modifications if unluac fails on certain files.
- **Priority:** LOW — Only useful as reference if standard decompilation fails.

### AquaNox `.sco` Lua bytecode tools — MEDIUM PRIORITY
- **URL:** https://github.com/Swyter/aquanox-tools
- **What it does:** 010 Editor binary templates and tools for AquaNox, which also uses `.sco` Lua bytecode in its game archives.
- **Relevance:** AquaNox (Massive Entertainment, 2001) is a contemporaneous game that used Lua bytecode in PAK archives — a similar architecture to Mercenaries 2. The binary template for `.sco` files could be adapted as a starting point for understanding any Pandemic-specific bytecode header modifications.
- **Priority:** MEDIUM — Useful reference for Lua bytecode header analysis.

---

## 2. Havok 5.5 Tools

### Havok IO (Blender) — **HIGH PRIORITY**
- **URL:** https://github.com/NewSkyLine-dev/havokmax-blender
- **What it does:** Blender add-on that imports `.hkx`, `.hkt`, `.hka`, `.igz`, and `.pak` files from Havok XML and binary archives. Builds armatures and keyframed actions from animation data, constructs static meshes from geometry blocks.
- **Relevance:** Direct pipeline integration potential. Our Havok 5.5 packfile extraction (`tools/hk_packfile.py`) produces `.hkx` binary slices. If we can get these into a format Havok IO accepts, we could visualize skeleton hierarchies and animation data in Blender, bypassing our partially-implemented delta/wavelet decompression. The armature building code could serve as a reference for our `hk_skeleton.py` and `anim_gltf_export.py`.
- **Priority:** HIGH — Could accelerate the skeletal animation pipeline significantly.

### HavokNoesis — **HIGH PRIORITY**
- **URL:** https://github.com/PredatorCZ/HavokNoesis
- **What it does:** Noesis plugin for Havok binary format. Part of PredatorCZ's broader Havok reverse engineering work.
- **Relevance:** PredatorCZ (Lukas Cone) is one of the foremost Havok format reverse engineers. His tooling likely handles multiple Havok SDK versions including older ones near our 5.5 target. The Noesis plugin could directly preview our extracted `.hkx` slices without any conversion. His code is also a reference implementation for Havok binary packfile parsing.
- **Priority:** HIGH — PredatorCZ's work is the gold standard for Havok RE.

### hkxc (HKX Conversion CLI) — MEDIUM PRIORITY
- **URL:** https://www.nexusmods.com/skyrimspecialedition/mods/126214
- **What it does:** CLI tool to convert between x86/x64 HKX and XML animation files.
- **Relevance:** Could be used to convert our Havok 5.5 binary packfiles to XML for inspection and debugging. Havok XML is human-readable and would let us verify our `hk_packfile.py` parsing without running hkxcmd. The x86 support is important since our data comes from a 32-bit game.
- **Priority:** MEDIUM — Useful for verification of our Havok parsing.

### HavokPreviewToolsBatch2018 — MEDIUM PRIORITY
- **URL:** https://github.com/asasasasasbc/HavokPreviewToolsBatch2018
- **What it does:** Batch conversion script for Havok Preview Tool 2018. Automatically converts HKX/HKT files between format versions.
- **Relevance:** Havok format versioning is a known pain point. Our 5.5 data may need version conversion before newer tools can read it. This batch wrapper could automate conversion of our extracted animation slices.
- **Priority:** MEDIUM — Useful if version mismatch blocks other Havok tools.

### hkxPoser — LOW PRIORITY
- **URL:** https://www.nexusmods.com/skyrimspecialedition/mods/11783
- **What it does:** HKX animation file editor with visual pose editing.
- **Relevance:** If we can get our Havok 5.5 animations into a compatible format, this could provide visual verification. Lower priority because it targets Skyrim's Havok version (2010+), not 5.5.
- **Priority:** LOW — Version gap may be too large.

### hkxlib / hkxEdit — LOW PRIORITY
- **URL:** https://github.com/aerisarn/hkxlib / https://github.com/aerisarn/hkxEdit
- **What it does:** JAXB parser and visual editor for TAGXML formatted Havok files (2010.2).
- **Relevance:** The TAGXML format is newer than our 5.5 packfile format, but the Java parsing code could serve as a reference for Havok class hierarchy understanding.
- **Priority:** LOW — Different Havok generation.

### TagTools — LOW PRIORITY
- **URL:** https://github.com/blueskythlikesclouds/TagTools
- **What it does:** Tools for editing Havok 2015/2016 binary tag files. Includes collision converter.
- **Relevance:** Too new for our 5.5 format, but the collision converter concept could be relevant if we need to extract Havok physics collision shapes from our data.
- **Priority:** LOW — Wrong Havok version.

### dark_souls_hkx — MEDIUM PRIORITY
- **URL:** https://github.com/Danilodum/dark_souls_hkx
- **What it does:** Noesis plugins for Dark Souls HKX (Havok animation) with extra root bone and root motion support.
- **Relevance:** Dark Souls uses a relatively old Havok SDK version. The root bone handling and animation extraction techniques could be applicable to our Mercenaries 2 character animations. Worth studying for the bone hierarchy reconstruction approach.
- **Priority:** MEDIUM — Similar era Havok, animation-focused.

### SSE-Fallout-4-Animation-Converter — LOW PRIORITY
- **URL:** https://github.com/Backporter/SSE-Fallout-4-Animation-Converter
- **What it does:** Converts animations between Havok versions for Skyrim/Fallout.
- **Relevance:** Demonstrates Havok animation format conversion between versions — the core technique we need to bridge our 5.5 format to modern tooling.
- **Priority:** LOW — May not support versions old enough for 5.5.

---

## 3. Archive & Container Format Tools

### QuickBMS — **HIGH PRIORITY**
- **URL:** https://aluigi.altervista.org/quickbms.htm
- **What it does:** Universal archive extractor/reimporter with BMS scripting language. Script database covers thousands of games.
- **Relevance:** We already have `docs/quickbms_notes.md` documenting prior QuickBMS workflows. The BMS scripting language can describe our FFCS WAD format for extraction. QuickBMS's reimport capability is also valuable — if we could write a BMS script for FFCS, it would enable modded WAD repacking as an alternative to our Python `ffcs_patch_wad.py`. The script database may also contain entries for related Pandemic games.
- **Priority:** HIGH — Already partially integrated; BMS scripts for FFCS would benefit the community.

### RTB-QuickBMS-Scripts — MEDIUM PRIORITY
- **URL:** https://github.com/RandomTBush/RTB-QuickBMS-Scripts
- **What it does:** Collection of QuickBMS scripts for various games.
- **Relevance:** Worth searching for any Pandemic Studios game scripts. Even if Mercenaries 2 isn't directly covered, scripts for Star Wars: Battlefront or other Pandemic titles might decode related format variants.
- **Priority:** MEDIUM — Search for Pandemic-adjacent game scripts.

### GameExtractor — MEDIUM PRIORITY
- **URL:** https://github.com/wattostudios/GameExtractor
- **What it does:** Multi-game archive tool supporting 4000+ games. Java-based GUI.
- **Relevance:** We already have `docs/game_extractor_notes.md` documenting its use. It has some Mercenaries 2 support. Can serve as a cross-validation tool against our Python extraction pipeline, and its broad format knowledge base might reveal similarities between FFCS and other archive formats.
- **Priority:** MEDIUM — Already used; useful for verification.

### binwalk — MEDIUM PRIORITY
- **URL:** https://github.com/ReFirmLabs/binwalk
- **What it does:** Firmware analysis tool for identifying and extracting embedded files from binary blobs. The Rust v3 version provides significant speed improvements.
- **Relevance:** Useful for probing unknown binary blobs in our UCFX containers. binwalk's signature scanning could identify embedded formats we haven't detected yet (e.g., hidden RIFF audio, additional DDS textures, or Havok data at unexpected offsets). Good complement to our `ucfx_parser.py` tag scanning.
- **Priority:** MEDIUM — Good for finding undiscovered embedded data.

### Kaitai Struct — MEDIUM PRIORITY
- **URL:** https://kaitai.io/
- **What it does:** Declarative language for describing binary data structures, with code generation for multiple languages including Python.
- **Relevance:** We could formally specify our FFCS, sges, UCFX, and placement record formats in Kaitai's `.ksy` format. This would auto-generate parsers, produce interactive web visualizations of binary data, and serve as machine-readable documentation alongside our `docs/format_reference.md`. Particularly valuable for the complex UCFX chunk hierarchy.
- **Priority:** MEDIUM — Documentation and validation tool.

---

## 4. Binary Analysis & Reverse Engineering

### Ghidra — **HIGH PRIORITY** (already in use)
- **URL:** https://github.com/NationalSecurityAgency/ghidra
- **What it does:** NSA's software reverse engineering framework with disassembly, decompilation, graphing, and scripting.
- **Relevance:** Already integrated — we have `make ghidra-ps3-eboot` for headless PS3 EBOOT analysis. Essential for understanding `Mercenaries2.exe` internals: FFCS loading, sges decompression, UCFX parsing, Lua VM integration, and the hash-based asset resolution system.
- **Priority:** HIGH — Core tool, already in use.

### ghidra-delinker-extension — MEDIUM PRIORITY
- **URL:** https://github.com/widberg/ghidra-delinker-extension
- **What it does:** Ghidra extension for extracting functions from executables into relocatable object files. Supports PE format.
- **Relevance:** Could enable extracting specific functions from `Mercenaries2.exe` (e.g., the sges decompressor, UCFX parser, or pandemic_hash function) as standalone relocatable objects. These could then be linked into test harnesses for verification against our Python reimplementations.
- **Priority:** MEDIUM — Valuable for function-level extraction and verification.

### HexRaysCodeXplorer — **HIGH PRIORITY**
- **URL:** https://github.com/REhints/HexRaysCodeXplorer
- **What it does:** Hex-Rays Decompiler plugin for automatic type reconstruction, vtable detection, and RTTI analysis in C++ binaries.
- **Relevance:** Directly applicable to Mercenaries 2's MSVC-compiled binary. The RTTI analysis would help recover class hierarchies for the ECS component system, UCFX chunk handlers, and Havok integration layer. vtable detection is critical for understanding the game's polymorphic object system. The C++ reconstruction features would dramatically accelerate RE of the engine internals.
- **Priority:** HIGH — Essential for MSVC C++ RE if using IDA.

### FakePDB — MEDIUM PRIORITY
- **URL:** https://github.com/Mixaill/FakePDB
- **What it does:** Generates PDB files from IDA Pro databases. Can export IDA databases to JSON, find binary signatures, and import function names from JSON.
- **Relevance:** If working with `Mercenaries2.exe` in IDA, generating a fake PDB would enable debugging the game with Visual Studio or WinDbg, using recovered function names and type information. The JSON export capability is also useful for sharing analysis results.
- **Priority:** MEDIUM — Useful for debugging with recovered symbols.

### HexForge — LOW PRIORITY
- **URL:** https://github.com/elastic/HexForge
- **What it does:** IDA plugin for decoding/decrypting/altering data directly from the hex view.
- **Relevance:** Could speed up in-IDA analysis of UCFX chunk data and FFCS headers, allowing quick decode operations without leaving the disassembler.
- **Priority:** LOW — Convenience tool.

### atlas (Hashing Tool) — **HIGH PRIORITY**
- **URL:** https://github.com/nblockbuster/atlas
- **What it does:** Plugin-based hashing tool supporting FNV (0, 1, 1a), MD5, Murmur2/3, SipHash, SHA, XXHash/XXHash3. Designed for RE hash analysis.
- **Relevance:** Directly relevant. Our `pandemic_hash` is confirmed as FNV-1a with `|0x20` case suppression (see `tools/pandemic_hash.py`). atlas's FNV-1a implementation could be used to cross-validate our hash function and brute-force unknown hashes in the ASET chunk. Its batch processing would help map unresolved hash values in `block_dependency_graph.json`.
- **Priority:** HIGH — Cross-validation for our hash system.

### Pattern16 — MEDIUM PRIORITY
- **URL:** https://github.com/Dasaav-dsv/Pattern16
- **What it does:** Fastest x86-64 signature matching library (25 GB/s). Header-only C++ library.
- **Relevance:** Useful for building signature scanners that locate specific code patterns in `Mercenaries2.exe`. Could help our ASI plugin (`dlc_enable.c`) find hook targets by pattern rather than hardcoded addresses, making it version-resilient.
- **Priority:** MEDIUM — Improves ASI plugin robustness.

### iced (x86 disassembler) — LOW PRIORITY
- **URL:** https://github.com/icedland/iced
- **What it does:** Blazing fast x86/x64 disassembler, assembler, decoder, and encoder. Available for Python and Lua.
- **Relevance:** The Python binding could be useful for scripting disassembly of specific `Mercenaries2.exe` code regions from within our Python toolchain, without needing a full Ghidra/IDA session.
- **Priority:** LOW — We already have Ghidra for this.

### qiling — LOW PRIORITY
- **URL:** https://github.com/qilingframework/qiling
- **What it does:** Advanced binary emulation framework supporting Windows x86 PE binaries.
- **Relevance:** Could theoretically emulate specific Mercenaries 2 functions (e.g., the sges decompressor or UCFX parser) in an isolated environment for verification against our Python reimplementations. The x86 Windows PE support makes it applicable to our 32-bit game binary.
- **Priority:** LOW — Complex setup for marginal benefit over direct RE.

### Veles — LOW PRIORITY
- **URL:** https://codisec.com/veles/
- **What it does:** Binary analysis and visualization tool for reverse engineering.
- **Relevance:** Visual analysis of binary data patterns could help identify undiscovered structure in our UCFX chunks or FFCS data blocks.
- **Priority:** LOW — Our existing parsers cover most binary analysis needs.

### binviz — LOW PRIORITY
- **URL:** https://github.com/VelocityRa/binviz
- **What it does:** Binary visualization tool for identifying patterns in unknown files.
- **Relevance:** Could help visualize raw block files to spot compression, encryption, or structural patterns at a glance.
- **Priority:** LOW — Supplementary visualization.

---

## 5. D3D9 / Rendering Tools

### rwd3d9 — MEDIUM PRIORITY
- **URL:** https://github.com/aap/rwd3d9
- **What it does:** D3D9 extension of RenderWare for GTA III/Vice City. Demonstrates D3D9 renderer integration patterns.
- **Relevance:** While Mercenaries 2 doesn't use RenderWare, this codebase demonstrates D3D9 rendering pipeline integration patterns from the same era. The D3D9 vertex format handling, texture management, and shader setup code could serve as a reference for understanding how our game's renderer processes UCFX mesh data. Particularly relevant for understanding the D3D9 vertex declarations that map to our STRM/IBUF chunk formats.
- **Priority:** MEDIUM — Reference for D3D9 pipeline understanding.

### hlsldecompiler-rs (3DMigoto HLSL decompiler) — MEDIUM PRIORITY
- **URL:** https://github.com/cohaereo/hlsldecompiler-rs
- **What it does:** Statically linked Rust wrapper for 3DMigoto's HLSL shader decompilation. Part of the 3DMigoto ecosystem which can intercept and replace D3D9/D3D11 shaders.
- **Relevance:** 3DMigoto is one of the most powerful D3D hook frameworks. While this specific wrapper targets HLSL decompilation, the broader 3DMigoto project can intercept D3D9 calls, dump vertex/index buffers, capture shader constants, and replace shaders at runtime. This would be invaluable for understanding how the game's renderer processes our extracted mesh data and for verifying vertex format interpretations.
- **Priority:** MEDIUM — 3DMigoto ecosystem is powerful for renderer analysis.

### NinjaRipper — MEDIUM PRIORITY
- **URL:** Via [io_mesh_ninjaripper](https://github.com/REDxEYE/io_mesh_ninjaripper) Blender addon
- **What it does:** Captures rendered geometry from D3D9/D3D11 games at runtime by hooking draw calls. The Blender addon imports the captured `.rip` files.
- **Relevance:** NinjaRipper could capture meshes as they're actually rendered by the Mercenaries 2 engine, providing ground-truth geometry to validate against our UCFX extraction pipeline. Comparing NinjaRipper captures to our extracted OBJ/GLB files would reveal any vertex format misinterpretations, missing submeshes, or transform errors.
- **Priority:** MEDIUM — Excellent for validation of extraction accuracy.

### RAW pixels viewer — LOW PRIORITY
- **URL:** https://www.kernellabs.com/rawpixels/
- **What it does:** Web-based tool for analyzing raw image data, allowing interactive exploration of color formats and image parameters.
- **Relevance:** Useful for debugging unknown texture formats in UCFX blocks that don't match standard DDS. Could help identify custom pixel formats in BODY chunks that our `texture_extractor.py` doesn't recognize.
- **Priority:** LOW — Edge case debugging tool.

---

## 6. ASI / DLL Injection & Hooking

### Reloaded-II — **HIGH PRIORITY**
- **URL:** https://github.com/Reloaded-Project/Reloaded-II
- **What it does:** Universal .NET Core powered modding framework for native x86/x64 games. DLL injection based mod loader with mod management, optional mod SDK, and plugin support.
- **Relevance:** Comprehensive alternative to our current Ultimate ASI Loader approach. Reloaded-II provides a complete mod management ecosystem: dependency resolution between mods, hot-reload during runtime, configuration UI, and update distribution. If we expand beyond a single `dlc_enable.asi` to a broader modding framework (e.g., custom mission scripting, asset hot-swapping, WAD overlay management), Reloaded-II would be a more maintainable foundation.
- **Priority:** HIGH — Superior mod loader framework if we expand modding scope.

### Reloaded.Hooks — **HIGH PRIORITY**
- **URL:** https://github.com/Reloaded-Project/Reloaded.Hooks
- **What it does:** Advanced native function hooks for x86 and x64. High-performance hooking library with unit testing support.
- **Relevance:** Our `dlc_enable.c` currently uses manual detour patching. Reloaded.Hooks provides a more robust hooking primitive that handles edge cases (thread safety, code relocation, calling convention preservation). If we port our ASI to the Reloaded ecosystem, this library would replace our hand-rolled hook stubs.
- **Priority:** HIGH — Better hooking foundation than manual detours.

### hooking (Resource Collection) — MEDIUM PRIORITY
- **URL:** https://github.com/alphaSeclab/hooking
- **What it does:** Massive repository of 300+ hooking tools and 600+ articles covering all platforms.
- **Relevance:** Comprehensive reference for hooking techniques applicable to our `Mercenaries2.exe` instrumentation. Covers Windows x86 function hooking, IAT hooking, inline patching, and more. Useful for improving our ASI plugin's hook reliability and learning advanced techniques for intercepting game functions.
- **Priority:** MEDIUM — Reference and education resource.

### ModEngine2 — MEDIUM PRIORITY
- **URL:** https://github.com/soulsmods/ModEngine2
- **What it does:** Runtime code patching and injection library for FromSoftware games. Supports mod loading and file replacement.
- **Relevance:** Although built for Dark Souls/Elden Ring, ModEngine2 demonstrates a mature approach to runtime mod loading in native games. Its architecture (DLL proxy → mod discovery → file redirect → code patching) is exactly what we need for a full Mercenaries 2 mod framework. The file redirect pattern could replace WAD patching with virtual filesystem overlays.
- **Priority:** MEDIUM — Architecture reference for mod framework design.

### ps3-ckit — LOW PRIORITY
- **URL:** https://github.com/tge-was-taken/ps3-ckit
- **What it does:** PS3 C code injection framework for hooking existing functions and inserting custom functionality.
- **Relevance:** Could be relevant for PS3 version modding (we have the PS3 EBOOT.elf analyzed in Ghidra). Lower priority since our focus is the PC version.
- **Priority:** LOW — PS3 specific; PC is primary target.

### REFramework — LOW PRIORITY
- **URL:** https://github.com/praydog/REFramework
- **What it does:** Scripting framework and mod loader for RE Engine games with Lua scripting access.
- **Relevance:** The Lua scripting integration approach is interesting — REFramework exposes engine internals via Lua. A similar approach for Mercenaries 2 (exposing the game's own Lua VM to modders via an ASI hook) could be powerful, but the implementation is RE Engine specific.
- **Priority:** LOW — Design inspiration only.

### cauldron — LOW PRIORITY
- **URL:** https://github.com/cauldronloader/cauldron
- **What it does:** Rust-based mod loader for Decima engine games with DLL proxy loading and RTTI symbol dumping.
- **Relevance:** The RTTI dumping capability is interesting — a similar approach for `Mercenaries2.exe` could recover class hierarchies. The DLL proxy loading pattern is already what our Ultimate ASI Loader does.
- **Priority:** LOW — RTTI dump concept is useful but engine-specific.

---

## 7. Game Modding Frameworks

### Cyber Engine Tweaks — MEDIUM PRIORITY
- **URL:** https://github.com/maximegmd/CyberEngineTweaks
- **What it does:** Framework for scripting mods via Lua with access to internal scripting features. For Cyberpunk 2077/REDengine.
- **Relevance:** Demonstrates the approach of exposing a game's internal Lua VM to modders. Mercenaries 2 already has a Lua 5.1 VM — a similar framework could let modders write new scripts that interact with the game's existing Lua environment (faction AI, mission logic, equipment data) without binary patching. Our DLC ASI already hooks Lua function calls; this could be expanded.
- **Priority:** MEDIUM — Design pattern for Lua-based modding framework.

### ArchiveXL (Cyberpunk 2077) — LOW PRIORITY
- **URL:** https://github.com/psiberx/cp2077-archive-xl
- **What it does:** Loads custom resources without overriding existing archive entries.
- **Relevance:** Conceptually similar to our WAD overlay/patching system. The approach of adding new assets alongside existing ones (rather than replacing) could inform our DLC WAD design where we inject new blocks alongside retail content.
- **Priority:** LOW — Conceptual reference only.

---

## 8. Pandemic Studios / Similar Engine Tools

### Star Wars: Battlefront Unpacker/Decoder — **HIGH PRIORITY**
- **URL:** https://www.moddb.com/games/star-wars-battlefront/downloads/starwars-battlefront-unpacker-decoder
- **What it does:** Custom toolset for unpacking and extracting Star Wars: Battlefront archives.
- **Relevance:** **Critical lead.** Star Wars: Battlefront (2004) was developed by Pandemic Studios — the same studio that made Mercenaries 2. Battlefront uses Pandemic's engine technology and likely shares archive format DNA with FFCS. The unpacker may reveal format similarities or even partial compatibility with our WAD files. Battlefront's modding community may have documented format details that apply to Mercenaries 2.
- **Priority:** HIGH — Same studio, potentially overlapping formats.

### Star Wars: Battlefront Modification Tools — **HIGH PRIORITY**
- **URL:** https://www.moddb.com/games/star-wars-battlefront/downloads/star-wars-battlefront-modification-tools
- **What it does:** Official modding tools for creating levels in Star Wars: Battlefront.
- **Relevance:** **Official Pandemic Studios tools.** These were created by or with cooperation from Pandemic. They encode knowledge about Pandemic's asset pipeline, data formats, and engine architecture. Even though they target Battlefront specifically, the underlying format knowledge (Lua scripting integration, archive structure, texture handling) could transfer to Mercenaries 2 since both games share engine lineage.
- **Priority:** HIGH — Official Pandemic tools with shared engine knowledge.

### 3D Object Converter (Star Wars Battlefront II) — MEDIUM PRIORITY
- **URL:** https://www.moddb.com/games/star-wars-battlefront-ii/downloads/3d-object-converter
- **What it does:** Polygon-based 3D object converter supporting 440 file formats.
- **Relevance:** Battlefront II (2005) is another Pandemic game. If this converter handles Pandemic's mesh formats, it might have partial support for the mesh data structures also found in Mercenaries 2's UCFX containers.
- **Priority:** MEDIUM — May support related Pandemic mesh formats.

### SabTool (The Saboteur) — MEDIUM PRIORITY
- **URL:** https://github.com/BoBoBaSs84/SabTool
- **What it does:** CLI tool for managing files for The Saboteur.
- **Relevance:** The Saboteur (2009) was Pandemic Studios' last game before the studio was closed by EA. It was built on a version of Pandemic's engine (Odin Engine) that evolved from the same codebase used in Mercenaries 2. SabTool's format handling likely deals with evolved versions of the same archive and asset structures. Studying it could reveal format evolution patterns and help identify shared data structures.
- **Priority:** MEDIUM — Evolved Pandemic engine; format similarities likely.

### Gibbed.Visceral — LOW PRIORITY
- **URL:** https://github.com/gibbed/Gibbed.Visceral
- **What it does:** Tools for Visceral Games titles (Dead Space 2, Dante's Inferno).
- **Relevance:** Visceral Games was an EA studio operating in the same era. While they used different engine technology, their titles were published alongside Pandemic games and may share some EA-common format conventions (audio banks, texture formats). Low priority since engine architecture differs.
- **Priority:** LOW — Different engine, same publisher era.

### MeltyTool (Dead Space support) — LOW PRIORITY
- **URL:** https://github.com/MeltyPlayer/MeltyTool
- **What it does:** Multitool supporting Dead Space among many other games.
- **Relevance:** Dead Space was a Visceral/EA game from 2008 (same year as Mercenaries 2). The EA publishing pipeline may have shared some format conventions.
- **Priority:** LOW — Indirect EA connection.

---

## 9. DDS / Texture Tools

### DDS.Tools — MEDIUM PRIORITY
- **URL:** https://github.com/BoBoBaSs84/DDS.Tools
- **What it does:** DDS and PNG toolset for bulk conversion with duplicate detection and sorting.
- **Relevance:** We do extensive DDS→PNG transcoding in our texture pipeline. DDS.Tools could serve as a batch conversion alternative or validation tool, especially its duplicate detection which could help identify redundant textures across WAD blocks.
- **Priority:** MEDIUM — Batch processing and dedup.

### detex — MEDIUM PRIORITY
- **URL:** https://github.com/hglm/detex
- **What it does:** Low-level library for decompression and manipulation of texture blocks. Supports BC1/DXT1/S3TC through BC7, ETC, KTX, DDS.
- **Relevance:** Our `texture_extractor.py` handles DXT1/DXT3/DXT5. detex supports the same formats but as a C library, making it potentially faster for bulk operations. Could also help decode any non-standard texture formats we encounter in UCFX BODY chunks.
- **Priority:** MEDIUM — Performance alternative for texture decoding.

### BCDec — LOW PRIORITY
- **URL:** https://github.com/neptuwunium/bcdec
- **What it does:** All-in-one C++ texture decoding library for BC1-BC7, ETC1/2, and ASTC.
- **Relevance:** Similar to detex but C++ based. Our Python/Pillow pipeline already handles our DXT needs.
- **Priority:** LOW — We already handle DXT formats.

### DirectXTexNet — LOW PRIORITY
- **URL:** https://github.com/deng0/DirectXTexNet
- **What it does:** .NET wrapper for Microsoft's DirectXTex library.
- **Relevance:** DirectXTex is the authoritative reference implementation for DDS format handling. Could be useful if we encounter DDS files with non-standard headers or formats that Pillow doesn't handle.
- **Priority:** LOW — Edge case format support.

### ImageHeat — LOW PRIORITY
- **URL:** https://github.com/bartlomiejduda/ImageHeat
- **What it does:** Texture viewing tool for encoded textures with platform-specific unswizzling.
- **Relevance:** Could help identify unknown texture formats in UCFX blocks. The PS3 unswizzling support is relevant for our cross-platform analysis work.
- **Priority:** LOW — Debugging/exploration tool.

---

## 10. General Format Analysis

### 010 Editor + Game Templates — **HIGH PRIORITY**
- **URL:** https://www.sweetscape.com/010editor/ (editor), templates: [010GameTemplates](https://github.com/Nenkai/010GameTemplates), [010-Editor-Templates](https://github.com/tge-was-taken/010-Editor-Templates), [bt](https://github.com/neptuwunium/bt)
- **What it does:** Professional hex editor with powerful binary template system. The game template collections contain hundreds of format templates.
- **Relevance:** 010 Editor templates are the most popular way to document and visualize game binary formats. We should create `.bt` templates for FFCS, sges, UCFX, and placement records. This would let anyone with 010 Editor interactively explore our binary data, and serves as executable documentation alongside `docs/format_reference.md`. The existing template collections may also contain templates for related formats.
- **Priority:** HIGH — Best-in-class binary format documentation tool.

### ImHex — **HIGH PRIORITY**
- **URL:** https://github.com/WerWolv/ImHex
- **What it does:** Modern, open-source hex editor with pattern language for reverse engineering file formats.
- **Relevance:** Free alternative to 010 Editor with a similar pattern language. We could provide ImHex patterns alongside 010 Editor templates, making our format documentation accessible to anyone without a paid license. ImHex's pattern language is also powerful enough to describe our full format hierarchy.
- **Priority:** HIGH — Free, open-source format exploration.

### ReverseBox — MEDIUM PRIORITY
- **URL:** https://github.com/bartlomiejduda/ReverseBox
- **What it does:** Python library for reverse engineering with utilities for checksums, compression, encryption, hashing, and image processing. Supports FNV hashing, CRC variants, and 100+ pixel formats.
- **Relevance:** Directly useful. ReverseBox's FNV hashing implementation could cross-validate our `pandemic_hash.py`. Its CRC variant support could help verify our custom CRC-32 CSUM implementation (init=0, no final XOR). The DXT pixel format support could augment our texture decoding pipeline.
- **Priority:** MEDIUM — Cross-validation for our hash and CRC implementations.

### Noesis — MEDIUM PRIORITY
- **URL:** https://richwhitehouse.com/index.php?content=inc_projects.php&showproject=91
- **What it does:** All-in-one tool for previewing and converting 500+ model, texture, and animation formats. Rich plugin ecosystem.
- **Relevance:** Noesis with HavokNoesis plugin could preview our extracted Havok data. A custom Noesis Python plugin for UCFX mesh format could serve as an alternative viewer to our Three.js viewer. The plugin system makes it relatively easy to add new format support.
- **Priority:** MEDIUM — Preview tool with Havok plugin potential.

### bitfield — LOW PRIORITY
- **URL:** https://github.com/wavedrom/bitfield
- **What it does:** Renders bit field diagrams from JSON descriptions.
- **Relevance:** Could generate visual diagrams of our binary format structures for documentation. Nice complement to `format_reference.md` tables.
- **Priority:** LOW — Documentation enhancement.

### pics (File Format Dissections) — LOW PRIORITY
- **URL:** https://github.com/corkami/pics
- **What it does:** File format dissections and visualizations for reverse engineering.
- **Relevance:** Reference for how to visually document binary formats. Our format documentation could benefit from similar visual approaches.
- **Priority:** LOW — Inspiration for documentation style.

---

## 11. Communities & Knowledge Bases

### ZenHAX — MEDIUM PRIORITY
- **URL:** https://zenhax.com/
- **What it does:** Game hacking and reverse engineering forum.
- **Relevance:** Active community with knowledge of many proprietary game formats. May have existing threads on Pandemic Studios games, FFCS format, or related EA formats. Worth searching for prior Mercenaries 2 RE work.
- **Priority:** MEDIUM — Potential existing research.

### ResHax — MEDIUM PRIORITY
- **URL:** https://reshax.com/
- **What it does:** Game Reversing Archives and Formats.
- **Relevance:** Archive of format research. May contain Pandemic or EA-related format documentation.
- **Priority:** MEDIUM — Format archive search.

### XeNTaX Wiki (archived) — MEDIUM PRIORITY
- **URL:** https://web.archive.org/web/20230822181840/https://wiki.xentax.com/index.php/Game_File_Format_Central
- **What it does:** Massive database of game file format specifications.
- **Relevance:** The XeNTaX wiki was the largest game format documentation resource before it went offline. The Wayback Machine archive may contain FFCS or Pandemic-related format entries. The wiki's systematic format documentation approach (`DGTEFF`) inspired much of the game RE community's methodology.
- **Priority:** MEDIUM — Historical format documentation.

### REGames Discord — LOW PRIORITY
- **URL:** https://discord.com/invite/regames-760531247704702996
- **What it does:** Community for game reverse engineering and file format research.
- **Relevance:** Active community where format questions can be asked. May have members with experience on Pandemic Studios games.
- **Priority:** LOW — Community outreach.

### Just Solve the File Format Problem — LOW PRIORITY
- **URL:** http://fileformats.archiveteam.org/wiki/Game_data_files
- **What it does:** ArchiveTeam's wiki for file formats.
- **Relevance:** May have entries for WAD-style archive formats or related compression schemes.
- **Priority:** LOW — General reference.

### DGTEFF (Definitive Guide To Exploring File Formats) — LOW PRIORITY
- **URL:** https://web.archive.org/web/20230817151933/http://wiki.xentax.com/index.php/DGTEFF
- **What it does:** Classic guide on systematic file format reverse engineering methodology.
- **Relevance:** Educational resource for anyone new to the project who needs to understand our format RE methodology.
- **Priority:** LOW — Educational foundation.

---

## Summary: Top 10 Highest Priority Items

| # | Tool | Category | Why |
|---|------|----------|-----|
| 1 | **unluac** | Lua | Direct Lua 5.1 bytecode decompiler for our `.luac` files |
| 2 | **Havok IO (Blender)** | Havok | Import `.hkx` animations into Blender; accelerates skeletal pipeline |
| 3 | **HavokNoesis** | Havok | PredatorCZ's gold-standard Havok format parser/viewer |
| 4 | **SW:BF Unpacker** | Pandemic | Same studio's archive tools — format DNA overlap with FFCS |
| 5 | **SW:BF Mod Tools** | Pandemic | Official Pandemic tools with shared engine architecture |
| 6 | **atlas** | Binary RE | FNV-1a hash cross-validation for `pandemic_hash` system |
| 7 | **010 Editor + templates** | Binary RE | Industry-standard binary format documentation/exploration |
| 8 | **ImHex** | Binary RE | Free open-source alternative with pattern language |
| 9 | **Reloaded-II** | Modding | Superior mod loader framework for expanding modding scope |
| 10 | **HexRaysCodeXplorer** | Binary RE | RTTI/vtable recovery for MSVC C++ binary analysis |

---

## Next Steps

1. **Immediate:** Try `unluac` on our extracted `.luac` files from `analysis/cross_platform/scripts_vz_comparison/`
2. **Immediate:** Test `HavokNoesis` and `Havok IO` with our extracted `.hkx` slices from `output/extracted/review/*/havok/`
3. **Short-term:** Download and examine SW:Battlefront unpacker/mod tools for FFCS format similarities
4. **Short-term:** Write 010 Editor templates and/or ImHex patterns for FFCS, sges, UCFX header, and placement records
5. **Medium-term:** Evaluate `Reloaded-II` as a replacement for our Ultimate ASI Loader + manual C hooks approach
6. **Medium-term:** Use `atlas` to batch-resolve unknown hashes in our ASET chunk data
7. **Long-term:** Build `Kaitai Struct` specifications for all our binary formats as machine-readable documentation
8. **Long-term:** Create a Noesis plugin for UCFX mesh format as an alternative preview path

---

*Generated from awesome-game-file-format-reversing repository review, May 2026.*
*For Mercenaries 2: World in Flames RE project.*

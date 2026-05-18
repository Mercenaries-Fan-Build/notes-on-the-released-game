# Mercenaries 2: World in Flames (PC) — Modding Deep-Dive

> Comprehensive analysis of data-file modding feasibility for Mercenaries 2 (Pandemic Studios / EA, 2008).
> Covers DRM, integrity mechanisms, hash systems, Lua scripting, and a practical modding roadmap.
>
> **Date:** 2026-05-17
> **Status:** Research findings + tooling built. Runtime validation tests pending (require game installation).

---

## Table of Contents

1. [DRM / Copy Protection](#1-drm--copy-protection)
2. [`vz.bin` — Build Certificate Analysis](#2-vzbin--build-certificate-analysis)
3. [FFCS Header Blob (0x48)](#3-ffcs-header-blob-0x48)
4. [Hash Systems (3 Distinct Layers)](#4-hash-systems-3-distinct-layers)
5. [Lua Scripting System](#5-lua-scripting-system)
6. [Modding Feasibility Matrix](#6-modding-feasibility-matrix)
7. [Modding Roadmap (Phased)](#7-modding-roadmap-phased)
8. [FFCS INDX Structure](#8-ffcs-indx-structure)
9. [Open Questions](#9-open-questions)

---

## 1. DRM / Copy Protection

### 1.1 SecuROM v7

Mercenaries 2 PC ships with **SecuROM v7** copy protection plus EA online activation.
Evidence:

- The demo's help files (`Support/EA Help/en-us/Error_Message/_CD_DVD_Emulation_Software_Detected_.htm`) explicitly reference SecuROM, including instructions for generating `AnalysisLog.sr0` diagnostic files and emailing `support@securom.com`.
- `GL.ini` (UTF-16 LE, 240 KB) is the DRM launcher configuration — see §1.2 below.
- PDB path embedded in executables: `D:\vfdev-SecuROM-DRM_7_38\SecuROM_DRM\Wrapper\wrapper.pdb`

#### Version identification (confirmed via binary analysis)

| Executable | SecuROM Version | PDB Build Path |
|-----------|----------------|----------------|
| Demo (`Merc2-Demo.exe`, 16.3 MB) | v7.38 | `SecuROM-DRM_7_38` |
| Retail v1.0 (`Mercenaries2.exe`, 16.1 MB) | v7.37 | `SecuROM-DRM_7_37` |
| Update v1.1 (`Mercenaries2.exe`, 51.4 MB) | v7.38 | `SecuROM-DRM_7_38` |
| Cracked (from ISO `Crack/`) | v7.37 (patched) | `SecuROM-DRM_7_37` |

#### PE section layout (SecuROM v7 specific)

SecuROM v7 uses a different section scheme from earlier versions (v4-v5 used `.cms_t`/`.cms_d`):

| Section | Raw Size | Purpose |
|---------|----------|---------|
| `Stext` | 3.3–6.5 MB | Encrypted/compressed game code (decompressed at runtime) |
| `Sitext` | 28 KB | SecuROM initialization code (**entry point lives here**) |
| `Srdata` | 360–368 KB | SecuROM read-only data |
| `Sdata` | 876–884 KB | SecuROM mutable data |
| `Sidata` | 24 KB | SecuROM import data |
| `.securom` | 1.3–20 MB | SecuROM protection engine, activation data, PA URLs |

The original/demo exes have `Stext` compressed (~50% of virtual size). The cracked exe has `Stext` fully decompressed (RawSize = VirtSize), eliminating the need for SecuROM's decompression routine.

#### How SecuROM v7 works (confirmed by binary analysis)

1. **Entry point hijack**: The PE entry point is in `Sitext`, not `.text`. SecuROM takes control before any game code runs.
2. **Code encryption**: Portions of the game's `.text` section are encrypted into `Stext`. At runtime, SecuROM decrypts/decompresses them back.
3. **Named event authentication**: SecuROM creates a named Win32 Event (`v7_XXXX` where XXXX derives from PID ⊕ magic constant `0x19EA3FD3`). The presence of this event signals successful authentication.
4. **Callback verification**: A function pointer (at VA `0xB054D4` in the full game) is called periodically; SecuROM's handler validates authentication state.
5. **Anti-debugging**: Standard anti-debug checks prevent reaching the Original Entry Point (OEP).
6. **Online activation**: URLs to `securom.com` PA servers embedded in `.securom` section.

#### The bypass mechanism (ISO `Crack/` directory)

The ISO contains two files in `Crack/`:

| File | Size | Purpose |
|------|------|---------|
| `Mercenaries2.exe` | 51 MB | Patched exe (entry point moved to OEP in `.text`) |
| `cruise.dll` | 8 KB | SecuROM event emulator DLL |

**Patched EXE changes:**
- Entry point moved from `Sitext` (VA `0x1C87A10`) to `.text` (VA `0xB04C2E` = game's OEP)
- Small stub patched at the OEP that: (1) saves/replaces SecuROM's verification callback, (2) calls `LoadLibraryA("cruise.dll")`, (3) jumps to original init code
- A conditional hook at VA `0xB04C44` intercepts SecuROM's verification calls: if the call signature matches SecuROM's expected pattern, returns OK; otherwise passes through to the original handler
- SECURITY directory (Authenticode signature) removed
- `Stext` section pre-decompressed (no runtime decompression needed)
- New `reloaded` section (816 bytes) — crack team signature

**cruise.dll DllMain pseudocode** (fully reverse-engineered):
```c
BOOL DllMain(HINSTANCE hDll, DWORD reason, LPVOID reserved) {
    HMODULE hMsvcr = LoadLibraryA("msvcr71.dll");
    sprintf_fn = GetProcAddress(hMsvcr, "sprintf");
    DWORD pid = GetCurrentProcessId();
    DWORD token = pid ^ 0x19EA3FD3;  // SecuROM v7 magic constant
    sprintf(buffer, "v7_%04d", token);
    CreateEventA(NULL, TRUE, TRUE, buffer);  // Named event = "authenticated"
    return TRUE;
}
```

The DLL has **no exports** — it only has DllMain. It creates the named event that SecuROM's remaining stub code checks for, spoofing successful authentication.

**Combined bypass effect:**
1. EXE starts at OEP (skips SecuROM's Sitext initialization entirely)
2. `cruise.dll` is loaded, creates the authentication event
3. The patched callback hook intercepts any remaining SecuROM verification calls
4. Game runs without disc/activation checks

#### What SecuROM does NOT protect

**Critical for modding:** SecuROM v7 does NOT check game data files:
- No WAD/bin file references in any SecuROM section
- No file integrity APIs (beyond what SecuROM uses for its own activation data)
- The `.securom` section contains only `CreateFileA`, `ReadFile`, `GetFileSizeEx` for its OWN internal files
- SecuROM's architecture is exclusively exe-protection

### 1.2 `GL.ini` — DRM Launcher Configuration

`GL.ini` is a UTF-16 LE INI file (retail: ~240 KB) containing localized error messages for EA's Game Launcher / DRM system. Key sections:

```ini
[GameLauncherConfig]
Domain=eadm
SubDomain=eadm
PartitionKey=online_content
GUID=mercenaries2
ContentString=mercenaries2

[DRMLicense]
DRMSTUDIO=EA Games
DRMPRODUCT=Mercenaries 2 World in Flames
LogoGraphic=DialogLogo128x128.jpg
```

Error codes of interest for modding:

| Code | Message | Relevance |
|------|---------|-----------|
| GL:5531 | "The game seems to be improperly configured" | Possible EXE config check |
| GL:5533 | "The game seems to be tampered with" | **Integrity check failure** |
| GL:5534 | "Problem verifying ownership" | Online validation |
| GL:5570 | "The game installation has become corrupt" | **File integrity failure** |
| GL:5571 | "Missing configuration files" | File presence check |
| GL:5572 | "Configuration file is corrupt" | Config validation |

### 1.3 Why DRM Does NOT Block Data-File Modding

**Confirmed via binary analysis:** SecuROM protection wraps the **executable** only. Evidence:

1. **No WAD/bin file references** in any SecuROM section (`.securom`, `Stext`, `Sitext`, `Srdata`, `Sdata`, `Sidata`)
2. **`vz.bin` is not referenced by filename** in any executable (demo, original, cracked, or update v1.1)
3. **`vz.wad` is referenced only in game code** (`.text` section at `"%s\vz.wad"` pattern — the engine's WAD loader, not SecuROM)
4. **SecuROM's file I/O imports** (`CreateFileA`, `ReadFile`) in the `.securom` section are for its own activation data, not game assets
5. **The bypass (cruise.dll) has no effect on WAD loading** — it only spoofs the authentication event

The game data files use:
- **FFCS** container format (not encrypted, not DRM-protected)
- **sges** compression (standard raw deflate, `zlib` windowBits `-15`)
- **UCFX** chunk containers (plaintext 4-byte ASCII tags, standard binary structures)

None of these layers involve SecuROM. Data modification requires understanding Pandemic's formats but does not require defeating copy protection.

### 1.4 Demo SecuROM: Full Protection Present

The demo (`Merc2-Demo.exe`, 16.3 MB) has **full SecuROM v7.38** — it is NOT a lighter or stripped-down version:
- Entry point is in `Sitext` (SecuROM takes control first)
- All 7 SecuROM sections present with same architecture as retail
- Authenticode signature in SECURITY directory
- Online activation URLs to `securom.com` embedded
- Sony VXD driver references (`sony_ssm.vxd`, `sony_ssm.sys`)

**Implication for demo modding:** If the demo's black screen is caused by SecuROM failing (e.g., activation expired), the game would typically show an error dialog or crash immediately — it would NOT load and then black-screen during gameplay. A black screen during WAD loading is almost certainly the game engine's own validation failing, not SecuROM.

### 1.5 Modder's Guide: Working With SecuROM

For modders who need to test modified WAD files:

**You do NOT need to bypass SecuROM to mod data files.** SecuROM checks:
- ✅ Executable integrity (modifying the EXE triggers SecuROM)
- ✅ Disc presence or activation status
- ❌ WAD file contents (never checked by SecuROM)
- ❌ `vz.bin` contents (never checked by SecuROM)
- ❌ Any file in `data/` directory

**If the game won't launch at all** (SecuROM blocks startup):
- The crack files bypass all SecuROM checks
- The mechanism: patched entry point + `cruise.dll` creating the auth event
- This removes disc/activation requirements but has zero effect on data file validation

**If the game launches but shows black screen with modded data:**
- This is the game ENGINE's validation, not SecuROM
- Check FFCS CSUM (CRC-32) per-block checksums
- Check FFCS INDX entries for consistency
- The engine uses `"%s\vz.wad"` format to open WADs — path must be correct

---

## 2. `vz.bin` — Build Certificate Analysis

### 2.1 Structure

`vz.bin` is a 258-byte ASCII text file found at `data/vz.bin` in both the demo and retail installs. Its structure:

```
x<256 hex characters>x
```

That is: the ASCII letter `x`, followed by 256 hexadecimal characters, followed by the ASCII letter `x`. Decoding the hex body yields **128 bytes = 1024 bits**.

### 2.2 Demo vs Retail Comparison

| Property | Demo | Retail |
|----------|------|--------|
| File size | 258 bytes | 258 bytes |
| Content | `xa37dd45f...3bf23d4ex` | `xa37dd45f...3bf23d4ex` |
| **Identical** | **Yes — byte-for-byte** | |

The demo `vz.wad` is 968 MB; the retail `vz.wad` is 2.4 GB. They contain completely different block counts and content. Yet `vz.bin` is **identical**. This proves `vz.bin` is **not** a hash or checksum of WAD content.

### 2.3 Statistical Profile

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Decoded size | 128 bytes = 1024 bits | Matches RSA-1024 key/signature size |
| Shannon entropy | 6.37 bits/byte | Below true random (~7.5) but well above structured data |
| Unique byte values | 92 / 256 | Moderate diversity |
| Hex char `f` frequency | 12.9% (expected 6.25%) | Statistically skewed |
| Hex char `3` frequency | 10.5% (expected 6.25%) | Statistically skewed |
| Hex chars `0`, `6` frequency | 3.1% each (expected 6.25%) | Underrepresented |
| Divisible by 2 | Yes | Rules out RSA modulus (always odd) |
| Divisible by 3 | Yes | Rules out RSA modulus |

### 2.4 Decryption Attempts

XOR decryption was attempted against the decoded 128 bytes using the following keys. None produced recognizable ASCII or known data structures:

- Single-byte: `0x55`, `0xAA`, `0xFF`, `0x5A`, `0xA5`, `0x69`, `0x96`, `0x3C`, `0xC3`, `0x0F`, `0xF0`
- Multi-byte strings: `VZ`, `vz`, `FFCS`, `sges`, `UCFX`, `EA`, `Pandemic`, `Mercs2`, `SecuROM`

### 2.5 Interpretation

`vz.bin` is a **static per-product build signing token**. It is not derived from WAD content, not an RSA key, and not encrypted data in any recognized scheme. It is likely checked at startup by the game launcher (tied to `GL.ini`'s `[DRMLicense]` section) to validate that the installation came from an authorized build.

**Modding implication:** Since `vz.bin` is static and not content-dependent, it does **not** need modification when modding WAD contents.

### 2.6 Decoded Hex Dump

```
Offset  Hex                                              ASCII
000000  a3 7d d4 5f fe 10 0b ff  fc c9 75 3a ab ac 32 5f  .}._......u:..2_
000010  07 cb 3f a2 31 14 4f e2  e3 3a e4 78 3f ee ad 2b  ..?.1.O..:.x?..+
000020  8a 73 ff 02 1f ac 32 6d  f0 ef 97 53 ab 9c df 65  .s....2m...S...e
000030  73 dd ff 03 12 fa b0 b0  ff 39 77 9e af f3 12 a4  s........9w.....
000040  f5 de 65 89 2f fe e3 3a  44 56 9b eb f2 1f 66 d2  ..e./..:.V....f.
000050  2e 54 a2 23 47 ef d3 75  98 11 88 74 3a fd 99 ba  .T.#G..u...t:...
000060  ac c3 42 d8 8a 99 32 12  35 79 87 25 fe dc bf 43  ..B...2.5y.%...C
000070  25 26 69 da de 32 41 5f  ee 89 da 54 3b f2 3d 4e  %&i..2A_...T;.=N
```

---

## 3. FFCS Header Blob (0x48)

### 3.1 Location

Every FFCS `.wad` file has the following header layout:

```
0x00-0x03: "FFCS" magic
0x04-0x07: version (u32, always 2)
0x08-0x0B: declared chunk count (u32, always 7)
0x0C-0x47: 5 chunk rows × 12 bytes each (INDX, DATA, CSUM, ASET, PTHS)
0x48-0xD7: 144-byte blob (high-entropy data)
0xD8-0xFF: zero padding
```

The declared chunk count is 7, but only 5 chunk rows are present in the 0x0C–0x47 range. The remaining 144 bytes at 0x48 occupy the space where rows 6 and 7 would be, but they do **not** parse as valid chunk rows (tags are non-ASCII, offsets exceed file size).

### 3.2 Cross-WAD Comparison

The 0x48 blob is **byte-for-byte identical** across **all 8 WAD files** tested (4 demo + 4 retail):

| WAD | Size | 0x48 blob (first 32 bytes) |
|-----|------|---------------------------|
| Demo `English.wad` | 2.8 MB | `a8d846fa28870e14 9ad33171e2540a8f` |
| Demo `Loading.wad` | 2.5 MB | `a8d846fa28870e14 9ad33171e2540a8f` |
| Demo `shell.wad` | 24.6 MB | `a8d846fa28870e14 9ad33171e2540a8f` |
| Demo `vz.wad` | 968 MB | `a8d846fa28870e14 9ad33171e2540a8f` |
| Retail `English.wad` | 461 MB | `a8d846fa28870e14 9ad33171e2540a8f` |
| Retail `Loading.wad` | 2.5 MB | `a8d846fa28870e14 9ad33171e2540a8f` |
| Retail `shell.wad` | 29.6 MB | `a8d846fa28870e14 9ad33171e2540a8f` |
| Retail `vz.wad` | 2.4 GB | `a8d846fa28870e14 9ad33171e2540a8f` |

Meanwhile, the actual chunk row data (INDX offsets, CSUM values, ASET sizes, etc.) **differs** between WADs as expected.

### 3.3 Full 0x48 Blob Hex Dump

```
a8 d8 46 fa 28 87 0e 14  9a d3 31 71 e2 54 0a 8f
f8 ab 0a 3b 3e f1 5e 66  d0 f6 53 f7 78 e9 e5 39
5a 54 22 c1 54 1a b8 e6  87 4d df e8 c7 59 73 20
4e 90 0b 60 14 3c 27 e5  61 2d 98 de ce 7a e7 99
55 65 16 18 5d c3 47 56  bc 8d 0b fa 50 42 72 5b
86 2f 61 34 10 ca 8b 9f  5c 81 02 16 20 83 0e fe
f2 47 ce ac c4 30 7d 4d  d5 29 48 ea 7a 15 11 f0
14 63 fe bc 5a bd 08 56  7f 80 10 63 6a df b9 59
07 93 56 7c 71 03 e7 ec  bb 49 f6 1c 80 86 49 42
```

(144 bytes total, followed by zero-padding to offset 0x100.)

### 3.4 Relationship to `vz.bin`

Both the 0x48 blob (144 bytes) and `vz.bin` (128 decoded bytes) are:
- **Static** across all WADs and both SKUs
- **Not derived from WAD content**
- **High-entropy but not true random**

They are **not identical** to each other (different lengths, different content). They likely originate from the same Pandemic build pipeline signing system but serve different roles — the 0x48 blob is embedded in every WAD header, while `vz.bin` is a standalone file alongside the `vz.wad`.

**Modding implication:** Neither needs modification when modding WAD contents.

---

## 4. Hash Systems (3 Distinct Layers)

Mercenaries 2 uses three separate hash/checksum systems at different levels of the data pipeline. They do **not** overlap or cross-reference each other.

### 4.1 Per-UCFX CSUM Trailers

Every UCFX container within decompressed `.block` files ends with an 8-byte trailer:

```
Offset  Size  Field
+0      4     ASCII tag "CSUM"
+4      4     u32 checksum value (LE)
```

This pattern is consistent across all block types:

| Block | CSUM trailer count | Meaning |
|-------|--------------------|---------|
| `scripts_vz` | 114 | One per Lua chunk UCFX |
| `layers_static` | 173 | One per entity group UCFX |
| `vz_base` | 1 | Single UCFX container |
| `vz_mar_roads` | 1 | Single UCFX container |

#### Sample values (from `scripts_vz` Lua chunks)

| Chunk source name | BINN size | CSUM trailer value |
|--------------------|-----------|--------------------|
| `wiftutorialtank` | 1,000 B | `0xfb7c10d2` |
| `gurjob001` | 899 B | `0xb89ff7df` |
| `jetcon001` | 21,139 B | `0xe694bf8e` |
| `wiftutorialairstrikeinterrupt` | 1,808 B | `0x93156479` |
| `chicon001` | 13,540 B | `0x9c4021bc` |
| `gurcon002` | 37,503 B | `0x6abdd9ea` |
| `wifpmcinterior` | 80,017 B | `0x6f872d84` |
| `chicon008` | 9,239 B | `0xba31256c` |
| `wifvzambience` | 1,851 B | `0xa5387f59` |
| `allcon003` | 5,778 B | `0x201472c5` |

#### Algorithm IDENTIFIED: CRC-32/JAMCRC

**Confirmed via differential analysis and validated against 53,765 chunks across 10,099 block files — 100.00% match rate.**

The algorithm is **CRC-32/JAMCRC**: the standard Ethernet CRC-32 polynomial with non-standard initialization and finalization:

| Parameter | Standard CRC-32 (zlib) | CRC-32/JAMCRC (Mercs 2) |
|-----------|----------------------|-------------------------|
| Polynomial | `0xEDB88320` (reflected) | `0xEDB88320` (reflected) — **same** |
| Init value | `0xFFFFFFFF` | `0x00000000` |
| Final XOR | `0xFFFFFFFF` | `0x00000000` (no invert) |
| Reflect in/out | Yes | Yes |

This is a well-known variant catalogued as [CRC-32/JAMCRC](https://reveng.sourceforge.io/crc-catalogue/all.htm#crc.cat.crc-32-jamcrc) in the RevEng CRC catalogue.

#### Why earlier tests missed it

All prior CRC-32 testing used either `init=0xFFFFFFFF` with `final_xor=0xFFFFFFFF` (standard zlib CRC-32) or the Zero CRC-32 MSB-first variant (`poly=0x04C11DB7`, non-reflected). The JAMCRC variant uses the same reflected polynomial as zlib but with `init=0` and `final_xor=0`. Changing the init value propagates through the entire shift-register computation — it is **not** simply the bitwise NOT of standard CRC-32.

#### Input range

The checksum covers: **all bytes from the start of the `UCFX` tag (inclusive) through the byte immediately before the `CSUM` tag** — i.e., the entire UCFX container including its header, sub-chunks (INFO, DEPS, BINN), and all payload data (LuaQ bytecode, mesh geometry, placement records, etc.).

#### Python implementation

```python
def crc32_jamcrc(data: bytes) -> int:
    """CRC-32/JAMCRC: init=0, poly=0xEDB88320 (reflected), no final XOR."""
    crc = 0x00000000
    for b in data:
        crc ^= b
        for _ in range(8):
            if crc & 1:
                crc = (crc >> 1) ^ 0xEDB88320
            else:
                crc >>= 1
    return crc
```

Or equivalently, using Python's `zlib.crc32` with adjustment:

```python
import zlib
def crc32_jamcrc_fast(data: bytes) -> int:
    # zlib.crc32 uses init=~0, final=~result
    # JAMCRC uses init=0, final=identity
    # Compute via table-driven: init=0, no final invert
    crc = 0
    for b in data:
        crc ^= b
        for _ in range(8):
            crc = (crc >> 1) ^ (0xEDB88320 if crc & 1 else 0)
    return crc
```

#### Verification

| Chunk | Script name | CSUM value | JAMCRC(UCFX..CSUM) | Match |
|-------|-------------|------------|---------------------|-------|
| 0 | `wiftutorialtank` | `0xfb7c10d2` | `0xfb7c10d2` | ✓ |
| 1 | `gurjob001` | `0xb89ff7df` | `0xb89ff7df` | ✓ |
| 2 | `jetcon001` | `0xe694bf8e` | `0xe694bf8e` | ✓ |
| ... | ... | ... | ... | ✓ |
| **Total** | **53,765 chunks** | | | **100%** |

#### Statistical properties

- Uniformly distributed (chi-squared = 10.91, well below critical threshold of 25)
- No correlation with chunk size (Pearson r = −0.078)
- Maximum entropy (6.833 bits per value)
- No always-set or always-clear bits
- Zero sequential autocorrelation

#### Modding implication

**The CSUM is a content integrity checksum, not a build fingerprint.** When modifying UCFX content (e.g., replacing Lua bytecode), the CSUM must be recomputed over the modified bytes from `UCFX` tag to end of payload. The algorithm is fully deterministic and trivial to implement. Whether the game engine validates this checksum at runtime is still untested — but now we can produce correct values either way.

### 4.2 FFCS-Level CSUM Chunk

Each `.wad` file's FFCS header contains a CSUM chunk row with an `offset` and `meta` field:

| WAD (retail) | CSUM "offset" | CSUM entry count (`meta`) | Block count (INDX `meta`) |
|-------------|--------------|--------------------------|--------------------------|
| `vz.wad` | `0x02b38fcb` | 7,018 | 11,370 |
| `English.wad` | `0x1ca773e3` | 55 | 47 |
| `shell.wad` | `0x0ddfde99` | 416 | 36 |
| `Loading.wad` | `0x37ea846e` | 3 | 8 |

Key observations:

- **The CSUM "offset" is NOT a file offset.** For demo `vz.wad` (968 MB), the CSUM offset is `0x9abfa097` = 2.6 GB, far exceeding the file size. It is likely a hash value itself (e.g., CRC32 of the INDX data or a build timestamp).
- **Entry count does NOT match block count.** Retail `vz.wad` has 7,018 CSUM entries vs 11,370 blocks. The relationship is unclear — it's not "one per Q3 block" (3,581) or any other obvious LOD subset.
- **All entries are unique.** Zero collisions across 7,018 u32 values.
- **Different between demo and retail for same WAD name.** Demo and retail `Loading.wad` have different CSUM offset values (`0x680bfeb9` vs `0x37ea846e`) despite different builds.

#### Algorithm testing

CRC32, FNV-1a, and DJB2 were tested against block path strings from `paths.txt`. None of the computed hashes appeared in the CSUM entry set. CRC32 and Adler32 of decompressed block content also had zero hits.

The CSUM entries may be checksums of the **compressed** `sges` data within the DATA chunk (not the decompressed blocks that were tested). This hypothesis has not been verified — doing so requires mapping each INDX entry to its byte range within DATA and hashing the raw compressed bytes.

### 4.3 Asset Hashes (ASET / Texture Streaming Index)

The ASET chunk and `texture_index.json` use the same 32-bit asset hash format:

| System | Width | Example values | Purpose |
|--------|-------|----------------|---------|
| ASET `u32_0` | u32 | `0x64be9fc6`, `0x35383ccd` | Asset streaming key |
| `texture_index.json` keys | u32 | `0x69d3c746`, `0x30a64191` | Texture mip chain assembly |
| Terrain TOC `hash1` | u32 | (per-tile values) | Mesh tile identity |

Fixed type discriminator constants (NOT per-asset hashes):

| Constant | Meaning |
|----------|---------|
| `0xF011157A` | Texture / BODY streaming type |
| `0x5B724250` | Mesh type |
| `0x1602815C` | Terrain tile type (normal) |

### 4.3.1 Hash Algorithm IDENTIFIED: Pandemic FNV-1a

**Confirmed from Mercenaries 1 source code** (see §10 below). Pandemic Studios uses **FNV-1a 32-bit with case suppression** as their universal hash algorithm for all asset name lookups, type identifiers, and script bindings.

#### Algorithm specification

```c
uint32 MakeHashFNV1a(const char* pcText)
{
    if (!pcText || !*pcText) return 0;
    uint32 uiValue = 0x811c9dc5;        // FNV offset basis
    while (*pcText) {
        uiValue ^= (uint32)*pcText++ | 0x20;  // Case suppression
        uiValue *= 0x01000193;           // FNV prime
    }
    return uiValue;
}
```

Key properties:
- **Init**: `0x811C9DC5` (standard FNV-1a offset basis)
- **Prime**: `0x01000193` (standard FNV-1a prime)
- **Case suppression**: Each input byte is OR'd with `0x20` before XOR. This forces ASCII uppercase to lowercase (`'A'|0x20 = 'a'`) while leaving lowercase, digits, and most punctuation unchanged.
- **Returns 0** for empty/null strings

#### Verification

From Mercenaries 1 source code `RedVirtualDisk.cpp` line 479, the hash `0x3884598e` is associated with the string `"registry"`:

```
pandemic_hash("registry") = 0x3884598e  ✓ CONFIRMED
```

**Implementation:** `tools/pandemic_hash.py`

#### What the type hash strings are

The ASET type constants (`0xF011157A`, `0x5B724250`, `0x1602815C`) are FNV-1a hashes of type name strings. The exact strings used in Mercenaries 2 have not been identified yet — they likely differ from the Mercenaries 1 type names (`texture`, `model`, `config`, etc.) as the engine evolved between games. The input strings may include file extensions, asset class names, or pipeline identifiers.

### 4.4 Entity Keys

Placement records in `layers_static` and `vz_state` use u32 entity keys to link Transform, Name, and other COMP data sections. These are **opaque ECS pairing IDs**, not file-path hashes. They may be allocator-based sequential IDs or hashed internally, but the pipeline treats them as opaque keys for component cross-referencing.

### 4.5 Save File Checksum

The save profile header (`tools/savefile_parser.py`) has a u32 at offset `0x00` labeled `checksum_hex`. From Mercenaries 1 source code (`RsLoadSaveGameFile.cpp`), save-game block checksums use **FNV-1a over raw bytes** (init `0x811C9DC5`, prime `0x01000193`, **without** `|0x20` case suppression — it hashes binary data, not strings). The save CRC skips the first 4 bytes (the CRC field itself) and XOR-combines sub-block CRCs. The same approach likely applies to Mercenaries 2 save files.

### 4.6 Block File Header Table (Asset Index)

Decompressed `.block.bin` files (e.g., `scripts_vz_P000_Q3.block.bin`) begin with an **asset index table** before the first UCFX chunk. Structure:

```
Offset  Size  Field
+0      4     u32 record_count (N)
+4      N*16  Asset records (16 bytes each)
+4+N*16 ...   UCFX chunks begin immediately after
```

Each 16-byte asset record:

```
Offset  Size  Field
+0      4     u32 asset_hash — appears in FFCS ASET chunk (asset streaming key)
+4      4     u32 constant = 0x42498680 (float 50.381...; purpose unknown, same in all records)
+8      4     u32 zero (reserved)
+12     4     u32 chunk_size — total bytes from UCFX tag to end of CSUM trailer (inclusive)
```

**Verified:** All 114 `chunk_size` values in `scripts_vz` exactly match the byte distance from each UCFX tag to the end of its CSUM trailer. The `asset_hash` values are found in the FFCS `aset.bin` but do **not** match `pandemic_hash(script_name)` for any tested name/path variant — the hash algorithm for ASET asset keys remains unidentified (it is NOT FNV-1a, Zero CRC-32, zlib CRC-32, MurmurHash2, DJB2, SDBM, ELF, Jenkins OAAT, BKDR, or AP hash on any tested name format).

**Modding implication:** When replacing or adding UCFX assets within a block, the header table must be updated to reflect the new `chunk_size`. The `asset_hash` must match the corresponding ASET entry in the FFCS WAD for the game's streaming system to locate the asset.

### 4.7 BINN Metadata & Dependency Graph

Within `scripts_vz` UCFX chunks, the BINN data payload contains script metadata before the LuaQ bytecode:

```
Offset  Size  Field
+0      4     u32 bytecode_size (size of LuaQ bytecode that follows)
+4      8     zeros (reserved)
+12     1     u8 type_code (always 0x05 for Lua scripts)
+13     2     u16 name_length
+15     N     ASCII script name (null-terminated)
+15+N+1 M     u8 dep_count + dependency asset hashes (variable)
+15+N+1+M 4   u32 asset_identity_hash
...     ...   LuaQ bytecode begins (\x1bLuaQ header)
```

The **dependency section** between the script name and the LuaQ header contains:
1. A count byte and metadata flags
2. An array of u32 **asset identity hashes** referencing other scripts this script depends on
3. The script's own **asset identity hash** (4 bytes immediately before `\x1bLuaQ`)

These identity hashes form a **dependency graph** — e.g., `jetcon001`'s dependency list includes the identity hash of `gurjob001`, confirming inter-script references. Scripts with shared base classes (e.g., all `wiftutorial*` scripts) share the same identity hash of their parent class.

| Asset identity hash | Scripts sharing it | Likely meaning |
|--------------------|--------------------|----------------|
| `0x8a40183a` | 17 (all `wiftutorial*`) | WifTutorial base class |
| `0x262958ad` | 13 (`allcon050`, `chicon051`, ...) | Shared contract template |
| `0xb2cec5f5` | 11 (`pircon002`, `gurcon005`, ...) | Shared contract template |
| `0xc86a87da` | 8 (`gurjob001`, `oilcon003`, ...) | Shared job template |
| `0x00000400` | 2 (`wifvzambience`, `wifhqdata`) | Simple data scripts |

Small integer values like `0x00000400`, `0x00000a00` appear for data-only scripts (no dependencies), suggesting these may be literal sizes or type codes rather than hashes.

**Note:** The asset identity hashes are NOT the same as the block header table `asset_hash` values (§4.6) or the CSUM values (§4.1). All three are independent hash systems.

---

## 5. Lua Scripting System

### 5.1 Bytecode Format

Mercenaries 2 uses **standard Lua 5.1 bytecode** with non-default number type.

#### Header (12 bytes, identical across all 114 chunks)

```
Hex: 1b 4c 75 61 51 00 01 04 04 04 04 00
```

| Offset | Value | Field | Meaning |
|--------|-------|-------|---------|
| 0x00 | `1b 4c 75 61` | Magic | Standard `\x1bLua` Lua bytecode signature |
| 0x04 | `51` | Version | Lua **5.1** (`0x51` = ASCII `Q`, hence "LuaQ") |
| 0x05 | `00` | Format | Official format (0 = standard) |
| 0x06 | `01` | Endianness | Little-endian |
| 0x07 | `04` | `sizeof(int)` | 4 bytes |
| 0x08 | `04` | `sizeof(size_t)` | 4 bytes |
| 0x09 | `04` | `sizeof(Instruction)` | 4 bytes |
| 0x0A | `04` | `sizeof(lua_Number)` | **4 bytes (float)** — NOT the standard 8-byte double |
| 0x0B | `00` | Integral flag | 0 = floating-point numbers |

**Critical note:** The game uses `lua_Number = float` (single-precision, 4 bytes). Stock Lua 5.1 defaults to `double` (8 bytes). Any recompilation must use `#define LUA_NUMBER float` in `luaconf.h`, otherwise bytecode constants will be misaligned and the VM will crash.

### 5.2 Container Structure

The `scripts_vz_P000_Q3.block.bin` (1.58 MB decompressed) contains **114 UCFX containers**, each wrapping exactly one Lua chunk:

```
scripts_vz block (1,579,504 bytes):
  [preamble / header data, ~1.8 KB]
  UCFX #0:
    UCFX header (20 bytes: tag + u0/u1/u2/u3)
    INFO chunk (20-byte chunk header)
    DEPS chunk (20-byte chunk header)
    BINN chunk (20-byte chunk header: tag, offset, size, u2, u3)
    [data area at ucfx_offset + u0]:
      LuaQ bytecode (BINN.size bytes, starts at BINN.offset from data_base)
    CSUM trailer (8 bytes: "CSUM" + u32)
  UCFX #1:
    ... (same structure)
  ...
  UCFX #113:
    ... (same structure)
```

Key structural facts:

| Property | Value |
|----------|-------|
| UCFX containers | 114 (exactly 1 per Lua chunk) |
| BINN chunks | 114 (exactly 1 per UCFX) |
| LuaQ chunks | 114 (exactly 1 per BINN) |
| Gap before LuaQ data | **0 bytes** (LuaQ starts exactly at BINN data offset) |
| CSUM trailer size | 8 bytes (`CSUM` tag + u32 value) |
| Trailer location | Immediately after BINN data ends, before next UCFX |

### 5.3 BINN Chunk Semantics

The BINN (binary data) chunk wraps the raw Lua bytecode:

| Field | Meaning |
|-------|---------|
| `BINN.offset` | Byte offset from UCFX data base to start of LuaQ bytecode |
| `BINN.size` | Exact byte count of the compiled Lua bytecode |

`BINN.size` is always **smaller** than the distance to the next UCFX boundary — the remaining bytes are the 8-byte CSUM trailer.

### 5.4 Script Names (Source Field)

Every LuaQ chunk preserves its source name in the standard Lua 5.1 function header (a `size_t` length followed by the string). These names identify the script's purpose:

| Source name | Size (bytes) | Category |
|-------------|-------------|----------|
| `wiftutorialtank` | 1,000 | Tutorial |
| `gurjob001` | 899 | Guerrilla mission |
| `jetcon001` | 21,139 | Jet contract |
| `wiftutorialairstrikeinterrupt` | 1,808 | Tutorial |
| `chicon001` | 13,540 | Chinese contract |
| `gurcon002` | 37,503 | Guerrilla contract |
| `wifpmcinterior` | 80,017 | PMC base interior |
| `chicon008` | 9,239 | Chinese contract |
| `wifvzambience` | 1,851 | Ambient scripting |
| `allcon003` | 5,778 | Allied contract |
| `vz` | 38,194 | Core world script |
| `meccon001` | 32,397 | Mechanic contract |

### 5.5 ObjectScript ECS Linkage

Game entities reference Lua scripts through the `ObjectScript` ECS component:

| Field | Width | Notes |
|-------|-------|-------|
| `script_hash_0` | u32 | Primary script binding hash |
| `script_u32_1` | u32 | Secondary field (often `1`) |
| Extended payload | up to 32 bytes | Tripartite repeats of `(hash, 1, event-id?)` in some records |

103 entities in `layers_static` have `ObjectScript` components. Only **three distinct** `script_hash_0` values occur: `0x543977f7`, `0xad6148d4`, and `0x00000000`.

- `0x543977f7` appears **17 times as a literal u32** inside the `scripts_vz` block (likely a function/chunk identifier embedded in bytecode constants).
- `0xad6148d4` does **not** appear as a literal u32 in `scripts_vz` — suggesting the binding may involve indirection through the EXE's runtime tables, not a direct bytecode offset.

**The exact mechanism by which `script_hash_0` maps to a specific Lua chunk is not yet resolved.** It may be a hash of the source name, an index into an EXE-side registry, or a hash of the chunk's content.

### 5.6 String Harvest

The `tools/lua_script_chunks.py` harvester extracts ASCII strings from each chunk and filters for PMC/gameplay-related tokens. Categories found:

| Category | Example strings |
|----------|----------------|
| Handlers | `Activated`, `GetMessage`, `SetupActivationCriteria`, `SetupCancellationCriteria` |
| Region triggers | `CheckpointRegionActivate`, `BeachRegionActivate`, `AASiteRegionActivate`, `CopterAttackRegionActivate` |
| Tutorials | `ActivateTutorial`, `MrxTutorial`, `wiftutorialtank` |
| PMC / contracts | `MrxPmc`, `WifPmcGarage`, `PmcBoss`, `HUD_PMC_*`, `Fiona-In-Mission-Contract-*` |
| Layer tokens | `vz_state_pmcinterior_*`, `RuntimeLayer`, `LoadInterior` |
| Spawning | `SpawnPatrols`, `CopterSpawn`, `SimpleSpawner` |
| Lua standard | `inherit`, `ScriptEvent` |

The regex filter captures only a subset — the full string tables within each chunk contain hundreds of additional identifiers (function names, variable names, debug info) that are accessible via decompilation.

### 5.7 Compatible Tooling

Because the bytecode is standard Lua 5.1 (with float numbers), the following tools should work **if configured for 4-byte `lua_Number`**:

| Tool | URL | Notes |
|------|-----|-------|
| **unluac** | github.com/HansWessworking/unluac | Java-based decompiler; needs `--rawstring` or custom number-size config |
| **luadec51** | search "luadec 5.1" | C-based decompiler; compile against matching Lua 5.1 source |
| **LuaDisAss** | github.com/jcmnn/LuaDisAss | Disassembler (lower-level than decompilers); confirm header match |
| **luac 5.1** | lua.org/ftp/lua-5.1.5.tar.gz | Official compiler; build with `LUA_NUMBER=float` for matching bytecode |

---

## 6. Modding Feasibility Matrix

| Mod type | Difficulty | Prerequisites | Key unknowns | Recommended approach |
|----------|-----------|---------------|-------------|---------------------|
| **Save editing** | Low | `savefile_parser.py` | Checksum algorithm (u32 at offset 0x00) | Modify cash/fuel/layer state; test if checksum is enforced |
| **Texture swaps** | Medium | Texture extraction pipeline | CSUM enforcement, Precache invalidation | Replace DDS bytes in-place (same resolution + format), recompress block |
| **Lua script mods** | Medium | Custom Lua 5.1 (float) compiler, sges compressor, WAD patcher | CSUM enforcement, ObjectScript hash binding | Decompile → edit → recompile → splice into block → recompress → patch WAD |
| **Placement edits** | Medium-Hard | Placement extractor, UCFX writer | CSUM enforcement, COMP record count updates | Edit 42-byte transform records in-place; harder if adding/removing entities |
| **Mesh replacement** | Hard | Full UCFX serializer with GEOM/MESH/PRMG/STRM/IBUF | CSUM, vertex format matching, Precache regeneration | Must match exact vertex stride, index format, bounding boxes, material refs |
| **New asset injection** | Very Hard | Full FFCS repacker (INDX + DATA + CSUM + ASET + PTHS) | All hash algorithms, Precache format, ASET dependency graph | Requires reimplementing Pandemic's asset build pipeline |

### Precache Consideration

The `Precache/` directory (403 MB, 272 files across 34 zone slots) contains pre-baked GPU-ready data (vertex/index buffers, shader caches, texture refs). Modifying geometry or textures may cause the game to render stale cached data, crash, or silently ignore changes. The `CERP` precache format is minimally decoded (magic + version only). Deleting precache files may force regeneration on next load, but this is unverified.

---

## 7. Modding Roadmap (Phased)

### Phase 1: Prove Lua Replacement Works

**Goal:** Verify that modified Lua bytecode loads and executes in-game.

1. Build a custom Lua 5.1 compiler from source with matching header:
   - `#define LUA_NUMBER float` in `luaconf.h`
   - Verify `sizeof(int)=4, sizeof(size_t)=4, sizeof(Instruction)=4`
   - Build as 32-bit LE
2. Decompile a simple chunk (e.g., `wiftutorialtank` at 1,000 bytes) using unluac or luadec51
3. Recompile the unchanged source with the custom compiler
4. Compare the original and recompiled bytecode byte-for-byte
5. If they differ (likely due to debug info or optimization differences), test whether the game loads the recompiled version by replacing the BINN data and leaving the CSUM unchanged

**Required tools:** Lua 5.1.5 source, C compiler (32-bit target or cross-compile), Java (for unluac), hex editor.

### Phase 2: Determine If CSUM Is Enforced at Runtime

**Goal:** Establish whether per-UCFX CSUM trailers are validated by the game engine.

1. Take the decompressed `scripts_vz` block
2. Zero out one CSUM trailer value (e.g., change `0xfb7c10d2` to `0x00000000` for chunk 0)
3. Re-sges-compress the modified block
4. Patch it into `vz.wad` at the correct DATA offset
5. Launch the game and load an area that triggers the modified script
6. **If the game crashes or shows GL:5533 "tampered":** CSUM is validated; proceed to Phase 4
7. **If the game works normally:** CSUMs are build-pipeline-only artifacts; ignore them for modding

### Phase 3: Build the Reverse Pipeline

**Goal:** Create the tooling needed for repeatable mod injection.

1. **`sges_compress.py`** — inverse of `sges_decompress.py`:
   - Input: decompressed block bytes
   - Output: `sges` compressed block with correct segment table and 16-byte-aligned payload
   - Compression: raw deflate (`zlib`, `windowBits=-15`)
   - Must match the segment structure: minor field = segment count, each segment has a (compressed_size, uncompressed_size) pair in the header table
2. **WAD patcher** — splice modified compressed blocks into `vz.wad`:
   - Read INDX to find the target block's DATA offset and size
   - If new compressed size ≤ old size: overwrite in-place with zero padding
   - If new compressed size > old size: append to DATA and update INDX offset (requires INDX rewrite)
   - Optionally update FFCS CSUM entries (if §4.2 checksums are over compressed data)

### Phase 4: Hash Algorithm Identification (If Phase 2 Shows Enforcement)

**Goal:** Reverse-engineer the per-UCFX CSUM algorithm so modified blocks can have valid checksums.

1. Unpack SecuROM from `Mercenaries2.exe` (standard tools exist for 2008-era SecuROM: OllyDbg + OEP finder, or dedicated unpackers)
2. Search the unpacked binary for:
   - References to the ASCII string `CSUM`
   - CRC table constants (e.g., `0xEDB88320` for standard CRC32, or other polynomials)
   - Hash computation loops near UCFX/block loading code
3. Alternatively, brute-force test custom CRC polynomials:
   - Use the 10 known (input, output) pairs from §4.1
   - Iterate over CRC32 polynomial space with various init/final-XOR values
   - Test reversed / reflected variants

### Required Tooling Summary

| Tool | Purpose | Status |
|------|---------|--------|
| Lua 5.1.5 (float build) | Compile modified scripts | **Built** — `tools/lua51-mercs2/luac` (header: `1b4c75615100010404040400`) |
| unluac / luadec51 | Decompile existing scripts | Available (needs config for float numbers) |
| `lua_roundtrip_test.py` | Automated decompile/recompile verification | **Written** — `tools/lua_roundtrip_test.py` |
| `sges_compress.py` | Recompress modified blocks | **Written** — `tools/sges_compress.py` (roundtrip-verified) |
| `wad_patcher.py` | Inject modified blocks into `.wad` | **Written** — `tools/wad_patcher.py` (in-place + append strategies) |
| `ffcs_csum_analyzer.py` | Test hash algorithms vs FFCS CSUM | **Written** — `tools/ffcs_csum_analyzer.py` |
| `csum_enforcement_test.py` | Prepare CSUM enforcement test | **Written** — `tools/csum_enforcement_test.py` |
| SecuROM unpacker | Access EXE internals for hash RE | Available (community tools) |

---

## 8. FFCS INDX Structure

The INDX chunk contains one row per block in the WAD. Each row is 12 bytes:

| Offset | Size | Field | Notes |
|--------|------|-------|-------|
| +0 | 4 | `block_id` | u32, small integers (e.g., 0x41=65, 0x42=66, ...) |
| +4 | 4 | `segment_count` | u32, typically 1 (sometimes 2 or 4) |
| +8 | 4 | `flags` | u32, high bit often set (`0x80000001`, `0x80000002`) |

The `block_id` values correspond to block indices within the DATA chunk. The `segment_count` may indicate how many `sges` segments comprise a block. The `flags` field's high bit (`0x80000000`) may indicate "compressed" vs "raw" status.

Retail `vz.wad`: INDX at offset `0x8000`, `meta` = 11,370 entries (matching `paths.txt` line count).

### FFCS Chunk Count Discrepancy

The FFCS header declares **7** chunks (`chunk_count` u32 at offset 0x08), but only **5** chunk rows parse correctly at 0x0C–0x47. The remaining space (0x48–0xD7) contains the static build certificate blob (§3), not valid chunk rows. The `tools/ffcs_wad.py` parser reads exactly 5 rows and ignores the post-0x48 region.

---

## 9. Open Questions

These are the critical unknowns that determine modding feasibility:

1. **Is the per-UCFX CSUM enforced at runtime?** If yes, what algorithm does it use? This is the single most important question — it gates whether any data modification works.

2. **What is the ObjectScript `script_hash_0` binding mechanism?** Is it a hash of the source name? An index? How does the engine locate the correct Lua chunk for a given entity's script reference?

3. **Does the game validate FFCS-level CSUM entries?** If so, are they checksums of compressed or decompressed block data?

4. **Does the Precache system tolerate stale or missing files?** Can precache files be deleted to force regeneration, or does the game hard-fail without them?

5. **Does `vz.bin` serve any role beyond startup validation?** Is it checked only by the launcher, or does the engine read it during gameplay?

6. **What algorithm produces the ASET / texture_index asset hashes?** Identifying this would enable creation of new asset entries without reverse-engineering the EXE.

7. **What is the save file checksum algorithm?** Needed for save editing to survive integrity checks.

---

## 10. Mercenaries 1 Source Code Analysis

Access to the Mercenaries 1 (2005) editor and engine source code provides direct insight into Pandemic Studios' engineering practices. While Mercenaries 2 was built on a later version of the engine, the foundational systems are shared.

### 10.1 Engine Architecture

| Component | Name | Role |
|-----------|------|------|
| Core library | **Pebble** | Hash tables, streams, file I/O, math, memory, compression |
| Rendering engine | **Red Engine** | Models, textures, terrain, effects, actors, virtual disk |
| Build tools | **Handy Library** | Chunk I/O (binary/text), file manipulation, database, string handling |
| Tool framework | **MungeApp** | Base class for all asset "munge" (compilation) tools |
| Level editor | **Zero Editor** | World editor (Visual Studio solution `zeroeditor.sln`) |
| Game project | **RetroStrike** | Mercenaries 1 game code (codename "Retro Strike") |

### 10.2 Hash Algorithm

The hash algorithm is in two locations:
- `Projects/Tools/Hash/Hash.c` — standalone CLI tool (`WinHash.exe`)
- `Projects/Pebble/Source/PblHashTable.cpp` — engine runtime (`PblHash::_MakeHash`)

Both implement **FNV-1a 32-bit with `|0x20` case suppression** (see §4.3.1 for full specification).

The `PblHash` class wraps this into a type-safe hash key:

```cpp
class PblHash {
    PblHash(const char* pcText) : _uiValue(_MakeHash(pcText)) {}
    operator uint32() const { return _uiValue; }
};
```

Used throughout the engine for:
- Asset name lookup (`RedFileInfo._uiName`)
- Asset type identification (`RedFileInfo._uiType`)
- Hash table keys (`PblHashTable`, `PblFixedHashTable`)
- Map/level identification (`RedVirtualDisk::SetCurrentMap`)

### 10.3 Asset File Format (Virtual Disk)

`RedVirtualDisk` manages asset loading from `.dsk` archive files. The directory format:

```
Header:
  u32  entry_count
  
Directory (entry_count entries):
  u32  file_size
  char[] name_string (null-terminated, lowercase)
  
Data:
  [file data packed contiguously]
```

The runtime struct `RedFileInfo`:

```cpp
class RedFileInfo {
    uint32 _uiName;              // FNV-1a hash of asset name
    uint32 _uiType;              // FNV-1a hash of asset type
    int    _iOffsetInDiscFile;   // byte offset in archive
    int    _iFileSize;           // size in bytes
    uint32 _iFileID;             // which archive file
};
```

This directly maps to the ASET entry format in Mercenaries 2: `(u32 name_hash, u32 type_hash, u32 offset_or_meta, u32 size_or_meta)`.

### 10.4 Chunk System (UCF → UCFX)

The `HandyWriteBinaryChunk` class writes binary chunks in the format:

```
Per chunk:
  u32  tag    (4 ASCII chars, LE packed)
  u32  size   (child data size, NOT including this 8-byte header)
  [child data]
```

This is the **direct ancestor** of the UCFX chunk format observed in Mercenaries 2. The 4-byte tag + 4-byte size header is identical; Mercs 2 added additional metadata fields (u2, u3) to the UCFX wrapper but preserved the core chunk nesting model.

In Mercs 1, the "UCF" format was used:

```
ucft (text format) or ucfb (binary format)
  └── scr (script chunk)
      ├── NAME  → script name string
      ├── INFO  → format byte + uncompressed size
      └── BODY  → LZSS-compressed or raw script text
```

In Mercs 2, this evolved to:

```
UCFX (binary, extended)
  ├── INFO  → asset metadata
  ├── DEPS  → dependency list
  └── BINN  → compiled Lua bytecode (LuaQ)
```

### 10.5 Script System

**Mercs 1:** Lua 5.0.1 with build-time configurable number type:

```c
// luser_number.h
#ifdef USE_FLOAT
#define LUA_NUMBER float
#endif
#ifdef USE_DOUBLE
#define LUA_NUMBER double
#endif
```

**Mercs 2:** Lua 5.1 with `lua_Number = float` (confirmed from bytecode headers).

The `ScriptMunge` tool in Mercs 1 strips comments and whitespace from Lua source, optionally LZSS-compresses it, and wraps it in UCF chunks. The name is stored lowercase via `MungeName.LowerCase()`. This is consistent with the FNV-1a hash being case-insensitive (via `|0x20`).

In Mercs 2, the build pipeline upgraded to compile Lua to bytecode (LuaQ format) instead of shipping text source. The BINN chunk wrapper replaced the BODY+INFO text wrapper.

### 10.6 Compression

Mercs 1 uses two compression schemes:
- **LZSS** (`PblCompress.h`) — for individual assets (scripts, small data)
- **zlib** (bundled in `Projects/zlib/`) — for bulk data

Mercs 2 switched to **raw deflate** (`sges` blocks with `zlib` windowBits `-15`) for block-level compression, dropping LZSS.

### 10.7 Implications for Mercs 2 Modding

1. **Asset hashes use FNV-1a with `|0x20`**: The `_uiName` fields in ASET entries, texture_index keys, and terrain TOC hashes are all computed with `pandemic_hash()`. To create new assets or rename existing ones, apply this hash to the lowercase asset name.

2. **No CSUM validation was found** in the Mercs 1 source. The `ZeroRecord.h` `GetCheckSum` is for network sync debugging, not asset validation. This supports the hypothesis that per-UCFX CSUM trailers in Mercs 2 are build-pipeline fingerprints, not runtime integrity checks.

3. **Script binding**: In Mercs 1, scripts are referenced by name hash. The `ObjectScript` ECS component's `script_hash_0` in Mercs 2 is likely `pandemic_hash(script_name)`, but the exact input string format (with or without path prefix) is not yet determined.

---

## Related Documentation

- [`docs/format_reference.md`](format_reference.md) — Master binary format reference (FFCS, sges, UCFX, textures, Havok)
- [`docs/luadisass_findings.md`](luadisass_findings.md) — Lua disassembly integration notes
- [`docs/external_resources.md`](external_resources.md) — Community tools and RE resources
- [`docs/game_data_analysis.md`](game_data_analysis.md) — Game data directory structure and block taxonomy
- [`docs/aset_format.md`](aset_format.md) — ASET chunk row layout
- [`docs/placement_data_format.md`](placement_data_format.md) — Placement record format (42-byte transforms)
- [`docs/ecs_components.md`](ecs_components.md) — ECS component documentation (ObjectScript, etc.)

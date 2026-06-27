# XEX2 Metadata — disc identity of the "Jul 11 2008" X360 preview

**Scope:** Parse every XEX2 optional header of **both** executables on the Jul 11 2008 Xbox 360 preview disc — the game `mercs2_xenon_p_EN_FR.xex` (→ `Mercs2_Xenon_P.pdb`) and the boot loader `default.xex` (`Mercs2_Xenon_F.exe`) — and decode the identity fields: title/media/version IDs, region, image/module flags, original PE name, XDK library versions, and compression. **Provenance:** Mercenaries 2 World in Flames, Pandemic "Pangea" engine, devkit "Profile" build. All numbers below come from running `tools/xex_info.py` (extended for this doc) or the inline `python3` snippets shown; nothing is hand-asserted.

Related: [`default_xex.md`](default_xex.md) (loader unpack), [`embedded_xex_modules.md`](embedded_xex_modules.md) (the other 23 XEX signatures on disc), [`jul08_prototype_iso.md`](jul08_prototype_iso.md), [`prototype_vs_retail.md`](prototype_vs_retail.md).

Input files (both XEX2, devkit-encrypted + LZX):
- `output/_scratch/jul08_iso/mercs2_xenon_p_EN_FR.xex` — 5,140,480 B (game)
- `output/_scratch/jul08_iso/default.xex` — 4,739,072 B (loader)

Reproduce everything:
```
python tools/xex_info.py output/_scratch/jul08_iso/mercs2_xenon_p_EN_FR.xex \
                         output/_scratch/jul08_iso/default.xex
```
(`tools/xex_info.py` was extended in this work stream to decode ExecutionId, OriginalPEName, StaticLibraries and ImportLibraries; the prior version only listed raw opt-header offsets.)

---

## 1. XEX2 file header (offset 0)

`struct.unpack_from(">IIIII", d, 4)` → `module_flags, pe_data_off, reserved, security_off, opt_header_count`.

| field | game | default |
|---|---|---|
| magic | `XEX2` | `XEX2` |
| module_flags | `0x00000001` = **TITLE** | `0x00000001` = **TITLE** |
| pe_data_off | `0x5000` | `0x4000` |
| security_off | `0x108` | `0x100` |
| opt_header_count | **14** | **13** |

Both are title modules (not DLLs/patches). Only the **TITLE** bit is set; no `DLL_MODULE`, `MODULE_PATCH`, `PATCH_FULL/DELTA`, `EXPORTS_TO_TITLE` — i.e. these are standalone title images, not patches or system modules.

---

## 2. ExecutionId — the disc's identity (opt header `0x00040006`)

Struct `XEX_EXECUTION_ID` at the header's data offset (game `0x3210`, default `0x2980`):
`be32 media_id; be32 version; be32 base_version; be32 title_id; u8 platform; u8 executable_table; u8 disc_number; u8 disc_count; be32 savegame_id`.

| field | game | default |
|---|---|---|
| **title_id** | **`0x45410828`** | **`0x45410828`** |
| media_id | `0x00000000` | `0x00000000` |
| version | `0.0.0.0` (`0x00000000`) | `0.0.0.0` |
| base_version | `0.0.0.0` | `0.0.0.0` |
| platform | 0 | 0 |
| executable_table | 0 | 0 |
| disc_number / count | 0 / 0 | 0 / 0 |

**Title ID decode:** `0x45410828`. The high word `0x4541` is the publisher code = ASCII **`"EA"`** (Electronic Arts); the low word `0x0828` is the title number (decimal 2088). So this is **EA title 0x0828** — the registered Mercenaries 2 title ID. *(Inference: that this specific `0x0828` is the shipped Mercs 2 ID is consistent with the embedded resource name `45410828`, see §6, but not independently cross-checked against a public title-ID registry.)*

**Version = `0.0.0.0` on both, media_id = 0, disc = 0/0:** the build was never assigned a real package version or disc identity. This is the canonical signature of an **unfinished pre-cert devkit build** — a shipping retail disc would carry a non-zero version (e.g. `1.0.x`) and a media id. Consistent with the "preview/prototype" provenance.

---

## 3. Region / image flags / load address (security info @ `security_off`)

The XEX2 security info block holds `header_size, image_size`, a 256-byte RSA signature, then the `image_info` body. Reading the structurally-meaningful u32s (the digests are encrypted noise):

```python
B = sec_off + 8 + 256            # start of image_info
g = lambda off: struct.unpack_from(">I", d, B+off)[0]
# +00 info_size  +08 load_address  +20 import_count  +70 game_regions  +74 media_flags
```

| field | game | default |
|---|---|---|
| security `header_size` | `0x2fd4` | `0x2764` |
| security `image_size` | `0x01ee0000` (32,374,784 B) | `0x01940000` (26,476,544 B) |
| image_info `info_size` | `0x174` (372) | `0x174` |
| **load_address** | `0x82000000` | `0x82000000` |
| import_table_count | 3 | 2 |
| **game_regions** | **`0xFFFFFFFF` = ALL REGIONS** | **`0xFFFFFFFF` = ALL REGIONS** |
| media_flags (@+0x74) | `0x08000605` | `0x08000605` |

- **Region = `0xFFFFFFFF` (region-free)** on both — no region lock, again typical of a dev/preview image.
- The game's security `image_size` `0x01ee0000` = **32,374,784 B**, which matches the recovered PE size in the environment notes (`mercs2_xenon_p.pe_full.bin` = 32,374,784 B) — independent confirmation the security-info parse is aligned.
- `load_address = 0x82000000` matches the PE `ImageBaseAddress` opt header (`0x00010201`, §5). The other base-addr header (`0x00010100`) differs per file (game `0x82610c50`, default `0x8257eb20`) and is the image's high-water/entry-region address.

> Note: the per-bit *image_flags* field (image_info `+0x04` = `0x00000000` on both) carries no set flags; the constant `0x08000605` at `+0x74` is reported as media_flags and is identical across both files. Exact bit semantics of `0x08000605` are **(unconfirmed)** — only the structurally reliable fields above are claimed.

---

## 4. Compression / encryption (BaseFileFormat, opt `0x000003FF`)

`u32 size; u16 encryption_type; u16 compression_type; [u32 lzx_window; u32 first_block_size]`.

| field | game | default |
|---|---|---|
| encryption | `1` = **ENCRYPTED** (devkit key) | `1` = ENCRYPTED |
| compression | `2` = **LZX** | `2` = LZX |
| LZX window_size | `0x8000` | `0x8000` |
| first_block_size | `0xf800` | `0x10000` |

Both are devkit-key encrypted + LZX-compressed; `tools/xex_unpack.py --devkit` decrypts/deblocks/LZX-decompresses them to the full PE.

---

## 5. PE / module headers

| opt header | id | game | default |
|---|---|---|---|
| PE_ImageBaseAddress | `0x00010201` | `0x82000000` | `0x82000000` |
| ImageBaseAddr (high) | `0x00010100` | `0x82610c50` | `0x8257eb20` |
| TLSInfo | `0x00020200` | value `0x80000` | value `0x80000` |
| Checksum/Timestamp | `0x00018002` | data `0x3114`, size 0 | data `0x289c`, size 0 |

- **TLSInfo (`0x00020200`)** is present on both with the same opt value `0x80000`. The pointed-to TLS directory bytes decrypt to noise in the still-encrypted XEX (slot_count etc. read as garbage), so the concrete TLS slot count / data size must be read from the **decrypted PE's** TLS directory, not the XEX header — **(not extracted here; TLS directory lives in the unpacked `*.pe_full.bin`)**.
- The `0x00018002` "checksum/timestamp" header has a zero-length payload on both files — no usable build timestamp is exposed via this header (the disc's date evidence lives elsewhere; see `prototype_vs_retail.md`).

---

## 6. Original PE name + embedded resource (opt `0x000183FF`, `0x000002FF`)

**OriginalPEName** (`0x000183FF`, length-prefixed ASCII):

| | game | default |
|---|---|---|
| OriginalPEName | **`Mercs2_Xenon_P.exe`** | **`Mercs2_Xenon_F.exe`** |

The `_P` ("Profile") game module matches the PDB path `…\Profile\Mercs2_Xenon_P.pdb`. The loader is the `_F` variant.

**ResourceInfo** (`0x000002FF`) — one entry each, named after the title id:

| | game | default |
|---|---|---|
| resource name | `45410828` | `45410828` |
| address | `0x83e30000` | `0x83890000` |
| size | 707,891 B | 707,891 B |

The single embedded resource is named `45410828` = the title id (this is the title's XGD resource section). Both carry the same 707,891-byte resource.

---

## 7. XDK fingerprint — Static & Import libraries

This is the most useful build-dating evidence.

**StaticLibraries** (`0x000200FF`) — every linked XDK static lib, version-stamped:

| game (12) | default (11) |
|---|---|
| XRTLLIBI 2.0.6995.0 | — |
| XAPILIB 2.0.6995.16385 | XAPILIB 2.0.6995.16385 |
| **D3D9I** 2.0.6995.0 | **D3D9** 2.0.6995.16384 |
| D3DX9 2.0.6995.16384 | D3DX9 2.0.6995.16384 |
| XGRAPHC 2.0.6995.16384 | XGRAPHC 2.0.6995.16384 |
| XBOXKRNL 2.0.6995.16384 | XBOXKRNL 2.0.6995.16384 |
| XNET 2.0.6995.16384 | XNET 2.0.6995.16384 |
| XONLINE 2.0.6995.16384 | XONLINE 2.0.6995.16384 |
| XHV 2.0.6995.16384 | XHV 2.0.6995.16384 |
| LIBCMT 2.0.6995.16384 | LIBCMT 2.0.6995.16384 |
| XAUD 2.0.6995.16384 | XAUD 2.0.6995.16384 |
| XMP 2.0.6995.16384 | XMP 2.0.6995.16384 |

- **All libs are XDK build `2.0.6995`** — both executables were linked against the same XDK release. (XDK 6995 is a 2008-era SDK; mapping `6995`→a calendar month is **(unconfirmed)** here.)
- The **game links the instrumented/profile variants** — `D3D9I` (instrumented D3D9) and `XRTLLIBI` (instrumented RTL) — whereas `default.xex` links plain `D3D9` and has no `XRTLLIBI`. This is concrete confirmation the game module is a **Profile/instrumented build**, not retail, and that the loader is a thinner module.
- The `.16384`/`.16385` QFE suffix vs `.0` distinguishes the released-config libs from the instrumented ones.

**ImportLibraries** (`0x000103FF`) — runtime XEX imports:

| | game | default |
|---|---|---|
| imports | `xam.xex`, `xboxkrnl.exe`, **`xbdm.xex`** | `xam.xex`, `xboxkrnl.exe` |
| xam.xex | ver 2.0.6995.0, min 2.0.1861.0, 220 records | ver 2.0.6995.0, min 2.0.1861.0, 218 records |
| xboxkrnl.exe | 2.0.6995.0 / 2.0.1861.0, 313 records | 2.0.6995.0 / 2.0.1861.0, 313 records |
| xbdm.xex | 2.0.6995.0 / 2.0.1861.0, 2 records | (absent) |

- **The game imports `xbdm.xex` (Xbox Debug Monitor)** — a devkit-only module. A retail title would not link `xbdm`. This, together with the instrumented D3D, is hard proof the game executable is a **debug/devkit build**.
- Import `version_min = 2.0.1861.0` is the minimum compatible XDK; the libs themselves are `2.0.6995`.

---

## Most notable findings

1. **Title ID `0x45410828`** on both files — publisher `"EA"` (`0x4541`) + title `0x0828` (2088); matches the embedded resource name `45410828`.
2. **ExecutionId is blank-but-for-title**: media_id = 0, version = `0.0.0.0`, base_version = `0.0.0.0`, disc 0/0, and **region = `0xFFFFFFFF` (region-free)** — the fingerprint of an unfinished, uncertified devkit/preview image.
3. **Game = devkit "Profile" build, proven by imports/libs**: it imports **`xbdm.xex`** (debug monitor) and statically links **`D3D9I` + `XRTLLIBI`** (instrumented), while `default.xex` uses plain `D3D9` and omits both — matching `…\Profile\Mercs2_Xenon_P.pdb`.
4. **OriginalPEName** = `Mercs2_Xenon_P.exe` (game) vs `Mercs2_Xenon_F.exe` (loader); both link **XDK 2.0.6995** across all static libs.
5. **Security image_size `0x01ee0000` = 32,374,784 B** exactly equals the recovered game PE size — the security-info parse is independently corroborated; both files are devkit-encrypted (`encryption=1`) + **LZX** (`compression=2`, 0x8000 window).

# PS3 EBOOT Analysis (BLUS30056)

**Title:** Mercenaries 2: World in Flames  
**Title ID:** `BLUS30056` (from `PARAM.SFO`)  
**EBOOT:** `game-files/[BLUS30056] Mercenaries 2 - World in Flames/PS3_GAME/USRDIR/EBOOT.BIN`  
**IRD:** `BLUS30056_0100_0100_241_...IRD` (Redump IRD, gzip — ISO decryption metadata, not EBOOT keys)

## Decryption status

| Item | Value |
|------|--------|
| On-disc format | SCE **SELF** (`SCE\x00`, key revision **0x0001**) |
| SELF type | Application (retail) |
| FW version (control info) | **02.41** (24100) |
| Keyset used | **`appldr` revision 0001** (SDK 3.15) |
| Decrypted output | `analysis/cross_platform/ps3_eboot/EBOOT.elf` (~18.2 MB PPC64 ELF) |

### How to decrypt

```bash
# One-time: oscetool + keys (do not set PS3= to a stale custom key dir)
git clone --depth 1 https://github.com/spacemanspiff/oscetool.git /tmp/oscetool
make -C /tmp/oscetool
cp -r /path/to/ps3dotdir/data /tmp/oscetool/data   # keys, ldr_curves, vsh_curves

./scripts/decrypt_ps3_eboot.sh
.venv/bin/python3 tools/ps3_eboot_analyze.py \
  --elf analysis/cross_platform/ps3_eboot/EBOOT.elf \
  --output analysis/cross_platform/ps3_eboot
```

**Common failure:** `PS3=/tmp/oscetool_data` in the shell pointing at wrong keys → `Could not decrypt header`.  
Fix: `env -u PS3` when running oscetool, or use the script above.

## String findings (decrypted ELF)

Prior analysis on **encrypted** EBOOT reported no WAD strings. After decryption:

| String | File offset | Notes |
|--------|-------------|--------|
| `VZ.WAD` | `0x00DCAB78` | With `SHELL.WAD`, `LOADING.WAD` |
| `%s\%s.wad` | `0x00DC4870` | Base WAD open pattern |
| `%s\%s-patch.wad` | `0x00DC4860` | Patch overlay (same as PC) |
| `/dev_bdvd/PS3_GAME/USRDIR` | `0x00DC48F0` | Disc path |
| `/app_home` | `0x00DC48E0` | Devkit/install path |
| `BLUS30056` | `0x00DC48B0` | Title ID |
| `IsDLC` / `DlcMapId` | `0x00DE0530` | DLC session fields (present on PS3) |
| `SetMasterScriptName` | `0x00DD16F8` | Same API family as PC |

`bit_xor` at `0x00DD8970` is a **Flash/ActionScript VM opcode** (next to `bit_and`, `bit_or`), **not** WAD cryptography.

## `0x80800` in the executable

The constant **`0x80800`** appears **13 times** in the ELF (e.g. `0x00A18C69`, `0x00DA6152`), often alongside **`0x8000`** (32 KiB page size).

Hex context at `0x00A18C40` looks like a **page/allocator configuration table** (repeated `0x114`, `0x80800`, `0x8000`, `0x424000`), consistent with engine strings:

- `SmallBlockPage 32K`
- `// Large enough for Havok pages`

This supports the hypothesis that **`0x80800` is the PS3 metadata region size** (16 × 32 KiB + 0x800 gap), wired into the memory/WAD loader — but the **cipher implementation** still needs a PPC disassembler xref from `VZ.WAD` → function.

## VZ.WAD header (still open)

| Fact | Status |
|------|--------|
| Cleartext `segs` at file `0x80800` | Confirmed |
| Encrypted envelope `0x0`–`0x807FF` | Confirmed (~7.9 bits/byte entropy) |
| Algorithm in EBOOT | **Not yet identified** (no `segs`/`SCFF` strings; likely inline cipher) |
| `9FED8BC6` magic in ELF | Not found as string (may be runtime-only) |

## Next steps

See **[`ps3_ppc_re_workflow.md`](ps3_ppc_re_workflow.md)** for install + Ghidra/radare2 commands.

1. **PPC disassembly** — xref `VZ.WAD` @ VA `0x00DDAB78` (`make ghidra-ps3-eboot` or `./scripts/r2_vz_wad_xrefs.sh`).
2. **Compare** header decrypt to PC `vz.wad` loader (SecuROM-decrypted EXE) once PS3 function is located.
3. **Runtime** — hook after `cellFsRead` on `/dev_bdvd/.../VZ.WAD` and dump first `0x80800` bytes post-decrypt.
4. **IRD** — use only for Redump ISO decrypt; EBOOT uses standard `appldr` keys, not IRD.

## Artifacts

| Path | Content |
|------|---------|
| `analysis/cross_platform/ps3_eboot/EBOOT.elf` | Decrypted executable |
| `analysis/cross_platform/ps3_eboot/eboot_analysis.md` | Auto-generated string report |
| `analysis/cross_platform/ps3_eboot/eboot_analysis.json` | Machine-readable |
| `tools/ps3_eboot_analyze.py` | Regenerate analysis |
| `scripts/decrypt_ps3_eboot.sh` | Decrypt wrapper |
| `tools/ps3_wad_header_crack.py` | WAD-side cryptanalysis |

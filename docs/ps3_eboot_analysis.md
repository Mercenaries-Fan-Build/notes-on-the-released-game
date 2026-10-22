# PS3 EBOOT Analysis (BLUS30056)

**Title:** Mercenaries 2: World in Flames  
**Title ID:** `BLUS30056` (from `PARAM.SFO`)  
**EBOOT:** `game-files/ps3-version/EBOOT.BIN` (sha256 `73ff3fab…`)  
**IRD:** `BLUS30056_0100_0100_241_...IRD` (Redump IRD, gzip — ISO decryption metadata, not EBOOT keys)

The decrypted ELF is image `ps3-v100` of `tools/wad_simulator/crates/mercs2_exemap/data/images.tsv`
(sha256 `dfb5b1c5…`, `game-files/ps3-version/EBOOT.elf`). Its Ghidra project, functions export
and the other PS3 images: [`ps3_ppc_re_workflow.md`](ps3_ppc_re_workflow.md).

## Decryption

| Item | Value |
|------|--------|
| On-disc format | SCE **SELF** (`SCE\x00`, key revision **0x0001**) |
| SELF type | Application (retail) |
| FW version (control info) | **02.41** (24100) |
| Keyset used | **`appldr` revision 0001** (SDK 3.15) |

```bash
tools/wad_simulator/target/release/exemap derive ps3-v100 \
  --from game-files/ps3-version/EBOOT.BIN --out <EBOOT.elf>
```

prints sha256 `dfb5b1c5…`.

## String findings (decrypted ELF)

File offsets; in this segment the VA is the file offset + `0x10000` (`VZ.WAD`: file `0x00DCAB78`,
VA `0x00DDAB78`).

| String | File offset | Notes |
|--------|-------------|--------|
| `VZ.WAD` | `0x00DCAB78` | Followed by `AUDIOS/AMBIENCE.PWS` |
| `%s\%s.wad` | `0x00DC4870` | Base WAD open pattern |
| `%s\%s-patch.wad` | `0x00DC4860` | Patch overlay (same as PC) |
| `/dev_bdvd/PS3_GAME/USRDIR` | `0x00DC48F0` | Disc path |
| `/app_home` | `0x00DC48E0` | Devkit/install path |
| `BLUS30056` | `0x00DC48B0` | Title ID |
| `IsDLC` / `DlcMapId` | `0x00DE0530` | DLC session fields (present on PS3) |
| `SetMasterScriptName` | `0x00DD16F8` | Same API family as PC |

`bit_xor` at `0x00DD8970` is a **Flash/ActionScript VM opcode** (next to `shl`, `asr`, `lsr`), not
cryptography.

Any other string: `ghidra_strings` (corpus MCP server) with `image: ps3-v100`, or the Ghidra project.

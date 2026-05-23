# PS3 EBOOT PPC Reverse Engineering Workflow

Decrypt EBOOT first ([`scripts/decrypt_ps3_eboot.sh`](../scripts/decrypt_ps3_eboot.sh)), then locate the **VZ.WAD header decrypt** routine via the string at VA **`0x00DDAB78`**.

## Prerequisites

```bash
brew install ghidra radare2

# JDK for Ghidra (this repo uses asdf — see .tool-versions)
asdf plugin add java https://github.com/halcyon/asdf-java.git  # once per machine
asdf install   # installs temurin-21 from .tool-versions
java -version  # should show 21.x

./scripts/decrypt_ps3_eboot.sh
```

**Ghidra needs a JDK on `PATH` / `JAVA_HOME`.** `make ghidra-ps3-eboot` loads asdf from your shell
and uses the repo `java` shim. If you use a different Temurin build, edit `.tool-versions` to match
what `asdf list java` shows installed.

**GUI (`ghidraRun`):** Run from the same terminal where `java -version` works, or:

```bash
export JAVA_HOME="$(asdf where java)"
export PATH="$JAVA_HOME/bin:$PATH"
ghidraRun
```

Artifacts:

| Path | Content |
|------|---------|
| `analysis/cross_platform/ps3_eboot/EBOOT.elf` | Decrypted PPC64 BE ELF (~18 MB) |
| `analysis/cross_platform/ps3_eboot/eboot_analysis.json` | String VA map |

## Headless Ghidra (repo script)

```bash
chmod +x scripts/ghidra_analyze_ps3_eboot.sh
./scripts/ghidra_analyze_ps3_eboot.sh
# or: make ghidra-ps3-eboot
```

Opens/creates project `analysis/cross_platform/ghidra_projects/Mercenaries2_PS3_EBOOT`.

**Import vs analysis:** Headless import uses **`-noanalysis`** by default (fast). Do **not** use
`-analysisTimeoutPerFile 0` — in Ghidra 12 that means **timeout at 0 seconds** (analysis skipped).

For headless auto-analysis (slow, ~1–2+ hours):

```bash
GHIDRA_ANALYSIS_TIMEOUT=7200 make ghidra-ps3-eboot
```

Your project is still usable after import-only: open GUI → **Analysis → Auto Analyze**.

## GUI workflow

1. `ghidraRun` → open project above → `EBOOT.elf`
2. **Search → For Strings** → `VZ.WAD` (address `0x00DDAB78`) — direct code xrefs are often **empty** (TOC).
   Prefer the filename table slot **`0x00FC63B4`** (points to `0x00DDAB78`) or class **`FxArchiveStoreFile`**.
3. **References** on `0x00FC63B4` / vtable **`0x00FB4D60`** → follow callers (WAD open / read path).
   See [`analysis/cross_platform/ps3_eboot/ps3_eboot_re_targets.md`](../analysis/cross_platform/ps3_eboot/ps3_eboot_re_targets.md).
4. Walk **callers upward** until you see:
   - Read of **`0x80800`** bytes (header envelope size)
   - Transform loop (xor, stream cipher, AES-CTR-shaped blocks)
   - Constants **`0x8000`** (32 KiB pages) nearby
5. Document function address + algorithm in [`docs/ps3_wad_wrapper.md`](ps3_wad_wrapper.md)
6. Implement decrypt in [`tools/ps3_wad_header_crack.py`](../tools/ps3_wad_header_crack.py)

**PS3 ABI:** Functions use **TOC in `r2`**. If decompilation is wrong at calls, trust disassembly for the decrypt loop first.

## radare2 quick xref

```bash
./scripts/r2_vz_wad_xrefs.sh
```

## Compare to PC

After PS3 routine is identified, diff against PC `Mercenaries2.exe` WAD loader (SecuROM-decrypted) — same engine family, likely similar envelope handling.

## Runtime fallback

PS3 hardware/emulator: hook after `cellFsRead` on `VZ.WAD`, dump first `0x80800` bytes post-decrypt. Use only if static RE stalls.

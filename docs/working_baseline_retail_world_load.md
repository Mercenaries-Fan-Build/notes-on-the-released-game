# Working baseline — retail world load (2026-06-04)

Verified: **menu → load save / new game → playable in-world** with the configuration below.

This baseline pins **stock retail content** (`data/vz.wad` active). The converted DLC patch is present on disk but **not mounted** (`data/vz-patch.wad.disabled`). Use this as the known-good floor before enabling DLC.

## Runtime stack

| Component | Role |
|-----------|------|
| `Mercenaries2.exe` | SecuROM-cracked retail EXE, **40/40** sites from `tools/patch_anim_table.py` (1024→4096 anim hash table + sentinel/texture/effect/vertex fixes) |
| `pmc_bb.dll` | Built with `make vanilla` (`-DPMC_NO_COMPAT_HOOKS`): SecuROM spoof, debug console, ASI loader only — **no MinHook / compat detours** |
| `scripts/windowed_mode.asi` | D3D9 windowed `CreateDevice` vtable hook |
| `scripts/global.ini` | `LoadPlugins=1`, `DontLoadFromDllMain=0`, `LoadFromScriptsOnly=0`, `LoadRecursively=1` |
| `xinput1_3.dll` | **Retail-shipped** game DLL (not an ASI proxy) |
| `pmc_bb.dll` ASI search paths | Game root, `scripts/`, `plugins/`, `update/` (see `tools/pmc_blackbox/pmc_blackbox.c`) |

**Not used on this baseline:** `MinHook.x86.dll` (deprecated; removed). No `dlc_enable.asi`, `net_hooks.asi`, or `asset_miss_probe.asi` in `scripts/`.

## WAD / patch mount state

| File | Mounted? | Notes |
|------|----------|--------|
| `data/vz.wad` | **Yes** | Active world archive (retail PC) |
| `data/vz-patch.wad.disabled` | **No** | DLC port artifact renamed so the engine does not load it |
| `data/vz.bin` | (engine) | 258-byte sidecar next to active `vz.wad` |

To test DLC on a **future** baseline: rename to `data/vz-patch.wad` (or swap mount per your launcher) and regenerate manifests — do not mix hashes with this retail baseline.

## Verify before play

```powershell
cd <repo-root>
.\.venv\Scripts\python.exe tools\patch_anim_table.py `
  "C:\Users\Shadow\Desktop\Mercenaries 2 World in Flames\Mercenaries2.exe" --verify-only
# Expect: OK: all 40 patch sites match patched values
```

Build `pmc_bb.dll` (vanilla):

```powershell
cd tools\pmc_blackbox
make vanilla
# Copy pmc_bb.dll next to Mercenaries2.exe
```

## SHA-256 manifests (canonical)

Full machine-readable manifests (reproducible diff):

| Manifest | Path |
|----------|------|
| All of `data/` (68 files) | `output/baselines/retail_world_load_2026-06-04/data_manifest.json` |
| Runtime pins (exe, dll, asi, ini) | `output/baselines/retail_world_load_2026-06-04/runtime_manifest.json` |

Regenerate `data/` hashes:

```powershell
.\.venv\Scripts\python.exe tools\hash_game_data_manifest.py `
  --game-dir "C:\Users\Shadow\Desktop\Mercenaries 2 World in Flames" `
  --data-only `
  --label "retail_world_load_baseline" `
  --out "output\baselines\retail_world_load_2026-06-04\data_manifest.json"
```

### Key data assets (quick reference)

| Path | Size | SHA-256 |
|------|------|---------|
| `data/vz.wad` | 2,565,537,792 | `A67ADA8BB1EF4255D3067475D6BC579CC1421FAB262E9383A9EED74C8C59C011` |
| `data/vz-patch.wad.disabled` | 118,456,320 | `DA87F187981E10CD283C93A85D6083C1CCC6ADABD5971EF3A512577AFDFBF753` |
| `data/vz.bin` | 258 | `D8987197B67B50450A390E2B5CDF71C22D06B14EF09B063A4DC9D68D4D2B0CD3` |
| `data/shell.wad` | 29,622,272 | `7B01FF39900C6D9430F97F2037CB814F77331FA23AB5838BE32E9B04ABAD766F` |
| `data/English.wad` | 483,426,304 | `298BB943CEA0416D697B1F47421F27AFCDCF40B2D4A8DC1991036B81469D480E` |

All **68** files under `data/` (Audios, Movies, shaders, WADs, ini) are in `data_manifest.json`.

### Runtime pins (quick reference)

| Path | Size | SHA-256 |
|------|------|---------|
| `Mercenaries2.exe` (patched) | 53,482,288 | `186E9D59ED462B812899CAC29F569B8993D241B05771D7367D59D938039CB03E` |
| `Mercenaries2 - Copy.exe` (pre-patch backup) | 53,482,288 | `958EB22776067C2DBB7D684E472C5045D419EC0ECFB49BFEA7D23FCF4A83F115` |
| `pmc_bb.dll` (vanilla) | 27,648 | `353FE1BE79672B6FCD5C6E725725DF19B3EE68AB079710C2E585946FB9D08104` |
| `scripts/windowed_mode.asi` | 12,800 | `35431D2BFA44D2F1A96E3E5A6F901C3152230CE89CC14CA25B0D7DF7E3D2D3D7` |
| `scripts/global.ini` | 82 | `B51DB9FE8DD9E847F80BCC26DD600A243CC94150429091B8E8748C9E1B58639E` |
| `xinput1_3.dll` (retail) | 81,768 | `8D540D484EA41E374FD0107D55D253F87DED4CE780D515D8FD59BBE8C98970A7` |

## Ladder from this baseline

1. **This baseline** — retail `vz.wad`, patched EXE, vanilla `pmc_bb`, `windowed_mode.asi` → world load OK.
2. **+ compat hooks** — rebuild `pmc_bb` with `make mingw` (diagnostic MinHook only) → confirm no regression on retail.
3. **+ DLC** — mount `vz-patch.wad`, new manifest label → measure unique keys / next crash (separate baseline doc).

## Related tools

- `tools/patch_anim_table.py` — EXE patch catalog and verify
- `tools/hash_game_data_manifest.py` — `data/` SHA-256 manifest generator
- `tools/pmc_blackbox/Makefile` — `make vanilla` vs `make mingw`

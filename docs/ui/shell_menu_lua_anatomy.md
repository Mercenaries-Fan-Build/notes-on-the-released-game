# Shell main-menu anatomy (Phase 0 recon)

> Recon for adding a native **MODS** main-menu item via `shell-patch.wad`.
> Source: PC retail `game-files/shell.wad` (identical to the live `data/shell.wad`,
> 29,622,272 bytes). Xbox JTAGRip `shell.wad` is a *different*, big-endian file — do not use.

## Block map (relevant)

| Block | Name | Decompressed | Role |
|-------|------|--------------|------|
| 0  | `shell_base_P000_Q3` | 11 KB | entity/layer schema |
| 17 | `resident_P000_Q3` | 3.21 MB | **all shell Lua** + GUI framework (28 chunks) |
| 18 | `scaleform_shell_P000_Q3` | 35.6 MB | Scaleform texture atlas / movies |
| 29 | `english_P000_Q3` | 1.65 MB | **English stringdb** (+ fonts, textures) |

Decompress: `python tools/sges_decompress.py --wad game-files/shell.wad --index N --out ...`

## The main menu is Scaleform Flash, not a Lua item list

The front-end menu is a Scaleform GFx movie, **`shell.gfx`** (referenced in
`mrxguishell` chunk). The buttons and their labels live *inside the movie*. The Lua
side only wires **event handlers** for events the SWF dispatches:

```
mrxguishell:  oFlash:SetSwfFile("shell.gfx")
              oFlash:SetFlashEventHandler("newGame",  _NewGameFlashCallback)
              oFlash:SetFlashEventHandler("joinGame", _JoinGameFlashCallback)
              oFlash:SetFlashEventHandler("exitGame", _ExitGameFlashCallback)
              oFlash:SetFlashEventHandler("Enter.Lobby", _EnterLobbyFlashCallback)
              ... (~30 handlers: lobby, options, input remap, camera, movies)
```

Implication: **adding a literally-new button to the main menu requires editing
`shell.gfx`** (Scaleform GFx 2.x / AS2, 2006–2008 vintage → needs era-specific
`gfxexport`/`gfximport`, not modern SWF tools). The Lua half of a new action is
trivial (`SetFlashEventHandler` + callback); the SWF half is the hard part.

### Phase-2 options for the MODS entry (no SWF authoring required)
1. **Repurpose an existing front-end path.** The stringdb already contains a full
   DLC/Add-Ons front-end: `DOWNLOADABLE CONTENT`, `GAME ADD-ONS`,
   `Connect and Download Extras`, `Download New Mission`, `Select to Download Game Add-On`.
   If that screen is reachable, relabel + redirect it to the MODS screen. This also
   aligns with Phase 3 (BITA DLC detection lives here naturally).
2. **Hotkey-triggered Lua screen.** Bind an input handler in the shell Lua to open a
   MODS screen built from `Gui.*`/`MrxGui` widgets — no SWF edit, not a "button" though.
3. **Edit `shell.gfx`** to add a real button (highest fidelity, highest effort).

## Lua chunks in block 17 (28 total)

Key: `mrxguishell` (main shell + flash wiring), `mrxguishelllayout`, `shell`,
`shellbootstrap`, `mrxguibase` (widget base: `SetText`/`SetTexture`/`SetSwfFile`),
`mrxmultipagemenu` (generic `AddOption`-based menu used for sub/pause menus),
`mrxguidialogbox` (dialogs), `mrxguimanager`.

Extract + disasm: `python tools/extract_all_scripts.py --block <block17.bin> --output <dir> --luac tools/lua51-mercs2/luac.exe`
→ `output/shell_recon/block17_scripts/` (`bytecode/*.luac`, `*.disasm.txt`).

Text is set via `widget:SetText(...)`; there are **no** `Localize`/`GetString` calls
in the shell Lua — string→text resolution is engine-side (stringdb) or baked in the SWF.
Phase 1 spike (below) determines which for the main-menu labels.

## stringdb (block 29, entry 2)

Block 29 = 5 UCFX containers: `[font, font, stringdb(type 0x39E5E978), texture, texture]`.
Entry 2 (offset `0x2558`, size `1375560`) is the **stringdb**; strings are **UTF-16LE**,
each UCFX ends with an 8-byte `CSUM` trailer (CRC-32/JAMCRC over `UCFX..CSUM`).

All main-menu labels are unique, single-occurrence, all in entry 2:

| Label | UTF-16 offset |
|-------|---------------|
| `CONTINUE` | 0x8d3e8 |
| `NEW GAME` | 0x8d3fa |
| `JOIN GAME` | 0x8d40c |
| `OPTIONS` | 0x5d4de |
| `LOAD GAME` | 0x5d4ee |
| `QUIT` | 0x5d502 |

Length-preserving edits are safe; only the touched UCFX's CSUM must be recomputed
(`crc32_mercs2` in `tools/ffcs_patch_wad.py` IS JAMCRC — verified it reproduces entry
2's stored `0x9fb24dc9`).

## Phase 1 spike (built, pending in-game verify)

Tool: `tools/build_shell_string_patch.py` (in-place UTF-16 edits + CSUM recompute +
single-block FFCS patch via `build_patch_wad.cmd_build_patch`).

```
python tools/build_shell_string_patch.py --source-wad game-files/shell.wad \
    --block-index 29 --replace "NEW GAME=MOD MENU" --replace "OPTIONS=MODTEST" \
    --output output/data/shell-patch.wad
```

Produces `output/data/shell-patch.wad` (1 block, validated: edits applied, CSUM
correct, sges round-trips). Deployed to `…\Mercenaries 2 World in Flames\data\`.

**Open question this answers when launched:** if the main menu shows `MOD MENU`/
`MODTEST`, the stringdb drives main-menu labels (→ Phase 2 can relabel without SWF
edits) *and* the whole shell-patch pipeline (sges + JAMCRC + FFCS + engine override)
is proven. If labels are unchanged, main-menu text is baked in `shell.gfx`.
To revert: delete `data\shell-patch.wad`.

# Linux / Proton runbook — Mercenaries 2: World in Flames

Status (2026-06-19): **SOLVED — boots, fully loads into the world, and renders on the
discrete GPU under Proton.** `loadprobe` = REACHED-WORLD; `nvidia-smi` shows the game
process holding VRAM with real GPU utilization.

The launcher is implemented in the **mercs2-modkit** (Rust): `src-tauri/src/commands/launch.rs`
runs the recipe below on Linux (the modkit's **Play** button). This doc is the reference
recipe + the two host prerequisites + the manual CLI command for debugging without the GUI.

## The recipe

1. Launch the de-DRM'd **`Mercenaries2.cracked.exe`** (it imports `pmc_bb.dll`, the ASI
   loader / SecuROM spoof / `pmc_blackbox.log` writer). The stock `Mercenaries2.exe` is
   SecuROM-wrapped and dies under Wine.
2. Run Proton **inside the Steam Linux Runtime (sniper) container** — *not* bare `proton run`.
   Bare proton works but doesn't set up the GPU stack the same way; the container is the
   supported path (and what Steam uses).
3. Native **DXVK** on the GPU. No `DXVK_FILTER_DEVICE_NAME`, no dgVoodoo2, no WineD3D — those
   were dead-ends chased before the real cause (host prereq B) was found.

## Host prerequisites (the two non-obvious blockers)

**A. Allow unprivileged user namespaces** (Ubuntu 24.04 restricts them; without this the
pressure-vessel/bwrap container fails with `setting up uid map: Permission denied`, which is
also why a Steam-UI launch exits instantly with no log):
```bash
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
echo 'kernel.apparmor_restrict_unprivileged_userns=0' | sudo tee /etc/sysctl.d/60-steam-userns.conf
```

**B. Install the 32-bit NVIDIA driver libraries** (Mercs2 is a 32-bit game; without the i386
NVIDIA Vulkan ICD, the game's DXVK enumerates only `llvmpipe` and renders in software at
~0.3 FPS — the 64-bit half being present is not enough):
```bash
sudo apt install libnvidia-gl-<branch>:i386     # e.g. libnvidia-gl-595:i386
sudo reboot                                      # required if it bumps the kernel module version
```
Diagnosis signature in the Proton log: the `Build: x86_64` instance shows
`Found device: NVIDIA …` but the `Build: x86` (game) instance shows only
`Found device: llvmpipe`. After the fix, the `x86` instance does
`Creating device: NVIDIA GeForce RTX 4070 Ti / Driver : NVIDIA`.

The modkit's launch preflight checks both A and B and surfaces the exact fix command.

## Manual CLI launch (debugging without the modkit)

```bash
GAME="$HOME/Desktop/Mercenaries 2 World in Flames"
STEAM="$HOME/.steam/debian-installation"
PROTON="$STEAM/steamapps/common/Proton - Experimental/proton"
SNIPER="$STEAM/steamapps/common/SteamLinuxRuntime_sniper/_v2-entry-point"
STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM" \
STEAM_COMPAT_DATA_PATH="$HOME/.local/share/mercs2-proton" \
DXVK_HUD=fps,gpuload,devinfo,version \
"$SNIPER" --verb=waitforexitandrun -- "$PROTON" waitforexitandrun "$GAME/Mercenaries2.cracked.exe"
```
Then analyze: `tools/wad_simulator/target/release/loadprobe --no-color "$GAME/pmc_blackbox.log"`
(or the `analyze-game-log` skill). The engine writes `scripts/global.ini`
(`LoadPlugins=1`, `DontLoadFromDllMain=0`, …) — the modkit/launcher stages it if missing.

## Verify (milestone ladder)

| Phase | loadprobe signal |
|------:|------------------|
| 0–7 | process init → soundbanks (main menu) |
| 8–13 | shell exit → GlobalEnter |
| 20 | **World fully loaded** → `REACHED-WORLD` (exit 0) |

GPU proof (not the DXVK HUD, which can report llvmpipe's load): `nvidia-smi` should list
`Mercenaries2.cracked.exe` as a process holding VRAM with non-trivial GPU utilization. The
Proton log should show `Creating device: NVIDIA …` for the `Build: x86` instance.
EIP `0x874E7D` is a benign teardown artifact, not a crash.

# Windows Test Environment

Runs Windows 7 Ultimate in a Docker container via [dockur/windows](https://github.com/dockur/windows) for verifying Mercenaries 2 game modding tools. Requires a Linux host with KVM.

## Prerequisites

- Linux host with KVM (`/dev/kvm` available)
- Docker and Docker Compose
- Patched game files in `output/` (see below)

### Prepare patched files on the host

```bash
# 1. Crack the retail EXE (produces output/patched/Mercenaries2.exe + pmc_bb.dll)
make crack-game RETAIL_EXE="path/to/Mercenaries2.exe" OUTPUT=./output

# 2. Port DLC content (produces output/data/vz-patch.wad + audio .pws files)
make dlc-port DLC_RAR="path/to/DLC.rar" OUTPUT=./output

# 3. (Optional) Copy the full game install for use inside Windows
mkdir -p output/game-install
cp -r "/path/to/Mercenaries 2 World in Flames/"* output/game-install/
```

## Start the test environment

```bash
make test-windows
```

This launches a Windows 7 container with:
- **4 CPU cores, 8 GB RAM, 64 GB disk**
- `./output` mounted as `C:\Shared` inside Windows
- `test-env/oem/install.bat` runs automatically after Windows setup

### Access methods

| Method | Address | Credentials |
|--------|---------|-------------|
| **noVNC (browser)** | `http://<host>:8006` | — |
| **RDP** | `<host>:3389` | `mercs2` / `mercs2` |

First boot takes **5–10 minutes** (Windows installation). Subsequent starts are faster since the virtual disk is persisted in a Docker volume.

## What install.bat does

After Windows setup completes, `install.bat` runs automatically and:

1. Copies the game from `C:\Shared\game-install\` to `C:\Mercs2\` (if provided)
2. Overwrites with the patched `Mercenaries2.exe` from `C:\Shared\patched\`
3. Copies `pmc_bb.dll` (SecuROM spoof + ASI loader DLL)
4. Copies `vz-patch.wad` to `C:\Mercs2\data\`
5. Copies DLC audio `.pws` files to `C:\Mercs2\data\Audios\`
6. Creates a desktop shortcut

## Verification checklist

### SecuROM crack works
1. Double-click the "Mercenaries 2" desktop shortcut (or `C:\Mercs2\Mercenaries2.exe`)
2. The game should reach the main menu without a SecuROM error dialog
3. If it crashes, check that both `Mercenaries2.exe` and `pmc_bb.dll` are present

### Game launches with DirectX 9
1. Windows 7 includes DirectX 9 out of the box
2. The container uses software rendering (no GPU passthrough), so expect low FPS
3. Reaching the main menu is sufficient to confirm the EXE is functional

### DLC content loads (vz-patch.wad)
1. Start a new game or load a save
2. Look for DLC-specific content:
   - Costumes in the outfit menu
   - DLC vehicles at the PMC
   - The "Blow It Up Again" challenge mode
3. If DLC content is missing, verify `data\vz-patch.wad` exists in the game directory

### Crash investigation
- Check `C:\Mercs2\` for crash logs or minidumps
- Use the Windows Event Viewer for application errors
- The shared folder persists — copy logs to `C:\Shared\` to access from the host

## Iterating on patches

The `C:\Shared` folder is a live mount of `./output` on the host. To test updated patches:

```bash
# On the host: rebuild the patch WAD
make dlc-port DLC_RAR="path/to/DLC.rar" OUTPUT=./output

# Inside Windows: re-copy the updated file
copy C:\Shared\data\vz-patch.wad C:\Mercs2\data\vz-patch.wad
```

Or re-run `install.bat` from `C:\Shared\oem\install.bat` (it's also in `C:\Shared` since the OEM folder is separate, but you can copy it there too).

## Container management

```bash
make test-windows          # Start
make test-windows-down     # Stop and remove container
make test-windows-logs     # Follow container logs

# Reset (deletes the Windows virtual disk — forces fresh install)
docker compose -f docker-compose.test-windows.yml down -v
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Container exits immediately | Check `make test-windows-logs` — likely missing `/dev/kvm` |
| "KVM not available" | Enable virtualization in BIOS; verify `ls /dev/kvm` on host |
| Windows install stuck | Give it time (up to 15 min); check logs for disk space issues |
| Port 8006 in use | Change the port mapping in `docker-compose.test-windows.yml` |
| Game crashes on launch | Verify both `Mercenaries2.exe` and `pmc_bb.dll` are in `C:\Mercs2\` |
| No DLC content | Verify `C:\Mercs2\data\vz-patch.wad` exists and matches host file size |
| RDP won't connect | Wait for Windows to finish installing; try noVNC first |

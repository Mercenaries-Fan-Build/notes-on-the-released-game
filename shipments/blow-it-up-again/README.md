# Blow It Up Again

The Blow It Up Again DLC as a level on PC. This Shipment holds the recipe. Your own copy of the Xbox
package supplies the content, so no DLC bytes are in this folder's history or in anything published
from it.

## Build it

From the `wad_simulator` workspace, convert your package into `src/level/`:

```
dlc_port --x360-stfs <your package> --java <java> --unluac <unluac.jar> \
  --vz-wad <game>/data/vz.wad --output <this folder>/src/level/dlc01.wad
```

That writes `src/level/dlc01.wad` and the 7 streams under `src/level/Audios/`. ffmpeg decodes the
streams, so it has to be on your `PATH` or named by `MERCS2_FFMPEG`.

Then:

```
qm lint <this folder>
qm build <this folder> --game <game>
```

`qm lint` needs `src/level/` to exist, because it checks every file the manifest names.

## What it installs

`_build/placement.json` lists these, each with its size and sha256:

| file | how |
|---|---|
| `data/dlc01-patch.wad` | built here |
| `data/dlc01.wad` | a copy of your `data/vz.wad`, made at deploy |
| `data/Audios/*.pws` | built here, 7 files |

The engine opens `data\dlc01.wad`, then `data\dlc01-patch.wad` above it. The DLC does not run alone:
its archive lacks most of what its scripts import, so the level sits over the base game, as it does on
PS3. `vz.wad` itself is never changed. The copy costs as much disk as `vz.wad`, about 2.4 GB.

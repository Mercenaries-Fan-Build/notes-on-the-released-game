# QuickBMS / compression scanning

QuickBMS is Windows/Linux tooling; on macOS install upstream binaries or use Wine.

Workflow once `output/ffcs_vz/data.bin` exists:

1. Copy `data.bin` to a machine with QuickBMS installed.
2. Run `comtype_scan2.bms` on slices — zlib signatures are plentiful inside `vz` DATA.
3. Promote successful decompressions into a dedicated `.bms` script.

Download: https://aluigi.altervista.org/quickbms.htm


# Game Extractor (watto.org)

Game Extractor lists Mercenaries 2 support via an **Archive_BLOCK** handler.

1. Clone/build https://github.com/wattostudios/GameExtractor
2. Open `data/vz.wad` or `output/ffcs_vz/data.bin`
3. Cross-check paths with `output/ffcs_vz/paths.txt`

Logical filenames are stored in FFCS `PTHS`; nested `.block` payloads live inside `DATA` after the `sges` header.


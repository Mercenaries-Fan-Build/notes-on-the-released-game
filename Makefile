# Mercenaries 2 — full extraction / review (no artificial limits)
#
# ZIP — relative or absolute path to the retail zip (paths below assume you run make from this repo root).
#
# OUTPUT — pipeline root. Default: ../output if ZIP=../Mercenaries 2 World in Flames.zip, else ./output
#
# Examples (relative paths from repo root mercenaries-game/):
#   make extract-all ZIP=../Mercenaries 2 World in Flames.zip
#   make extract-all ZIP=./Mercenaries 2 World in Flames.zip OUTPUT=./output
#   make review-all OUTPUT=./output
#   make clean OUTPUT=./output
#
# FORCE_UNZIP=1 — delete existing OUTPUT and unzip again before processing (passes --force-unzip).

.PHONY: default help clean venv extract-all batch-all build-texture-index review-all review-textures-only stage2-post-validate all extract-saves extract-audio extract-video extract-iso variants export-ue5 ue5-bundle filter-maracaibo regen-maracaibo-glbs regen-all-glbs regen-c3-cells category-samples sample-bundle full-pipeline viewer preview-placements preview-placement-bbox animations animations-validation extract-placements condense-placements build-vz-act-manifest road-graph destruction-graph watermap-decode ue-bind-manifest filter-maracaibo-placements build-pmc-base-set build-c3-cell-manifest extract-demo-ffcs filter-pmc-base regen-pmc-glbs filter-pool-200m regen-pool-200m-glbs extract-terrain extract-zone-props build-luac build-ucfx-byteswap build-havok-extract build-destruction-extract wad-simulator rosetta-oracle dlc-port dlc-port-assets-only trim-patch-wad scan-patch-placements bisect-patch-wad fix-dlc01-aset verify-patch-dlc01 verify-dlc-import-chain dlc-phase0 inventory-dlc-patch verify-patch-dlc verify-patch-dlc-hook verify-patch-vz verify-patch-wad-structure audio-verify-dlc verify-dlc-endian crack-game dlc-asi-native winsock-redirect-asi dlc-asi-native-nobootstrap dlc-asi-native-minimal dlc-asi-native-nohooks dlc-asi-native-no-crash-patch dlc-asi-native-debug lua-enum-asi lua-enum-asi-debug mercs2-probe mercs2-probe-debug asset-miss-probe asset-miss-probe-debug validate-probe-results pmc-blackbox pmc-blackbox-nopatch cruise-dll test-windows test-windows-down test-windows-logs ghidra-ps3-eboot r2-ps3-vz-xrefs ghidra-annotate-preanalysis verify-audio-field-map verify-audio-converter verify-audio-converter-goldens verify-audio-endian patch-anim-table harvest-dlc-strings export-console-strings extract-strings build-wad-crates

# Radius zone around PMC pool building (populate_radius_zone.py in UE).
RADIUS_ZONE_ID ?= pool_200m
RADIUS_ZONE_ANCHOR_ID ?= 0x000a3b30
RADIUS_ZONE_ANCHOR_NAME ?= _pmcoutpost_bld_pool
RADIUS_ZONE_METRES ?= 200

REPO_ROOT := $(abspath .)
# Prefer repo virtualenv (pygltflib, etc.); override with `make PYTHON=python3 …`.
PYTHON := $(if $(wildcard $(REPO_ROOT)/.venv/bin/python),$(REPO_ROOT)/.venv/bin/python,python3)

ZIP ?=
ifndef OUTPUT
  OUTPUT := $(REPO_ROOT)/output
endif

# Uniform glTF root scale for ``make regen-maracaibo-glbs`` (default 1; UE applies glTF unit scaling).
GLB_ROOT_SCALE ?= 1
# Parallel workers for ``make regen-all-glbs`` (default 1; set higher for multi-core).
REGEN_JOBS ?= 1
REGEN_C3_JOBS ?= 16
REGEN_C3_LOD ?= highest-poly-per-xz-footprint

STAGE2_SEQUENTIAL ?= 0
STAGE2_JOBS ?=

# Passed through to stage2_review_extract.sh / stage2_parallel.sh (override per invocation).
STAGE2_MESH_LOD ?= keep-all
STAGE2_SKIP_UCFX ?= 0
STAGE2_SKIP_MESH ?= 0
STAGE2_SKIP_TEX ?= 0
STAGE2_SKIP_HAVOK ?= 0
STAGE2_DIALOG ?= 1
STAGE2_GLTF ?= 1
STAGE2_ANIM ?= 0
STAGE2_LEVEL ?= 0
STAGE2_EMBEDDED_AUDIO ?= 0
# Post-pass after stage 2 (needs build-ucfx-byteswap when STAGE2_VALIDATE_RUST=1)
STAGE2_VALIDATE_RUST ?= 1
STAGE2_VALIDATE_GLTF ?= 0
STAGE2_VALIDATE_SAMPLE ?= 0
STAGE2_VALIDATE_JOBS ?= 8
STAGE2_VALIDATE_STRICT ?= 0
TEXTURE_PNG ?= 1

FORCE_UNZIP ?=

ifeq ($(FORCE_UNZIP),1)
  FORCE_UNZIP_FLAG := --force-unzip
else
  FORCE_UNZIP_FLAG :=
endif

default: help

help:
	@echo "Mercenaries 2 pipeline (full — all packs including vz, all blocks, full stage 2 when using extract-all)"
	@echo ""
	@echo "  make venv         Create ./.venv and pip install requirements.txt (pygltflib — use before tools / make animations)"
	@echo "  make clean       Remove OUTPUT (default: $(OUTPUT))"
	@echo "  make extract-all ZIP=../Mercenaries 2 World in Flames.zip"
	@echo "                      (zip one directory up from this repo — adjust if yours lives elsewhere)"
	@echo "  make extract-all ZIP=./Mercenaries 2 World in Flames.zip OUTPUT=./output"
	@echo "                      Unzip → FFCS → batch decompress every .wad → texture_index.json → stage 2 review"
	@echo "  make batch-all OUTPUT=./output"
	@echo "                      Batch-decompress every extracted/ffcs_* (bulk sges per pack unless EXTRACT_JOBS=1)"
	@echo "  make build-texture-index OUTPUT=./output"
	@echo "                      Scan extracted/**/blocks → OUTPUT/extracted/texture_index.json (cross-block mips)"
	@echo "  make review-all OUTPUT=./output"
	@echo "                      build-texture-index then re-run stage 2 (STAGE2_VALIDATE_RUST=1 default; STAGE2_JOBS=N optional)"
	@echo "  make stage2-post-validate OUTPUT=./output"
	@echo "                      Rust UCFX + optional glTF checks on existing review (no re-extract)"
	@echo "  make review-textures-only OUTPUT=./output"
	@echo "                      Rebuild index + textures only (skip ucfx/mesh/havok/dialog/gltf)"
	@echo "  make extract-saves OUTPUT=./output"
	@echo "                      Parse SaveGames/*.profile → OUTPUT/knowledge/saves.json"
	@echo "  make extract-audio OUTPUT=./output"
	@echo "                      Scan OUTPUT/data/Audios/*.pws → OUTPUT/extracted_audio/"
	@echo "  make extract-video OUTPUT=./output"
	@echo "                      BIK → MP4 via ffmpeg → OUTPUT/movies_mp4/"
	@echo "  make variants OUTPUT=./output"
	@echo "                      Build variant_registry.json from ffcs_shell paths.txt (after extract-all)"
	@echo "  make export-ue5 OUTPUT=./output"
	@echo "                      Bundle review assets → OUTPUT/ue5_import/ (import scripts → UnrealEngineGame/Content/Python/)"
	@echo "  make filter-maracaibo OUTPUT=./output"
	@echo "                      Filter ue5_import manifest → OUTPUT/maracaibo_asset_list.json (for import_mercs2.py)"
	@echo "  make regen-maracaibo-glbs OUTPUT=./output [GLB_ROOT_SCALE=1]"
	@echo "                      Regenerate mesh_scene.glb (embedded textures) for Maracaibo subset"
	@echo "  make regen-all-glbs OUTPUT=./output [REGEN_JOBS=4]"
	@echo "  make regen-c3-cells OUTPUT=./output [REGEN_C3_JOBS=16] [REGEN_C3_LOD=highest-poly-per-xz-footprint]"
	@echo "                      Re-extract ~2234 c3 world-cell GLBs (mesh + LOD dedup; no full stage 2)"
	@echo "                      Regenerate mesh_scene.glb for ALL assets in manifest (skips existing; --force to redo)"
	@echo "  make extract-terrain OUTPUT=./output"
	@echo "                      Merge low_res_terrain UCFX tiles → OUTPUT/extracted/review/batch_vz/.../mesh_scene.glb"
	@echo "  make animations OUTPUT=./output"
	@echo "                      Havok animgroup blocks → OUTPUT/animations/<slug>/<slug>.glb (tools/mercs2_anim_pipeline.py)"
	@echo "  make animations-validation OUTPUT=./output"
	@echo "                      Scan OUTPUT/animations and write OUTPUT/animations/_validation.json (no block reprocess)"
	@echo "  make extract-placements OUTPUT=./output"
	@echo "                      Extract placement data from layers_static + vz_state → output/placements/"
	@echo "                      (+ ECS merge, ASET decode, pmc_base_block_set.json)"
	@echo "  make ue-bind-manifest OUTPUT=./output [WAD_VZ=game-files/pc-game-vz.wad]"
	@echo "                      Water: WAD_VZ or decompressed resident block under output/extracted/"
	@echo "                      Merge placements/graphs/water/c3 → ue5_import/ue_game_binding.json (Editor apply)"
	@echo "  make condense-placements OUTPUT=./output"
	@echo "                      Slim gzip bundle + manifest for transfer (after extract-placements)"
	@echo "  make build-pmc-base-set OUTPUT=./output"
	@echo "                      Write output/pmc_base_block_set.json (needs placements first)"
	@echo "  make extract-demo-ffcs"
	@echo "                      FFCS-slice demo vz.wad → output_demo/extracted/ffcs_vz_demo/ (see docs/demo_corpus.md)"
	@echo "  make filter-pmc-base OUTPUT=./output"
	@echo "                      PMC subset manifests → pmc_base_asset_list.json + placements/pmc_base.json"
	@echo "  make regen-pmc-glbs OUTPUT=./output"
	@echo "                      Regenerate mesh_scene.glb for PMC base asset list"
	@echo "  make filter-pool-200m OUTPUT=./output"
	@echo "                      200m zone around pool → output/radius_zones/pool_200m/ (placements + assets)"
	@echo "  make regen-pool-200m-glbs OUTPUT=./output"
	@echo "                      Regenerate GLBs for pool 200m zone asset list"
	@echo "  make extract-zone-props OUTPUT=./output"
	@echo "                      Extract individual submesh prop GLBs for radius zone → output/submesh_glbs/"
	@echo "  make filter-maracaibo-placements OUTPUT=./output"
	@echo "                      Filter placements to Maracaibo area → output/placements/maracaibo_placements.json"
	@echo "  make ue5-bundle   variants + animations + export-ue5 (after extract-all / review-all)"
	@echo "  make category-samples OUTPUT=./output [TOP=N]"
	@echo "                      Pick one representative mesh per category → OUTPUT/ue5_import/category_samples.json"
	@echo "  make sample-bundle OUTPUT=./output [TOP=N]"
	@echo "                      category-samples + reduced UE5 bundle → OUTPUT/ue5_import_samples/ (smoke-test subset)"
	@echo "  make full-pipeline ZIP=... OUTPUT=./output"
	@echo "                      clean + extract-all (Rust validate on) + saves/audio/video + placements"
	@echo "                      + condense-placements + extract-terrain + ue5-bundle + regen-maracaibo-glbs"
	@echo ""
	@echo "  Resume (after a failed run — do not use full-pipeline; it runs clean):"
	@echo "          make review-all OUTPUT=./output   # re-run stage 2 (builds texture index first)"
	@echo "          # Faster if only glTF failed: STAGE2_SKIP_UCFX=1 STAGE2_SKIP_MESH=1 STAGE2_SKIP_TEX=1 \\"
	@echo "          #   STAGE2_SKIP_HAVOK=1 STAGE2_DIALOG=0 make review-all OUTPUT=./output"
	@echo "          make extract-saves extract-audio extract-video ue5-bundle OUTPUT=./output   # if not done yet"
	@echo "  make preview-placements OUTPUT=./output   # viewer dev server + placement map (MERCS2_PLACEMENTS_ROOT)"
	@echo "  make preview-placement-bbox OUTPUT=./output  # bbox regions + rotation override QA page"
	@echo "  make viewer       npm install + dev server (asset viewer)"
	@echo "  make preview-world-cells  Open Three.js c3 grid preview (/world-cells)"
	@echo "  make extract-iso  Prints ISO/locale extraction hints (mount ISO yourself)"
	@echo "  make clean OUTPUT=./output"
	@echo "  make all           extract-all + saves/audio/video + ue5-bundle + regen-maracaibo-glbs (needs ZIP)"
	@echo ""
	@echo "  make test-windows      Start Windows 7 Docker container (dockur/windows) for game testing"
	@echo "  make test-windows-down Stop the Windows test container"
	@echo "  make test-windows-logs Follow container logs"
	@echo ""
	@echo "  make harvest-dlc-strings OUTPUT=./output"
	@echo "                      DLC patch WAD asset names → fold new hashes into tools/rainbow_table.json"
	@echo "  make export-console-strings"
	@echo "                      Xbox 360 + PS3 WAD names+blocks → game-files/<stem>.{blocks,strings,unique-strings}.txt (+table)"
	@echo "  make extract-strings OUTPUT=./output"
	@echo "                      Both of the above (vars: PATCH_WAD XBOX_WAD PS3_WAD; STRINGS_MERGE=0 to skip table writes)"
	@echo ""
	@echo "  make ghidra-annotate-preanalysis"
	@echo "                      Scan Mercs 1 source → scripts/mercs2_annotations.json (for Ghidra script)"
	@echo ""
	@echo "Variables: ZIP OUTPUT FORCE_UNZIP=1 VARIANT_PATH EXTRACT_JOBS (1=per-block sges; else bulk)"
	@echo "            PYTHON (default: \`./.venv/bin/python\` if present, else \`python3\` — run \`make venv\` for pygltflib)"
	@echo "            STAGE2_SEQUENTIAL=1 STAGE2_JOBS=N STAGE2_SKIP_* STAGE2_VALIDATE_* (stage 2; see docs/stage2_review_improvements.md)"
	@echo "            TOP=N VIEWER_BASE=http://… (category-samples / sample-bundle)"
	@echo "            GLB_ROOT_SCALE (regen-maracaibo-glbs; default 1)"
	@echo "Current OUTPUT=$(OUTPUT)"

venv:
	@set -e; \
	  if [ -x "$(REPO_ROOT)/.venv/bin/python" ]; then \
	    echo "./.venv exists — upgrading pip and syncing requirements.txt"; \
	  else \
	    echo "Creating $(REPO_ROOT)/.venv …"; \
	    python3 -m venv "$(REPO_ROOT)/.venv"; \
	  fi; \
	  "$(REPO_ROOT)/.venv/bin/python" -m pip install -U pip; \
	  "$(REPO_ROOT)/.venv/bin/python" -m pip install -r "$(REPO_ROOT)/requirements.txt"; \
	  echo "Done. Make targets use ./.venv/bin/python automatically, or run: .venv/bin/python tools/…"

clean:
	@test -n "$(OUTPUT)" || (echo "error: OUTPUT is empty" >&2; exit 1)
	@test "$(OUTPUT)" != "/" || (echo "error: refusing to rm /" >&2; exit 1)
	@echo "Removing $(OUTPUT)"
	rm -rf "$(OUTPUT)"

# Clear env knobs that cap or skip work in scripts/extract_all_from_paths.sh (full run = no limits).
# Stage 2 runs separately via review-all so we can build texture_index.json first (cross-block mip assembly).
extract-all:
	@test -n "$(ZIP)" || (echo "error: set ZIP, e.g.  make extract-all ZIP=../Mercenaries 2 World in Flames.zip" >&2; exit 1)
	@test -f "$(ZIP)" || (echo "error: ZIP file not found: $(ZIP)" >&2; exit 1)
	bash -c 'unset MAX START VZ_MAX SKIP_EXISTING WITH_UCFX ALLOW_PARTIAL 2>/dev/null; \
	  exec "$(REPO_ROOT)/scripts/extract_from_zip.sh" --everything --no-stage2 --out-dir "$(OUTPUT)" $(FORCE_UNZIP_FLAG) "$(ZIP)"'
	@$(MAKE) review-all OUTPUT="$(OUTPUT)" \
	  STAGE2_VALIDATE_RUST="$(STAGE2_VALIDATE_RUST)" STAGE2_VALIDATE_GLTF="$(STAGE2_VALIDATE_GLTF)" \
	  STAGE2_VALIDATE_SAMPLE="$(STAGE2_VALIDATE_SAMPLE)" STAGE2_VALIDATE_JOBS="$(STAGE2_VALIDATE_JOBS)" \
	  STAGE2_VALIDATE_STRICT="$(STAGE2_VALIDATE_STRICT)"

# Scan all decompressed block blobs and build hash→chunk map for texture_streaming / full mip chains.
build-texture-index:
	@test -d "$(OUTPUT)/extracted" || (echo "error: $(OUTPUT)/extracted missing — run extract-all or batch-all first" >&2; exit 1)
	@echo "Building texture streaming index → $(OUTPUT)/extracted/texture_index.json"
	@set -e; \
	  blocks=$$(find "$(OUTPUT)/extracted" -type d -name blocks 2>/dev/null | sort -u); \
	  test -n "$$blocks" || (echo "error: no .../extracted/**/blocks directories under $(OUTPUT)" >&2; exit 1); \
	  "$(PYTHON)" "$(REPO_ROOT)/tools/texture_streaming_index.py" $$blocks --out "$(OUTPUT)/extracted/texture_index.json"

# Re-run batch sges step for every FFCS pack (no unzip). Clears caps so vz and every other .wad pack are included.
batch-all:
	@test -d "$(OUTPUT)/extracted" || (echo "error: $(OUTPUT)/extracted missing — run extract-all first (needs FFCS folders)" >&2; exit 1)
	bash -c 'set -e; unset MAX START VZ_MAX SKIP_EXISTING WITH_UCFX ALLOW_PARTIAL 2>/dev/null || true; \
	  export EXTRACT_OUT_ROOT="$(OUTPUT)/extracted"; \
	  for d in "$(OUTPUT)"/extracted/ffcs_*/; do \
	    test -f "$$d/paths.txt" || continue; \
	    echo "=== batch $$(basename "$$d") → $$EXTRACT_OUT_ROOT ==="; \
	    "$(REPO_ROOT)/scripts/extract_all_from_paths.sh" "$$d"; \
	  done'

review-all: build-texture-index
	@test -d "$(OUTPUT)" || (echo "error: OUTPUT directory missing: $(OUTPUT) (run extract-all first or set OUTPUT=./output)" >&2; exit 1)
	@test -f "$(OUTPUT)/extracted/texture_index.json" || (echo "error: missing $(OUTPUT)/extracted/texture_index.json (build-texture-index failed?)" >&2; exit 1)
	@env TEXTURE_INDEX="$(OUTPUT)/extracted/texture_index.json" \
	  STAGE2_SEQUENTIAL="$(STAGE2_SEQUENTIAL)" STAGE2_JOBS="$(STAGE2_JOBS)" \
	  STAGE2_MESH_LOD="$(STAGE2_MESH_LOD)" \
	  STAGE2_SKIP_UCFX="$(STAGE2_SKIP_UCFX)" STAGE2_SKIP_MESH="$(STAGE2_SKIP_MESH)" STAGE2_SKIP_TEX="$(STAGE2_SKIP_TEX)" STAGE2_SKIP_HAVOK="$(STAGE2_SKIP_HAVOK)" \
	  STAGE2_DIALOG="$(STAGE2_DIALOG)" STAGE2_GLTF="$(STAGE2_GLTF)" STAGE2_ANIM="$(STAGE2_ANIM)" STAGE2_LEVEL="$(STAGE2_LEVEL)" \
	  STAGE2_EMBEDDED_AUDIO="$(STAGE2_EMBEDDED_AUDIO)" \
	  STAGE2_VALIDATE_RUST="$(STAGE2_VALIDATE_RUST)" STAGE2_VALIDATE_GLTF="$(STAGE2_VALIDATE_GLTF)" \
	  STAGE2_VALIDATE_SAMPLE="$(STAGE2_VALIDATE_SAMPLE)" STAGE2_VALIDATE_JOBS="$(STAGE2_VALIDATE_JOBS)" \
	  STAGE2_VALIDATE_STRICT="$(STAGE2_VALIDATE_STRICT)" TEXTURE_PNG="$(TEXTURE_PNG)" \
	  bash -c 'unset MAX START VZ_MAX SKIP_EXISTING WITH_UCFX ALLOW_PARTIAL 2>/dev/null; \
	  OUT="$$1"; \
	  if [ "$$STAGE2_SEQUENTIAL" = "1" ]; then \
	    exec "$(REPO_ROOT)/scripts/stage2_review_extract.sh" "$$OUT"; \
	  elif [ -n "$$STAGE2_JOBS" ]; then \
	    exec "$(REPO_ROOT)/scripts/stage2_parallel.sh" "$$OUT" "$$STAGE2_JOBS"; \
	  else \
	    exec "$(REPO_ROOT)/scripts/stage2_parallel.sh" "$$OUT"; \
	  fi' bash "$(OUTPUT)"

# Re-extract textures only (reuses existing ucfx/mesh/havok); rebuilds texture_index.json first.
review-textures-only: build-texture-index
	@$(MAKE) review-all OUTPUT="$(OUTPUT)" STAGE2_SKIP_UCFX=1 STAGE2_SKIP_MESH=1 STAGE2_SKIP_HAVOK=1 STAGE2_DIALOG=0 STAGE2_GLTF=0

# Post-validate existing stage-2 output (Rust structural + optional glTF). Build byteswap first if needed.
stage2-post-validate: build-ucfx-byteswap
	@test -d "$(OUTPUT)" || (echo "error: OUTPUT missing: $(OUTPUT)" >&2; exit 1)
	@STAGE2_VALIDATE_RUST=1 STAGE2_VALIDATE_GLTF="$(STAGE2_VALIDATE_GLTF)" \
	  STAGE2_VALIDATE_SAMPLE="$(STAGE2_VALIDATE_SAMPLE)" STAGE2_VALIDATE_JOBS="$(STAGE2_VALIDATE_JOBS)" \
	  STAGE2_VALIDATE_STRICT="$(STAGE2_VALIDATE_STRICT)" \
	  bash "$(REPO_ROOT)/scripts/stage2_post_validate.sh" "$(OUTPUT)"

VARIANT_PATH ?=

variants:
	@set -e; \
	if [ -n "$(VARIANT_PATH)" ] && [ -f "$(VARIANT_PATH)" ]; then \
	  echo "variant_classifier: $(VARIANT_PATH)"; \
	  "$(PYTHON)" "$(REPO_ROOT)/tools/variant_classifier.py" --paths "$(VARIANT_PATH)" --out "$(OUTPUT)/variant_registry.json"; \
	elif [ -f "$(OUTPUT)/extracted/ffcs_shell/paths.txt" ]; then \
	  echo "variant_classifier: $(OUTPUT)/extracted/ffcs_shell/paths.txt"; \
	  "$(PYTHON)" "$(REPO_ROOT)/tools/variant_classifier.py" --paths "$(OUTPUT)/extracted/ffcs_shell/paths.txt" --out "$(OUTPUT)/variant_registry.json"; \
	else \
	  echo "Skipping variants: no paths.txt (set VARIANT_PATH= or run extract-all first)"; \
	fi

extract-saves:
	@mkdir -p "$(OUTPUT)/knowledge"
	bash -c 'shopt -s nullglob; profiles=("$(REPO_ROOT)/SaveGames"/*.profile); \
	  if [ $${#profiles[@]} -eq 0 ]; then echo "No SaveGames/*.profile — skipping"; exit 0; fi; \
	  "$(PYTHON)" "$(REPO_ROOT)/tools/savefile_parser.py" "$${profiles[@]}" --out "$(OUTPUT)/knowledge/saves.json"'

extract-audio:
	@mkdir -p "$(OUTPUT)/extracted_audio"
	@bash -c 'if [ ! -d "$(OUTPUT)/data/Audios" ]; then echo "Note: $(OUTPUT)/data/Audios missing — unzip game data first (extract-all)"; exit 0; fi; \
	  set -e; shopt -s nullglob; \
	  for f in "$(OUTPUT)/data/Audios"/*.pws; do \
	    echo "pws_extractor: $$f"; \
	    "$(PYTHON)" "$(REPO_ROOT)/tools/pws_extractor.py" "$$f" --out-dir "$(OUTPUT)/extracted_audio"; \
	  done'

extract-video:
	@mkdir -p "$(OUTPUT)/movies_mp4"
	@if [ ! -d "$(OUTPUT)/data/Movies" ]; then \
	  echo "Note: $(OUTPUT)/data/Movies missing — skipping"; exit 0; \
	fi
	@"$(PYTHON)" "$(REPO_ROOT)/tools/bik_extractor.py" --movies-dir "$(OUTPUT)/data/Movies" --out-dir "$(OUTPUT)/movies_mp4"

extract-iso:
	@echo "Locale/audio from disc image (examples):"
	@echo "  macOS:  hdiutil attach \"$$ISO\" -mountpoint /Volumes/M2"
	@echo "  Then copy French.wad / Russian.wad or vo_stream.*.pws into OUTPUT/data and re-run extract-audio."
	@echo "  Set ISO to your .iso path when mounting."

export-ue5: variants animations
	@test -d "$(OUTPUT)" || (echo "error: OUTPUT missing: $(OUTPUT)" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/ue5_export.py" --pipeline-root "$(OUTPUT)" --out "$(OUTPUT)/ue5_import"

animations:
	@if [ ! -d "$(OUTPUT)/extracted" ]; then echo "Note: skipping animations (no $(OUTPUT)/extracted — run extract-all / batch-all first)"; exit 0; fi
	@"$(PYTHON)" -c "import pygltflib" 2>/dev/null || (echo "error: pygltflib not available with PYTHON=$(PYTHON) — run \`make venv\` (repo .venv)" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/mercs2_anim_pipeline.py" --pipeline-root "$(OUTPUT)" --filter all

animations-validation:
	@test -d "$(OUTPUT)/animations" || (echo "error: $(OUTPUT)/animations missing — run make animations first" >&2; exit 1)
	@"$(PYTHON)" -c "import pygltflib" 2>/dev/null || (echo "error: pygltflib not available with PYTHON=$(PYTHON) — run \`make venv\`" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/regen_anim_glbs.py" --pipeline-root "$(OUTPUT)" --validation-only

ue5-bundle: export-ue5

build-vz-act-manifest:
	@test -f "$(OUTPUT)/placements/vz_state/all_vz_state.json" || (echo "error: run make extract-placements first" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/build_vz_act_manifest.py" --output "$(OUTPUT)/placements/vz_act_layer_manifest.json"

# Game→UE binding manifest (merge placements, graphs, water, c3 cells — no Editor required).
WAD_VZ ?= $(REPO_ROOT)/game-files/pc-game-vz.wad
# Fallback when WAD_VZ is absent but extract-all produced decompressed resident:
RESIDENT_BLOCK ?= $(OUTPUT)/extracted/batch_vz/blocks/03185_blocks__VZ__resident_P000_Q3.block.bin

road-graph:
	@test -f "$(OUTPUT)/placements/layers_static.json" || (echo "error: run make extract-placements first" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/road_graph_extractor.py" \
	  --placements "$(OUTPUT)/placements/layers_static.json" \
	  --out "$(OUTPUT)/placements/road_graph.json"

destruction-graph:
	@test -f "$(OUTPUT)/placements/layers_static.json" || (echo "error: run make extract-placements first" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/destruction_link_resolver.py" \
	  --layers-static "$(OUTPUT)/placements/layers_static.json" \
	  --vz-state-glob "$(OUTPUT)/placements/vz_state/*.json" \
	  --out "$(OUTPUT)/placements/destruction_graph.json"

watermap-decode:
	@if [ -f "$(WAD_VZ)" ]; then \
	  "$(PYTHON)" "$(REPO_ROOT)/tools/watermap_decode.py" \
	    --wad "$(WAD_VZ)" \
	    --out "$(OUTPUT)/watermap_decode.json"; \
	elif [ -f "$(RESIDENT_BLOCK)" ]; then \
	  echo "watermap-decode: using extracted resident block ($(RESIDENT_BLOCK))"; \
	  "$(PYTHON)" "$(REPO_ROOT)/tools/watermap_decode.py" \
	    --block-bin "$(RESIDENT_BLOCK)" \
	    --out "$(OUTPUT)/watermap_decode.json"; \
	else \
	  echo "error: no WAD_VZ ($(WAD_VZ)) and no RESIDENT_BLOCK ($(RESIDENT_BLOCK))" >&2; \
	  echo "  run extract-all first or set WAD_VZ=/path/to/vz.wad" >&2; \
	  exit 1; \
	fi

ue-bind-manifest: extract-placements
	@$(MAKE) build-vz-act-manifest OUTPUT="$(OUTPUT)" --no-print-directory
	@if [ -d "$(OUTPUT)/extracted/review/batch_vz" ]; then \
	  $(MAKE) build-c3-cell-manifest OUTPUT="$(OUTPUT)" --no-print-directory; \
	else \
	  echo "Note: skipping build-c3-cell-manifest (no review/batch_vz — run review-all)"; \
	fi
	@$(MAKE) watermap-decode OUTPUT="$(OUTPUT)" WAD_VZ="$(WAD_VZ)" RESIDENT_BLOCK="$(RESIDENT_BLOCK)" --no-print-directory
	@$(MAKE) road-graph destruction-graph OUTPUT="$(OUTPUT)" --no-print-directory
	@"$(PYTHON)" "$(REPO_ROOT)/tools/build_ue_game_binding.py" --output "$(OUTPUT)"

extract-placements:
	@test -d "$(OUTPUT)/extracted/batch_vz/blocks" || (echo "error: $(OUTPUT)/extracted/batch_vz/blocks missing — run extract-all first" >&2; exit 1)
	@mkdir -p "$(OUTPUT)/placements/vz_state"
	@echo "Extracting placements from layers_static..."
	@"$(PYTHON)" "$(REPO_ROOT)/tools/placement_extractor.py" \
	  "$(OUTPUT)/extracted/batch_vz/blocks/00029_blocks__VZ__layers_static_P000_Q3.block.bin" \
	  -o "$(OUTPUT)/placements/layers_static.json"
	@echo "Extracting placements from vz_state blocks (batch)..."
	@"$(PYTHON)" "$(REPO_ROOT)/tools/placement_extractor.py" \
	  --batch "$(OUTPUT)/extracted/batch_vz/blocks/" \
	  --filter vz_state \
	  -o "$(OUTPUT)/placements/vz_state/all_vz_state.json"
	@echo "ECS COMP harvest + merge (see tools/ecs_metadata_extract.py)..."
	@"$(PYTHON)" "$(REPO_ROOT)/tools/ecs_metadata_extract.py" \
	  --layers-static-bin "$(OUTPUT)/extracted/batch_vz/blocks/00029_blocks__VZ__layers_static_P000_Q3.block.bin" \
	  --vz-state-dir "$(OUTPUT)/extracted/batch_vz/blocks" \
	  --out-ecs "$(OUTPUT)/placements/ecs_components.json" \
	  --merge-layers-static-json "$(OUTPUT)/placements/layers_static.json" \
	  --merge-vz-state-json "$(OUTPUT)/placements/vz_state/all_vz_state.json"
	@echo "ASET decode → block_dependency_graph.json..."
	@"$(PYTHON)" "$(REPO_ROOT)/tools/aset_decoder.py" \
	  --aset "$(OUTPUT)/extracted/ffcs_vz/aset.bin" \
	  --texture-index "$(OUTPUT)/extracted/texture_index.json" \
	  --out "$(OUTPUT)/block_dependency_graph.json"
	@echo "PMC base block inventory..."
	@"$(PYTHON)" "$(REPO_ROOT)/tools/build_pmc_base_block_set.py" \
	  --ffcs-paths "$(OUTPUT)/extracted/ffcs_vz/paths.txt" \
	  --layers-static "$(OUTPUT)/placements/layers_static.json" \
	  --out "$(OUTPUT)/pmc_base_block_set.json"
	@echo "Lua script chunk split + PMC string harvest..."
	@"$(PYTHON)" "$(REPO_ROOT)/tools/lua_script_chunks.py" \
	  --scripts-bin "$(OUTPUT)/extracted/batch_vz/blocks/03197_blocks__VZ__scripts_vz_P000_Q3.block.bin" \
	  --out-dir "$(OUTPUT)/lua_chunks/scripts_vz" \
	  --harvest-json "$(OUTPUT)/placements/pmc_lua_string_harvest.json" \
	  --harvest-csv "$(OUTPUT)/placements/pmc_lua_string_harvest.csv"
	@echo "Script hash → Lua chunk index map..."
	@"$(PYTHON)" "$(REPO_ROOT)/tools/script_hash_map.py" \
	  --scripts-block "$(OUTPUT)/extracted/batch_vz/blocks/03197_blocks__VZ__scripts_vz_P000_Q3.block.bin" \
	  --resident-block "$(OUTPUT)/extracted/batch_vz/blocks/00464_blocks__VZ__resident_P000_Q3.block.bin" \
	  --harvest-json "$(OUTPUT)/placements/pmc_lua_string_harvest.json" \
	  --out "$(OUTPUT)/placements/script_hash_map.json"
	@echo "Placement extraction complete → $(OUTPUT)/placements/"

condense-placements:
	@test -f "$(OUTPUT)/placements/layers_static.json" || (echo "error: run make extract-placements first" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/condense_placements.py" condense \
	  --output "$(OUTPUT)" \
	  --write-subsets

build-c3-cell-manifest:
	@test -d "$(OUTPUT)/extracted/review/batch_vz" || (echo "error: run make review-all first" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/build_c3_cell_manifest.py" \
	  --review-root "$(OUTPUT)/extracted/review/batch_vz" \
	  --out "$(OUTPUT)/placements/c3_cell_manifest.json" \
	  --min-vertices 50

build-pmc-base-set:
	@test -f "$(OUTPUT)/placements/layers_static.json" || (echo "error: run make extract-placements first" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/build_pmc_base_block_set.py" \
	  --ffcs-paths "$(OUTPUT)/extracted/ffcs_vz/paths.txt" \
	  --layers-static "$(OUTPUT)/placements/layers_static.json" \
	  --out "$(OUTPUT)/pmc_base_block_set.json"

extract-demo-ffcs:
	@mkdir -p "$(REPO_ROOT)/output_demo/extracted"
	@"$(PYTHON)" "$(REPO_ROOT)/tools/mercs2_ffcs_extract.py" \
	  "$(REPO_ROOT)/Mercenaries 2 World in Flames DEMO/data/vz.wad" \
	  --out "$(REPO_ROOT)/output_demo/extracted/ffcs_vz_demo"

filter-pmc-base:
	@test -f "$(OUTPUT)/ue5_import/metadata/manifest.json" || (echo "error: missing $(OUTPUT)/ue5_import — run make ue5-bundle" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/filter_pmc_base.py" \
	  --pmc-set "$(OUTPUT)/pmc_base_block_set.json" \
	  --manifest "$(OUTPUT)/ue5_import/metadata/manifest.json" \
	  --layers-static "$(OUTPUT)/placements/layers_static.json" \
	  --vz-state "$(OUTPUT)/placements/vz_state/all_vz_state.json" \
	  --out-assets "$(OUTPUT)/pmc_base_asset_list.json" \
	  --out-placements "$(OUTPUT)/placements/pmc_base.json" \
	  --out-streaming "$(OUTPUT)/pmc_base_streaming_groups.json"

regen-pmc-glbs: filter-pmc-base
	@"$(PYTHON)" -c "import pygltflib" 2>/dev/null || (echo "error: pygltflib — run make venv" >&2; exit 1)
	@cd "$(REPO_ROOT)/tools" && "$(PYTHON)" "$(REPO_ROOT)/tools/regen_pmc_base_glbs.py" --pipeline-root "$(abspath $(OUTPUT))" --glb-root-scale "$(GLB_ROOT_SCALE)"

filter-pool-200m:
	@test -f "$(OUTPUT)/placements/layers_static.json" || (echo "error: run make extract-placements first" >&2; exit 1)
	@test -f "$(OUTPUT)/ue5_import/metadata/manifest.json" || (echo "error: run make ue5-bundle first" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/filter_radius_zone.py" \
	  --zone-id "$(RADIUS_ZONE_ID)" \
	  --anchor-entity-id "$(RADIUS_ZONE_ANCHOR_ID)" \
	  --anchor-entity-name "$(RADIUS_ZONE_ANCHOR_NAME)" \
	  --radius "$(RADIUS_ZONE_METRES)" \
	  --review-root "$(OUTPUT)/extracted/review" \
	  --output "$(OUTPUT)"

regen-pool-200m-glbs: filter-pool-200m
	@"$(PYTHON)" -c "import pygltflib" 2>/dev/null || (echo "error: pygltflib — run make venv" >&2; exit 1)
	@cd "$(REPO_ROOT)/tools" && "$(PYTHON)" "$(REPO_ROOT)/tools/regen_pmc_base_glbs.py" \
	  --pipeline-root "$(abspath $(OUTPUT))" \
	  --asset-list "$(abspath $(OUTPUT))/radius_zones/$(RADIUS_ZONE_ID)/asset_list.json" \
	  --glb-root-scale "$(GLB_ROOT_SCALE)"

extract-zone-props: filter-pool-200m
	@"$(PYTHON)" -c "import pygltflib" 2>/dev/null || (echo "error: pygltflib — run make venv" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/extract_submesh_glbs.py" \
	  --asset-list "$(abspath $(OUTPUT))/radius_zones/$(RADIUS_ZONE_ID)/asset_list.json" \
	  --zone-json "$(abspath $(OUTPUT))/radius_zones/$(RADIUS_ZONE_ID)/zone.json" \
	  --review-root "$(OUTPUT)/extracted/review" \
	  --out "$(abspath $(OUTPUT))/submesh_glbs"

filter-maracaibo-placements: extract-placements
	@echo "Filtering placements to Maracaibo area..."
	@"$(PYTHON)" "$(REPO_ROOT)/tools/filter_maracaibo_placements.py" \
	  --layers-static "$(OUTPUT)/placements/layers_static.json" \
	  --vz-state-dir "$(OUTPUT)/placements/vz_state/" \
	  --out "$(OUTPUT)/placements/maracaibo_placements.json"

filter-maracaibo:
	@test -f "$(OUTPUT)/ue5_import/metadata/manifest.json" || \
	  (echo "error: missing $(OUTPUT)/ue5_import/metadata/manifest.json — run make ue5-bundle first" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/filter_maracaibo.py" \
	  --manifest "$(OUTPUT)/ue5_import/metadata/manifest.json" \
	  --review-root "$(OUTPUT)/extracted/review" \
	  --out "$(OUTPUT)/maracaibo_asset_list.json"

regen-maracaibo-glbs: filter-maracaibo filter-maracaibo-placements
	@"$(PYTHON)" -c "import pygltflib" 2>/dev/null || (echo "error: pygltflib not available — run make venv" >&2; exit 1)
	@cd "$(REPO_ROOT)/tools" && "$(PYTHON)" "$(REPO_ROOT)/tools/regen_maracaibo_glbs.py" --pipeline-root "$(abspath $(OUTPUT))" --glb-root-scale "$(GLB_ROOT_SCALE)"

REGEN_FORCE ?=
regen-c3-cells: build-texture-index
	@test -d "$(OUTPUT)/extracted/review/batch_vz" || (echo "error: run make review-all first" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/regen_c3_world_cells.py" \
	  --pipeline-root "$(abspath $(OUTPUT))" \
	  --lod "$(REGEN_C3_LOD)" \
	  --jobs $(REGEN_C3_JOBS) \
	  --texture-index "$(OUTPUT)/extracted/texture_index.json" \
	  --glb-root-scale "$(GLB_ROOT_SCALE)"

regen-all-glbs:
	@"$(PYTHON)" -c "import pygltflib" 2>/dev/null || (echo "error: pygltflib not available — run make venv" >&2; exit 1)
	@test -f "$(OUTPUT)/ue5_import/metadata/manifest.json" || (echo "error: missing manifest — run make ue5-bundle first" >&2; exit 1)
	@cd "$(REPO_ROOT)/tools" && "$(PYTHON)" "$(REPO_ROOT)/tools/regen_all_glbs.py" --pipeline-root "$(abspath $(OUTPUT))" --glb-root-scale "$(GLB_ROOT_SCALE)" --jobs $(REGEN_JOBS) $(if $(REGEN_FORCE),--force,)

extract-terrain:
	@"$(PYTHON)" -c "import pygltflib" 2>/dev/null || (echo "error: pygltflib — run make venv" >&2; exit 1)
	@test -d "$(OUTPUT)/extracted/batch_vz/blocks" || (echo "error: missing $(OUTPUT)/extracted/batch_vz/blocks — run review-all / stage2 first" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/terrain_extractor.py" \
	  --repo-root "$(REPO_ROOT)" \
	  --extracted-root "$(abspath $(OUTPUT))/extracted"

TOP ?= 1
VIEWER_BASE ?= http://localhost:5173

category-samples:
	@test -f "$(OUTPUT)/ue5_import/metadata/manifest.json" || \
	  (echo "error: missing $(OUTPUT)/ue5_import/metadata/manifest.json — run make ue5-bundle first" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/select_category_samples.py" \
	  --bundle "$(OUTPUT)/ue5_import" \
	  --review-root "$(OUTPUT)/extracted/review" \
	  --viewer-base "$(VIEWER_BASE)" \
	  --top $(TOP)

sample-bundle:
	@test -f "$(OUTPUT)/ue5_import/metadata/manifest.json" || \
	  (echo "error: missing $(OUTPUT)/ue5_import/metadata/manifest.json — run make ue5-bundle first" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/select_category_samples.py" \
	  --bundle "$(OUTPUT)/ue5_import" \
	  --review-root "$(OUTPUT)/extracted/review" \
	  --viewer-base "$(VIEWER_BASE)" \
	  --top $(TOP) \
	  --samples-bundle "$(OUTPUT)/ue5_import_samples"

full-pipeline:
	@test -n "$(ZIP)" || (echo "error: set ZIP for full-pipeline" >&2; exit 1)
	$(MAKE) clean OUTPUT="$(OUTPUT)"
	$(MAKE) extract-all ZIP="$(ZIP)" OUTPUT="$(OUTPUT)" \
	  STAGE2_VALIDATE_RUST="$(STAGE2_VALIDATE_RUST)" STAGE2_VALIDATE_GLTF="$(STAGE2_VALIDATE_GLTF)" \
	  STAGE2_VALIDATE_SAMPLE="$(STAGE2_VALIDATE_SAMPLE)" STAGE2_VALIDATE_JOBS="$(STAGE2_VALIDATE_JOBS)" \
	  STAGE2_VALIDATE_STRICT="$(STAGE2_VALIDATE_STRICT)"
	$(MAKE) extract-saves OUTPUT="$(OUTPUT)"
	$(MAKE) extract-audio OUTPUT="$(OUTPUT)"
	$(MAKE) extract-video OUTPUT="$(OUTPUT)"
	$(MAKE) extract-placements OUTPUT="$(OUTPUT)"
	$(MAKE) condense-placements OUTPUT="$(OUTPUT)"
	$(MAKE) extract-terrain OUTPUT="$(OUTPUT)"
	$(MAKE) ue5-bundle OUTPUT="$(OUTPUT)"
	$(MAKE) regen-maracaibo-glbs OUTPUT="$(OUTPUT)"

# ---- SecuROM Removal (Retail → Cracked) ----
# Accepts v1.0 (17MB, original disc) or v1.1 (51MB, update) — auto-detected.

RETAIL_EXE ?=

crack-game:
	@test -n "$(RETAIL_EXE)" || (echo "error: set RETAIL_EXE=path/to/Mercenaries2.exe (v1.0 or v1.1 retail)" >&2; exit 1)
	@test -f "$(RETAIL_EXE)" || (echo "error: retail exe not found at $(RETAIL_EXE)" >&2; exit 1)
	@mkdir -p "$(OUTPUT)/patched"
	@"$(PYTHON)" "$(REPO_ROOT)/tools/apply_securom_patch.py" \
	  "$(RETAIL_EXE)" \
	  --output "$(OUTPUT)/patched/Mercenaries2.exe"
	@echo ""
	@echo "Building pmc_bb.dll..."
	@$(MAKE) pmc-blackbox
	@cp "$(OUTPUT)/dlls/pmc_bb.dll" "$(OUTPUT)/patched/pmc_bb.dll"
	@echo ""
	@echo "Ready: $(OUTPUT)/patched/"
	@echo "  Mercenaries2.exe   (patched, imports pmc_bb.dll)"
	@echo "  pmc_bb.dll   (SecuROM spoof + debug console + ASI loader)"

# ---- Animation Hash Table Patch (1024 -> 4096 entries) ----
# Expands the animation override hash table to prevent livelock when loading
# patch WADs with >1024 animation entries (DLC has 2,609).
CRACKED_EXE ?=

patch-anim-table:
	@test -n "$(CRACKED_EXE)" || (echo "error: set CRACKED_EXE=path/to/cracked/Mercenaries2.exe" >&2; exit 1)
	@test -f "$(CRACKED_EXE)" || (echo "error: cracked exe not found at $(CRACKED_EXE)" >&2; exit 1)
	@mkdir -p "$(OUTPUT)/patched"
	@"$(PYTHON)" "$(REPO_ROOT)/tools/patch_anim_table.py" \
	  "$(CRACKED_EXE)" \
	  --output "$(OUTPUT)/patched/Mercenaries2.exe"
	@echo ""
	@echo "Patched EXE: $(OUTPUT)/patched/Mercenaries2.exe"
	@echo "  Animation hash table expanded from 1024 to 4096 entries"

# ---- Native Lua 5.1 Compiler (Mercs2-compatible) ----
# Builds a platform-native luac by copying clean upstream Lua 5.1.5 source,
# applying Mercs2 bytecode-compatibility patches, and compiling for the host.
# Patches live in tools/lua51-mercs2/patches/ and are applied in sorted order.
LUAC_UPSTREAM := $(REPO_ROOT)/tools/lua51-src/src
LUAC_BUILD_DIR := $(REPO_ROOT)/tools/lua51-mercs2/build
LUAC_PATCHES := $(REPO_ROOT)/tools/lua51-mercs2/patches
LUAC_NATIVE := $(LUAC_BUILD_DIR)/luac

# Detect platform for the Lua Makefile target
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  LUA_PLAT := macosx
else ifeq ($(UNAME_S),Linux)
  LUA_PLAT := linux
else
  LUA_PLAT := posix
endif

build-luac:
	@if [ -f "$(REPO_ROOT)/tools/lua51-mercs2/luac.exe" ]; then \
	   echo "Using prebuilt luac: tools/lua51-mercs2/luac.exe (skipping rebuild)"; \
	elif [ -x "$(LUAC_NATIVE)" ]; then \
	   echo "Using built luac: $(LUAC_NATIVE)"; \
	else \
	   "$(MAKE)" "$(LUAC_NATIVE)"; \
	fi

$(LUAC_NATIVE): $(LUAC_PATCHES)/*.patch
	@echo "Building native luac (platform: $(LUA_PLAT))..."
	@echo "  [1/4] Copying upstream Lua 5.1.5 source..."
	@rm -rf "$(LUAC_BUILD_DIR)"
	@cp -r "$(LUAC_UPSTREAM)" "$(LUAC_BUILD_DIR)"
	@echo "  [2/4] Applying Mercs2 patches..."
	@for p in "$(LUAC_PATCHES)"/*.patch; do \
	   echo "    - $$(basename $$p)"; \
	   patch -d "$(LUAC_BUILD_DIR)" -p1 < "$$p" || exit 1; \
	 done
	@echo "  [3/4] Compiling..."
	@"$(MAKE)" -C "$(LUAC_BUILD_DIR)" $(LUA_PLAT) 2>&1 | tail -3
	@test -f "$(LUAC_NATIVE)" || (echo "  ERROR: build failed" >&2; exit 1)
	@echo "  [4/4] Verifying bytecode header..."
	@echo 'print("")' > /tmp/_luac_verify.lua
	@"$(LUAC_NATIVE)" -o /tmp/_luac_verify.luac /tmp/_luac_verify.lua
	@HDR=$$(xxd -p -l 12 /tmp/_luac_verify.luac); \
	 if [ "$$HDR" = "1b4c75615100010404040400" ]; then \
	   echo "  OK: $$HDR"; \
	 else \
	   echo "  ERROR: header mismatch: $$HDR (expected 1b4c75615100010404040400)" >&2; \
	   rm -f "$(LUAC_NATIVE)"; \
	   exit 1; \
	 fi
	@rm -f /tmp/_luac_verify.lua /tmp/_luac_verify.luac
	@echo "  Built: $(LUAC_NATIVE)"

# ---- Xbox 360 DLC Port ----
# Produces a complete vz-patch.wad with DLC blocks + nohook bootstrap.
# Requires SOURCE_WAD (retail vz.wad) for INDX/ASET template + bootstrap injection.

DLC_RAR ?= Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar
SOURCE_WAD ?=

# Parallel block conversion workers (default: all CPUs). Override: make dlc-port JOBS=8
JOBS ?=

build-ucfx-byteswap:
	@echo "Building Rust ucfx_byteswap binary..."
	cd "$(REPO_ROOT)/tools/wad_simulator" && cargo build --release -p ucfx_byteswap
	@echo "  Built: tools/wad_simulator/target/release/ucfx_byteswap"

# Build every Rust crate in the wad_simulator workspace (ucfx_byteswap converter,
# wad_simulator validator, mercs2_formats, dlc_port, loadprobe) in one pass. The
# DLC port runs the converter binary directly, and the ucfx_byteswap_wrapper only
# *warns* on a stale binary — so port targets depend on this to guarantee fresh
# converter machine code (and a fresh validator for the post-port simulator run).
build-wad-crates:
	@echo "Building all Rust WAD crates (workspace: ucfx_byteswap, wad_simulator, mercs2_formats, dlc_port, loadprobe)..."
	cd "$(REPO_ROOT)/tools/wad_simulator" && cargo build --release --workspace
	@echo "  Built workspace binaries in tools/wad_simulator/target/release/"
build-havok-extract:
	@echo "Building Rust havok_extract binary (exact LE Havok packfile decoder)..."
	cd "$(REPO_ROOT)/tools/wad_simulator" && cargo build --release -p havok_extract
	@echo "  Built: tools/wad_simulator/target/release/havok_extract"
	@echo "  (stage2_parallel.sh uses it automatically when present; else falls back to tools/havok_extractor.py)"

build-destruction-extract:
	@echo "Building Rust destruction_extract binary (HIER/SWIT destruction-state decoder)..."
	cd "$(REPO_ROOT)/tools/wad_simulator" && cargo build --release -p destruction_extract
	@echo "  Built: tools/wad_simulator/target/release/destruction_extract"
	@echo "  (stage2_parallel.sh runs it per block; orchestrator blocks emit destruction.json)"

# Build + run the engine-consumption simulator over a WAD. Includes the
# texture buffer-too-small validator (BODY shorter than the engine's
# dimension-derived DXT mip chain -> STATUS_BUFFER_TOO_SMALL -> streaming
# livelock). Compilation is platform-agnostic via cargo.
#   make wad-simulator                       # runs on $(OUTPUT)/data/vz-patch.wad
#   make wad-simulator SIM_WAD=/path/to.wad  # any WAD
#   make wad-simulator SOURCE_WAD=game-files/vz.wad   # add base overlay
# Tip: pipe through grep for just the streaming-livelock hits:
#   make wad-simulator 2>&1 | grep -i buffer_too_small
SIM_WAD=$(OUTPUT)/data/vz-patch.wad
SOURCE_WAD=$(REPO_ROOT)/game-files/pc-game-vz.wad
RAINBOW_TABLE=$(REPO_ROOT)/tools/rainbow_table.json
# External streaming audio dir fed to the simulator (--audios-dir). Default: the
# converted audio produced by the pipeline. Passed only when it exists.
SIM_AUDIOS_DIR=$(OUTPUT)/data/Audios
wad-simulator:
	@echo "Building wad_simulator (cargo, platform-agnostic)..."
	cd "$(REPO_ROOT)/tools/wad_simulator" && cargo build --release -p wad_simulator
	@test -f "$(SIM_WAD)" || (echo "error: WAD not found: $(SIM_WAD) (set SIM_WAD=...)" >&2; exit 1)
	@echo "Running wad_simulator on $(SIM_WAD)..."
	"$(REPO_ROOT)/tools/wad_simulator/target/release/wad_simulator" \
	  --wad "$(SIM_WAD)" \
	  $(if $(wildcard $(RAINBOW_TABLE)),--rainbow-table "$(RAINBOW_TABLE)",) \
	  $(if $(wildcard $(SIM_AUDIOS_DIR)),--audios-dir "$(SIM_AUDIOS_DIR)",) \
	  $(if $(SOURCE_WAD),--base-wad "$(SOURCE_WAD)" --base-wad-dir "$(dir $(SOURCE_WAD))",)

# Rosetta oracle: convert every Xbox base-game entry through the production
# converter and diff byte-for-byte against the PC vz.wad ground truth (keyed by
# block path + asset hash). Regression gate for the BE->LE converter.
# See .cursor/notes/rosetta_oracle_baseline.md.
ROSETTA_XBOX_WAD ?= $(REPO_ROOT)/game-files/xbox-vz.wad
ROSETTA_PC_WAD   ?= $(REPO_ROOT)/game-files/vz.wad
ROSETTA_JOBS     ?= 8
ROSETTA_TYPE     ?=

rosetta-oracle: build-ucfx-byteswap
	@test -f "$(ROSETTA_XBOX_WAD)" || (echo "error: xbox WAD not found at $(ROSETTA_XBOX_WAD) — set ROSETTA_XBOX_WAD=" >&2; exit 1)
	@test -f "$(ROSETTA_PC_WAD)" || (echo "error: PC WAD not found at $(ROSETTA_PC_WAD) — set ROSETTA_PC_WAD=" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/wad_be_le_oracle.py" \
	  --xbox-wad "$(ROSETTA_XBOX_WAD)" --pc-wad "$(ROSETTA_PC_WAD)" \
	  --converter rust --jobs $(ROSETTA_JOBS) \
	  $(if $(ROSETTA_TYPE),--type $(ROSETTA_TYPE),) \
	  --out-dir "$(OUTPUT)/_scratch/rosetta_baseline"

dlc-port: build-luac build-wad-crates
	@test -f "$(DLC_RAR)" || (echo "error: DLC RAR not found at $(DLC_RAR) — set DLC_RAR=path" >&2; exit 1)
	@test -n "$(SOURCE_WAD)" || (echo "error: set SOURCE_WAD=path/to/vz.wad (retail PC base WAD)" >&2; exit 1)
	@test -f "$(SOURCE_WAD)" || (echo "error: vz.wad not found at $(SOURCE_WAD)" >&2; exit 1)
	@mkdir -p "$(OUTPUT)/data/Audios"
	@"$(PYTHON)" "$(REPO_ROOT)/tools/dlc_port.py" \
	  --x360-rar "$(DLC_RAR)" \
	  --source-wad "$(SOURCE_WAD)" \
	  --no-hook \
	  $(if $(JOBS),--jobs $(JOBS),) \
	  $(DLC_PORT_FLAGS) \
	  --output "$(OUTPUT)/data/vz-patch.wad" \
	  --extract-audio "$(OUTPUT)/data/Audios"
	@echo ""
	@echo "Built DLC nohook vz-patch.wad."
	@echo "Deploy with: make dlc-asi-native OUTPUT=$(OUTPUT)"
	@echo "Mac gates: make dlc-phase0 verify-dlc-import-chain OUTPUT=$(OUTPUT) SOURCE_WAD=$(SOURCE_WAD)"

# Post-hoc trim: rebuild existing patch WAD with fewer blocks (no re-conversion needed).
trim-patch-wad:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: vz-patch.wad missing — run make dlc-port" >&2; exit 1)
	@test -n "$(SOURCE_WAD)" || (echo "error: set SOURCE_WAD=path/to/vz.wad" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/trim_patch_wad.py" \
	  --auto \
	  --base-wad "$(SOURCE_WAD)" \
	  --target-reduction 200 \
	  --input "$(OUTPUT)/data/vz-patch.wad" \
	  --output "$(OUTPUT)/data/vz-patch.wad" \
	  --verbose

# 2196 DLC asset blocks only — no scripts_vz bootstrap (boot baseline, not Row 13 success).
dlc-port-assets-only: build-wad-crates
	@test -f "$(DLC_RAR)" || (echo "error: DLC RAR not found at $(DLC_RAR)" >&2; exit 1)
	@test -n "$(SOURCE_WAD)" || (echo "error: set SOURCE_WAD=path/to/vz.wad" >&2; exit 1)
	@mkdir -p "$(OUTPUT)/data"
	@"$(PYTHON)" "$(REPO_ROOT)/tools/dlc_port.py" \
	  --x360-rar "$(DLC_RAR)" \
	  --source-wad "$(SOURCE_WAD)" \
	  --no-bootstrap \
	  --output "$(OUTPUT)/data/vz-patch-assets-only.wad"
	@echo "Built assets-only WAD (2196 blocks, no scripts_vz). Not Row 13 activation."

# Phase 0 regression report + import chain + stringdb forensic.
dlc-phase0:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: $(OUTPUT)/data/vz-patch.wad missing" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/dlc_phase0_baseline.py" \
	  --output-wad "$(OUTPUT)/data/vz-patch.wad" \
	  --fresh-wad "$(REPO_ROOT)/fresh-rebuilt/data/vz-patch.wad" \
	  --base-wad "$(SOURCE_WAD)"

verify-dlc-import-chain:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: vz-patch.wad missing" >&2; exit 1)
	@test -f "$(SOURCE_WAD)" || (echo "error: set SOURCE_WAD=game-files/vz.wad" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/verify_dlc_import_chain.py" \
	  --base-wad "$(SOURCE_WAD)" \
	  --patch-wad "$(OUTPUT)/data/vz-patch.wad"

inventory-dlc-patch:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: vz-patch.wad missing" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/inventory_dlc_patch.py" \
	  --wad "$(OUTPUT)/data/vz-patch.wad" \
	  --json "$(REPO_ROOT)/analysis/cross_platform/dlc_patch_inventory.json"

scan-patch-placements:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: vz-patch.wad missing — run make dlc-port" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/scan_patch_placements.py" \
	  --wad "$(OUTPUT)/data/vz-patch.wad" --fail-on-violations

bisect-patch-wad:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: vz-patch.wad missing" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/bisect_patch_wad.py" \
	  --wad "$(OUTPUT)/data/vz-patch.wad"

# One-shot fix if bootstrap used ASET type_id=0 (breaks import('dlc01') on PC).
fix-dlc01-aset:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: $(OUTPUT)/data/vz-patch.wad not found" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/fix_dlc01_aset_type.py" --wad "$(OUTPUT)/data/vz-patch.wad"
	@"$(PYTHON)" "$(REPO_ROOT)/tools/fix_patch_script_aset_dupes.py" --wad "$(OUTPUT)/data/vz-patch.wad"

fix-patch-script-aset:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: $(OUTPUT)/data/vz-patch.wad not found" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/fix_patch_script_aset_dupes.py" --wad "$(OUTPUT)/data/vz-patch.wad"

verify-patch-dlc01: verify-patch-dlc

all:
	@test -n "$(ZIP)" || (echo "error: set ZIP, e.g. make all ZIP=./Mercenaries\\ 2\\ World\\ in\\ Flames.zip OUTPUT=./output" >&2; exit 1)
	$(MAKE) extract-all ZIP="$(ZIP)" OUTPUT="$(OUTPUT)"
	$(MAKE) extract-saves OUTPUT="$(OUTPUT)"
	$(MAKE) extract-audio OUTPUT="$(OUTPUT)"
	$(MAKE) extract-video OUTPUT="$(OUTPUT)"
	$(MAKE) extract-placements OUTPUT="$(OUTPUT)"
	$(MAKE) ue5-bundle OUTPUT="$(OUTPUT)"
	$(MAKE) regen-maracaibo-glbs OUTPUT="$(OUTPUT)"

viewer:
	@test -d "$(REPO_ROOT)/viewer" && test -f "$(REPO_ROOT)/viewer/package.json" || (echo "No viewer/ app" >&2; exit 1)
	cd "$(REPO_ROOT)/viewer" && npm install && npm run dev

preview-world-cells:
	@test -d "$(REPO_ROOT)/viewer" && test -f "$(REPO_ROOT)/viewer/package.json" || (echo "No viewer/ app" >&2; exit 1)
	cd "$(REPO_ROOT)/viewer" && npm install && npm run dev -- --open /world-cells

# Placement / region preview (serves output/placements/*.json via MERCS2_PLACEMENTS_ROOT).
preview-placements:
	@test -d "$(REPO_ROOT)/viewer" && test -f "$(REPO_ROOT)/viewer/package.json" || (echo "No viewer/ app" >&2; exit 1)
	cd "$(REPO_ROOT)/viewer" && npm install && MERCS2_PLACEMENTS_ROOT="$(abspath $(OUTPUT))/placements" npm run dev -- --open /placement-preview.html

preview-placement-bbox:
	@test -d "$(REPO_ROOT)/viewer" && test -f "$(REPO_ROOT)/viewer/package.json" || (echo "No viewer/ app" >&2; exit 1)
	cd "$(REPO_ROOT)/viewer" && npm install && MERCS2_PLACEMENTS_ROOT="$(abspath $(OUTPUT))/placements" npm run dev -- --open /placement-bbox.html

# ---- Docker / Webapp ----

docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f

docker-reset:
	docker compose down -v
	docker compose up -d

# Run Alembic migrations inside the API container.
db-migrate:
	docker compose exec api alembic upgrade head

# Run the ingest CLI inside the API container (output/ is mounted at /data/output).
db-ingest:
	docker compose exec api python -m app.ingest.cli --output /data/output

# Start the FastAPI backend (without Docker, needs running Postgres + local deps).
api:
	cd "$(REPO_ROOT)/webapp" && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Full webapp stack: start Docker (db + api), then viewer frontend.
webapp: docker-up
	@echo "Waiting for API to be ready…"
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		curl -sf http://localhost:8000/api/health > /dev/null 2>&1 && break; \
		sleep 2; \
	done
	cd "$(REPO_ROOT)/viewer" && npm install && npm run dev

# ---- Windows Test Environment (dockur/windows) ----
# Runs Windows 7 in a Docker container for game testing.
# Requires: Linux host with KVM, patched files in output/ (crack-game, dlc-port).

test-windows:
	@echo "Starting Windows 7 test environment..."
	@echo ""
	@test -d "$(OUTPUT)/patched" && test -f "$(OUTPUT)/patched/Mercenaries2.exe" \
	  || echo "WARNING: No patched EXE found at $(OUTPUT)/patched/Mercenaries2.exe"
	@test -f "$(OUTPUT)/data/vz-patch.wad" \
	  || echo "WARNING: No vz-patch.wad found at $(OUTPUT)/data/vz-patch.wad"
	@echo ""
	docker compose -f docker-compose.test-windows.yml up -d
	@echo ""
	@echo "============================================================"
	@echo "  Windows 7 test environment starting up."
	@echo ""
	@echo "  Web viewer (noVNC): http://localhost:8006"
	@echo "  RDP:                localhost:3389  (mercs2/mercs2)"
	@echo ""
	@echo "  Windows installation takes ~5-10 minutes on first run."
	@echo "  install.bat runs automatically after setup completes."
	@echo ""
	@echo "  Game files:  C:\\Mercs2\\"
	@echo "  Shared:      C:\\Shared\\ (= host ./output/)"
	@echo "============================================================"

test-windows-down:
	docker compose -f docker-compose.test-windows.yml down

test-windows-logs:
	docker compose -f docker-compose.test-windows.yml logs -f

# ---- Lua binding reports (needs cracked EXE) ----

LUA_BIND_EXE ?= $(firstword $(wildcard game-files/cracked-parts/Crack/Mercenaries2.exe) $(wildcard $(OUTPUT)/patched/Mercenaries2.exe))

debug-binding-report: venv
	@test -n "$(LUA_BIND_EXE)" || (echo "error: place Mercenaries2.exe under game-files/cracked-parts/Crack/ or $(OUTPUT)/patched/" >&2; exit 1)
	$(PYTHON) tools/debug_binding_report.py --exe "$(LUA_BIND_EXE)"
	$(PYTHON) tools/dump_lua_bindings.py --exe "$(LUA_BIND_EXE)" \
	  --json "$(OUTPUT)/lua_bindings_primary.json"

dump-lua-bindings: venv
	@test -n "$(LUA_BIND_EXE)" || (echo "error: set LUA_BIND_EXE or place EXE in game-files/cracked-parts/Crack/" >&2; exit 1)
	$(PYTHON) tools/dump_lua_bindings.py --exe "$(LUA_BIND_EXE)" \
	  --json "$(OUTPUT)/lua_bindings_dump.json" --csv "$(OUTPUT)/lua_bindings_dump.csv"

# ---- DLC PC activation gates (G1/G2 — run on game PC or fresh-rebuilt WAD) ----

REFERENCE_WAD ?= game-files/vz.wad

verify-patch-vz:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: $(OUTPUT)/data/vz-patch.wad not found" >&2; exit 1)
	@test -f "$(REFERENCE_WAD)" || (echo "error: $(REFERENCE_WAD) not found" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/verify_patch_vz.py" --wad "$(OUTPUT)/data/vz-patch.wad" --reference-wad "$(REFERENCE_WAD)"

verify-patch-dlc:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || test -f "$(REPO_ROOT)/fresh-rebuilt/data/vz-patch.wad" || \
	  (echo "error: no vz-patch.wad under OUTPUT or fresh-rebuilt" >&2; exit 1)
	@WAD="$(OUTPUT)/data/vz-patch.wad"; \
	  test -f "$$WAD" || WAD="$(REPO_ROOT)/fresh-rebuilt/data/vz-patch.wad"; \
	  "$(PYTHON)" "$(REPO_ROOT)/tools/verify_patch_dlc01.py" --wad "$$WAD"

verify-patch-dlc-hook:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || test -f "fresh-rebuilt/data/vz-patch.wad" || \
	  (echo "error: no vz-patch.wad under OUTPUT or fresh-rebuilt" >&2; exit 1)
	@WAD="$(OUTPUT)/data/vz-patch.wad"; \
	  test -f "$$WAD" || WAD="fresh-rebuilt/data/vz-patch.wad"; \
	  $(PYTHON) tools/verify_patch_dlc_hook.py --wad "$$WAD"

# G6 — FFCS structure + 258-byte PTHS trailer (patch_wad_format.md)
WAD_VARIANT ?= any
WAD_EXPECT_BLOCKS ?=

verify-patch-wad-structure:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: $(OUTPUT)/data/vz-patch.wad not found" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/verify_patch_wad_structure.py" \
	  --wad "$(OUTPUT)/data/vz-patch.wad" \
	  --variant "$(WAD_VARIANT)" \
	  $(if $(WAD_EXPECT_BLOCKS),--expect-blocks $(WAD_EXPECT_BLOCKS),)

verify-dlc-endian:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: $(OUTPUT)/data/vz-patch.wad not found" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/verify_ucfx_endian.py" \
	  --wad "$(OUTPUT)/data/vz-patch.wad" \
	  --fail-on-issues

# DLC audio gate: manifest + wavebank structure + wad_simulator audio-only
audio-verify-dlc:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: vz-patch.wad missing — run make dlc-port" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/audio_verify_dlc.py" \
	  --output "$(OUTPUT)" \
	  $(if $(SOURCE_WAD),--base-wad "$(SOURCE_WAD)",)

# PS3 EBOOT PPC analysis (requires brew install ghidra; decrypt EBOOT first)
ghidra-ps3-eboot:
	@chmod +x "$(REPO_ROOT)/scripts/ghidra_analyze_ps3_eboot.sh"
	@"$(REPO_ROOT)/scripts/ghidra_analyze_ps3_eboot.sh"

r2-ps3-vz-xrefs:
	@chmod +x "$(REPO_ROOT)/scripts/r2_vz_wad_xrefs.sh"
	@"$(REPO_ROOT)/scripts/r2_vz_wad_xrefs.sh"

# ---- DLC Enable ASI Plugin (Native MinGW build) ----

dlc-asi-native:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/dlc_enable_asi" mingw
	@cp "$(REPO_ROOT)/tools/dlc_enable_asi/dlc_enable.asi" "$(OUTPUT)/scripts/dlc_enable.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/dlc_enable.asi to <game>/scripts/"
	@echo "Verify: log Build: VZ_LOAD; see docs/dlc_pc_activation_checklist.md"

winsock-redirect-asi:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/winsock_redirect_asi" mingw
	@cp "$(REPO_ROOT)/tools/winsock_redirect_asi/winsock_redirect.asi" "$(OUTPUT)/scripts/winsock_redirect.asi"
	@test -f "$(OUTPUT)/scripts/winsock_redirect.ini" || cp "$(REPO_ROOT)/tools/winsock_redirect_asi/winsock_redirect.ini" "$(OUTPUT)/scripts/winsock_redirect.ini"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/winsock_redirect.asi (+ .ini) to <game>/scripts/"
	@echo "Set modkit_ip in winsock_redirect.ini, then run: docker compose up coopserver"
	@echo "See docs/coop_capture_server.md"

dlc-asi-native-nobootstrap:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/dlc_enable_asi" mingw-nobootstrap
	@cp "$(REPO_ROOT)/tools/dlc_enable_asi/dlc_enable.asi" "$(OUTPUT)/scripts/dlc_enable.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/dlc_enable.asi to <game>/scripts/"
	@echo "Bisect: REG_PATCH+NET, no bootstrap — expect Flags REG_PATCH=1 NET=1 VZ_LOAD=0"

dlc-asi-native-minimal:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/dlc_enable_asi" mingw-minimal
	@cp "$(REPO_ROOT)/tools/dlc_enable_asi/dlc_enable.asi" "$(OUTPUT)/scripts/dlc_enable.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/dlc_enable.asi to <game>/scripts/"
	@echo "Bisect: NET hooks only — expect Flags MINIMAL=1 REG_PATCH=0 NET=1"

dlc-asi-native-nohooks:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/dlc_enable_asi" mingw-nohooks
	@cp "$(REPO_ROOT)/tools/dlc_enable_asi/dlc_enable.asi" "$(OUTPUT)/scripts/dlc_enable.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/dlc_enable.asi to <game>/scripts/"
	@echo "Bisect: zero hooks — expect Build: NO_HOOKS; compare vs removing ASI entirely"

dlc-asi-native-no-crash-patch:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/dlc_enable_asi" mingw-no-crash-patch
	@cp "$(REPO_ROOT)/tools/dlc_enable_asi/dlc_enable.asi" "$(OUTPUT)/scripts/dlc_enable.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/dlc_enable.asi to <game>/scripts/"
	@echo "Bisect: VZ bootstrap without CRASH_PATCH at 0x005AE372"

dlc-asi-native-debug:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/dlc_enable_asi" mingw-debug
	@cp "$(REPO_ROOT)/tools/dlc_enable_asi/dlc_enable.asi" "$(OUTPUT)/scripts/dlc_enable.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/dlc_enable.asi to <game>/scripts/"
	@echo "NOTE: This build shows a MessageBox on load for diagnostics."

# ---- Lua binding enumeration ASI (runtime + static .rdata inventory) ----

lua-enum-asi:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/lua_enum_asi" mingw
	@cp "$(REPO_ROOT)/tools/lua_enum_asi/lua_enum.asi" "$(OUTPUT)/scripts/lua_enum.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/lua_enum.asi to <game>/scripts/"
	@echo "After running the game ~10s, collect scripts/lua_bindings_runtime.{txt,json}"

lua-enum-asi-debug:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/lua_enum_asi" mingw-debug
	@cp "$(REPO_ROOT)/tools/lua_enum_asi/lua_enum.asi" "$(OUTPUT)/scripts/lua_enum.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/lua_enum.asi to <game>/scripts/"

# ---- Runtime research probe ASI (standalone — not dlc_enable) ----

mercs2-probe:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/mercs2_probe" mingw
	@cp "$(REPO_ROOT)/tools/mercs2_probe/mercs2_probe.asi" "$(OUTPUT)/scripts/mercs2_probe.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/mercs2_probe.asi to <game>/scripts/"
	@echo "After ~15s in-game, collect scripts/probe_results/*.json"
	@echo "Validate: make validate-probe-results PROBE_DIR=<path/to/probe_results>"

mercs2-probe-debug:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/mercs2_probe" mingw-debug
	@cp "$(REPO_ROOT)/tools/mercs2_probe/mercs2_probe.asi" "$(OUTPUT)/scripts/mercs2_probe.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/mercs2_probe.asi to <game>/scripts/"

# ---- Asset-miss probe ASI (file-open failure tracer — standalone) ----

asset-miss-probe:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/asset_miss_probe" mingw
	@cp "$(REPO_ROOT)/tools/asset_miss_probe/asset_miss_probe.asi" "$(OUTPUT)/scripts/asset_miss_probe.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/asset_miss_probe.asi to <game>/scripts/"
	@echo "Reproduce the GlobalEnter spin, then read pmc_blackbox.log (or"
	@echo "asset_miss_probe.log) for 'MISS ... path=...' lines."

asset-miss-probe-debug:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/asset_miss_probe" mingw-debug
	@cp "$(REPO_ROOT)/tools/asset_miss_probe/asset_miss_probe.asi" "$(OUTPUT)/scripts/asset_miss_probe.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/asset_miss_probe.asi to <game>/scripts/"

# PROBE_DIR — directory with probe_results/*.json from a game run (default: OUTPUT/scripts/probe_results)
PROBE_DIR ?= $(OUTPUT)/scripts/probe_results

validate-probe-results:
	$(PYTHON) "$(REPO_ROOT)/tools/validate_probe_results.py" --probe-dir "$(PROBE_DIR)"

# ---- PMC Blackbox (SecuROM spoof + debug console + ASI loader) ----
# Output: pmc_bb.dll — game's import table must reference this name.

# There is now ONE build. The engine compat DETOURS (compat_hooks.c / MinHook)
# were removed — they reintroduced the early-init 0x45b1d2 crash. pmc_bb applies
# only the in-memory compat PATCHES (compat_patches.gen.c via VirtualProtect:
# anim-table 1024->4096 expansion + DLC guards) — no exe edit, no engine hooks.
# `make pmc-blackbox-nopatch` builds a control DLL with the patches compiled out
# (-DPMC_NO_RUNTIME_PATCH) to A/B whether a runtime patch is responsible.
pmc-blackbox:
	$(MAKE) -C "$(REPO_ROOT)/tools/pmc_blackbox" mingw
	@mkdir -p "$(OUTPUT)/dlls"
	@cp "$(REPO_ROOT)/tools/pmc_blackbox/pmc_bb.dll" "$(OUTPUT)/dlls/pmc_bb.dll"
	@echo ""
	@echo "Built pmc_bb.dll (compat PATCHES in-memory, no engine hooks)."
	@echo "Install: copy $(OUTPUT)/dlls/pmc_bb.dll to <game>/pmc_bb.dll"
	@echo "         (game import table must reference pmc_bb.dll)"

pmc-blackbox-nopatch:
	$(MAKE) -C "$(REPO_ROOT)/tools/pmc_blackbox" mingw EXTRA_CFLAGS=-DPMC_NO_RUNTIME_PATCH
	@mkdir -p "$(OUTPUT)/dlls"
	@cp "$(REPO_ROOT)/tools/pmc_blackbox/pmc_bb.dll" "$(OUTPUT)/dlls/pmc_bb.dll"
	@echo ""
	@echo "Built CONTROL pmc_bb.dll (compat patches DISABLED, -DPMC_NO_RUNTIME_PATCH)."
	@echo "Install: copy $(OUTPUT)/dlls/pmc_bb.dll to <game>/pmc_bb.dll"

# ---- Ghidra Annotation (Mercs 1 → Mercs 2 cross-reference) ----

ghidra-annotate-preanalysis:
	@"$(PYTHON)" "$(REPO_ROOT)/scripts/ghidra_mercs2_preanalysis.py" \
	  --output "$(REPO_ROOT)/scripts/mercs2_annotations.json"
	@echo ""
	@echo "Annotation database: scripts/mercs2_annotations.json"
	@echo "Next: load Mercs 2 EXE in Ghidra, run scripts/ghidra_mercs2_annotate.py"

# ---- Audio Endian Verification (packed-type proof) ----

verify-audio-field-map:
	@"$(PYTHON)" "$(REPO_ROOT)/tools/verify_audio_field_map.py" \
	  --pc-wad "$(REPO_ROOT)/game-files/pc-game-vz.wad" \
	  --xbox-wad "$(REPO_ROOT)/game-files/xbox-vz.wad" \
	  --output "$(REPO_ROOT)/analysis/audio_endian/audio_field_spec.json" \
	  --extract-goldens --goldens-dir "$(REPO_ROOT)/tools/testdata/audio_endian" \
	  --strict

verify-audio-converter:
	@"$(PYTHON)" "$(REPO_ROOT)/tools/verify_audio_converter.py" \
	  --pc-wad "$(REPO_ROOT)/game-files/pc-game-vz.wad" \
	  --xbox-wad "$(REPO_ROOT)/game-files/xbox-vz.wad" \
	  --spec "$(REPO_ROOT)/analysis/audio_endian/audio_field_spec.json"

verify-audio-converter-goldens:
	@"$(PYTHON)" "$(REPO_ROOT)/tools/verify_audio_converter.py" \
	  --goldens-only \
	  --goldens-dir "$(REPO_ROOT)/tools/testdata/audio_endian" \
	  --spec "$(REPO_ROOT)/analysis/audio_endian/audio_field_spec.json"

verify-audio-endian: verify-audio-field-map verify-audio-converter

# ---- Name-string extraction → pandemic_hash rainbow table (pure Python; Mac/Linux/Windows) ----
# Harvest DLC/console asset name strings and fold genuinely-new pandemic_hash_m2
# hashes into tools/rainbow_table.json (gitignored, regenerable). Console export
# also writes per-WAD <stem>.{blocks,strings,unique-strings}.txt into game-files/.
#
#   make harvest-dlc-strings  OUTPUT=./output     # DLC patch WAD  → rainbow table
#   make export-console-strings                   # Xbox 360 + PS3 → game-files/*.txt + table
#   make extract-strings      OUTPUT=./output     # both of the above
#
# Override inputs: PATCH_WAD=… XBOX_WAD=… PS3_WAD=…  ·  skip table writes: STRINGS_MERGE=0
PATCH_WAD ?= $(OUTPUT)/data/vz-patch.wad
XBOX_WAD ?= $(REPO_ROOT)/game-files/xbox-vz.wad
PS3_WAD ?= $(REPO_ROOT)/game-files/ps3-VZ.WAD
STRINGS_MERGE ?= 1
ifeq ($(STRINGS_MERGE),1)
  STRINGS_MERGE_FLAG := --merge
else
  STRINGS_MERGE_FLAG :=
endif

harvest-dlc-strings:
	@WAD="$(PATCH_WAD)"; \
	  if [ ! -f "$$WAD" ] && [ -f "$(REPO_ROOT)/game-files/vz-patch.wad" ]; then WAD="$(REPO_ROOT)/game-files/vz-patch.wad"; fi; \
	  test -f "$$WAD" || (echo "error: patch WAD not found ($(PATCH_WAD) or game-files/vz-patch.wad) — set PATCH_WAD= or run make dlc-port" >&2; exit 1); \
	  echo "Harvesting DLC strings from $$WAD"; \
	  "$(PYTHON)" "$(REPO_ROOT)/tools/harvest_dlc_strings.py" --wad "$$WAD" --quality $(STRINGS_MERGE_FLAG)

export-console-strings:
	@test -f "$(XBOX_WAD)" || test -f "$(PS3_WAD)" || \
	  (echo "error: neither XBOX_WAD ($(XBOX_WAD)) nor PS3_WAD ($(PS3_WAD)) found — set XBOX_WAD=/PS3_WAD=" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/export_platform_strings.py" \
	  $(if $(wildcard $(XBOX_WAD)),--wad "$(XBOX_WAD)",) \
	  $(if $(wildcard $(PS3_WAD)),--wad "$(PS3_WAD)",) \
	  --out-dir "$(REPO_ROOT)/game-files" \
	  $(STRINGS_MERGE_FLAG)

extract-strings: harvest-dlc-strings export-console-strings

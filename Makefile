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

.PHONY: default help clean venv extract-all batch-all build-texture-index review-all review-textures-only all extract-saves extract-audio extract-video extract-iso variants export-ue5 ue5-bundle filter-maracaibo regen-maracaibo-glbs regen-all-glbs category-samples sample-bundle full-pipeline viewer preview-placements preview-placement-bbox animations animations-validation extract-placements build-vz-act-manifest filter-maracaibo-placements build-pmc-base-set build-c3-cell-manifest extract-demo-ffcs filter-pmc-base regen-pmc-glbs filter-pool-200m regen-pool-200m-glbs extract-terrain extract-zone-props dlc-port fix-dlc01-aset dlc-bootstrap dlc-bootstrap-merge crack-game dlc-asi-native dlc-asi-native-bootstrap dlc-asi-native-bootstrap-deferred dlc-asi-native-debug lua-enum-asi lua-enum-asi-debug pmc-blackbox cruise-dll test-windows test-windows-down test-windows-logs

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

STAGE2_SEQUENTIAL ?= 0
STAGE2_JOBS ?=

# Passed through to stage2_review_extract.sh / stage2_parallel.sh (override per invocation).
STAGE2_SKIP_UCFX ?= 0
STAGE2_SKIP_MESH ?= 0
STAGE2_SKIP_TEX ?= 0
STAGE2_SKIP_HAVOK ?= 0
STAGE2_DIALOG ?= 1
STAGE2_GLTF ?= 1
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
	@echo "                      build-texture-index then re-run stage 2 (TEXTURE_INDEX set; STAGE2_JOBS=N optional)"
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
	@echo "                      clean + extract-all + saves/audio/video + ue5-bundle + regen-maracaibo-glbs"
	@echo ""
	@echo "  Resume (after a failed run — do not use full-pipeline; it runs clean):"
	@echo "          make review-all OUTPUT=./output   # re-run stage 2 (builds texture index first)"
	@echo "          # Faster if only glTF failed: STAGE2_SKIP_UCFX=1 STAGE2_SKIP_MESH=1 STAGE2_SKIP_TEX=1 \\"
	@echo "          #   STAGE2_SKIP_HAVOK=1 STAGE2_DIALOG=0 make review-all OUTPUT=./output"
	@echo "          make extract-saves extract-audio extract-video ue5-bundle OUTPUT=./output   # if not done yet"
	@echo "  make preview-placements OUTPUT=./output   # viewer dev server + placement map (MERCS2_PLACEMENTS_ROOT)"
	@echo "  make preview-placement-bbox OUTPUT=./output  # bbox regions + rotation override QA page"
	@echo "  make viewer       npm install + dev server (asset viewer)"
	@echo "  make extract-iso  Prints ISO/locale extraction hints (mount ISO yourself)"
	@echo "  make clean OUTPUT=./output"
	@echo "  make all           extract-all + saves/audio/video + ue5-bundle + regen-maracaibo-glbs (needs ZIP)"
	@echo ""
	@echo "  make test-windows      Start Windows 7 Docker container (dockur/windows) for game testing"
	@echo "  make test-windows-down Stop the Windows test container"
	@echo "  make test-windows-logs Follow container logs"
	@echo ""
	@echo "Variables: ZIP OUTPUT FORCE_UNZIP=1 VARIANT_PATH EXTRACT_JOBS (1=per-block sges; else bulk)"
	@echo "            PYTHON (default: \`./.venv/bin/python\` if present, else \`python3\` — run \`make venv\` for pygltflib)"
	@echo "            STAGE2_SEQUENTIAL=1 STAGE2_JOBS=N STAGE2_SKIP_* (stage 2; default uses all CPUs up to 48)"
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
	@$(MAKE) review-all OUTPUT="$(OUTPUT)"

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
	  STAGE2_SKIP_UCFX="$(STAGE2_SKIP_UCFX)" STAGE2_SKIP_MESH="$(STAGE2_SKIP_MESH)" STAGE2_SKIP_TEX="$(STAGE2_SKIP_TEX)" STAGE2_SKIP_HAVOK="$(STAGE2_SKIP_HAVOK)" \
	  STAGE2_DIALOG="$(STAGE2_DIALOG)" STAGE2_GLTF="$(STAGE2_GLTF)" TEXTURE_PNG="$(TEXTURE_PNG)" \
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
	@echo "Placement extraction complete → $(OUTPUT)/placements/"

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
	$(MAKE) extract-all ZIP="$(ZIP)" OUTPUT="$(OUTPUT)"
	$(MAKE) extract-saves OUTPUT="$(OUTPUT)"
	$(MAKE) extract-audio OUTPUT="$(OUTPUT)"
	$(MAKE) extract-video OUTPUT="$(OUTPUT)"
	$(MAKE) extract-placements OUTPUT="$(OUTPUT)"
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
	@cp "$(REPO_ROOT)/dlls/pmc_bb.dll" "$(OUTPUT)/patched/pmc_bb.dll"
	@echo ""
	@echo "Ready: $(OUTPUT)/patched/"
	@echo "  Mercenaries2.exe   (patched, imports pmc_bb.dll)"
	@echo "  pmc_bb.dll   (SecuROM spoof + debug console + ASI loader)"

# ---- Xbox 360 DLC Port ----
# Produces a complete vz-patch.wad with DLC blocks + Lua bootstrap.
# Set SOURCE_WAD to the retail vz.wad for integrated bootstrap injection.
# Without SOURCE_WAD, produces DLC blocks only (no bootstrap).

DLC_RAR ?= Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar

dlc-port:
	@test -f "$(DLC_RAR)" || (echo "error: DLC RAR not found at $(DLC_RAR) — set DLC_RAR=path" >&2; exit 1)
	@mkdir -p "$(OUTPUT)/data/Audios"
	@"$(PYTHON)" "$(REPO_ROOT)/tools/dlc_port.py" \
	  --x360-rar "$(DLC_RAR)" \
	  $(if $(SOURCE_WAD),--source-wad "$(SOURCE_WAD)") \
	  --output "$(OUTPUT)/data/vz-patch.wad" \
	  --extract-audio "$(OUTPUT)/data/Audios"

# One-shot fix if bootstrap used ASET type_id=0 (breaks import('dlc01') on PC).
fix-dlc01-aset:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: $(OUTPUT)/data/vz-patch.wad not found" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/fix_dlc01_aset_type.py" --wad "$(OUTPUT)/data/vz-patch.wad"

verify-patch-dlc01:
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: $(OUTPUT)/data/vz-patch.wad not found" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/verify_patch_dlc01.py" --wad "$(OUTPUT)/data/vz-patch.wad"

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

# ---- DLC Bootstrap Injection (standalone/legacy) ----
# PREFERRED: use `make dlc-port DLC_RAR=... SOURCE_WAD=...` which integrates
# the bootstrap directly into the DLC porting pipeline (single command).
#
# These targets remain as alternatives for building bootstrap-only WADs or
# merging into pre-existing patch WADs without re-running the full DLC port.

SOURCE_WAD ?=

dlc-bootstrap:
	@test -n "$(SOURCE_WAD)" || (echo "error: set SOURCE_WAD=path/to/vz.wad" >&2; exit 1)
	@test -f "$(SOURCE_WAD)" || (echo "error: vz.wad not found at $(SOURCE_WAD)" >&2; exit 1)
	@mkdir -p "$(OUTPUT)/data"
	@"$(PYTHON)" "$(REPO_ROOT)/tools/build_patch_wad.py" \
	  --inject-dlc-bootstrap \
	  --source-wad "$(SOURCE_WAD)" \
	  --output "$(OUTPUT)/data/vz-patch.wad"

dlc-bootstrap-merge:
	@test -n "$(SOURCE_WAD)" || (echo "error: set SOURCE_WAD=path/to/vz.wad" >&2; exit 1)
	@test -f "$(SOURCE_WAD)" || (echo "error: vz.wad not found at $(SOURCE_WAD)" >&2; exit 1)
	@test -f "$(OUTPUT)/data/vz-patch.wad" || (echo "error: existing vz-patch.wad not found (run dlc-port first)" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/build_patch_wad.py" \
	  --inject-dlc-bootstrap-merge \
	  --source-wad "$(SOURCE_WAD)" \
	  --merge-from "$(OUTPUT)/data/vz-patch.wad" \
	  --output "$(OUTPUT)/data/vz-patch.wad"

# ---- Lua binding reports (needs cracked EXE) ----

LUA_BIND_EXE ?= $(firstword $(wildcard game-files/cracked-parts/Crack/Mercenaries2.exe) $(wildcard $(OUTPUT)/patched/Mercenaries2.exe))

debug-binding-report: venv
	@test -n "$(LUA_BIND_EXE)" || (echo "error: place Mercenaries2.exe under game-files/cracked-parts/Crack/ or $(OUTPUT)/patched/" >&2; exit 1)
	$(PYTHON) tools/debug_binding_report.py --exe "$(LUA_BIND_EXE)"
	$(PYTHON) tools/dump_lua_bindings.py --exe "$(LUA_BIND_EXE)" --no-heuristic \
	  --json "$(OUTPUT)/lua_bindings_primary.json"

dump-lua-bindings: venv
	@test -n "$(LUA_BIND_EXE)" || (echo "error: set LUA_BIND_EXE or place EXE in game-files/cracked-parts/Crack/" >&2; exit 1)
	$(PYTHON) tools/dump_lua_bindings.py --exe "$(LUA_BIND_EXE)" \
	  --json "$(OUTPUT)/lua_bindings_dump.json" --csv "$(OUTPUT)/lua_bindings_dump.csv"

# ---- DLC Enable ASI Plugin (Native MinGW build) ----

dlc-asi-native:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/dlc_enable_asi" mingw
	@cp "$(REPO_ROOT)/tools/dlc_enable_asi/dlc_enable.asi" "$(OUTPUT)/scripts/dlc_enable.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/dlc_enable.asi to <game>/scripts/"
	@echo "Verify: file size ~19456 bytes; log must show VZ_LOAD=1 and Build: ... bootstrap=ON"

dlc-asi-native-nobootstrap:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/dlc_enable_asi" mingw-nobootstrap
	@cp "$(REPO_ROOT)/tools/dlc_enable_asi/dlc_enable.asi" "$(OUTPUT)/scripts/dlc_enable.asi"
	@echo ""
	@echo "Install: logging/net only — no import(dlc01) (VZ_LOAD=0)"

dlc-asi-native-bootstrap:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/dlc_enable_asi" mingw-bootstrap
	@cp "$(REPO_ROOT)/tools/dlc_enable_asi/dlc_enable.asi" "$(OUTPUT)/scripts/dlc_enable.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/dlc_enable.asi to <game>/scripts/"
	@echo "Expect log: Flags: ... VZ_LOAD=1 ... then import(dlc01) at vz level load"

dlc-asi-native-bootstrap-deferred:
	@mkdir -p "$(OUTPUT)/scripts"
	$(MAKE) -C "$(REPO_ROOT)/tools/dlc_enable_asi" mingw-bootstrap-deferred
	@cp "$(REPO_ROOT)/tools/dlc_enable_asi/dlc_enable.asi" "$(OUTPUT)/scripts/dlc_enable.asi"
	@echo ""
	@echo "Install: copy $(OUTPUT)/scripts/dlc_enable.asi to <game>/scripts/"

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

# ---- PMC Blackbox (SecuROM spoof + debug console + ASI loader) ----
# Output: pmc_bb.dll — game's import table must reference this name.

pmc-blackbox:
	$(MAKE) -C "$(REPO_ROOT)/tools/pmc_blackbox" mingw
	@mkdir -p "$(REPO_ROOT)/dlls"
	@cp "$(REPO_ROOT)/tools/pmc_blackbox/pmc_bb.dll" "$(REPO_ROOT)/dlls/pmc_bb.dll"
	@echo ""
	@echo "Install: copy dlls/pmc_bb.dll to <game>/pmc_bb.dll"
	@echo "         (game import table must reference pmc_bb.dll)"

# Backward-compat alias
cruise-dll: pmc-blackbox

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

.PHONY: default help clean venv extract-all batch-all build-texture-index review-all review-textures-only all extract-saves extract-audio extract-video extract-iso variants export-ue5 ue5-bundle filter-maracaibo regen-maracaibo-glbs category-samples sample-bundle full-pipeline viewer animations animations-validation

REPO_ROOT := $(abspath .)
# Prefer repo virtualenv (pygltflib, etc.); override with `make PYTHON=python3 …`.
PYTHON := $(if $(wildcard $(REPO_ROOT)/.venv/bin/python),$(REPO_ROOT)/.venv/bin/python,python3)

ZIP ?=
ifndef OUTPUT
  OUTPUT := $(REPO_ROOT)/output
endif

# Uniform glTF root scale for ``make regen-maracaibo-glbs`` (default 1; UE applies glTF unit scaling).
GLB_ROOT_SCALE ?= 1

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
	@echo "  make animations OUTPUT=./output"
	@echo "                      Havok animgroup blocks → OUTPUT/animations/<slug>/<slug>.glb (tools/mercs2_anim_pipeline.py)"
	@echo "  make animations-validation OUTPUT=./output"
	@echo "                      Scan OUTPUT/animations and write OUTPUT/animations/_validation.json (no block reprocess)"
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
	@echo "  make viewer       npm install + dev server (asset viewer)"
	@echo "  make extract-iso  Prints ISO/locale extraction hints (mount ISO yourself)"
	@echo "  make clean OUTPUT=./output"
	@echo "  make all           extract-all + saves/audio/video + ue5-bundle + regen-maracaibo-glbs (needs ZIP)"
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

filter-maracaibo:
	@test -f "$(OUTPUT)/ue5_import/metadata/manifest.json" || \
	  (echo "error: missing $(OUTPUT)/ue5_import/metadata/manifest.json — run make ue5-bundle first" >&2; exit 1)
	@"$(PYTHON)" "$(REPO_ROOT)/tools/filter_maracaibo.py" \
	  --manifest "$(OUTPUT)/ue5_import/metadata/manifest.json" \
	  --review-root "$(OUTPUT)/extracted/review" \
	  --out "$(OUTPUT)/maracaibo_asset_list.json"

regen-maracaibo-glbs: filter-maracaibo
	@"$(PYTHON)" -c "import pygltflib" 2>/dev/null || (echo "error: pygltflib not available — run make venv" >&2; exit 1)
	@cd "$(REPO_ROOT)/tools" && "$(PYTHON)" "$(REPO_ROOT)/tools/regen_maracaibo_glbs.py" --pipeline-root "$(abspath $(OUTPUT))" --glb-root-scale "$(GLB_ROOT_SCALE)"

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
	$(MAKE) ue5-bundle OUTPUT="$(OUTPUT)"
	$(MAKE) regen-maracaibo-glbs OUTPUT="$(OUTPUT)"

all:
	@test -n "$(ZIP)" || (echo "error: set ZIP, e.g. make all ZIP=./Mercenaries\\ 2\\ World\\ in\\ Flames.zip OUTPUT=./output" >&2; exit 1)
	$(MAKE) extract-all ZIP="$(ZIP)" OUTPUT="$(OUTPUT)"
	$(MAKE) extract-saves OUTPUT="$(OUTPUT)"
	$(MAKE) extract-audio OUTPUT="$(OUTPUT)"
	$(MAKE) extract-video OUTPUT="$(OUTPUT)"
	$(MAKE) ue5-bundle OUTPUT="$(OUTPUT)"
	$(MAKE) regen-maracaibo-glbs OUTPUT="$(OUTPUT)"

viewer:
	@test -d "$(REPO_ROOT)/viewer" && test -f "$(REPO_ROOT)/viewer/package.json" || (echo "No viewer/ app" >&2; exit 1)
	cd "$(REPO_ROOT)/viewer" && npm install && npm run dev

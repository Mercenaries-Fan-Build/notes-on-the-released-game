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

.PHONY: default help clean extract-all batch-all review-all all extract-saves extract-audio extract-video extract-iso variants export-ue5 ue5-bundle full-pipeline viewer

REPO_ROOT := $(abspath .)

ZIP ?=
ifndef OUTPUT
  OUTPUT := $(REPO_ROOT)/output
endif

STAGE2_SEQUENTIAL ?= 0
STAGE2_JOBS ?=

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
	@echo "  make clean       Remove OUTPUT (default: $(OUTPUT))"
	@echo "  make extract-all ZIP=../Mercenaries 2 World in Flames.zip"
	@echo "                      (zip one directory up from this repo — adjust if yours lives elsewhere)"
	@echo "  make extract-all ZIP=./Mercenaries 2 World in Flames.zip OUTPUT=./output"
	@echo "                      Full pipeline: unzip → FFCS → batch decompress every .wad → stage 2 review"
	@echo "  make batch-all OUTPUT=./output"
	@echo "                      Batch-decompress every extracted/ffcs_* (existing ZIP/data assumed); writes extracted/batch_*"
	@echo "  make review-all OUTPUT=./output"
	@echo "                      Re-run stage 2 on existing batch_* (parallel workers; STAGE2_JOBS= N optional)"
	@echo "  make extract-saves OUTPUT=./output"
	@echo "                      Parse SaveGames/*.profile → OUTPUT/knowledge/saves.json"
	@echo "  make extract-audio OUTPUT=./output"
	@echo "                      Scan OUTPUT/data/Audios/*.pws → OUTPUT/extracted_audio/"
	@echo "  make extract-video OUTPUT=./output"
	@echo "                      BIK → MP4 via ffmpeg → OUTPUT/movies_mp4/"
	@echo "  make variants OUTPUT=./output"
	@echo "                      Build variant_registry.json from ffcs_shell paths.txt (after extract-all)"
	@echo "  make export-ue5 OUTPUT=./output"
	@echo "                      Bundle review assets → OUTPUT/ue5_import/ (+ manifest, import_assets.py stub)"
	@echo "  make ue5-bundle   variants + export-ue5 (after extract-all / review-all)"
	@echo "  make full-pipeline ZIP=... OUTPUT=./output"
	@echo "                      clean + extract-all + saves/audio/video + ue5-bundle (stage 2 parallel)"
	@echo ""
	@echo "  Resume (after a failed run — do not use full-pipeline; it runs clean):"
	@echo "          make review-all OUTPUT=./output   # re-run stage 2 (uses .venv/bin/python if it exists)"
	@echo "          # Faster if only glTF failed: STAGE2_SKIP_UCFX=1 STAGE2_SKIP_MESH=1 STAGE2_SKIP_TEX=1 \\"
	@echo "          #   STAGE2_SKIP_HAVOK=1 STAGE2_DIALOG=0 make review-all OUTPUT=./output"
	@echo "          make extract-saves extract-audio extract-video ue5-bundle OUTPUT=./output   # if not done yet"
	@echo "  make viewer       npm install + dev server (asset viewer)"
	@echo "  make extract-iso  Prints ISO/locale extraction hints (mount ISO yourself)"
	@echo "  make clean OUTPUT=./output"
	@echo "  make all           extract-all + extract-saves + extract-audio + extract-video + ue5-bundle (needs ZIP)"
	@echo ""
	@echo "Variables: ZIP OUTPUT FORCE_UNZIP=1 VARIANT_PATH STAGE2_SEQUENTIAL=1 STAGE2_JOBS=N (stage 2)"
	@echo "Current OUTPUT=$(OUTPUT)"

clean:
	@test -n "$(OUTPUT)" || (echo "error: OUTPUT is empty" >&2; exit 1)
	@test "$(OUTPUT)" != "/" || (echo "error: refusing to rm /" >&2; exit 1)
	@echo "Removing $(OUTPUT)"
	rm -rf "$(OUTPUT)"

# Clear env knobs that cap or skip work in scripts/extract_all_from_paths.sh (full run = no limits).
extract-all:
	@test -n "$(ZIP)" || (echo "error: set ZIP, e.g.  make extract-all ZIP=../Mercenaries 2 World in Flames.zip" >&2; exit 1)
	@test -f "$(ZIP)" || (echo "error: ZIP file not found: $(ZIP)" >&2; exit 1)
	bash -c 'unset MAX START VZ_MAX SKIP_EXISTING WITH_UCFX ALLOW_PARTIAL 2>/dev/null; \
	  exec "$(REPO_ROOT)/scripts/extract_from_zip.sh" --everything --out-dir "$(OUTPUT)" $(FORCE_UNZIP_FLAG) "$(ZIP)"'

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

review-all:
	@test -d "$(OUTPUT)" || (echo "error: OUTPUT directory missing: $(OUTPUT) (run extract-all first or set OUTPUT=./output)" >&2; exit 1)
	@env STAGE2_SEQUENTIAL="$(STAGE2_SEQUENTIAL)" STAGE2_JOBS="$(STAGE2_JOBS)" bash -c 'unset MAX START VZ_MAX SKIP_EXISTING WITH_UCFX ALLOW_PARTIAL 2>/dev/null; \
	  OUT="$$1"; \
	  if [ "$$STAGE2_SEQUENTIAL" = "1" ]; then \
	    exec "$(REPO_ROOT)/scripts/stage2_review_extract.sh" "$$OUT"; \
	  elif [ -n "$$STAGE2_JOBS" ]; then \
	    exec "$(REPO_ROOT)/scripts/stage2_parallel.sh" "$$OUT" "$$STAGE2_JOBS"; \
	  else \
	    exec "$(REPO_ROOT)/scripts/stage2_parallel.sh" "$$OUT"; \
	  fi' bash "$(OUTPUT)"

VARIANT_PATH ?=

variants:
	@set -e; \
	if [ -n "$(VARIANT_PATH)" ] && [ -f "$(VARIANT_PATH)" ]; then \
	  echo "variant_classifier: $(VARIANT_PATH)"; \
	  python3 "$(REPO_ROOT)/tools/variant_classifier.py" --paths "$(VARIANT_PATH)" --out "$(OUTPUT)/variant_registry.json"; \
	elif [ -f "$(OUTPUT)/extracted/ffcs_shell/paths.txt" ]; then \
	  echo "variant_classifier: $(OUTPUT)/extracted/ffcs_shell/paths.txt"; \
	  python3 "$(REPO_ROOT)/tools/variant_classifier.py" --paths "$(OUTPUT)/extracted/ffcs_shell/paths.txt" --out "$(OUTPUT)/variant_registry.json"; \
	else \
	  echo "Skipping variants: no paths.txt (set VARIANT_PATH= or run extract-all first)"; \
	fi

extract-saves:
	@mkdir -p "$(OUTPUT)/knowledge"
	bash -c 'shopt -s nullglob; profiles=("$(REPO_ROOT)/SaveGames"/*.profile); \
	  if [ $${#profiles[@]} -eq 0 ]; then echo "No SaveGames/*.profile — skipping"; exit 0; fi; \
	  python3 "$(REPO_ROOT)/tools/savefile_parser.py" "$${profiles[@]}" --out "$(OUTPUT)/knowledge/saves.json"'

extract-audio:
	@mkdir -p "$(OUTPUT)/extracted_audio"
	@bash -c 'if [ ! -d "$(OUTPUT)/data/Audios" ]; then echo "Note: $(OUTPUT)/data/Audios missing — unzip game data first (extract-all)"; exit 0; fi; \
	  set -e; shopt -s nullglob; \
	  for f in "$(OUTPUT)/data/Audios"/*.pws; do \
	    echo "pws_extractor: $$f"; \
	    python3 "$(REPO_ROOT)/tools/pws_extractor.py" "$$f" --out-dir "$(OUTPUT)/extracted_audio"; \
	  done'

extract-video:
	@mkdir -p "$(OUTPUT)/movies_mp4"
	@if [ ! -d "$(OUTPUT)/data/Movies" ]; then \
	  echo "Note: $(OUTPUT)/data/Movies missing — skipping"; exit 0; \
	fi
	@python3 "$(REPO_ROOT)/tools/bik_extractor.py" --movies-dir "$(OUTPUT)/data/Movies" --out-dir "$(OUTPUT)/movies_mp4"

extract-iso:
	@echo "Locale/audio from disc image (examples):"
	@echo "  macOS:  hdiutil attach \"$$ISO\" -mountpoint /Volumes/M2"
	@echo "  Then copy French.wad / Russian.wad or vo_stream.*.pws into OUTPUT/data and re-run extract-audio."
	@echo "  Set ISO to your .iso path when mounting."

export-ue5: variants
	@test -d "$(OUTPUT)" || (echo "error: OUTPUT missing: $(OUTPUT)" >&2; exit 1)
	@python3 "$(REPO_ROOT)/tools/ue5_export.py" --pipeline-root "$(OUTPUT)" --out "$(OUTPUT)/ue5_import"

ue5-bundle: export-ue5

full-pipeline:
	@test -n "$(ZIP)" || (echo "error: set ZIP for full-pipeline" >&2; exit 1)
	$(MAKE) clean OUTPUT="$(OUTPUT)"
	$(MAKE) extract-all ZIP="$(ZIP)" OUTPUT="$(OUTPUT)"
	$(MAKE) extract-saves OUTPUT="$(OUTPUT)"
	$(MAKE) extract-audio OUTPUT="$(OUTPUT)"
	$(MAKE) extract-video OUTPUT="$(OUTPUT)"
	$(MAKE) ue5-bundle OUTPUT="$(OUTPUT)"

all:
	@test -n "$(ZIP)" || (echo "error: set ZIP, e.g. make all ZIP=./Mercenaries\\ 2\\ World\\ in\\ Flames.zip OUTPUT=./output" >&2; exit 1)
	$(MAKE) extract-all ZIP="$(ZIP)" OUTPUT="$(OUTPUT)"
	$(MAKE) extract-saves OUTPUT="$(OUTPUT)"
	$(MAKE) extract-audio OUTPUT="$(OUTPUT)"
	$(MAKE) extract-video OUTPUT="$(OUTPUT)"
	$(MAKE) ue5-bundle OUTPUT="$(OUTPUT)"

viewer:
	@test -d "$(REPO_ROOT)/viewer" && test -f "$(REPO_ROOT)/viewer/package.json" || (echo "No viewer/ app" >&2; exit 1)
	cd "$(REPO_ROOT)/viewer" && npm install && npm run dev

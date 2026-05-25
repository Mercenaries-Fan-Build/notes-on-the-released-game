#!/usr/bin/env bash
#
# Interactive batch commit helper for mercenaries-game.
#
# Stages and commits changed files in logical groups, excluding:
#   - Lua source (.lua, Lua VM .c/.h/.o under lua51 dirs)
#   - Compiled Lua bytecode (.luac)
#   - Compressed archives (.tar.gz, .zip, .rar, .gz)
#   - Original game binaries (.wad, .elf, .bin)
#   - Executables and build artifacts (.exe, .dll, .asi, .o, .so, .dylib, .a)
#
# Paths containing "wad" in the name are allowed (e.g. analyze_wad.py, patch_wad_format.md).
# Never commits without your approval at each group.
#
# Usage:
#   ./scripts/safe_commit.sh           # interactive commits
#   ./scripts/safe_commit.sh --dry-run   # preview only, no git writes
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
fi

# ---------------------------------------------------------------------------
# Exclusion rules
# ---------------------------------------------------------------------------

readonly EXCLUDE_DIR_PREFIXES=(
    'tools/lua51-src/'
    'tools/lua51-mercs2/src/'
    'tools/x32dbg/'
    'analysis/'
    '.cursor/'
)

readonly EXCLUDE_EXACT_FILES=(
    'mercenaries-game-output.tar.gz'
    'tools/lua51-mercs2/lua.exe'
    'tools/lua51-mercs2/luac.exe'
    'tools/pmc_blackbox/pmc_blackbox.dll'
    'viewer/public/models/sample.obj',
    'scripts/safe_commit.sh',
)

readonly ALLOW_C_SOURCE_PREFIXES=(
    'tools/net_hooks_asi/'
    'tools/windowed_mode_asi/'
)

readonly LUA51_MERC2_ALLOW=(
    'build.bat'
    'Makefile'
)

# Group display order and default messages (parallel arrays, bash 3.2 safe).
# Tools are split by role: docs, shared libraries, and CLI commands by workflow.
readonly GROUP_ORDER=(
    root-config
    docs-format
    docs-dlc
    docs-lua-re
    docs-new
    tools-docs
    tools-lib-codecs
    tools-lib-havok-gltf
    tools-cli-wad-ffcs
    tools-cli-extract
    tools-cli-pipeline
    tools-cli-dlc-patch
    tools-cli-lua-re
    tools-cli-verify-analysis
    tools-native-asi-gameplay
    tools-native-inject
    tools-lua51-build
    tools-other
    game-scripts
    viewer
    webapp
    scripts
    windows-env
    other
)

readonly GROUP_TITLES=(
    'Root config and build'
    'Docs: binary formats and pipeline'
    'Docs: DLC and modding'
    'Docs: Lua and engine reverse engineering'
    'Docs: new analysis (audio, loading, UI)'
    'Tools: README and usage docs'
    'Tools: shared codecs (UCFX, sges, coords, hash)'
    'Tools: Havok and glTF libraries (hk_anim, gltf_exporter)'
    'Tools: CLI — WAD/FFCS archive commands'
    'Tools: CLI — asset extraction (mesh, texture, placement, anim)'
    'Tools: CLI — pipeline regen, filter, UE5 export'
    'Tools: CLI — DLC port, patch WAD, verification'
    'Tools: CLI — Lua bytecode and binding RE'
    'Tools: CLI — validation, forensics, world analysis'
    'Tools: native ASI mods (gameplay hooks)'
    'Tools: native injectors (pmc_blackbox, probe, lua_enum)'
    'Tools: Lua 5.1 Mercs2 build config'
    'Tools: other'
    'UE5 editor scripts'
    'Three.js asset viewer'
    'FastAPI webapp'
    'Pipeline shell scripts'
    'Windows environment helpers'
    'Other changes'
)

readonly GROUP_MESSAGES=(
    'Update project config, deps, and build targets'
    'Update binary format and pipeline documentation'
    'Update DLC research and modding documentation'
    'Update Lua runtime and engine reverse engineering docs'
    'Add analysis docs: audio crash, mission loading, UI'
    'Update tools README and third-party tool documentation'
    'Update shared binary codec modules (UCFX, sges, coordinates, hash)'
    'Update Havok decompression and glTF export libraries'
    'Update WAD/FFCS/sges archive CLI tools'
    'Update asset extraction CLIs (mesh, texture, placement, animation)'
    'Update pipeline regen, filter, and UE5 bundle CLIs'
    'Update DLC port, patch WAD, and DLC verification CLIs'
    'Update Lua bytecode and engine binding RE CLIs'
    'Update validation, forensic, and world-analysis CLIs'
    'Add native ASI gameplay mod build files (net hooks, windowed mode, DLC enable)'
    'Add native injector build files (pmc_blackbox, mercs2_probe, lua_enum)'
    'Add Lua 5.1 Mercs2 custom build configuration'
    'Update miscellaneous tools'
    'Update UE5 editor scripts (player setup, weather, world populate)'
    'Update Three.js asset viewer'
    'Update FastAPI webapp (schemas, routes, ingest, migrations)'
    'Update pipeline shell scripts'
    'Add Windows environment helpers'
    'Miscellaneous repository updates'
)

# Temp files for grouping (bash 3.2 has no associative arrays).
GROUP_TMPDIR=""
EXCLUDED_FILE=""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() { echo "error: $*" >&2; exit 1; }

tolower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

normalize_path() {
    local p="$1"
    p="${p#./}"
    p="${p%/}"
    printf '%s' "$p"
}

path_has_prefix() {
    local path="$1"
    local prefix="$2"
    case "$path" in
        "$prefix"*) return 0 ;;
        *) return 1 ;;
    esac
}

in_list() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        [[ "$needle" == "$item" ]] && return 0
    done
    return 1
}

group_index() {
    local gid="$1"
    local i=0
    while [[ $i -lt ${#GROUP_ORDER[@]} ]]; do
        if [[ "${GROUP_ORDER[$i]}" == "$gid" ]]; then
            echo "$i"
            return 0
        fi
        i=$((i + 1))
    done
    echo "-1"
}

group_file_path() {
    local gid="$1"
    echo "${GROUP_TMPDIR}/group_${gid}.lst"
}

has_blocked_extension() {
    local lower="$1"
    case "$lower" in
        *.lua|*.luac|*.exe|*.dll|*.asi|*.so|*.dylib|*.wad|*.bin|*.elf|*.zip|*.rar|*.gz|*.gpr|*.dp64|*.dp32)
            return 0
            ;;
        *.tar.gz|*.tgz)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

has_blocked_c_extension() {
    local lower="$1"
    case "$lower" in
        *.c|*.h|*.o|*.a)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

is_excluded() {
    local f
    f="$(normalize_path "$1")"

    if in_list "$f" "${EXCLUDE_EXACT_FILES[@]}"; then
        return 0
    fi

    local dir
    for dir in "${EXCLUDE_DIR_PREFIXES[@]}"; do
        if path_has_prefix "$f" "$dir"; then
            return 0
        fi
    done

    if path_has_prefix "$f" 'tools/lua51-mercs2/'; then
        local base="${f##*/}"
        if ! in_list "$base" "${LUA51_MERC2_ALLOW[@]}"; then
            return 0
        fi
    fi

    local lower
    lower="$(tolower "$f")"

    if has_blocked_extension "$lower"; then
        return 0
    fi

    if has_blocked_c_extension "$lower"; then
        local allow=0
        local prefix
        for prefix in "${ALLOW_C_SOURCE_PREFIXES[@]}"; do
            if path_has_prefix "$f" "$prefix"; then
                allow=1
                break
            fi
        done
        if [[ "$allow" -eq 0 ]]; then
            return 0
        fi
    fi

    return 1
}

append_to_group() {
    local gid="$1"
    local f="$2"
    local list
    list="$(group_file_path "$gid")"
    printf '%s\n' "$f" >> "$list"
}

# Classify paths under tools/ by library vs CLI and by workflow (see tools/README.md).
classify_tools_file() {
    local f="$1"

    case "$f" in
        tools/README.md|tools/external/*|tools/*/README.md)
            echo 'tools-docs'
            return
            ;;
    esac

    # Shared modules imported by CLIs (not run directly as pipeline entrypoints).
    case "$f" in
        tools/ucfx_*.py|tools/sges_*.py|tools/mercs2_coords.py|tools/pandemic_hash.py|tools/aset_type_ids.py|tools/c3_cell_grid.py)
            echo 'tools-lib-codecs'
            return
            ;;
        tools/hk_anim/*|tools/hk_animation.py|tools/hk_mesh.py|tools/hk_packfile.py|tools/hk_skeleton.py|tools/gltf_exporter.py)
            echo 'tools-lib-havok-gltf'
            return
            ;;
    esac

    # CLI: archive slicing, WAD patch, CSUM (see tools/README.md "Commands", "sges").
    case "$f" in
        tools/ffcs_wad.py|tools/mercs2_ffcs_extract.py|tools/analyze_wad.py|tools/wad_patcher.py|tools/ffcs_patch_wad.py|tools/ffcs_csum_analyzer.py|tools/forensic_wad_compare.py|tools/csum_corruption_test.py|tools/csum_cross_analysis.py|tools/csum_enforcement_test.py|tools/verify_ucfx_endian.py|tools/ucfx_be_to_le.py)
            echo 'tools-cli-wad-ffcs'
            return
            ;;
    esac

    # CLI: per-block asset extraction (mesh, texture, placement, Havok, scripts, audio).
    case "$f" in
        tools/mesh_extractor.py|tools/texture_extractor.py|tools/placement_extractor.py|tools/terrain_extractor.py|tools/level_extractor.py|tools/dialog_extractor.py|tools/bik_extractor.py|tools/pws_extractor.py|tools/ucfx_parser.py|tools/havok_extractor.py|tools/hk_skeleton_extractor.py|tools/animgroup_extractor.py|tools/anim_block_pairing.py|tools/anim_gltf_export.py|tools/mercs2_anim_pipeline.py|tools/ecs_metadata_extract.py|tools/aset_decoder.py|tools/aset_prop_tracer.py|tools/lua_script_chunks.py|tools/extract_all_scripts.py|tools/extract_submesh_glbs.py|tools/extract_amazon_dlc.py|tools/cerp_precache.py|tools/savefile_parser.py|tools/pws_xbox_to_pc.py)
            echo 'tools-cli-extract'
            return
            ;;
    esac

    # CLI: Makefile pipeline — filter subsets, regen GLBs, UE5 bundle.
    case "$f" in
        tools/filter_*.py|tools/regen_*.py|tools/ue5_export.py|tools/ue5_material_import.py|tools/build_pmc_base_block_set.py|tools/build_c3_cell_manifest.py|tools/build_vz_act_manifest.py|tools/mercs2_scan_assets.py|tools/variant_classifier.py|tools/texture_streaming_index.py|tools/gltf_validate.py|tools/select_category_samples.py|tools/validate_meshes.py)
            echo 'tools-cli-pipeline'
            return
            ;;
    esac

    # CLI: DLC port, patch construction, import-chain verification.
    case "$f" in
        tools/dlc_port.py|tools/dlc_port_x360_to_pc.py|tools/port_xbox_dlc.py|tools/x360_dlc_io.py|tools/audit_dlc_*.py|tools/verify_dlc_*.py|tools/verify_patch_dlc*.py|tools/verify_patch_vz.py|tools/verify_patch_wad_structure.py|tools/build_patch_wad.py|tools/build_dlc_asi.py|tools/build_diagnostic_asi.py|tools/inventory_dlc_patch.py|tools/dlc_aset_normalize.py|tools/fix_dlc*.py|tools/fix_patch_script_aset_dupes.py|tools/dlc_stringdb_forensic.py|tools/dlc_phase0_baseline.py|tools/validate_patch_wad.py)
            echo 'tools-cli-dlc-patch'
            return
            ;;
    esac

    # CLI: Lua bytecode, bindings, round-trip tests.
    case "$f" in
        tools/lua_*.py|tools/dump_lua_bindings.py|tools/debug_binding_report.py|tools/verify_lua_vas.py|tools/patch_oilcon001_bytecode.py)
            echo 'tools-cli-lua-re'
            return
            ;;
    esac

    # CLI: validation, RE forensics, placement/world analysis, SecuROM, PS3.
    case "$f" in
        tools/validate_*.py|tools/verify_exe_imports.py|tools/verify_rotation_encoding.py|tools/analyze_*.py|tools/_skeleton_probe.json|tools/audit_map_split.py|tools/audit_terrain_*.py|tools/audit_unhandled_tags.py|tools/securom_*.py|tools/apply_securom_patch.py|tools/remove_securom.py|tools/ps3_*.py|tools/cross_platform_vz_compare.py|tools/mesh_ucfx_skeleton_audit.py|tools/skeleton_families.py|tools/spawn_flag_crossref.py|tools/terrain_jigsaw_solver.py|tools/solve_terrain_offsets.py|tools/probe_terrain_offsets.py|tools/diagnose_terrain_disconnect.py|tools/enumerate_type_hashes.py|tools/mercs2_ecs_manifest.py|tools/scan_json_quality.py|tools/validate_probe_results.py|tools/test_rotation_helpers.py)
            echo 'tools-cli-verify-analysis'
            return
            ;;
    esac

    # Native ASI mods (C sources excluded; Makefiles/README/asm allowed).
    case "$f" in
        tools/net_hooks_asi/*|tools/windowed_mode_asi/*|tools/dlc_enable_asi/*)
            echo 'tools-native-asi-gameplay'
            return
            ;;
        tools/pmc_blackbox/*|tools/mercs2_probe/*|tools/lua_enum_asi/*)
            echo 'tools-native-inject'
            return
            ;;
        tools/lua51-mercs2/*)
            echo 'tools-lua51-build'
            return
            ;;
    esac

    echo 'tools-other'
}

classify_file() {
    local f="$1"

    case "$f" in
        .tool-versions|AGENTS.md|Makefile|README.md|requirements.txt|docker-compose.yml|docker-compose.test-windows.yml)
            echo 'root-config'
            return
            ;;
    esac

    case "$f" in
        docs/audio_crash_analysis.md|docs/dlc_mission_loading.md|docs/loading_shell_wad_analysis.md|docs/ui|docs/ui/*)
            echo 'docs-new'
            return
            ;;
    esac

    case "$f" in
        docs/dlc_*|docs/asi_loader_setup.md|docs/how-to-bypass-securom-drm.md|docs/modding_deep_dive.md|docs/securom_forensic_analysis.md|docs/xbox360_dlc_analysis.md|docs/vanilla_mission_lifecycle_analysis.md|docs/patch_wad_format.md|docs/teknogods_coop_research.md)
            echo 'docs-dlc'
            return
            ;;
    esac

    case "$f" in
        docs/lua_*|docs/exe_*|docs/mercs1_engine_analysis.md|docs/luadisass_findings.md|docs/ghidra_annotation_guide.md|docs/ps3_eboot_analysis.md|docs/ps3_ppc_re_workflow.md)
            echo 'docs-lua-re'
            return
            ;;
    esac

    case "$f" in
        docs/*)
            echo 'docs-format'
            return
            ;;
    esac

    case "$f" in
        tools/*)
            classify_tools_file "$f"
            return
            ;;
    esac

    case "$f" in
        game-scripts/*)
            echo 'game-scripts'
            return
            ;;
        viewer/*)
            echo 'viewer'
            return
            ;;
        webapp/*)
            echo 'webapp'
            return
            ;;
        scripts/*)
            echo 'scripts'
            return
            ;;
        analysis/*)
            echo 'analysis'
            return
            ;;
        env.bat|env.ps1|test-env/*)
            echo 'windows-env'
            return
            ;;
    esac

    echo 'other'
}

parse_status_path() {
    local line="$1"
    local path="${line:3}"
    path="${path#\"}"
    path="${path%\"}"
    case "$path" in
        *" -> "*)
            path="${path##* -> }"
            path="${path#\"}"
            path="${path%\"}"
            ;;
    esac
    normalize_path "$path"
}

collect_and_group() {
    : > "$EXCLUDED_FILE"

    local line path gid
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        path="$(parse_status_path "$line")"

        if is_excluded "$path"; then
            printf '%s\n' "$path" >> "$EXCLUDED_FILE"
            continue
        fi

        if [[ -e "$path" ]] || git ls-files --error-unmatch "$path" &>/dev/null; then
            gid="$(classify_file "$path")"
            append_to_group "$gid" "$path"
        fi
    done < <(git status --porcelain -uall)

    # Dedupe group lists
    local gid list tmp
    for gid in "${GROUP_ORDER[@]}"; do
        list="$(group_file_path "$gid")"
        if [[ -f "$list" ]]; then
            sort -u "$list" -o "$list"
        fi
    done

    if [[ -f "$EXCLUDED_FILE" ]]; then
        sort -u "$EXCLUDED_FILE" -o "$EXCLUDED_FILE"
    fi
}

count_lines() {
    local f="$1"
    if [[ ! -f "$f" || ! -s "$f" ]]; then
        echo 0
        return
    fi
    wc -l < "$f" | tr -d ' '
}

print_file_list() {
    local list="$1"
    [[ ! -f "$list" ]] && return
    local f st
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        st="$(git status --porcelain -- "$f" 2>/dev/null | head -1 || true)"
        if [[ -z "$st" ]]; then
            printf '    %s\n' "$f"
        else
            printf '    %s  %s\n' "${st:0:2}" "$f"
        fi
    done < "$list"
}

do_commit_group() {
    local gid="$1"
    local msg="$2"
    local idx title list count

    list="$(group_file_path "$gid")"
    count="$(count_lines "$list")"
    [[ "$count" -eq 0 ]] && return 0

    idx="$(group_index "$gid")"
    title="${GROUP_TITLES[$idx]}"

    echo
    echo "================================================================"
    echo "  Group: $title"
    echo "  Files: $count"
    echo "  Message: $msg"
    echo "================================================================"
    print_file_list "$list"
    echo

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[dry-run] Would: git add ($count files) && git commit -m \"$msg\""
        return 0
    fi

    local default_msg="$msg"
    while true; do
        printf 'Commit? [y]es / [e]dit message / [s]kip / [q]uit: '
        read -r choice
        case "${choice:-}" in
            y|Y|yes)
                local files=()
                while IFS= read -r f; do
                    [[ -z "$f" ]] && continue
                    files+=("$f")
                done < "$list"

                git add -- "${files[@]}"
                git commit -m "$msg"
                echo "Committed: $msg"
                return 0
                ;;
            e|E|edit)
                printf 'Enter commit message: '
                read -r msg
                if [[ -z "$msg" ]]; then
                    echo "Empty message; keeping previous."
                    msg="$default_msg"
                fi
                ;;
            s|S|skip)
                echo "Skipped: $title"
                return 0
                ;;
            q|Q|quit)
                echo "Aborted remaining groups."
                exit 0
                ;;
            *)
                echo "Invalid choice. Use y, e, s, or q."
                ;;
        esac
    done
}

cleanup() {
    if [[ -n "$GROUP_TMPDIR" && -d "$GROUP_TMPDIR" ]]; then
        rm -rf "$GROUP_TMPDIR"
    fi
}

main() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        die "Not inside a git repository."
    fi

    if [[ -z "$(git status --porcelain)" ]]; then
        echo "Working tree clean — nothing to commit."
        exit 0
    fi

    GROUP_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/safe_commit.XXXXXX")"
    EXCLUDED_FILE="${GROUP_TMPDIR}/excluded.lst"
    trap cleanup EXIT

    local gid
    for gid in "${GROUP_ORDER[@]}"; do
        : > "$(group_file_path "$gid")"
    done

    echo "safe_commit.sh — mercenaries-game batch commit helper"
    echo "Repo: $REPO_ROOT"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "Mode: DRY RUN (no git writes)"
    else
        echo "Mode: INTERACTIVE (you approve each group)"
    fi
    echo

    collect_and_group

    local total_eligible=0 excluded_count=0 idx
    for gid in "${GROUP_ORDER[@]}"; do
        total_eligible=$((total_eligible + $(count_lines "$(group_file_path "$gid")")))
    done
    excluded_count="$(count_lines "$EXCLUDED_FILE")"

    echo "Eligible files: $total_eligible"
    echo "Excluded files: $excluded_count"
    if [[ "$excluded_count" -gt 0 ]]; then
        echo
        echo "Excluded (not staged by this script):"
        local shown=0 max_show=40
        while IFS= read -r ex; do
            [[ -z "$ex" ]] && continue
            if [[ "$shown" -lt "$max_show" ]]; then
                printf '  - %s\n' "$ex"
                shown=$((shown + 1))
            fi
        done < "$EXCLUDED_FILE"
        if [[ "$excluded_count" -gt "$max_show" ]]; then
            echo "  ... and $((excluded_count - max_show)) more"
        fi
    fi
    echo

    if [[ "$total_eligible" -eq 0 ]]; then
        echo "No eligible files after exclusions."
        exit 0
    fi

    for gid in "${GROUP_ORDER[@]}"; do
        local n
        n="$(count_lines "$(group_file_path "$gid")")"
        [[ "$n" -eq 0 ]] && continue
        idx="$(group_index "$gid")"
        do_commit_group "$gid" "${GROUP_MESSAGES[$idx]}"
    done

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo
        echo "Dry run complete. Re-run without --dry-run to commit interactively."
    else
        echo
        echo "All groups processed."
    fi
}

main "$@"

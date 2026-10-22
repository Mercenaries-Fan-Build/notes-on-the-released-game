# scripts/ghidra_tables.sh — sourced (not run) by scripts/ghidra_export_functions.sh and the
# scripts/ghidra_analyze_*.sh scripts. Reads the per-image tables by image id. Every function
# writes its result to stdout; on an error it prints the reason to stderr and exits 1, which stops
# a caller that assigns the result under `set -e` (x=$(image_export_sha256 pc-v10)).
#
# Needs REPO_ROOT (the notes repo root) set by the caller.

GHIDRA_IMAGES_TSV="$REPO_ROOT/tools/wad_simulator/crates/mercs2_exemap/data/images.tsv"
GHIDRA_IMAGES_HEADER=$'image_id\tplatform\tghidra_language\tsha256\tsize\tbase\tbuild_id\tcode_image\tfrom_sha256\tstep'
GHIDRA_PROJECTS_TSV="$REPO_ROOT/scripts/ghidra_projects.tsv"
GHIDRA_PROJECTS_HEADER=$'image_id\tproject_dir\tproject_name\tprogram\tsettings_dir\timports\tcode_blocks'

# The row of <file> whose first field is <id> (nothing when it has none), after checking that the
# first line is <header>. Exits 1 when the header differs, the id has more than one row, or the
# row's field count is not the header's.
ghidra_row_of() {
  local file="$1" header="$2" id="$3" found="" line n=0 width
  [[ -f "$file" ]] || { echo "missing table $file" >&2; exit 1; }
  width=$(awk -F'\t' '{print NF; exit}' <<<"$header") || exit 1
  while IFS= read -r line || [[ -n "$line" ]]; do
    n=$((n + 1))
    if [[ $n -eq 1 ]]; then
      [[ "$line" == "$header" ]] || { echo "$file: header is not '${header//$'\t'/\\t}'" >&2; exit 1; }
      continue
    fi
    [[ "${line%%$'\t'*}" == "$id" ]] || continue
    [[ -z "$found" ]] || { echo "$file has more than one row for $id" >&2; exit 1; }
    [[ $(awk -F'\t' '{print NF}' <<<"$line") -eq $width ]] \
      || { echo "$file:$n: the row for $id does not have $width fields" >&2; exit 1; }
    found="$line"
  done < "$file"
  printf '%s' "$found"
}

# Field <n> (1-based) of the tab-separated <row>.
ghidra_field() { awk -F'\t' -v n="$2" '{print $n}' <<<"$1"; }

# The images.tsv sha256 of <id>, the value ExportFunctions.java checks the program against.
# Exits 1 when <id> has no row, when its code_image is not "-" (it shares that image's code and
# is exported as that image), or when the sha256 is not 64 lowercase hex digits.
image_export_sha256() {
  local id="$1" row sha code_image
  row=$(ghidra_row_of "$GHIDRA_IMAGES_TSV" "$GHIDRA_IMAGES_HEADER" "$id") || exit 1
  [[ -n "$row" ]] || { echo "$id has no row in $GHIDRA_IMAGES_TSV" >&2; exit 1; }
  code_image=$(ghidra_field "$row" 8) || exit 1
  [[ "$code_image" == "-" ]] || {
    echo "$id shares its code with $code_image (images.tsv code_image); export $code_image instead" >&2
    exit 1
  }
  sha=$(ghidra_field "$row" 4) || exit 1
  [[ "$sha" =~ ^[0-9a-f]{64}$ ]] || { echo "$GHIDRA_IMAGES_TSV: the sha256 of $id is '$sha'" >&2; exit 1; }
  printf '%s' "$sha"
}

# The analyzeHeadless path: the `ghidra_headless = "<path>"` line of the machine-local, git-ignored
# tools/wad_simulator/.mercs2-local.toml. Exits 1 when the file is missing, the key is missing,
# repeated or malformed, or the path is not an executable file.
ghidra_headless_path() {
  local config="$REPO_ROOT/tools/wad_simulator/.mercs2-local.toml" headless="" line
  [[ -f "$config" ]] || { echo "$config does not exist; it must name analyzeHeadless as ghidra_headless = \"<path>\"" >&2; exit 1; }
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^ghidra_headless[[:space:]]*=[[:space:]]*\"(.*)\"[[:space:]]*$ ]]; then
      [[ -z "$headless" ]] || { echo "$config names ghidra_headless more than once" >&2; exit 1; }
      headless="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^ghidra_headless ]]; then
      echo "$config: the ghidra_headless line is not ghidra_headless = \"<path>\": $line" >&2; exit 1
    fi
  done < "$config"
  [[ -n "$headless" ]] || { echo "$config has no key ghidra_headless (ghidra_headless = \"<path to analyzeHeadless>\")" >&2; exit 1; }
  [[ -x "$headless" ]] || { echo "ghidra_headless in $config is '$headless', which is not an executable file" >&2; exit 1; }
  printf '%s' "$headless"
}

# The directory Ghidra keeps one user's settings in under a settings root given by
# -Dapplication.settingsdir: <user>-ghidra/ghidra_<application.version>_<application.release.name>,
# the version and release name read from the install of the analyzeHeadless at <headless>
# (<install>/support/analyzeHeadless, <install>/Ghidra/application.properties). Exits 1 when a
# property is missing.
ghidra_user_settings_subdir() {
  local headless="$1" props version release
  props="$(cd "$(dirname "$headless")/.." && pwd)/Ghidra/application.properties"
  [[ -f "$props" ]] || { echo "no $props next to $headless" >&2; exit 1; }
  version=$(awk -F= '$1=="application.version"{print $2}' "$props")
  release=$(awk -F= '$1=="application.release.name"{print $2}' "$props")
  [[ -n "$version" && -n "$release" ]] || { echo "$props lacks application.version or application.release.name" >&2; exit 1; }
  printf '%s-ghidra/ghidra_%s_%s' "$(id -un)" "$version" "$release"
}

# The scripts/ghidra_projects.tsv row of <id>. Exits 1 when it has none.
ghidra_project_row() {
  local id="$1" row
  row=$(ghidra_row_of "$GHIDRA_PROJECTS_TSV" "$GHIDRA_PROJECTS_HEADER" "$id") || exit 1
  [[ -n "$row" ]] || { echo "$id has no row in $GHIDRA_PROJECTS_TSV" >&2; exit 1; }
  printf '%s' "$row"
}

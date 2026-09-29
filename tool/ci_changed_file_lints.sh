#!/usr/bin/env bash
# Fails when a Dart file changed against the base branch has a rule that fires
# more often than on the base branch (architecture.md, Gates, item 3).
#
# `dart analyze <directory>` does not report analyzer plugin lints such as
# max_file_lines, but `dart analyze <file>...` does. This script therefore
# analyzes the changed files one by one, on HEAD and on the merge base.
#
# Usage: tool/ci_changed_file_lints.sh [base-ref]   (default: origin/master)
set -euo pipefail

base_ref="${1:-origin/master}"
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

merge_base="$(git merge-base "$base_ref" HEAD)"

skip_pattern='\.(g|freezed)\.dart$|^lib/l10n/|^lib/firebase_options\.dart$'

# Changed files on HEAD, and for each one its path on the merge base.
# A renamed file is compared against its old path.
changed=()
declare -A base_path_of=()
while IFS=$'\t' read -r status first second; do
  case "$status" in
    R*) old_path="$first" new_path="$second" ;;
    *) old_path="$first" new_path="$first" ;;
  esac
  [[ "$new_path" =~ $skip_pattern ]] && continue
  changed+=("$new_path")
  base_path_of["$new_path"]="$old_path"
done < <(
  git diff --name-status -M --diff-filter=AMR "$merge_base" HEAD -- \
    'lib/*.dart' 'test/*.dart' 'integration_test/*.dart'
)

if [ "${#changed[@]}" -eq 0 ]; then
  echo "No changed Dart files."
  exit 0
fi

echo "Analyzing ${#changed[@]} changed Dart files against $base_ref ($merge_base)."

work_dir="$(mktemp -d)"
base_tree="$work_dir/base"
cleanup() {
  git worktree remove --force "$base_tree" >/dev/null 2>&1 || true
  rm -rf "$work_dir"
}
trap cleanup EXIT

# Prints "<relative path>|<CODE>" for every issue, one line per issue.
# Exit codes 1 to 3 mean issues were found; anything higher means the
# analyzer itself failed, and the gate must not pass then.
analyze() {
  local root="$1"
  shift
  [ "$#" -eq 0 ] && return 0
  local output="$work_dir/analyze.out"
  local status=0
  (cd "$root" && dart analyze --format=machine "$@") >"$output" 2>&1 ||
    status=$?
  if [ "$status" -gt 3 ]; then
    echo "dart analyze failed with exit code $status in $root:" >&2
    cat "$output" >&2
    exit "$status"
  fi
  awk -F'|' -v root="$root/" 'NF >= 8 {
    path = $4
    sub("^" root, "", path)
    print path "|" $3
  }' "$output"
}

analyze "$repo_root" "${changed[@]}" >"$work_dir/head.unsorted"
sort "$work_dir/head.unsorted" >"$work_dir/head.txt"

git worktree add --detach --quiet "$base_tree" "$merge_base"
(cd "$base_tree" && flutter pub get >/dev/null)
(cd "$base_tree/tools/architecture_lints" && dart pub get >/dev/null)

base_files=()
: >"$work_dir/renames.txt"
for file in "${changed[@]}"; do
  base_file="${base_path_of[$file]}"
  [ -f "$base_tree/$base_file" ] || continue
  base_files+=("$base_file")
  echo "$base_file|$file" >>"$work_dir/renames.txt"
done
analyze "$base_tree" "${base_files[@]}" >"$work_dir/base.unsorted"
# Report base issues under the HEAD path so renamed files line up.
# The awk scripts test FILENAME instead of FNR == NR: an empty first file
# would make FNR == NR true for the second file as well.
awk -F'|' '
  FILENAME == ARGV[1] { head_path[$1] = $2; next }
  { print head_path[$1] "|" $2 }
' "$work_dir/renames.txt" "$work_dir/base.unsorted" | sort >"$work_dir/base.txt"

# Issues on HEAD beyond the count on the base branch, per file and rule.
new_issues="$(
  awk -F'|' '
    FILENAME == ARGV[1] { base[$0]++; next }
    { head[$0]++ }
    END {
      for (key in head) {
        if (head[key] > base[key]) {
          print key " (" base[key] + 0 " -> " head[key] ")"
        }
      }
    }
  ' "$work_dir/base.txt" "$work_dir/head.txt" | sort
)"

if [ -n "$new_issues" ]; then
  echo "New analyzer issues in changed files (file|rule (base -> head)):"
  echo "$new_issues"
  echo
  echo "Full output for these files:"
  (dart analyze "${changed[@]}" || true)
  exit 1
fi

echo "No new analyzer issues in changed files."

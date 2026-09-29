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

mapfile -t changed < <(
  git diff --name-only --diff-filter=AMR "$merge_base" HEAD -- \
    'lib/*.dart' 'test/*.dart' 'integration_test/*.dart' |
    grep -vE '\.(g|freezed)\.dart$|^lib/l10n/|^lib/firebase_options\.dart$' ||
    true
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
analyze() {
  local root="$1"
  shift
  [ "$#" -eq 0 ] && return 0
  (cd "$root" && dart analyze --format=machine "$@" 2>&1 || true) |
    awk -F'|' -v root="$root/" 'NF >= 8 {
      path = $4
      sub("^" root, "", path)
      print path "|" $3
    }'
}

analyze "$repo_root" "${changed[@]}" | sort >"$work_dir/head.txt"

git worktree add --detach --quiet "$base_tree" "$merge_base"
(cd "$base_tree" && flutter pub get >/dev/null)
(cd "$base_tree/tools/architecture_lints" && dart pub get >/dev/null)

base_files=()
for file in "${changed[@]}"; do
  [ -f "$base_tree/$file" ] && base_files+=("$file")
done
analyze "$base_tree" "${base_files[@]}" | sort >"$work_dir/base.txt"

# Issues on HEAD beyond the count on the base branch, per file and rule.
new_issues="$(
  awk -F'|' '
    FNR == NR { base[$0]++; next }
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

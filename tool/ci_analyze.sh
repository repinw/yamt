#!/usr/bin/env bash
# Analyzes lib, test and integration_test and fails on every issue, infos
# included, except max_file_lines.
#
# Since Dart 3.14 `dart analyze <directory>` also reports analyzer plugin
# lints. max_file_lines then fires in every old file over 300 lines. Those
# files are listed in test/architecture/file_size_test.dart, and
# tool/ci_changed_file_lints.sh fails when a changed file gets a new one.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

output="$(mktemp)"
trap 'rm -f "$output"' EXIT

# Exit codes 1 to 3 mean issues were found; anything higher means the
# analyzer itself failed.
status=0
dart analyze --format=machine lib test integration_test >"$output" 2>&1 ||
  status=$?
if [ "$status" -gt 3 ]; then
  echo "dart analyze failed with exit code $status:" >&2
  cat "$output" >&2
  exit "$status"
fi

# A failed run without one readable issue line is not a clean run.
if [ "$status" -ne 0 ] && ! awk -F'|' 'NF >= 8 { found = 1 } END { exit !found }' "$output"; then
  echo "dart analyze exited with $status but printed no issue:" >&2
  cat "$output" >&2
  exit 1
fi

issues="$(awk -F'|' -v root="$PWD/" 'NF >= 8 && tolower($3) != "max_file_lines" {
  path = $4
  sub("^" root, "", path)
  print tolower($1) " - " path ":" $5 ":" $6 " - " $8 " - " tolower($3)
}' "$output")"

if [ -n "$issues" ]; then
  echo "$issues"
  echo "$(echo "$issues" | wc -l) issues found." >&2
  exit 1
fi
echo "No issues found (max_file_lines in old files is not counted)."

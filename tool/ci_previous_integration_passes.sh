#!/usr/bin/env bash
# Prints the integration tests that passed in the CI run of a commit, one per
# line, from that run's "integration-passed" artifact. Exits with 1 when the
# run or the artifact does not exist, for example while that run still
# uploads it.
#
# Usage: tool/ci_previous_integration_passes.sh <sha>
# Needs GH_TOKEN and GITHUB_REPOSITORY, as set in GitHub Actions.
set -euo pipefail

sha="$1"
run_id="$(
  gh api "repos/$GITHUB_REPOSITORY/actions/runs?head_sha=$sha&event=pull_request" \
    -q '[.workflow_runs[] | select(.name == "CI")][0].id // empty'
)"
if [ -z "$run_id" ]; then
  echo "No CI run for $sha." >&2
  exit 1
fi

dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT
if ! gh run download "$run_id" --repo "$GITHUB_REPOSITORY" \
  --name integration-passed --dir "$dir" >/dev/null 2>&1; then
  echo "No passed integration tests recorded in run $run_id." >&2
  exit 1
fi
cat "$dir/passed.txt"

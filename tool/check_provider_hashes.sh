#!/usr/bin/env bash
# Fails when a Riverpod provider changed but its generated hash did not.
#
# riverpod_generator writes a hash of each provider's source into the .g.dart
# file. A stale hash still compiles and passes every test, so analyze and the
# tests do not catch it, and the next branch that runs build_runner picks it
# up as an unrelated change. Only hash lines count here; other regenerated
# files are listed but do not fail the check.
#
# The script regenerates in the working tree and compares it with HEAD, so it
# refuses uncommitted Dart changes. It leaves the regenerated files there, so
# they can be folded into the commits that changed the providers.
#
# Usage: tool/check_provider_hashes.sh
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if ! git diff HEAD --quiet -- '*.dart'; then
  echo "Commit or stash the Dart changes first; the check compares with HEAD." >&2
  exit 1
fi

flutter pub get >/dev/null
# build_runner prints its errors to stdout.
if ! build_log="$(dart run build_runner build --delete-conflicting-outputs 2>&1)"; then
  echo "$build_log" >&2
  exit 1
fi

stale="$(git diff HEAD --name-only -G "r'[0-9a-f]{40}'" -- '*.g.dart')"
if [[ -n "$stale" ]]; then
  echo "Stale provider hashes. build_runner regenerated:" >&2
  echo "$stale" >&2
  echo "Fold these files into the commits that changed their providers." >&2
  exit 1
fi

other="$(git diff HEAD --name-only -- '*.g.dart')"
if [[ -n "$other" ]]; then
  echo "build_runner also changed these files (not checked):" >&2
  echo "$other" >&2
fi

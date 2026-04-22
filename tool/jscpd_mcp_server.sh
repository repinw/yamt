#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

cd "${repo_root}"

port="${JSCPD_MCP_PORT:-3000}"

exec npx --yes jscpd-server . --port "${port}"

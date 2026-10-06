#!/usr/bin/env bash
# Sets config/app_version in Firestore, which every app reads at start.
#
#   tool/set_app_version.sh <latest_version> <min_version>
#
# latest_version: the newest version that is live in both stores. Older apps
#   show a snackbar once.
# min_version: older apps show only the update page and run no migration.
#   Raise it only to a version that is live in both stores, or users who
#   cannot update yet are locked out.
#
# Needs `gcloud auth login` with access to the Firebase project. Clients may
# not write this document, so this goes through the admin REST API.
set -euo pipefail

project="${FIREBASE_PROJECT:-mealtrack-4b239}"
latest="${1:?latest version, for example 3.6.0}"
min="${2:?min version, for example 3.5.0}"
pattern='^[0-9]+\.[0-9]+\.[0-9]+$'
[[ "$latest" =~ $pattern && "$min" =~ $pattern ]] ||
  { echo "Versions must look like 3.6.0." >&2; exit 1; }
# min above latest would lock out every app, the newest store build included.
if [ "$(printf '%s\n%s\n' "$min" "$latest" | sort -V | tail -1)" != "$latest" ]; then
  echo "min $min is above latest $latest; arguments are <latest> <min>." >&2
  exit 1
fi

token="$(gcloud auth print-access-token)"
curl --fail-with-body -sS -X PATCH \
  -H "Authorization: Bearer $token" \
  -H "x-goog-user-project: $project" \
  -H "Content-Type: application/json" \
  "https://firestore.googleapis.com/v1/projects/$project/databases/(default)/documents/config/app_version" \
  -d "{\"fields\":{\"latest_version\":{\"stringValue\":\"$latest\"},\"min_version\":{\"stringValue\":\"$min\"}}}" \
  | jq -c '.fields | {latest_version: .latest_version.stringValue, min_version: .min_version.stringValue}'

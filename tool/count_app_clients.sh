#!/usr/bin/env bash
# Counts the devices that started the app in the last N days, by app version,
# from users/{uid}/clients/{installId}. A release uses it to decide whether a
# migration can go: few or no active devices below its version.
#
#   tool/count_app_clients.sh [days]   (default 30)
#
# Needs `gcloud auth login` with access to the Firebase project.
set -euo pipefail

project="${FIREBASE_PROJECT:-mealtrack-4b239}"
days="${1:-30}"
since="$(date -u -d "-$days days" +%Y-%m-%dT%H:%M:%SZ)"
token="$(gcloud auth print-access-token)"

query="$(jq -n --arg since "$since" '{structuredQuery: {
  from: [{collectionId: "clients", allDescendants: true}],
  where: {fieldFilter: {
    field: {fieldPath: "last_seen_at"},
    op: "GREATER_THAN_OR_EQUAL",
    value: {timestampValue: $since}}}}}')"

curl --fail-with-body -sS -X POST \
  -H "Authorization: Bearer $token" \
  -H "x-goog-user-project: $project" \
  -H "Content-Type: application/json" \
  "https://firestore.googleapis.com/v1/projects/$project/databases/(default)/documents:runQuery" \
  -d "$query" \
  | jq -r --arg days "$days" '
      [.[] | .document | select(. != null)
        | {install: (.name | split("/") | last),
           seen: .fields.last_seen_at.timestampValue,
           version: .fields.app_version.stringValue,
           platform: .fields.platform.stringValue}]
      # One device can hold several accounts; count it once, at its newest start.
      | group_by(.install) | map(max_by(.seen))
      | group_by(.version)
      | "Active devices in the last \($days) days, by app version:",
        (.[] | "  \(.[0].version)  \(length)  (" +
          (group_by(.platform) | map("\(.[0].platform) \(length)") | join(", ")) + ")")'

#!/usr/bin/env bash
# fetch-metadata.sh — Fetches build metadata from ERP API
# Usage: ./scripts/fetch-metadata.sh <metadata_url> [callback_token]

set -euo pipefail

METADATA_URL="${1:?Usage: fetch-metadata.sh <metadata_url>}"
OUTPUT_FILE="${2:-metadata.json}"

echo "[fetch] Fetching metadata from $METADATA_URL"
curl -sS -f -o "$OUTPUT_FILE" "$METADATA_URL" || {
  echo "[fetch] ERROR: Failed to fetch metadata"
  exit 1
}

echo "[fetch] Metadata saved to $OUTPUT_FILE"
echo "[fetch] App name: $(jq -r '.appName // "unknown"' "$OUTPUT_FILE")"
echo "[fetch] Domain:   $(jq -r '.clientDomain // "unknown"' "$OUTPUT_FILE")"
echo "[fetch] Package:  $(jq -r '.packageId // "unknown"' "$OUTPUT_FILE")"

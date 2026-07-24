#!/usr/bin/env bash
# upload-artifact.sh — Uploads APK/IPA to ERP via multipart/form-data
# Usage: ./scripts/upload-artifact.sh <build_id> <apk_path> <platform> <app> <callback_url> <callback_token>

set -euo pipefail

BUILD_ID="${1:?Usage: upload-artifact.sh <build_id> <apk_path> <platform> <app> <callback_url> <callback_token>}"
APK_PATH="${2:?}"
PLATFORM="${3:?}"
APP="${4:?}"
CALLBACK_URL="${5:?}"
CALLBACK_TOKEN="${6:-}"

if [ ! -f "$APK_PATH" ]; then
  echo "[upload] ERROR: artifact not found at $APK_PATH"
  curl -sS -X POST "$CALLBACK_URL" \
    -F "buildId=$BUILD_ID" \
    -F "app=$APP" \
    -F "platform=$PLATFORM" \
    -F "status=failed" \
    -F "errorMessage=Artifact not found at $APK_PATH" \
    -F "callbackToken=$CALLBACK_TOKEN" || true
  exit 1
fi

echo "[upload] Uploading $APK_PATH to $CALLBACK_URL (multipart)..."

HTTP_CODE=$(curl -sS -w "%{http_code}" -X POST "$CALLBACK_URL" \
  -F "file=@$APK_PATH" \
  -F "buildId=$BUILD_ID" \
  -F "app=$APP" \
  -F "platform=$PLATFORM" \
  -F "status=completed" \
  -F "callbackToken=$CALLBACK_TOKEN" \
  -o /tmp/upload-response.txt) || true

echo "[upload] HTTP status: $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
  echo "[upload] Upload complete"
else
  echo "[upload] Upload failed"
  cat /tmp/upload-response.txt 2>/dev/null || true
  exit 1
fi

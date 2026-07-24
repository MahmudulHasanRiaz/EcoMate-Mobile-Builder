#!/usr/bin/env bash
# sign-android.sh — Signs an Android APK with a keystore from environment
# Usage: ./scripts/sign-android.sh <apk_path> [output_path]
#
# Required env vars:
#   ANDROID_KEYSTORE_BASE64   — base64-encoded .jks / .keystore file
#   ANDROID_KEYSTORE_PASSWORD — keystore password
#   ANDROID_KEY_ALIAS         — key alias
#   ANDROID_KEY_PASSWORD      — key password (optional, falls back to keystore password)

set -euo pipefail

APK_PATH="${1:?Usage: sign-android.sh <apk_path> [output_path]}"
OUTPUT_PATH="${2:-${APK_PATH%.*}-signed.apk}"

if [ -z "${ANDROID_KEYSTORE_BASE64:-}" ]; then
  echo "[sign] WARNING: ANDROID_KEYSTORE_BASE64 not set — skipping signing"
  cp "$APK_PATH" "$OUTPUT_PATH"
  exit 0
fi

echo "[sign] Decoding keystore..."
echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > /tmp/build.keystore

KEYSTORE_PASS="${ANDROID_KEYSTORE_PASSWORD:-}"
KEY_PASS="${ANDROID_KEY_PASSWORD:-$KEYSTORE_PASS}"
KEY_ALIAS="${ANDROID_KEY_ALIAS:?ANDROID_KEY_ALIAS is required}"

if [ ! -f "${ANDROID_HOME:-$HOME/Android/Sdk}/build-tools/"*/apksigner ]; then
  echo "[sign] apksigner not found — trying jarsigner fallback"
  jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
    -keystore /tmp/build.keystore \
    -storepass "$KEYSTORE_PASS" \
    -keypass "$KEY_PASS" \
    "$APK_PATH" "$KEY_ALIAS"
else
  echo "[sign] Signing with apksigner..."
  apksigner sign \
    --ks /tmp/build.keystore \
    --ks-pass "pass:$KEYSTORE_PASS" \
    --key-pass "pass:$KEY_PASS" \
    --ks-key-alias "$KEY_ALIAS" \
    --out "$OUTPUT_PATH" \
    "$APK_PATH"
fi

echo "[sign] Signed APK: $OUTPUT_PATH"
rm -f /tmp/build.keystore

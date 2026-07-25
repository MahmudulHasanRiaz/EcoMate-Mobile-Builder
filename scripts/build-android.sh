#!/usr/bin/env bash
# build-android.sh — Builds Android APK/AAB for a Capacitor app
# Usage: ./scripts/build-android.sh <app> [release|debug]

set -euo pipefail

APP="${1:?Usage: build-android.sh <app> [release|debug]}"
BUILD_TYPE="${2:-release}"
APP_DIR="apps/$APP"

if [ ! -d "$APP_DIR" ]; then
  echo "[build] ERROR: app directory $APP_DIR not found"
  exit 1
fi

echo "[build] Building $APP ($BUILD_TYPE)..."

cd "$APP_DIR"

# Add Android platform if not present
if [ ! -f "android/build.gradle" ]; then
  echo "[build] Adding Android platform..."
  npx cap add android 2>&1 || { echo "[build] cap add android failed"; exit 1; }
fi

# Sync
mkdir -p dist android/app/src/main/assets
echo "[build] Syncing Capacitor config..."
npx cap sync android 2>&1

# Build
echo "[build] Running Gradle (assemble${BUILD_TYPE^})..."
cd android

if [ "$BUILD_TYPE" = "release" ]; then
  ./gradlew assembleRelease --no-daemon 2>&1
  APK_SRC="app/build/outputs/apk/release/app-release.apk"
  AAB_SRC="app/build/outputs/bundle/release/app-release.aab"
else
  ./gradlew assembleDebug --no-daemon 2>&1
  APK_SRC="app/build/outputs/apk/debug/app-debug.apk"
fi

cd ..

if [ -f "$APK_SRC" ]; then
  mkdir -p ../../mobile-builds/$APP/android
  # Sign the APK before copying to output
  echo "[build] Signing APK..."
  bash ../../scripts/sign-android.sh "$APK_SRC" "../../mobile-builds/$APP/android/latest.apk"
  echo "[build] APK ready: mobile-builds/$APP/android/latest.apk"
else
  echo "[build] ERROR: APK not produced"
  exit 1
fi

echo "[build] $APP Android build complete"

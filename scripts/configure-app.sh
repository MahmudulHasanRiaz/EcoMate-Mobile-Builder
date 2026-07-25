#!/usr/bin/env bash
# configure-app.sh — Configures Capacitor app with runtime metadata
# Usage: ./scripts/configure-app.sh <app> <metadata.json>

set -euo pipefail

APP="${1:?Usage: configure-app.sh <app> <metadata.json>}"
META="${2:-metadata.json}"

if [ ! -f "$META" ]; then
  echo "[configure] ERROR: metadata file $META not found"
  exit 1
fi

APP_DIR="apps/$APP"
[ -d "$APP_DIR" ] || { echo "[configure] ERROR: app dir $APP_DIR not found"; exit 1; }

APP_NAME=$(jq -r '.appName // "EcoMate"' "$META")
APP_NAME_ID=$(jq -r '.appNameId // "ecomate"' "$META")
PACKAGE_ID=$(jq -r '.packageId // "com.ecomate.app"' "$META")
CLIENT_DOMAIN=$(jq -r '.clientDomain // "localhost"' "$META")
PRIMARY_COLOR=$(jq -r '.colors.primary // "#0089CD"' "$META")
FAVICON_URL=$(jq -r '.favicon // ""' "$META")
LOGO_URL=$(jq -r '.logo // ""' "$META")

echo "[configure] Configuring $APP for $APP_NAME ($CLIENT_DOMAIN)"
echo "[configure] Package ID: $PACKAGE_ID"

# Generate capacitor.config.js (no TypeScript needed)
cat > "$APP_DIR/capacitor.config.js" <<CONF
/** @type {import('@capacitor/cli').CapacitorConfig} */
const config = {
  appId: '${PACKAGE_ID}',
  appName: '${APP_NAME}',
  webDir: 'dist',
  bundledWebRuntime: false,
  server: {
    url: 'https://${CLIENT_DOMAIN}',
    cleartext: true,
    hostname: '${CLIENT_DOMAIN}',
  },
  android: {
    allowMixedContent: true,
  },
  ios: {
    contentInset: 'always',
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: '${PRIMARY_COLOR}',
    },
  },
};
export default config;
CONF

# Delete old TypeScript config if present
rm -f "$APP_DIR/capacitor.config.ts"

echo "[configure] capacitor.config.js written"

# Download icon if URL provided
if [ -n "$FAVICON_URL" ] && [ "$FAVICON_URL" != "null" ]; then
  echo "[configure] Downloading icon from $FAVICON_URL"
  mkdir -p "$APP_DIR/android/app/src/main/res/mipmap"
  curl -sS -o /tmp/app-icon.png "$FAVICON_URL" || true
fi

# Download logo if URL provided
if [ -n "$LOGO_URL" ] && [ "$LOGO_URL" != "null" ]; then
  echo "[configure] Downloading logo from $LOGO_URL"
  mkdir -p "$APP_DIR/android/app/src/main/res/drawable"
  curl -sS -o /tmp/app-logo.png "$LOGO_URL" || true
fi

echo "[configure] $APP configured successfully"

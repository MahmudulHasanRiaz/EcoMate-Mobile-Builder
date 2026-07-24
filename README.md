# EcoMate Mobile Builder

Generic mobile app artifact factory for EcoMate tenants.

## Architecture

```
ERP Backend → Metadata API → EcoMate-Mobile-Builder → APK/IPA → ERP Backend
```

Builder fetches all client config from ERP at build time. No hardcoded client data.

## Directory Structure

```
├── apps/                    # Capacitor app shells
│   ├── storefront/          # Storefront mobile wrapper
│   ├── admin/               # Admin panel mobile wrapper
│   └── pos/                 # POS mobile wrapper
├── scripts/
│   ├── fetch-metadata.sh    # Fetch client config from ERP
│   ├── configure-app.sh     # Generate capacitor.config.ts + download assets
│   ├── build-android.sh     # Build signed APK/AAB
│   ├── build-ios.sh         # Build signed IPA
│   └── upload-artifact.sh   # Upload build back to ERP
├── assets/
│   ├── icon.png             # Default icon placeholder
│   └── splash.png           # Default splash placeholder
├── signing/                 # Keystore + signing configs (gitignored)
└── .github/workflows/
    ├── build-mobile.yml      # Manual + repository_dispatch trigger
```

## Usage

### Manual trigger via GitHub Actions
1. Go to Actions → Build Mobile App → Run workflow
2. Enter metadata URL from ERP `/api/mobile-builder/metadata`
3. Select app (storefront/admin/pos/all) and platform

### Automated trigger via ERP
Admin clicks "Publish" in ERP admin panel → ERP calls GitHub API →
`repository_dispatch` with type `mobile-build` → workflow starts.

## Required Secrets

| Secret | Required | Purpose |
|--------|----------|---------|
| `MOBILE_BUILDER_CALLBACK_TOKEN` | ✅ Yes | Shared secret for artifact upload callback to ERP |
| `ANDROID_KEYSTORE_BASE64` | ⚠️ For release | Base64-encoded `.jks` keystore file |
| `ANDROID_KEYSTORE_PASSWORD` | ⚠️ For release | Keystore password |
| `ANDROID_KEY_ALIAS` | ⚠️ For release | Key alias inside the keystore |
| `ANDROID_KEY_PASSWORD` | ⚠️ For release | Key password (defaults to keystore password if unset) |

Without signing secrets, the APK is built as **debug-signed** (cannot publish to Play Store).

## Signing Setup

1. Generate a keystore (one per client or shared):
   ```bash
   keytool -genkey -v -keystore client-release.keystore \
     -alias client-key -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Base64 encode it:
   ```bash
   base64 -i client-release.keystore -o client-release.b64
   ```
3. Add as GitHub Secrets:
   - `ANDROID_KEYSTORE_BASE64` — content of the `.b64` file
   - `ANDROID_KEYSTORE_PASSWORD` — the store password
   - `ANDROID_KEY_ALIAS` — the alias name
4. The `sign-android.sh` script runs automatically after each build

## No Business Logic
This repo contains no ERP code, no Prisma, no NestJS.
All client identity comes from the metadata API response at build time.

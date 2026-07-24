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
- `MOBILE_BUILDER_CALLBACK_TOKEN`: Shared secret for artifact upload

## No Business Logic
This repo contains no ERP code, no Prisma, no NestJS.
All client identity comes from the metadata API response at build time.

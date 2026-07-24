# EcoMate-Mobile-Builder — API Contract

এই document দুইটি repository-র (ERP ↔ Builder) মধ্যে communication contract নির্ধারণ করে।

---

## 1. Trigger

### Dispatch Payload (ERP → GitHub → Builder)

ERP `POST /api/mobile-builder/publish` → GitHub `repository_dispatch` event:

```json
{
  "event_type": "mobile-build",
  "client_payload": {
    "buildId": "uuid-abc-123",
    "erpUrl": "https://client-domain.com",
    "callbackToken": "shared-secret-token"
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `buildId` | string | yes | MobileBuild record UUID from ERP |
| `erpUrl` | string | yes | ERP base URL (used for metadata fetch + artifact callback) |
| `callbackToken` | string | yes | Shared secret for artifact upload auth |

**Size:** ~200 bytes. No metadata, no branding, no configuration.

---

## 2. Metadata Fetch

### Request (Builder → ERP)

```
GET {erpUrl}/api/mobile-builder/metadata/{buildId}
```

Auth: `mobile_distribution` license feature (ERP-side gate)

### Response (ERP → Builder) — 200 OK

```json
{
  "buildId": "uuid-abc-123",
  "clientDomain": "fixedplus.com.bd",
  "appName": "FixedPlus",
  "packageId": "com.ecomate.fixedplus",
  "bundleId": "com.ecomate.fixedplus",
  "versionName": "1.0.0",
  "versionCode": 5,
  "iconUrl": "https://cdn.erp.com/uploads/favicon.png",
  "splashColor": "#0089CD"
}
```

| Field | Type | Purpose | Compile-time |
|-------|------|---------|:------------:|
| `clientDomain` | string | server.url in capacitor.config.ts | ✅ APK |
| `appName` | string | App label on Android home screen | ✅ APK |
| `packageId` | string | com.ecomate.{slug} — immutable after 1st publish | ✅ APK |
| `bundleId` | string | iOS bundle ID (same as packageId) | ✅ IPA |
| `versionName` | string | Human-readable version | ✅ APK |
| `versionCode` | int | Monotonically incrementing | ✅ APK |
| `iconUrl` | string | URL to launcher icon PNG (≥1024×1024) | ✅ asset |
| `splashColor` | string | Splash screen background hex color | ✅ APK |

### Error Response

```json
{ "statusCode": 400, "message": "Build not found" }
{ "statusCode": 403, "message": "Forbidden" }
```

---

## 3. Artifact Upload (Callback)

### Request (Builder → ERP)

```
POST {erpUrl}/api/mobile-builder/artifact
Content-Type: multipart/form-data
```

| Form Field | Type | Required | Description |
|------------|------|----------|-------------|
| `file` | binary | no | APK or IPA file |
| `buildId` | string | yes | Build record UUID |
| `status` | string | yes | `completed` \| `failed` |
| `callbackToken` | string | yes | Shared secret (validated against ERP's `MOBILE_BUILDER_CALLBACK_TOKEN`) |
| `app` | string | no | `storefront` \| `admin` \| `pos` |
| `platform` | string | no | `android` \| `ios` |
| `buildLogUrl` | string | no | GitHub Actions run URL |
| `errorMessage` | string | no | Failure reason (if status=failed) |

### Response (ERP → Builder) — 200 OK

```json
{ "received": true, "buildId": "uuid-abc-123", "status": "completed" }
```

### Error Response

```json
{ "statusCode": 400, "message": "Invalid callback token" }
{ "statusCode": 400, "message": "Build {id} not found" }
```

---

## 4. Authentication

| Mechanism | Used For | Secret Location |
|-----------|----------|----------------|
| GitHub token | ERP → GitHub dispatch | `MOBILE_BUILDER_GITHUB_TOKEN` (ERP env) |
| Callback token | Builder → ERP artifact upload | `MOBILE_BUILDER_CALLBACK_TOKEN` (GitHub secret + ERP env) |

Callback token is passed:
1. In dispatch `client_payload.callbackToken`
2. Sent back as `multipart/form-data` field `callbackToken`
3. ERP validates against its `MOBILE_BUILDER_CALLBACK_TOKEN` env var

---

## 5. Error Codes

| HTTP | When |
|------|------|
| 400 | Bad request (invalid input, build not found) |
| 403 | License feature not enabled |
| 409 | Build already in progress for this client |
| 500 | Internal error (GitHub token missing, GitHub API error) |

---

## 6. Build Status Lifecycle

```
queued → running → uploading → completed
                  └→ failed
        └→ cancelled
```

- **ERP** sets status to `queued`, then `running` after successful GitHub dispatch
- **Builder** sets status to `uploading` during artifact upload
- **Builder** sets final status: `completed` or `failed`
- **Admin** can cancel → `cancelled`

---

## 7. Compile-time vs Runtime Assets

| Asset | When Set | How |
|-------|----------|-----|
| App Name | compile-time | capacitor.config.ts → strings.xml |
| Package ID | compile-time | capacitor.config.ts → build.gradle |
| App Icon | compile-time | mipmap resource (downloaded from iconUrl) |
| Splash Color | compile-time | capacitor.config.ts → styles.xml |
| Server URL | compile-time | capacitor.config.ts → webview base url |
| Brand Colors | runtime | Loaded from ERP API in web app CSS |
| Store Logo | runtime | Loaded from ERP API in web app UI |
| Content | runtime | All API-driven (products, categories, etc.) |

---

## 8. Builder Output Paths

```
mobile-builds/{app}/{platform}/latest.apk
mobile-builds/{app}/{platform}/latest.ipa
```

These paths are consumed by ERP's `GET /api/mobile-download/{app}/{platform}` endpoint.

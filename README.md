# Apiary Manager — Flutter App

> Mobile app for professional beekeeping: apiaries, hives, queens, inspections, honey production, treatments, equipment, sales, and AI-powered assistants.

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Domain Modules](#domain-modules)
- [Data Storage Strategy](#data-storage-strategy)
- [AI Stack](#ai-stack)
- [Subscriptions & AI Tiers](#subscriptions--ai-tiers)
- [Localization](#localization)
- [Backend Integration](#backend-integration)
- [Getting Started](#getting-started)
- [Configuration & Secrets](#configuration--secrets)
- [Build & Release](#build--release)
- [Related Repositories](#related-repositories)

---

## Overview

Apiary Manager is a Flutter mobile app paired with a Django REST backend. It is offline-capable, syncs bidirectionally, and bundles three AI surfaces (chat, voice entry, frame analysis) gated by a tiered subscription system backed by RevenueCat.

| Property | Value |
|---|---|
| **Platform** | Flutter (Android primary; iOS, Web, Linux, macOS supported) |
| **Dart SDK** | ≥ 3.0.0 < 4.0.0 |
| **Android Min SDK** | API 21 (Android 5.0) |
| **App Version** | 1.0.3+19 |
| **Backend** | Django 4.2 + DRF @ `cible99.pythonanywhere.com` (MySQL: `Cible99$apiary`) |
| **Local DB schema** | v7 (SQLite) |

---

## Tech Stack

### Core

| Layer | Technology |
|---|---|
| Language | Dart 3+ |
| UI | Flutter (Material 3) |
| State management | Provider + Riverpod (hybrid) |

### Dependencies

| Category | Packages |
|---|---|
| **Networking** | `http`, `connectivity_plus`, `cached_network_image` |
| **Local storage** | `sqflite`, `shared_preferences`, `path_provider` |
| **Maps & location** | `flutter_map`, `flutter_map_marker_cluster`, `latlong2`, `geolocator` |
| **Charts & UI** | `fl_chart`, `shimmer`, `flutter_speed_dial`, `flutter_svg`, `google_fonts` |
| **Media** | `image_picker`, `flutter_image_compress`, `screenshot` |
| **Voice & audio** | `speech_to_text`, `google_speech`, `flutter_sound`, `audioplayers` |
| **ML** | `tflite_flutter` (YOLOv8-seg bee detector) |
| **QR / barcode** | `mobile_scanner`, `qr_flutter` |
| **Payments** | `purchases_flutter`, `purchases_ui_flutter` (RevenueCat) |
| **Auth** | `google_sign_in` |
| **Notifications** | `flutter_local_notifications`, `flutter_timezone`, `flutter_html` (broadcast body) |
| **Background work** | `flutter_background_service`, `flutter_background_service_android` |
| **Permissions** | `permission_handler` |
| **Export** | `pdf`, `printing`, `csv`, `share_plus` |
| **Sensors** | `sensors_plus`, `vibration` |
| **NFC & deep links** | `nfc_manager`, `app_links` |
| **App updates** | `in_app_update` (Play Store in-app update) |
| **i18n** | `flutter_localizations`, `intl` |

### Custom fonts
Caveat, Quicksand, Poppins.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        Flutter App                           │
│                                                              │
│   Screens ─┬─ Widgets ──── Providers (Provider + Riverpod)   │
│            │                                                 │
│            ▼                                                 │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                   Services Layer                    │   │
│   │  ApiService · AuthService · StorageService          │   │
│   │  SyncService · ControlloService · ColoniaService    │   │
│   │  AiQuotaService · ChatService · MCPService          │   │
│   │  BeeDetectionService · VoiceDataProcessor           │   │
│   │  SubscriptionService (RevenueCat)                   │   │
│   │  StatisticheService · MeteoService · ...            │   │
│   └────────────┬─────────────────────────────┬──────────┘   │
│                │                             │              │
│   ┌────────────▼──────────┐    ┌─────────────▼──────────┐   │
│   │    SharedPreferences  │    │     SQLite (v7)         │   │
│   │  apiari, arnie,       │    │  controlli,             │   │
│   │  melari, regine, ...  │    │  analisi_telaini,       │   │
│   │                       │    │  colonie, ...           │   │
│   └───────────────────────┘    └─────────────────────────┘   │
└────────────┬─────────────────────────────────┬───────────────┘
             │ REST (token auth)               │ direct API
             ▼                                 ▼
   ┌──────────────────────┐    ┌────────────────────────────┐
   │  Django 4.2 + DRF    │    │  Gemini API (v1beta)       │
   │  PythonAnywhere      │    │  + RevenueCat (entitlements)│
   │  + MySQL             │    │                            │
   └──────────────────────┘    └────────────────────────────┘
```

### State management

- **Riverpod** — reactive UI state on screens that need fine-grained rebuilds.
- **Provider** — global singleton services (auth, API, sync, subscription, AI quota).

`provider_setup.dart` wires everything: `LanguageService` → `ConnectivityService` → `StorageService` → `AuthService` → `ApiService` → `SyncService` → `MCPService` → `BeeDetectionService` → `AnalisiTelainoService` → `AudioService` → `VoiceFeedbackService` → `SubscriptionService` → `AiQuotaService` → `StatisticheService` → `ChatService`.

---

## Project Structure

```
lib/
├── main.dart                   # Entry point — RC bootstrap, edge-to-edge UI
├── app.dart                    # MaterialApp shell (legacy, see main.dart)
├── provider_setup.dart         # Service & provider wiring
│
├── constants/                  # api_constants, theme_constants, gemini_constants,
│                               #  app_constants, piante_mellifere
├── l10n/                       # AppStrings + strings_it / strings_en (custom i18n)
│
├── models/                     # Pure Dart data classes (~25)
│   ├── apiario, arnia, colonia, controllo_arnia, regina
│   ├── melario, smielatura, invasettamento, maturatore,
│   │   contenitore_stoccaggio, preferenza_maturazione
│   ├── fioritura, fioritura_conferma, trattamento, tipo_trattamento
│   ├── attrezzatura, manutenzione, spesa_attrezzatura
│   ├── pagamento, vendita, cliente, gruppo, quota_utente
│   ├── analisi_telaino, voice_entry, chat_message
│   ├── osm_vegetazione, user
│
├── database/                   # SQLite layer
│   ├── database_helper.dart    # v7 schema + onUpgrade migrations
│   └── dao/
│       ├── apiario_dao.dart, arnia_dao.dart, colonia_dao.dart
│       ├── controllo_arnia_dao.dart   # _convertBools() guard
│       └── analisi_telaino_dao.dart
│
├── services/                   # Business logic & I/O
│   ├── api_service, api_cache_helper, sync_service, background_sync_service
│   ├── auth_service, auth_token_provider, storage_service, connectivity_service
│   ├── controllo_service, colonia_service, regina_service
│   ├── analisi_telaino_service, attrezzatura_service, pagamento_service
│   ├── fioritura_service, gruppo_service, statistiche_service
│   ├── notification_service, notification_polling_service, notification_navigator
│   ├── update_service             # Play Store in-app update (startup + resume)
│   ├── location_service, locations_service, meteo_service
│   ├── osm_vegetazione_service, sensor_service, mobile_scanner_service, qr_*_service
│   ├── export_service, language_service, jokes_service
│   │
│   │  # AI / voice / subscription
│   ├── chat_service               # Gemini chat (direct w/ personal key, proxy w/ shared)
│   ├── mcp_service                # tool layer over backend REST
│   ├── ai_quota_service           # quota & tier gating (single source of truth)
│   ├── ai_quota_local_tracker     # offline counters
│   ├── bee_detection_service      # YOLOv8-seg TFLite inference
│   ├── voice_data_processor       # voice → structured fields (Gemini)
│   ├── gemini_audio_processor     # audio → text via Gemini (direct or backend proxy)
│   ├── voice_feedback_service, voice_queue_service, voice_settings_service
│   ├── voice_language_rules, bee_vocabulary_corrector
│   ├── platform_speech_service, platform_voice_input_manager
│   ├── audio_service, audio_recorder_service, audio_queue_service
│   ├── subscription_service       # RevenueCat wrapper
│   │
│   │  # NFC & deep linking
│   ├── nfc_service                # raw NFC reader (nfc_manager)
│   ├── nfc_handler                # resolves nfc_id → arnia and navigates
│   └── deep_link_handler          # https://.../a/<nfc_id> + apiary:// links
│
├── screens/                    # 40+ screens, domain-organised
│   ├── auth/, splash_screen, onboarding/
│   ├── apiario/, arnia/, colonia/, regina/, controllo/
│   ├── melario/, nucleo/, cantina/  (maturatori + contenitori + invasettamenti)
│   ├── alimentazione/, nomadismo/   # ML dataset feeds, per-colonia
│   ├── notifications/               # broadcast notification centre
│   ├── fioritura/, trattamento/, attrezzatura/
│   ├── pagamento/, vendita/, gruppo/
│   ├── analisi_telaino/, mappa/
│   ├── statistiche/             # 3 tabs: dashboard, query_builder, nl_query
│   ├── ai_tier_upgrade_screen   # paywall + tester code activation
│   ├── chat_screen              # Gemini-powered AI chat
│   ├── voice_command_screen, voice_entry_verification_screen,
│   │   voice_transcript_review_screen
│   ├── settings_screen, dashboard_screen
│   ├── help/, donazione/, whats_new/
│   ├── disclaimer_screen, privacy_policy_screen
│   └── mobile_scanner_wrapper_screen
│
├── widgets/                    # ~25 reusable widgets
│   ├── drawer_widget, app_card widgets, error_widget (canonical)
│   ├── skeleton_widgets        # Skeleton{ListView,DetailHeader,DashboardContent}
│   ├── loading_widget, retry_button_widget, offline_banner, sync_status_widget
│   ├── voice_input_widget, audio_input_widget, voice_animations,
│   │   voice_context_banner, corrected_transcription_widget
│   ├── chart_widget, weather_widget, qr_generator_widget
│   ├── attrezzatura_prompt_dialog, hive_frame_visualizer,
│   │   beehive_illustrations, paper_widgets
│   └── bee_joke_bubble, contextual_hint, field_help_icon
│
├── providers/                  # Riverpod providers
│   └── apiario_provider, auth_provider, connectivity_provider, sync_provider
│
└── utils/                      # Helpers, formatters, route generator
```

---

## Domain Modules

### Apiaries & hives
CRUD, color coding, geo-location, clustered map view (`flutter_map_marker_cluster`).

### Colonie
First-class entity separate from arnia (a hive can host different colonies over time).

### Inspections (`controllo_arnia`)
Structured forms with telaini config persisted as JSON. Stored in SQLite via `ControlloArniaDao`.

### Queens (regine)
Genealogy and status; refreshed from server on every arnia load.

### Honey production & cantina
Full lifecycle: melario → smielatura → maturatore → contenitore → invasettamento (jarring), with maturation preferences.

### Treatments, flowering, equipment, sales, payments, groups
CRUD plus auto-payment generation when an attrezzatura/manutenzione has cost > 0; multi-user collaborative groups with invitations.

### Statistiche (3 tabs)
- **Dashboard** — 12 cards (`DashboardCardBase`): produzione, varroa trend, salute arnie, andamento covata/scorte, performance regine, attrezzature, bilancio, frequenza controlli, fioriture vicine, quote gruppo, regine, etc.
- **Query Builder** — point-and-click filters over apiari/arnie data.
- **NL Query** — natural-language questions answered by Gemini through the MCP tool layer.

### AI chat
Conversational assistant for the apiary with function-calling tools.

### Voice entry
Free-form speech → structured inspection records.

### Frame analysis
On-device YOLOv8-seg detection of bees / drones / queens / royal cells from a frame photo.

### NFC & deep links
Each arnia can be bound to an NFC tag via its `nfc_id` (UID hex). Scanning a tag — either inside the app or from the OS — opens the matching arnia detail screen.

- `NfcService` reads the UID via `nfc_manager` (supports nfca/nfcb/nfcf/nfcv/ISO-DEP/MIFARE/FeliCa/ISO15693/ISO7816).
- `NfcHandler` resolves the UID locally first, then via `ApiService.searchArnie()`, and navigates.
- `DeepLinkHandler` (App Links / Universal Links + custom scheme) handles `https://cible99.pythonanywhere.com/a/<nfc_id>` and `apiary://a/<nfc_id>`, queueing the link until the user is authenticated.
- Server-side artefacts to wire OS-level deep linking live in `deploy/nfc-deeplink/` (`assetlinks.json`, `apple-app-site-association`, `views.py`, `nfc_landing.html`).

---

## Data Storage Strategy

Two **independent** local stores — mixing them is a recurring source of bugs:

| Store | Used for | Access |
|---|---|---|
| **SharedPreferences** | apiari, arnie, melari, regine | `StorageService.getStoredData('key')` |
| **SQLite (v7)** | controlli, analisi_telaini, colonie, apiari/arnie DAOs | `*Dao` / `ControlloService` |

### Critical patterns

- **Bool/int pitfall** — sqflite persists `bool` as `INTEGER` 0/1. Every read in `ControlloArniaDao` runs `_convertBools()`; without it, UI code crashes with `TypeError: type 'int' is not a subtype of type 'bool'`.
- **Schema-safe sync** — `syncFromServer()` and `insert()` use `DatabaseHelper.getTableColumns()` (`PRAGMA table_info`) to strip server fields absent from the local schema, so backend column additions don't break the app before the next migration.
- **Offline-first cache** — `ApiService` tries network first, falls back to `ApiCacheHelper` when offline, and persists successful responses for later offline reads.

---

## AI Stack

### 1. Gemini chat (direct from client)

`ChatService(AiQuotaService, MCPService)` calls Gemini's `v1beta/models/{model}:generateContent` directly with function-calling tools provided by `MCPService`. Tools translate to authenticated REST calls against the Django backend.

- Model fallback chain in `lib/constants/gemini_constants.dart`: `gemini-3.8-flash` → `gemini-3.6-flash` → `gemini-3.5-flash-lite`. Retired models answer `404 NOT_FOUND` and the rotation retries each one with the full payload, which for voice carries the base64 audio, so keep the list short and current. Note that `ListModels` still advertises models that reject calls with `404 no longer available to new users`, so verify a model with a real request before adding it.
- System prompt is enriched with a per-user apiary/hive snapshot via `MCPService.prepareContext()` (cached 60 s).
- Telemetry/quota: `AiQuotaService.recordChatCallToBackend()` posts `record_only:true` to `/api/v1/ai/chat/`.
- A user can supply a **personal Gemini key** in Settings (`User.geminiApiKey`); when set, `ChatService.setPersonalKey()` skips the tier limit.

### 2. Voice pipeline

```
mic → speech_to_text / google_speech / gemini_audio_processor
  → BeeVocabularyCorrector  (domain term correction)
  → VoiceDataProcessor      (Gemini → structured fields)
  → VoiceEntryVerificationScreen (user confirms parsed data)
  → ControlloService / StorageService
```

### 3. Bee detector

YOLOv8-seg quantised to TFLite at `assets/models/bee_detector.tflite`. Classes: `bees(0)`, `drone(1)`, `queenbees(2)`, `royal cell(3)`. Used by `AnalisiTelainoScreen` to count frame contents from a camera photo.

---

## Subscriptions & AI Tiers

The app gates AI features (chat / voice / stats NL queries) by tier. Tiers are defined in `lib/models/user.dart`:

| Tier | Label | Fallback daily limits (chat / voice / total) |
|---|---|---|
| `free` | Uovo 🥚 | 10 / 5 / 15 |
| `apicoltore` | Larva 🐛 | 30 / 30 / 60 |
| `professionale` | Ape 🐝 | 200 / 100 / 300 |

Labels follow the bee life cycle and are rendered as animated SVGs by `AnimatedTierIcon` (`assets/images/icons/Tiers/`). The enum values are unchanged — they are the serialization contract with the backend.

Authoritative limits come from the backend (`GET /api/v1/ai/quota/` → `all_tier_limits`); local values are only fallbacks.

### Upgrade paths

1. **RevenueCat in-app purchase** — `SubscriptionService` (entitlement: `Apiary Pro`) maps active products to tiers (`yearly` → `professionale`, otherwise `apicoltore`). Lifecycle: `init()` at app start, `login()` after auth, `logout()` on sign-out.
2. **Tester code** — entered in `AiTierUpgradeScreen`; backend validates and bumps `User.ai_tier`.
3. **Personal Gemini key** — bypasses the tier rate limiter for chat (the user pays Google directly).

> **Shared key routing:** with a personal key the client calls Gemini directly. With the *shared* key it goes through the authenticated backend proxy `POST /api/v1/ai/gemini-proxy/`, which injects the key server-side — it is no longer compiled into the app binary. The proxy enforces the tier quota gate and returns 429 when exhausted.

`AiQuotaService` is the single source of truth for quota state; `ChatService`, statistiche tabs, and the upgrade screen all read from it.

---

## Localization

Custom in-app i18n, no ARB / `.arb` files:

- `lib/l10n/app_strings.dart` — abstract base class with one getter per string.
- `lib/l10n/strings_it.dart`, `lib/l10n/strings_en.dart` — concrete implementations.
- `LanguageService` (Provider) exposes the active `AppStrings` instance and persists the choice.

Adding a language: create one new `strings_<code>.dart` extending `AppStrings`, register it in `LanguageService._setFromCode()`. No widget changes needed.

---

## Backend Integration

DRF REST API with token authentication.

### Key endpoints

| Resource | Endpoint pattern |
|---|---|
| Apiari | `/api/v1/apiari/`, `/api/v1/apiari/{id}/` |
| Arnie | `/api/v1/arnie/`, `/api/v1/arnie/{id}/` |
| Controlli | `/api/v1/controlli/`, `/api/v1/arnie/{id}/controlli/` |
| Regine | `/api/v1/regine/`, `/api/v1/arnie/{id}/regina/` |
| Analisi telaini | `/api/v1/analisi-telaini/` |
| Melari / smielature | `/api/v1/melari/`, `/api/v1/smielature/` |
| Trattamenti / fioriture | `/api/v1/trattamenti/`, `/api/v1/fioriture/` |
| Pagamenti / vendite | `/api/v1/pagamenti/`, `/api/v1/vendite/` |
| Gruppi | `/api/v1/gruppi/` |
| Profile | `GET/PATCH /api/v1/users/me/` (exposes `gemini_api_key`, `ai_tier`) |
| AI quota | `GET /api/v1/ai/quota/`, `POST /api/v1/ai/chat/` |
| AI proxy | `POST /api/v1/ai/gemini-proxy/` (shared key, server-side injection) |
| Notifiche | `/api/v1/notifiche/`, `/notifiche/unread_count/`, `/notifiche/{id}/mark_read/`, `/notifiche/mark_all_read/` |
| ML dataset | `/api/v1/pesate-melari/`, `/api/v1/alimentazioni/`, `/api/v1/nomadismi/`, `/api/v1/ml/dataset/colonia/{id}/` |
| ML predictions | `GET /api/v1/ml/predict/colonia/{id}/` |

Auth header: `Authorization: Token <token>`.

> Note: `arniaReginaUrl` constant in `api_constants.dart` uses singular `/arnia/` which is **wrong**; production code uses the plural `arnieUrl`.

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.0.0
- Android Studio / Xcode
- Backend reachable (PythonAnywhere prod or local dev)

### Setup

```bash
git clone <repo-url>
cd Apiary_app

flutter pub get

# Configure API base URL
#   Edit lib/constants/api_constants.dart

# No client-side secret to configure: the app ships with no API key
# compiled in. See "Configuration & Secrets".

flutter run
```

---

## Configuration & Secrets

**No API key is compiled into the app.** Every key is resolved at runtime, so
there is nothing to fill in before building.

| Key | Where it lives | Set by | Used when |
|---|---|---|---|
| Personal Gemini key | User profile on the backend (`Profilo.gemini_api_key`) | End user, Settings → *AI API Keys* → Gemini | Client calls Gemini directly (independent quota) |
| Shared system Gemini key | Backend environment variable `GEMINI_API_KEY` | Developer, backend `.env` (see below) | Client has no personal key → calls go through `POST /api/v1/ai/gemini-proxy/` |
| Personal Groq key | Device only, `SharedPreferences` key `groq_api_key` | End user, Settings → *AI API Keys* → Groq | Statistics NL query |

The personal Gemini key is saved through `PATCH` on the profile
(`SettingsScreen._saveApiKey`) and propagated to `ChatService` and
`GeminiAudioProcessor` at startup by `provider_setup.dart`.

### Setting the shared system key (developer)

The system key is **backend-side only** and lives in the `Apiary` Django repo,
never in this one. `apiario_manager/settings.py` reads it from the environment
after loading a `.env`:

```bash
# Local dev — .env in the backend project root
GEMINI_API_KEY=AIzaSy...

# Production (PythonAnywhere) — /home/Cible99/.env
GEMINI_API_KEY=AIzaSy...
```

Reload the web app after editing the production file. `GeminiService` in
`core/ai_services.py` picks it up; when neither a personal nor a system key is
available the proxy answers `403` with
`Nessuna GEMINI_API_KEY configurata`.

### Removed: build-time key injection

Earlier builds compiled the shared key into the binary through
`lib/config/api_keys.dart` or `--dart-define-from-file=env.json`. That is how
the key got extracted and suspended by Google, and it is why the backend proxy
exists. Those placeholder files (`lib/config/api_keys.dart.example`,
`lib/config/google_credentials.dart`, `env.example.json`) have been deleted:
no `String.fromEnvironment('GEMINI_API_KEY')` is left in the code, so passing
`--dart-define` does nothing. Do not reintroduce them.

`.gitignore` still excludes `env.json`, `lib/config/api_keys.dart`, and
`android/app/google-services.json` as a safety net.

The RevenueCat Google Play API key is currently embedded as a constant in `lib/services/subscription_service.dart` (test key). Replace before shipping production builds.

---

## Build & Release

```bash
flutter run                         # debug

flutter test                        # tests

flutter build apk --release         # Android APK
flutter build appbundle --release   # Play Store bundle
flutter build ios --release         # iOS
flutter build web --release         # Web
```

Launcher icons & splash are managed by `flutter_launcher_icons` and `flutter_native_splash` (config in `pubspec.yaml`).

### Pre-release checklist

Run these in order before publishing a new build. Steps 1-4 are local and take
a couple of minutes; steps 5-7 need a device or emulator.

**1. Backend regression suite** (in the `Apiary` repo)

```bash
DJANGO_DEBUG=True python manage.py test core
```

Runs against a throwaway SQLite database, touches nothing in production. It
covers the melario lifecycle (place, remove, extract) and the feeding API,
including the cross-account access checks. `DJANGO_DEBUG` must be set or
Django tries to reach the production MySQL server.

**2. Static analysis** (app repo)

```bash
flutter analyze
```

The baseline is *zero* errors. Warnings and infos are pre-existing lint noise;
what matters is that the error count stays at zero and the warning list does
not grow.

**3. Unit tests** (app repo)

```bash
flutter test
```

Pure logic only, no network: payment splitting, melari counters and cache
round-trip, feeding aggregations.

**4. Compile check**

```bash
flutter build apk --debug
```

Catches anything the analyzer misses, such as missing assets declared in
`pubspec.yaml`.

**5. Smoke test on a device**

```bash
flutter run
```

Walk the flows that changed in the release. Log in as a real account with real
data, not an empty one: most regressions only show up with existing records.

**6. Check the release notes**

Open the what's-new sheet and confirm every entry matches something a user can
actually find. The changelog lives in `_changelog` in
`lib/screens/whats_new/whats_new_screen.dart`, keyed by build number, and the
build number is the digit after `+` in `pubspec.yaml`.

**7. Release build, installed on a real device**

Release builds are signed with the upload keystore declared in
`android/key.properties` (gitignored, never committed):

```
storeFile=C:/path/to/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Without that file `signingConfigs.release` gets a null `storeFile` and the
bundle comes out unsigned, which the Play Console rejects.

```bash
flutter build apk --release
```

Install the APK and open it once before uploading the bundle. Release mode
enables tree shaking and R8, which occasionally breaks things that work fine
in debug. Only then:

```bash
flutter build appbundle --release
```

Upload to the Play Console **internal testing** track first, and promote to
production once it installs and starts on at least one real device.

### Deployment order

When a release changes both repos, deploy the backend *first*. The app tolerates
a backend that lacks new response fields, but a new backend field the app never
receives shows up as missing data. Deploying the app first against an old
backend is the case that breaks.

---

## Related Repositories

| Repo | Description |
|---|---|
| `Apiary` | Django 4.2 + DRF backend (deployed on PythonAnywhere) |
| `Apiary_app` | This Flutter mobile application |

See `LEGGIMI_PROGETTO.md` in the repo root for the full project documentation (Italian).

---

## License

MIT — see `LICENSE`.

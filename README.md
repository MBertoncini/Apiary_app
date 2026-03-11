# Apiary Manager — Flutter App

> A comprehensive mobile application for professional beekeeping management: hives, queens, inspections, honey production, treatments, and AI-powered features.

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Key Features](#key-features)
- [Data Storage Strategy](#data-storage-strategy)
- [AI & Voice Features](#ai--voice-features)
- [Backend Integration](#backend-integration)
- [Getting Started](#getting-started)
- [Build & Release](#build--release)

---

## Overview

Apiary Manager is a Flutter mobile application that pairs with a Django REST backend to give beekeepers a fully offline-capable tool for managing every aspect of their apiaries. The app syncs data bidirectionally with the server, works seamlessly offline, and includes advanced features like AI-powered bee detection, voice command input, and QR-code navigation.

| Property | Value |
|---|---|
| **Platform** | Flutter (Android, iOS, Web, Linux, macOS) |
| **Dart SDK** | ≥ 3.0.0 < 4.0.0 |
| **Android Min SDK** | API 21 (Android 5.0) |
| **iOS Min SDK** | iOS 11+ |
| **App Version** | 1.0.0+1 |
| **Backend** | Django 4.2 + DRF @ PythonAnywhere |

---

## Tech Stack

### Core Framework

| Layer | Technology |
|---|---|
| Language | Dart 3+ |
| UI Framework | Flutter |
| State Management | Provider + Riverpod (hybrid) |

### Dependencies

| Category | Packages |
|---|---|
| **Networking** | `http`, `connectivity_plus`, `cached_network_image` |
| **Local Storage** | `sqflite`, `shared_preferences`, `path_provider` |
| **Maps & Location** | `flutter_map`, `latlong2`, `geolocator` |
| **Charts** | `fl_chart` |
| **Media** | `image_picker`, `flutter_image_compress`, `screenshot` |
| **Voice / Audio** | `speech_to_text`, `google_speech`, `flutter_sound`, `audioplayers` |
| **ML / AI** | `tflite_flutter` (YOLOv8-seg bee detector) |
| **QR / Barcode** | `mobile_scanner`, `qr_flutter` |
| **Notifications** | `flutter_local_notifications` |
| **Permissions** | `permission_handler` |
| **Export** | `pdf`, `csv`, `share_plus` |
| **UI Extras** | `google_fonts`, `flutter_svg`, `flutter_speed_dial` |
| **Background** | `flutter_background_service` |
| **Sensors** | `sensors_plus`, `vibration` |
| **Internationalization** | `intl`, `flutter_localizations` |

### Custom Fonts

- **Caveat** — Regular, Bold
- **Quicksand** — Regular, Medium, Bold
- **Poppins** — Regular, Medium, SemiBold, Bold

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Flutter App                        │
│                                                         │
│  ┌─────────┐  ┌──────────┐  ┌─────────┐  ┌─────────┐  │
│  │ Screens │  │ Widgets  │  │Providers│  │  Utils  │  │
│  └────┬────┘  └────┬─────┘  └────┬────┘  └─────────┘  │
│       │             │             │                      │
│  ┌────▼─────────────▼─────────────▼────────────────┐   │
│  │                  Services Layer                   │   │
│  │  ApiService · AuthService · StorageService       │   │
│  │  SyncService · ControlloService · VoiceServices  │   │
│  │  BeeDetectionService · NotificationService ...   │   │
│  └────┬─────────────────────────────────────┬───────┘   │
│       │                                     │            │
│  ┌────▼──────────┐                ┌─────────▼────────┐  │
│  │  SharedPrefs  │                │  SQLite (sqflite) │  │
│  │  (apiari,     │                │  (controlli,      │  │
│  │   arnie,      │                │   analisi         │  │
│  │   melari,     │                │   telaini)        │  │
│  │   regine)     │                │                   │  │
│  └───────────────┘                └──────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │  REST API (JWT)
                          ▼
           ┌──────────────────────────────┐
           │  Django 4.2 + DRF Backend    │
           │  cible99.pythonanywhere.com  │
           └──────────────────────────────┘
```

### State Management Strategy

The app uses a **hybrid approach**:
- **Riverpod** — for reactive, scoped UI state (screens that need fine-grained reactivity)
- **Provider** — for global singleton services (auth, storage, connectivity)

---

## Project Structure

```
lib/
├── main.dart                   # App entry point
├── app.dart                    # MaterialApp + routing
├── provider_setup.dart         # Service & provider wiring
│
├── config/                     # App-level configuration
│   └── google_credentials.dart
│
├── constants/                  # API URLs, theme colours, enums
│
├── models/                     # Pure Dart data classes
│   ├── apiario.dart
│   ├── arnia.dart
│   ├── controllo_arnia.dart    # Inspection with telaini config (JSON)
│   ├── regina.dart
│   ├── melario.dart
│   ├── smielatura.dart
│   ├── fioritura.dart
│   ├── trattamento.dart
│   ├── attrezzatura.dart
│   ├── pagamento.dart
│   ├── vendita.dart
│   ├── analisi_telaino.dart
│   ├── gruppo.dart
│   ├── voice_entry.dart
│   └── ...
│
├── database/                   # SQLite layer
│   ├── database_helper.dart    # DB init, schema, PRAGMA helpers
│   └── dao/
│       ├── controllo_arnia_dao.dart   # ← _convertBools() applied here
│       ├── analisi_telaino_dao.dart
│       └── ...
│
├── services/                   # Business logic & I/O
│   ├── api_service.dart               # HTTP client, pagination, offline cache
│   ├── auth_service.dart              # JWT login/register/logout
│   ├── storage_service.dart           # SharedPreferences wrapper
│   ├── api_cache_helper.dart          # Offline fallback cache
│   ├── sync_service.dart              # Manual bidirectional sync
│   ├── background_sync_service.dart   # Periodic background sync
│   ├── connectivity_service.dart
│   ├── controllo_service.dart         # Controlli → SQLite DAO
│   ├── analisi_telaino_service.dart
│   ├── attrezzatura_service.dart      # Auto-payment on cost > 0
│   ├── pagamento_service.dart
│   ├── fioritura_service.dart
│   ├── gruppo_service.dart
│   ├── bee_detection_service.dart     # TFLite inference
│   ├── voice_data_processor.dart      # Voice → structured data (Gemini)
│   ├── voice_feedback_service.dart
│   ├── voice_queue_service.dart
│   ├── platform_voice_input_manager.dart
│   ├── gemini_data_processor.dart
│   ├── bee_vocabulary_corrector.dart
│   ├── export_service.dart            # PDF / CSV
│   ├── mobile_scanner_service.dart
│   ├── qr_navigator_service.dart
│   ├── notification_service.dart
│   ├── location_service.dart
│   ├── camera_service.dart
│   └── ...
│
├── screens/                    # UI screens (35+), domain-organised
│   ├── auth/                   # Login, Register
│   ├── apiario/                # List, Detail, Form, Map widget
│   ├── arnia/                  # List, Detail, Form
│   ├── controllo/              # Inspection form
│   ├── regina/                 # List, Detail, Form
│   ├── melario/                # Melario, Smielatura, Invasettamento
│   ├── nucleo/                 # Nucleo detail
│   ├── fioritura/              # List, Detail, Form, Confirmation
│   ├── attrezzatura/           # Equipment + Maintenance + Expenses
│   ├── pagamento/              # Payments, Quotes
│   ├── vendita/                # Sales, Clients
│   ├── trattamento/            # Treatments
│   ├── gruppo/                 # Collaborative groups & invitations
│   ├── analisi_telaino/        # Telaino AI analysis
│   ├── mappa/                  # Full map view
│   └── (root)/                 # Dashboard, Settings, Splash, Chat,
│                               #  VoiceCommand, MobileScanner
│
├── widgets/                    # Reusable components (15+)
│   ├── app_drawer.dart
│   ├── loading_indicator.dart
│   ├── google_voice_input_widget.dart
│   └── ...
│
├── providers/                  # Riverpod providers
│
└── utils/                      # Helpers, formatters, validators
```

### Assets

```
assets/
├── fonts/          # Caveat, Quicksand, Poppins (TTF)
├── images/
│   ├── backgrounds/
│   ├── icons/
│   └── illustrations/
├── sounds/         # Voice feedback audio files
└── models/
    └── bee_detector.tflite   # YOLOv8-seg quantised model
```

---

## Key Features

### Apiary Management
- Full CRUD for **apiari** (apiaries) and **arnie** (hives)
- Hive status tracking, colour-coding, and geo-location
- Interactive **map** view using `flutter_map` (OpenStreetMap tiles)

### Queen Monitoring
- Queen genealogy and status tracking
- Automatic queen fetch from server on every arnia load

### Hive Inspections (`controllo_arnia`)
- Structured inspection forms (telaini, health, weight, notes)
- Telaini config stored as JSON within the inspection record
- Full offline support via SQLite

### Honey Production
- Melario lifecycle (create → harvest → jar)
- Smielatura (extraction) and Invasettamento (jarring) workflows
- Export to PDF/CSV

### Treatments & Flowering
- Sanitary treatment scheduling and history
- Flowering event tracking and confirmation by multiple users

### Payments & Sales
- Automatic payment creation when adding equipment/maintenance with cost > 0
- Sales tracking with client management and invoice export

### Collaborative Groups
- Multi-user apiaries with invitation system
- Shared data, role-based access

---

## Data Storage Strategy

The app maintains **two independent local stores** — mixing them is a common source of bugs:

| Store | Used for | Access pattern |
|---|---|---|
| **SharedPreferences** | Apiari, Arnie, Melari, Regine | `StorageService.getStoredData('key')` |
| **SQLite (sqflite)** | Controlli, Analisi Telaini | `ControlloService` / `ControlloArniaDao` |

### Critical Patterns

**SQLite Bool/Int pitfall** — sqflite persists Dart `bool` as `INTEGER` 0/1. Every DAO read method applies `_convertBools()` before returning data. Skipping this causes `TypeError: type 'int' is not a subtype of type 'bool'` at runtime.

**Schema-safe sync** — `syncFromServer()` calls `DatabaseHelper.getTableColumns()` (via `PRAGMA table_info`) to strip server fields absent from the local schema. This prevents `DatabaseException` when the backend adds columns before the app migration runs.

**Offline-first cache** — `ApiService` tries the network first, falls back to `ApiCacheHelper` when offline, and persists successful responses for future offline use.

---

## AI & Voice Features

### Bee Detector (`bee_detection_service.dart`)
- Model: **YOLOv8-seg** quantised to TFLite (`assets/models/bee_detector.tflite`)
- Classes detected: `bees (0)`, `drone (1)`, `queenbees (2)`, `royal cell (3)`
- Used in `AnalisiTelainoScreen` to count frame contents from camera photos

### Voice Command Pipeline
```
Microphone input
      │
      ▼
speech_to_text / google_speech   ← BeeVocabularyCorrecto applies domain correction
      │
      ▼
VoiceDataProcessor (Gemini API)  ← extracts structured fields from free-form speech
      │
      ▼
VoiceEntryVerificationScreen     ← user reviews & confirms parsed data
      │
      ▼
StorageService / ControlloService
```

### AI Integrations
- **Gemini API** — natural language → structured beekeeping data extraction
- **Google Speech-to-Text** — high-accuracy STT with Italian bee-vocabulary correction
- **Wit.ai** — alternative NLU backend (configurable)

---

## Backend Integration

The Django backend exposes a DRF REST API with JWT authentication.

### Key Endpoints

| Resource | List / Create | Retrieve / Update / Delete |
|---|---|---|
| Apiari | `GET/POST /api/v1/apiari/` | `GET/PUT/DELETE /api/v1/apiari/{id}/` |
| Arnie | `GET/POST /api/v1/arnie/` | `GET/PUT/DELETE /api/v1/arnie/{id}/` |
| Controlli | `GET/POST /api/v1/controlli/` | `GET /api/v1/arnie/{id}/controlli/` |
| Regine | `POST /api/v1/regine/` | `GET /api/v1/arnie/{id}/regina/` |
| Melari | `GET/POST /api/v1/melari/` | `GET/PUT/DELETE /api/v1/melari/{id}/` |
| Analisi Telaini | `GET/POST /api/v1/analisi-telaini/` | — |
| Trattamenti | `GET/POST /api/v1/trattamenti/` | — |
| Fioriture | `GET/POST /api/v1/fioriture/` | — |
| Pagamenti | `GET/POST /api/v1/pagamenti/` | — |
| Vendite | `GET/POST /api/v1/vendite/` | — |

Authentication header: `Authorization: Token <jwt_token>`

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.0.0
- Android Studio / Xcode (for device builds)
- Access to the Django backend (or run it locally)

### Setup

```bash
# 1. Clone the repository
git clone <repo-url>
cd Apiary_app

# 2. Install dependencies
flutter pub get

# 3. Configure the API base URL
#    Edit lib/constants/api_constants.dart
#    Set: const String baseUrl = 'https://cible99.pythonanywhere.com';

# 4. (Optional) Add Google Cloud credentials for Speech-to-Text
#    Edit lib/config/google_credentials.dart

# 5. Run the app
flutter run
```

---

## Build & Release

```bash
# Debug run
flutter run

# Run tests
flutter test

# Android release APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS release
flutter build ios --release

# Web
flutter build web --release
```

---

## Related Repositories

| Repository | Description |
|---|---|
| `Apiary` | Django 4.2 + DRF backend — deployed on PythonAnywhere |
| `Apiary_app` | This Flutter mobile application |

---

## License

MIT License — see `LICENSE` for details.

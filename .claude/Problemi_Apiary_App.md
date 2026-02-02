# Problemi in Apiary App - Audit Completo

> Ultimo aggiornamento: 02/02/2026
> Questo file documenta tutti i problemi trovati nell'app Flutter, organizzati per gravita'.
> Usalo come riferimento per le sessioni di fix future.

---

## STATO FIX GIA' APPLICATE

Queste fix sono gia' state applicate nella sessione del 02/02/2026:

- [x] **Overflow pulsante "Sincronizza"** in `settings_screen.dart:304-324` - Wrappato secondo bottone in `Expanded`
- [x] **Conteggio membri/apiari sempre 0** in `gruppo.dart` + `gruppo_service.dart` - Aggiunti campi `membriCountFromApi`/`apiariCountFromApi` con fallback
- [x] **Navigazione drawer Impostazioni** in `drawer_widget.dart:195` - `pushNamed` -> `pushReplacementNamed`
- [x] **Navigazione drawer Voice Command** in `drawer_widget.dart:224` - `pushNamed` -> `pushReplacementNamed`

---

## 1. ERRORI DI COMPILAZIONE (119 errori da `flutter analyze`)

Questi errori impediscono la compilazione di parti del progetto. I file principali dell'app (schermate, servizi core) compilano correttamente, ma questi moduli secondari no.

### 1.1 `lib/database/sync_service.dart` - 7 errori

**Problema**: Import mancante e accesso errato ai tipi.

```
error - Undefined name 'ApiConstants' (righe 93, 114, 133)
error - The method 'toJson' isn't defined for the type 'Map' (riga 128)
error - The getter 'id' isn't defined for the type 'Map<String, dynamic>' (righe 133, 137, 139)
```

**Causa**: `ApiConstants` non e' importato. Il codice tratta `Map<String, dynamic>` come se fosse un oggetto model con proprieta' `.id` e metodo `.toJson()`, ma e' una mappa - deve usare `['id']` e non ha bisogno di `.toJson()`.

**Fix necessaria**:
- Aggiungere `import '../constants/api_constants.dart';` in cima al file
- Cambiare `.id` in `['id']`
- Rimuovere `.toJson()` (la mappa e' gia' serializzabile)

---

### 1.2 `lib/providers/auth_provider.dart` - 8 errori

**Problema**: Type mismatch e import mancanti.

```
error - The argument type 'AuthStateNotifier' can't be assigned to the parameter type 'AuthService' (riga 60)
error - Undefined name 'ApiConstants' (righe 61, 76, 88, 142)
error - Undefined name 'http' (righe 178, 183)
```

**Causa**: Il provider Riverpod usa `AuthStateNotifier` ma i servizi aspettano `AuthService`. Manca l'import di `ApiConstants` e del package `http`.

**Fix necessaria**:
- Aggiungere import di `api_constants.dart` e `package:http/http.dart`
- Risolvere il type mismatch: o il provider deve esporre `AuthService`, oppure i servizi devono accettare `AuthStateNotifier`

---

### 1.3 `lib/providers/apiario_provider.dart` - 5 errori

**Problema**: Stessi problemi di auth_provider.

```
error - The argument type 'AlwaysAliveRefreshable<AuthStateNotifier>' can't be assigned to 'ProviderListenable<AuthService>' (riga 14)
error - Undefined name 'ApiConstants' (righe 55, 83, 123, 160)
```

**Fix necessaria**: Aggiungere import `api_constants.dart`, risolvere type mismatch provider.

---

### 1.4 `lib/providers/sync_provider.dart` - 2 errori

```
error - Same AlwaysAliveRefreshable type mismatch (riga 9)
error - Undefined class 'StreamSubscription' (riga 24)
```

**Fix necessaria**: Import `dart:async` per `StreamSubscription`, risolvere type mismatch.

---

### 1.5 `lib/services/background_sync_service.dart` - 11 errori

**Problema CRITICO**: Chiama un metodo factory che non esiste.

```
error - The method 'fromToken' isn't defined for the type 'ApiService' (riga 190)
error - Undefined name 'Platform' (righe 60, 65, 70)
error - The function 'Connectivity' isn't defined (riga 143)
error - The name 'StreamController' isn't a class (riga 156)
error - The name 'MyApp' isn't a class (riga 172)
```

**Causa**: `ApiService` ha solo il costruttore `ApiService(this._authService)` ma il background sync tenta `ApiService.fromToken(token, refreshToken)` che non esiste. Inoltre mancano import di `dart:io` (Platform), `dart:async` (StreamController), e il package connectivity.

**Fix necessaria**:
- Implementare factory `ApiService.fromToken()` in `api_service.dart`, OPPURE
- Ristrutturare il background sync per usare il costruttore esistente
- Aggiungere tutti gli import mancanti

---

### 1.6 `lib/services/sensor_service.dart` - 15 errori

**Problema**: Package non presenti nel `pubspec.yaml`.

```
error - Target of URI doesn't exist: 'package:sensors_plus/sensors_plus.dart'
error - Target of URI doesn't exist: 'package:light/light.dart'
error - Target of URI doesn't exist: 'package:weather/weather.dart'
error - Undefined class 'UserAccelerometerEvent', 'GyroscopeEvent', 'AccelerometerEvent'
error - Undefined class 'WeatherFactory', 'Weather', 'Light'
```

**Fix necessaria**: Aggiungere al `pubspec.yaml`:
```yaml
sensors_plus: ^4.0.0
light: ^3.0.0
weather: ^3.1.1
```
Oppure rimuovere il servizio se non e' necessario.

---

### 1.7 `lib/services/notification_service.dart` - 11 errori

```
error - Target of URI doesn't exist: 'package:flutter_native_timezone/flutter_native_timezone.dart'
error - Target of URI doesn't exist: 'package:flutter_app_badger/flutter_app_badger.dart'
error - The method 'notify' isn't defined for the type 'ServiceInstance'
error - The method 'cancelNotificationsByGroupKey' isn't defined
```

**Fix necessaria**: Aggiungere al `pubspec.yaml`:
```yaml
flutter_native_timezone: ^2.0.0
flutter_app_badger: ^1.3.0
```

---

### 1.8 `lib/services/export_service.dart` - 11 errori

```
error - Target of URI doesn't exist: 'package:pdf/pdf.dart'
error - Target of URI doesn't exist: 'package:pdf/widgets.dart'
error - Target of URI doesn't exist: 'package:csv/csv.dart'
error - Undefined name 'PdfColors'
error - The name 'ListToCsvConverter' isn't a class
```

**Fix necessaria**: Aggiungere al `pubspec.yaml`:
```yaml
pdf: ^3.10.0
csv: ^5.1.1
```

---

### 1.9 `lib/services/camera_service.dart` - 1 errore

```
error - Target of URI doesn't exist: 'package:flutter_image_compress/flutter_image_compress.dart'
```

**Fix necessaria**: Aggiungere `flutter_image_compress: ^2.1.0` al `pubspec.yaml`.

---

### 1.10 `lib/screens/voice_debug_screen.dart` - 6 errori

```
error - Target of URI doesn't exist: '../services/simple_record_service.dart'
error - Target of URI doesn't exist: '../services/simple_voice_input_manager.dart'
error - Undefined class 'SimpleRecordService', 'SimpleVoiceInputManager'
```

**Causa**: I file sorgente referenziati non esistono nel progetto. Probabilmente sono stati rimossi o rinominati senza aggiornare questo schermo.

**Fix necessaria**: Creare i file mancanti oppure aggiornare gli import ai servizi corretti (es. `wit_speech_recognition_service.dart`, `voice_input_manager.dart`).

---

### 1.11 `lib/widgets/` - Card widgets con DateFormatter mancante

```
error - Target of URI doesn't exist: '../utils/date_formatter.dart'  (arnia_card_widget, controllo_card_widget, apiario_card_widget)
error - Undefined name 'DateFormatter'
```

**Causa**: La classe `DateFormatter` in `utils/date_formatter.dart` non esiste.

**Fix necessaria**: Creare `lib/utils/date_formatter.dart` con i metodi di formattazione date usati dai widget, oppure usare `intl` package (`DateFormat`).

---

### 1.12 `lib/widgets/weather_widget.dart` - 9 errori

```
error - Target of URI doesn't exist: 'package:weather/weather.dart'
error - Undefined class 'Weather'
error - Null safety issues on weather properties
```

**Causa**: Stessa dipendenza mancante di `sensor_service.dart`.

---

## 2. PROBLEMI CRITICI A RUNTIME (non errori di compilazione ma crash)

### 2.1 `lib/models/regina.dart` - Manca `fromJson()`

**File**: `lib/models/regina.dart`

**Problema**: Il modello ha solo `fromMap()`/`toMap()` per il database SQLite locale. Non ha `fromJson()`/`toJson()` per le risposte API REST. Se un endpoint API restituisce dati di regine, il parsing fallira'.

**Impatto**: Lo schermo lista regine potrebbe crashare se carica dati dall'API invece che dal DB locale.

**Fix necessaria**: Aggiungere factory `Regina.fromJson(Map<String, dynamic> json)` che gestisca i campi snake_case dall'API Django, e `toJson()` per l'invio.

---

### 2.2 `lib/models/voice_entry.dart` - Variable shadowing in `toJson()`

**File**: `lib/models/voice_entry.dart` (riga ~152)

**Problema**: Nel metodo `toJson()`, la variabile locale `data` sovrascrive il campo della classe:
```dart
if (data != null) data['data'] = DateFormat('yyyy-MM-dd').format(this.data!);
```
Dopo questa riga, `data` si riferisce alla mappa locale, non al campo dell'oggetto. Le operazioni successive sulla mappa sono corrette, ma il nome e' confuso e potrebbe portare a bug futuri.

**Fix necessaria**: Rinominare la variabile locale (es. `result` o `jsonMap`).

---

### 2.3 Modelli con `double.parse()` unsafe

**File interessati**:
- `lib/models/apiario.dart` (righe 37-38) - `latitudine`, `longitudine`
- `lib/models/fioritura.dart` (righe 40-41) - `latitudine`, `longitudine`
- `lib/models/smielatura.dart` (riga 38) - campo numerico

**Problema**: Usano `double.parse()` che lancia `FormatException` su dati invalidi. Il LEGGIMI_PROGETTO.md dice esplicitamente di usare `double.tryParse()`:
> **`double` da JSON**: Il server puo' restituire un numero come `"10.50"` (stringa) o `10.5` (numero). Usa SEMPRE: `double.tryParse(json['campo'].toString()) ?? 0.0`

**Fix necessaria**: Sostituire `double.parse(...)` con `double.tryParse(...) ?? 0.0` (o `?? null` per campi nullable).

---

## 3. PROBLEMI DI ROUTING

### 3.1 Route definite ma non gestite (12 route orfane)

**File**: `lib/constants/app_constants.dart` vs `lib/utils/route_generator.dart`

Queste route sono definite in `app_constants.dart` ma NON hanno un `case` corrispondente in `route_generator.dart`. Navigare verso di esse produrra' la schermata di errore 404:

| Costante | Path | Note |
|----------|------|------|
| `reginaCreateRoute` | `/regina/create` | |
| `trattamentoDetailRoute` | `/trattamento/detail` | |
| `tipiTrattamentoRoute` | `/tipi-trattamento` | |
| `melarioDetailRoute` | `/melario/detail` | |
| `smielaturaListRoute` | `/smielature` | |
| `smielaturaCreateRoute` | `/smielatura/create` | |
| `smielaturaDetailRoute` | `/smielatura/detail` | |
| `gruppoMembriRoute` | `/gruppo/membri` | |
| `gruppoApiariRoute` | `/gruppo/apiari` | |
| `mappaApiariRoute` | `/mappa/apiari` | |
| `mappaMeteoRoute` | `/mappa/meteo` | |
| `voiceVerificationRoute` | `/voice/verification` | |

**Fix necessaria**: Aggiungere i `case` mancanti in `route_generator.dart` con le schermate corrispondenti, oppure rimuovere le costanti inutilizzate.

---

### 3.2 Route hardcoded senza costante

**File**: `lib/utils/route_generator.dart` (riga 106)

La route `'/qr_scanner'` e' hardcoded nel route generator ma non e' definita come costante in `app_constants.dart`.

**Fix necessaria**: Aggiungere `static const String qrScannerRoute = '/qr_scanner';` in `app_constants.dart`.

---

### 3.3 Route duplicate/alias

**File**: `lib/constants/app_constants.dart`

- `arniaCreateRoute` (riga 27) e `creaArniaRoute` (riga 28) puntano entrambe a `/arnia/create`
- `trattamentoCreateRoute` (riga 39) e `nuovoTrattamentoRoute` (riga 40) puntano entrambe a `/trattamento/create`

Il route_generator gestisce solo uno dei due alias. Questo crea confusione.

**Fix necessaria**: Rimuovere i duplicati e usare un solo nome per route.

---

## 4. PROBLEMI NEI SERVICES

### 4.1 Gestione paginazione inconsistente

**Pattern corretto** (usato in `controllo_service.dart`, `attrezzatura_service.dart`, `pagamento_service.dart`):
```dart
if (response is List) {
  return response;
} else if (response is Map && response.containsKey('results')) {
  return response['results'];
}
```

**Pattern errato** (usato in `mcp_service.dart` ~16 occorrenze, `gruppo_service.dart` riga 19):
```dart
final List<dynamic> data = response['results'] ?? [];  // CRASH se response e' una List
```

**Fix necessaria**: Standardizzare il pattern di gestione paginazione in tutti i service.

---

### 4.2 `chat_service.dart:37` - API Key hardcoded

**Problema**: La chiave API Gemini `AIzaSyCgoAfYh-MjTXm9_RzHEKhlfWAxXzUFNGs` e' hardcoded nel sorgente.

**Rischio**: Chiunque abbia accesso al repo puo' usare la chiave. Se il repo e' pubblico, la chiave e' compromessa.

**Fix necessaria**: Spostare in variabile d'ambiente o file di configurazione non committato (`.env`).

---

### 4.3 `chat_service.dart:153` - Accesso nested JSON unsafe

```dart
var botResponse = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
```

Nessun null-check. Se l'API Gemini cambia formato risposta o restituisce errore, crash.

**Fix necessaria**: Aggiungere null-checks o try-catch specifico.

---

## 5. PROBLEMI NEI MODELLI

### 5.1 Booleani senza default null-safe

**File interessati**: `apiario.dart`, `arnia.dart`, `controllo_arnia.dart`, `fioritura.dart`

**Problema**: Campi booleani estratti dal JSON senza `?? false`:
```dart
// Esempio in controllo_arnia.dart
presenzaRegina: json['presenza_regina'],  // null se il campo manca -> crash
```

**Fix necessaria**: Aggiungere `?? false` a tutti i campi booleani nel `fromJson()`.

---

### 5.2 `toJson()` incompleti in diversi modelli

**File interessati**: `pagamento.dart`, `quota_utente.dart`, `attrezzatura.dart`, `spesa_attrezzatura.dart`, `manutenzione.dart`

**Problema**: Il `toJson()` non include tutti i campi che `fromJson()` legge (campi display, nomi relazioni, ecc.). Questo non e' un problema per le POST (dove quei campi sono read-only), ma puo' causare problemi con il caching locale.

---

### 5.3 `smielatura.dart:36` - Lista senza null check

```dart
melari: List<int>.from(json['melari']),  // crash se json['melari'] e' null
```

**Fix necessaria**: `melari: json['melari'] != null ? List<int>.from(json['melari']) : []`

---

### 5.4 `DateTime.parse()` senza fallback

**File**: `user.dart` (righe 44-46)

```dart
dateJoined: json['date_joined'] != null ? DateTime.parse(json['date_joined']) : null,
```

Usa `DateTime.parse()` che lancia eccezione su formato invalido. Meglio `DateTime.tryParse()`.

---

## 6. PROBLEMI NELLE SCHERMATE

### 6.1 `mappa_screen.dart:305-312` - Logica incompleta

Il metodo `_userBelongsToGroup()` ritorna sempre `true`:

```dart
bool _userBelongsToGroup(int gruppoId) {
  // TODO: implementare logica reale
  return true;
}
```

**Impatto**: Tutti gli apiari condivisi vengono mostrati sulla mappa indipendentemente dall'appartenenza al gruppo.

---

### 6.2 TODO incompleti nelle schermate

| File | Riga | Descrizione |
|------|------|-------------|
| `apiario_detail_screen.dart` | ~129 | Navigazione a creazione arnia incompleta |
| `arnia_detail_screen.dart` | ~135 | `_navigateToReginaCreate()` TODO |
| `arnia_detail_screen.dart` | ~139 | `_navigateToMelarioCreate()` TODO |
| `regina_detail_screen.dart` | ~132, 146 | Feature implementation TODO |

---

### 6.3 `quote_screen.dart` - Form senza validazione

Il dialog `_showAddDialog()` (righe 260-290) ha `TextFormField` senza validators. L'utente puo' inviare dati vuoti o invalidi.

---

### 6.4 Potenziali overflow layout

| File | Zona | Problema |
|------|------|----------|
| `mappa_screen.dart:622` | Row con children illimitati | Manca Expanded/Flexible |
| `apiario_detail_screen.dart:596-641` | Row nested in Column | Possibile overflow su schermi piccoli |
| `arnia_detail_screen.dart:418-451` | Row in card | Children senza vincoli di larghezza |

---

## 7. PROBLEMI DI CONFIGURAZIONE

### 7.1 Import inutilizzato in `app.dart`

**File**: `lib/app.dart:11`

```dart
import 'widgets/drawer_widget.dart';  // WARNING: unused_import
```

---

### 7.2 Import inutilizzati in `database_helper.dart`

**File**: `lib/database/database_helper.dart`

Righe 6-14: Import di 9 modelli (`apiario.dart`, `arnia.dart`, `controllo_arnia.dart`, `regina.dart`, `fioritura.dart`, `trattamento.dart`, `melario.dart`, `smielatura.dart`, `app_constants.dart`) tutti inutilizzati.

---

### 7.3 Asset potenzialmente mancante

**File**: `lib/constants/theme_constants.dart:170`

Referenzia `'assets/images/backgrounds/paper_texture.png'`. Verificare che il file esista e sia dichiarato nel `pubspec.yaml` sotto `assets:`.

---

## 8. RIEPILOGO PRIORITA'

### Immediato (blocca funzionalita'):
1. Creare `lib/utils/date_formatter.dart` (blocca 3 widget card)
2. Fix `sync_service.dart` - import + accesso Map
3. Fix providers (auth, apiario, sync) - import + type mismatch
4. Fix `voice_debug_screen.dart` - import servizi mancanti

### Alta priorita' (crash potenziali):
5. Aggiungere `fromJson()` a `regina.dart`
6. Fix `double.parse()` -> `double.tryParse()` in apiario, fioritura, smielatura
7. Fix `smielatura.dart` lista null check
8. Fix `background_sync_service.dart` - `ApiService.fromToken()` non esiste
9. Fix booleani senza default in 4 modelli

### Media priorita' (funzionalita' degradata):
10. Aggiungere package mancanti al `pubspec.yaml` (sensor, notification, export, camera)
11. Standardizzare gestione paginazione nei service
12. Completare route mancanti nel route_generator
13. Spostare API key Gemini fuori dal codice

### Bassa priorita' (qualita' codice):
14. Rimuovere print() di debug ovunque
15. Rimuovere import inutilizzati
16. Completare TODO nelle schermate
17. Aggiungere validazione a quote_screen
18. Rimuovere route duplicate in app_constants

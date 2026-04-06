# Modulo 09 — Interfacce Astratte e Mixins

## 9.1 Classi Astratte come Interfacce

In Dart non esiste la parola chiave `interface` di Java. Si usano le `abstract class`:

```dart
abstract class Sincronizzabile {
  // Metodo astratto: NESSUNA implementazione — obbliga le sottoclassi
  Future<void> sincronizza();
  Future<bool> haModifiche();

  // Metodo concreto: implementazione di default — le sottoclassi possono sovrascrivere
  void logSincronizzazione() {
    print('[SYNC] ${runtimeType}: ${DateTime.now()}');
  }
}

// Implementazione concreta
class ApiarioService extends Sincronizzabile {
  @override
  Future<void> sincronizza() async {
    logSincronizzazione(); // usa il metodo concreto ereditato
    // ... logica specifica
  }

  @override
  Future<bool> haModifiche() async {
    return await _checkLocalChanges();
  }
}
```

Non puoi istanziare una classe astratta:
```dart
var s = Sincronizzabile(); // ERRORE
var a = ApiarioService();  // OK
```

---

## 9.2 `implements` — Implementare un Contratto

Con `implements`, una classe si impegna a fornire tutti i metodi dell'interfaccia,
ma **non eredita l'implementazione**:

```dart
abstract class AuthTokenProvider {
  Future<String?> getToken();
  Future<bool> refreshToken();
}

// AuthService implementa il contratto — deve fornire entrambi i metodi
class AuthService extends ChangeNotifier implements AuthTokenProvider {
  String? _token;

  @override
  Future<String?> getToken() async {
    // verifica se il token è valido, altrimenti lo rinnova
    if (_token == null) await refreshToken();
    return _token;
  }

  @override
  Future<bool> refreshToken() async {
    // ... logica di refresh
    return true;
  }
}
```

**Nel progetto** — `lib/services/auth_token_provider.dart` + `lib/services/auth_service.dart`.
Questo permette ad `ApiService` di accettare **qualsiasi** implementatore:

```dart
class ApiService {
  final AuthTokenProvider _authService; // non sa se è AuthService o qualcos'altro

  ApiService(this._authService); // dipendenza per interfaccia, non implementazione
}

// Funziona sia con AuthService...
ApiService(authService);

// ...sia con implementazioni mock per i test
ApiService(MockAuthProvider());
```

---

## 9.3 `extends` vs `implements` — Quando usare cosa

```
                 extends                    implements
                 ───────                    ──────────
Eredita codice?  Sì                         No
Quante?          Una sola                   Multiple
Relazione        "È un tipo di"             "Si comporta come"
Tipico uso       Riutilizzo implementazione Contratto/polimorfismo
```

Esempio pratico:

```dart
// "Extends": un ApiarioServicService È UN ChangeNotifier
class ApiarioService extends ChangeNotifier { ... }

// "Implements": AuthService si comporta come AuthTokenProvider
class AuthService extends ChangeNotifier implements AuthTokenProvider { ... }

// Combinato: può fare entrambe le cose
class ChatService extends ChangeNotifier implements VoiceDataProcessor { ... }
```

---

## 9.4 Multiple Interfaces

Una classe può implementare più interfacce:

```dart
abstract class Caricabile {
  Future<void> carica();
}

abstract class Salvabile {
  Future<void> salva();
}

// Implementa entrambe
class ApiarioRepository implements Caricabile, Salvabile {
  @override
  Future<void> carica() async { /* ... */ }

  @override
  Future<void> salva() async { /* ... */ }
}
```

---

## 9.5 Mixin — Riuso di Comportamento

I Mixin sono blocchi di codice riutilizzabile che puoi "mescolare" in più classi.
Non sono classi complete — non si istanziano direttamente.

```dart
mixin Loggabile {
  // Metodi che vengono "donati" alle classi che usano questo mixin
  void logInfo(String msg) => print('[INFO] $msg');
  void logError(String msg) => print('[ERROR] $msg');
}

mixin Cacheable {
  final Map<String, dynamic> _cache = {};

  void metti(String chiave, dynamic valore) => _cache[chiave] = valore;
  dynamic prendi(String chiave) => _cache[chiave];
  void svuotaCache() => _cache.clear();
}

// Le classi usano i mixin con 'with'
class ApiarioService extends ChangeNotifier with Loggabile, Cacheable {
  Future<List<Apiario>> getAll() async {
    // Usa metodi da Loggabile
    logInfo('Caricamento apiari...');

    // Usa metodi da Cacheable
    var cached = prendi('apiari');
    if (cached != null) return cached;

    var result = await _api.getApiari();
    metti('apiari', result);
    return result;
  }
}
```

---

## 9.6 `mixin on` — Vincolo sul Tipo Base

Un mixin può richiedere di essere usato solo su classi che estendono un certo tipo:

```dart
// Questo mixin funziona SOLO su ChangeNotifier (o sottoclassi)
mixin VoiceDataProcessor on ChangeNotifier {
  // Può chiamare notifyListeners() perché sa che la classe base è ChangeNotifier
  void _notificaAggiornamento() {
    notifyListeners(); // OK — ChangeNotifier ha questo metodo
  }

  Future<VoiceEntry?> processVoiceInput(String text);
  String? get error;
  bool get lastCallWasRateLimit => false;
  bool get lastCallWasNetworkError => false;
}
```

**Nel progetto** — `lib/services/voice_data_processor.dart`:
```dart
mixin VoiceDataProcessor on ChangeNotifier {
  Future<VoiceEntry?> processVoiceInput(String text);
  String? get error;
  bool get lastCallWasRateLimit => false;
  bool get lastCallWasNetworkError => false;
}
```

---

## 9.7 Differenza tra Mixin e Interfaccia

| | `abstract class` (interfaccia) | `mixin` |
|--|-------------------------------|---------|
| Scopo | Definire contratto | Riusare comportamento |
| Implementazione | Solo abstract o metodi default | Sempre implementato |
| Si istanzia? | No | No |
| Si "usa" con | `implements` o `extends` | `with` |
| Campi di stato? | Sì | Sì (ma attenzione) |

---

## 9.8 `ChangeNotifier` — Il Mixin Base di Flutter

Nel progetto quasi tutti i servizi estendono `ChangeNotifier`, che è una classe con
funzionalità di notifica (observer pattern):

```dart
class AuthService extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> login() async {
    _isLoading = true;
    notifyListeners(); // avvisa tutti i widget che "ascoltano" questo servizio

    await _eseguiLogin();

    _isLoading = false;
    notifyListeners(); // avvisa di nuovo
  }
}

// In Flutter, un Consumer<AuthService> si ricostruisce ogni volta
// che viene chiamato notifyListeners()
```

---

## 9.9 Polimorfismo in Azione

Con interfacce e abstract class puoi scrivere codice che funziona con qualsiasi
implementazione — senza conoscere i dettagli:

```dart
// Funzione che accetta QUALSIASI AuthTokenProvider
Future<void> eseguiChiamataAPI(AuthTokenProvider auth) async {
  final token = await auth.getToken(); // funziona con qualsiasi implementazione
  // ...
}

// Funziona con AuthService
eseguiChiamataAPI(authService);

// Funziona con una implementazione di test
eseguiChiamataAPI(FakeAuthProvider(token: 'test-token'));
```

**Nel progetto** — `lib/services/api_service.dart`:
```dart
class ApiService {
  final AuthTokenProvider _authService; // polimorfismo: qualsiasi implementazione

  ApiService(this._authService);

  factory ApiService.fromToken(String token, String refreshToken) {
    // _StaticTokenProvider implementa AuthTokenProvider
    return ApiService(_StaticTokenProvider(token, refreshToken));
  }
}
```

---

## 9.10 Esempio Completo — Architettura dei Servizi

```
AuthTokenProvider (interfaccia astratta)
├── getToken() → Future<String?>
└── refreshToken() → Future<bool>

Implementazioni:
├── AuthService extends ChangeNotifier implements AuthTokenProvider
│   └── Usa SharedPreferences, HttpClient
└── _StaticTokenProvider implements AuthTokenProvider
    └── Usa token fisso (per background sync)

Dipendenti:
└── ApiService(AuthTokenProvider)
    └── Funziona con qualsiasi implementazione
```

---

## Esercizi

1. In `lib/services/auth_token_provider.dart`:
   - Quali metodi definisce?
   - In `lib/services/auth_service.dart`, come vengono implementati?

2. In `lib/services/voice_data_processor.dart`:
   - È un mixin o una classe astratta?
   - Qual è il vincolo `on`? Perché è necessario?
   - Quale classe usa questo mixin? (cerca con `with VoiceDataProcessor`)

3. Crea una classe astratta `RicercabilePer<T>` con metodo:
   `Future<List<T>> cerca(String query)`
   
   Poi implementala con `ApiarioRepository` che:
   - Cerca apiari per nome nel database locale
   - Restituisce `Future<List<Apiario>>`

---

**Prossimo modulo:** [10 — Extensions e Enums](10_extensions_enums.md)

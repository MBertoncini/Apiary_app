# Modulo 13 — Pattern di Design

## 13.1 Cos'è un Design Pattern?

Un design pattern è una soluzione riutilizzabile a un problema ricorrente nello sviluppo
software. Non è codice da copiare — è un approccio che si adatta al contesto.

In questo progetto ne vediamo 6 fondamentali:
1. **Singleton** — una sola istanza globale
2. **Factory** — costruzione controllata degli oggetti
3. **Repository** — astrazione dell'accesso ai dati
4. **Observer** (ChangeNotifier) — notifiche di cambiamento
5. **Proxy** (ProxyProvider) — dipendenze tra servizi
6. **Strategy** (interfacce) — algoritmi intercambiabili

---

## 13.2 Singleton

**Problema:** Vuoi che esista una sola istanza di una classe (database, configurazione).

```dart
class DatabaseHelper {
  // Istanza unica statica
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  // Factory: restituisce SEMPRE la stessa istanza
  factory DatabaseHelper() => _instance;

  // Costruttore privato: nessuno può creare istanze dall'esterno
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!; // già inizializzata
    _database = await _initDatabase();         // init lazy
    return _database!;
  }
}

// Ogni chiamata a DatabaseHelper() ritorna lo stesso oggetto
var db1 = DatabaseHelper(); // istanza
var db2 = DatabaseHelper(); // stessa istanza
assert(identical(db1, db2)); // true
```

**Nel progetto** — `lib/database/database_helper.dart`

---

## 13.3 Factory Method

**Problema:** Vuoi controllare la creazione di oggetti, con logica complessa o varianti.

```dart
// Il factory method sceglie la classe concreta da istanziare
abstract class Esportatore {
  static Esportatore crea(String formato) {
    switch (formato) {
      case 'pdf':   return EsportatorePDF();
      case 'csv':   return EsportatoreCSV();
      case 'json':  return EsportatoreJSON();
      default:      throw ArgumentError('Formato non supportato: $formato');
    }
  }

  Future<Uint8List> esporta(List<Apiario> apiari);
}

class EsportatorePDF extends Esportatore {
  @override
  Future<Uint8List> esporta(List<Apiario> apiari) async {
    // ... crea PDF
  }
}

// Uso:
var esportatore = Esportatore.crea('pdf');
var file = await esportatore.esporta(apiari);
```

**Nel progetto** — ogni `factory Model.fromJson()` è un factory method,
e `ApiService.fromToken()` è un factory per scenari specifici.

---

## 13.4 Repository

**Problema:** Vuoi separare la logica di business dall'accesso ai dati (HTTP, SQLite, mock).

```dart
// Interfaccia del repository — non sa DOVE sono i dati
abstract class ApiarioRepository {
  Future<List<Apiario>> getAll();
  Future<Apiario?> getById(int id);
  Future<int> salva(Apiario apiario);
  Future<void> elimina(int id);
}

// Implementazione locale (SQLite)
class ApiarioLocalRepository implements ApiarioRepository {
  final DatabaseHelper _db;
  ApiarioLocalRepository(this._db);

  @override
  Future<List<Apiario>> getAll() async {
    final rows = await _db.query('apiari', orderBy: 'nome ASC');
    return rows.map((r) => Apiario.fromJson(r)).toList();
  }

  @override
  Future<Apiario?> getById(int id) async {
    final rows = await _db.query('apiari', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Apiario.fromJson(rows.first);
  }

  // ...
}

// Implementazione remota (API HTTP)
class ApiarioRemoteRepository implements ApiarioRepository {
  final ApiService _api;
  ApiarioRemoteRepository(this._api);

  @override
  Future<List<Apiario>> getAll() async {
    final response = await _api.get('/apiari/');
    // ... parsing
  }
  // ...
}

// Implementazione mock (per i test)
class ApiarioMockRepository implements ApiarioRepository {
  @override
  Future<List<Apiario>> getAll() async => [
    Apiario(id: 1, nome: 'Mock Nord', ...),
    Apiario(id: 2, nome: 'Mock Sud', ...),
  ];
  // ...
}
```

**Nel progetto** — i DAO (`lib/database/dao/`) seguono questo pattern
per SQLite. I `Service` lo estendono per API remote.

---

## 13.5 Observer (ChangeNotifier)

**Problema:** Quando i dati cambiano, l'UI deve aggiornarsi automaticamente.

```dart
// Soggetto (publisher) — il servizio notifica i cambiamenti
class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String user, String pass) async {
    _isAuthenticated = await _eseguiLogin(user, pass);
    notifyListeners(); // NOTIFICA: tutti i widget che ascoltano si ricostruiscono
  }
}

// Observer (subscriber) — il widget si ricostruisce alla notifica
class NavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // watch() si iscrive alle notifiche di AuthService
    final auth = context.watch<AuthService>();

    return auth.isAuthenticated
        ? _buildMenuPrincipale()
        : _buildLoginButton();
  }
}
```

**Nel progetto** — tutti i servizi in `lib/services/` estendono `ChangeNotifier`.

---

## 13.6 Provider / Dependency Injection

**Problema:** Le classi hanno dipendenze tra loro. Come fornire le dipendenze
in modo testabile e flessibile?

```dart
// lib/provider_setup.dart — configurazione centrale delle dipendenze
List<SingleChildWidget> providers = [
  // 1. AuthService non dipende da nulla
  ChangeNotifierProvider<AuthService>(
    create: (_) => AuthService(),
  ),

  // 2. ApiService dipende da AuthService — ProxyProvider lo crea con la dipendenza
  ProxyProvider<AuthService, ApiService>(
    update: (context, authService, prevApiService) =>
        prevApiService ?? ApiService(authService),
    // - 'authService' è iniettato automaticamente dal framework
    // - 'prevApiService' è l'istanza precedente (riuso se già creata)
  ),

  // 3. SyncService dipende da ApiService E StorageService
  ProxyProvider2<ApiService, StorageService, SyncService>(
    update: (_, apiService, storageService, prev) =>
        prev ?? SyncService(apiService, storageService),
    dispose: (_, service) => service.dispose(),
  ),
];

// In un widget, si ottiene il servizio senza sapere come è creato:
final apiService = context.read<ApiService>();
```

---

## 13.7 Strategy (Interfacce Intercambiabili)

**Problema:** Vuoi poter cambiare l'algoritmo/implementazione a runtime
senza modificare chi la usa.

```dart
// Interfaccia della strategia
abstract class AuthTokenProvider {
  Future<String?> getToken();
  Future<bool> refreshToken();
}

// Strategia 1: token da sessione utente (uso normale)
class AuthService extends ChangeNotifier implements AuthTokenProvider {
  @override
  Future<String?> getToken() async => _token; // da SharedPreferences + refresh

  @override
  Future<bool> refreshToken() async { /* ... */ return true; }
}

// Strategia 2: token statico (per background sync)
class _StaticTokenProvider implements AuthTokenProvider {
  final String _token;
  final String _refreshToken;

  _StaticTokenProvider(this._token, this._refreshToken);

  @override
  Future<String?> getToken() async => _token; // statico, non si aggiorna

  @override
  Future<bool> refreshToken() async => false; // non può refreshare
}

// ApiService usa la strategia senza sapere quale è
class ApiService {
  final AuthTokenProvider _auth; // strategia iniettata
  ApiService(this._auth);

  factory ApiService.fromToken(String token, String refresh) {
    return ApiService(_StaticTokenProvider(token, refresh)); // strategia 2
  }
}
```

**Nel progetto** — `lib/services/auth_token_provider.dart` + `api_service.dart`.

---

## 13.8 Composizione vs Ereditarietà

Un principio fondamentale: **preferisci la composizione all'ereditarietà**.

```dart
// EREDITARIETÀ — accoppiamento forte, difficile da cambiare
class ApiarioServiceAvanzato extends ApiarioService {
  // Deve conoscere l'implementazione interna di ApiarioService
}

// COMPOSIZIONE — accoppiamento debole, flessibile
class ApiarioViewModel {
  final ApiarioRepository _repository; // composto, non ereditato
  final ConnectivityService _connectivity;

  ApiarioViewModel(this._repository, this._connectivity);

  Future<List<Apiario>> getApiari() async {
    if (!_connectivity.hasConnection) {
      return _repository.getAll(); // versione locale
    }
    return _repository.getAll(); // stessa interfaccia, implementazione diversa
  }
}
```

---

## 13.9 Schema Architetturale del Progetto

```
┌──────────────────────────────────────────────────┐
│                  UI LAYER                         │
│  Screens + Widgets                                │
│  (Consumer<T>, context.watch<T>())                │
└────────────────────┬─────────────────────────────┘
                     │ Provider (Observer Pattern)
┌────────────────────▼─────────────────────────────┐
│              SERVICE LAYER                        │
│  AuthService, ApiService, ChatService...          │
│  (ChangeNotifier + Strategy via interfaces)       │
└────────────────────┬─────────────────────────────┘
                     │ Repository Pattern
┌────────────────────▼─────────────────────────────┐
│              DATA LAYER                           │
│  DAO (SQLite) + ApiService (HTTP)                 │
│  (Factory per fromJson, Singleton per DB)         │
└──────────────────────────────────────────────────┘
```

---

## 13.10 Anti-Pattern da Evitare

```dart
// ANTI-PATTERN: God Class — fa troppe cose
class AppManager {
  void login() { ... }
  void caricaApiari() { ... }
  void sincronizza() { ... }
  void esporta() { ... }
  void inviaEmail() { ... }
  // 500 righe di codice...
}

// MEGLIO: responsabilità singola
class AuthService { void login() {...} }
class ApiarioService { void carica() {...} }
class SyncService { void sincronizza() {...} }

// ANTI-PATTERN: accesso globale con variabili globali
ApiService globalApi = ApiService(); // difficile da testare

// MEGLIO: Dependency Injection tramite Provider
final api = context.read<ApiService>(); // iniettato dal framework
```

---

## Esercizi

1. In `lib/provider_setup.dart`:
   - Quali servizi usano `ChangeNotifierProvider` vs `ProxyProvider`?
   - Perché `ApiService` usa `ProxyProvider` e non `ChangeNotifierProvider`?
   - Cosa fa il parametro `lazy: true` su `ChatService`?

2. In `lib/database/database_helper.dart`:
   - Identifica il pattern Singleton — quali sono i suoi componenti?
   - Perché il database viene inizializzato "lazy" (solo quando serve)?

3. Progetta (su carta o in codice) il pattern Repository per `Arnia`:
   - Interfaccia `ArniaRepository` con metodi CRUD
   - Implementazione `ArniaLocalRepository` che usa `DatabaseHelper`
   - Come passeresti da "solo locale" a "locale + remoto" senza cambiare i widget?

---

## Conclusione del Corso

Hai completato il corso Dart usando il progetto Apiary App come riferimento reale.

### Riepilogo dei Concetti Appresi

| Modulo | Concetto | Dove nel Progetto |
|--------|----------|-------------------|
| 01 | Tipi, var, final, const | Tutti i file |
| 02 | Funzioni, named params, closures | `validators.dart`, `provider_setup.dart` |
| 03 | Classi, ereditarietà, getter/setter | `auth_service.dart`, tutti i modelli |
| 04 | Null Safety, ??, ?., late | Tutti i modelli e servizi |
| 05 | List, Map, Set, operazioni funzionali | DAO, `api_service.dart` |
| 06 | Future, async/await, try/catch | Tutti i servizi |
| 07 | Factory, copyWith, const constructors | Tutti i modelli |
| 08 | Generics `<T>` | `database_helper.dart`, Future |
| 09 | Abstract, implements, mixin, with | `auth_token_provider.dart`, `voice_data_processor.dart` |
| 10 | Extensions, Enum avanzati | `osm_vegetazione.dart`, `chat_service.dart` |
| 11 | Stream, StreamController, StreamBuilder | `connectivity_service.dart` |
| 12 | Exception, try/catch, runZonedGuarded | `main.dart`, `auth_service.dart` |
| 13 | Singleton, Factory, Repository, Observer, Provider | `database_helper.dart`, `provider_setup.dart` |

### Prossimi Passi

1. **Flutter UI**: studia come i widget usano i servizi (`Consumer`, `context.watch`, `Provider.of`)
2. **Testing**: scrivi test unitari per i modelli e servizi che hai studiato
3. **Refactoring**: prova a migliorare una parte del codice applicando i pattern appresi
4. **Riverpod**: dopo aver capito `Provider`, esplora `flutter_riverpod` già nel progetto

---

**Torna all'indice:** [00 — Indice del Corso](00_indice.md)

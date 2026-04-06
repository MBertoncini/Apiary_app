# Modulo 12 — Error Handling

## 12.1 Tipi di Errori in Dart

Dart distingue due categorie:

- **Exception**: errori prevedibili che si possono gestire (rete assente, token scaduto)
- **Error**: errori di programmazione (bug) che normalmente non si gestiscono (NullPointerError, StackOverflowError)

```dart
// Exception — si cattura e gestisce
throw Exception('Token scaduto');
throw FormatException('JSON malformato');

// Error — indica un bug, non gestire a runtime
throw ArgumentError('id non può essere negativo');
throw StateError('inizializza prima di usare');
```

---

## 12.2 `try / catch / finally`

```dart
Future<List<Apiario>> caricaApiari() async {
  try {
    // Codice che potrebbe fallire
    final response = await http.get(url);
    return _parseApiari(response.body);
  } on FormatException catch (e) {
    // Cattura solo FormatException
    print('JSON non valido: $e');
    return [];
  } on SocketException {
    // Cattura SocketException (rete assente) — 'e' non usata
    print('Nessuna connessione di rete');
    return [];
  } catch (e, stackTrace) {
    // Cattura qualsiasi altra eccezione + stacktrace
    print('Errore inatteso: $e\n$stackTrace');
    return [];
  } finally {
    // SEMPRE eseguito, con o senza eccezione
    print('Caricamento terminato');
  }
}
```

**Regola:** cattura l'eccezione più specifica prima di quella generica.
`catch (e)` alla fine cattura tutto il resto.

---

## 12.3 `throw` — Lanciare Eccezioni

```dart
class ApiService {
  Future<Apiario> getApiario(int id) async {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', 'L\'id deve essere positivo');
    }

    final response = await http.get(uri);

    if (response.statusCode == 404) {
      throw Exception('Apiario $id non trovato');
    }
    if (response.statusCode != 200) {
      throw HttpException('Errore HTTP: ${response.statusCode}');
    }

    return Apiario.fromJson(jsonDecode(response.body));
  }
}
```

---

## 12.4 Creare Eccezioni Personalizzate

```dart
// Eccezione personalizzata — estende Exception
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, {this.statusCode});

  @override
  String toString() => 'AuthException: $message (status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;
  final bool isTimeout;

  NetworkException(this.message, {this.isTimeout = false});

  @override
  String toString() => isTimeout
      ? 'NetworkException (timeout): $message'
      : 'NetworkException: $message';
}

// Uso:
try {
  await login(username, password);
} on AuthException catch (e) {
  if (e.statusCode == 401) {
    mostraErrore('Credenziali errate');
  } else if (e.statusCode == 403) {
    mostraErrore('Account bloccato');
  }
} on NetworkException catch (e) {
  if (e.isTimeout) {
    mostraErrore('Connessione lenta — riprova');
  }
}
```

---

## 12.5 Pattern nel Progetto: `try/catch` nei Servizi

**`lib/services/auth_service.dart`**:
```dart
Future<bool> checkAuth() async {
  _isLoading = true;
  notifyListeners();

  try {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(AppConstants.tokenKey);

    if (savedToken != null) {
      _token = savedToken;
      final userInfo = await _fetchUserInfo();
      if (userInfo != null) {
        _currentUser = userInfo;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    }

    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
    return false;
  } catch (e) {
    // Non distinguiamo il tipo — qualsiasi errore = fallback a false
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
```

Nota: il progetto usa `catch (e)` generico perché qualsiasi errore porta
allo stesso risultato (utente non autenticato).

---

## 12.6 `runZonedGuarded` — Cattura Errori Globali

In `lib/main.dart` — cattura gli errori non gestiti a livello di app:

```dart
void main() {
  // Cattura errori Flutter (widget tree, rendering)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
  };

  // Cattura errori asincroni non gestiti
  runZonedGuarded(
    () => runApp(const App()),
    (error, stackTrace) {
      print('Unhandled error: $error');
      print(stackTrace);
    },
  );
}
```

---

## 12.7 Errori HTTP — Gestione Status Code

```dart
Future<T> _parseResponse<T>(
  http.Response response,
  T Function(dynamic) parser,
) {
  switch (response.statusCode) {
    case 200:
    case 201:
      return Future.value(parser(jsonDecode(response.body)));
    case 400:
      throw FormatException('Richiesta non valida: ${response.body}');
    case 401:
      throw AuthException('Non autorizzato', statusCode: 401);
    case 403:
      throw AuthException('Accesso negato', statusCode: 403);
    case 404:
      throw Exception('Risorsa non trovata');
    case 429:
      throw Exception('Troppe richieste — attendi prima di riprovare');
    case >= 500:
      throw Exception('Errore del server (${response.statusCode})');
    default:
      throw Exception('Risposta inattesa: ${response.statusCode}');
  }
}
```

**Nel progetto** il `ChatService` gestisce il 429 (rate limit):
```dart
// lib/services/chat_service.dart
bool get lastCallWasRateLimit => false; // dal mixin VoiceDataProcessor
```

---

## 12.8 Gestione Errori nelle Collezioni

```dart
// tryParse — restituisce null invece di lanciare eccezione
int? sicuro = int.tryParse('abc'); // null
int pericoloso = int.parse('abc'); // lancia FormatException

// Nelle liste — gestire il parsing elemento per elemento
List<Apiario> parseApiari(List<dynamic> jsonList) {
  List<Apiario> risultato = [];

  for (var item in jsonList) {
    try {
      risultato.add(Apiario.fromJson(item));
    } catch (e) {
      // Se un elemento è malformato, lo saltiamo ma continuiamo
      print('Elemento non valido, saltato: $e');
    }
  }

  return risultato;
}
```

---

## 12.9 `assert` — Validazione in Development

Le asserzioni sono attive solo in modalità debug, non in produzione:

```dart
class Arnia {
  final int id;
  final int arniaId;

  Arnia({required this.id, required this.arniaId}) {
    // Questi controlli esistono solo durante lo sviluppo
    assert(id > 0, 'id deve essere positivo');
    assert(arniaId > 0, 'arniaId deve essere positivo');
  }
}
```

---

## 12.10 Pattern: Result Type per Errori Type-Safe

Invece di lanciare eccezioni, alcune architetture usano un tipo `Result`:

```dart
sealed class Result<T> {}

class Success<T> extends Result<T> {
  final T data;
  Success(this.data);
}

class Failure<T> extends Result<T> {
  final Exception errore;
  final String messaggio;
  Failure(this.errore, this.messaggio);
}

// Uso:
Future<Result<List<Apiario>>> caricaApiari() async {
  try {
    final lista = await apiService.getApiari();
    return Success(lista);
  } on NetworkException catch (e) {
    return Failure(e, 'Errore di rete: verifica la connessione');
  } catch (e) {
    return Failure(Exception(e.toString()), 'Errore inatteso');
  }
}

// Consumo con pattern matching (Dart 3):
final result = await caricaApiari();
switch (result) {
  case Success(:final data):
    mostraApiari(data);
  case Failure(:final messaggio):
    mostraErrore(messaggio);
}
```

---

## 12.11 Checklist per la Gestione Errori

```
✓ Usa tryParse invece di parse per input da utente/JSON
✓ Wrap le chiamate HTTP in try/catch
✓ Gestisci i casi 401 (non auth) e 429 (rate limit) separatamente
✓ Log degli errori ma non mostrare dettagli tecnici all'utente
✓ Fallback a stato sicuro (lista vuota, false, null) quando appropriato
✓ Non "ingoiare" silenziosamente gli errori — almeno un print/log
✓ Cancella subscription/timer nel dispose per evitare errori di "disposed widget"
✓ Usa runZonedGuarded per errori globali in main()
```

---

## Esercizi

1. In `lib/utils/validators.dart`:
   - Come usa `int.tryParse()` per evitare eccezioni?
   - Cosa restituisce in caso di errore? (String? — il messaggio di errore)

2. In `lib/services/auth_service.dart`:
   - Il `catch (e)` generico è una buona pratica qui? Perché?
   - Cosa potrebbe andare storto che il catch non gestisce specificamente?

3. Crea una funzione `caricaArniaConRetry(int id, {int tentativi = 3})` che:
   - Tenta di caricare un'arnia N volte
   - In caso di `NetworkException`, aspetta 2 secondi e riprova
   - In caso di altri errori, rilancia immediatamente
   - Usa eccezioni personalizzate e `try/catch`

---

**Prossimo modulo:** [13 — Pattern di Design](13_pattern_design.md)

# Modulo 06 — Async / Await e Future

## 6.1 Perché la Programmazione Asincrona?

Alcune operazioni richiedono tempo: chiamate HTTP, lettura da database, accesso a file.
Se il programma aspettasse bloccando tutto il resto, l'interfaccia si "congelerebbe".

Dart risolve questo con i **Future** e **async/await**: il programma può continuare
a fare altre cose mentre aspetta un'operazione lenta.

```
Sincrono (blocca tutto):     Asincrono (non blocca):
─────────────────────        ─────────────────────────
Avvia operazione lenta       Avvia operazione lenta
[BLOCCO... aspetto...]       Fai altre cose
                             Fai altre cose
Operazione finita            Operazione finita → gestisci
Continua                     Continua
```

---

## 6.2 Future — Promessa di un Valore

Un `Future<T>` rappresenta un valore che sarà disponibile **in futuro**.
È come una promessa: "ti prometto che ti darò un `T` quando avrò finito".

```dart
// Future che completa dopo 2 secondi con il valore 42
Future<int> operazioneLenta() {
  return Future.delayed(Duration(seconds: 2), () => 42);
}

// Future già completato
Future<String> subito() {
  return Future.value('risultato immediato');
}

// Future che fallisce
Future<String> errore() {
  return Future.error(Exception('Qualcosa è andato storto'));
}
```

Uno stato del Future:
- **Uncompleted** — in attesa
- **Completed with value** — ha il risultato
- **Completed with error** — ha un errore

---

## 6.3 `async` e `await`

Invece di gestire manualmente i Future con callback, usi `async`/`await`:

```dart
// Funzione asincrona — il tipo di ritorno è Future<T>
Future<String> caricaDati() async {
  // await sospende la funzione QUI, senza bloccare il programma
  await Future.delayed(Duration(seconds: 1));
  return 'dati caricati';
}

// Per usarla, devi essere anche tu in un contesto async
Future<void> main() async {
  print('inizio');
  String dati = await caricaDati(); // attende il completamento
  print(dati);    // "dati caricati"
  print('fine');
}
```

Regole fondamentali:
1. `await` può essere usato solo dentro una funzione `async`
2. Una funzione `async` restituisce sempre un `Future`
3. `await` "scarta" il Future e ti dà il valore interno

---

## 6.4 Gestione degli Errori con `try/catch`

```dart
Future<List<Apiario>> caricaApiari() async {
  try {
    final risposta = await http.get(Uri.parse('https://api.esempio.it/apiari'));

    if (risposta.statusCode == 200) {
      final json = jsonDecode(risposta.body) as List;
      return json.map((j) => Apiario.fromJson(j)).toList();
    } else {
      throw Exception('Errore HTTP: ${risposta.statusCode}');
    }
  } catch (e) {
    print('Errore durante il caricamento: $e');
    return []; // fallback
  }
}
```

**Nel progetto** — `lib/services/auth_service.dart`:
```dart
Future<bool> checkAuth() async {
  _isLoading = true;
  notifyListeners();

  try {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(AppConstants.tokenKey);

    if (savedToken != null) {
      _token = savedToken;
      final userInfo = await _fetchUserInfo(); // altra chiamata async
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
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
```

Nota il pattern: `try { operazione async } catch (e) { gestisci errore }`.

---

## 6.5 `then`, `catchError`, `whenComplete`

Alternativa ai `async`/`await` — i metodi del Future:

```dart
caricaDati()
  .then((dati) {
    print('Ricevuto: $dati');
  })
  .catchError((errore) {
    print('Errore: $errore');
  })
  .whenComplete(() {
    print('Operazione terminata (con o senza errori)');
  });
```

In pratica, `async`/`await` è più leggibile e preferibile. I metodi `then`/`catchError`
si vedono in codice più vecchio o in casi specifici.

---

## 6.6 `Future.wait` — Parallelismo

Per avviare più operazioni asincrone contemporaneamente e aspettarle tutte:

```dart
// Sequenziale — lento (4 secondi totali se ogni chiamata dura 1s)
List<Apiario> a1 = await caricaApiario(1);
List<Arnia> a2 = await caricaArnie(1);

// Parallelo — veloce (1 secondo totale)
List<dynamic> risultati = await Future.wait([
  caricaApiario(1),
  caricaArnie(1),
]);
List<Apiario> apiari = risultati[0];
List<Arnia> arnie = risultati[1];
```

---

## 6.7 `Future` con Timeout

Evita che un'operazione aspetti all'infinito:

```dart
try {
  final dati = await caricaDati().timeout(
    Duration(seconds: 10),
    onTimeout: () => throw TimeoutException('Timeout dopo 10s'),
  );
} on TimeoutException catch (e) {
  print('Operazione troppo lenta: $e');
}
```

---

## 6.8 Pattern: Retry Automatico

**Nel progetto** — `lib/services/api_service.dart`:
```dart
Future<http.Response> _executeWithRetry(
  Future<http.Response> Function(Map<String, String> headers) request,
) async {
  var headers = await _headers;
  var response = await request(headers);       // prima chiamata

  if (response.statusCode == 401) {
    // Token scaduto — prova a refreshare
    final refreshed = await _authService.refreshToken();
    if (refreshed) {
      headers = await _headers;
      response = await request(headers);       // seconda chiamata con nuovo token
    } else {
      _handleSessionExpired();
    }
  }

  return response;
}
```

Un `Future<http.Response> Function(Map<String, String>)` è una funzione passata
come parametro che restituisce un Future — pattern avanzato ma comune nei servizi.

---

## 6.9 `FutureBuilder` — Async nell'interfaccia Flutter

In Flutter, per mostrare dati asincroni nell'UI si usa `FutureBuilder`:

```dart
FutureBuilder<List<Apiario>>(
  future: apiarioService.getAll(), // il Future da attendere
  builder: (context, snapshot) {
    // snapshot contiene lo stato del Future
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return Text('Errore: ${snapshot.error}');
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Text('Nessun apiario trovato');
    }
    return ListView.builder(
      itemCount: snapshot.data!.length,
      itemBuilder: (ctx, i) => Text(snapshot.data![i].nome),
    );
  },
)
```

---

## 6.10 Errori Comuni

| Errore | Causa | Soluzione |
|--------|-------|-----------|
| `await` fuori da `async` | Dimentichi `async` nella firma | Aggiungi `async` |
| Future non awaited | Non usi `await` e ignori il Future | Sempre usa `await` o `then` |
| Stack overflow asincrono | Loop di await senza fine | Aggiungi condizione di uscita |
| Eccezione non gestita | Nessun `catch` | Aggiungi `try/catch` |

---

## 6.11 Mappa del Flusso Asincrono nel Progetto

```
UI (screen) chiede dati
    │
    ▼
Provider/Service (async) ── await ──► API HTTP o Database SQLite
    │                                        │
    │          ◄── Future completo ──────────┘
    │
    ▼
notifyListeners() → UI si aggiorna
```

Apri `lib/services/arnia_service.dart` per vedere una chiamata API completa:
`getArnie()` → `await http.get()` → parsing JSON → ritorna `List<Arnia>`.

---

## Esercizi

1. In `lib/services/auth_service.dart` cerca `checkAuth()`:
   - Quante chiamate `await` contiene?
   - Cosa succede se `_fetchUserInfo()` lancia un'eccezione?
   - Dove viene gestita?

2. In `lib/database/database_helper.dart` cerca `_initDatabase()`:
   - Perché è `async`?
   - Qual è il valore che restituisce?

3. Scrivi una funzione `caricaRiepilogo(int apiarioId)` che:
   - In parallelo (`Future.wait`) carica arnie e regina dell'apiario
   - Gestisce gli errori con try/catch
   - Ritorna una `Map<String, dynamic>` con i dati combinati
   - Ha un timeout di 15 secondi

---

**Prossimo modulo:** [07 — Classi Avanzate](07_classi_avanzate.md)

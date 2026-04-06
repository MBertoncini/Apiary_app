# Modulo 08 — Generics

## 8.1 Cos'è un Generic?

I generics permettono di scrivere codice che funziona con **tipi diversi** senza
ripetersi. Il tipo viene specificato quando si usa la classe o la funzione.

Senza generics dovresti scrivere:
```dart
List listaDiStringhe = [];  // perde la sicurezza del tipo
List listaDiInteri = [];    // stessa lista, tipo diverso
```

Con generics scrivi una volta e usi con qualsiasi tipo:
```dart
List<String> stringhe = [];  // sicuro: solo String
List<int> interi = [];       // sicuro: solo int
List<Apiario> apiari = [];   // sicuro: solo Apiario
```

---

## 8.2 Classi Generiche

Puoi creare classi parametrizzate con un tipo `T` (o qualsiasi lettera):

```dart
// Una "scatola" che contiene qualsiasi tipo T
class Scatola<T> {
  T contenuto;
  Scatola(this.contenuto);

  T apri() => contenuto;
  void metti(T nuovo) => contenuto = nuovo;
}

// Uso:
var scatolaStringhe = Scatola<String>('ciao');
var scatolaInt = Scatola<int>(42);

print(scatolaStringhe.apri()); // 'ciao'
print(scatolaInt.apri());      // 42
```

---

## 8.3 Funzioni Generiche

Anche le funzioni possono essere generiche:

```dart
T primoDi<T>(List<T> lista) {
  if (lista.isEmpty) throw StateError('Lista vuota');
  return lista.first;
}

String primoApiario = primoDi<String>(['Nord', 'Sud', 'Centro']);
int primoNumero = primoDi([1, 2, 3]); // tipo inferito automaticamente
```

---

## 8.4 Generics nel Progetto — `Future<T>`

Il `Future<T>` è il generic più usato nel progetto. `T` è il tipo del valore
che il Future produrrà:

```dart
Future<String?> getToken() async { ... }    // produrrà una String? 
Future<bool> refreshToken() async { ... }    // produrrà un bool
Future<List<Apiario>> getAll() async { ... } // produrrà una List<Apiario>
Future<Apiario?> getById(int id) async { ... } // produrrà un Apiario?
Future<void> sincronizza() async { ... }     // non produrrà nulla
```

---

## 8.5 `List<T>` e `Map<K, V>` — Generics nelle Collezioni

Abbiamo già usato questi nel Modulo 05 — ora capiamo perché sono generics:

```dart
// List<T>: lista di elementi di tipo T
List<Arnia> arnie = [];          // T = Arnia
List<String> razze = [];         // T = String
List<Map<String, dynamic>> rows; // T = Map<String, dynamic>

// Map<K, V>: dizionario da chiavi K a valori V
Map<String, String> headers;       // K=String, V=String
Map<String, dynamic> json;         // K=String, V=dynamic
Map<int, List<Arnia>> perApiario;  // K=int, V=List<Arnia>
```

---

## 8.6 Vincoli di Tipo (`extends` nei Generics)

Puoi limitare quali tipi può assumere `T` usando `extends`:

```dart
// T deve essere un numero (int, double, num)
T massimo<T extends num>(List<T> lista) {
  return lista.reduce((a, b) => a > b ? a : b);
}

int maxInt = massimo([3, 1, 4, 1, 5, 9]);     // OK: int extends num
double maxDouble = massimo([1.5, 2.3, 0.8]);  // OK: double extends num
// massimo(['a', 'b']); // ERRORE: String non extends num
```

---

## 8.7 `dynamic` vs Generics

`dynamic` disabilita i controlli del tipo — da evitare dove possibile:

```dart
// dynamic: qualsiasi tipo, nessun controllo
dynamic valore = 42;
valore = 'ora sono una stringa'; // OK a compile-time, potenzialmente problematico
valore.metodoInesistente();       // ERRORE solo a runtime!

// Generic: flessibile MA type-safe
T identità<T>(T valore) => valore;
int x = identità(42);             // OK
// String s = identità(42);       // ERRORE a compile-time
```

`Map<String, dynamic>` è un'eccezione accettabile: il JSON può contenere
qualsiasi tipo per i valori, ma le chiavi sono sempre String.

---

## 8.8 Generic nel DatabaseHelper — `inTransaction<T>`

**`lib/database/database_helper.dart`** — uno degli usi più avanzati nel progetto:

```dart
// T è il tipo del valore che la transazione produce
Future<T> inTransaction<T>(
  Future<T> Function(Transaction txn) action // callback generica
) async {
  final db = await database;
  return await db.transaction((txn) => action(txn));
}

// Uso — T viene inferito dalla callback:
int id = await db.inTransaction((txn) async {
  // qui fai più operazioni atomiche
  await txn.insert('tabella', {...});
  return txn.insert('altra', {...}); // ritorna int → T = int
});

List<Arnia> arnie = await db.inTransaction((txn) async {
  var rows = await txn.query('arnie');
  return rows.map((r) => Arnia.fromJson(r)).toList(); // ritorna List<Arnia>
});
```

La potenza: **un solo metodo** funziona per qualsiasi tipo di transazione.

---

## 8.9 `ApiService.fromToken<T>` — Factory Generic

**`lib/services/api_service.dart`**:

```dart
// Factory constructor statico — alternativa creazione
factory ApiService.fromToken(String token, String refreshToken) {
  return ApiService(_StaticTokenProvider(token, refreshToken));
}
```

I metodi HTTP del servizio possono usare generics per il parsing:

```dart
// Pattern tipico per API calls
Future<T> _get<T>(String endpoint, T Function(dynamic) parser) async {
  final response = await _executeWithRetry((headers) =>
    http.get(Uri.parse('$baseUrl$endpoint'), headers: headers)
  );

  if (response.statusCode == 200) {
    return parser(jsonDecode(response.body));
  }
  throw Exception('Errore ${response.statusCode}');
}

// Uso:
List<Apiario> apiari = await _get('/apiari/', (json) =>
  (json as List).map((j) => Apiario.fromJson(j)).toList()
);
```

---

## 8.10 Result Type — Pattern Generic Avanzato

Un pattern utile per gestire successo/errore in modo type-safe:

```dart
// Classe generica per wrappare risultati
class Result<T> {
  final T? data;
  final String? error;
  final bool success;

  Result.ok(T this.data)
      : error = null,
        success = true;

  Result.err(String this.error)
      : data = null,
        success = false;
}

// Uso:
Future<Result<List<Apiario>>> caricaApiari() async {
  try {
    final lista = await apiService.getApiari();
    return Result.ok(lista);
  } catch (e) {
    return Result.err('Errore: $e');
  }
}

// Consumo:
final result = await caricaApiari();
if (result.success) {
  mostraApiari(result.data!);
} else {
  mostraErrore(result.error!);
}
```

---

## 8.11 Riepilogo dei Generics nel Progetto

| Uso | Dove | Tipo |
|-----|------|------|
| `Future<bool>` | `auth_service.dart` | Future di bool |
| `Future<String?>` | `api_service.dart` | Future di String nullable |
| `Future<List<Apiario>>` | DAO files | Future di lista |
| `List<Map<String, dynamic>>` | `database_helper.dart` | Lista di mappe |
| `Map<String, String>` | `api_service.dart` | Mappa tipizzata |
| `Future<T> Function(...)` | `database_helper.dart` | Funzione generica come parametro |
| `StreamController<bool>` | `connectivity_service.dart` | Stream di bool |

---

## Esercizi

1. In `lib/database/dao/apiario_dao.dart`:
   - `getAll()` restituisce `Future<List<Apiario>>` — T = ?
   - `getById()` restituisce `Future<Apiario?>` — T = ?
   - Scrivi mentalmente la firma di un `getByNome(String nome)` che restituisce la prima corrispondenza

2. In `lib/services/api_service.dart`:
   - Cerca `Map<String, String>` — perché non `Map<String, dynamic>` per gli headers?
   - Cerca `Future<http.Response>` — cos'è il tipo T in questo caso?

3. Crea una classe generica `Cache<T>` che:
   - Memorizza un valore di tipo T con timestamp
   - Ha un getter `valoreCorrente` che ritorna `T?` (null se scaduto)
   - Ha un metodo `aggiorna(T nuovo)` che salva il valore e il timestamp corrente
   - Accetta una `Duration scadenza` nel costruttore

---

**Prossimo modulo:** [09 — Interfacce e Mixins](09_interfacce_mixins.md)

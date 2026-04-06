# Modulo 05 — Collections: List, Map, Set

## 5.1 List — Liste Ordinate

Una `List` è una sequenza ordinata di elementi dello stesso tipo.

```dart
// Creazione
List<String> razze = ['Ligustica', 'Carnica', 'Buckfast'];
var numeri = [1, 2, 3, 4, 5]; // tipo inferito: List<int>
List<int> vuota = [];          // lista vuota

// Accesso
print(razze[0]);         // "Ligustica" — indice zero-based
print(razze.last);       // "Buckfast"
print(razze.length);     // 3

// Aggiunta e rimozione
razze.add('Mellifera');
razze.remove('Carnica');
razze.insert(1, 'Nera'); // inserisce alla posizione 1
razze.clear();            // svuota la lista

// Controllo
bool contiene = razze.contains('Ligustica');
bool vuotaCheck = razze.isEmpty;
```

### Liste fisse vs crescenti

```dart
List<int> fissa = List.filled(5, 0);  // [0, 0, 0, 0, 0] — lunghezza fissa
List<int> crescente = [];              // lunghezza variabile
```

---

## 5.2 Iterazione sulle Liste

```dart
List<String> apiari = ['Nord', 'Sud', 'Centro'];

// for classico
for (int i = 0; i < apiari.length; i++) {
  print('$i: ${apiari[i]}');
}

// for-in (più leggibile)
for (String apiario in apiari) {
  print(apiario);
}

// forEach (lambda)
apiari.forEach((nome) => print(nome.toUpperCase()));
```

---

## 5.3 Operazioni Funzionali sulle Liste

Dart offre metodi potenti per trasformare le liste senza modificare l'originale.

### `map` — trasforma ogni elemento

```dart
List<int> telaini = [4, 8, 10, 6];
List<String> etichette = telaini.map((t) => '$t telaini').toList();
// ["4 telaini", "8 telaini", "10 telaini", "6 telaini"]
```

### `where` — filtra gli elementi (come filter)

```dart
List<int> valori = [1, 5, 2, 8, 3, 9, 4];
List<int> grandi = valori.where((v) => v > 4).toList();
// [5, 8, 9]
```

### `any` / `every` — verifiche booleane

```dart
List<bool> attive = [true, true, false, true];
bool qualcunaAttiva = attive.any((a) => a);    // true
bool tutteAttive = attive.every((a) => a);     // false
```

### `reduce` / `fold` — aggrega in un solo valore

```dart
List<int> peso = [1200, 800, 1500, 900];
int totale = peso.reduce((acc, p) => acc + p); // 4400
double media = peso.fold(0, (acc, p) => acc + p) / peso.length; // 1100.0
```

### `sort` — ordina (modifica la lista originale)

```dart
List<String> nomi = ['Gamma', 'Alpha', 'Beta'];
nomi.sort((a, b) => a.compareTo(b));
print(nomi); // ['Alpha', 'Beta', 'Gamma']
```

**Nel progetto** — `lib/database/dao/apiario_dao.dart`:
```dart
// Il DAO converte List<Map> in List<Apiario>
return List.generate(maps.length, (i) {
  return Apiario.fromJson(maps[i]);
});
```

---

## 5.4 Map — Dizionari Chiave-Valore

Una `Map<K, V>` associa chiavi di tipo K a valori di tipo V.

```dart
// Creazione
Map<String, dynamic> json = {
  'id': 1,
  'nome': 'Apiario Nord',
  'attivo': true,
  'lat': 45.9,
};

// Accesso
String nome = json['nome'];      // 'Apiario Nord'
dynamic valore = json['attivo']; // true

// Chiave inesistente → null (non lancia eccezione)
var x = json['campo_inesistente']; // null

// Aggiunta e modifica
json['note'] = 'Nuovo valore';
json['id'] = 2; // sovrascrive

// Controllo
bool haId = json.containsKey('id');
bool ha1 = json.containsValue(1);
print(json.length); // numero di coppie
```

### Iterazione su Map

```dart
Map<String, int> arnie = {'Nord': 5, 'Sud': 3, 'Centro': 8};

// Chiavi e valori separati
for (String k in arnie.keys) print(k);
for (int v in arnie.values) print(v);

// Coppie
arnie.forEach((chiave, valore) {
  print('$chiave: $valore arnie');
});

// entries — accesso strutturato
for (MapEntry<String, int> entry in arnie.entries) {
  print('${entry.key} → ${entry.value}');
}
```

**Nel progetto** — `Map<String, dynamic>` è il tipo standard per JSON:
```dart
// lib/models/arnia.dart
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'apiario': apiario,
    'apiario_nome': apiarioNome,
    'note': note,
    'attiva': attiva,
  };
}
```

---

## 5.5 Set — Insiemi (senza duplicati)

Un `Set<T>` è come una lista ma senza elementi duplicati e senza ordine garantito.

```dart
Set<String> razze = {'Ligustica', 'Carnica', 'Ligustica'};
print(razze); // {Ligustica, Carnica} — il duplicato è rimosso

razze.add('Buckfast');
razze.remove('Carnica');
bool c = razze.contains('Ligustica'); // true

// Operazioni insiemistiche
Set<int> A = {1, 2, 3, 4};
Set<int> B = {3, 4, 5, 6};
print(A.union(B));        // {1, 2, 3, 4, 5, 6}
print(A.intersection(B)); // {3, 4}
print(A.difference(B));   // {1, 2}
```

---

## 5.6 Spread Operator e Collection If/For

Dart ha operatori speciali per costruire collezioni in modo dichiarativo.

### Spread `...`

```dart
List<String> base = ['Ligustica', 'Carnica'];
List<String> extra = ['Buckfast', 'Nera'];

List<String> tutte = [...base, ...extra, 'Mellifera'];
// ['Ligustica', 'Carnica', 'Buckfast', 'Nera', 'Mellifera']
```

### Collection If

```dart
bool mostraExtra = true;

List<String> menu = [
  'Apiario',
  'Arnie',
  if (mostraExtra) 'Statistiche', // incluso solo se mostraExtra = true
  'Impostazioni',
];
```

### Collection For

```dart
List<int> ids = [1, 2, 3];
List<String> nomi = [
  for (int id in ids) 'Apiario $id',
];
// ['Apiario 1', 'Apiario 2', 'Apiario 3']
```

---

## 5.7 Conversioni tra Collezioni

```dart
List<int> lista = [1, 2, 3, 2, 1];
Set<int> insieme = lista.toSet();    // {1, 2, 3} — rimuove duplicati
List<int> di_nuovo = insieme.toList(); // [1, 2, 3]

Map<String, int> mappa = {'a': 1, 'b': 2};
List<MapEntry<String, int>> voci = mappa.entries.toList();
```

---

## 5.8 Collezioni nel Progetto

| Tipo | Dove | Scopo |
|------|------|-------|
| `List<Apiario>` | DAO, servizi | Risultati query |
| `List<Map<String,dynamic>>` | `database_helper.dart` | Risultati SQLite grezzi |
| `Map<String, dynamic>` | Tutti i modelli | Serializzazione JSON |
| `Map<String, String>` | `api_service.dart` | HTTP Headers |
| `List<LatLng>` | `osm_vegetazione.dart` | Punti geografici |
| `Set<String>` | Vari | Controllo duplicati |

**Esempio reale** — `lib/services/api_service.dart`:
```dart
Future<Map<String, String>> get _headers async {
  final token = await _authService.getToken();
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
```

---

## 5.9 Null Safety nelle Collezioni

```dart
List<String>? lista = null;          // la lista stessa può essere null
List<String?> con_null = ['a', null, 'b']; // elementi possono essere null

// Attenzione:
lista?.forEach((e) => print(e));    // sicuro — non itera se null
lista!.forEach((e) => print(e));    // crasha se null
```

---

## Esercizi

1. In `lib/database/dao/apiario_dao.dart` — la query `getAll()` ritorna
   `Future<List<Apiario>>`. Traccia il percorso dei dati:
   - Cosa ritorna `_dbHelper.query()`?
   - Come viene convertito in `List<Apiario>`?

2. In `lib/services/api_service.dart` — gli headers sono `Map<String, String>`.
   - Perché non `Map<String, dynamic>`?
   - Quando si usa `dynamic` e quando un tipo specifico?

3. Scrivi una funzione `riepilogoApiario` che:
   - Accetta una `List<Map<String, dynamic>>` (risultato JSON di arnie)
   - Ritorna una `Map<String, int>` con: `{'totale': N, 'attive': M, 'inattive': K}`
   - Usa `where`, `length`, e collection for dove appropriato

---

**Prossimo modulo:** [06 — Async / Await](06_async_await.md)

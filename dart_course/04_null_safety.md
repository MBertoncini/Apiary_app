# Modulo 04 — Null Safety

## 4.1 Il Problema di Null

In molti linguaggi, qualsiasi variabile può essere `null`. Questo causa i famigerati
"null pointer exceptions" a runtime. Dart, dalla versione 2.12, ha il **Null Safety**:
il compilatore sa già a compile-time se una variabile può essere null o no.

```dart
// Senza null safety (vecchio Dart / altri linguaggi):
String nome = null; // OK — esplode a runtime quando usi 'nome'

// Con null safety:
String nome = null;   // ERRORE di compilazione — String non può essere null
String? nome = null;  // OK — il ? dichiara esplicitamente la nullabilità
```

Il compilatore blocca gli errori prima che il programma giri. Ogni file del progetto
usa `'>=3.0.0 <4.0.0'` in `pubspec.yaml` — null safety è attivo ovunque.

---

## 4.2 Tipi Nullable e Non-Nullable

```dart
String nome = 'Apiario Nord';   // non può essere null — garanzia del compilatore
String? nota = null;            // può essere null

int contatore = 0;              // sempre un numero
int? scelta = null;             // potrebbe non essere stata fatta

bool attivo = true;             // deve essere true o false
bool? confermato = null;        // "non ancora deciso"
```

**Regola pratica:** usa `?` solo quando il valore può davvero mancare.
Evita di rendere tutto nullable — perdi i benefici del null safety.

---

## 4.3 Operatore `??` — Null Coalescing

Restituisce il valore a sinistra se non è null, altrimenti quello a destra:

```dart
String? nota = null;
String testo = nota ?? 'Nessuna nota';
print(testo); // "Nessuna nota"

int? docilita = null;
int valore = docilita ?? 0;
print(valore); // 0
```

**Nel progetto** — `lib/models/regina.dart` e ogni `fromJson`:
```dart
razza: json['razza'] ?? '',           // se manca dal JSON, stringa vuota
docilita: json['docilita'],           // può essere null → campo nullable
```

```dart
// lib/models/arnia.dart
attiva: json['attiva'] ?? true,       // se manca, assumi attiva = true
```

---

## 4.4 Operatore `?.` — Null-Aware Access

Accede a un membro solo se l'oggetto non è null. Se è null, restituisce null:

```dart
String? nome = null;
int? lunghezza = nome?.length; // non lancia eccezione — restituisce null
print(lunghezza);              // null

String? nome2 = 'Ciao';
int? lunghezza2 = nome2?.length;
print(lunghezza2); // 4
```

Concatenamento:
```dart
Arnia? arnia = trovArnia(id: 5); // potrebbe non esistere
String? nomeColonia = arnia?.coloniaAttiva?.nome; // sicuro anche se arnia o colonia è null
```

**Nel progetto** — pattern comune nei servizi:
```dart
_connectivitySubscription?.cancel(); // cancel solo se la subscription non è null
_connectionChangeController.close(); // sempre (non nullable)
```

---

## 4.5 Operatore `!` — Null Assertion

Dice al compilatore: "Fidati di me, so che questo NON è null."
Se invece è null, lancia un'eccezione a runtime.

```dart
String? valore = recuperaDaPreferences(); // potrebbe essere null
String sicuro = valore!; // ATTENZIONE: crasha se valore è null
```

**Usa `!` solo quando sei assolutamente certo.** Nel progetto si vede in:

```dart
// lib/database/database_helper.dart
if (_database != null) return _database!;
// Prima controlliamo che non sia null, poi usiamo !
```

---

## 4.6 `late` — Inizializzazione Differita

Dichiara che una variabile non-nullable verrà inizializzata **prima del primo uso**,
ma non immediatamente:

```dart
class GestoreApiario {
  late Database _db;    // non ancora inizializzato

  Future<void> init() async {
    _db = await openDatabase('apiario.db'); // inizializzato qui
  }

  Future<List<Apiario>> getAll() async {
    return await _db.query('apiari'); // usato qui — deve essere già init
  }
}
```

`late` è utile per dipendenze che richiedono inizializzazione asincrona.
Se usi la variabile prima dell'inizializzazione → `LateInitializationError`.

---

## 4.7 Controlli Null e Type Promotion

Dart "promuove" automaticamente i tipi dopo un controllo null:

```dart
String? testo = daCualcheParte();

// Senza controllo: ERRORE — testo potrebbe essere null
// print(testo.length); // Errore di compilazione

// Con controllo if: Dart sa che qui dentro testo != null
if (testo != null) {
  print(testo.length); // OK — promosso a String (non nullable)
}

// Equivalente con early return
if (testo == null) return;
print(testo.length); // OK — Dart sa che qui testo != null
```

---

## 4.8 Pattern Comuni nel Progetto

### Pattern 1: fromJson con valori di default
```dart
// lib/models/voice_entry.dart — parsing sicuro con ??
telainiCovata: json['telaini_covata'] is int
    ? json['telaini_covata']
    : int.tryParse(json['telaini_covata']?.toString() ?? ''),
```

### Pattern 2: Accesso condizionale a oggetti annidati
```dart
// Arnia può avere una coloniaAttiva opzionale
final Colonia? coloniaAttiva;

// Uso sicuro:
String? nomeColonia = arnia.coloniaAttiva?.nome;
int colore = arnia.coloniaAttiva?.colore ?? Colors.grey.value;
```

### Pattern 3: Assegnazione condizionale
```dart
// Imposta solo se non null
if (dati != null) {
  _currentUser = dati;
}

// Equivalente compatto con ??=
_currentUser ??= User.default(); // assegna solo se è null
```

### Pattern 4: Null check con cascaded assignment
```dart
// lib/services/connectivity_service.dart
_connectivitySubscription =
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
// _connectivitySubscription?.cancel() — annulla solo se esiste
```

---

## 4.9 Quando Usare Cosa

| Operatore | Situazione | Esempio |
|-----------|-----------|---------|
| `?` (tipo) | Il valore può mancare | `String? nota` |
| `??` | Valore di fallback | `nota ?? 'nessuna'` |
| `?.` | Accesso sicuro | `arnia?.nome` |
| `!` | Certezza assoluta (raro) | `_db!.query(...)` |
| `late` | Init differita | `late Database _db` |
| `if (x != null)` | Logica condizionale | promozione automatica |

---

## 4.10 Null Safety nel Mondo Reale — Analisi `lib/models/arnia.dart`

```dart
class Arnia {
  final int id;             // non nullable: ogni arnia HA un id
  final int apiario;        // non nullable: deve appartenere a un apiario
  final String apiarioNome; // non nullable: il nome dell'apiario è sempre noto
  final String? note;       // NULLABLE: le note possono non esserci
  final bool attiva;        // non nullable: è sempre true o false
  final Colonia? coloniaAttiva; // NULLABLE: l'arnia potrebbe non avere colonia
}
```

La scelta di nullable vs non-nullable in un modello comunica l'intento:
**`String?` dice "questo campo è facoltativo nel dominio applicativo".**

---

## Esercizi

1. Apri `lib/models/regina.dart` — quali campi sono nullable? Ha senso?
   Pensa al dominio: una regina deve avere sempre la razza? E il codice marcatura?

2. In `lib/services/auth_service.dart` cerca `_token`:
   - È nullable? Perché?
   - Come viene usato? (guarda il getter e i controlli null)

3. Scrivi una funzione `formattaDocilita(int? docilita)` che:
   - Se `docilita` è null → restituisce "Non valutata"
   - Se è tra 1 e 3 → "Aggressiva"
   - Se è tra 4 e 6 → "Normale"
   - Se è tra 7 e 10 → "Docile"
   - Usa `??` e la promozione di tipo dove opportuno

---

**Prossimo modulo:** [05 — Collections](05_collections.md)

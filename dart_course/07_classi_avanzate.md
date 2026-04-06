# Modulo 07 — Classi Avanzate: Factory, copyWith, Named Constructors

## 7.1 Named Constructors (Costruttori con Nome)

Una classe può avere più costruttori, ognuno con un nome diverso per chiarirne lo scopo:

```dart
class Apiario {
  final int id;
  final String nome;
  final double lat;
  final double lon;
  final bool attivo;

  // Costruttore principale
  Apiario({
    required this.id,
    required this.nome,
    required this.lat,
    required this.lon,
    this.attivo = true,
  });

  // Named constructor: crea un Apiario vuoto/placeholder
  Apiario.vuoto()
      : id = 0,
        nome = '',
        lat = 0.0,
        lon = 0.0,
        attivo = false;

  // Named constructor: crea da coordinate (posizione centrale Italia)
  Apiario.Italia({required int id, required String nome})
      : this(id: id, nome: nome, lat: 41.9, lon: 12.5);
}

var a1 = Apiario(id: 1, nome: 'Nord', lat: 45.0, lon: 9.0);
var vuoto = Apiario.vuoto();
var romano = Apiario.Italia(id: 2, nome: 'Roma');
```

---

## 7.2 Factory Constructors

Un `factory` constructor non crea sempre un nuovo oggetto — può:
- Restituire un oggetto già esistente (Singleton)
- Scegliere quale tipo concreto creare
- Fare elaborazione complessa prima della creazione

```dart
class Regina {
  final int id;
  final String razza;

  // Costruttore "normale" — privato
  Regina._({required this.id, required this.razza});

  // Factory constructor: costruisce da JSON
  factory Regina.fromJson(Map<String, dynamic> json) {
    // Logica di parsing qui — non possibile in costruttore normale
    int parsedId = json['id'] is int
        ? json['id']
        : int.tryParse(json['id'].toString()) ?? 0;

    return Regina._(
      id: parsedId,
      razza: json['razza'] ?? 'Sconosciuta',
    );
  }
}

// Uso:
final json = {'id': 1, 'razza': 'Ligustica'};
final regina = Regina.fromJson(json);
```

**Nel progetto** — è il pattern più usato nei modelli. `lib/models/arnia.dart`:
```dart
factory Arnia.fromJson(Map<String, dynamic> json) {
  return Arnia(
    id: json['id'],
    apiario: json['apiario'],
    apiarioNome: json['apiario_nome'],
    note: json['note'],
    attiva: json['attiva'] ?? true,
  );
}
```

### Factory per Singleton

```dart
class DatabaseHelper {
  // Istanza unica memorizzata
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  // Factory: ritorna sempre la stessa istanza
  factory DatabaseHelper() => _instance;

  // Costruttore privato: nessuno può chiamarlo direttamente
  DatabaseHelper._internal();
}

// Ogni volta che chiami DatabaseHelper() ottieni lo stesso oggetto
var db1 = DatabaseHelper();
var db2 = DatabaseHelper();
print(identical(db1, db2)); // true — è lo stesso oggetto
```

**Nel progetto** — `lib/database/database_helper.dart` usa esattamente questo pattern.

---

## 7.3 Il Pattern `copyWith` — Immutabilità

I modelli del progetto usano campi `final`: una volta creato, l'oggetto non cambia.
Per "modificare" un oggetto si crea una copia con i campi aggiornati — il `copyWith`:

```dart
class Regina {
  final int? id;
  final int arniaId;
  final String razza;
  final String? codiceMarcatura;
  final int? docilita;

  const Regina({
    this.id,
    required this.arniaId,
    required this.razza,
    this.codiceMarcatura,
    this.docilita,
  });

  // copyWith: crea una copia con alcuni campi cambiati
  Regina copyWith({
    int? id,
    int? arniaId,
    String? razza,
    String? codiceMarcatura,
    int? docilita,
  }) {
    return Regina(
      id: id ?? this.id,              // usa il nuovo se fornito, altrimenti l'attuale
      arniaId: arniaId ?? this.arniaId,
      razza: razza ?? this.razza,
      codiceMarcatura: codiceMarcatura ?? this.codiceMarcatura,
      docilita: docilita ?? this.docilita,
    );
  }
}

// Uso:
var regina = Regina(arniaId: 1, razza: 'Ligustica');
var modificata = regina.copyWith(razza: 'Carnica', docilita: 8);

print(regina.razza);    // 'Ligustica' — originale intatta
print(modificata.razza); // 'Carnica' — nuova copia
```

**Vantaggio:** gli oggetti immutabili non hanno effetti collaterali —
non devi preoccuparti che qualcuno li modifichi da un'altra parte del codice.

---

## 7.4 `toJson` — Serializzazione

Il complementare di `fromJson`: converte l'oggetto in una `Map<String, dynamic>`
per inviarlo come JSON a un'API o salvarlo nel database.

```dart
class Apiario {
  // ...campi...

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'latitudine': latitudine,
      'longitudine': longitudine,
      'attivo': attivo,
      // i campi nullable vengono inclusi come null se non presenti
      'note': note,
    };
  }
}

// Uso:
var apiario = Apiario(id: 1, nome: 'Nord', lat: 45.0, lon: 9.0);
Map<String, dynamic> json = apiario.toJson();
String jsonString = jsonEncode(json); // → stringa JSON per l'HTTP body
```

---

## 7.5 Factory con Validazione Complessa

A volte la creazione richiede logica elaborata — il factory è il posto giusto:

```dart
class VoiceEntry {
  final DateTime data;
  final int? telainiCovata;

  VoiceEntry._({required this.data, this.telainiCovata});

  factory VoiceEntry.fromJson(Map<String, dynamic> json) {
    // Parsing data con più formati possibili
    DateTime? parseDate() {
      if (json['data'] != null) {
        try {
          List<String> formats = ['yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy'];
          for (var format in formats) {
            try {
              return DateFormat(format).parse(json['data']);
            } catch (_) {}
          }
        } catch (_) {}
      }
      return DateTime.now(); // fallback
    }

    // Parsing int con gestione tipo dinamica
    int? parseIntField(String key) {
      final val = json[key];
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }

    return VoiceEntry._(
      data: parseDate()!,
      telainiCovata: parseIntField('telaini_covata'),
    );
  }
}
```

---

## 7.6 `const` Constructors

Se tutti i campi sono `final` e i valori sono noti a compile-time, puoi usare `const`:

```dart
class Punto {
  final double x;
  final double y;

  const Punto(this.x, this.y); // costruttore const
}

const p1 = Punto(0, 0);      // creato a compile-time — più efficiente
const p2 = Punto(0, 0);

print(identical(p1, p2)); // true — Dart riutilizza lo stesso oggetto!
```

In Flutter questo è fondamentale per le performance dei widget:
```dart
const Text('Ciao');    // non viene ricostruito ad ogni frame
const SizedBox();
const Icon(Icons.add);
```

---

## 7.7 Confronto tra i Tipi di Costruttori

| Tipo | Sintassi | Crea sempre nuovo? | Quando usare |
|------|----------|-------------------|--------------|
| Default | `ClassName({...})` | Sì | Costruzione normale |
| Named | `ClassName.nomeCtor(...)` | Sì | Varianti di costruzione |
| Factory | `factory ClassName(...)` | Non necessariamente | Parsing, Singleton, selezione |
| Const | `const ClassName(...)` | No (compile-time) | Valori fissi, widget Flutter |

---

## 7.8 Analisi Completa: `lib/models/arnia.dart`

Questo file usa tutti i pattern che abbiamo visto:

```dart
class Arnia {
  // Campi tutti final → immutabilità garantita
  final int id;
  final int apiario;
  final String apiarioNome;
  final String? note;      // nullable
  final bool attiva;
  final Colonia? coloniaAttiva;

  // 1. Costruttore principale con named + required
  Arnia({
    required this.id,
    required this.apiario,
    required this.apiarioNome,
    this.note,
    required this.attiva,
    this.coloniaAttiva,
  });

  // 2. Factory constructor per deserializzazione JSON
  factory Arnia.fromJson(Map<String, dynamic> json) {
    return Arnia(
      id: json['id'],
      apiario: json['apiario'],
      apiarioNome: json['apiario_nome'],
      note: json['note'],
      attiva: json['attiva'] ?? true,
    );
  }

  // 3. toJson per serializzazione
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apiario': apiario,
      'apiario_nome': apiarioNome,
      'note': note,
      'attiva': attiva,
    };
  }

  // 4. copyWith per immutabilità con modifiche
  Arnia copyWith({
    int? id,
    int? apiario,
    String? apiarioNome,
    String? note,
    bool? attiva,
    Colonia? coloniaAttiva,
  }) {
    return Arnia(
      id: id ?? this.id,
      apiario: apiario ?? this.apiario,
      apiarioNome: apiarioNome ?? this.apiarioNome,
      note: note ?? this.note,
      attiva: attiva ?? this.attiva,
      coloniaAttiva: coloniaAttiva ?? this.coloniaAttiva,
    );
  }
}
```

Questo è il **template standard** per i modelli dati in Dart/Flutter.
Lo troverai identico in `arnia.dart`, `apiario.dart`, `regina.dart`, ecc.

---

## Esercizi

1. Apri `lib/models/regina.dart` — elenca tutti i costruttori presenti:
   - Quale è il principale?
   - Quale è il factory?
   - Come gestisce il campo `arniaId` che può arrivare come int o String dal JSON?

2. In `lib/database/database_helper.dart` individua il pattern Singleton:
   - Quale campo statico contiene l'istanza?
   - Perché il costruttore interno si chiama `_internal`?

3. Crea un modello `Trattamento` completo con:
   - Campi: `id` (int?), `arniaId` (int), `prodotto` (String), `dose` (double?), `completato` (bool)
   - Costruttore named + required
   - `factory Trattamento.fromJson(...)`
   - `Map<String, dynamic> toJson()`
   - `Trattamento copyWith(...)`

---

**Prossimo modulo:** [08 — Generics](08_generics.md)

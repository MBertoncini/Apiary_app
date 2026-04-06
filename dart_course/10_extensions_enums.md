# Modulo 10 — Extensions e Enums

## 10.1 Extensions — Aggiungere Metodi a Tipi Esistenti

Le extensions ti permettono di aggiungere metodi a classi esistenti **senza modificarle**
e senza creare sottoclassi. È come "donare" nuove funzionalità a un tipo.

```dart
// Aggiungiamo un metodo capitalize() alla classe String di Dart
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

// Uso: sembra un metodo nativo di String
print('ciao mondo'.capitalize());    // "Ciao mondo"
print('questo testo lungo'.truncate(10)); // "questo tes..."
```

**Nel progetto** — `lib/services/chat_service.dart` usa questo pattern
per estendere `String` con `capitalize()`.

---

## 10.2 Extensions su Tipi Numerici

```dart
extension IntExt on int {
  Duration get secondi => Duration(seconds: this);
  Duration get minuti => Duration(minutes: this);
  bool get pari => this % 2 == 0;
}

// Uso:
await Future.delayed(5.secondi);  // invece di Duration(seconds: 5)
print(8.pari);   // true
print(7.pari);   // false
```

---

## 10.3 Extensions su Liste

```dart
extension ListaApiario on List<Apiario> {
  List<Apiario> soloAttivi() => where((a) => a.attivo).toList();

  Apiario? trovaPerId(int id) {
    try {
      return firstWhere((a) => a.id == id);
    } catch (_) {
      return null; // firstWhere lancia se non trovato
    }
  }

  Map<String, List<Apiario>> raggruppaPerRegione() {
    Map<String, List<Apiario>> mappa = {};
    for (var a in this) {
      mappa.putIfAbsent(a.regione ?? 'Altro', () => []).add(a);
    }
    return mappa;
  }
}

// Uso:
List<Apiario> attivi = tuttiGliApiari.soloAttivi();
Apiario? trovato = lista.trovaPerId(5);
```

---

## 10.4 Extensions su BuildContext (Flutter)

Un pattern molto usato in Flutter per evitare `MediaQuery.of(context)` verboso:

```dart
extension ContextExt on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
}

// In un Widget:
double larghezza = context.screenWidth;    // invece di MediaQuery.of(context).size.width
```

---

## 10.5 Enum — Enumerazioni

Un `enum` è un tipo che può assumere solo un insieme fisso di valori.
Rendono il codice più leggibile e sicuro dei "magic strings".

```dart
// Senza enum — fragile
String stato = 'attivo'; // potrebbe essere scritto male: 'attivoo', 'Attivo'

// Con enum — sicuro
enum StatoArnia { attiva, invernata, sciamata, morta }
StatoArnia stato = StatoArnia.attiva;

// Switch esaustivo — il compilatore avvisa se manca un caso
String descrizione = switch (stato) {
  StatoArnia.attiva    => 'In produzione',
  StatoArnia.invernata => 'In letargo invernale',
  StatoArnia.sciamata  => 'Sciame partito',
  StatoArnia.morta     => 'Colonia persa',
};
```

**Nel progetto** — `lib/models/osm_vegetazione.dart`:
```dart
enum OsmVegetazioneTipo {
  bosco,
  macchia,
  prato,
  frutteto,
  coltura,
  altro
}
```

---

## 10.6 Enum Avanzati (Dart 2.17+) — Enum con Metodi e Campi

I moderni enum Dart possono avere costruttori, campi e metodi:

```dart
enum RazzaApe {
  ligustica('Ligustica', 'Alta produzione di miele', Colors.amber),
  carnica('Carnica', 'Molto docile', Colors.grey),
  buckfast('Buckfast', 'Resistente alle malattie', Colors.brown),
  nera('Mellifera', 'Locale italiana', Colors.black);

  // Campi dell'enum
  final String nome;
  final String descrizione;
  final Color colore;

  // Costruttore const
  const RazzaApe(this.nome, this.descrizione, this.colore);

  // Metodi
  bool get isDocile => this == carnica || this == buckfast;
}

// Uso:
RazzaApe razza = RazzaApe.ligustica;
print(razza.nome);        // "Ligustica"
print(razza.descrizione); // "Alta produzione di miele"
print(razza.isDocile);    // false
```

---

## 10.7 Enum nel Progetto — `OsmVegetazioneTipo`

`lib/models/osm_vegetazione.dart` usa enum con getter calcolati:

```dart
enum OsmVegetazioneTipo { bosco, macchia, prato, frutteto, coltura, altro }

class OsmVegetazione {
  final OsmVegetazioneTipo tipo;

  // Getter che dipende dal tipo enum
  String get etichetta {
    switch (tipo) {
      case OsmVegetazioneTipo.bosco:    return 'Bosco';
      case OsmVegetazioneTipo.macchia:  return 'Macchia / Gariga';
      case OsmVegetazioneTipo.prato:    return 'Prato';
      case OsmVegetazioneTipo.frutteto: return 'Frutteto';
      case OsmVegetazioneTipo.coltura:  return 'Coltivazione';
      default:                          return 'Vegetazione';
    }
  }

  Color get colore {
    switch (tipo) {
      case OsmVegetazioneTipo.bosco:    return const Color(0xFF2E7D32);
      case OsmVegetazioneTipo.macchia:  return const Color(0xFF689F38);
      case OsmVegetazioneTipo.prato:    return const Color(0xFF9CCC65);
      case OsmVegetazioneTipo.frutteto: return const Color(0xFF00897B);
      case OsmVegetazioneTipo.coltura:  return const Color(0xFFF9A825);
      default:                          return const Color(0xFF558B2F);
    }
  }
}
```

Con gli enum avanzati, questo si riscrivedrebbe più elegantemente:

```dart
enum OsmVegetazioneTipo {
  bosco('Bosco', Color(0xFF2E7D32)),
  macchia('Macchia / Gariga', Color(0xFF689F38)),
  prato('Prato', Color(0xFF9CCC65)),
  frutteto('Frutteto', Color(0xFF00897B)),
  coltura('Coltivazione', Color(0xFFF9A825)),
  altro('Vegetazione', Color(0xFF558B2F));

  final String etichetta;
  final Color colore;
  const OsmVegetazioneTipo(this.etichetta, this.colore);
}

// Ora puoi usare direttamente:
print(OsmVegetazioneTipo.bosco.etichetta); // "Bosco"
print(OsmVegetazioneTipo.bosco.colore);    // Color(0xFF2E7D32)
```

---

## 10.8 Iterare sugli Enum

```dart
enum StatoArnia { attiva, invernata, sciamata, morta }

// Tutti i valori
for (StatoArnia s in StatoArnia.values) {
  print(s.name); // "attiva", "invernata", "sciamata", "morta"
}

// Dal nome (utile per deserializzazione JSON)
String daNome = 'attiva';
StatoArnia stato = StatoArnia.values.byName(daNome);
// oppure:
StatoArnia? stato2 = StatoArnia.values
    .where((s) => s.name == daNome)
    .firstOrNull;
```

---

## 10.9 Extension su Enum — Pattern Combinato

Puoi combinare extension e enum:

```dart
enum StatoColonia { normale, indebolita, rischio, critica }

extension StatoColoniaExt on StatoColonia {
  Color get colore => switch (this) {
    StatoColonia.normale    => Colors.green,
    StatoColonia.indebolita => Colors.yellow,
    StatoColonia.rischio    => Colors.orange,
    StatoColonia.critica    => Colors.red,
  };

  IconData get icona => switch (this) {
    StatoColonia.normale    => Icons.check_circle,
    StatoColonia.indebolita => Icons.warning,
    StatoColonia.rischio    => Icons.error_outline,
    StatoColonia.critica    => Icons.dangerous,
  };

  bool get richiedeIntervento => this == StatoColonia.rischio
      || this == StatoColonia.critica;
}

// Uso in Flutter:
Icon(stato.icona, color: stato.colore),
if (stato.richiedeIntervento) Text('Richiede intervento!'),
```

---

## 10.10 Limitazioni delle Extensions

```dart
// NON puoi aggiungere campi con stato a un'extension
extension StringExt on String {
  String _cache = ''; // ERRORE — le extension non hanno campi di istanza
}

// Ma puoi aggiungere getter calcolati (senza stato)
extension StringExt on String {
  bool get isEmail => RegExp(r'^[\w-]+@[\w-]+\.\w+$').hasMatch(this); // OK
}
```

---

## Esercizi

1. In `lib/models/osm_vegetazione.dart`:
   - Come viene determinato il tipo enum da un `Map<String, String>` di tag OSM?
   - Cerca il metodo `_tipoFromTags` — come usa i valori dell'enum?

2. Crea un `enum TipoControllo` con valori:
   `ispezione, trattamento, alimentazione, smielatura, invernamento`
   
   Aggiungi una extension con:
   - `String get etichetta` — nome leggibile in italiano
   - `bool get richiedeAttrezzatura` — true per smielatura e invernamento
   - `Duration get durataMedia` — stima della durata

3. Crea una extension `StringValidation on String` con:
   - `bool get isValidEmail`
   - `bool get isValidLatitudine` (tra -90 e 90)
   - `String get capitalizzata`
   
   Confrontala con il codice in `lib/utils/validators.dart` — quale approccio è più leggibile?

---

**Prossimo modulo:** [11 — Streams](11_streams.md)

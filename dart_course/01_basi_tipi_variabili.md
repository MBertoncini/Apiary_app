# Modulo 01 — Basi: Tipi e Variabili

## 1.1 Il tuo primo programma Dart

```dart
void main() {
  print('Ciao, Dart!');
}
```

`main()` è il punto di ingresso di ogni programma Dart. In Flutter, il progetto parte
da `lib/main.dart` con una funzione `main` simile.

---

## 1.2 Variabili e Parole Chiave

Dart ha tre modi per dichiarare una variabile:

```dart
var nome = 'Alveare Nord';   // tipo inferito dal compilatore (String)
String cognome = 'Api';      // tipo esplicito
final data = DateTime.now(); // valore assegnato una sola volta a runtime
const pi = 3.14159;          // valore noto a compile-time (costante vera)
```

### Differenza tra `final` e `const`

| | `final` | `const` |
|--|---------|---------|
| Quando viene fissato | A runtime | A compile-time |
| Può essere il risultato di una funzione | Sì | No |
| Uso tipico | Valori calcolati una volta | Letterali, colori, widget statici |

```dart
final ora = DateTime.now();     // OK: calcolato quando il programma gira
const ora2 = DateTime.now();    // ERRORE: non è noto a compile-time

const colore = Color(0xFF2E7D32); // OK: letterale numerico noto a compile-time
```

**Nel progetto:** cerca `const Color(` in `lib/models/osm_vegetazione.dart` —
tutti i colori della vegetazione usano `const` perché sono letterali fissi.

---

## 1.3 Tipi Primitivi

```dart
// Numeri
int telaini = 10;
double peso = 2.35;
num qualsiasi = 42;       // può essere int o double

// Stringhe
String apiario = 'Apiario Monte Bianco';
String multilinea = '''
  Prima riga
  Seconda riga
''';

// Booleani
bool attiva = true;
bool offline = false;

// Nulla (vedremo meglio nel Modulo 04)
String? nota = null;      // nullable: può contenere null
```

---

## 1.4 Interpolazione di Stringhe

Dart usa `$variabile` e `${espressione}` per incorporare valori nelle stringhe:

```dart
String nome = 'Apiario Nord';
int arnie = 5;

print('$nome ha $arnie arnie');
// → "Apiario Nord ha 5 arnie"

print('Il doppio delle arnie è ${arnie * 2}');
// → "Il doppio delle arnie è 10"
```

**Nel progetto** — `lib/utils/validators.dart`:
```dart
// La stringa di errore viene costruita con interpolazione
return 'La latitudine deve essere compresa tra -90 e 90';
```

---

## 1.5 Operatori

### Aritmetici
```dart
int a = 10, b = 3;
print(a + b);   // 13
print(a - b);   // 7
print(a * b);   // 30
print(a / b);   // 3.3333... (sempre double)
print(a ~/ b);  // 3 (divisione intera)
print(a % b);   // 1 (resto)
```

### Confronto e Logica
```dart
print(a > b);    // true
print(a == b);   // false
print(a != b);   // true

bool x = true, y = false;
print(x && y);   // false (AND)
print(x || y);   // true  (OR)
print(!x);       // false (NOT)
```

### Operatori su Null (anticipazione Modulo 04)
```dart
String? testo = null;

// ?? restituisce il valore di destra se quello di sinistra è null
String risultato = testo ?? 'valore default';
print(risultato); // "valore default"
```

---

## 1.6 Conversioni di Tipo

```dart
// String → int
String s = '42';
int n = int.parse(s);          // lancia eccezione se non valido
int? m = int.tryParse(s);      // restituisce null se non valido

// String → double
double d = double.parse('3.14');
double? d2 = double.tryParse('abc'); // null

// int → String
String testo = 42.toString();

// Verifica tipo a runtime
dynamic val = 'ciao';
if (val is String) {
  print(val.toUpperCase()); // Dart "promuove" val a String automaticamente
}
```

**Nel progetto** — `lib/models/regina.dart`:
```dart
// Parsing sicuro di int da JSON (il valore potrebbe essere int o String)
int parsedArniaId = 0;
if (json['arnia'] != null) {
  parsedArniaId = json['arnia'] is int
      ? json['arnia']
      : int.tryParse(json['arnia'].toString()) ?? 0;
}
```
Nota come `int.tryParse()` + `?? 0` gestisce il caso in cui il parsing fallisca.

---

## 1.7 Costanti del Progetto

Apri `lib/constants/` — troverai costanti globali usate in tutto il progetto:

```dart
// Esempio di pattern tipico in Dart per le costanti
class AppConstants {
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const int timeoutSeconds = 30;

  // Costruttore privato: impedisce istanziazione
  AppConstants._();
}
```

`static const` significa: appartiene alla classe (non all'istanza) ed è una costante
vera nota a compile-time.

---

## Esercizi

1. Apri `lib/main.dart` — identifica le variabili `final`, le costanti, e i tipi di base.
2. In `lib/models/arnia.dart` — individua tutti i campi `bool`, `int`, `String?`.
3. In `lib/utils/validators.dart` — trova `int.tryParse()` e `double.tryParse()`
   e spiega perché viene usato `tryParse` invece di `parse`.
4. Scrivi un piccolo programma Dart (nella cartella `test/`) che:
   - Dichiara le variabili: nome apiario (String), numero arnie (int), peso medio (double), attivo (bool)
   - Le stampa con interpolazione di stringhe
   - Converte il numero di arnie in String e viceversa

---

**Prossimo modulo:** [02 — Funzioni](02_funzioni.md)

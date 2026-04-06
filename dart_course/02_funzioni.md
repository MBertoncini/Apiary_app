# Modulo 02 — Funzioni

## 2.1 Funzione Base

```dart
// Tipo di ritorno esplicito + nome + parametri
int somma(int a, int b) {
  return a + b;
}

// void = non ritorna nulla
void stampa(String testo) {
  print(testo);
}

// Inferenza del tipo di ritorno (sconsigliato in codice professionale)
sommaInferita(int a, int b) => a + b;
```

---

## 2.2 Parametri Obbligatori Posizionali

```dart
double calcolaMedia(int covata, int scorte) {
  return (covata + scorte) / 2;
}

calcolaMedia(4, 6); // OK — posizione conta
calcolaMedia(6, 4); // Diverso! Ordine invertito
```

---

## 2.3 Parametri Named (con Nome)

In Dart i parametri con nome si racchiudono in `{}`. Sono opzionali per default.

```dart
void descriviArnia({String nome = '', int telaini = 0, bool attiva = true}) {
  print('$nome — $telaini telaini — attiva: $attiva');
}

// Chiamata: l'ordine non conta, si usa il nome
descriviArnia(nome: 'Arnia A', attiva: false, telaini: 8);
```

### `required` — parametri named obbligatori

```dart
void creaApiario({required String nome, required double lat, double? lon}) {
  // lon è opzionale (nullable), nome e lat sono obbligatori
}

creaApiario(nome: 'Monte Rosa', lat: 45.9);   // OK
creaApiario(lat: 45.9);                        // ERRORE: nome mancante
```

**Nel progetto** — ogni modello usa named + required nel costruttore.
Apri `lib/models/arnia.dart`:

```dart
Arnia({
  required this.id,
  required this.apiario,
  required this.apiarioNome,
  this.note,          // opzionale (nullable)
  required this.attiva,
  this.coloniaAttiva, // opzionale (nullable)
});
```

---

## 2.4 Arrow Function (Funzione Freccia)

Quando il corpo di una funzione è una singola espressione, puoi usare `=>`:

```dart
// Forma lunga
int quadrato(int x) {
  return x * x;
}

// Forma freccia — equivalente
int quadrato(int x) => x * x;

// Anche per metodi di classe
bool get isAuthenticated => _isAuthenticated;
```

**Nel progetto** — `lib/models/voice_entry.dart`:
```dart
// getter calcolato con arrow function
int get telainiTotali =>
    (telainiCovata ?? 0) +
    (telainiScorte ?? 0) +
    (telainiDiaframma ?? 0) +
    (tealiniFoglioCereo ?? 0) +
    (telainiNutritore ?? 0);
```

---

## 2.5 Funzioni come Oggetti (First-Class Functions)

In Dart le funzioni sono oggetti: puoi assegnarle a variabili e passarle come argomenti.

```dart
// Tipo di una funzione: Function, o più specifico
int Function(int) doppio = (x) => x * 2;
print(doppio(5)); // 10

// Passare una funzione come parametro
List<int> trasforma(List<int> lista, int Function(int) fn) {
  return lista.map(fn).toList();
}

List<int> risultato = trasforma([1, 2, 3], doppio);
// risultato = [2, 4, 6]
```

---

## 2.6 Closures (Chiusure)

Una closure è una funzione che "cattura" variabili dal suo contesto:

```dart
Function creaContatore() {
  int count = 0;
  return () {
    count++;         // cattura 'count' dal contesto esterno
    print(count);
  };
}

var conta = creaContatore();
conta(); // 1
conta(); // 2
conta(); // 3
```

**Nel progetto** — `lib/provider_setup.dart`:
```dart
// Il callback 'create' è una closure che cattura il contesto
ChangeNotifierProvider<AuthService>(
  create: (_) => AuthService(), // closure: crea AuthService
),
```

---

## 2.7 Funzioni Anonime (Lambda)

```dart
// Funzione anonima assegnata a variabile
var saluta = (String nome) {
  return 'Ciao, $nome!';
};

// Funzione anonima passata direttamente
List<int> numeri = [3, 1, 4, 1, 5, 9];
numeri.sort((a, b) => a.compareTo(b)); // lambda per comparazione
print(numeri); // [1, 1, 3, 4, 5, 9]
```

---

## 2.8 Parametri Posizionali Opzionali

Diversi dai named: si racchiudono in `[]`, si passano per posizione.

```dart
String formattaData(int giorno, int mese, [int? anno]) {
  if (anno != null) {
    return '$giorno/$mese/$anno';
  }
  return '$giorno/$mese';
}

formattaData(15, 6);       // "15/6"
formattaData(15, 6, 2024); // "15/6/2024"
```

> In pratica nel codice Flutter/Dart moderno si preferiscono i **named parameters**
> perché rendono il codice più leggibile. I posizionali opzionali si vedono meno.

---

## 2.9 Funzioni Ricorsive

```dart
int fattoriale(int n) {
  if (n <= 1) return 1;
  return n * fattoriale(n - 1); // chiama se stessa
}

print(fattoriale(5)); // 120
```

---

## 2.10 Funzioni Async (anticipazione Modulo 06)

Le funzioni che fanno operazioni lente (rete, database) sono `async` e
restituiscono un `Future`:

```dart
Future<String> leggiDati() async {
  // await sospende qui fino a quando il Future completa
  await Future.delayed(Duration(seconds: 1)); // simula attesa
  return 'dati pronti';
}
```

**Nel progetto** — `lib/services/auth_service.dart`:
```dart
Future<bool> checkAuth() async {
  _isLoading = true;
  // ... logica asincrona
  return false;
}
```

---

## 2.11 Dove si usano le Funzioni nel Progetto

| Pattern | File | Riga |
|---------|------|------|
| Named + required | `lib/models/arnia.dart` | costruttore |
| Arrow getter | `lib/models/voice_entry.dart` | `get telainiTotali` |
| Lambda in sort | `lib/services/` | vari |
| Closure in Provider | `lib/provider_setup.dart` | `create: (_) => ...` |
| Async/await | `lib/services/auth_service.dart` | `checkAuth()` |
| Funzione come param | `lib/database/database_helper.dart` | `inTransaction` |

---

## Esercizi

1. In `lib/utils/validators.dart` — ogni metodo è una funzione. Identifica:
   - Tipo di ritorno
   - Parametri (sono required? nullable?)
   - Usa l'arrow function `=>` oppure il corpo `{}`?

2. In `lib/database/database_helper.dart` cerca `inTransaction<T>`:
   - Qual è il tipo del parametro `action`?
   - È una funzione passata come argomento? (sì — è una callback)

3. Scrivi una funzione `valutaArnia` che accetta:
   - `required int telainiCovata`
   - `required int telainiScorte`
   - `String nota = ''` (opzionale con default)
   - Restituisce una `String` con la valutazione ('buona', 'media', 'scarsa')

---

**Prossimo modulo:** [03 — Classi e OOP](03_classi_oop.md)

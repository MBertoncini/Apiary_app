# Modulo 03 — Classi e OOP

## 3.1 Cos'è una Classe

Una classe è un "progetto" da cui si creano oggetti. Racchiude:
- **Campi** (dati)
- **Costruttori** (come creare l'oggetto)
- **Metodi** (comportamenti / funzioni)
- **Getter e Setter** (accesso controllato ai campi)

```dart
class Apiario {
  // --- Campi ---
  int id;
  String nome;
  double latitudine;
  double longitudine;

  // --- Costruttore ---
  Apiario({
    required this.id,
    required this.nome,
    required this.latitudine,
    required this.longitudine,
  });

  // --- Metodo ---
  String descrizione() {
    return '$nome ($latitudine, $longitudine)';
  }
}

// Usare la classe
var api = Apiario(id: 1, nome: 'Apiario Nord', latitudine: 45.5, longitudine: 9.2);
print(api.descrizione()); // "Apiario Nord (45.5, 9.2)"
```

---

## 3.2 `this` — riferimento all'istanza corrente

`this` si riferisce all'oggetto su cui viene chiamato il metodo.
Nel costruttore, `this.campo = campo` assegna il parametro al campo dell'oggetto.

```dart
class Arnia {
  int id;
  String posizione;

  Arnia(int id, String posizione) {
    this.id = id;             // this.id = campo, id = parametro
    this.posizione = posizione;
  }
}
```

La sintassi abbreviata `this.campo` nei parametri del costruttore fa lo stesso
in modo compatto — è quella usata nel progetto:

```dart
Arnia({required this.id, required this.posizione});
// equivalente a: { required int id, required String posizione } { this.id = id; ... }
```

---

## 3.3 Campi Privati

In Dart non esistono `private`/`public` come in Java. Un campo/metodo che inizia
con `_` è **privato al file** (library-private):

```dart
class AuthService {
  bool _isLoading = true;      // privato
  bool _isAuthenticated = false; // privato
  String? _token;              // privato + nullable

  // Getter pubblico — espone il campo privato in sola lettura
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
}
```

**Nel progetto** — `lib/services/auth_service.dart` usa esattamente questo pattern:
i campi interni sono privati (`_`), esposti tramite getter pubblici.

---

## 3.4 Getter e Setter

```dart
class Colonia {
  int _popolazione = 0;

  // Getter: si accede come se fosse un campo
  int get popolazione => _popolazione;

  // Setter: si assegna come se fosse un campo, ma con validazione
  set popolazione(int val) {
    if (val < 0) throw ArgumentError('La popolazione non può essere negativa');
    _popolazione = val;
  }
}

var c = Colonia();
c.popolazione = 5000;      // chiama il setter
print(c.popolazione);      // chiama il getter → 5000
c.popolazione = -1;        // lancia ArgumentError
```

**Getter senza setter (read-only)** — pattern comune nel progetto:

```dart
// lib/models/voice_entry.dart
int get telainiTotali =>
    (telainiCovata ?? 0) + (telainiScorte ?? 0) + ...;
```

---

## 3.5 Ereditarietà (`extends`)

Una classe figlia eredita tutti i campi e metodi della classe madre,
e può aggiungere o sovrascrivere comportamenti.

```dart
class Insetto {
  String nome;
  Insetto(this.nome);

  String suono() => '...';
}

class Ape extends Insetto {
  String alveare;

  Ape(String nome, this.alveare) : super(nome); // chiama il costruttore della madre

  @override
  String suono() => 'Bzzzz'; // sovrascrive il metodo
}

var ape = Ape('Apis mellifera', 'Alveare A');
print(ape.suono()); // "Bzzzz"
print(ape.nome);    // "Apis mellifera" — ereditato
```

`super(nome)` — chiama il costruttore della classe genitore.
`@override` — indica esplicitamente che stai sovrascrivendo un metodo (buona pratica).

---

## 3.6 Classi Astratte (`abstract`)

Una classe astratta non può essere istanziata direttamente; serve come "contratto"
che le classi figlie devono rispettare.

```dart
abstract class SincronizzabileBase {
  // Metodo astratto: DEVE essere implementato dalla classe figlia
  Future<void> sincronizza();

  // Metodo concreto: viene ereditato così com'è
  void logSincronizzazione() {
    print('Sincronizzazione avviata: ${DateTime.now()}');
  }
}

class ApiarioService extends SincronizzabileBase {
  @override
  Future<void> sincronizza() async {
    logSincronizzazione();
    // ... logica specifica per gli apiari
  }
}
```

**Nel progetto** — `lib/services/auth_token_provider.dart`:
```dart
abstract class AuthTokenProvider {
  Future<String?> getToken();
  Future<bool> refreshToken();
}
```
Questo file definisce solo il contratto. `AuthService` lo implementa concretamente.

---

## 3.7 `implements` — Implementare un'Interfaccia

In Dart, qualsiasi classe può essere usata come interfaccia con `implements`.
La classe che implementa deve fornire tutti i metodi:

```dart
abstract class AuthTokenProvider {
  Future<String?> getToken();
  Future<bool> refreshToken();
}

// AuthService si impegna a fornire getToken() e refreshToken()
class AuthService extends ChangeNotifier implements AuthTokenProvider {
  @override
  Future<String?> getToken() async => _token;

  @override
  Future<bool> refreshToken() async {
    // ... logica
    return true;
  }
}
```

Differenza tra `extends` e `implements`:

| | `extends` | `implements` |
|--|-----------|-------------|
| Eredita l'implementazione | Sì | No |
| Quante ne puoi usare | Una sola | Molte |
| Tipico uso | Riutilizzo codice | Definire contratto |

---

## 3.8 Il Costruttore Inizializzante (Initializer List)

Prima che il corpo del costruttore esegua, puoi inizializzare campi con `:`:

```dart
class Apiario {
  final String nome;
  final DateTime creatoIl;

  // ":" introduce la initializer list
  Apiario(String nome)
      : nome = nome.trim().toUpperCase(),
        creatoIl = DateTime.now();
}

var a = Apiario('  apiario nord  ');
print(a.nome);     // "APIARIO NORD"
print(a.creatoIl); // data di creazione
```

---

## 3.9 `toString()` e `==`

Per rendere i tuoi oggetti leggibili e confrontabili:

```dart
class Regina {
  final int id;
  final String razza;

  Regina({required this.id, required this.razza});

  @override
  String toString() => 'Regina($id, $razza)';

  @override
  bool operator ==(Object other) =>
      other is Regina && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

var r1 = Regina(id: 1, razza: 'Ligustica');
var r2 = Regina(id: 1, razza: 'Carnica');
print(r1 == r2);   // true (stesso id)
print(r1);         // "Regina(1, Ligustica)"
```

---

## 3.10 Schema Completo: Il Modello `Arnia` nel Progetto

Apri `lib/models/arnia.dart` e vedrai questi elementi tutti insieme:

```
Arnia
 ├── Campi final (immutabili dopo costruzione)
 ├── Costruttore named + required
 ├── factory Arnia.fromJson(...) → Named constructor
 ├── toJson() → Metodo di serializzazione
 └── copyWith() → Pattern immutabilità (Modulo 07)
```

I campi `final` garantiscono che una volta creato l'oggetto i valori non cambino.
Se serve una versione modificata, si usa `copyWith()`.

---

## Esercizi

1. Apri `lib/models/apiario.dart` — elenca tutti i campi e classifica ognuno:
   - È `final`? Nullable?
   - Quale tipo Dart ha?

2. In `lib/services/auth_service.dart`:
   - Cosa estende `AuthService` (`extends`)?
   - Cosa implementa (`implements`)?
   - Perché ha senso separare le due cose?

3. Crea una classe `Trattamento` con:
   - Campi: `id` (int), `arniaId` (int), `prodotto` (String), `dataInizio` (DateTime)
   - Costruttore named + required
   - Getter `durataGiorni` che calcola i giorni da `dataInizio` ad oggi
   - `toString()` che ritorna una stringa leggibile

---

**Prossimo modulo:** [04 — Null Safety](04_null_safety.md)

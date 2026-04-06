# Modulo 11 — Streams

## 11.1 Future vs Stream

| | `Future<T>` | `Stream<T>` |
|--|-------------|-------------|
| Valori | Uno solo | Molti nel tempo |
| Completamento | Una volta | Può non finire mai |
| Analogia | Ordinare una pizza (aspetti, arriva) | Abbonamento Netflix (arriva sempre) |
| `await` | Sì | Solo con `await for` |

```dart
// Future: un valore futuro
Future<String> getDato() async => 'ciao';

// Stream: sequenza di valori nel tempo
Stream<int> contatore() async* {
  for (int i = 0; i < 5; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i; // "emette" un valore
  }
}
```

---

## 11.2 Creare Uno Stream

### Con `async*` e `yield`

```dart
Stream<String> messaggi() async* {
  yield 'Inizio';
  await Future.delayed(Duration(seconds: 1));
  yield 'Metà';
  await Future.delayed(Duration(seconds: 1));
  yield 'Fine';
}
```

### Con `Stream.fromIterable`

```dart
Stream<int> numeri = Stream.fromIterable([1, 2, 3, 4, 5]);
```

### Con `Stream.periodic` — emette a intervalli

```dart
Stream<DateTime> orologio = Stream.periodic(
  Duration(seconds: 1),
  (_) => DateTime.now(),
);
```

---

## 11.3 Consumare uno Stream

### `await for` — itera asincrono

```dart
Future<void> ascolta() async {
  await for (String msg in messaggi()) {
    print(msg); // eseguito ad ogni valore emesso
  }
  print('Stream terminato');
}
```

### `listen` — callback

```dart
messaggi().listen(
  (msg) => print('Ricevuto: $msg'),         // ad ogni valore
  onError: (e) => print('Errore: $e'),       // se c'è un errore
  onDone: () => print('Stream terminato'),   // alla fine
);
```

---

## 11.4 `StreamController` — Creare Stream Manuali

Per creare stream a cui puoi aggiungere eventi da fuori:

```dart
// Crea il controller
StreamController<String> controller = StreamController<String>();

// Accedi allo stream
Stream<String> stream = controller.stream;

// Emetti valori
controller.add('primo valore');
controller.add('secondo valore');

// Segnala errori
controller.addError(Exception('qualcosa è andato storto'));

// Chiudi lo stream
controller.close();

// Ascolta
stream.listen((val) => print(val));
```

**Nel progetto** — `lib/services/connectivity_service.dart`:
```dart
class ConnectivityService {
  final StreamController<bool> _connectionChangeController =
      StreamController<bool>.broadcast(); // broadcast: più listener possibili

  // Espone solo lo Stream (read-only dall'esterno)
  Stream<bool> get connectionChange => _connectionChangeController.stream;

  void _updateConnectionStatus(ConnectivityResult result) {
    bool hasConnection = result != ConnectivityResult.none;
    if (hasConnection != _hasConnection) {
      _hasConnection = hasConnection;
      _connectionChangeController.add(hasConnection); // emette nuovo stato
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionChangeController.close(); // IMPORTANTE: chiudere il controller
  }
}
```

---

## 11.5 Stream Broadcast vs Single-Subscription

```dart
// Single-subscription (default): solo un listener alla volta
StreamController<int> single = StreamController();
single.stream.listen(print);
// single.stream.listen(print); // ERRORE: già ascoltato

// Broadcast: molti listener contemporaneamente
StreamController<int> broadcast = StreamController.broadcast();
broadcast.stream.listen(print);
broadcast.stream.listen((v) => doSomethingElse(v)); // OK
```

---

## 11.6 Operatori sugli Stream

Gli stream supportano operazioni simili alle liste:

```dart
Stream<int> numeri = Stream.fromIterable([1, 2, 3, 4, 5, 6]);

// map — trasforma ogni elemento
Stream<String> stringhe = numeri.map((n) => 'Arnia $n');

// where — filtra
Stream<int> pari = numeri.where((n) => n % 2 == 0);

// take — primi N elementi
Stream<int> primi3 = numeri.take(3);

// skip — salta i primi N
Stream<int> dopo2 = numeri.skip(2);

// distinct — rimuove consecutivi uguali
Stream<bool> connettivita = Stream.fromIterable([true, true, false, false, true]);
Stream<bool> cambiamenti = connettivita.distinct(); // [true, false, true]
```

---

## 11.7 `StreamSubscription` — Gestire l'Ascolto

```dart
// listen ritorna un StreamSubscription
StreamSubscription<bool> sub = connectivityService.connectionChange.listen(
  (isConnected) {
    if (isConnected) {
      print('Connessione ripristinata — sincronizzazione...');
    } else {
      print('Connessione persa — modalità offline');
    }
  },
);

// Puoi mettere in pausa / riprendere / cancellare
sub.pause();
sub.resume();
sub.cancel(); // IMPORTANTE: sempre cancellare quando non serve più
```

**Nel progetto** — `lib/services/connectivity_service.dart`:
```dart
StreamSubscription? _connectivitySubscription;

ConnectivityService() {
  _connectivitySubscription =
      _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
}

void dispose() {
  _connectivitySubscription?.cancel(); // pulizia corretta
  _connectionChangeController.close();
}
```

---

## 11.8 `StreamBuilder` — Stream nell'UI Flutter

Come `FutureBuilder` ma per stream — si ricostruisce ad ogni evento:

```dart
StreamBuilder<bool>(
  stream: connectivityService.connectionChange,
  initialData: connectivityService.hasConnection,
  builder: (context, snapshot) {
    final isConnected = snapshot.data ?? false;

    return Row(
      children: [
        Icon(
          isConnected ? Icons.wifi : Icons.wifi_off,
          color: isConnected ? Colors.green : Colors.red,
        ),
        Text(isConnected ? 'Online' : 'Offline'),
      ],
    );
  },
)
```

---

## 11.9 Pattern: Stream come Bus di Eventi

Un pattern utile per comunicazione tra componenti senza dipendenze dirette:

```dart
class EventBus {
  static final EventBus _instance = EventBus._();
  factory EventBus() => _instance;
  EventBus._();

  final StreamController<String> _controller = StreamController.broadcast();

  Stream<String> get eventi => _controller.stream;

  void pubblica(String evento) => _controller.add(evento);

  void dispose() => _controller.close();
}

// In un servizio:
EventBus().pubblica('apiario:aggiornato');

// In un widget:
EventBus().eventi
  .where((e) => e.startsWith('apiario:'))
  .listen((_) => setState(() {}));
```

---

## 11.10 Gestione Corretta del Lifecycle

Il problema più comune con gli stream: dimenticare di cancellarli causa memory leak.

```dart
class _ApiarioScreenState extends State<ApiarioScreen> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = connectivityService.connectionChange.listen(_onConnectivityChange);
  }

  void _onConnectivityChange(bool isConnected) {
    if (isConnected) _sincronizza();
  }

  @override
  void dispose() {
    _sub?.cancel(); // FONDAMENTALE: cancella nella dispose
    super.dispose();
  }
}
```

---

## 11.11 Stream vs ChangeNotifier — Quando Usare Cosa

| | `Stream` | `ChangeNotifier` |
|--|----------|-----------------|
| Quando cambia | Emette valore | Chiama notifyListeners() |
| Consumer Flutter | `StreamBuilder` | `Consumer<T>` o `watch()` |
| Tipo dati | Specifico `Stream<T>` | Intero oggetto notifier |
| Sequenza | Sì (valori ordinati) | No (solo "è cambiato") |
| Tipico uso | Connettività, sensori, chat | Stato UI, form, business logic |

---

## Esercizi

1. In `lib/services/connectivity_service.dart`:
   - Perché usa `StreamController.broadcast()` invece del default?
   - Cosa succede se non viene chiamato `dispose()`?
   - Come viene usato `_connectivitySubscription?.cancel()`?

2. Cerca `onConnectivityChanged` nel progetto (è lo stream della libreria `connectivity_plus`):
   - Qual è il tipo del suo Stream?
   - Come viene "ascoltato" nel progetto?

3. Crea una classe `RileveratoreTemperatura` che:
   - Simula letture di temperatura ogni 5 secondi con `Stream.periodic`
   - Espone uno `Stream<double>` con le temperature
   - Ha un metodo `allarme` che filtra le temperature > 35°C
   - Gestisce correttamente la `dispose()`

---

**Prossimo modulo:** [12 — Error Handling](12_error_handling.md)

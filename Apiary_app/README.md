# Apiario Manager - App Flutter

Un'applicazione mobile per la gestione completa degli apiari, delle arnie e di tutte le attività correlate all'apicoltura.

## Caratteristiche

- Gestione completa di apiari e arnie
- Monitoraggio delle regine
- Controlli periodici documentati
- Gestione dei trattamenti sanitari
- Monitoraggio delle fioriture
- Gestione della produzione di miele (melari, smielature)
- Sincronizzazione con server remoto
- Visualizzazione su mappa di apiari e fioriture
- Monitoraggio meteo per gli apiari
- Funzionalità offline

## Requisiti di sistema

- Flutter SDK >=2.18.0 <3.0.0
- Dispositivo Android (API 21+) o iOS (iOS 11+)

## Configurazione del progetto

### Installazione

1. Clona il repository:
   ```
   git clone https://github.com/username/apiario_manager.git
   ```

2. Installa le dipendenze:
   ```
   cd apiario_manager
   flutter pub get
   ```

3. Configura l'URL dell'API in `lib/constants/api_constants.dart`

4. Esegui l'app:
   ```
   flutter run
   ```

## Struttura del progetto

```
apiario_manager/
├── lib/
│   ├── constants/       # Costanti dell'app e configurazioni
│   ├── models/          # Modelli dati
│   ├── screens/         # Schermate dell'app
│   ├── services/        # Servizi (API, auth, storage, ecc.)
│   ├── utils/           # Utility e helper
│   ├── widgets/         # Widget riutilizzabili
│   ├── app.dart         # Configurazione app
│   └── main.dart        # Punto di ingresso
├── assets/              # Risorse (immagini, font, ecc.)
├── pubspec.yaml         # Dipendenze e configurazione
└── README.md            # Documentazione
```

## Sviluppo

### Comandi utili

- Esegui l'app in modalità debug:
  ```
  flutter run
  ```

- Esegui i test:
  ```
  flutter test
  ```

- Genera una build di release:
  ```
  flutter build apk --release  # Android
  flutter build ios --release  # iOS
  ```

### Contribuire

Per contribuire al progetto, si prega di seguire queste linee guida:

1. Fork del repository
2. Crea un branch per la tua feature: `git checkout -b feature/nome-feature`
3. Commit delle modifiche: `git commit -m 'Aggiungi feature'`
4. Push al branch: `git push origin feature/nome-feature`
5. Invia una Pull Request

## Licenza

Questo progetto è concesso in licenza con i termini della licenza MIT.

## Contatti

Per domande o supporto, contattare il team di sviluppo all'indirizzo info@exemplo.com.
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

# Implementazione Google Speech-to-Text API in Apiario Manager

Questo documento descrive l'implementazione del riconoscimento vocale utilizzando le API Google Speech-to-Text nell'app Apiario Manager.

## Panoramica

L'implementazione sostituisce il pacchetto `speech_to_text` originale con un sistema basato su Google Speech-to-Text API, che offre un riconoscimento vocale più accurato e robusto, particolarmente utile per i termini tecnici utilizzati nell'apicoltura.

## Prerequisiti

Per utilizzare questa implementazione, è necessario:

1. Un account Google Cloud Platform
2. Un progetto GCP con Speech-to-Text API abilitata
3. Credenziali di servizio con autorizzazioni per Speech-to-Text

## Files Implementati

Ecco i nuovi file creati per questa implementazione:

- `lib/services/google_speech_recognition_service.dart` - Implementazione del servizio di riconoscimento vocale
- `lib/services/voice_input_manager_google.dart` - Manager per l'input vocale che utilizza Google Speech API
- `lib/services/audio_service.dart` - Servizio per la riproduzione di feedback audio
- `lib/services/voice_feedback_service_updated.dart` - Versione aggiornata del servizio di feedback 
- `lib/config/google_credentials.dart` - File per le credenziali di Google Cloud
- `lib/widgets/google_voice_input_widget.dart` - Widget UI per l'input vocale
- `lib/screens/voice_command_screen_updated.dart` - Schermata aggiornata per l'input vocale

## Struttura del Servizio

L'implementazione segue un'architettura a più livelli:

1. **Livello API** - `GoogleSpeechRecognitionService` comunica direttamente con le API Google
2. **Livello Manager** - `VoiceInputManagerGoogle` coordina il riconoscimento vocale e l'elaborazione dei dati
3. **Livello UI** - `GoogleVoiceInputWidget` fornisce l'interfaccia utente per l'input vocale

## Flusso di Lavoro

1. L'utente preme il pulsante del microfono per avviare la registrazione
2. L'audio viene registrato e inviato a Google Speech-to-Text API
3. Il testo riconosciuto viene elaborato dal `VoiceDataProcessor` (esistente) utilizzando Gemini
4. I dati strutturati vengono visualizzati per la verifica
5. L'utente conferma e i dati vengono salvati nel database

## Configurazione delle Credenziali

Per configurare le credenziali di Google Cloud:

1. Accedi alla [Console Google Cloud](https://console.cloud.google.com/)
2. Crea un progetto o seleziona un progetto esistente
3. Abilita l'API Speech-to-Text
4. Crea un account di servizio con ruolo "Speech-to-Text User"
5. Crea una chiave JSON per l'account di servizio
6. Copia il contenuto del file JSON nelle credenziali in `lib/config/google_credentials.dart`

```dart
// lib/config/google_credentials.dart
class GoogleCredentials {
  static const String serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "your-private-key-id",
  "private_key": "your-private-key",
  "client_email": "your-client-email",
  ...
}
''';
}
```

## Utilizzo

Per utilizzare la nuova implementazione, esegui l'app con la versione aggiornata del main:

```bash
flutter run -t lib/main_updated.dart
```

## Passaggi di Migrazione

Per migrare completamente l'app dalla precedente implementazione:

1. Aggiungi le nuove dipendenze al pubspec.yaml
2. Crea la cartella `assets/sounds` e aggiungi i file audio necessari
3. Configura correttamente le credenziali Google nel file `google_credentials.dart`
4. Sostituisci `provider_setup.dart` con `provider_setup_updated.dart`
5. Sostituisci `main.dart` con `main_updated.dart` o aggiorna il file esistente

## Vantaggi della Nuova Implementazione

- **Maggiore precisione**: Google Speech-to-Text offre un riconoscimento vocale più accurato, soprattutto per termini tecnici
- **Supporto multilingua**: Supporto nativo per l'italiano e altre lingue
- **Feedback migliorato**: Feedback audio e visivo per una migliore esperienza utente
- **Compatibilità**: Risolve i problemi di compilazione con le versioni più recenti di Flutter e Kotlin

## Prestazioni e Considerazioni sui Costi

- Google Speech-to-Text API è un servizio a pagamento, ma offre una quota gratuita per utilizzo limitato
- Per l'utilizzo in produzione, configurare la fatturazione e monitorare l'utilizzo
- Considerare l'implementazione di quote utente per limitare i costi

## Risoluzione dei Problemi

Se incontri problemi con l'implementazione:

1. Verifica che le credenziali siano configurate correttamente
2. Assicurati di avere una connessione Internet attiva
3. Controlla i log per errori specifici dell'API
4. Verifica che i permessi del microfono siano concessi nell'app

Per ulteriori informazioni sulle API Google Speech-to-Text, consulta la [documentazione ufficiale](https://cloud.google.com/speech-to-text/docs).


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
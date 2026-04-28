# Piano refactor – Statistiche & AI

> Documento editabile. Spunta `[x]` quando un task è completato, modifica priorità,
> aggiungi note. Le citazioni `file.dart:NN` puntano a riga al momento dell'analisi
> (2026-04-24, branch `main`).

## Indice priorità
- **P0** – Sicurezza / dati persi / crash. Da fare subito.
- **P1** – Bug funzionali visibili all'utente o regressioni di UX.
- **P2** – Qualità del codice, manutenibilità, debt tecnico.
- **P3** – Feature / miglioramenti opzionali.

---

## P0 – Sicurezza & dati

### [x] P0-1. Revoca e ruota la chiave Gemini esposta
- **File**: `lib/config/api_keys.dart:12`
- **Problema**: `static const String geminiApiKey = 'AIzaSy...'` è committata in chiaro.
  Usata come fallback in `chat_service.dart:245`, `gemini_audio_processor.dart:154`,
  `gemini_data_processor.dart:147`. Chiunque cloni il repo (anche solo per snapshot
  cache di GitHub) può abusarla.
- **Azioni**:
  1. Revoca la chiave dalla console Google AI Studio.
  2. Genera nuova chiave con quota tagliata (es. 50 req/giorno).
  3. Sostituisci con `--dart-define=GEMINI_API_KEY=...` letto via
     `String.fromEnvironment('GEMINI_API_KEY')`.
  4. **Migliore**: sposta l'invocazione Gemini dietro al backend (proxy che firma
     le richieste con la chiave server-side). Elimina la chiave dal client.
  5. Aggiungi `lib/config/api_keys.dart` a `.gitignore` (committa una versione
     `api_keys.example.dart` con placeholder).
- **Note**: file `lib/config/api_keys.dart` ora usa `String.fromEnvironment`
  per Gemini e Wit.ai, niente segreti committati. **Azioni manuali ancora
  richieste**: revocare la chiave esposta sulla console Google AI Studio,
  emettere una nuova chiave, e passarla via `--dart-define=GEMINI_API_KEY=...`
  / `--dart-define=WIT_AI_TOKEN=...` nei comandi di build.

### [x] P0-2. `ChatService._loadChart` è uno stub vuoto
- **File**: `lib/services/chat_service.dart:371-386`
- **Problema**: contiene solo `await Future.delayed(500ms)`; nessuna chiamata a
  `MCPService.generate*Chart`. Il chart visualizzato in chat usa direttamente
  `chartData = params` (riga 337), che contiene `{arniaId, months}` non i dati del
  grafico → `ChartWidget` riceve dati malformati.
- **Azioni**:
  1. Inietta `MCPService` in `_loadChart` (lo è già via `_mcpService`).
  2. Mappa `chartType` ai metodi esistenti e popola `message.chartData` con il
     risultato reale.
  3. Aggiungi gestione errore (oggi swallow nel `try/catch` ma non setta
     un flag visibile).
- **Note**: già implementato in `_loadChart` (esegue il tool MCP, sostituisce
  il placeholder con `chartData` reale, gestisce error path con messaggio
  testuale). Niente da fare.

### [x] P0-3. `StatisticheService._cache` statica + persistenza tra utenti
- **File**: `lib/services/statistiche_service.dart:21`
- **Problema**:
  - Cache `static final Map` non viene mai pulita su logout → utente B vede dati
    di utente A finché non fa pull-to-refresh.
  - Cresce indefinita.
- **Azioni**:
  1. Rendi `_cache` di istanza (rimuovi `static`).
  2. Registra `StatisticheService` come Provider unico (vedi P1-3).
  3. In `AuthService.logout()` invoca `service.clearAllCache()` (oggi è
     `static`; cambia firma).
  4. Aggiungi TTL (5 min) per ciascuna entry.
- **Note**: cache resa di istanza con TTL 5 min, registrato come
  `ProxyProvider3` (deps su Auth) che svuota la cache appena
  `auth.currentUser == null`. Tab dashboard / query builder / NL query ora
  usano `context.read<StatisticheService>()`.

### [x] P0-4. `analisi_telaino_service.syncPending` crea duplicati
- **File**: `lib/services/analisi_telaino_service.dart:91-127`
- **Problema**: dopo upload riuscito di un record con ID locale negativo, si
  chiama `markSynced(record['id'])` che cambia solo lo status. Al successivo
  `getAnalisiByArnia` il backend ritorna lo stesso record con ID positivo,
  `_dao.insert` crea una seconda riga → la lista mostra duplicati.
- **Azioni**:
  1. `postMultipart` ritorna il JSON con `id` server: cattura.
  2. Cancella la riga locale con ID negativo (`_dao.deleteById(record['id'])`).
  3. Inserisci la nuova versione con ID positivo e `sync_status: synced`.
  4. Distingui errori 4xx (drop, log a backend) da 5xx (retry).
- **Note**: `syncPending` ora cattura il JSON server, cancella la riga locale
  con ID negativo e re-inserisce con ID server e `sync_status: synced`.
  Distinzione 4xx/5xx via nuova `HttpStatusException` esposta da `ApiService`.
  Nuovo metodo `AnalisiTelainoDao.markFailed` per i 4xx (richiede colonna
  `last_error` futura per persistere il dettaglio).

---

## P1 – Bug funzionali

### [x] P1-1. `ChatService._executeGeminiLoop` può lanciare `StateError`
- **File**: `lib/services/chat_service.dart:202`
- **Problema**: `parts.firstWhere((p) => p.containsKey('text'))` senza `orElse`
  → se Gemini ritorna solo function calls senza testo a fine loop, crash.
- **Fix**:
  ```dart
  final textPart = parts.firstWhere(
    (p) => p.containsKey('text'),
    orElse: () => null,
  );
  return textPart?['text'] as String?;
  ```
- **Note**: già fatto — `_executeGeminiLoop` ora itera tutte le `parts` e
  concatena con `StringBuffer`, gestendo elementi non-Map e `finishReason`
  vuoto senza crashare.

### [x] P1-2. Switch deformato in `MCPService.executeToolCall`
- **File**: `lib/services/mcp_service.dart:96-134`
- **Problema**: indentazione del case `generateArniaPopulationChart` è
  spostata di 4 livelli; `default` finisce nel posto sbagliato. Funziona
  ma è una trappola per chi modifica.
- **Azioni**:
  1. Riformatta tutto lo switch.
  2. Rimuovi anche la mappa `tools` (riga 13-30) che non viene mai usata
     dal dispatch.
- **Note**: switch riformattato, mappa `tools` morta cancellata, sostituita
  con `_toolNames` (lista di stringhe). Anche P2-1 chiuso.

### [x] P1-3. `StatisticheService` istanziata 3 volte, gating quota incompleto
- **File**: `lib/screens/statistiche/dashboard/dashboard_tab.dart:53`,
  `query_builder/query_builder_tab.dart:53`, `nl_query/nl_query_tab.dart:48`
- **Problema**: ognuno crea la propria istanza → solo `nl_query_tab` passa
  `quotaService`. Il `_cache` statico le accomuna ma non il gating.
- **Azioni**:
  1. Aggiungi in `provider_setup.dart`:
     ```dart
     ChangeNotifierProxyProvider2<ApiService, AiQuotaService, StatisticheService>(
       create: (ctx) => StatisticheService(
         ctx.read<ApiService>(),
         quotaService: ctx.read<AiQuotaService>(),
       ),
       update: (ctx, api, quota, prev) {
         final s = prev ?? StatisticheService(api, quotaService: quota);
         s.attachQuotaService(quota);
         return s;
       },
     ),
     ```
  2. In ciascun tab: `final _service = context.read<StatisticheService>();`
  3. Rimuovi `late final _service` locale.
- **Note**: registrato come `ProxyProvider3<ApiService, AiQuotaService,
  AuthService, StatisticheService>` in `provider_setup.dart`. Tutti e tre i
  tab leggono dal Provider; quota gating ora vale ovunque.

### [x] P1-4. Mancato `recordOptimisticCall` per stats
- **File**: `lib/services/statistiche_service.dart:158-182`
- **Problema**: chat e voice incrementano l'overlay; stats no. Se l'utente
  spara più NL query veloci prima del refresh autoritativo, può superare il
  pool senza essere bloccato.
- **Fix**: in `chiediAI`, dopo `if (quota != null && !quota.canCall(...))`
  e prima del `await _postStats`, chiamare `quota.recordOptimisticCall(AiFeature.stats)`.
- **Note**: aggiunto `recordOptimisticCall(AiFeature.stats)` prima del POST;
  `recordStatsCall` (già esistente) decrementa l'overlay alla risposta.

### [x] P1-5. Cast non difensivi nei widget dashboard
- **Files**:
  - `salute_arnie_widget.dart:54-57, 93`
  - `bilancio_widget.dart:54-57`
  - `varroa_trend_widget.dart:55`
  - probabilmente anche `produzione_widget`, `frequenza_controlli_widget`,
    `regine_statistiche_widget`, `performance_regine_widget`,
    `quote_gruppo_widget`, `andamento_scorte_widget`,
    `produzione_tipo_widget`, `attrezzature_widget`,
    `fioriture_vicine_widget`.
- **Problema**: `(_data!['key'] as num).toInt()` crash se backend ritorna `{}`
  o omette campo. La cache statica può contenere `{}` per errore parziale
  (vedi `dashboard_tab.dart:64-75` dove `catchError` ritorna `<String, dynamic>{}`).
- **Pattern di fix**:
  ```dart
  final ottima  = (_data?['ottima']  as num?)?.toInt() ?? 0;
  final critiche = (_data?['arnie_critiche'] as List?) ?? const [];
  ```
- **Note**: applicato il pattern a salute_arnie, bilancio, varroa_trend,
  produzione, frequenza_controlli, regine_statistiche, performance_regine,
  quote_gruppo, fioriture_vicine, andamento_scorte, produzione_tipo,
  attrezzature.

### [x] P1-6. `_preloadAll` ignora `forceRefresh`
- **File**: `lib/screens/statistiche/dashboard/dashboard_tab.dart:62-78` +
  `:118-123`
- **Problema**: il pull-to-refresh fa `clearAllCache` poi `_preloadAll` ma
  i metodi sono chiamati senza `forceRefresh: true`. Se due refresh in race,
  il secondo legge la cache appena scritta dal primo.
- **Fix**: aggiungere parametro `bool forceRefresh = false` a `_preloadAll`
  e propagarlo. Pull-to-refresh: `_preloadAll(forceRefresh: true)`.
- **Note**: parametro `forceRefresh` propagato a tutti i 12 widget; pull-to-
  refresh ora invoca `_preloadAll(forceRefresh: true)` dopo `clearAllCache`.

### [x] P1-7. `_executeGeminiLoop` esegue tool call in serie
- **File**: `lib/services/chat_service.dart:212-228`
- **Problema**: `for (var call in functionCalls) { ... await _mcpService.executeToolCall(...) }`
  serializza chiamate indipendenti. Gemini consente più function call per turn.
- **Fix**:
  ```dart
  final results = await Future.wait(functionCalls.map((call) async {
    final fc = call['functionCall'];
    final res = await _mcpService.executeToolCall(fc['name'], Map.from(fc['args'] ?? {}));
    return {'functionResponse': {'name': fc['name'], 'response': {'content': res}}};
  }));
  contents.add({'role': 'user', 'parts': results});
  ```
- **Note**: tool call ora eseguite con `Future.wait` su tutte le
  `functionCalls` del turno; latenza ridotta proporzionalmente al numero di
  chiamate parallele.

### [x] P1-8. `chat_screen` scroll forzato a ogni `build`
- **File**: `lib/screens/chat_screen.dart:54-56`
- **Problema**: scrolla in fondo ad ogni rebuild. Se l'utente sta leggendo un
  messaggio precedente durante streaming/typing, viene riportato giù.
- **Fix**: tracciare `_lastMessageCount`; scrollare solo se `messages.length`
  è cambiato.
- **Note**: aggiunto `_lastMessageCount` in `_ChatScreenState`; scroll solo
  quando il count cambia, niente più auto-scroll su tipi nel campo input.

### [x] P1-9. Sort tool MCP esplodono su date/numeri null
- **File**: `lib/services/mcp_service.dart` linee 340, 378, 453, 587, 739, 802, 1081
- **Problema**: `DateTime.parse(t['data_fine'])` o `a['arnia_numero'].compareTo(...)`
  senza null guard → un record marcio rompe l'intero tool.
- **Fix**: helper `_safeParseDate` che ritorna `DateTime(1970)` su null/invalid;
  `compareTo` con coalescing su null.
- **Note**: aggiunto `MCPService._safeParseDate`; usato in tutte le sort
  individuate (trattamenti, controlli, riepilogo telaini, apiario/arnia
  controlli, generateArniaPopulationChart, generateHoneyProductionChart).
  Sort `arnia_numero` ora usa coalescing a stringa.

### [x] P1-10. NL query: errore generico nasconde tutto
- **File**: `lib/screens/statistiche/nl_query/nl_query_tab.dart:106-115`
- **Problema**: solo 504/timeout/400 sono mappati; tutto il resto cade in
  `nlQueryErrGenerico`. Errori auth, network, server 500 sono indistinguibili.
- **Fix**: aggiungi case 401/403 → "sessione scaduta", 500/502/503 → "servizio
  temporaneamente non disponibile". In dev mode (`kDebugMode`) appendi anche
  il messaggio raw.
- **Note**: aggiunti case 401/403 e 5xx, plus suffix `[debug]` con raw in
  `kDebugMode`. Nuove stringhe `nlQueryErrSessione` / `nlQueryErrServizio` in
  IT/EN.

### [x] P1-11. Welcome message duplicato in chat
- **File**: `lib/services/chat_service.dart:37-67, 87-97`,
  `lib/screens/chat_screen.dart:51`
- **Problema**: hardcoded ITA in costruttore + `setWelcomeMessage` chiamato a
  ogni `build` di `ChatScreen`. Se localizzazione cambia tra rebuild, può
  causare loop notify→build→notify. Inoltre il welcome IT appare brevemente
  prima del rebuild localizzato.
- **Fix**:
  1. Costruisci `ChatService` senza welcome message; inserisci messaggio solo
     dopo prima `setWelcomeMessage`.
  2. In `setWelcomeMessage` confronta prima `if (message == _welcomeMessage) return;`.
- **Note**: `setWelcomeMessage` ora idempotente (early return se uguale).
  Il default ITA in `ChatService` resta solo come bootstrap (P2-12 aperto se
  servirà un fix più radicale, ma ora il loop notify→build→notify è risolto).

### [x] P1-12. Gating bypassabile con chiave Gemini personale ma counter inflated
- **File**: `lib/services/ai_quota_service.dart:269-271, 449-520`
- **Problema**: con `hasPersonalGeminiKey`, voice non è bloccata ma
  `recordVoiceCallToBackend` continua a incrementare `voice_today` e
  `total_today`. Il banner paywall mostra contatori inflati.
- **Fix**: skippa `recordVoiceCallToBackend` se `_hasPersonalGeminiKey`,
  oppure invia un flag `personal_key: true` che il backend escluda dai
  contatori del tier.
- **Note**: short-circuit in `recordVoiceCallToBackend`: se chiave personale,
  scala l'overlay ottimistico e ritorna senza POST. Counter di tier non più
  inflato per chiamate fatte con chiave personale.

### [x] P1-13. `markSynced` ignora 4xx vs 5xx
- **File**: `lib/services/analisi_telaino_service.dart:123-126`
- **Problema**: catch generico → un record con dati corrotti viene riprovato
  ad ogni sync per sempre.
- **Fix**: distingui status code; per 4xx → marca come `failed` con
  `last_error`. (Richiede esposizione dello status da `ApiService`.)
- **Note**: introdotta `HttpStatusException` (in `api_service.dart`); 4xx →
  `markFailed`, 5xx/network → record resta pending. Colonna `last_error`
  non aggiunta a schema (richiederebbe migrazione DB), per ora solo
  `debugPrint`.

### [ ] P1-14. Chiave Groq inviata in chiaro al backend
- **File**: `lib/services/statistiche_service.dart:170` (lato client) +
  endpoint `/api/stats/nl-query/` lato server.
- **Problema**: `body['groq_api_key'] = groqApiKey;` viaggia su HTTPS ma il
  backend potrebbe loggarla. Verificare server-side che non finisca in log /
  Sentry.
- **Azioni**:
  1. Audit log lato Django.
  2. Considerare di scartare la chiave dopo l'uso (non persistere).
  3. Considerare client-side direct call a Groq se l'utente ha la propria chiave.
- **Note**:

---

## P2 – Qualità & manutenibilità

### [x] P2-1. Mappa `tools` morta in MCPService
- **File**: `lib/services/mcp_service.dart:13-30`
- **Azione**: cancella. La dispatch reale è lo switch in `executeToolCall`.

### [x] P2-2. `_modelFallbacks` duplicato in 3 file
- **Files**: `chat_service.dart:26`, `gemini_audio_processor.dart:20`,
  `gemini_data_processor.dart:16`
- **Azione**: estrarre in `lib/constants/gemini_constants.dart`:
  ```dart
  const kGeminiModelFallbacks = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-3-flash-preview',
    'gemini-3.1-flash-lite-preview',
  ];
  ```
- **Note**: creato `lib/constants/gemini_constants.dart` con
  `kGeminiBaseUrl` + `kGeminiModelFallbacks`. ChatService /
  GeminiAudioProcessor / GeminiDataProcessor li importano.

### [ ] P2-3. `_handleFinalResponse` matcha solo il primo `[GENERA_GRAFICO:…]`
- **File**: `lib/services/chat_service.dart:294-353`
- **Azione**: usa `regex.allMatches(...)` se è un comportamento atteso, oppure
  documenta esplicitamente "1 grafico per messaggio" nel system prompt.

### [ ] P2-4. `MCPService` health score scarico di logica
- **File**: `lib/services/mcp_service.dart:1047-1061`
- **Problema**: pesi arbitrari (regina 30, uova 20, problemi -30, +5×covata).
  Non è allineato a `getSaluteArnie` del backend.
- **Azioni**:
  1. Rimuovi calcolo client; chiama `StatisticheService.getSaluteArnie(apiarioId)`
     e passa il dato già calcolato.
  2. Oppure documenta lo score con costanti nominate
     (`_kRegineScore`, `_kCovataScorePerFrame`).

### [ ] P2-5. Soglie hardcoded "stato_famiglia" telaini
- **File**: `lib/services/mcp_service.dart:624-627`
- **Problema**: `>= 5` forte / `<= 2` debole indipendente dalla taglia arnia.
- **Azione**: parametrizzare in funzione della dimensione totale dell'arnia
  (10/12/13 telaini).

### [ ] P2-6. Fallback `List.filled(10, 'vuoto')` in MCPService
- **Files**: `mcp_service.dart:397, 471, 526, 603, 754, 820`
- **Problema**: ignora arnie da 6/8/12/13 telaini.
- **Azione**: leggere taglia da `arnia['numero_telaini']` o da modello.

### [ ] P2-7. Euristica "efficacia trattamento" testuale
- **File**: `lib/services/mcp_service.dart:1124-1129`
- **Problema**: cerca "fallito" / "inefficace" nelle note. Falsi negativi
  facili.
- **Azione**: aggiungere campo `efficace: bool` nel modello backend e usare
  quello.

### [x] P2-8. `recordVoiceCallToBackend` doppio conteggio durante flush
- **File**: `lib/services/ai_quota_service.dart:225-228, 693-719`
- **Problema**: `usedFor(voice) = backend + optimistic + pending`. Durante
  `_flushPendingVoice`, il backend incrementa `voice_today` mentre i record
  pending sono ancora in coda → conteggio doppio finché flush non termina.
- **Azione**: rimuovi `pending` dalla somma durante un flush attivo
  (flag `_flushInProgress`).
- **Note**: aggiunto `_flushInProgress`; `usedFor` e `totalUsed` escludono
  i pending durante il flush.

### [x] P2-9. `AiTierUpgradeScreen` legge `allTierLimits` via ChatService
- **File**: `lib/screens/ai_tier_upgrade_screen.dart:39, 57, 97`
- **Problema**: dipendenza inversa (ChatService → AiQuotaService); se l'utente
  apre il paywall senza aver mai aperto la chat, può vedere fallback statico.
- **Azione**: leggi direttamente da `Provider.of<AiQuotaService>(context).allTierLimits`.
- **Note**: `AiTierUpgradeScreen` ora consuma direttamente
  `AiQuotaService.allTierLimits` e fa `quota.refresh()` se mancano. Pulsanti
  upgrade/activate continuano a delegare a `ChatService.activateCode` (che
  ora è un thin wrapper).

### [ ] P2-10. `setPersonalKey` non reattivo a cambio chiave
- **File**: `lib/provider_setup.dart:117-134`
- **Problema**: aggiornato solo a `update` del proxy; se l'utente cambia chiave
  da Settings senza causare rebuild, ChatService usa quella precedente.
- **Azione**: trasforma `_personalApiKey` in callback letto a chiamata, oppure
  ascolta `AuthService` con listener interno in `ChatService`.

### [ ] P2-11. NL query rilegge SharedPreferences a ogni invio
- **File**: `lib/screens/statistiche/nl_query/nl_query_tab.dart:88-97`
- **Azione**: trasforma `AiQuotaLocalTracker` in `ChangeNotifier` registrato
  come Provider; aggiorna in tempo reale quando le settings cambiano.

### [ ] P2-12. Welcome hardcoded ITA in `ChatService`
- **File**: `lib/services/chat_service.dart:37`
- **Azione**: rimuovi default; richiedi che ChatScreen chiami sempre
  `setWelcomeMessage` prima del primo build (in `initState`).

### [x] P2-13. Stato `_personalApiKey` non passato a `GeminiDataProcessor`
- **File**: `lib/services/gemini_data_processor.dart` non è in
  `provider_setup.dart`. Viene creato altrove? Cerca usi.
- **Azione**: ovunque sia istanziato, applicare la chiave personale come per
  `GeminiAudioProcessor` (vedi `voice_command_screen.dart:75`).
- **Note**: nessun import di `GeminiDataProcessor` in tutto `lib/` (solo
  self-reference). È codice morto. La classe ha già `setPersonalKey`, quindi
  appena qualcuno la istanzierà basterà chiamarla. Niente da fare ora.

---

## P3 – Feature & UX

### [ ] P3-1. Endpoint backend aggregato `/api/stats/dashboard-bundle`
- **Motivazione**: `_preloadAll` fa 12 GET in parallelo all'avvio dashboard.
  Su rete lenta o backend cold-start su PythonAnywhere è lento.
- **Azione backend**: vista DRF che ritorna tutti i widget visibili in 1 chiamata.
- **Azione client**: nuovo metodo `StatisticheService.getDashboardBundle()`
  + modifica `dashboard_tab.dart` per consumarlo.

### [ ] P3-2. Personalizzazione widget dashboard
- **Stato attuale**: backend ha già `getDashboardConfig` /
  `saveDashboardConfig`. Client li ignora (`_visibleWidgets` hardcoded in
  `dashboard_tab.dart:34-47`).
- **Azione**: leggi config, mostra UI "Aggiungi/rimuovi widget", salva.

### [ ] P3-3. Filtro apiario in dashboard
- **Stato**: tutti gli endpoint stats accettano `apiarioId`. La dashboard non
  espone selettore.
- **Azione**: dropdown in AppBar; propagare a tutti i widget.

### [ ] P3-4. Streaming risposta chat (`streamGenerateContent`)
- **Motivazione**: oggi blocco totale fino al `200`. Streaming migliora UX.
- **Azione**: passare a SSE/streaming. Refactor `_callGeminiApi` + UI per
  rendering progressivo.

### [ ] P3-5. Persistenza cronologia chat
- **Problema**: messaggi solo in memoria; al rebuild della MaterialApp si
  perdono.
- **Azione**: salva conversazione in SQLite (DAO dedicato) con TTL 30 giorni.

### [ ] P3-6. `AiQuotaBanner` widget riusabile
- **Motivazione**: chat / voice / nl-query duplicano UI banner quota.
- **Azione**: estrai `lib/widgets/ai_quota_banner.dart` parametrizzato per
  `AiFeature`.

### [ ] P3-7. Compressione audio prima dell'upload Gemini
- **File**: `lib/services/gemini_audio_processor.dart:131-149`
- **Problema**: 15MB AAC → 20MB base64 in JSON. Lento su rete debole.
- **Azione**: transcode a Opus 24kbps (libreria FFmpeg / native plugin)
  prima del base64.

### [ ] P3-8. Whisper.cpp on-device come fallback offline
- **Motivazione**: voice è 100% online. Whisper small può girare on-device
  (~70MB).

### [ ] P3-9. Score "salute arnie" client-side mostrato anche nel form controllo
- **Motivazione**: oggi calcoli e warning stanno solo in `analisi_telaino_screen`.
  Mostrarli in `controllo_form_screen` chiude il loop.

### [ ] P3-10. Salvare conteggi YOLO su `controllo_arnia`
- **Motivazione**: arricchire dashboard `salute_arnie` con dati di detection.
- **Azione backend**: nuovo campo o tabella. Client: passare conteggi.

### [ ] P3-11. "Coming soon" per IAP è obsoleto
- **File**: `lib/screens/ai_tier_upgrade_screen.dart:89-91`
- **Stato**: `subscription_service.dart` esiste già (RevenueCat integration in
  memoria). Verificare se mostrare flow attivo.

---

## Ordine di esecuzione consigliato
1. **Sprint sicurezza (1 settimana)**: P0-1, P0-2, P0-3, P0-4, P1-1, P1-2.
2. **Sprint refactor (1 settimana)**: P1-3, P1-4, P1-5, P1-6, P1-11, P2-1, P2-2.
3. **Sprint UX (1 settimana)**: P1-7, P1-8, P1-9, P1-10, P3-6.
4. **Sprint quote AI (1 settimana)**: P1-12, P1-13, P1-14, P2-8, P2-9, P2-10.
5. **Backlog miglioramenti**: P2-3..7, P2-11..13, tutti i P3.

---

## Note di sessione
> Aggiungi qui decisioni, link a PR, note di test:

- 2026-04-26 — sessione di refactor su sprint sicurezza + gran parte degli
  sprint refactor / quote AI. Completati: P0-1, P0-2, P0-3, P0-4, P1-1, P1-2,
  P1-3, P1-4, P1-5, P1-6, P1-7, P1-8, P1-9, P1-10, P1-11, P1-12, P1-13, P2-1,
  P2-2, P2-8, P2-9, P2-13. `flutter analyze` clean (solo warning preesistenti).
  Da fare manualmente su Google AI Studio: revoca chiave esposta + nuova
  build con `--dart-define=GEMINI_API_KEY=...`.
- Aperti: P1-14 (audit log Django), P2-3..7, P2-10..12, tutti i P3.
-

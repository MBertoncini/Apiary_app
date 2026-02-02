# LEGGIMI - Guida Completa al Progetto Apiario Manager

> Questo documento serve come riferimento per qualsiasi AI (o sviluppatore) che lavori su questo progetto.
> Leggilo SEMPRE prima di apportare modifiche.

---

## 1. PANORAMICA DEL SISTEMA

Il progetto **Apiario Manager** e' un sistema di gestione apicoltura composto da **due repository Git separati** che lavorano insieme:

| Componente | Repository | Percorso locale | Tecnologia |
|---|---|---|---|
| **Backend + Web App** | `MBertoncini/Apiary` | `I:\Progetti Git\Apiary` | Django 4.2, DRF, SQLite |
| **App Mobile** | `MBertoncini/Apiary_app` | `I:\Progetti Git\Apiary_app` | Flutter (Dart) |

**Hosting**: Il backend gira su **PythonAnywhere** all'indirizzo `https://cible99.pythonanywhere.com`

**Database**: SQLite su PythonAnywhere (percorso server: `/home/Cible99/Apiary/db.sqlite3`)

---

## 2. ARCHITETTURA DEL BACKEND DJANGO

### 2.1 Struttura del progetto Django
```
Apiary/
├── apiario_manager/          # Progetto Django principale
│   ├── settings.py           # Configurazione (DB, JWT, CORS, REST Framework)
│   ├── urls.py               # Routing principale: /admin, /app/, /api/v1/
│   └── wsgi.py               # WSGI per PythonAnywhere
├── core/                     # App Django principale (UNICA app)
│   ├── models.py             # TUTTI i modelli del database (~25 modelli)
│   ├── views.py              # Viste web (template-based, per il sito)
│   ├── api_views.py          # ViewSet REST API (per l'app Flutter)
│   ├── serializers.py        # Serializzatori DRF (JSON <-> Model)
│   ├── api_urls.py           # Router DRF + URL API
│   ├── urls.py               # URL viste web
│   ├── forms.py              # Form Django (per il sito web)
│   ├── admin.py              # Registrazione admin Django
│   ├── auth_views.py         # Login/Registrazione custom
│   ├── decorators.py         # Decoratori personalizzati
│   ├── meteo_utils.py        # Utility meteo (OpenWeatherMap)
│   ├── context_processors.py # Context processor per template
│   ├── templatetags/         # Tag template custom
│   └── migrations/           # Migrazioni database
├── templates/                # Template HTML (web app)
├── static/                   # File statici (CSS, JS, immagini)
├── requirements.txt          # Dipendenze Python
└── manage.py
```

### 2.2 Modelli principali (core/models.py)
```
Gruppo, MembroGruppo, InvitoGruppo          → Gruppi collaborativi
Apiario                                      → Apiari con geolocalizzazione
Arnia                                        → Arnie con colore e stato
ControlloArnia                               → Ispezioni arnie
Regina, StoriaRegine                         → Regine e genealogia
Melario                                      → Melari
Smielatura                                   → Raccolti miele
Fioritura                                    → Fioriture
TipoTrattamento, TrattamentoSanitario        → Trattamenti sanitari
Pagamento, QuotaUtente                       → Pagamenti e quote
CategoriaAttrezzatura                        → Categorie attrezzature
Attrezzatura                                 → Attrezzature
ManutenzioneAttrezzatura                     → Manutenzioni
SpesaAttrezzatura                            → Spese attrezzatura
PrestitoAttrezzatura                         → Prestiti attrezzatura
InventarioAttrezzature                       → Inventario
DatiMeteo, PrevisioneMeteo                   → Dati meteo
Profilo, ImmagineProfilo                     → Profili utente
```

### 2.3 Due sistemi di viste PARALLELI

**IMPORTANTE**: Il backend ha DUE sistemi separati che servono gli stessi dati:

1. **Viste Web** (`core/views.py` + `core/urls.py`) → Template HTML, usate dal sito web sotto `/app/`
2. **API REST** (`core/api_views.py` + `core/api_urls.py`) → JSON, usate dall'app Flutter sotto `/api/v1/`

Quando aggiungi un nuovo modello/funzionalita':
- Se serve al sito web → aggiungi in `views.py` + `urls.py` + template
- Se serve all'app mobile → aggiungi in `serializers.py` + `api_views.py` + `api_urls.py`
- Se serve a entrambi → **aggiungi in ENTRAMBI i posti**

### 2.4 Autenticazione
- **Sito web**: Session-based (Django standard login)
- **API REST**: JWT via `djangorestframework-simplejwt`
  - `POST /api/v1/token/` → ottieni access + refresh token
  - `POST /api/v1/token/refresh/` → rinnova access token
  - Access token dura **1 giorno**, refresh token **30 giorni**
  - Ogni richiesta API richiede header `Authorization: Bearer <access_token>`

### 2.5 Paginazione API
- Attiva di default: `PageNumberPagination` con `PAGE_SIZE = 20`
- Le risposte paginata hanno formato: `{ "count": N, "next": url, "previous": url, "results": [...] }`
- L'app Flutter gestisce sia risposte paginata che liste dirette (vedi `_buildUrl` in `api_service.dart`)

---

## 3. ARCHITETTURA DELL'APP FLUTTER

### 3.1 Struttura del progetto Flutter
```
Apiary_app/lib/
├── main.dart                    # Entry point
├── app.dart                     # MultiProvider setup
├── provider_setup.dart          # Configurazione provider
├── constants/
│   ├── api_constants.dart       # URL endpoints (baseUrl + tutti gli endpoint)
│   ├── app_constants.dart       # Route, storage keys, feature flags
│   └── theme_constants.dart     # Tema (colori miele/carta, font)
├── models/                      # 18 modelli Dart (fromJson/toJson)
├── services/                    # 30+ servizi
│   ├── api_service.dart         # Client HTTP centralizzato
│   ├── auth_service.dart        # Autenticazione (ChangeNotifier)
│   ├── storage_service.dart     # SharedPreferences
│   ├── api_cache_helper.dart    # Cache offline
│   ├── attrezzatura_service.dart # Logica attrezzature + pagamenti auto
│   ├── pagamento_service.dart   # Gestione pagamenti
│   └── ...                      # Altri servizi dominio
├── screens/                     # 35+ schermate organizzate per dominio
│   ├── auth/                    # Login, registrazione
│   ├── apiario/                 # Lista, dettaglio, form apiario
│   ├── arnia/                   # Lista, dettaglio, form arnia
│   ├── attrezzatura/            # Lista, dettaglio, form, spese, manutenzioni
│   ├── pagamento/               # Lista, dettaglio, form, quote
│   └── ...                      # Altri domini
├── widgets/                     # 15+ widget riutilizzabili
├── utils/
│   └── route_generator.dart     # Routing completo (45+ route)
├── database/                    # SQLite locale + sync
│   ├── database_helper.dart     # Singleton DB
│   ├── sync_service.dart        # Push/pull sync
│   └── dao/                     # Data access objects
└── providers/                   # Riverpod state management
```

### 3.2 State Management (IBRIDO)
L'app usa **due** sistemi di state management:
- **Provider (ChangeNotifier)**: Per servizi fondamentali (`AuthService`, `ApiService`)
- **Riverpod (StateNotifier)**: Per stato dominio specifico (apiari, connettivita', sync)

### 3.3 Come funziona ApiService
Il file `api_service.dart` e' il cuore delle comunicazioni:
- Metodi: `get()`, `post()`, `put()`, `delete()`
- `_buildUrl(endpoint)` costruisce l'URL completo:
  - Se l'endpoint inizia con `http` → lo usa cosi' com'e'
  - Se inizia con `/api/v1` → aggiunge solo `baseUrl`
  - Altrimenti → aggiunge `baseUrl + /api/v1 + endpoint`
- **Quindi**: `apiService.get('/gruppi/')` diventa `https://cible99.pythonanywhere.com/api/v1/gruppi/`
- **E anche**: `apiService.get(ApiConstants.gruppiUrl)` funziona uguale (URL completo)

### 3.4 Pattern Cache Offline
```
if (online) {
    try: fetch API → salva in cache → ritorna dati
    catch: carica da cache (fallback)
} else {
    carica da cache (o dati di default)
}
```

### 3.5 Logica Pagamenti Automatici (attrezzatura_service.dart)
Quando si crea un'attrezzatura, spesa o manutenzione con un costo > 0:
1. `createAttrezzatura()` con prezzo → crea SpesaAttrezzatura + Pagamento
2. `createSpesaAttrezzatura()` → crea sempre Pagamento
3. `createManutenzione()` con costo → crea SpesaAttrezzatura + Pagamento
4. Se `condiviso_con_gruppo == true` → il pagamento ha `gruppo` settato
5. Se personale → `gruppo = null`

---

## 4. REGOLE D'ORO PER LE MODIFICHE

### 4.1 Aggiungere un nuovo modello/entita'

**Lato Django (Apiary):**
1. Aggiungi il modello in `core/models.py`
2. Crea e applica migrazione: `python manage.py makemigrations && python manage.py migrate`
3. Aggiungi serializer in `core/serializers.py`
4. Aggiungi ViewSet in `core/api_views.py`
5. Registra nel router in `core/api_urls.py`
6. Se serve anche al sito web: aggiungi vista in `views.py`, URL in `urls.py`, template
7. **Deploya su PythonAnywhere** (vedi sezione 5)

**Lato Flutter (Apiary_app):**
1. Crea modello Dart in `lib/models/` con `fromJson()` e `toJson()`
2. Aggiungi URL endpoint in `lib/constants/api_constants.dart`
3. Crea servizio in `lib/services/` (se ha logica complessa)
4. Aggiungi route in `lib/constants/app_constants.dart`
5. Crea schermate in `lib/screens/<dominio>/`
6. Registra route in `lib/utils/route_generator.dart`
7. Aggiungi al drawer in `lib/widgets/drawer_widget.dart` (se necessario)

### 4.2 CORRISPONDENZA MODELLI Django ↔ Flutter

**CRITICO**: I modelli Flutter DEVONO corrispondere ESATTAMENTE ai modelli Django.

| Django (Python) | Flutter (Dart) | Note |
|---|---|---|
| `snake_case` field | `camelCase` field | `fromJson` usa `json['snake_case']` |
| `CharField(choices=...)` | `static const List<String>` | I valori devono essere IDENTICI |
| `ForeignKey` | `int?` (solo l'ID) | Il serializer puo' aggiungere `_nome` |
| `TextField(blank=True)` | `String?` o `String` | Dipende se `null=True` |
| `DecimalField` | `double?` | Usa `double.tryParse(json[...].toString())` |
| `DateField` | `DateTime?` | Usa `DateTime.parse(json[...])` |
| `BooleanField(default=False)` | `bool` con default | |
| `auto_now_add=True` | campo read-only | Non inviare nel `toJson()` |

**Esempio di errore comune**: Django ha `TIPO_CHOICES = [('ordinaria', 'Ordinaria'), ...]` e nel Flutter scrivi `tipiManutenzione = ['preventiva', ...]` → il server rifiuta il valore!

**Regola**: Quando crei un modello Flutter, LEGGI SEMPRE `core/models.py` per verificare:
- I nomi esatti dei campi
- I valori delle CHOICES
- Quali campi sono required vs optional
- Quali campi sono read-only (auto_now, auto_now_add)

### 4.3 I Serializer aggiungono campi extra

Nei serializer Django, spesso si aggiungono `SerializerMethodField` che NON esistono nel modello:
```python
class AttrezzaturaSerializer(serializers.ModelSerializer):
    categoria_nome = serializers.CharField(source='categoria.nome', read_only=True)
    proprietario_username = serializers.CharField(source='proprietario.username', read_only=True)
```
Questi campi extra (`categoria_nome`, `proprietario_username`, `tipo_display`, `stato_display`) devono essere presenti nel modello Flutter come campi opzionali (`String?`) e popolati nel `fromJson()`.

### 4.4 Gestione errori comuni di tipo

**`double` da JSON**: Il server puo' restituire un numero come `"10.50"` (stringa) o `10.5` (numero).
Usa SEMPRE: `double.tryParse(json['campo'].toString()) ?? 0.0`

**`int` da JSON**: Stesso problema.
Usa: `json['id'] is String ? int.parse(json['id']) : json['id']`

**`Map<String, dynamic>` esplicito**: Se crei una mappa con tipi misti (String e double), Dart potrebbe inferire `Map<String, String>`. Dichiara SEMPRE il tipo esplicito:
```dart
final data = <String, dynamic>{
  'stato': 'completata',
  'costo': 150.0,  // double, non String!
};
```

---

## 5. DEPLOY SU PYTHONANYWHERE

### 5.1 Processo di deploy

Il backend gira su **PythonAnywhere** (utente: `Cible99`). Il deploy segue questo flusso:

```
[Locale] git commit + git push origin main
    ↓
[PythonAnywhere] git pull origin main
    ↓
[PythonAnywhere] python manage.py migrate (se ci sono nuove migrazioni)
    ↓
[PythonAnywhere] Reload web app (dalla dashboard o API)
```

### 5.2 Percorsi sul server PythonAnywhere
```
/home/Cible99/Apiary/              # Root progetto Django
/home/Cible99/Apiary/db.sqlite3    # Database SQLite
/home/Cible99/Apiary/static/       # File statici (collectstatic)
/home/Cible99/Apiary/media/        # File media (upload)
```

### 5.3 Come fare deploy

**Opzione 1 - Console PythonAnywhere (web)**:
1. Vai su `https://www.pythonanywhere.com` → login come `Cible99`
2. Apri una console Bash
3. Esegui:
```bash
cd /home/Cible99/Apiary
git pull origin main
python manage.py migrate
python manage.py collectstatic --noinput
```
4. Vai su "Web" tab → clicca "Reload" su `cible99.pythonanywhere.com`

**Opzione 2 - API PythonAnywhere** (se hai un token API):
```bash
# Pull e reload via API
curl -X POST "https://www.pythonanywhere.com/api/v0/user/Cible99/consoles/" \
  -H "Authorization: Token YOUR_API_TOKEN" \
  -d "command=cd /home/Cible99/Apiary && git pull && python manage.py migrate"

# Reload webapp
curl -X POST "https://www.pythonanywhere.com/api/v0/user/Cible99/webapps/cible99.pythonanywhere.com/reload/" \
  -H "Authorization: Token YOUR_API_TOKEN"
```

### 5.4 Checklist post-deploy
- [ ] Il sito web funziona? → `https://cible99.pythonanywhere.com/`
- [ ] L'API risponde? → `https://cible99.pythonanywhere.com/api/v1/` (dovrebbe mostrare la root DRF)
- [ ] Swagger funziona? → `https://cible99.pythonanywhere.com/api/docs/`
- [ ] L'app Flutter riesce a fare login?
- [ ] I nuovi endpoint rispondono? (testa con curl o Swagger)

### 5.5 ATTENZIONE: Migrazioni
- PythonAnywhere usa **SQLite** → non supporta bene ALTER TABLE complessi
- Se una migrazione fallisce, potrebbe essere necessario ricreare il DB
- Fai SEMPRE backup prima di migrazioni importanti: `cp db.sqlite3 db.sqlite3.backup`
- I file di migrazione (`core/migrations/`) DEVONO essere committati e pushati

---

## 6. CONFIGURAZIONI IMPORTANTI

### 6.1 Django settings.py
```python
ALLOWED_HOSTS = ['Cible99.pythonanywhere.com', 'localhost', '127.0.0.1']
CORS_ALLOW_ALL_ORIGINS = True    # L'app Flutter puo' chiamare da qualsiasi origine
REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,             # Attenzione: le risposte sono paginata!
}
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=30),
    'ROTATE_REFRESH_TOKENS': True,
}
```

### 6.2 Flutter api_constants.dart
```dart
static const String baseUrl = "https://cible99.pythonanywhere.com";
static const String apiPrefix = "/api/v1";
```
Tutti gli endpoint sono costruiti come: `baseUrl + apiPrefix + '/nome-endpoint/'`

### 6.3 Convenzione URL degli endpoint
- Django Router genera automaticamente: `GET/POST /api/v1/attrezzature/` e `GET/PUT/DELETE /api/v1/attrezzature/{id}/`
- Nel Flutter, usiamo: `ApiConstants.attrezzatureUrl` per la lista e `'${ApiConstants.attrezzatureUrl}$id/'` per il dettaglio
- **IMPORTANTE**: Gli URL devono SEMPRE terminare con `/` (Django lo richiede con `APPEND_SLASH=True`)

---

## 7. STRUTTURA DEI VIEWSET API

Ogni ViewSet in `api_views.py` segue questo pattern:

```python
class NomeViewSet(viewsets.ModelViewSet):
    serializer_class = NomeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Filtra: oggetti propri + condivisi con i gruppi dell'utente
        propri = Model.objects.filter(proprietario=user)
        gruppi_utente = Gruppo.objects.filter(membri=user)
        condivisi = Model.objects.filter(
            condiviso_con_gruppo=True,
            gruppo__in=gruppi_utente
        ).exclude(proprietario=user)
        return (propri | condivisi).distinct()

    def perform_create(self, serializer):
        serializer.save(proprietario=self.request.user)
```

**Regola**: Ogni ViewSet filtra i dati per utente. L'utente vede SOLO i propri dati + quelli condivisi nei suoi gruppi. Il campo `proprietario` (o `utente`) viene settato automaticamente nel `perform_create`.

---

## 8. TESTING

### 8.1 Build Flutter
```bash
cd "I:\Progetti Git\Apiary_app"
flutter build apk --debug          # Build debug veloce
flutter run                         # Run su dispositivo/emulatore
```

### 8.2 Test API Django
```bash
cd "I:\Progetti Git\Apiary"
python manage.py runserver          # Server locale su :8000
# Swagger: http://localhost:8000/api/docs/
```

### 8.3 Test rapido endpoint
```bash
# Ottieni token
curl -X POST https://cible99.pythonanywhere.com/api/v1/token/ \
  -d "username=UTENTE&password=PASSWORD"

# Testa endpoint (con token ottenuto)
curl -H "Authorization: Bearer ACCESS_TOKEN" \
  https://cible99.pythonanywhere.com/api/v1/attrezzature/
```

---

## 9. GOTCHAS E TRAPPOLE COMUNI

1. **Due repository, un sistema**: Modifiche al backend SENZA deploy non hanno effetto sull'app. Modifiche all'app SENZA backend aggiornato danno 404/500.

2. **Paginazione**: L'API ritorna `{"count": N, "results": [...]}` non una lista diretta. Il Flutter deve gestire entrambi i formati.

3. **CHOICES devono combaciare**: Se Django ha `STATO_CHOICES = [('disponibile', 'Disponibile')]`, il Flutter deve avere esattamente `'disponibile'`, non `'buono'` o `'attivo'`.

4. **ForeignKey nel JSON**: Un `ForeignKey` nel serializer viene serializzato come `int` (l'ID). Per avere anche il nome, servono campi extra nel serializer (`source='relazione.campo'`).

5. **Trailing slash obbligatorio**: Django richiede `/api/v1/attrezzature/` (con slash finale). Senza slash → 301 redirect → possibile errore.

6. **File statici PythonAnywhere**: Dopo modifiche CSS/JS, esegui `python manage.py collectstatic` sul server.

7. **Il campo `proprietario`/`utente` e' read-only**: Non inviarlo dal Flutter nel POST/PUT. Viene settato automaticamente da `perform_create()` nel ViewSet.

8. **SQLite e concorrenza**: SQLite non gestisce bene molte scritture simultanee. Se l'app ha molti utenti, considera di passare a MySQL/PostgreSQL su PythonAnywhere.

9. **Cache dell'app Flutter**: Se l'API cambia formato risposta, l'app potrebbe usare dati vecchi dalla cache. Pulisci i dati dell'app o gestisci la migrazione del formato cache.

10. **NDK Warning nel build**: Il progetto Flutter mostra warning sulle versioni NDK dei plugin. Non blocca il build ma potrebbe dare problemi in futuro. La versione NDK piu' alta richiesta e' `26.3.11579264`.

---

## 10. QUICK REFERENCE - FILE DA MODIFICARE

### Aggiungere nuovo endpoint API:
```
Django: serializers.py → api_views.py → api_urls.py → migrate → deploy
Flutter: models/*.dart → api_constants.dart → services/*.dart → screens/*.dart → route_generator.dart
```

### Modificare un modello esistente:
```
Django: models.py → makemigrations → migrate → serializers.py (se campi cambiano) → deploy
Flutter: models/*.dart (aggiorna fromJson/toJson) → screens che usano il modello
```

### Aggiungere schermata Flutter:
```
app_constants.dart (route) → screens/*.dart (widget) → route_generator.dart (case) → drawer_widget.dart (menu)
```

---

*Ultimo aggiornamento: Febbraio 2026*
*Progetto: Apiario Manager - Gestione Apicoltura*

# PythonAnywhere – Piano di Scalabilità per Apiary

> Creato: 09/04/2026  
> Riferimento backend: Django 4.2 + DRF, SQLite, ~45 endpoint REST, immagini, AI (Gemini), meteo  
> URL attuale: `cible99.pythonanywhere.com`

---

## Ipotesi di calcolo

| Parametro | Valore stimato |
|---|---|
| DAU (Daily Active Users) | ~25% degli utenti registrati |
| Richieste API per sessione attiva | ~50 chiamate (sync + operazioni normali) |
| Tempo CPU medio per richiesta | ~80ms (Django + SQLite query) |
| Endpoint sync (più pesante) | ~200ms CPU |
| Endpoint AI (Gemini) | ~10ms CPU locale (risposta esterna) |
| Stagionalità | Picchi in primavera/estate |

> **Nota critica – SQLite:** SQLite gestisce bene le letture concorrenti, ma permette **un solo writer alla volta**. Con la funzione di sync bidirezionale dell'app, durante i picchi si rischiano errori `503 Database is locked`. Questa è la principale limitazione di scala.

---

## Riepilogo per gruppo utenti

### 20 utenti

| Metrica | Valore |
|---|---|
| DAU stimato | ~5 utenti/giorno |
| Richieste/giorno | ~250 |
| CPU consumata/giorno | ~20 secondi |
| Concorrenza di picco | 1–2 worker |

**Tier consigliato: Developer – $10/mese**

Sebbene il piano Free (Beginner) regga il carico (100 CPU-sec/giorno → margine ampio), il piano Free **non ha task pianificati, non ha SSH, ha 1 solo worker e ha accesso Internet limitato**. Per un ambiente di produzione reale – anche piccolo – il piano Developer da $10/mese è il minimo sensato:
- 3 worker: abbondanti per questo carico
- 5.000 CPU-sec/giorno: si usa meno del 1%
- SSH + task schedulati: utile per backups e manutenzione

> Il piano Free va bene solo per demo/test personali.

---

### 50 utenti

| Metrica | Valore |
|---|---|
| DAU stimato | ~12 utenti/giorno |
| Richieste/giorno | ~600 |
| CPU consumata/giorno | ~48 secondi |
| Concorrenza di picco | 2–3 worker |

**Tier consigliato: Developer – $10/mese**

Carico molto basso. I 3 worker del piano Developer bastano ampiamente. Si usa circa l'1% della quota CPU disponibile. Nessuna modifica al database necessaria.

---

### 100 utenti

| Metrica | Valore |
|---|---|
| DAU stimato | ~25 utenti/giorno |
| Richieste/giorno | ~1.250 |
| CPU consumata/giorno | ~100 secondi |
| Concorrenza di picco | 3–5 worker |

**Tier consigliato: Developer – $10/mese**

Ancora gestibile con il piano Developer. La quota CPU (5.000 sec/giorno) viene usata al ~2%. I 3 worker coprono il picco. **Monitorare** i lock di SQLite durante le sincronizzazioni simultanee: a questo livello sono eventi rari ma possibili.

**Azione preventiva:** Configurare un timeout SQLite in `settings.py`:
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
        'OPTIONS': {'timeout': 20},  # evita crash immediati su lock
    }
}
```

---

### 500 utenti

| Metrica | Valore |
|---|---|
| DAU stimato | ~125 utenti/giorno |
| Richieste/giorno | ~6.250 |
| CPU consumata/giorno | ~500 secondi |
| Concorrenza di picco | 15–20 worker necessari |

**Tier consigliato: Custom – ~$25–40/mese**

Il piano Developer da $10 non basta più: i **3 worker sono insufficienti** per 15–20 utenti concorrenti nei picchi. Richieste in coda → timeout → crash percepiti dall'utente.

Con Custom si configurano **6–8 worker** mantenendo la spesa bassa.

**Problemi critici a questo livello:**
- **SQLite write lock:** con 125 DAU che sincronizzano dati, i conflitti di scrittura diventano frequenti. **Migrare a MySQL** (disponibile nativamente su PythonAnywhere) è **fortemente consigliato**.
- **Spazio disco:** stimare ~500MB–1GB per immagini (api arnie, regine, controlli). Scegliere almeno 5–10 GB nello storage Custom.

**Piano Custom configurazione minima:**
- 6–8 web worker
- 2.000–3.000 CPU-sec/giorno (ampio margine)
- 10 GB storage
- MySQL invece di SQLite

---

### 5.000 utenti

| Metrica | Valore |
|---|---|
| DAU stimato | ~1.250 utenti/giorno |
| Richieste/giorno | ~62.500 |
| CPU consumata/giorno | ~5.000 secondi |
| Concorrenza di picco | 100–150 worker necessari |

**Tier consigliato: Custom – ~$80–130/mese**

Il piano Developer viene superato in CPU (5.000 sec/giorno = limite esatto, senza margine per picchi). Si entra nel territorio Custom medio.

**Requisiti minimi:**
- **MySQL obbligatorio** – SQLite non è assolutamente adatto a questo volume
- **15–20 web worker** (dipende dal tempo medio di risposta)
- **20.000–30.000 CPU-sec/giorno** con margine per picchi stagionali
- **20–30 GB storage** per immagini e media
- Always-on task per gestione sync in background

**Avvertenze:**
- A questa scala valutare un **CDN per le immagini** (es. Cloudflare R2 o AWS S3) per spostare il peso del bandwidth fuori da PythonAnywhere
- Implementare **caching** (Django cache framework con file o database) per endpoint read-heavy come `/api/v1/apiario/`, `/api/v1/fioritura/`
- PythonAnywhere regge, ma inizia a essere "tirato". Monitorare latenza attentamente

---

### 10.000 utenti

| Metrica | Valore |
|---|---|
| DAU stimato | ~2.500 utenti/giorno |
| Richieste/giorno | ~125.000 |
| CPU consumata/giorno | ~10.000 secondi |
| Concorrenza di picco | 200–300 worker necessari |

**Tier consigliato: Custom – ~$150–200/mese**  
*(oppure valutare migrazione piattaforma)*

Siamo nel Custom alto. 10.000 CPU-sec/giorno richiedono un piano significativo. Il numero di worker necessari (~30–40 in picco) porta la spesa vicino ai $150–200/mese.

**Requisiti minimi:**
- **MySQL con connection pooling** (es. `django-db-connection-pool`)
- **30–40 web worker** nei momenti di picco (configurabili dinamicamente su Custom)
- **30.000–50.000 CPU-sec/giorno**
- **50+ GB storage** + CDN esterno per media
- Cache Django con Redis (via servizio esterno, es. Upstash)
- Rate limiting sugli endpoint `/api/v1/sync/` e AI per evitare storm

**Considerazione strategica:** A 10.000 utenti, PythonAnywhere rimane tecnicamente possibile ma non è più la scelta più economica né la più scalabile. A questo punto vale la pena valutare:
- **Railway.app**: ~$20–50/mese con PostgreSQL incluso, più flessibile
- **Render.com**: piano da $25/mese con auto-scaling
- **Hetzner VPS** (server europeo): €5–15/mese, pieno controllo, ma richiede DevOps

---

## Tabella riassuntiva

| Utenti | Tier | Costo/mese | Worker | DB | CPU-sec/gg | Note |
|--------|------|------------|--------|-----|------------|------|
| 20 | Developer | **$10** | 3 | SQLite | 5.000 | Minimo per produzione |
| 50 | Developer | **$10** | 3 | SQLite | 5.000 | Comodo |
| 100 | Developer | **$10** | 3 | SQLite* | 5.000 | Aggiungere timeout SQLite |
| 500 | Custom | **~$30–40** | 6–8 | MySQL | ~3.000 | Migrare a MySQL! |
| 5.000 | Custom | **~$80–130** | 15–20 | MySQL | ~25.000 | CDN per media |
| 10.000 | Custom | **~$150–200** | 30–40 | MySQL | ~40.000 | Valutare piattaforma diversa |

---

## Azioni prioritarie per scalare

1. **Subito (qualsiasi livello >100 utenti):** Migrare da SQLite a **MySQL** (incluso nei piani PythonAnywhere)
2. **Da 500 utenti:** Aggiungere `OPTIONS: {'timeout': 20}` al DB config
3. **Da 5.000 utenti:** CDN per le immagini, cache per le letture frequenti
4. **Da 10.000 utenti:** Valutare migrazione su infrastruttura con auto-scaling

---

## Costo totale a confronto

```
20 utenti   →  $10/mese   →  $120/anno
50 utenti   →  $10/mese   →  $120/anno
100 utenti  →  $10/mese   →  $120/anno
500 utenti  →  $35/mese   →  $420/anno
5.000 utenti → $100/mese  →  $1.200/anno
10.000 utenti → $175/mese →  $2.100/anno
```

# NFC tag → app — Setup backend

Per fare in modo che un tag NFC scansionato dal telefono apra direttamente
l'app Apiary anche quando l'app è chiusa, il backend Django deve servire 3 cose:

1. `/.well-known/assetlinks.json` — per Android App Links
2. `/.well-known/apple-app-site-association` — per iOS Universal Links
3. `/a/<nfc_id>` — landing page di fallback (browser senza app installata)

Tutti devono essere serviti **in HTTPS sul dominio configurato** in
`AppConstants.deepLinkHost` (attualmente `cible99.pythonanywhere.com`).

---

## 1. assetlinks.json (Android)

File: `assetlinks.json`

**Stato:** già popolato con due fingerprint:
- Release (upload keystore `android/app/apiary-release.jks`, alias `apiary`)
- Debug (`~/.android/debug.keystore`, alias `androiddebugkey`) — per testare gli
  App Link da Android Studio senza dover firmare release.

> ⚠️ **Play App Signing**: se l'app è distribuita tramite Play Store con
> Play App Signing attivo, Google ri-firma l'APK con una propria chiave.
> In quel caso la SHA-256 da inserire **non** è quella locale ma quella
> mostrata in Google Play Console → Release → Setup → App integrity →
> "App signing key certificate" → "SHA-256 certificate fingerprint".
> Va **aggiunta** all'array (mantenendo anche quella upload per le installazioni
> da bundle non firmato da Google, es. internal testing diretto).

**Deploy su PythonAnywhere:**
Servire il file all'URL **esatto** `https://cible99.pythonanywhere.com/.well-known/assetlinks.json`
con `Content-Type: application/json`. Su PythonAnywhere si può:
- Aggiungere uno `static` file mapping nel pannello "Web" verso una directory
  che contiene il file, **oppure**
- Usare una view Django dedicata (vedi `views.py`).

**Verifica:**
Dopo il deploy, in 24-48h Android scarica e verifica il file. Per testare subito:
```powershell
adb shell pm verify-app-links --re-verify it.apiary.app
adb shell pm get-app-links it.apiary.app
```

Lo stato deve essere `verified`. Se è `none` o `1024:...`, ricontrolla SHA-256
e MIME type.

---

## 2. apple-app-site-association (iOS)

File: `apple-app-site-association` (**senza estensione**, MIME `application/json`).

**Cosa modificare prima del deploy:**
- `appID` → `<TEAM_ID>.<BUNDLE_ID>`
  - `TEAM_ID` = 10 caratteri, dal portale Apple Developer (Membership Details)
  - `BUNDLE_ID` = quello del target Runner. Attualmente `com.example.apiaryApp`
    nel pbxproj — **da rinominare** prima della pubblicazione su App Store
    (consiglio: `it.apiary.app` per allinearlo ad Android).

**Deploy su PythonAnywhere:**
Servire all'URL **esatto** `https://cible99.pythonanywhere.com/.well-known/apple-app-site-association`
con `Content-Type: application/json`, **senza redirect**.

**Verifica:**
```powershell
curl -I https://cible99.pythonanywhere.com/.well-known/apple-app-site-association
```
Deve rispondere `200 OK` con `Content-Type: application/json` e nessun redirect.
Apple effettua una scansione periodica del file dopo l'installazione/aggiornamento dell'app.

---

## 3. Landing page `/a/<nfc_id>` (HTML fallback)

Pagina che si apre se l'utente scansiona il tag su un dispositivo senza l'app
installata: mostra link store + bottone "Apri in app" (per quando l'app è
installata ma la verifica App Link non è ancora avvenuta).

File: `landing_page.html`, `views.py`, `urls.py`.

---

## Snippet Django da integrare

In `apiary/urls.py` (root):

```python
from django.urls import path
from .views_nfc import nfc_landing, assetlinks_json, apple_aasa

urlpatterns = [
    # ... esistenti ...
    path('a/<str:nfc_id>/', nfc_landing, name='nfc_landing'),
    path('.well-known/assetlinks.json', assetlinks_json),
    path('.well-known/apple-app-site-association', apple_aasa),
]
```

Vedi `views.py` per il codice. Copiarlo in un file `views_nfc.py` nel modulo
principale dell'app Django.

---

## Checklist deploy

- [ ] `assetlinks.json`: SHA-256 release inserita
- [ ] `assetlinks.json`: SHA-256 debug inserita (opzionale per test)
- [ ] `apple-app-site-association`: TEAM_ID e BUNDLE_ID corretti
- [ ] Entrambi i file raggiungibili in HTTPS, MIME `application/json`, no redirect
- [ ] View `/a/<nfc_id>` deployata e raggiungibile
- [ ] App reinstallata / verificata: `adb shell pm get-app-links it.apiary.app` → `verified`

"""
View Django per il deep-linking NFC.

Da copiare in un file `views_nfc.py` (o equivalente) nell'app Django
principale e collegare via `urls.py` (vedi README.md).

Nota: i due file di metadata `.well-known` sono serviti come JSON statici
embeddati nel codice; in alternativa li puoi servire come file statici
configurati direttamente da PythonAnywhere.
"""
import json
import os
from django.http import HttpResponse, JsonResponse
from django.shortcuts import render
from django.views.decorators.http import require_GET

# ─────────────────────────────────────────────────────────────────────────────
# .well-known files (Android App Links + iOS Universal Links)
# ─────────────────────────────────────────────────────────────────────────────

# Carica i file dal disco — comodo per aggiornare la SHA-256 senza redeploy.
# In alternativa, embedda i dict direttamente nel codice.
_WELL_KNOWN_DIR = os.path.join(os.path.dirname(__file__), 'well_known')


@require_GET
def assetlinks_json(request):
    """GET /.well-known/assetlinks.json — Android App Links verification."""
    path = os.path.join(_WELL_KNOWN_DIR, 'assetlinks.json')
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    response = JsonResponse(data, safe=False)
    response['Cache-Control'] = 'public, max-age=3600'
    return response


@require_GET
def apple_aasa(request):
    """GET /.well-known/apple-app-site-association — iOS Universal Links."""
    path = os.path.join(_WELL_KNOWN_DIR, 'apple-app-site-association')
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    # Apple richiede esplicitamente application/json e nessun redirect
    response = HttpResponse(content, content_type='application/json')
    response['Cache-Control'] = 'public, max-age=3600'
    return response


# ─────────────────────────────────────────────────────────────────────────────
# Landing page /a/<nfc_id>
# ─────────────────────────────────────────────────────────────────────────────

PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=it.apiary.app'
APP_STORE_URL = 'https://apps.apple.com/app/idREPLACE_APP_STORE_ID'


@require_GET
def nfc_landing(request, nfc_id):
    """
    Pagina HTML mostrata quando si apre https://<host>/a/<nfc_id> in un
    browser (i.e. tag NFC scansionato su dispositivo senza l'app installata,
    oppure prima della verifica degli App Link).

    Quando l'app è installata e gli App Link sono verificati, Android e
    iOS aprono direttamente l'app senza passare di qui.
    """
    return render(request, 'nfc_landing.html', {
        'nfc_id': nfc_id,
        'deep_link_https': f'https://cible99.pythonanywhere.com/a/{nfc_id}',
        'deep_link_custom': f'apiary://a/{nfc_id}',
        'play_store_url': PLAY_STORE_URL,
        'app_store_url': APP_STORE_URL,
    })

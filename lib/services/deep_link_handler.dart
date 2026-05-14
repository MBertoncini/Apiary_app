import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import 'auth_service.dart';
import 'nfc_handler.dart';

/// Gestisce i deep link in arrivo dall'OS quando un tag NFC (record URI)
/// viene scansionato fuori dall'app, o quando si apre un App Link / Universal
/// Link da browser o messaggi.
///
/// Formato URL atteso:
///   https://cible99.pythonanywhere.com/a/<nfc_id>
///   apiary://a/<nfc_id>
///
/// Se l'utente non è ancora autenticato al momento dell'arrivo del link, il
/// link viene messo in coda e processato non appena AuthService notifica un
/// utente valido.
class DeepLinkHandler extends ChangeNotifier {
  final AuthService _authService;
  final NfcHandler _nfcHandler;
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;
  String? _pendingNfcId;
  bool _initialized = false;

  DeepLinkHandler(this._authService, this._nfcHandler) {
    _authService.addListener(_onAuthChanged);
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Cold start: link che ha lanciato l'app
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri, source: 'initial');
      }
    } catch (e) {
      debugPrint('DeepLinkHandler: errore getInitialAppLink → $e');
    }

    // Warm start: link che arrivano mentre l'app è in foreground/background
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri, source: 'stream'),
      onError: (Object e) => debugPrint('DeepLinkHandler: stream error → $e'),
    );
  }

  void _onAuthChanged() {
    if (_pendingNfcId != null && _authService.currentUser != null) {
      final id = _pendingNfcId!;
      _pendingNfcId = null;
      _processNfcId(id, source: 'pending');
    }
  }

  void _handleUri(Uri uri, {required String source}) {
    debugPrint('DeepLinkHandler [$source]: ricevuto $uri');

    final nfcId = _extractNfcId(uri);
    if (nfcId == null || nfcId.isEmpty) {
      debugPrint('DeepLinkHandler: URI non riconosciuto');
      return;
    }

    if (_authService.currentUser == null) {
      debugPrint('DeepLinkHandler: utente non autenticato, link in coda');
      _pendingNfcId = nfcId;
      return;
    }

    _processNfcId(nfcId, source: source);
  }

  /// Estrae il nfc_id dall'URI se il pattern matcha:
  ///   https://<deepLinkHost>/a/<nfc_id>
  ///   apiary://a/<nfc_id>
  String? _extractNfcId(Uri uri) {
    final isHttpsAppLink = uri.scheme == AppConstants.deepLinkScheme &&
        uri.host == AppConstants.deepLinkHost &&
        uri.pathSegments.length >= 2 &&
        '/${uri.pathSegments.first}/' == AppConstants.deepLinkArniaPathPrefix;

    final isCustomScheme = uri.scheme == AppConstants.deepLinkCustomScheme &&
        uri.host == AppConstants.deepLinkCustomHost &&
        uri.pathSegments.isNotEmpty;

    if (isHttpsAppLink) {
      return Uri.decodeComponent(uri.pathSegments[1]);
    }
    if (isCustomScheme) {
      return Uri.decodeComponent(uri.pathSegments.first);
    }
    return null;
  }

  void _processNfcId(String nfcId, {required String source}) {
    // Non bloccante: NfcHandler ha già il proprio _isProcessing guard
    unawaited(
      _nfcHandler.resolveAndNavigateByNfcId(nfcId, source: 'deeplink:$source'),
    );
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    _linkSubscription?.cancel();
    super.dispose();
  }
}

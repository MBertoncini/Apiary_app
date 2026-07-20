import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../utils/navigator_key.dart';

/// Mappa i valori del dropdown admin (`link_route` su AdminBroadcast) alle
/// rotte concrete dell'app. Centralizzato qui per non sparpagliare la logica
/// nei vari widget di notifica e per restare in sync se l'admin aggiunge
/// nuove destinazioni lato backend.
class NotificationNavigator {
  NotificationNavigator._();

  /// Naviga alla schermata target di una notifica. Se il route è ignoto o
  /// la navigazione fallisce, logga e basta — l'utente è già nel centro
  /// notifiche, non vogliamo errori visibili.
  static void navigate({required String linkRoute, String linkParam = ''}) {
    if (linkRoute.isEmpty) return;
    final state = navigatorKey.currentState;
    if (state == null) {
      debugPrint('NotificationNavigator: navigatorKey non disponibile');
      return;
    }
    final route = _resolveRoute(linkRoute);
    if (route == null) {
      debugPrint('NotificationNavigator: route ignota "$linkRoute"');
      return;
    }
    final args = _resolveArgs(linkRoute, linkParam);
    try {
      state.pushNamed(route, arguments: args);
    } catch (e) {
      debugPrint('NotificationNavigator: pushNamed fallito → $e');
    }
  }

  static String? _resolveRoute(String linkRoute) {
    switch (linkRoute) {
      case 'home':
        return AppConstants.dashboardRoute;
      case 'apiari':
        return AppConstants.apiarioListRoute;
      case 'arnie':
        return AppConstants.arniaListRoute;
      case 'trattamenti':
        return AppConstants.trattamentiRoute;
      case 'melari':
        return AppConstants.melariRoute;
      case 'community':
        return AppConstants.mappaRoute;
      case 'statistiche':
        return AppConstants.statisticheRoute;
      case 'subscription':
        // L'abbonamento è dentro Impostazioni → temporaneamente apre quella.
        return AppConstants.settingsRoute;
      case 'settings':
        return AppConstants.settingsRoute;
      case 'whats_new':
        return AppConstants.whatsNewRoute;
      case 'guida':
        return AppConstants.guidaRoute;
      case 'chat':
        return AppConstants.chatRoute;
      default:
        return null;
    }
  }

  /// Alcune rotte di dettaglio attendono un `int` come args, altre niente.
  /// Per ora il dropdown admin offre solo rotte di lista → arg sempre null.
  /// `linkParam` resta come hook per future estensioni (es. arnia/<id>).
  static dynamic _resolveArgs(String linkRoute, String linkParam) {
    if (linkParam.isEmpty) return null;
    return int.tryParse(linkParam) ?? linkParam;
  }
}

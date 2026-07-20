import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Gestisce il controllo aggiornamenti via Play Store In-App Update.
///
/// Regole:
/// - `updatePriority >= 4` → immediate update bloccante (schermo intero).
/// - Altrimenti flexible update (download in background + install al termine),
///   cosi' un aggiornamento ordinario non interrompe il lavoro dell'utente.
/// - Solo se il Play Store non concede il flexible si ripiega sull'immediate.
/// - Se l'utente nega o il flusso fallisce, si ritenta al prossimo resume dell'app.
///
/// NOTA: `updatePriority` NON e' impostabile dalla UI della Play Console. Si
/// definisce solo via Publishing API, nel campo `inAppUpdatePriority` di
/// `Edits.tracks.releases`, al momento della creazione della release (valori
/// 0-5, default 0). Pubblicando l'aab a mano la priorita' resta 0, quindi si
/// prende il ramo flexible.
class UpdateService {
  static const int _immediatePriorityThreshold = 4;

  static bool _checkInProgress = false;
  static bool _flexibleDownloadStarted = false;

  static Future<void> checkForUpdate() async {
    if (!Platform.isAndroid) return;
    if (_checkInProgress) return;
    _checkInProgress = true;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.installStatus == InstallStatus.downloaded) {
        await _safeCompleteFlexible();
        return;
      }

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      final highPriority = (info.updatePriority) >= _immediatePriorityThreshold;

      if (highPriority && info.immediateUpdateAllowed) {
        await _runImmediate();
        return;
      }

      if (info.flexibleUpdateAllowed && !_flexibleDownloadStarted) {
        await _runFlexible();
        return;
      }

      // Priorita' bassa ma il Play Store concede solo l'immediate: meglio
      // aggiornare in modo bloccante che non aggiornare affatto.
      if (info.immediateUpdateAllowed) {
        await _runImmediate();
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('UpdateService.checkForUpdate error: $e\n$st');
      }
    } finally {
      _checkInProgress = false;
    }
  }

  static Future<void> _runImmediate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UpdateService.performImmediateUpdate error: $e');
      }
    }
  }

  static Future<void> _runFlexible() async {
    _flexibleDownloadStarted = true;
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        await _safeCompleteFlexible();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UpdateService.startFlexibleUpdate error: $e');
      }
    } finally {
      _flexibleDownloadStarted = false;
    }
  }

  static Future<void> _safeCompleteFlexible() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UpdateService.completeFlexibleUpdate error: $e');
      }
    }
  }
}

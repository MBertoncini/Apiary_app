// lib/services/regina_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Gestisce logica di business per le regine, inclusa la creazione automatica.
class ReginaService {
  static const String _autoCreatedKey = 'auto_created_queens';

  /// Restituisce gli ID delle regine auto-create che richiedono attenzione.
  static Future<Set<int>> getAutoCreatedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_autoCreatedKey) ?? [];
    return list.map((s) => int.tryParse(s) ?? -1).where((id) => id > 0).toSet();
  }

  /// Segna una regina come auto-creata (richiede completamento dall'utente).
  static Future<void> markAutoCreated(int reginaId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_autoCreatedKey) ?? [];
    if (!list.contains(reginaId.toString())) {
      list.add(reginaId.toString());
      await prefs.setStringList(_autoCreatedKey, list);
    }
  }

  /// Rimuove il flag di auto-creazione (es. quando l'utente completa la scheda).
  static Future<void> clearAutoCreated(int reginaId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_autoCreatedKey) ?? [];
    list.remove(reginaId.toString());
    await prefs.setStringList(_autoCreatedKey, list);
  }

  /// Se [arniaId] non ha una regina attiva e [presenzaRegina] è true,
  /// crea automaticamente una scheda base e la segna come "da completare".
  ///
  /// Restituisce la mappa della regina creata, o null se non è stata creata.
  static Future<Map<String, dynamic>?> maybeAutoCreate({
    required int arniaId,
    required bool presenzaRegina,
    required String dataControllo,
    required ApiService apiService,
    required StorageService storageService,
  }) async {
    if (!presenzaRegina) return null;

    // Controlla se l'arnia ha già una regina attiva
    try {
      final existing = await apiService.get(
        '${ApiConstants.arnieUrl}$arniaId/regina/',
      );
      if (existing != null &&
          existing is Map<String, dynamic> &&
          existing.containsKey('id')) {
        return null; // Regina già presente, niente da fare
      }
    } catch (_) {
      // 404 o errore di rete → nessuna regina, procediamo
    }

    // Crea scheda base
    try {
      final created = await apiService.post(ApiConstants.regineUrl, {
        'arnia': arniaId,
        'data_introduzione': dataControllo,
        'razza': 'altro',
        'origine': 'sconosciuta',
        'marcata': false,
        'fecondata': false,
      });

      if (created != null &&
          created is Map<String, dynamic> &&
          created['id'] != null) {
        // Aggiorna cache locale
        final regine = await storageService.getStoredData('regine');
        await storageService.saveData('regine', [...regine, created]);

        // Segna come da completare
        await markAutoCreated(created['id'] as int);

        debugPrint(
          'ReginaService: auto-creata regina ${created['id']} per arnia $arniaId',
        );
        return created;
      }
    } catch (e) {
      debugPrint(
        'ReginaService: auto-creazione regina per arnia $arniaId fallita: $e',
      );
    }

    return null;
  }
}

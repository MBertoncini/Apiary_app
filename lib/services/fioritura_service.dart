import '../services/api_service.dart';
import '../models/fioritura.dart';
import '../models/fioritura_conferma.dart';

class FiorituraService {
  final ApiService _apiService;

  FiorituraService(this._apiService);

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<List<Fioritura>> getFioriture() async {
    final response = await _apiService.get('fioriture/');
    final List<dynamic> list =
        response is List ? response : (response['results'] ?? []);
    return list.map((j) => Fioritura.fromJson(j)).toList();
  }

  Future<List<Fioritura>> getFioritureAttive() async {
    final response = await _apiService.get('fioriture/attive/');
    final List<dynamic> list =
        response is List ? response : (response['results'] ?? []);
    return list.map((j) => Fioritura.fromJson(j)).toList();
  }

  Future<List<Fioritura>> getFioritueCommunity() async {
    final response = await _apiService.get('fioriture/community/');
    final List<dynamic> list =
        response is List ? response : (response['results'] ?? []);
    return list.map((j) => Fioritura.fromJson(j)).toList();
  }

  Future<List<Fioritura>> getFioritureVicine({
    required double lat,
    required double lng,
    double raggioKm = 20,
  }) async {
    final response = await _apiService
        .get('fioriture/vicine/?lat=$lat&lng=$lng&raggio_km=$raggioKm');
    final List<dynamic> list =
        response is List ? response : (response['results'] ?? []);
    return list.map((j) => Fioritura.fromJson(j)).toList();
  }

  Future<Fioritura> createFioritura(Map<String, dynamic> data) async {
    final response = await _apiService.post('fioriture/', data);
    return Fioritura.fromJson(response);
  }

  Future<Fioritura> updateFioritura(int id, Map<String, dynamic> data) async {
    final response = await _apiService.put('fioriture/$id/', data);
    return Fioritura.fromJson(response);
  }

  Future<void> deleteFioritura(int id) async {
    await _apiService.delete('fioriture/$id/');
  }

  // ── SOCIAL ───────────────────────────────────────────────────────────────────

  /// Conferma (o aggiorna) la propria segnalazione su una fioritura.
  Future<Fioritura> confermaFioritura(
    int fiorituraId, {
    int? intensita,
    String? nota,
  }) async {
    final body = <String, dynamic>{};
    if (intensita != null) body['intensita'] = intensita;
    if (nota != null && nota.isNotEmpty) body['nota'] = nota;
    final response =
        await _apiService.post('fioriture/$fiorituraId/conferma/', body);
    return Fioritura.fromJson(response);
  }

  /// Rimuove la propria conferma da una fioritura.
  Future<void> rimuoviConferma(int fiorituraId) async {
    await _apiService.delete('fioriture/$fiorituraId/rimuovi_conferma/');
  }

  /// Restituisce le conferme dell'utente corrente.
  Future<List<FiorituraConferma>> getMieConferme() async {
    final response = await _apiService.get('fioriture-conferme/');
    final List<dynamic> list =
        response is List ? response : (response['results'] ?? []);
    return list.map((j) => FiorituraConferma.fromJson(j)).toList();
  }
}

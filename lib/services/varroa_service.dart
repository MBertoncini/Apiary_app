import '../constants/api_constants.dart';
import '../models/varroa_checkpoint.dart';
import 'api_service.dart';

class VarroaService {
  final ApiService _apiService;

  VarroaService(this._apiService);

  Future<List<VarroaCheckpoint>> getCheckpointsByColonia(int coloniaId) async {
    final data = await _apiService.get(
      '${ApiConstants.varroaCheckpointsUrl}?colonia=$coloniaId',
    );
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list
        .map((e) => VarroaCheckpoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VarroaCheckpoint> createCheckpoint(Map<String, dynamic> payload) async {
    final data = await _apiService.post(ApiConstants.varroaCheckpointsUrl, payload);
    return VarroaCheckpoint.fromJson(data as Map<String, dynamic>);
  }

  Future<VarroaCheckpoint> updateCheckpoint(int id, Map<String, dynamic> payload) async {
    final data = await _apiService.put(
      '${ApiConstants.varroaCheckpointsUrl}$id/',
      payload,
    );
    return VarroaCheckpoint.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteCheckpoint(int id) async {
    await _apiService.delete('${ApiConstants.varroaCheckpointsUrl}$id/');
  }

  /// Returns full trajectory + alarm + statistics from the backend engine.
  Future<Map<String, dynamic>> getTraiettoria(
    int coloniaId, {
    int daysAhead = 60,
  }) async {
    final data = await _apiService.get(
      '${ApiConstants.varroaTraiettoriaUrl}?colonia_id=$coloniaId&days_ahead=$daysAhead',
    );
    return data as Map<String, dynamic>;
  }
}

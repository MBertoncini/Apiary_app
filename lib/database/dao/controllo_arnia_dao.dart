import '../database_helper.dart';
import '../../models/controllo_arnia.dart';

class ControlloArniaDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(ControlloArnia controllo) async {
    return await _dbHelper.insert(
      _dbHelper.tableControlli,
      controllo.toJson(),
    );
  }

  Future<List<ControlloArnia>> getAll() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      orderBy: 'data DESC',
    );
    
    return List.generate(maps.length, (i) {
      return ControlloArnia.fromJson(maps[i]);
    });
  }

  Future<ControlloArnia?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return ControlloArnia.fromJson(maps.first);
  }

  Future<List<ControlloArnia>> getByArnia(int arniaId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      where: 'arnia = ?',
      whereArgs: [arniaId],
      orderBy: 'data DESC',
    );
    
    return List.generate(maps.length, (i) {
      return ControlloArnia.fromJson(maps[i]);
    });
  }

  Future<List<ControlloArnia>> getByApiario(int apiarioId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      where: 'apiario_id = ?',
      whereArgs: [apiarioId],
      orderBy: 'data DESC',
    );
    
    return List.generate(maps.length, (i) {
      return ControlloArnia.fromJson(maps[i]);
    });
  }

  Future<List<ControlloArnia>> getRecentByArnia(int arniaId, {int days = 30}) async {
    final date = DateTime.now().subtract(Duration(days: days));
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      where: 'arnia = ? AND data >= ?',
      whereArgs: [arniaId, dateStr],
      orderBy: 'data DESC',
    );
    
    return List.generate(maps.length, (i) {
      return ControlloArnia.fromJson(maps[i]);
    });
  }

  Future<ControlloArnia?> getLatestByArnia(int arniaId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      where: 'arnia = ?',
      whereArgs: [arniaId],
      orderBy: 'data DESC',
      limit: 1,
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return ControlloArnia.fromJson(maps.first);
  }

  Future<int> update(ControlloArnia controllo) async {
    return await _dbHelper.update(
      _dbHelper.tableControlli,
      controllo.toJson(),
      'id = ?',
      [controllo.id],
    );
  }

  Future<int> delete(int id) async {
    return await _dbHelper.delete(
      _dbHelper.tableControlli,
      'id = ?',
      [id],
    );
  }

  Future<List<ControlloArnia>> getPendingChanges() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.getPendingChanges(
      _dbHelper.tableControlli,
    );
    
    return List.generate(maps.length, (i) {
      return ControlloArnia.fromJson(maps[i]);
    });
  }

  Future<void> markSynced(int id) async {
    await _dbHelper.markSynced(_dbHelper.tableControlli, id);
  }

  Future<void> syncFromServer(List<Map<String, dynamic>> records) async {
    await _dbHelper.batchInsertOrUpdate(_dbHelper.tableControlli, records);
  }
}
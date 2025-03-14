import '../database_helper.dart';
import '../../models/arnia.dart';

class ArniaDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Arnia arnia) async {
    return await _dbHelper.insert(
      _dbHelper.tableArnie,
      arnia.toJson(),
    );
  }

  Future<List<Arnia>> getAll() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableArnie,
      orderBy: 'apiario ASC, numero ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Arnia.fromJson(maps[i]);
    });
  }

  Future<Arnia?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableArnie,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return Arnia.fromJson(maps.first);
  }

  Future<List<Arnia>> getByApiario(int apiarioId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableArnie,
      where: 'apiario = ?',
      whereArgs: [apiarioId],
      orderBy: 'numero ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Arnia.fromJson(maps[i]);
    });
  }

  Future<List<Arnia>> getAttiveByApiario(int apiarioId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableArnie,
      where: 'apiario = ? AND attiva = 1',
      whereArgs: [apiarioId],
      orderBy: 'numero ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Arnia.fromJson(maps[i]);
    });
  }

  Future<int> update(Arnia arnia) async {
    return await _dbHelper.update(
      _dbHelper.tableArnie,
      arnia.toJson(),
      'id = ?',
      [arnia.id],
    );
  }

  Future<int> delete(int id) async {
    return await _dbHelper.delete(
      _dbHelper.tableArnie,
      'id = ?',
      [id],
    );
  }

  Future<List<Arnia>> getPendingChanges() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.getPendingChanges(
      _dbHelper.tableArnie,
    );
    
    return List.generate(maps.length, (i) {
      return Arnia.fromJson(maps[i]);
    });
  }

  Future<void> markSynced(int id) async {
    await _dbHelper.markSynced(_dbHelper.tableArnie, id);
  }

  Future<void> syncFromServer(List<Map<String, dynamic>> records) async {
    await _dbHelper.batchInsertOrUpdate(_dbHelper.tableArnie, records);
  }
}
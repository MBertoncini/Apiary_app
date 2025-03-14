import '../database_helper.dart';
import '../../models/apiario.dart';

class ApiarioDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Apiario apiario) async {
    return await _dbHelper.insert(
      _dbHelper.tableApiari,
      apiario.toJson(),
    );
  }

  Future<List<Apiario>> getAll() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableApiari,
      orderBy: 'nome ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Apiario.fromJson(maps[i]);
    });
  }

  Future<Apiario?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableApiari,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return Apiario.fromJson(maps.first);
  }

  Future<List<Apiario>> getByProprietario(int proprietarioId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableApiari,
      where: 'proprietario = ?',
      whereArgs: [proprietarioId],
      orderBy: 'nome ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Apiario.fromJson(maps[i]);
    });
  }

  Future<int> update(Apiario apiario) async {
    return await _dbHelper.update(
      _dbHelper.tableApiari,
      apiario.toJson(),
      'id = ?',
      [apiario.id],
    );
  }

  Future<int> delete(int id) async {
    return await _dbHelper.delete(
      _dbHelper.tableApiari,
      'id = ?',
      [id],
    );
  }

  Future<List<Apiario>> search(String query) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableApiari,
      where: 'nome LIKE ? OR posizione LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'nome ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Apiario.fromJson(maps[i]);
    });
  }

  Future<List<Apiario>> getPendingChanges() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.getPendingChanges(
      _dbHelper.tableApiari,
    );
    
    return List.generate(maps.length, (i) {
      return Apiario.fromJson(maps[i]);
    });
  }

  Future<void> markSynced(int id) async {
    await _dbHelper.markSynced(_dbHelper.tableApiari, id);
  }

  Future<void> syncFromServer(List<Map<String, dynamic>> records) async {
    await _dbHelper.batchInsertOrUpdate(_dbHelper.tableApiari, records);
  }
}
import '../database_helper.dart';
import '../../models/controllo_arnia.dart';

class ControlloArniaDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Map<String, dynamic> controlloDati) async {
    // Per prima cosa, assicuriamoci che abbia i campi richiesti per il database locale
    controlloDati['sync_status'] = 'pending';
    controlloDati['last_updated'] = DateTime.now().millisecondsSinceEpoch;
    
    return await _dbHelper.insert(
      _dbHelper.tableControlli,
      controlloDati,
    );
  }

  Future<int> update(int id, Map<String, dynamic> controlloDati) async {
    // Aggiorna lo stato di sincronizzazione e il timestamp
    controlloDati['sync_status'] = 'pending';
    controlloDati['last_updated'] = DateTime.now().millisecondsSinceEpoch;
    
    return await _dbHelper.update(
      _dbHelper.tableControlli,
      controlloDati,
      'id = ?',
      [id],
    );
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return maps.first;
  }

  Future<List<Map<String, dynamic>>> getByArnia(int arniaId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      where: 'arnia = ?',
      whereArgs: [arniaId],
      orderBy: 'data DESC',
    );
    
    return maps;
  }

  Future<List<Map<String, dynamic>>> getRecentByArnia(int arniaId, {int days = 30}) async {
    final date = DateTime.now().subtract(Duration(days: days));
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      where: 'arnia = ? AND data >= ?',
      whereArgs: [arniaId, dateStr],
      orderBy: 'data DESC',
    );
    
    return maps;
  }

  Future<Map<String, dynamic>?> getLatestByArnia(int arniaId) async {
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
    
    return maps.first;
  }

  Future<List<Map<String, dynamic>>> getPendingChanges() async {
    return await _dbHelper.getPendingChanges(_dbHelper.tableControlli);
  }

  Future<void> markSynced(int id) async {
    await _dbHelper.markSynced(_dbHelper.tableControlli, id);
  }

  Future<void> syncFromServer(List<Map<String, dynamic>> records) async {
    await _dbHelper.batchInsertOrUpdate(_dbHelper.tableControlli, records);
  }
  
  Future<int> delete(int id) async {
    return await _dbHelper.delete(
      _dbHelper.tableControlli,
      'id = ?',
      [id],
    );
  }
}
import '../database_helper.dart';

class AnalisiTelainoDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Map<String, dynamic> analisiDati) async {
    analisiDati['sync_status'] = 'pending';
    analisiDati['last_updated'] = DateTime.now().millisecondsSinceEpoch;
    return await _dbHelper.insert(
      _dbHelper.tableAnalisiTelaini,
      analisiDati,
    );
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableAnalisiTelaini,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<List<Map<String, dynamic>>> getByArnia(int arniaId) async {
    return await _dbHelper.query(
      _dbHelper.tableAnalisiTelaini,
      where: 'arnia = ?',
      whereArgs: [arniaId],
      orderBy: 'data DESC, data_registrazione DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSync() async {
    return await _dbHelper.getPendingChanges(_dbHelper.tableAnalisiTelaini);
  }

  Future<void> markSynced(int id) async {
    await _dbHelper.markSynced(_dbHelper.tableAnalisiTelaini, id);
  }

  /// Marca un record come definitivamente fallito (es. 4xx dal server) per
  /// impedire retry infiniti su record corrotti. La colonna last_error non
  /// esiste a schema, quindi il dettaglio viene perso ma loggato.
  Future<void> markFailed(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      _dbHelper.tableAnalisiTelaini,
      {'sync_status': 'failed'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> syncFromServer(List<Map<String, dynamic>> records) async {
    await _dbHelper.batchInsertOrUpdate(_dbHelper.tableAnalisiTelaini, records);
  }

  Future<int> delete(int id) async {
    return await _dbHelper.delete(
      _dbHelper.tableAnalisiTelaini,
      'id = ?',
      [id],
    );
  }
}

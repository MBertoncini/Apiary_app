import '../database_helper.dart';

class ControlloArniaDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // SQLite stores booleans as INTEGER 0/1; convert them back to Dart bool.
  static const _boolFields = {
    'presenza_regina', 'sciamatura', 'problemi_sanitari',
    'regina_vista', 'uova_fresche', 'celle_reali', 'regina_sostituita',
  };

  static Map<String, dynamic> _convertFromSql(Map<String, dynamic> r) {
    final m = Map<String, dynamic>.from(r);
    for (final f in _boolFields) {
      final v = m[f];
      if (v is int) m[f] = v != 0;
    }
    // Mappa colonia_id (SQLite) -> colonia (Modello/API)
    if (m.containsKey('colonia_id')) {
      m['colonia'] = m['colonia_id'];
    }
    return m;
  }

  Future<int> insert(Map<String, dynamic> controlloDati) async {
    final d = Map<String, dynamic>.from(controlloDati);
    // Mappa colonia (Modello/API) -> colonia_id (SQLite)
    if (d.containsKey('colonia') && d['colonia'] != null) {
      d['colonia_id'] = d['colonia'];
    }

    // Strip any fields not present in the current SQLite schema before inserting.
    final knownColumns = await _dbHelper.getTableColumns(_dbHelper.tableControlli);
    final filtered = Map<String, dynamic>.fromEntries(
      d.entries.where((e) => knownColumns.contains(e.key)),
    );
    filtered['sync_status'] = 'pending';
    filtered['last_updated'] = DateTime.now().millisecondsSinceEpoch;

    return await _dbHelper.insert(
      _dbHelper.tableControlli,
      filtered,
    );
  }

  Future<int> update(int id, Map<String, dynamic> controlloDati) async {
    final d = Map<String, dynamic>.from(controlloDati);
    // Mappa colonia (Modello/API) -> colonia_id (SQLite)
    if (d.containsKey('colonia') && d['colonia'] != null) {
      d['colonia_id'] = d['colonia'];
    }

    // Aggiorna lo stato di sincronizzazione e il timestamp
    d['sync_status'] = 'pending';
    d['last_updated'] = DateTime.now().millisecondsSinceEpoch;
    
    // Filtra campi non presenti nello schema
    final knownColumns = await _dbHelper.getTableColumns(_dbHelper.tableControlli);
    final filtered = Map<String, dynamic>.fromEntries(
      d.entries.where((e) => knownColumns.contains(e.key)),
    );

    return await _dbHelper.update(
      _dbHelper.tableControlli,
      filtered,
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
    if (maps.isEmpty) return null;
    return _convertFromSql(maps.first);
  }

  // ── Query per Colonia (FK primario post-refactor) ─────────────────────────

  Future<List<Map<String, dynamic>>> getByColonia(int coloniaId) async {
    final maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      where: 'colonia_id = ?',
      whereArgs: [coloniaId],
      orderBy: 'data DESC',
    );
    return maps.map(_convertFromSql).toList();
  }

  Future<List<Map<String, dynamic>>> getRecentByColonia(int coloniaId, {int days = 30}) async {
    final date    = DateTime.now().subtract(Duration(days: days));
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      where: 'colonia_id = ? AND data >= ?',
      whereArgs: [coloniaId, dateStr],
      orderBy: 'data DESC',
    );
    return maps.map(_convertFromSql).toList();
  }

  Future<Map<String, dynamic>?> getLatestByColonia(int coloniaId) async {
    final maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      where: 'colonia_id = ?',
      whereArgs: [coloniaId],
      orderBy: 'data DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _convertFromSql(maps.first);
  }

  // ── Query legacy per Arnia (mantenuti per compatibilità) ──────────────────

  Future<List<Map<String, dynamic>>> getByArnia(int arniaId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      where: 'arnia = ?',
      whereArgs: [arniaId],
      orderBy: 'data DESC',
    );
    return maps.map(_convertFromSql).toList();
  }

  Future<List<Map<String, dynamic>>> getRecentByArnia(int arniaId, {int days = 30}) async {
    final date    = DateTime.now().subtract(Duration(days: days));
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      where: 'arnia = ? AND data >= ?',
      whereArgs: [arniaId, dateStr],
      orderBy: 'data DESC',
    );
    return maps.map(_convertFromSql).toList();
  }

  Future<Map<String, dynamic>?> getLatestByArnia(int arniaId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _dbHelper.tableControlli,
      where: 'arnia = ?',
      whereArgs: [arniaId],
      orderBy: 'data DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _convertFromSql(maps.first);
  }

  Future<List<Map<String, dynamic>>> getPendingChanges() async {
    return await _dbHelper.getPendingChanges(_dbHelper.tableControlli);
  }

  Future<void> markSynced(int id) async {
    await _dbHelper.markSynced(_dbHelper.tableControlli, id);
  }

  Future<void> syncFromServer(List<Map<String, dynamic>> records) async {
    // Filter out any server fields not present in the local SQLite schema.
    // This prevents DatabaseException when the backend adds new columns before
    // the app's schema is migrated (e.g. telaini_config on schema v2).
    final knownColumns = await _dbHelper.getTableColumns(_dbHelper.tableControlli);
    final filtered = records
        .map((r) {
          final map = Map<String, dynamic>.from(r);
          // Mappa colonia (API) -> colonia_id (SQLite)
          if (map.containsKey('colonia') && map['colonia'] != null) {
            map['colonia_id'] = map['colonia'];
          }
          return Map<String, dynamic>.fromEntries(
            map.entries.where((e) => knownColumns.contains(e.key)),
          );
        })
        .toList();
    await _dbHelper.batchInsertOrUpdate(_dbHelper.tableControlli, filtered);
  }
  
  Future<int> delete(int id) async {
    return await _dbHelper.delete(
      _dbHelper.tableControlli,
      'id = ?',
      [id],
    );
  }
}
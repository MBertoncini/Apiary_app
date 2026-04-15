import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/colonia.dart';

/// DAO per la tabella locale `colonie`.
/// Gestisce la cache offline delle colonie sincronizzate dal server.
class ColoniaDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ── Campi booleani da convertire (SQLite li salva come 0/1) ──────────────
  static const List<String> _boolFields = ['is_attiva'];

  Map<String, dynamic> _convertBools(Map<String, dynamic> row) {
    final result = Map<String, dynamic>.from(row);
    for (final field in _boolFields) {
      if (result[field] is int) {
        result[field] = result[field] == 1;
      }
    }
    return result;
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<int> insert(Map<String, dynamic> data) async {
    final db = await _dbHelper.database;
    final cols = await _dbHelper.getTableColumns(_dbHelper.tableColonie);
    final filtered = Map.fromEntries(
      data.entries.where((e) => cols.contains(e.key)),
    );
    // Converti bool → int per SQLite
    for (final field in _boolFields) {
      if (filtered[field] is bool) {
        filtered[field] = (filtered[field] as bool) ? 1 : 0;
      }
    }
    filtered['sync_status'] = 'synced';
    filtered['last_updated'] = DateTime.now().millisecondsSinceEpoch;
    return await db.insert(
      _dbHelper.tableColonie, filtered,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> syncFromServer(List<Map<String, dynamic>> colonieData) async {
    for (final c in colonieData) {
      await insert(c);
    }
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      _dbHelper.tableColonie,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _dbHelper.tableColonie,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _convertBools(rows.first);
  }

  Future<List<Map<String, dynamic>>> getByApiario(int apiarioId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _dbHelper.tableColonie,
      where: 'apiario = ?',
      whereArgs: [apiarioId],
      orderBy: 'data_inizio DESC',
    );
    return rows.map(_convertBools).toList();
  }

  Future<List<Map<String, dynamic>>> getByArnia(int arniaId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _dbHelper.tableColonie,
      where: 'arnia = ?',
      whereArgs: [arniaId],
      orderBy: 'data_inizio DESC',
    );
    return rows.map(_convertBools).toList();
  }

  /// Restituisce la colonia attiva in un'arnia (is_attiva=1).
  Future<Map<String, dynamic>?> getAttivaByArnia(int arniaId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _dbHelper.tableColonie,
      where: 'arnia = ? AND is_attiva = 1',
      whereArgs: [arniaId],
      orderBy: 'data_inizio DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _convertBools(rows.first);
  }

  /// Restituisce la colonia attiva in un nucleo.
  Future<Map<String, dynamic>?> getAttivaByNucleo(int nucleoId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _dbHelper.tableColonie,
      where: 'nucleo = ? AND is_attiva = 1',
      whereArgs: [nucleoId],
      orderBy: 'data_inizio DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _convertBools(rows.first);
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _dbHelper.tableColonie,
      orderBy: 'data_inizio DESC',
    );
    return rows.map(_convertBools).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Converte una riga del DAO in un oggetto [Colonia].
  static Colonia fromRow(Map<String, dynamic> row) {
    Map<String, dynamic>? reginaAttiva;
    final raw = row['regina_attiva'];
    if (raw is String && raw.isNotEmpty) {
      try { reginaAttiva = jsonDecode(raw) as Map<String, dynamic>; } catch (_) {}
    } else if (raw is Map<String, dynamic>) {
      reginaAttiva = raw;
    }
    return Colonia(
      id:                  row['id'] as int,
      apiario:             row['apiario'] as int,
      apiarioNome:         row['apiario_nome'] as String? ?? '',
      arnia:               row['arnia'] as int?,
      nucleo:              row['nucleo'] as int?,
      contenitore:         row['contenitore'] as String? ?? '',
      contenitoreNumero:   row['contenitore_numero'] as int?,
      dataInizio:          row['data_inizio'] as String,
      dataFine:            row['data_fine'] as String?,
      stato:               row['stato'] as String,
      isAttiva:            row['is_attiva'] == true || row['is_attiva'] == 1,
      motivoFine:          row['motivo_fine'] as String?,
      noteFine:            row['note_fine'] as String?,
      note:                row['note'] as String?,
      coloniaOrigineId:    row['colonia_origine'] as int?,
      coloniaSuccessoreId: row['colonia_successore'] as int?,
      dataCreazione:       row['data_creazione'] as String?,
      nControlli:          row['n_controlli'] as int?,
      reginaAttiva:        reginaAttiva,
    );
  }

  /// Converte un oggetto [Colonia] in una mappa per la tabella locale.
  static Map<String, dynamic> toRow(Colonia c) {
    return {
      'id':                 c.id,
      'apiario':            c.apiario,
      'apiario_nome':       c.apiarioNome,
      'arnia':              c.arnia,
      'nucleo':             c.nucleo,
      'contenitore':        c.contenitore,
      'contenitore_numero': c.contenitoreNumero,
      'data_inizio':        c.dataInizio,
      'data_fine':          c.dataFine,
      'stato':              c.stato,
      'is_attiva':          c.isAttiva ? 1 : 0,
      'motivo_fine':        c.motivoFine,
      'note_fine':          c.noteFine,
      'note':               c.note,
      'colonia_origine':    c.coloniaOrigineId,
      'colonia_successore': c.coloniaSuccessoreId,
      'data_creazione':     c.dataCreazione,
      'n_controlli':        c.nControlli,
      'regina_attiva':      c.reginaAttiva != null ? jsonEncode(c.reginaAttiva) : null,
    };
  }
}


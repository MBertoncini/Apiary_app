import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  final String _databaseName = "apiario_manager.db";
  final int _databaseVersion = 1;

  // Tabelle
  final String tableApiari = 'apiari';
  final String tableArnie = 'arnie';
  final String tableControlli = 'controlli';
  final String tableRegine = 'regine';
  final String tableFioriture = 'fioriture';
  final String tableTrattamenti = 'trattamenti';
  final String tableMelari = 'melari';
  final String tableSmielature = 'smielature';
  final String tableSyncStatus = 'sync_status';

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabella Apiari
    await db.execute('''
      CREATE TABLE $tableApiari (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL,
        posizione TEXT NOT NULL,
        latitudine REAL,
        longitudine REAL,
        note TEXT,
        monitoraggio_meteo INTEGER NOT NULL,
        proprietario INTEGER NOT NULL,
        proprietario_username TEXT NOT NULL,
        gruppo INTEGER,
        condiviso_con_gruppo INTEGER NOT NULL,
        visibilita_mappa TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        last_updated INTEGER NOT NULL
      )
    ''');

    // Tabella Arnie
    await db.execute('''
      CREATE TABLE $tableArnie (
        id INTEGER PRIMARY KEY,
        apiario INTEGER NOT NULL,
        apiario_nome TEXT NOT NULL,
        numero INTEGER NOT NULL,
        colore TEXT NOT NULL,
        colore_hex TEXT NOT NULL,
        data_installazione TEXT NOT NULL,
        note TEXT,
        attiva INTEGER NOT NULL,
        sync_status TEXT NOT NULL,
        last_updated INTEGER NOT NULL,
        FOREIGN KEY (apiario) REFERENCES $tableApiari(id) ON DELETE CASCADE
      )
    ''');

    // Tabella Controlli
    await db.execute('''
      CREATE TABLE $tableControlli (
        id INTEGER PRIMARY KEY,
        arnia INTEGER NOT NULL,
        arnia_numero INTEGER NOT NULL,
        apiario_nome TEXT NOT NULL,
        apiario_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        utente INTEGER NOT NULL,
        utente_username TEXT NOT NULL,
        telaini_scorte INTEGER NOT NULL,
        telaini_covata INTEGER NOT NULL,
        presenza_regina INTEGER NOT NULL,
        sciamatura INTEGER NOT NULL,
        data_sciamatura TEXT,
        note_sciamatura TEXT,
        problemi_sanitari INTEGER NOT NULL,
        note_problemi TEXT,
        note TEXT,
        data_creazione TEXT NOT NULL,
        regina_vista INTEGER NOT NULL,
        uova_fresche INTEGER NOT NULL,
        celle_reali INTEGER NOT NULL,
        numero_celle_reali INTEGER NOT NULL,
        regina_sostituita INTEGER NOT NULL,
        sync_status TEXT NOT NULL,
        last_updated INTEGER NOT NULL,
        FOREIGN KEY (arnia) REFERENCES $tableArnie(id) ON DELETE CASCADE
      )
    ''');

    // Tabella Regine
    await db.execute('''
      CREATE TABLE $tableRegine (
        id INTEGER PRIMARY KEY,
        arnia INTEGER NOT NULL,
        arnia_numero INTEGER NOT NULL,
        apiario_nome TEXT NOT NULL,
        apiario_id INTEGER NOT NULL,
        data_nascita TEXT,
        data_introduzione TEXT NOT NULL,
        origine TEXT NOT NULL,
        razza TEXT NOT NULL,
        regina_madre INTEGER,
        marcata INTEGER NOT NULL,
        codice_marcatura TEXT,
        colore_marcatura TEXT NOT NULL,
        fecondata INTEGER NOT NULL,
        selezionata INTEGER NOT NULL,
        docilita INTEGER,
        produttivita INTEGER,
        resistenza_malattie INTEGER,
        tendenza_sciamatura INTEGER,
        note TEXT,
        sync_status TEXT NOT NULL,
        last_updated INTEGER NOT NULL,
        FOREIGN KEY (arnia) REFERENCES $tableArnie(id) ON DELETE CASCADE,
        FOREIGN KEY (regina_madre) REFERENCES $tableRegine(id) ON DELETE SET NULL
      )
    ''');

    // Tabella Fioriture
    await db.execute('''
      CREATE TABLE $tableFioriture (
        id INTEGER PRIMARY KEY,
        apiario INTEGER,
        apiario_nome TEXT,
        pianta TEXT NOT NULL,
        data_inizio TEXT NOT NULL,
        data_fine TEXT,
        latitudine REAL NOT NULL,
        longitudine REAL NOT NULL,
        raggio INTEGER,
        note TEXT,
        creatore INTEGER,
        creatore_username TEXT,
        is_active INTEGER NOT NULL,
        sync_status TEXT NOT NULL,
        last_updated INTEGER NOT NULL,
        FOREIGN KEY (apiario) REFERENCES $tableApiari(id) ON DELETE SET NULL
      )
    ''');

    // Tabella Trattamenti
    await db.execute('''
      CREATE TABLE $tableTrattamenti (
        id INTEGER PRIMARY KEY,
        apiario INTEGER NOT NULL,
        apiario_nome TEXT NOT NULL,
        tipo_trattamento INTEGER NOT NULL,
        tipo_trattamento_nome TEXT NOT NULL,
        data_inizio TEXT NOT NULL,
        data_fine TEXT,
        data_fine_sospensione TEXT,
        stato TEXT NOT NULL,
        utente INTEGER NOT NULL,
        utente_username TEXT NOT NULL,
        note TEXT,
        blocco_covata_attivo INTEGER NOT NULL,
        data_inizio_blocco TEXT,
        data_fine_blocco TEXT,
        metodo_blocco TEXT,
        note_blocco TEXT,
        sync_status TEXT NOT NULL,
        last_updated INTEGER NOT NULL,
        FOREIGN KEY (apiario) REFERENCES $tableApiari(id) ON DELETE CASCADE
      )
    ''');

    // Tabella arnie_trattamenti (many-to-many)
    await db.execute('''
      CREATE TABLE arnie_trattamenti (
        trattamento_id INTEGER NOT NULL,
        arnia_id INTEGER NOT NULL,
        PRIMARY KEY (trattamento_id, arnia_id),
        FOREIGN KEY (trattamento_id) REFERENCES $tableTrattamenti(id) ON DELETE CASCADE,
        FOREIGN KEY (arnia_id) REFERENCES $tableArnie(id) ON DELETE CASCADE
      )
    ''');

    // Tabella Melari
    await db.execute('''
      CREATE TABLE $tableMelari (
        id INTEGER PRIMARY KEY,
        arnia INTEGER NOT NULL,
        arnia_numero INTEGER NOT NULL,
        apiario_id INTEGER NOT NULL,
        apiario_nome TEXT NOT NULL,
        numero_telaini INTEGER NOT NULL,
        posizione INTEGER NOT NULL,
        data_posizionamento TEXT NOT NULL,
        data_rimozione TEXT,
        stato TEXT NOT NULL,
        note TEXT,
        sync_status TEXT NOT NULL,
        last_updated INTEGER NOT NULL,
        FOREIGN KEY (arnia) REFERENCES $tableArnie(id) ON DELETE CASCADE
      )
    ''');

    // Tabella Smielature
    await db.execute('''
      CREATE TABLE $tableSmielature (
        id INTEGER PRIMARY KEY,
        data TEXT NOT NULL,
        apiario INTEGER NOT NULL,
        apiario_nome TEXT NOT NULL,
        quantita_miele REAL NOT NULL,
        tipo_miele TEXT NOT NULL,
        utente INTEGER NOT NULL,
        utente_username TEXT NOT NULL,
        note TEXT,
        data_registrazione TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        last_updated INTEGER NOT NULL,
        FOREIGN KEY (apiario) REFERENCES $tableApiari(id) ON DELETE CASCADE
      )
    ''');

    // Tabella melari_smielature (many-to-many)
    await db.execute('''
      CREATE TABLE melari_smielature (
        smielatura_id INTEGER NOT NULL,
        melario_id INTEGER NOT NULL,
        PRIMARY KEY (smielatura_id, melario_id),
        FOREIGN KEY (smielatura_id) REFERENCES $tableSmielature(id) ON DELETE CASCADE,
        FOREIGN KEY (melario_id) REFERENCES $tableMelari(id) ON DELETE CASCADE
      )
    ''');

    // Tabella Stato Sincronizzazione
    await db.execute('''
      CREATE TABLE $tableSyncStatus (
        entity_name TEXT PRIMARY KEY,
        last_sync TEXT NOT NULL
      )
    ''');

    // Inizializza tabella di stato sincronizzazione
    final entities = [
      'apiari', 'arnie', 'controlli', 'regine', 
      'fioriture', 'trattamenti', 'melari', 'smielature'
    ];
    
    final batch = db.batch();
    for (var entity in entities) {
      batch.insert(tableSyncStatus, {
        'entity_name': entity,
        'last_sync': DateTime.now().toIso8601String()
      });
    }
    await batch.commit();
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Gestione aggiornamenti schema per future versioni
    if (oldVersion < 2) {
      // Aggiungi migrazioni per versione 2
    }
  }

  // Metodi CRUD generici
  Future<int> insert(String table, Map<String, dynamic> data) async {
    data['sync_status'] = 'pending';
    data['last_updated'] = DateTime.now().millisecondsSinceEpoch;
    Database db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    Database db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(String table, Map<String, dynamic> data, String where, List<dynamic> whereArgs) async {
    data['sync_status'] = 'pending';
    data['last_updated'] = DateTime.now().millisecondsSinceEpoch;
    Database db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<dynamic> whereArgs) async {
    Database db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // Metodi specifici per la sincronizzazione
  Future<void> updateSyncStatus(String entityName, String lastSync) async {
    Database db = await database;
    await db.update(
      tableSyncStatus,
      {'last_sync': lastSync},
      where: 'entity_name = ?',
      whereArgs: [entityName],
    );
  }

  Future<String?> getLastSyncTime(String entityName) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      tableSyncStatus,
      where: 'entity_name = ?',
      whereArgs: [entityName],
    );
    
    if (result.isNotEmpty) {
      return result.first['last_sync'];
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getPendingChanges(String table) async {
    Database db = await database;
    return await db.query(
      table,
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );
  }

  Future<void> markSynced(String table, int id) async {
    Database db = await database;
    await db.update(
      table,
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> batchInsertOrUpdate(String table, List<Map<String, dynamic>> records) async {
    final db = await database;
    final batch = db.batch();
    
    for (final record in records) {
      record['sync_status'] = 'synced';
      record['last_updated'] = DateTime.now().millisecondsSinceEpoch;
      
      // Check if record exists
      final List<Map<String, dynamic>> existing = await db.query(
        table, 
        where: 'id = ?', 
        whereArgs: [record['id']]
      );
      
      if (existing.isNotEmpty) {
        batch.update(
          table, 
          record, 
          where: 'id = ?', 
          whereArgs: [record['id']]
        );
      } else {
        batch.insert(table, record);
      }
    }
    
    await batch.commit(noResult: true);
  }
  
  // Metodi per transazioni
  Future<T> inTransaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Metodi di pulizia
  Future<void> clearSyncedData(Duration olderThan) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(olderThan).millisecondsSinceEpoch;
    
    final tables = [
      tableApiari, tableArnie, tableControlli, tableRegine,
      tableFioriture, tableTrattamenti, tableMelari, tableSmielature
    ];
    
    for (final table in tables) {
      await db.delete(
        table,
        where: 'sync_status = ? AND last_updated < ?',
        whereArgs: ['synced', cutoffTime],
      );
    }
  }
}
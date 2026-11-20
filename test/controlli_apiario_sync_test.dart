import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:apiary_app/constants/api_constants.dart';
import 'package:apiary_app/database/dao/controllo_arnia_dao.dart';
import 'package:apiary_app/database/database_helper.dart';
import 'package:apiary_app/services/api_service.dart';
import 'package:apiary_app/services/auth_token_provider.dart';
import 'package:apiary_app/services/controllo_service.dart';

/// Il database locale finisce in una cartella temporanea, non nei documenti.
class _TempPathProvider extends PathProviderPlatform {
  _TempPathProvider(this.path);
  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

class _NoAuth implements AuthTokenProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('auth non usata nei test');
}

/// ApiService finto: risponde ai GET con le risposte registrate per URL.
class _FakeApi extends ApiService {
  _FakeApi(this.risposte) : super(_NoAuth());

  final Map<String, dynamic> risposte;
  final List<String> richieste = [];

  @override
  Future<dynamic> get(String endpoint) async {
    richieste.add(endpoint);
    final r = risposte[endpoint];
    if (r == null) throw StateError('GET inatteso: $endpoint');
    if (r is Exception) throw r;
    return r;
  }
}

String _giorniFa(int giorni) {
  final d = DateTime.now().subtract(Duration(days: giorni));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}'
      '-${d.day.toString().padLeft(2, '0')}';
}

/// Controllo come lo restituisce ControlloArniaDetailSerializer.
Map<String, dynamic> _dettaglio(int id, int arnia, String data,
        {int scorte = 3}) =>
    {
      'id': id,
      'colonia': 100 + arnia,
      'colonia_id': 100 + arnia,
      'arnia': arnia,
      'arnia_numero': arnia,
      'apiario_nome': 'Prova',
      'apiario_id': 7,
      'data': data,
      'utente': 1,
      'utente_username': 'prova',
      'telaini_scorte': scorte,
      'telaini_covata': 4,
      'presenza_regina': true,
      'sciamatura': false,
      'data_sciamatura': null,
      'note_sciamatura': null,
      'problemi_sanitari': false,
      'note_problemi': null,
      'note': 'nota $id',
      'data_creazione': '${data}T10:00:00Z',
      'regina_vista': true,
      'uova_fresche': true,
      'celle_reali': false,
      'numero_celle_reali': 0,
      'regina_sostituita': false,
      'sostituzione_scatola': false,
      'telaini_config': null,
    };

/// Controllo come lo restituisce ControlloArniaListSerializer (server senza
/// ?detail=1).
Map<String, dynamic> _breve(int id, int arnia, String data) => {
      'id': id,
      'colonia': 100 + arnia,
      'colonia_id': 100 + arnia,
      'arnia': arnia,
      'arnia_numero': arnia,
      'apiario_nome': 'Prova',
      'data': data,
      'telaini_scorte': 9,
      'telaini_covata': 9,
      'presenza_regina': true,
      'problemi_sanitari': false,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  final dao = ControlloArniaDao();
  final db = DatabaseHelper();

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('apiary_test_');
    PathProviderPlatform.instance = _TempPathProvider(tempDir.path);
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await (await db.database).close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // Su Windows il file puo' restare bloccato per poco: non e' un errore.
    }
  });

  setUp(() async {
    await (await db.database).delete(db.tableControlli);
  });

  Future<List<int>> idsInCache() async {
    final rows = await (await db.database)
        .query(db.tableControlli, columns: ['id'], orderBy: 'id');
    return rows.map((r) => r['id'] as int).toList();
  }

  /// Controllo creato offline e non ancora inviato al server. I bool vanno
  /// passati come 0/1: sqflite su Android li converte, l'FFI dei test no.
  Future<void> inserisciPending(int id, int arnia, String data) async {
    await dao.insert(_dettaglio(id, arnia, data)
        .map((k, v) => MapEntry(k, v is bool ? (v ? 1 : 0) : v)));
  }

  group('ControlloArniaDao.replaceArnieFromServer', () {
    test('aggiorna i ricevuti e toglie solo i sincronizzati spariti dal server',
        () async {
      await dao.syncFromServer([
        _dettaglio(1, 10, _giorniFa(5)), // resta: ancora sul server
        _dettaglio(2, 10, _giorniFa(6)), // cancellato dal web: va tolto
        _dettaglio(3, 11, _giorniFa(7)), // cancellato dal web: va tolto
        _dettaglio(4, 10, _giorniFa(200)), // fuori finestra: resta
        _dettaglio(5, 99, _giorniFa(5)), // arnia di un altro apiario: resta
      ]);
      await inserisciPending(-1, 10, _giorniFa(1)); // offline: resta

      await dao.replaceArnieFromServer(
        [10, 11],
        [_dettaglio(1, 10, _giorniFa(5), scorte: 6), _dettaglio(6, 11, _giorniFa(2))],
        days: 90,
      );

      expect(await idsInCache(), [-1, 1, 4, 5, 6]);
      expect((await dao.getById(1))!['telaini_scorte'], 6);
      expect((await dao.getById(-1))!['sync_status'], 'pending');
      // Le colonne booleane tornano bool anche dopo la sostituzione.
      expect((await dao.getById(6))!['presenza_regina'], isTrue);
    });

    test('ripetere la sincronizzazione non duplica i controlli', () async {
      final risposta = [
        _dettaglio(1, 10, _giorniFa(5)),
        _dettaglio(2, 11, _giorniFa(3)),
      ];
      await dao.replaceArnieFromServer([10, 11], risposta);
      await dao.replaceArnieFromServer([10, 11], risposta);

      expect(await idsInCache(), [1, 2]);
    });

    test('senza arnie si limita ad aggiornare, non cancella nulla', () async {
      await dao.syncFromServer([_dettaglio(1, 10, _giorniFa(5))]);

      await dao.replaceArnieFromServer([], [_dettaglio(2, 11, _giorniFa(3))]);

      expect(await idsInCache(), [1, 2]);
    });
  });

  group('ControlloService.syncControlliByApiario', () {
    const apiarioId = 7;
    const url =
        '${ApiConstants.apiariUrl}$apiarioId/controlli/?days=90&detail=1';

    test('risposta completa: una sola richiesta e cache allineata', () async {
      await dao.syncFromServer([_dettaglio(2, 10, _giorniFa(6))]);
      final api = _FakeApi({
        url: [_dettaglio(1, 10, _giorniFa(5)), _dettaglio(3, 11, _giorniFa(4))],
      });

      final ok =
          await ControlloService(api).syncControlliByApiario(apiarioId, [10, 11]);

      expect(ok, isTrue);
      expect(api.richieste, [url]);
      expect(await idsInCache(), [1, 3]);
      expect((await dao.getById(3))!['note'], 'nota 3');
    });

    test('server senza detail=1 (risposta breve): false e cache intatta',
        () async {
      await dao.syncFromServer([
        _dettaglio(1, 10, _giorniFa(5)),
        _dettaglio(2, 10, _giorniFa(6)),
      ]);
      final api = _FakeApi({
        url: [_breve(1, 10, _giorniFa(5))],
      });

      final ok =
          await ControlloService(api).syncControlliByApiario(apiarioId, [10]);

      expect(ok, isFalse);
      expect(await idsInCache(), [1, 2]);
      // Il record breve non sovrascrive quello completo in cache.
      final c = await dao.getById(1);
      expect(c!['telaini_scorte'], 3);
      expect(c['note'], 'nota 1');
    });

    test('lista vuota: toglie i sincronizzati, tiene quelli offline', () async {
      await dao.syncFromServer([_dettaglio(1, 10, _giorniFa(5))]);
      await inserisciPending(-1, 10, _giorniFa(1));
      final api = _FakeApi({url: <dynamic>[]});

      final ok =
          await ControlloService(api).syncControlliByApiario(apiarioId, [10]);

      expect(ok, isTrue);
      expect(await idsInCache(), [-1]);
    });

    test('pagina con altre pagine dopo: false, cache intatta', () async {
      await dao.syncFromServer([_dettaglio(1, 10, _giorniFa(5))]);
      final api = _FakeApi({
        url: {
          'count': 2,
          'next': '$url&page=2',
          'results': [_dettaglio(2, 10, _giorniFa(3))],
        },
      });

      final ok =
          await ControlloService(api).syncControlliByApiario(apiarioId, [10]);

      expect(ok, isFalse);
      expect(await idsInCache(), [1]);
    });

    test('pagina unica (results senza next): trattata come lista completa',
        () async {
      final api = _FakeApi({
        url: {
          'count': 1,
          'next': null,
          'results': [_dettaglio(2, 10, _giorniFa(3))],
        },
      });

      final ok =
          await ControlloService(api).syncControlliByApiario(apiarioId, [10]);

      expect(ok, isTrue);
      expect(await idsInCache(), [2]);
    });

    test('errore del server: eccezione rilanciata, cache intatta', () async {
      await dao.syncFromServer([_dettaglio(1, 10, _giorniFa(5))]);
      final api = _FakeApi({
        url: HttpStatusException(statusCode: 502, body: 'errore'),
      });

      await expectLater(
        ControlloService(api).syncControlliByApiario(apiarioId, [10]),
        throwsA(isA<HttpStatusException>()),
      );
      expect(await idsInCache(), [1]);
      expect(api.richieste, [url]);
    });
  });
}

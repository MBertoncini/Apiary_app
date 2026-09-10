import 'package:flutter_test/flutter_test.dart';

import 'package:apiary_app/models/melario.dart';
import 'package:apiary_app/utils/melari_stats.dart';

Melario _melario({
  required int id,
  required String stato,
  int? arnia,
  int? apiario,
}) =>
    Melario(
      id: id,
      colonia: 100 + id,
      coloniaId: 100 + id,
      arnia: arnia,
      arniaNumero: arnia,
      apiarioId: apiario,
      apiarioNome: 'Apiario $apiario',
      numeroTelaini: 10,
      posizione: 1,
      dataPosizionamento: '2026-05-01',
      stato: stato,
    );

void main() {
  group('Melario round-trip cache', () {
    test('toJson conserva arnia, colonia e apiario', () {
      final m = _melario(id: 7, stato: 'rimosso', arnia: 3, apiario: 2);
      final back = Melario.fromJson(m.toJson());

      expect(back.id, 7);
      expect(back.stato, 'rimosso');
      // Il campo su cui la vista alveari raggruppa i melari: se si perde,
      // il melario sparisce dalla colonna dell'arnia dopo un riavvio.
      expect(back.arnia, 3);
      expect(back.arniaNumero, 3);
      expect(back.apiarioId, 2);
      expect(back.colonia, 107);
      expect(back.coloniaId, 107);
    });

    test('round-trip stabile su piu passaggi', () {
      final m = _melario(id: 1, stato: 'posizionato', arnia: 9, apiario: 4);
      final due = Melario.fromJson(Melario.fromJson(m.toJson()).toJson());
      expect(due.arnia, 9);
      expect(due.apiarioId, 4);
      expect(due.numeroTelaini, 10);
      expect(due.escludiRegina, isTrue);
    });

    test('sopravvive ai campi opzionali nulli', () {
      final m = Melario(
        id: 5,
        numeroTelaini: 10,
        posizione: 1,
        dataPosizionamento: '2026-05-01',
        stato: 'smielato',
      );
      final back = Melario.fromJson(m.toJson());
      expect(back.arnia, isNull);
      expect(back.colonia, isNull);
      expect(back.stato, 'smielato');
    });
  });

  group('melariGiaSmielatiIds', () {
    test('raccoglie gli id da tutte le smielature', () {
      final ids = melariGiaSmielatiIds([
        {'id': 1, 'melari': [10, 11]},
        {'id': 2, 'melari': [12]},
      ]);
      expect(ids, {10, 11, 12});
    });

    test('tollera liste mancanti o malformate dalla cache', () {
      final ids = melariGiaSmielatiIds([
        {'id': 1},
        {'id': 2, 'melari': null},
        {'id': 3, 'melari': 'non-una-lista'},
        {'id': 4, 'melari': [5, '6', 7.0]},
      ]);
      expect(ids, {5, 6, 7});
    });
  });

  group('isMelarioDaSmielare', () {
    test('conta i rimossi non ancora smielati', () {
      final m = _melario(id: 1, stato: 'rimosso', arnia: 1, apiario: 1);
      expect(isMelarioDaSmielare(m, {}), isTrue);
    });

    test('non conta i melari ancora posizionati', () {
      final m = _melario(id: 1, stato: 'posizionato', arnia: 1, apiario: 1);
      expect(isMelarioDaSmielare(m, {}), isFalse);
    });

    test('non conta i melari gia smielati per stato', () {
      final m = _melario(id: 1, stato: 'smielato', arnia: 1, apiario: 1);
      expect(isMelarioDaSmielare(m, {}), isFalse);
    });

    test('il caso segnalato: rimosso ma gia incluso in una smielatura', () {
      // Il backend non ha ancora portato lo stato a 'smielato' (o la cache e
      // stale), ma la produzione lo elenca fra i suoi melari: non va contato.
      final m = _melario(id: 42, stato: 'rimosso', arnia: 1, apiario: 1);
      final ids = melariGiaSmielatiIds([
        {'id': 9, 'melari': [42]},
      ]);
      expect(isMelarioDaSmielare(m, ids), isFalse);
    });

    test('conteggio sotto la singola arnia: rimozione poi smielatura', () {
      // Arnia 1 ha due melari posizionati. L'utente li rimuove: finiscono
      // "da smielare" sotto quella arnia. Registrata la smielatura, il badge
      // sotto l'arnia deve sparire.
      var melari = [
        _melario(id: 1, stato: 'posizionato', arnia: 1, apiario: 1),
        _melario(id: 2, stato: 'posizionato', arnia: 1, apiario: 1),
      ];
      int daSmielareSuArnia1(List<Melario> l, Set<int> ids) => l
          .where((m) => m.arnia == 1 && isMelarioDaSmielare(m, ids))
          .length;

      expect(daSmielareSuArnia1(melari, {}), 0);

      // "Rimuovi": lo stato passa a 'rimosso', il melario resta legato
      // all'arnia e conta come da smielare. Comportamento atteso.
      melari = melari.map((m) => m.copyWith(stato: 'rimosso')).toList();
      expect(daSmielareSuArnia1(melari, {}), 2);

      // Smielatura registrata: la produzione elenca i due melari.
      final ids = melariGiaSmielatiIds([
        {'id': 5, 'melari': [1, 2]},
      ]);
      expect(daSmielareSuArnia1(melari, ids), 0);
    });

    test('conteggio sotto la singola arnia: eliminazione del melario', () {
      // "Elimina" toglie il record: sparisce da entrambi i conteggi.
      final melari = [
        _melario(id: 1, stato: 'rimosso', arnia: 1, apiario: 1),
        _melario(id: 2, stato: 'rimosso', arnia: 1, apiario: 1),
      ];
      int suArnia1(List<Melario> l) =>
          l.where((m) => m.arnia == 1 && isMelarioDaSmielare(m, {})).length;

      expect(suArnia1(melari), 2);
      final dopoDelete = melari.where((m) => m.id != 1).toList();
      expect(suArnia1(dopoDelete), 1);
      expect(suArnia1(const []), 0);
    });

    test('il conteggio non sconfina fra arnie diverse', () {
      final melari = [
        _melario(id: 1, stato: 'rimosso', arnia: 1, apiario: 1),
        _melario(id: 2, stato: 'rimosso', arnia: 2, apiario: 1),
      ];
      int suArnia(int a) => melari
          .where((m) => m.arnia == a && isMelarioDaSmielare(m, {}))
          .length;
      expect(suArnia(1), 1);
      expect(suArnia(2), 1);
      expect(suArnia(3), 0);
    });

    test('conteggio per apiario dopo la smielatura', () {
      final melari = [
        _melario(id: 1, stato: 'rimosso', arnia: 1, apiario: 1),
        _melario(id: 2, stato: 'rimosso', arnia: 1, apiario: 1),
        _melario(id: 3, stato: 'rimosso', arnia: 2, apiario: 1),
        _melario(id: 4, stato: 'posizionato', arnia: 2, apiario: 1),
      ];
      final ids = melariGiaSmielatiIds([
        {'id': 9, 'melari': [1, 2, 3]},
      ]);
      final residui = melari.where((m) => isMelarioDaSmielare(m, ids)).length;
      expect(residui, 0);
    });
  });
}

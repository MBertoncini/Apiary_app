import 'package:flutter_test/flutter_test.dart';

import 'package:apiary_app/models/alimentazione.dart';
import 'package:apiary_app/utils/alimentazioni_stats.dart';

Alimentazione _a({
  int id = 1,
  int colonia = 1,
  String data = '2026-09-01',
  String tipo = 'candito',
  String? tipoDisplay,
  String? scopo,
  String? scopoDisplay,
  double kg = 1,
  int? apiario,
  String? apiarioNome,
  String? note,
}) =>
    Alimentazione(
      id: id,
      colonia: colonia,
      coloniaDisplay: 'Arnia $colonia',
      apiario: apiario,
      apiarioNome: apiarioNome,
      data: data,
      tipo: tipo,
      tipoDisplay: tipoDisplay ?? tipo,
      scopo: scopo,
      scopoDisplay: scopoDisplay,
      quantitaKg: kg,
      note: note,
    );

void main() {
  group('parsing modello', () {
    test('legge apiario e note dal JSON del backend', () {
      final a = Alimentazione.fromJson({
        'id': 3,
        'colonia': 12,
        'colonia_display': 'Arnia 4',
        'apiario': 2,
        'apiario_nome': 'Bosco',
        'data': '2026-09-02',
        'tipo': 'sciroppo_2_1',
        'tipo_display': 'Sciroppo 2:1 (invernale)',
        'scopo': 'invernale',
        'scopo_display': 'Riserve invernali',
        'quantita_kg': '2.50',
        'note': 'Prima somministrazione',
      });
      expect(a.apiario, 2);
      expect(a.apiarioNome, 'Bosco');
      expect(a.quantitaKg, 2.5);
      expect(a.note, 'Prima somministrazione');
    });

    test('regge un backend che non espone ancora apiario', () {
      final a = Alimentazione.fromJson({
        'id': 1,
        'colonia': 1,
        'data': '2026-09-02',
        'tipo': 'candito',
        'quantita_kg': 1,
      });
      expect(a.apiario, isNull);
      expect(a.apiarioNome, isNull);
    });
  });

  group('filtri', () {
    final items = [
      _a(id: 1, data: '2026-09-01', tipo: 'candito'),
      _a(id: 2, data: '2025-11-10', tipo: 'candito'),
      _a(id: 3, data: '2026-04-05', tipo: 'sciroppo_1_1'),
    ];

    test('anni disponibili in ordine decrescente', () {
      expect(anniDisponibili(items), [2026, 2025]);
    });

    test('filtro per anno', () {
      expect(filtraAlimentazioni(items, anno: 2026).length, 2);
      expect(filtraAlimentazioni(items, anno: 2025).single.id, 2);
    });

    test('filtro per tipo', () {
      expect(filtraAlimentazioni(items, tipo: 'candito').length, 2);
    });

    test('filtri combinati', () {
      final r = filtraAlimentazioni(items, anno: 2026, tipo: 'candito');
      expect(r.single.id, 1);
    });

    test('nessun filtro restituisce tutto', () {
      expect(filtraAlimentazioni(items).length, 3);
    });
  });

  group('riepilogo', () {
    test('somma kg, conta somministrazioni e colonie distinte', () {
      final r = riepilogo([
        _a(id: 1, colonia: 1, kg: 2, data: '2026-09-01'),
        _a(id: 2, colonia: 1, kg: 3, data: '2026-09-05'),
        _a(id: 3, colonia: 2, kg: 5, data: '2026-08-20'),
      ]);
      expect(r.kgTotali, 10);
      expect(r.somministrazioni, 3);
      expect(r.colonieCoinvolte, 2);
      expect(r.kgPerColonia, 5);
      expect(r.ultimaData, '2026-09-05');
    });

    test('lista vuota', () {
      final r = riepilogo([]);
      expect(r.kgTotali, 0);
      expect(r.somministrazioni, 0);
      expect(r.ultimaData, isNull);
    });
  });

  group('raggruppamenti', () {
    final items = [
      _a(id: 1, tipo: 'candito', tipoDisplay: 'Candito', kg: 2),
      _a(id: 2, tipo: 'candito', tipoDisplay: 'Candito', kg: 3),
      _a(
        id: 3,
        tipo: 'sciroppo_2_1',
        tipoDisplay: 'Sciroppo 2:1 (invernale)',
        kg: 9,
      ),
    ];

    test('per tipo, ordinato per kg decrescenti', () {
      final g = perTipo(items);
      expect(g.first.key, 'sciroppo_2_1');
      expect(g.first.kg, 9);
      expect(g.first.count, 1);
      expect(g[1].key, 'candito');
      expect(g[1].kg, 5);
      expect(g[1].count, 2);
    });

    test('per scopo raggruppa i vuoti sotto una sola voce', () {
      final g = perScopo([
        _a(id: 1, kg: 1),
        _a(id: 2, kg: 2, scopo: '', scopoDisplay: ''),
        _a(id: 3, kg: 4, scopo: 'invernale', scopoDisplay: 'Riserve invernali'),
      ], senzaScopo: 'Non indicato');
      expect(g.first.label, 'Riserve invernali');
      expect(g.last.label, 'Non indicato');
      expect(g.last.kg, 3);
    });

    test('per colonia usa la label del backend', () {
      final g = perColonia([
        _a(id: 1, colonia: 4, kg: 1),
        _a(id: 2, colonia: 4, kg: 1),
        _a(id: 3, colonia: 7, kg: 5),
      ]);
      expect(g.first.label, 'Arnia 7');
      expect(g.last.label, 'Arnia 4');
      expect(g.last.count, 2);
    });

    test('per apiario vuoto se il backend non lo espone', () {
      expect(perApiario(items), isEmpty);
    });

    test('per apiario quando il dato c e', () {
      final g = perApiario([
        _a(id: 1, apiario: 1, apiarioNome: 'Casa', kg: 2),
        _a(id: 2, apiario: 2, apiarioNome: 'Bosco', kg: 7),
        _a(id: 3, apiario: 1, apiarioNome: 'Casa', kg: 1),
      ]);
      expect(g.first.label, 'Bosco');
      expect(g.last.label, 'Casa');
      expect(g.last.kg, 3);
    });
  });

  group('formatKg', () {
    test('taglia gli zeri inutili e usa la virgola', () {
      expect(formatKg(3), '3');
      expect(formatKg(3.5), '3,5');
      expect(formatKg(3.25), '3,25');
      expect(formatKg(0), '0');
    });
  });
}

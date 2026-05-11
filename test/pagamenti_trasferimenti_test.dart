import 'package:flutter_test/flutter_test.dart';
import 'package:apiary_app/screens/pagamento/trasferimenti_calculator.dart';

Map<String, dynamic> _membro({
  required int id,
  required String username,
  required double saldo,
}) {
  return {
    'utenteId': id,
    'username': username,
    'saldo': saldo,
  };
}

void main() {
  group('calcolaTrasferimenti', () {
    test('caso degenere: un creditore e un debitore di pari importo', () {
      final bilancio = [
        _membro(id: 1, username: 'A', saldo: 10.0),
        _membro(id: 2, username: 'B', saldo: -10.0),
      ];

      final trasf = calcolaTrasferimenti(bilancio);

      expect(trasf, hasLength(1));
      expect(trasf.first['da'], 'B');
      expect(trasf.first['a'], 'A');
      expect(trasf.first['importo'], closeTo(10.0, 1e-9));
    });

    test('saldi tutti a zero -> nessun trasferimento', () {
      final bilancio = [
        _membro(id: 1, username: 'A', saldo: 0.0),
        _membro(id: 2, username: 'B', saldo: 0.0),
        _membro(id: 3, username: 'C', saldo: 0.005), // sotto soglia
        _membro(id: 4, username: 'D', saldo: -0.005), // sotto soglia
      ];

      expect(calcolaTrasferimenti(bilancio), isEmpty);
    });

    test('match perfetti vengono risolti con largest-first', () {
      // Largest creditore (C=+10) ↔ largest debitore (D=-10), poi A=+5 ↔ B=-5.
      // Numero ottimo di trasferimenti per questo input: 2.
      final bilancio = [
        _membro(id: 1, username: 'A', saldo: 5.0),
        _membro(id: 2, username: 'B', saldo: -5.0),
        _membro(id: 3, username: 'C', saldo: 10.0),
        _membro(id: 4, username: 'D', saldo: -10.0),
      ];

      final trasf = calcolaTrasferimenti(bilancio);

      expect(trasf, hasLength(2));
      // Verifica che la somma trasferita = somma dei crediti
      final totale = trasf.fold<double>(
        0.0,
        (s, t) => s + (t['importo'] as double),
      );
      expect(totale, closeTo(15.0, 1e-9));
    });

    test('output deterministico indipendente dall\'ordine di input', () {
      final base = [
        _membro(id: 1, username: 'A', saldo: 10.0),
        _membro(id: 2, username: 'B', saldo: 5.0),
        _membro(id: 3, username: 'C', saldo: -7.0),
        _membro(id: 4, username: 'D', saldo: -8.0),
      ];

      final shuffled = [base[3], base[0], base[2], base[1]];
      final reverseShuffled = base.reversed.toList();

      final t1 = calcolaTrasferimenti(base);
      final t2 = calcolaTrasferimenti(shuffled);
      final t3 = calcolaTrasferimenti(reverseShuffled);

      // Stesse triple (da,a,importo) nello stesso ordine.
      String firma(List<Map<String, dynamic>> ts) => ts
          .map((t) =>
              '${t['daId']}->${t['aId']}:${(t['importo'] as double).toStringAsFixed(4)}')
          .join('|');

      expect(firma(t1), equals(firma(t2)));
      expect(firma(t1), equals(firma(t3)));
    });

    test('saldi a parità di valore -> tie-break per utenteId asc', () {
      // Due creditori con saldo identico: deve vincere quello con id minore.
      final bilancio = [
        _membro(id: 7, username: 'Z', saldo: 5.0),
        _membro(id: 3, username: 'M', saldo: 5.0),
        _membro(id: 1, username: 'X', saldo: -10.0),
      ];

      final trasf = calcolaTrasferimenti(bilancio);

      expect(trasf, hasLength(2));
      // Primo trasferimento va al creditore con id minore (3 = M)
      expect(trasf[0]['aId'], 3);
      expect(trasf[1]['aId'], 7);
    });

    test('membro senza quota che ha pagato appare come creditore', () {
      // Scenario "ghost-payment": un membro non ha quota ma ha pagato 20€.
      // Saldo netto positivo, deve essere rimborsato dagli altri.
      final bilancio = [
        _membro(id: 1, username: 'A', saldo: -10.0),
        _membro(id: 2, username: 'B', saldo: -10.0),
        _membro(id: 99, username: 'Ghost', saldo: 20.0),
      ];

      final trasf = calcolaTrasferimenti(bilancio);

      expect(trasf, hasLength(2));
      // Ghost riceve da entrambi
      expect(trasf.every((t) => t['aId'] == 99), isTrue);
      final totale = trasf.fold<double>(
        0.0,
        (s, t) => s + (t['importo'] as double),
      );
      expect(totale, closeTo(20.0, 1e-9));
    });

    test('non muta il bilancio in input', () {
      final bilancio = [
        _membro(id: 1, username: 'A', saldo: 10.0),
        _membro(id: 2, username: 'B', saldo: -10.0),
      ];
      final saldoPrima = bilancio[0]['saldo'];

      calcolaTrasferimenti(bilancio);

      expect(bilancio[0]['saldo'], saldoPrima);
      expect(bilancio[0].containsKey('residuo'), isFalse);
    });
  });
}

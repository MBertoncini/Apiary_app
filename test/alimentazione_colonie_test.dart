import 'package:flutter_test/flutter_test.dart';
import 'package:apiary_app/screens/alimentazione/alimentazione_form_screen.dart';

Map<String, dynamic> _colonia(
  int id, {
  int? arnia,
  int? nucleo,
  String dataInizio = '2026-03-01',
  bool attiva = true,
}) =>
    {
      'id': id,
      'apiario': 1,
      'arnia': arnia,
      'nucleo': nucleo,
      'contenitore': arnia != null ? 'arnia' : (nucleo != null ? 'nucleo' : null),
      'contenitore_numero': arnia ?? nucleo,
      'data_inizio': dataInizio,
      'is_attiva': attiva,
    };

List<int> _ids(List<Map<String, dynamic>> l) =>
    l.map((c) => c['id'] as int).toList()..sort();

void main() {
  const sel = AlimentazioneFormScreen.colonieSelezionabili;

  test('scarta le colonie chiuse e quelle senza contenitore', () {
    final out = sel([
      _colonia(1, arnia: 10),
      _colonia(2, arnia: 11, attiva: false),
      _colonia(3), // arnia eliminata: colonia rimasta attiva senza box
    ]);
    expect(_ids(out), [1]);
  });

  test('una sola colonia per box, la più recente', () {
    final out = sel([
      _colonia(1, arnia: 10, dataInizio: '2026-03-01'),
      _colonia(2, arnia: 10, dataInizio: '2026-05-01'),
      _colonia(3, nucleo: 10),
    ]);
    expect(_ids(out), [2, 3]);
  });

  test('a parità di data vince l\'id più alto', () {
    final out = sel([
      _colonia(5, arnia: 10),
      _colonia(4, arnia: 10),
    ]);
    expect(_ids(out), [5]);
  });
}

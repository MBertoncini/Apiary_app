import 'package:flutter_test/flutter_test.dart';

import 'package:apiary_app/constants/api_constants.dart';
import 'package:apiary_app/screens/trattamento/trattamento_form_screen.dart';
import 'package:apiary_app/services/api_service.dart';
import 'package:apiary_app/services/auth_token_provider.dart';

class _NoAuth implements AuthTokenProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('auth non usata nei test');
}

/// ApiService finto: risponde ai GET con le pagine registrate per URL.
class _FakeApi extends ApiService {
  _FakeApi(this.pagine) : super(_NoAuth());

  final Map<String, dynamic> pagine;
  final List<String> richieste = [];

  @override
  Future<dynamic> get(String endpoint) async {
    richieste.add(endpoint);
    final r = pagine[endpoint];
    if (r == null) throw StateError('GET inatteso: $endpoint');
    if (r is Exception) throw r;
    return r;
  }
}

List<Map<String, dynamic>> _arnie(int da, int a, int apiario) => [
      for (var i = da; i <= a; i++)
        {'id': i, 'numero': i, 'apiario': apiario},
    ];

void main() {
  const apiarioId = 7;
  const url1 = '${ApiConstants.arnieUrl}?apiario=$apiarioId';
  const url2 = '${ApiConstants.arnieUrl}?apiario=$apiarioId&page=2';
  const url3 = '${ApiConstants.arnieUrl}?apiario=$apiarioId&page=3';

  test('legge tutte le pagine seguendo next (45 arnie su 3 pagine)', () async {
    final api = _FakeApi({
      url1: {'count': 45, 'next': url2, 'previous': null,
        'results': _arnie(1, 20, apiarioId)},
      url2: {'count': 45, 'next': url3, 'previous': url1,
        'results': _arnie(21, 40, apiarioId)},
      url3: {'count': 45, 'next': null, 'previous': url2,
        'results': _arnie(41, 45, apiarioId)},
    });

    final arnie = await caricaArnieApiario(api, apiarioId);

    expect(arnie.length, 45);
    expect(arnie.map((a) => a['id']), List.generate(45, (i) => i + 1));
    expect(api.richieste, [url1, url2, url3]);
  });

  test('scarta le arnie di altri apiari se il server ignora ?apiario',
      () async {
    final api = _FakeApi({
      url1: {'count': 30, 'next': url2,
        'results': [..._arnie(1, 15, apiarioId), ..._arnie(16, 20, 99)]},
      url2: {'count': 30, 'next': null,
        'results': [..._arnie(21, 25, 99), ..._arnie(26, 30, apiarioId)]},
    });

    final arnie = await caricaArnieApiario(api, apiarioId);

    expect(arnie.length, 20);
    expect(arnie.every((a) => a['apiario'] == apiarioId), isTrue);
  });

  test('risposta non paginata (lista semplice)', () async {
    final api = _FakeApi({url1: _arnie(1, 3, apiarioId)});

    final arnie = await caricaArnieApiario(api, apiarioId);

    expect(arnie.length, 3);
    expect(api.richieste, [url1]);
  });

  test('errore su una pagina successiva: nessuna lista parziale', () async {
    final api = _FakeApi({
      url1: {'count': 25, 'next': url2, 'results': _arnie(1, 20, apiarioId)},
      url2: HttpStatusException(statusCode: 500, body: 'errore'),
    });

    expect(caricaArnieApiario(api, apiarioId),
        throwsA(isA<HttpStatusException>()));
  });
}

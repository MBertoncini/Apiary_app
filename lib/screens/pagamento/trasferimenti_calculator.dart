/// Calcola i trasferimenti necessari per saldare un gruppo a partire dai
/// bilanci dei singoli membri.
///
/// Ogni elemento di [bilancioMembri] deve contenere almeno:
/// - `utenteId` (int)
/// - `username` (String)
/// - `saldo` (double): positivo = creditore, negativo = debitore
///
/// L'output è una lista di trasferimenti `{da, daId, a, aId, importo}`
/// deterministica per qualsiasi permutazione dell'input: creditori e debitori
/// vengono ordinati per `|saldo|` decrescente, e a parità di saldo per
/// `utenteId` ascendente. L'ordinamento "largest-first" produce anche un
/// numero di transazioni vicino all'ottimo nei casi pratici.
List<Map<String, dynamic>> calcolaTrasferimenti(
  List<Map<String, dynamic>> bilancioMembri, {
  double epsilon = 0.01,
}) {
  final List<Map<String, dynamic>> creditori = [];
  final List<Map<String, dynamic>> debitori = [];

  for (final membro in bilancioMembri) {
    final double saldo = (membro['saldo'] as num).toDouble();
    if (saldo > epsilon) {
      creditori.add({...membro, 'residuo': saldo});
    } else if (saldo < -epsilon) {
      debitori.add({...membro, 'residuo': -saldo});
    }
  }

  int comparaResiduoPoiId(Map<String, dynamic> a, Map<String, dynamic> b) {
    final cmp = (b['residuo'] as double).compareTo(a['residuo'] as double);
    if (cmp != 0) return cmp;
    return (a['utenteId'] as int).compareTo(b['utenteId'] as int);
  }

  creditori.sort(comparaResiduoPoiId);
  debitori.sort(comparaResiduoPoiId);

  final List<Map<String, dynamic>> trasferimenti = [];
  int i = 0, j = 0;

  while (i < debitori.length && j < creditori.length) {
    final double residuoDeb = debitori[i]['residuo'] as double;
    final double residuoCred = creditori[j]['residuo'] as double;
    final double importo = residuoDeb < residuoCred ? residuoDeb : residuoCred;

    if (importo > epsilon) {
      trasferimenti.add({
        'da': debitori[i]['username'],
        'daId': debitori[i]['utenteId'],
        'a': creditori[j]['username'],
        'aId': creditori[j]['utenteId'],
        'importo': importo,
      });
    }

    debitori[i]['residuo'] = residuoDeb - importo;
    creditori[j]['residuo'] = residuoCred - importo;

    if ((debitori[i]['residuo'] as double) < epsilon) i++;
    if ((creditori[j]['residuo'] as double) < epsilon) j++;
  }

  return trasferimenti;
}

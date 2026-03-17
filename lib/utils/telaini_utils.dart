/// Utilità per la gestione e l'ordinamento dei telaini dell'arnia.
///
/// Regola canonica (da sinistra a destra):
///   scorte(sx) | covata(sx) | foglio_cereo | covata(dx) | scorte(dx) | nutritore | diaframma | vuoto
library telaini_utils;

/// Restituisce la lista di telaini ordinata secondo la regola canonica.
///
/// Esempio (10 telaini):
///   [scorte, scorte, covata, covata, foglio_cereo, covata, covata, scorte, diaframma, vuoto]
List<String> sortTelaini(List<String> frames) {
  final vuoti      = frames.where((f) => f == 'vuoto').toList();
  final diaframmi  = frames.where((f) => f == 'diaframma').toList();
  final fogliCerei = frames.where((f) => f == 'foglio_cereo').toList();
  final covata     = frames.where((f) => f == 'covata' || f == 'misto').toList();
  final scorte     = frames.where((f) => f == 'scorte').toList();
  final nutritori  = frames.where((f) => f == 'nutritore').toList();

  final halfC = (covata.length / 2).ceil();
  final halfS = (scorte.length / 2).ceil();

  return [
    ...scorte.sublist(0, halfS),
    ...covata.sublist(0, halfC),
    ...fogliCerei,
    ...covata.sublist(halfC),
    ...scorte.sublist(halfS),
    ...nutritori,
    ...diaframmi,
    ...vuoti,
  ];
}

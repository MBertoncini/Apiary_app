/// Utilità per la gestione e l'ordinamento dei telaini dell'arnia.
///
/// Regola canonica (da sinistra a destra):
///   scorte(sx) | covata(sx) | foglio_cereo | trappola_varroa | gabbia_regina | covata(dx) | scorte(dx) | nutritore | diaframma | vuoto
library telaini_utils;

/// Restituisce la lista di telaini ordinata secondo la regola canonica.
///
/// Esempio (10 telaini):
///   [scorte, scorte, covata, covata, foglio_cereo, covata, covata, scorte, diaframma, vuoto]
/// Normalizza una configurazione salvata a esattamente [size] slot,
/// SENZA riordinarla: la posizione scelta dall'utente (diaframmi ai lati,
/// fogli cerei dove inseriti, ecc.) è un dato e va rispettata.
/// Usare [sortTelaini] solo per configurazioni generate dai contatori
/// o su richiesta esplicita (pulsante "Auto ordina").
List<String> normalizeTelaini(List<String> frames, {int size = 10}) {
  final out = List<String>.from(frames);
  while (out.length < size) out.add('vuoto');
  return out.length > size ? out.sublist(0, size) : out;
}

List<String> sortTelaini(List<String> frames) {
  final vuoti        = frames.where((f) => f == 'vuoto').toList();
  final diaframmi    = frames.where((f) => f == 'diaframma').toList();
  final fogliCerei   = frames.where((f) => f == 'foglio_cereo').toList();
  final trappVarroa  = frames.where((f) => f == 'trappola_varroa').toList();
  final gabbieRegina = frames.where((f) => f == 'gabbia_regina').toList();
  final covata       = frames.where((f) => f == 'covata' || f == 'misto').toList();
  final scorte       = frames.where((f) => f == 'scorte').toList();
  final nutritori    = frames.where((f) => f == 'nutritore').toList();

  final halfC = (covata.length / 2).ceil();
  final halfS = (scorte.length / 2).ceil();

  return [
    ...scorte.sublist(0, halfS),
    ...covata.sublist(0, halfC),
    ...fogliCerei,
    ...trappVarroa,
    ...gabbieRegina,
    ...covata.sublist(halfC),
    ...scorte.sublist(halfS),
    ...nutritori,
    ...diaframmi,
    ...vuoti,
  ];
}

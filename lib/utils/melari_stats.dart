import '../models/melario.dart';

/// Logica pura dei contatori melari, estratta da `MelariScreen` per poter
/// essere coperta da unit test senza montare la UI.

/// Stati in cui un melario è ancora fisicamente sull'arnia.
const Set<String> kMelarioStatiAttivi = {'posizionato', 'in_smielatura'};

/// Stati in cui un melario è staccato dall'arnia e in attesa di smielatura.
const Set<String> kMelarioStatiInCoda = {'rimosso', 'in_smielatura'};

/// Id dei melari già inclusi in almeno una smielatura registrata.
///
/// Legge il campo m2m `melari` delle produzioni così come arriva dall'API
/// (`SmielaturaSerializer`) o dalla cache locale. Tollera valori non interi
/// e liste mancanti, perché la cache può contenere record scritti da versioni
/// precedenti dell'app.
Set<int> melariGiaSmielatiIds(List<Map<String, dynamic>> smielature) {
  final ids = <int>{};
  for (final s in smielature) {
    final raw = s['melari'];
    if (raw is! List) continue;
    for (final e in raw) {
      if (e is int) {
        ids.add(e);
      } else if (e is num) {
        ids.add(e.toInt());
      } else {
        final parsed = int.tryParse('$e');
        if (parsed != null) ids.add(parsed);
      }
    }
  }
  return ids;
}

/// Un melario è ancora "da smielare" se è staccato dall'arnia o in coda e non
/// risulta già consumato da una smielatura registrata.
///
/// L'incrocio con le smielature rende il contatore self-correcting: sparisce
/// appena la smielatura include il melario, senza dover attendere che il
/// backend porti lo stato a 'smielato' né che la cache locale venga
/// invalidata.
bool isMelarioDaSmielare(Melario m, Set<int> giaSmielatiIds) =>
    kMelarioStatiInCoda.contains(m.stato) && !giaSmielatiIds.contains(m.id);

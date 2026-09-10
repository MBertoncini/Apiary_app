import '../models/alimentazione.dart';

/// Aggregazioni pure sulle alimentazioni, usate dalla scheda "Analisi".
///
/// Vivono qui e non nella schermata per poter essere coperte da unit test
/// senza montare la UI.

/// Riga di un raggruppamento: chiave tecnica, etichetta leggibile, kg totali
/// e numero di somministrazioni.
class AlimentazioneGroup {
  final String key;
  final String label;
  final double kg;
  final int count;

  const AlimentazioneGroup({
    required this.key,
    required this.label,
    required this.kg,
    required this.count,
  });
}

/// Sintesi complessiva di un insieme di alimentazioni.
class AlimentazioniSummary {
  final double kgTotali;
  final int somministrazioni;
  final int colonieCoinvolte;

  /// Media dei kg per colonia coinvolta (0 se nessuna).
  final double kgPerColonia;

  /// Data della somministrazione più recente, formato ISO `yyyy-MM-dd`.
  final String? ultimaData;

  const AlimentazioniSummary({
    required this.kgTotali,
    required this.somministrazioni,
    required this.colonieCoinvolte,
    required this.kgPerColonia,
    required this.ultimaData,
  });

  static const AlimentazioniSummary empty = AlimentazioniSummary(
    kgTotali: 0,
    somministrazioni: 0,
    colonieCoinvolte: 0,
    kgPerColonia: 0,
    ultimaData: null,
  );
}

/// Anno di una data ISO `yyyy-MM-dd`; null se non interpretabile.
int? annoDi(String data) {
  if (data.length < 4) return null;
  return int.tryParse(data.substring(0, 4));
}

/// Anni presenti nel dataset, dal più recente al più vecchio.
List<int> anniDisponibili(List<Alimentazione> items) {
  final anni = <int>{};
  for (final a in items) {
    final y = annoDi(a.data);
    if (y != null) anni.add(y);
  }
  final list = anni.toList()..sort((a, b) => b.compareTo(a));
  return list;
}

/// Applica i filtri della scheda: anno (null = tutti) e tipo (null = tutti).
List<Alimentazione> filtraAlimentazioni(
  List<Alimentazione> items, {
  int? anno,
  String? tipo,
}) {
  return items.where((a) {
    if (anno != null && annoDi(a.data) != anno) return false;
    if (tipo != null && a.tipo != tipo) return false;
    return true;
  }).toList();
}

AlimentazioniSummary riepilogo(List<Alimentazione> items) {
  if (items.isEmpty) return AlimentazioniSummary.empty;
  var kg = 0.0;
  final colonie = <int>{};
  String? ultima;
  for (final a in items) {
    kg += a.quantitaKg;
    colonie.add(a.colonia);
    if (ultima == null || a.data.compareTo(ultima) > 0) ultima = a.data;
  }
  return AlimentazioniSummary(
    kgTotali: kg,
    somministrazioni: items.length,
    colonieCoinvolte: colonie.length,
    kgPerColonia: colonie.isEmpty ? 0 : kg / colonie.length,
    ultimaData: ultima,
  );
}

/// Raggruppa per una chiave arbitraria, ordinando per kg decrescenti.
///
/// [labelOf] riceve la prima alimentazione incontrata per quella chiave, così
/// si può riusare l'etichetta già tradotta dal backend (`tipo_display`,
/// `scopo_display`, `colonia_display`).
List<AlimentazioneGroup> raggruppa(
  List<Alimentazione> items,
  String Function(Alimentazione) keyOf,
  String Function(Alimentazione) labelOf,
) {
  final kg = <String, double>{};
  final count = <String, int>{};
  final label = <String, String>{};
  for (final a in items) {
    final k = keyOf(a);
    kg[k] = (kg[k] ?? 0) + a.quantitaKg;
    count[k] = (count[k] ?? 0) + 1;
    label.putIfAbsent(k, () => labelOf(a));
  }
  final groups = kg.keys
      .map((k) => AlimentazioneGroup(
            key: k,
            label: label[k] ?? k,
            kg: kg[k]!,
            count: count[k]!,
          ))
      .toList();
  groups.sort((a, b) {
    final c = b.kg.compareTo(a.kg);
    return c != 0 ? c : a.label.compareTo(b.label);
  });
  return groups;
}

/// Raggruppamento per tipo di alimento.
List<AlimentazioneGroup> perTipo(List<Alimentazione> items) =>
    raggruppa(items, (a) => a.tipo, (a) => a.tipoDisplay ?? a.tipo);

/// Raggruppamento per scopo; le righe senza scopo finiscono sotto [senzaScopo].
List<AlimentazioneGroup> perScopo(
  List<Alimentazione> items, {
  String senzaScopo = '—',
}) =>
    raggruppa(
      items,
      (a) => (a.scopo == null || a.scopo!.isEmpty) ? '' : a.scopo!,
      (a) => (a.scopoDisplay == null || a.scopoDisplay!.isEmpty)
          ? senzaScopo
          : a.scopoDisplay!,
    );

/// Raggruppamento per colonia, utile per vedere chi ha ricevuto di più.
List<AlimentazioneGroup> perColonia(List<Alimentazione> items) => raggruppa(
      items,
      (a) => '${a.colonia}',
      (a) => a.coloniaDisplay ?? 'Colonia ${a.colonia}',
    );

/// Raggruppamento per apiario. Richiede che il backend esponga
/// `apiario_nome` sull'alimentazione: se manca, restituisce lista vuota e la
/// sezione va nascosta (compatibilità con backend non ancora aggiornati).
List<AlimentazioneGroup> perApiario(List<Alimentazione> items) {
  final conApiario =
      items.where((a) => a.apiarioNome != null && a.apiarioNome!.isNotEmpty);
  if (conApiario.isEmpty) return const [];
  return raggruppa(
    conApiario.toList(),
    (a) => '${a.apiario ?? a.apiarioNome}',
    (a) => a.apiarioNome!,
  );
}

/// Formatta i kg senza zeri decimali inutili: 3 → "3", 3.5 → "3,5".
String formatKg(double v) {
  final s = v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return s.replaceAll('.', ',');
}

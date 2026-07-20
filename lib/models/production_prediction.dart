/// Stima di produzione miele per-colonia (regressione).
///
/// Mappa `predictions.honey_production` di `GET /api/v1/ml/predict/colonia/<id>/`.
/// Diversa dai modelli di rischio: porta kg attesi + intervallo, non un livello.
/// Il testo arriva già in italiano dal backend.
class ProductionDriver {
  final String label; // pianta/fioritura
  final double kg; // contributo stimato in kg

  const ProductionDriver({required this.label, required this.kg});

  factory ProductionDriver.fromJson(Map<String, dynamic> j) => ProductionDriver(
        label: (j['label'] ?? '').toString(),
        kg: (j['kg'] as num?)?.toDouble() ?? 0,
      );
}

class ProductionPrediction {
  final int? year;
  final double? expectedKg; // null se non stimabile (nessuna fioritura)
  final double? kgLow;
  final double? kgHigh;
  final double? nectarPotential;
  final double? lastSeasonKg;
  final double? feedingKg;
  final String confidence; // nessuna | bassa | media | alta
  final bool lowData;
  final List<ProductionDriver> drivers;
  final String summary;
  final List<String> notes;
  final String basis;
  final String model;

  const ProductionPrediction({
    required this.year,
    required this.expectedKg,
    required this.kgLow,
    required this.kgHigh,
    required this.nectarPotential,
    required this.lastSeasonKg,
    required this.feedingKg,
    required this.confidence,
    required this.lowData,
    required this.drivers,
    required this.summary,
    required this.notes,
    required this.basis,
    required this.model,
  });

  bool get hasData => expectedKg != null;

  static ProductionPrediction? fromResponse(dynamic res) {
    if (res is! Map) return null;
    final preds = res['predictions'];
    if (preds is! Map) return null;
    final p = preds['honey_production'];
    if (p is! Map) return null;
    final j = p.cast<String, dynamic>();

    return ProductionPrediction(
      year: (j['year'] as num?)?.toInt(),
      expectedKg: (j['expected_kg'] as num?)?.toDouble(),
      kgLow: (j['kg_low'] as num?)?.toDouble(),
      kgHigh: (j['kg_high'] as num?)?.toDouble(),
      nectarPotential: (j['nectar_potential'] as num?)?.toDouble(),
      lastSeasonKg: (j['last_season_kg'] as num?)?.toDouble(),
      feedingKg: (j['feeding_kg'] as num?)?.toDouble(),
      confidence: (j['confidence'] ?? 'nessuna').toString(),
      lowData: j['low_data'] == true,
      drivers: (j['factors'] as List? ?? [])
          .whereType<Map>()
          .map((f) => ProductionDriver.fromJson(f.cast<String, dynamic>()))
          .toList(),
      summary: (j['summary'] ?? '').toString(),
      notes: (j['notes'] as List? ?? []).map((n) => n.toString()).toList(),
      basis: (j['basis'] ?? '').toString(),
      model: (j['model'] ?? '').toString(),
    );
  }
}

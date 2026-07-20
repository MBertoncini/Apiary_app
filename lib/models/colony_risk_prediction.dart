/// Predizioni di rischio per-colonia (modello generico, riusabile per più target).
///
/// Mappa la risposta di `GET /api/v1/ml/predict/colonia/<id>/`, campo
/// `predictions`, che contiene una voce per target (es. `swarm_risk`,
/// `wintering_risk`). I target a livello di rischio condividono la stessa forma
/// (score/livello/fattori/confidenza); la produzione miele (regressione) avrà
/// un modello a parte.
///
/// Il testo (summary, fattori, note) arriva già in italiano dal backend.
class RiskFactor {
  final String label;
  final int impact; // >0 aumenta il rischio, <0 lo riduce

  const RiskFactor({required this.label, required this.impact});

  factory RiskFactor.fromJson(Map<String, dynamic> j) => RiskFactor(
        label: (j['label'] ?? '').toString(),
        impact: (j['impact'] as num?)?.round() ?? 0,
      );
}

class ColonyRiskPrediction {
  final String kind; // swarm_risk | wintering_risk
  final String title; // titolo UI (italiano)
  final int? score; // 0-100, null se dati insufficienti
  final String? level; // basso | medio | alto | critico
  final double? probability; // popolato quando ci sarà lo strato statistico
  final String confidence; // nessuna | bassa | media | alta
  final bool lowData;
  final List<RiskFactor> factors;
  final String summary;
  final List<String> notes;
  final String model;

  const ColonyRiskPrediction({
    required this.kind,
    required this.title,
    required this.score,
    required this.level,
    required this.probability,
    required this.confidence,
    required this.lowData,
    required this.factors,
    required this.summary,
    required this.notes,
    required this.model,
  });

  bool get hasData => score != null && level != null;

  static const Map<String, String> _titles = {
    'swarm_risk': 'Rischio sciamatura',
    'wintering_risk': 'Rischio invernamento',
  };

  factory ColonyRiskPrediction.fromJson(String kind, Map<String, dynamic> j) {
    return ColonyRiskPrediction(
      kind: kind,
      title: _titles[kind] ?? kind,
      score: (j['score'] as num?)?.round(),
      level: j['level'] as String?,
      probability: (j['probability'] as num?)?.toDouble(),
      confidence: (j['confidence'] ?? 'nessuna').toString(),
      lowData: j['low_data'] == true,
      factors: (j['factors'] as List? ?? [])
          .whereType<Map>()
          .map((f) => RiskFactor.fromJson(f.cast<String, dynamic>()))
          .toList(),
      summary: (j['summary'] ?? '').toString(),
      notes: (j['notes'] as List? ?? []).map((n) => n.toString()).toList(),
      model: (j['model'] ?? '').toString(),
    );
  }
}

class ColonyPredictions {
  final String? asOf;
  final int? nControls;
  final List<ColonyRiskPrediction> risks;

  const ColonyPredictions({
    required this.asOf,
    required this.nControls,
    required this.risks,
  });

  // Ordine di visualizzazione delle card di rischio.
  static const List<String> _order = ['swarm_risk', 'wintering_risk'];

  static ColonyPredictions? fromResponse(dynamic res) {
    if (res is! Map) return null;
    final preds = res['predictions'];
    if (preds is! Map) return null;

    final risks = <ColonyRiskPrediction>[];
    for (final kind in _order) {
      final p = preds[kind];
      if (p is Map) {
        risks.add(ColonyRiskPrediction.fromJson(kind, p.cast<String, dynamic>()));
      }
    }
    return ColonyPredictions(
      asOf: res['as_of'] as String?,
      nControls: (res['n_controls'] as num?)?.toInt(),
      risks: risks,
    );
  }
}

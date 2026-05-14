/// Aggregato meteo giornaliero per apiario (dataset ML).
///
/// Mirror del modello backend `MeteoGiornaliero`. Una riga per (apiario, data).
class MeteoGiornaliero {
  final int id;
  final int apiario;
  final DateTime data;

  // Temperatura (°C)
  final double? tempMin;
  final double? tempMax;
  final double? tempMean;

  // Precipitazioni
  final double? precipMm;
  final double? precipHours;

  // Umidità / Vento / Pressione
  final double? umiditaMedia;
  final double? ventoMedio;
  final double? ventoRafficaMax;
  final double? pressioneMedia;

  // Sole / Radiazione / GDD
  final double? oreSole;
  final double? radiazioneMj;
  final double? gddBase10;

  // Meta
  final int? weatherCodeDominante;
  final String source; // 'archive' | 'forecast'
  final DateTime? updatedAt;

  MeteoGiornaliero({
    required this.id,
    required this.apiario,
    required this.data,
    this.tempMin,
    this.tempMax,
    this.tempMean,
    this.precipMm,
    this.precipHours,
    this.umiditaMedia,
    this.ventoMedio,
    this.ventoRafficaMax,
    this.pressioneMedia,
    this.oreSole,
    this.radiazioneMj,
    this.gddBase10,
    this.weatherCodeDominante,
    required this.source,
    this.updatedAt,
  });

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory MeteoGiornaliero.fromJson(Map<String, dynamic> json) {
    return MeteoGiornaliero(
      id: json['id'] as int,
      apiario: json['apiario'] as int,
      data: DateTime.parse(json['data'] as String),
      tempMin: _asDouble(json['temp_min']),
      tempMax: _asDouble(json['temp_max']),
      tempMean: _asDouble(json['temp_mean']),
      precipMm: _asDouble(json['precip_mm']),
      precipHours: _asDouble(json['precip_hours']),
      umiditaMedia: _asDouble(json['umidita_media']),
      ventoMedio: _asDouble(json['vento_medio']),
      ventoRafficaMax: _asDouble(json['vento_raffica_max']),
      pressioneMedia: _asDouble(json['pressione_media']),
      oreSole: _asDouble(json['ore_sole']),
      radiazioneMj: _asDouble(json['radiazione_mj']),
      gddBase10: _asDouble(json['gdd_base10']),
      weatherCodeDominante: _asInt(json['weather_code_dominante']),
      source: (json['source'] as String?) ?? 'archive',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}

/// Aggregati statistici sul range richiesto (endpoint `/meteo-giornaliero/stats/`).
class MeteoStats {
  final DateTime start;
  final DateTime end;
  final int giorni;
  final double? tempMin;
  final double? tempMax;
  final double? tempMedia;
  final double? precipTotale;
  final double? precipHoursTotale;
  final double? umiditaMedia;
  final double? ventoMedio;
  final double? oreSoleTotale;
  final double? radiazioneTotale;
  final double? gddCumulato;

  MeteoStats({
    required this.start,
    required this.end,
    required this.giorni,
    this.tempMin,
    this.tempMax,
    this.tempMedia,
    this.precipTotale,
    this.precipHoursTotale,
    this.umiditaMedia,
    this.ventoMedio,
    this.oreSoleTotale,
    this.radiazioneTotale,
    this.gddCumulato,
  });

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory MeteoStats.fromJson(Map<String, dynamic> json) {
    return MeteoStats(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      giorni: (json['giorni'] as num?)?.toInt() ?? 0,
      tempMin: _asDouble(json['temp_min']),
      tempMax: _asDouble(json['temp_max']),
      tempMedia: _asDouble(json['temp_media']),
      precipTotale: _asDouble(json['precip_totale']),
      precipHoursTotale: _asDouble(json['precip_hours_totale']),
      umiditaMedia: _asDouble(json['umidita_media']),
      ventoMedio: _asDouble(json['vento_medio']),
      oreSoleTotale: _asDouble(json['ore_sole_totale']),
      radiazioneTotale: _asDouble(json['radiazione_totale']),
      gddCumulato: _asDouble(json['gdd_cumulato']),
    );
  }
}

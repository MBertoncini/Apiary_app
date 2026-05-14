import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/theme_constants.dart';
import '../l10n/app_strings.dart';
import '../models/meteo_giornaliero.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../services/meteo_storico_service.dart';

/// Vista storica meteo per un apiario. Mostra:
/// * selettore range (30 / 90 / 365 giorni)
/// * card con KPI aggregati (T media, precip totale, GDD cumulato)
/// * grafici T min/max, precipitazioni giornaliere, GDD cumulato.
///
/// Si appoggia agli endpoint REST `/api/v1/apiari/{id}/meteo-giornaliero/`
/// e `/meteo-giornaliero/stats/`.
class MeteoStoricoWidget extends StatefulWidget {
  final int apiarioId;

  const MeteoStoricoWidget({Key? key, required this.apiarioId})
      : super(key: key);

  @override
  State<MeteoStoricoWidget> createState() => _MeteoStoricoWidgetState();
}

class _MeteoStoricoWidgetState extends State<MeteoStoricoWidget> {
  int _rangeDays = 90;
  bool _loading = true;
  String? _error;
  List<MeteoGiornaliero> _rows = const [];
  MeteoStats? _stats;

  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final service = MeteoStoricoService(api);
      final end = DateTime.now().subtract(const Duration(days: 1));
      final start = end.subtract(Duration(days: _rangeDays - 1));
      final results = await Future.wait([
        service.getMeteoGiornaliero(widget.apiarioId, start: start, end: end),
        service.getStats(widget.apiarioId, start: start, end: end),
      ]);
      if (!mounted) return;
      setState(() {
        _rows = results[0] as List<MeteoGiornaliero>;
        _stats = results[1] as MeteoStats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _setRange(int days) {
    if (_rangeDays == days) return;
    setState(() => _rangeDays = days);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _rangeSelector(),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _errorBox()
          else if (_rows.isEmpty)
            _emptyBox()
          else ...[
            _statsCard(),
            const SizedBox(height: 16),
            _chartCard(_s.meteoStoricoChartTemperatura, _temperatureChart()),
            const SizedBox(height: 16),
            _chartCard(_s.meteoStoricoChartPrecipitazioni, _precipChart()),
            const SizedBox(height: 16),
            _chartCard(_s.meteoStoricoChartGdd, _gddChart(),
                infoText: _s.meteoStoricoGddInfo),
          ],
        ],
      ),
    );
  }

  Widget _rangeSelector() {
    final options = [
      (30, _s.meteoStoricoRange30),
      (90, _s.meteoStoricoRange90),
      (365, _s.meteoStoricoRange365),
    ];
    return Wrap(
      spacing: 8,
      children: [
        for (final opt in options)
          ChoiceChip(
            label: Text(opt.$2),
            selected: _rangeDays == opt.$1,
            onSelected: (_) => _setRange(opt.$1),
          ),
      ],
    );
  }

  Widget _errorBox() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_s.meteoStoricoError,
                style: const TextStyle(
                    color: ThemeConstants.textSecondaryColor)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(_s.btnRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyBox() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_s.meteoStoricoEmpty,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: ThemeConstants.textSecondaryColor)),
      ),
    );
  }

  Widget _statsCard() {
    final s = _stats;
    if (s == null) return const SizedBox.shrink();
    String fmt(double? v, {int decimals = 1, String suffix = ''}) {
      if (v == null) return '—';
      return '${v.toStringAsFixed(decimals)}$suffix';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _kpi('${s.giorni}', _s.meteoStoricoStatsGiorni,
                Icons.calendar_today, Colors.blueGrey),
            _kpi(fmt(s.tempMedia, suffix: '°'),
                _s.meteoStoricoStatsTempMedia, Icons.thermostat, Colors.orange),
            _kpi(fmt(s.precipTotale, suffix: ' mm'),
                _s.meteoStoricoStatsPrecipTotale, Icons.umbrella,
                Colors.indigo),
            _kpi(fmt(s.gddCumulato, decimals: 0),
                _s.meteoStoricoStatsGddCumulato, Icons.eco, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _kpi(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: ThemeConstants.textSecondaryColor)),
      ],
    );
  }

  Widget _chartCard(String title, Widget chart, {String? infoText}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(title, style: ThemeConstants.subheadingStyle)),
                if (infoText != null)
                  GestureDetector(
                    onTap: () => _showInfoDialog(title, infoText),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.info_outline,
                          size: 18, color: Colors.blueGrey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Grafici
  // ────────────────────────────────────────────────────────────────────

  double _x(MeteoGiornaliero r) =>
      r.data.difference(_rows.first.data).inDays.toDouble();

  Widget _temperatureChart() {
    final minSpots = <FlSpot>[];
    final maxSpots = <FlSpot>[];
    for (final r in _rows) {
      if (r.tempMin != null) minSpots.add(FlSpot(_x(r), r.tempMin!));
      if (r.tempMax != null) maxSpots.add(FlSpot(_x(r), r.tempMax!));
    }
    if (minSpots.isEmpty && maxSpots.isEmpty) {
      return Center(child: Text(_s.meteoStoricoEmpty));
    }
    final allValues = [...minSpots, ...maxSpots].map((s) => s.y);
    final minY = allValues.reduce((a, b) => a < b ? a : b) - 2;
    final maxY = allValues.reduce((a, b) => a > b ? a : b) + 2;
    return Column(
      children: [
        Expanded(
          child: LineChart(LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: _datesTitlesData(),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: minSpots,
                isCurved: true,
                barWidth: 2,
                color: Colors.blue,
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: maxSpots,
                isCurved: true,
                barWidth: 2,
                color: Colors.red,
                dotData: const FlDotData(show: false),
              ),
            ],
          )),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(Colors.blue, _s.meteoStoricoTempMin),
            const SizedBox(width: 16),
            _legend(Colors.red, _s.meteoStoricoTempMax),
          ],
        ),
      ],
    );
  }

  Widget _precipChart() {
    final bars = <BarChartGroupData>[];
    double maxVal = 0;
    for (int i = 0; i < _rows.length; i++) {
      final v = _rows[i].precipMm ?? 0;
      if (v > maxVal) maxVal = v;
      bars.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: v,
          color: Colors.indigo,
          width: _rangeDays > 60 ? 1 : 4,
        ),
      ]));
    }
    return BarChart(BarChartData(
      maxY: (maxVal == 0 ? 1 : maxVal * 1.2),
      barGroups: bars,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: _datesTitlesData(),
      borderData: FlBorderData(show: false),
    ));
  }

  Widget _gddChart() {
    final spots = <FlSpot>[];
    double cum = 0;
    for (int i = 0; i < _rows.length; i++) {
      cum += _rows[i].gddBase10 ?? 0;
      spots.add(FlSpot(i.toDouble(), cum));
    }
    if (spots.isEmpty) return Center(child: Text(_s.meteoStoricoEmpty));
    return LineChart(LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: _datesTitlesData(),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 2,
          color: Colors.green,
          belowBarData: BarAreaData(
              show: true, color: Colors.green.withOpacity(0.15)),
          dotData: const FlDotData(show: false),
        ),
      ],
    ));
  }

  FlTitlesData _datesTitlesData() {
    final count = _rows.length;
    if (count == 0) return const FlTitlesData(show: false);

    // Adatta formato, intervallo e rotazione in base al range selezionato.
    final DateFormat df;
    final int labelInterval;
    final bool rotate;
    if (count >= 200) {
      // ~365 giorni: un'etichetta per mese, formato corto, ruotata
      df = DateFormat('MMM yy');
      labelInterval = 30;
      rotate = true;
    } else if (count >= 60) {
      // ~90 giorni: ogni ~2 settimane
      df = DateFormat('dd/MM');
      labelInterval = 15;
      rotate = false;
    } else {
      // ~30 giorni: ogni settimana
      df = DateFormat('dd/MM');
      labelInterval = 7;
      rotate = false;
    }

    return FlTitlesData(
      leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
      rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          // reservedSize maggiore se le etichette sono ruotate
          reservedSize: rotate ? 40 : 22,
          // interval=1 + filtro manuale = comportamento corretto sia su
          // LineChart che su BarChart (fl_chart gestisce i due in modo diverso)
          interval: 1,
          getTitlesWidget: (value, meta) {
            final idx = value.toInt();
            if (idx < 0 || idx >= _rows.length) return const SizedBox.shrink();
            if (idx % labelInterval != 0) return const SizedBox.shrink();
            final label = Text(
              df.format(_rows[idx].data),
              style: const TextStyle(fontSize: 10),
            );
            if (rotate) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Transform.rotate(
                  angle: -0.785, // -45°
                  child: label,
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: label,
            );
          },
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10, color: color),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11)),
    ]);
  }
}

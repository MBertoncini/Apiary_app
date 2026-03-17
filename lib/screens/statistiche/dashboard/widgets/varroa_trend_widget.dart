import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../services/statistiche_service.dart';
import 'dashboard_card_base.dart';

class VarroaTrendWidget extends StatefulWidget {
  final StatisticheService service;
  const VarroaTrendWidget({super.key, required this.service});

  @override
  State<VarroaTrendWidget> createState() => _VarroaTrendWidgetState();
}

class _VarroaTrendWidgetState extends State<VarroaTrendWidget> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.service.getVarroaTrend(forceRefresh: forceRefresh);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCardBase(
      icon: const Icon(Icons.bug_report, color: Color(0xFFD4A017)),
      title: 'Trattamenti Sanitari nel Tempo',
      loading: _loading,
      error: _error,
      onRetry: () => _load(forceRefresh: true),
      child: _data != null ? _buildChart() : const SizedBox.shrink(),
    );
  }

  Widget _buildChart() {
    final mesi = List<String>.from(_data!['mesi'] ?? []);
    final serie = _data!['serie'] as List;

    if (mesi.isEmpty || serie.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Nessun trattamento nel periodo')));
    }

    final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple];
    final linee = serie.asMap().entries.map((entry) {
      final s = entry.value;
      final valori = List<double>.from((s['valori'] as List).map((v) => (v as num).toDouble()));
      return LineChartBarData(
        spots: valori.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
        isCurved: true,
        color: colors[entry.key % colors.length],
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              lineBarsData: linee,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  interval: (mesi.length / 4).ceilToDouble(),
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= mesi.length) return const SizedBox();
                    return Text(mesi[idx].substring(5), style: const TextStyle(fontSize: 10));
                  },
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        // Legenda
        Wrap(
          spacing: 12,
          children: serie.asMap().entries.map((entry) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 12, height: 3, color: colors[entry.key % colors.length]),
              const SizedBox(width: 4),
              Text(entry.value['apiario_nome'] ?? '', style: const TextStyle(fontSize: 11)),
            ],
          )).toList(),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../services/statistiche_service.dart';
import '../../../../services/language_service.dart';
import '../../../../l10n/app_strings.dart';
import 'dashboard_card_base.dart';

class AndamentoScorteWidget extends StatefulWidget {
  final StatisticheService service;
  const AndamentoScorteWidget({super.key, required this.service});

  @override
  State<AndamentoScorteWidget> createState() => _AndamentoScorteWidgetState();
}

class _AndamentoScorteWidgetState extends State<AndamentoScorteWidget> {
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
      final data = await widget.service.getAndamentoScorte(forceRefresh: forceRefresh);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  static const _colors = [Color(0xFFD4A017), Colors.blue, Colors.green, Colors.red, Colors.purple];

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  Widget build(BuildContext context) {
    return DashboardCardBase(
      icon: const Icon(Icons.trending_up, color: Color(0xFFD4A017)),
      title: _s.dashboardTitleAndamentoScorte,
      loading: _loading,
      error: _error,
      onRetry: () => _load(forceRefresh: true),
      loadingHeight: 210,
      child: _data != null ? _buildChart() : const SizedBox.shrink(),
    );
  }

  Widget _buildChart() {
    final arnie = _data!['arnie'] as List;
    if (arnie.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_s.dashboardScorteNessuno)));
    }

    final lines = arnie.take(5).toList().asMap().entries.map((entry) {
      final a = entry.value;
      final dati = a['dati'] as List;
      return LineChartBarData(
        spots: dati.asMap().entries.map((e) => FlSpot(e.key.toDouble(), ((e.value['valore'] as num?) ?? 0).toDouble())).toList(),
        isCurved: true,
        color: _colors[entry.key % _colors.length],
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();

    return Column(
      children: [
        IgnorePointer(
          child: SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              lineTouchData: const LineTouchData(enabled: false, handleBuiltInTouches: false),
              lineBarsData: lines,
              titlesData: FlTitlesData(
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)),
                )),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 10,
          children: arnie.take(5).toList().asMap().entries.map((entry) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 3, color: _colors[entry.key % _colors.length]),
              const SizedBox(width: 4),
              Text('Arnia #${entry.value['numero']}', style: const TextStyle(fontSize: 11)),
            ],
          )).toList(),
        ),
      ],
    );
  }
}

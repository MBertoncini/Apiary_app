import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../services/statistiche_service.dart';
import '../../../../services/language_service.dart';
import '../../../../l10n/app_strings.dart';
import 'dashboard_card_base.dart';

class ProduzioneAnnualeWidget extends StatefulWidget {
  final StatisticheService service;
  const ProduzioneAnnualeWidget({super.key, required this.service});

  @override
  State<ProduzioneAnnualeWidget> createState() => _ProduzioneAnnualeWidgetState();
}

class _ProduzioneAnnualeWidgetState extends State<ProduzioneAnnualeWidget> {
  static const List<int> _anniOptions = [3, 5, 10];

  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  int _anni = 3;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.service.getProduzioneAnnuale(anni: _anni, forceRefresh: forceRefresh);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCardBase(
      icon: const Icon(Icons.water_drop, color: Color(0xFFD4A017)),
      title: _s.dashboardTitleProduzione,
      loading: _loading,
      error: _error,
      onRetry: () => _load(forceRefresh: true),
      loadingHeight: 200,
      headerTrailing: DropdownButton<int>(
        value: _anni,
        isDense: true,
        underline: const SizedBox.shrink(),
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        items: _anniOptions
            .map((n) => DropdownMenuItem<int>(value: n, child: Text('$n')))
            .toList(),
        onChanged: (v) {
          if (v == null || v == _anni) return;
          setState(() => _anni = v);
          _load(forceRefresh: true);
        },
      ),
      child: _data != null ? _buildChart() : const SizedBox.shrink(),
    );
  }

  Widget _buildChart() {
    final anni = List<String>.from(_data?['anni'] ?? const []);
    final kgRaw = (_data?['kg'] as List?) ?? const [];
    final kgList = kgRaw.map((v) => (v is num ? v.toDouble() : 0.0)).toList();

    if (anni.isEmpty || kgList.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_s.dashboardProdTipoNessuno)));
    }

    final maxY = kgList.reduce((a, b) => a > b ? a : b) * 1.2;

    return IgnorePointer(
      child: SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(enabled: false),
          maxY: maxY > 0 ? maxY : 10,
          barGroups: List.generate(anni.length, (i) => BarChartGroupData(
            x: i,
            barRods: [BarChartRodData(
              toY: kgList[i],
              color: const Color(0xFFD4A017),
              width: 28,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            )],
          )),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(anni[v.toInt()], style: const TextStyle(fontSize: 11)),
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toInt()} kg', style: const TextStyle(fontSize: 10)))),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
        ),
      ),
      ),
    );
  }
}

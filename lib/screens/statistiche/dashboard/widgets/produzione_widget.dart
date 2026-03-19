import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../services/statistiche_service.dart';
import 'dashboard_card_base.dart';

class ProduzioneAnnualeWidget extends StatefulWidget {
  final StatisticheService service;
  const ProduzioneAnnualeWidget({super.key, required this.service});

  @override
  State<ProduzioneAnnualeWidget> createState() => _ProduzioneAnnualeWidgetState();
}

class _ProduzioneAnnualeWidgetState extends State<ProduzioneAnnualeWidget> {
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
      final data = await widget.service.getProduzioneAnnuale(forceRefresh: forceRefresh);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCardBase(
      icon: const Icon(Icons.water_drop, color: Color(0xFFD4A017)),
      title: 'Produzione Miele per Anno',
      loading: _loading,
      error: _error,
      onRetry: () => _load(forceRefresh: true),
      loadingHeight: 200,
      child: _data != null ? _buildChart() : const SizedBox.shrink(),
    );
  }

  Widget _buildChart() {
    final anni = List<String>.from(_data!['anni'] ?? []);
    final kgList = List<double>.from((_data!['kg'] as List).map((v) => (v as num).toDouble()));

    if (anni.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Nessuna smielatura registrata')));
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

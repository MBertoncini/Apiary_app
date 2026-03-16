import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../services/statistiche_service.dart';

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

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.service.getProduzioneAnnuale();
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop, color: Color(0xFFD4A017)),
                const SizedBox(width: 8),
                const Text('Produzione Miele per Anno', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: _load),
              ],
            ),
            const Divider(),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_error != null)
              _buildError()
            else if (_data != null)
              _buildChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Column(children: [
      const Icon(Icons.error_outline, color: Colors.red),
      TextButton(onPressed: _load, child: const Text('Riprova')),
    ]),
  );

  Widget _buildChart() {
    final anni = List<String>.from(_data!['anni'] ?? []);
    final kgList = List<double>.from((_data!['kg'] as List).map((v) => (v as num).toDouble()));

    if (anni.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Nessuna smielatura registrata')));
    }

    final maxY = kgList.reduce((a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
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
    );
  }
}

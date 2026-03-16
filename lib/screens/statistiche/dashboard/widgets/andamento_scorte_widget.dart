import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../services/statistiche_service.dart';

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

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.service.getAndamentoScorte();
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  static const _colors = [Color(0xFFD4A017), Colors.blue, Colors.green, Colors.red, Colors.purple];

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
                const Icon(Icons.trending_up, color: Color(0xFFD4A017)),
                const SizedBox(width: 8),
                const Text('Andamento Scorte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: _load),
              ],
            ),
            const Divider(),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_error != null)
              Center(child: Column(children: [const Icon(Icons.error_outline, color: Colors.red), TextButton(onPressed: _load, child: const Text('Riprova'))]))
            else if (_data != null)
              _buildChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final arnie = _data!['arnie'] as List;
    if (arnie.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Nessun dato scorte disponibile')));
    }

    final lines = arnie.take(5).toList().asMap().entries.map((entry) {
      final a = entry.value;
      final dati = a['dati'] as List;
      return LineChartBarData(
        spots: dati.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['valore'] as num).toDouble())).toList(),
        isCurved: true,
        color: _colors[entry.key % _colors.length],
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

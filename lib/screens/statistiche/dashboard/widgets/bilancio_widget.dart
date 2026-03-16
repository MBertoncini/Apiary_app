import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../services/statistiche_service.dart';

class BilancioWidget extends StatefulWidget {
  final StatisticheService service;
  const BilancioWidget({super.key, required this.service});

  @override
  State<BilancioWidget> createState() => _BilancioWidgetState();
}

class _BilancioWidgetState extends State<BilancioWidget> {
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
      final data = await widget.service.getBilancioEconomico();
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
                const Icon(Icons.euro, color: Color(0xFFD4A017)),
                const SizedBox(width: 8),
                Text('Bilancio ${_data?['anno'] ?? DateTime.now().year}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final entrate = List<double>.from((_data!['entrate'] as List).map((v) => (v as num).toDouble()));
    final uscite = List<double>.from((_data!['uscite'] as List).map((v) => (v as num).toDouble()));
    final mesi = List<String>.from(_data!['mesi'] ?? []);
    final saldo = (_data!['saldo_totale'] as num).toDouble();

    final maxY = [...entrate, ...uscite].fold(0.0, (max, v) => v > max ? v : max) * 1.2;

    return Column(
      children: [
        // Saldo totale KPI
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: saldo >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Saldo annuale: ', style: const TextStyle(fontSize: 14)),
              Text('€ ${saldo.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: saldo >= 0 ? Colors.green : Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY > 0 ? maxY : 10,
              barGroups: List.generate(12, (i) => BarChartGroupData(
                x: i,
                barsSpace: 2,
                barRods: [
                  BarChartRodData(toY: entrate[i], color: Colors.green.withOpacity(0.8), width: 6, borderRadius: const BorderRadius.vertical(top: Radius.circular(2))),
                  BarChartRodData(toY: uscite[i], color: Colors.red.withOpacity(0.8), width: 6, borderRadius: const BorderRadius.vertical(top: Radius.circular(2))),
                ],
              )),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Text(mesi[v.toInt()], style: const TextStyle(fontSize: 9)),
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text('€${v.toInt()}', style: const TextStyle(fontSize: 9)))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(Colors.green, 'Entrate'),
            const SizedBox(width: 16),
            _legendItem(Colors.red, 'Uscite'),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}

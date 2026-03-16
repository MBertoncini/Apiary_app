import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../services/statistiche_service.dart';

class SaluteArnieWidget extends StatefulWidget {
  final StatisticheService service;
  const SaluteArnieWidget({super.key, required this.service});

  @override
  State<SaluteArnieWidget> createState() => _SaluteArnieWidgetState();
}

class _SaluteArnieWidgetState extends State<SaluteArnieWidget> {
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
      final data = await widget.service.getSaluteArnie();
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
                const Icon(Icons.hive, color: Color(0xFFD4A017)),
                const SizedBox(width: 8),
                const Text('Salute degli Alveari', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: _load),
              ],
            ),
            const Divider(),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_error != null)
              _ErrorWidget(error: _error!, onRetry: _load)
            else if (_data != null)
              _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final ottima = (_data!['ottima'] as num).toInt();
    final attenzione = (_data!['attenzione'] as num).toInt();
    final critica = (_data!['critica'] as num).toInt();
    final totale = (_data!['totale'] as num).toInt();

    if (totale == 0) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Nessuna arnia trovata')));
    }

    return Row(
      children: [
        SizedBox(
          height: 160,
          width: 160,
          child: PieChart(
            PieChartData(
              sections: [
                if (ottima > 0) PieChartSectionData(value: ottima.toDouble(), color: Colors.green, title: '$ottima', radius: 55, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                if (attenzione > 0) PieChartSectionData(value: attenzione.toDouble(), color: Colors.orange, title: '$attenzione', radius: 55, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                if (critica > 0) PieChartSectionData(value: critica.toDouble(), color: Colors.red, title: '$critica', radius: 55, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(color: Colors.green, label: 'Ottima', valore: ottima),
              _LegendItem(color: Colors.orange, label: 'Attenzione', valore: attenzione),
              _LegendItem(color: Colors.red, label: 'Critica', valore: critica),
              const Divider(),
              Text('Totale: $totale arnie', style: const TextStyle(fontWeight: FontWeight.w600)),
              if ((_data!['arnie_critiche'] as List).isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Critiche: ${(_data!['arnie_critiche'] as List).map((a) => 'Arnia #${a['numero']}').join(', ')}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int valore;
  const _LegendItem({required this.color, required this.label, required this.valore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label),
          const Spacer(),
          Text('$valore', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(height: 8),
          Text('Errore caricamento dati', style: TextStyle(color: Colors.red[700])),
          TextButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    );
  }
}

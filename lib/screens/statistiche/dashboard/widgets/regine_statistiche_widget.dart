import 'package:flutter/material.dart';
import '../../../../services/statistiche_service.dart';

class RegineStatisticheWidget extends StatefulWidget {
  final StatisticheService service;
  const RegineStatisticheWidget({super.key, required this.service});

  @override
  State<RegineStatisticheWidget> createState() => _RegineStatisticheWidgetState();
}

class _RegineStatisticheWidgetState extends State<RegineStatisticheWidget> {
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
      final data = await widget.service.getRegineStatistiche();
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
                const Icon(Icons.local_florist, color: Color(0xFFD4A017)),
                const SizedBox(width: 8),
                const Text('Regine — Statistiche', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    final totale = _data!['sostituzioni_totali'] ?? 0;
    final attive = _data!['regine_attive'] ?? 0;
    final durata = _data!['durata_media_mesi'];
    final perMotivo = _data!['per_motivo'] as List;

    return Column(
      children: [
        Row(
          children: [
            _KpiCard(label: 'Regine attive', valore: '$attive', color: Colors.green),
            const SizedBox(width: 8),
            _KpiCard(label: 'Sostituzioni', valore: '$totale', color: Colors.orange),
            const SizedBox(width: 8),
            _KpiCard(label: 'Vita media', valore: durata != null ? '${durata} mesi' : 'N/D', color: Colors.blue),
          ],
        ),
        if (perMotivo.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Align(alignment: Alignment.centerLeft, child: Text('Motivi sostituzione:', style: TextStyle(fontWeight: FontWeight.w600))),
          ...perMotivo.take(5).map((m) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Text(m['motivo'] ?? 'N/D', style: const TextStyle(fontSize: 13)),
              const Spacer(),
              Text('${m['count']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          )),
        ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String valore;
  final Color color;
  const _KpiCard({required this.label, required this.valore, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(valore, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

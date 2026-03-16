import 'package:flutter/material.dart';
import '../../../../services/statistiche_service.dart';

class PerformanceRegineWidget extends StatefulWidget {
  final StatisticheService service;
  const PerformanceRegineWidget({super.key, required this.service});

  @override
  State<PerformanceRegineWidget> createState() => _PerformanceRegineWidgetState();
}

class _PerformanceRegineWidgetState extends State<PerformanceRegineWidget> {
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
      final data = await widget.service.getPerformanceRegine();
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
                const Icon(Icons.star, color: Color(0xFFD4A017)),
                const SizedBox(width: 8),
                const Text('Performance Regine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    final regine = _data!['regine'] as List;
    if (regine.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Nessuna regina con valutazione')));
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF1A1A2E)),
          children: ['Regina', 'Prod.', 'Doc.', 'Resist.', 'Sc.']
              .map((h) => Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                  ))
              .toList(),
        ),
        ...regine.asMap().entries.map((entry) {
          final r = entry.value;
          return TableRow(
            decoration: BoxDecoration(color: entry.key % 2 == 0 ? Colors.white : const Color(0xFFF5F0E8)),
            children: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(r['codice'] ?? 'N/D', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
              ),
              _scoreCell(r['produttivita']),
              _scoreCell(r['docilita']),
              _scoreCell(r['resistenza_malattie']),
              _scoreCell(r['tendenza_sciamatura']),
            ],
          );
        }),
      ],
    );
  }

  Widget _scoreCell(dynamic val) {
    final v = val as int?;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        v != null ? '$v/5' : '-',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: v == null ? Colors.grey : (v >= 4 ? Colors.green : v >= 3 ? Colors.orange : Colors.red),
        ),
      ),
    );
  }
}

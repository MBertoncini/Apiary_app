import 'package:flutter/material.dart';
import '../../../../services/statistiche_service.dart';

class QuoteGruppoWidget extends StatefulWidget {
  final StatisticheService service;
  const QuoteGruppoWidget({super.key, required this.service});

  @override
  State<QuoteGruppoWidget> createState() => _QuoteGruppoWidgetState();
}

class _QuoteGruppoWidgetState extends State<QuoteGruppoWidget> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  bool _notCoordinator = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _notCoordinator = false; });
    try {
      final data = await widget.service.getQuoteGruppo();
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('403') || msg.contains('coordinatori') || msg.contains('404')) {
        setState(() { _notCoordinator = true; _loading = false; });
      } else {
        setState(() { _error = msg; _loading = false; });
      }
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
                const Icon(Icons.group, color: Color(0xFFD4A017)),
                const SizedBox(width: 8),
                const Text('Quote Gruppo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: _load),
              ],
            ),
            const Divider(),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_notCoordinator)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Visibile solo ai coordinatori di gruppo', style: TextStyle(color: Colors.grey))))
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
    final pct = (_data!['percentuale'] as num).toDouble();
    final raccolto = (_data!['totale_raccolto'] as num).toDouble();
    final atteso = (_data!['totale_atteso'] as num).toDouble();
    final membri = _data!['membri'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar globale
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('€${raccolto.toStringAsFixed(2)} / €${atteso.toStringAsFixed(2)} (${pct.toStringAsFixed(0)}%)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      color: pct >= 100 ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...membri.map((m) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Icon(m['pagato'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: m['pagato'] == true ? Colors.green : Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(m['nome'] ?? 'N/D', style: const TextStyle(fontSize: 13))),
              Text('€${(m['importo_pagato'] as num).toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        )),
      ],
    );
  }
}

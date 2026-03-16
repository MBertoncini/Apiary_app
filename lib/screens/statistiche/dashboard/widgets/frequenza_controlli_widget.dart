import 'package:flutter/material.dart';
import '../../../../services/statistiche_service.dart';

class FrequenzaControlliWidget extends StatefulWidget {
  final StatisticheService service;
  const FrequenzaControlliWidget({super.key, required this.service});

  @override
  State<FrequenzaControlliWidget> createState() => _FrequenzaControlliWidgetState();
}

class _FrequenzaControlliWidgetState extends State<FrequenzaControlliWidget> {
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
      final data = await widget.service.getFrequenzaControlli();
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
                const Icon(Icons.calendar_today, color: Color(0xFFD4A017)),
                const SizedBox(width: 8),
                const Text('Frequenza Controlli', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    final media = _data!['media_giorni_tra_controlli'];
    final arnie = _data!['arnie'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (media != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF5F0E8), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Color(0xFFD4A017), size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Media giorni tra controlli', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${media} giorni', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (arnie.isNotEmpty) ...[
          const Text('Dettaglio per arnia:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...arnie.take(8).map((a) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text('Arnia #${a['numero']}', style: const TextStyle(fontSize: 13)),
                const Spacer(),
                Text(
                  a['media_intervallo_giorni'] != null ? '${a['media_intervallo_giorni']} gg' : 'N/D',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: a['media_intervallo_giorni'] != null && (a['media_intervallo_giorni'] as num) > 30
                        ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }
}

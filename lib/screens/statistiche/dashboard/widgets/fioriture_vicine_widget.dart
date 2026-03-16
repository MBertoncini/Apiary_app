import 'package:flutter/material.dart';
import '../../../../services/statistiche_service.dart';

class FioritureVicineWidget extends StatefulWidget {
  final StatisticheService service;
  const FioritureVicineWidget({super.key, required this.service});

  @override
  State<FioritureVicineWidget> createState() => _FioritureVicineWidgetState();
}

class _FioritureVicineWidgetState extends State<FioritureVicineWidget> {
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
      final data = await widget.service.getFioritureVicine();
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
                const Icon(Icons.eco, color: Color(0xFFD4A017)),
                const SizedBox(width: 8),
                const Text('Fioriture Vicine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    final fioriture = _data!['fioriture'] as List;
    if (fioriture.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Nessuna fioritura nel raggio di 5 km')));
    }

    return Column(
      children: fioriture.take(6).map((f) {
        final intensita = f['intensita'] as int?;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_florist, color: Colors.green),
          ),
          title: Text(f['pianta'] ?? 'N/D', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${f['apiario_vicino']} • ${f['distanza_km']} km'),
          trailing: intensita != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < intensita ? Colors.amber : Colors.grey[300])),
                )
              : null,
        );
      }).toList(),
    );
  }
}

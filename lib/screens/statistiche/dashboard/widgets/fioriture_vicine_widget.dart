import 'package:flutter/material.dart';
import '../../../../services/statistiche_service.dart';
import 'dashboard_card_base.dart';

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

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.service.getFioritureVicine(forceRefresh: forceRefresh);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCardBase(
      icon: const Icon(Icons.eco, color: Color(0xFFD4A017)),
      title: 'Fioriture Vicine',
      loading: _loading,
      error: _error,
      onRetry: () => _load(forceRefresh: true),
      loadingHeight: 290,
      child: _data != null ? _buildContent() : const SizedBox.shrink(),
    );
  }

  Widget _buildContent() {
    final fioriture = _data!['fioriture'] as List;
    if (fioriture.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Nessuna fioritura nel raggio di 5 km')));
    }

    return Column(
      children: fioriture.take(4).map((f) {
        final intensita = f['intensita'] as int?;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_florist, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f['pianta'] ?? 'N/D', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${f['apiario_vicino']} • ${f['distanza_km']} km', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              if (intensita != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < intensita ? Colors.amber : Colors.grey[300])),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

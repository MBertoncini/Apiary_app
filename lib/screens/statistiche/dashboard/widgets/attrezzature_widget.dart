import 'package:flutter/material.dart';
import '../../../../services/statistiche_service.dart';
import 'dashboard_card_base.dart';

class AttrezzatureWidget extends StatefulWidget {
  final StatisticheService service;
  const AttrezzatureWidget({super.key, required this.service});

  @override
  State<AttrezzatureWidget> createState() => _AttrezzatureWidgetState();
}

class _AttrezzatureWidgetState extends State<AttrezzatureWidget> {
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
      final data = await widget.service.getRiepilogoAttrezzature(forceRefresh: forceRefresh);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCardBase(
      icon: const Icon(Icons.build, color: Color(0xFFD4A017)),
      title: 'Riepilogo Attrezzature',
      loading: _loading,
      error: _error,
      onRetry: () => _load(forceRefresh: true),
      child: _data != null ? _buildContent() : const SizedBox.shrink(),
    );
  }

  Widget _buildContent() {
    final categorie = _data!['per_categoria'] as List;
    final totale = (_data!['valore_totale_inventario'] as num).toDouble();

    if (categorie.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Nessuna attrezzatura registrata')));
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: const BoxDecoration(color: Color(0xFF1A1A2E)),
          child: Row(
            children: const [
              Expanded(flex: 3, child: Text('Categoria', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 1, child: Text('N°', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('Valore', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
            ],
          ),
        ),
        ...categorie.asMap().entries.map((entry) {
          final c = entry.value;
          return Container(
            color: entry.key % 2 == 0 ? Colors.white : const Color(0xFFF5F0E8),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(c['categoria'] ?? 'N/D', style: const TextStyle(fontSize: 13))),
                Expanded(flex: 1, child: Text('${c['count']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('€${(c['valore_totale'] as num).toStringAsFixed(0)}', style: const TextStyle(fontSize: 13), textAlign: TextAlign.right)),
              ],
            ),
          );
        }),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Expanded(flex: 3, child: Text('Inventario totale', style: TextStyle(fontWeight: FontWeight.bold))),
              const Expanded(flex: 1, child: SizedBox()),
              Expanded(flex: 2, child: Text('€${totale.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
            ],
          ),
        ),
      ],
    );
  }
}

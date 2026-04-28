import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/statistiche_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/language_service.dart';
import '../../../../l10n/app_strings.dart';
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

  List<Map<String, dynamic>> _apiari = const [];
  int? _selectedApiarioId;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    _loadApiari();
    _load();
  }

  Future<void> _loadApiari() async {
    final storage = context.read<StorageService>();
    final raw = await storage.getStoredData('apiari');
    if (!mounted) return;
    setState(() {
      _apiari = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.service.getFioritureVicine(
        apiarioId: _selectedApiarioId,
        forceRefresh: forceRefresh,
      );
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onSelect(int? id) {
    if (id == _selectedApiarioId) return;
    setState(() => _selectedApiarioId = id);
    _load();
  }

  String _selectedLabel() {
    if (_selectedApiarioId == null) return _s.dashboardFioritureFiltroTutti;
    final match = _apiari.firstWhere(
      (a) => a['id'] == _selectedApiarioId,
      orElse: () => const {},
    );
    return (match['nome'] as String?) ?? _s.dashboardFioritureFiltroTutti;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCardBase(
      icon: const Icon(Icons.eco, color: Color(0xFFD4A017)),
      title: _s.dashboardTitleFioritureVicine,
      loading: _loading,
      error: _error,
      onRetry: () => _load(forceRefresh: true),
      loadingHeight: 290,
      headerTrailing: _apiari.length > 1 ? _buildFilter() : null,
      child: _data != null ? _buildContent() : const SizedBox.shrink(),
    );
  }

  Widget _buildFilter() {
    return PopupMenuButton<int?>(
      tooltip: _selectedLabel(),
      onSelected: _onSelect,
      itemBuilder: (_) => [
        PopupMenuItem<int?>(
          value: null,
          child: Text(_s.dashboardFioritureFiltroTutti),
        ),
        const PopupMenuDivider(),
        ..._apiari.map((a) => PopupMenuItem<int?>(
          value: a['id'] as int?,
          child: Text((a['nome'] as String?) ?? '—'),
        )),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _selectedLabel(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final fioriture = (_data?['fioriture'] as List?) ?? const [];
    if (fioriture.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_s.dashboardFioritureNessuna)));
    }

    return Column(
      children: fioriture.take(4).map((f) {
        final intensita = (f is Map ? f['intensita'] : null) is num ? (f['intensita'] as num).toInt() : null;
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

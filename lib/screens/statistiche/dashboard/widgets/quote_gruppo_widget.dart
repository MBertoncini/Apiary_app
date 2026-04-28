import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';
import '../../../../services/gruppo_service.dart';
import '../../../../services/statistiche_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/language_service.dart';
import '../../../../l10n/app_strings.dart';
import 'dashboard_card_base.dart';

/// SharedPreferences key for the persisted group selection of the
/// dashboard "Quote Gruppo" widget. Also read by `DashboardTab._preloadAll`
/// so the preload hits the same cache key as the widget.
const String kQuoteGruppoSelectedIdKey = 'dashboard_quote_gruppo_selected_id';

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

  // Lista minima {id, nome} per popolare il selettore. Caricata una sola volta
  // dalla cache locale; rete solo se la cache è vuota.
  List<Map<String, dynamic>> _gruppi = const [];
  int? _selectedGruppoId;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Cattura provider prima di qualsiasi await (linter: use_build_context_synchronously).
    final storage = Provider.of<StorageService>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    _selectedGruppoId = prefs.getInt(kQuoteGruppoSelectedIdKey);
    await _loadGruppiList(storage, api);
    // Se l'id salvato non è più tra i gruppi disponibili, lo resetto:
    // l'utente potrebbe essere stato rimosso dal gruppo. Senza il reset
    // il backend ritornerebbe 404 e finiremmo nel ramo _notCoordinator.
    if (_selectedGruppoId != null &&
        _gruppi.isNotEmpty &&
        !_gruppi.any((g) => g['id'] == _selectedGruppoId)) {
      _selectedGruppoId = null;
      await prefs.remove(kQuoteGruppoSelectedIdKey);
    }
    await _load();
  }

  Future<void> _loadGruppiList(StorageService storage, ApiService api) async {
    try {
      final cached = await storage.getStoredData('gruppi');
      List<dynamic> raw = cached;
      if (raw.isEmpty) {
        // Cache vuota: una sola chiamata di rete per ottenere la lista.
        final groups = await GruppoService(api, storage).getGruppi();
        raw = groups.map((g) => {'id': g.id, 'nome': g.nome}).toList();
      }
      final list = <Map<String, dynamic>>[];
      for (final item in raw) {
        if (item is Map) {
          final id = item['id'];
          final nome = item['nome'];
          if (id is int && nome is String) {
            list.add({'id': id, 'nome': nome});
          }
        }
      }
      if (mounted) setState(() => _gruppi = list);
    } catch (_) {
      // Fallisce silenziosamente: il widget continua a funzionare con il
      // gruppo di default scelto dal backend.
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() { _loading = true; _error = null; _notCoordinator = false; });
    try {
      final data = await widget.service.getQuoteGruppo(
        gruppoId: _selectedGruppoId,
        forceRefresh: forceRefresh,
      );
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('403') || msg.contains('coordinatori') || msg.contains('404') ||
          msg.contains('not_admin') || msg.contains('no_gruppo')) {
        setState(() { _notCoordinator = true; _loading = false; });
      } else {
        setState(() { _error = msg; _loading = false; });
      }
    }
  }

  Future<void> _onGruppoSelected(int id) async {
    if (id == _selectedGruppoId) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kQuoteGruppoSelectedIdKey, id);
    setState(() => _selectedGruppoId = id);
    await _load(forceRefresh: true);
  }

  Widget? _buildGruppoSelector() {
    if (_gruppi.length < 2) return null;
    final currentId = _selectedGruppoId ??
        (_data?['gruppo_id'] is int ? _data!['gruppo_id'] as int : null);
    return PopupMenuButton<int>(
      tooltip: _s.dashboardQuoteGruppoSelezionaGruppo,
      icon: const Icon(Icons.swap_horiz, size: 20),
      onSelected: _onGruppoSelected,
      itemBuilder: (_) => _gruppi.map((g) {
        final id = g['id'] as int;
        final nome = g['nome'] as String;
        final selected = id == currentId;
        return PopupMenuItem<int>(
          value: id,
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 16,
                color: selected ? const Color(0xFFD4A017) : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(nome, overflow: TextOverflow.ellipsis)),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nomeGruppo = _data?['nome_gruppo'] as String?;
    return DashboardCardBase(
      icon: const Icon(Icons.group, color: Color(0xFFD4A017)),
      title: nomeGruppo != null && nomeGruppo.isNotEmpty
          ? '${_s.dashboardTitleQuoteGruppo} · $nomeGruppo'
          : _s.dashboardTitleQuoteGruppo,
      loading: _loading,
      error: _error,
      onRetry: () => _load(forceRefresh: true),
      headerTrailing: _buildGruppoSelector(),
      child: _notCoordinator
          ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_s.dashboardQuoteGruppoSoloCoord, style: const TextStyle(color: Colors.grey))))
          : _data != null ? _buildContent() : const SizedBox.shrink(),
    );
  }

  double _num(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

  Widget _buildContent() {
    final speso = _num(_data?['totale_speso']);
    final dovuto = _num(_data?['totale_dovuto'] ?? _data?['totale_atteso']);
    final raccolto = _num(_data?['totale_raccolto']);
    final pct = _num(_data?['percentuale']);
    final quoteComplete = _data?['quote_complete'] != false;
    final membri = (_data?['membri'] as List?) ?? const [];

    if (speso <= 0 && membri.every((m) => _num(m['importo_pagato']) <= 0)) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(_s.dashboardQuoteGruppoNessunaSpesa, style: const TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_s.dashboardQuoteGruppoLabelSpeso}: €${speso.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        Text(
          '${_s.dashboardQuoteGruppoLabelCopertura}: €${raccolto.toStringAsFixed(2)} / €${dovuto.toStringAsFixed(2)} (${pct.toStringAsFixed(0)}%)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: dovuto > 0 ? (raccolto / dovuto).clamp(0.0, 1.0) : 0.0,
            minHeight: 12,
            backgroundColor: Colors.grey[200],
            color: pct >= 100 ? Colors.green : Colors.orange,
          ),
        ),
        if (!quoteComplete) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _s.dashboardQuoteGruppoQuoteIncomplete,
                  style: const TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        ...membri.map((m) {
          final dovutoM = _num(m['importo_dovuto'] ?? m['importo_atteso']);
          final pagatoM = _num(m['importo_pagato']);
          final ok = m['pagato'] == true;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: ok ? Colors.green : Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(m['nome'] ?? 'N/D', style: const TextStyle(fontSize: 13))),
                Text(
                  '€${pagatoM.toStringAsFixed(2)} / €${dovutoM.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: ok ? Colors.green[700] : Colors.orange[800],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

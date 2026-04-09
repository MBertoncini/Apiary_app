import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../l10n/app_strings.dart';
import '../../models/maturatore.dart';
import '../../models/contenitore_stoccaggio.dart';
import '../../models/invasettamento.dart';
import '../../widgets/offline_banner.dart';
import 'widgets/maturatore_card.dart';
import 'widgets/contenitore_card.dart';
import 'widgets/lotto_vasetti_section.dart';
import 'sheets/aggiungi_maturatore_sheet.dart';
import 'sheets/trasferisci_sheet.dart';
import 'sheets/invasetta_sheet.dart';

class CantinaScreen extends StatefulWidget {
  const CantinaScreen({Key? key}) : super(key: key);

  @override
  State<CantinaScreen> createState() => _CantinaScreenState();
}

class _CantinaScreenState extends State<CantinaScreen> {
  late ApiService _apiService;
  late StorageService _storageService;

  List<Maturatore> _maturatori = [];
  List<ContenitoreStoccaggio> _contenitori = [];
  List<Invasettamento> _invasettamenti = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(auth);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _load();
  }

  Future<void> _load() async {
    // Phase 1: cache
    final cached = await Future.wait([
      _storageService.getStoredData('maturatori'),
      _storageService.getStoredData('contenitori_stoccaggio'),
      _storageService.getStoredData('invasettamenti'),
    ]);
    if (cached[0].isNotEmpty || cached[1].isNotEmpty || cached[2].isNotEmpty) {
      _maturatori = cached[0].map<Maturatore>((e) => Maturatore.fromJson(e)).toList();
      _contenitori = cached[1].map<ContenitoreStoccaggio>((e) => ContenitoreStoccaggio.fromJson(e)).toList();
      _invasettamenti = cached[2].map<Invasettamento>((e) => Invasettamento.fromJson(e)).toList();
      if (mounted) setState(() { _isLoading = false; _isRefreshing = true; });
    } else {
      if (mounted) setState(() { _isRefreshing = true; });
    }

    // Phase 2: server
    try {
      final results = await Future.wait([
        _apiService.get(ApiConstants.maturatoriUrl),
        _apiService.get(ApiConstants.contenitoriStoccaggioUrl),
        _apiService.get(ApiConstants.invasettamentiUrl),
      ]);
      final mList = results[0] is List ? results[0] : (results[0]['results'] as List? ?? []);
      final cList = results[1] is List ? results[1] : (results[1]['results'] as List? ?? []);
      final iList = results[2] is List ? results[2] : (results[2]['results'] as List? ?? []);

      _maturatori = mList.map<Maturatore>((e) => Maturatore.fromJson(e)).toList();
      _contenitori = cList.map<ContenitoreStoccaggio>((e) => ContenitoreStoccaggio.fromJson(e)).toList();
      _invasettamenti = iList.map<Invasettamento>((e) => Invasettamento.fromJson(e)).toList();

      await Future.wait([
        if (mList.isNotEmpty) _storageService.saveData('maturatori', mList),
        if (cList.isNotEmpty) _storageService.saveData('contenitori_stoccaggio', cList),
        if (iList.isNotEmpty) _storageService.saveData('invasettamenti', iList),
      ]);
    } catch (e) {
      if (_maturatori.isEmpty && _contenitori.isEmpty) {
        _error = _s.msgErrorGeneric(e.toString());
      }
    }

    if (mounted) setState(() { _isLoading = false; _isRefreshing = false; });
  }

  // ── Grouped invasettamenti by tipo_miele + formato ──────────────────
  Map<String, List<Invasettamento>> get _invasettamentiPerTipo {
    final active = _invasettamenti.where((i) => i.numeroVasetti > 0).toList();
    final Map<String, List<Invasettamento>> map = {};
    for (final inv in active) {
      map.putIfAbsent(inv.tipoMiele, () => []).add(inv);
    }
    return map;
  }

  // ── Total kg in maturation ───────────────────────────────────────────
  double get _totKgMaturazione =>
      _maturatori.where((m) => !m.isSvuotato).fold(0, (s, m) => s + m.kgAttuali);

  double get _totKgStoccaggio =>
      _contenitori.where((c) => !c.isVuoto).fold(0, (s, c) => s + c.kgAttuali);

  int get _totVasetti =>
      _invasettamenti.fold(0, (s, i) => s + i.numeroVasetti);

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.cantinaTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _load,
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildSummaryRow(),
                            const SizedBox(height: 20),
                            _buildMaturatoriSection(),
                            const SizedBox(height: 20),
                            _buildStoccaggioSection(),
                            const SizedBox(height: 20),
                            _buildInvasettatiSection(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddMaturatore,
        icon: const Icon(Icons.add),
        label: Text(s.cantinaBtnNuovoMaturatore),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: Text(s.btnRetry)),
        ],
      ),
    );
  }

  // ── Summary bar ──────────────────────────────────────────────────────
  Widget _buildSummaryRow() {
    return Row(
      children: [
        _summaryChip(Icons.hourglass_top, '${_totKgMaturazione.toStringAsFixed(1)} kg', s.cantinaInMaturazione, Colors.orange),
        const SizedBox(width: 8),
        _summaryChip(Icons.water_drop, '${_totKgStoccaggio.toStringAsFixed(1)} kg', s.cantinaStoccati, Colors.blue),
        const SizedBox(width: 8),
        _summaryChip(Icons.local_grocery_store, '$_totVasetti', s.cantinaVasetti, Colors.green),
      ],
    );
  }

  Widget _summaryChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // ── Maturatori ───────────────────────────────────────────────────────
  Widget _buildMaturatoriSection() {
    final active = _maturatori.where((m) => !m.isSvuotato).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(s.cantinaSectionMaturatori, s.cantinaAttiviLabel(active.length), onAdd: _onAddMaturatore),
        if (active.isEmpty)
          _emptyHint(s.cantinaNoMaturatori)
        else
          ...active.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MaturatoreCard(
              maturatore: m,
              onTrasferisci: () => _onTrasferisci(m),
              onDelete: () => _onDeleteMaturatore(m),
              onEdit: () => _onEditMaturatore(m),
            ),
          )),
      ],
    );
  }

  // ── Stoccaggio ───────────────────────────────────────────────────────
  Widget _buildStoccaggioSection() {
    final active = _contenitori.where((c) => !c.isVuoto).toList();
    // Group by tipo_miele
    final Map<String, List<ContenitoreStoccaggio>> byTipo = {};
    for (final c in active) {
      byTipo.putIfAbsent(c.tipoMiele, () => []).add(c);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(s.cantinaSectionStoccaggio, s.cantinaContenitoriLabel(active.length)),
        if (active.isEmpty)
          _emptyHint(s.cantinaNoContenitori)
        else
          ...byTipo.entries.map((entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: entry.value.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ContenitoreCard(
                      contenitore: c,
                      onInvasetta: () => _onInvasetta(c),
                      onDelete: () => _onDeleteContenitore(c),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          )),
      ],
    );
  }

  // ── Invasettato ──────────────────────────────────────────────────────
  Widget _buildInvasettatiSection() {
    final byTipo = _invasettamentiPerTipo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(s.cantinaSectionInvasettato, s.cantinaVasettiLabel(_totVasetti)),
        if (byTipo.isEmpty)
          _emptyHint(s.cantinaNoVasetti)
        else
          ...byTipo.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LottoVasettiSection(
              tipoMiele: entry.key,
              invasettamenti: entry.value,
              onSell: (selected, deductions) => _onSellVasetti(entry.key, selected, deductions),
            ),
          )),
      ],
    );
  }

  // ── Section header ───────────────────────────────────────────────────
  Widget _sectionHeader(String title, String subtitle, {VoidCallback? onAdd}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          if (onAdd != null)
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: Text(_s.btnAdd),
            ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(text, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────
  Future<void> _onAddMaturatore() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AggiungiMaturatoreSheet(apiService: _apiService),
    );
    if (result == true) _load();
  }

  Future<void> _onEditMaturatore(Maturatore m) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AggiungiMaturatoreSheet(apiService: _apiService, existing: m),
    );
    if (result == true) _load();
  }

  Future<void> _onTrasferisci(Maturatore m) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => TrasferisciSheet(apiService: _apiService, maturatore: m),
    );
    if (result == true) _load();
  }

  Future<void> _onInvasetta(ContenitoreStoccaggio c) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => InvasettaSheet(apiService: _apiService, contenitore: c),
    );
    if (result == true) _load();
  }

  Future<void> _onDeleteMaturatore(Maturatore m) async {
    final ok = await _confirmDelete(_s.cantinaDeleteMaturatoreMsg(m.nome));
    if (!ok) return;
    try {
      await _apiService.delete('${ApiConstants.maturatoriUrl}${m.id}/');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.msgErrorGeneric(e.toString()))));
    }
  }

  Future<void> _onDeleteContenitore(ContenitoreStoccaggio c) async {
    final ok = await _confirmDelete(_s.cantinaDeleteContenitoreMsg(c.nome.isEmpty ? c.tipoDisplay : c.nome));
    if (!ok) return;
    try {
      await _apiService.delete('${ApiConstants.contenitoriStoccaggioUrl}${c.id}/');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.msgErrorGeneric(e.toString()))));
    }
  }

  Future<void> _onSellVasetti(
    String tipoMiele,
    List<Map<String, dynamic>> selected,
    List<Map<String, dynamic>> deductions,
  ) async {
    final result = await Navigator.pushNamed(
      context,
      '/vendita/create',
      arguments: {'prefill_miele': selected, 'tipo_miele': tipoMiele},
    );
    // Solo se la vendita è stata salvata, scala i vasetti
    if (result == true && deductions.isNotEmpty) {
      try {
        await Future.wait(deductions.map((d) => _apiService.patch(
          '${ApiConstants.invasettamentiUrl}${d['id']}/',
          {'numero_vasetti': d['numero_vasetti']},
        )));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_s.cantinaVenditaErrVasetti}: $e')),
        );
      }
    }
    _load();
  }

  Future<bool> _confirmDelete(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(_s.dialogConfirmDeleteTitle),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_s.dialogCancelBtn)),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(_s.dialogConfirmDeleteBtn, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }
}

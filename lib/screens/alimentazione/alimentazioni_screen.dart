import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/api_constants.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../l10n/app_strings.dart';
import '../../models/alimentazione.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../utils/alimentazioni_stats.dart';
import '../../widgets/drawer_widget.dart';

/// Registro delle alimentazioni somministrate.
///
/// Due schede, come per i trattamenti sanitari:
/// - **Elenco**: le somministrazioni in ordine di data, con modifica e
///   cancellazione;
/// - **Analisi**: kg totali, colonie servite e ripartizione per tipo, scopo,
///   apiario e colonia sul periodo filtrato.
///
/// Aperta dal menu laterale (tutte le alimentazioni) oppure da
/// [ColoniaDetailScreen] passando `arguments: coloniaId` (int) per
/// pre-filtrare su una singola colonia.
class AlimentazioniScreen extends StatefulWidget {
  final int? coloniaId;
  const AlimentazioniScreen({Key? key, this.coloniaId}) : super(key: key);

  @override
  State<AlimentazioniScreen> createState() => _AlimentazioniScreenState();
}

class _AlimentazioniScreenState extends State<AlimentazioniScreen>
    with SingleTickerProviderStateMixin {
  late ApiService _api;
  late TabController _tabController;
  bool _loading = true;
  String? _error;
  List<Alimentazione> _items = [];

  /// null = tutti gli anni / tutti i tipi.
  int? _annoFiltro;
  String? _tipoFiltro;

  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  /// Id colonia effettivo: dal costruttore o dagli argomenti di rotta.
  int? _coloniaId;

  /// `didChangeDependencies` viene richiamato a ogni cambio di dipendenze
  /// (lingua, dimensioni, tema): senza questo flag il primo caricamento
  /// verrebbe rifatto ogni volta.
  bool _argsRisolti = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    final auth = Provider.of<AuthService>(context, listen: false);
    _api = ApiService(auth);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRisolti) return;
    _argsRisolti = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    _coloniaId = widget.coloniaId ?? (args is int ? args : null);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = _coloniaId != null
          ? '${ApiConstants.alimentazioniUrl}?colonia=$_coloniaId'
          : ApiConstants.alimentazioniUrl;
      final list = await _api.getAll(url);
      if (!mounted) return;
      setState(() {
        _items = list
            .map((e) => Alimentazione.fromJson(e as Map<String, dynamic>))
            .toList();
        // Se l'anno selezionato non esiste più (ultima riga cancellata),
        // il filtro tornerebbe a nascondere tutto: lo si azzera.
        if (_annoFiltro != null &&
            !anniDisponibili(_items).contains(_annoFiltro)) {
          _annoFiltro = null;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Alimentazione> get _filtrate =>
      filtraAlimentazioni(_items, anno: _annoFiltro, tipo: _tipoFiltro);

  // ── Azioni ────────────────────────────────────────────────────────────

  Future<void> _nuova() async {
    final ok = await Navigator.pushNamed(
      context,
      AppConstants.alimentazioneCreateRoute,
      arguments: _coloniaId,
    );
    if (ok == true) _load();
  }

  Future<void> _edit(Alimentazione a) async {
    final ok = await Navigator.pushNamed(
      context,
      AppConstants.alimentazioneEditRoute,
      arguments: a,
    );
    if (ok == true) _load();
  }

  Future<bool> _confirmDelete() async {
    final s = _s;
    final c = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.alimentazioniDeleteTitle),
        content: Text(s.alimentazioniDeleteMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.dialogCancelBtn),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.btnDelete),
          ),
        ],
      ),
    );
    return c == true;
  }

  Future<void> _delete(Alimentazione a) async {
    try {
      await _api.delete('${ApiConstants.alimentazioniUrl}${a.id}/');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_s.alimentazioniDeleted)));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.alimentazioniError(e.toString()))),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    // Con il pre-filtro per colonia si mostra la sua etichetta leggibile
    // (es. "Arnia 7") invece dell'id tecnico del database.
    final coloniaLabel = _coloniaId == null
        ? null
        : (_items.isNotEmpty ? _items.first.coloniaDisplay : null) ??
            'ID $_coloniaId';

    return Scaffold(
      appBar: AppBar(
        title: Text(coloniaLabel == null
            ? s.alimentazioniTitle
            : s.alimentazioniTitleColonia(coloniaLabel)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
                icon: const Icon(Icons.list_alt, size: 18),
                text: s.alimentazioniTabElenco),
            Tab(
                icon: const Icon(Icons.insights, size: 18),
                text: s.alimentazioniTabAnalisi),
          ],
        ),
      ),
      // Il drawer solo quando si arriva dal menu: dal dettaglio colonia la
      // schermata è un push e deve mantenere la freccia indietro.
      drawer: _coloniaId == null
          ? AppDrawer(currentRoute: AppConstants.alimentazioniRoute)
          : null,
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(s.alimentazioniFabNuova),
        onPressed: _nuova,
      ),
      body: _buildBody(s),
    );
  }

  Widget _buildBody(AppStrings s) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.alimentazioniError(_error!), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: Text(s.btnRetry)),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(s.alimentazioniEmpty, textAlign: TextAlign.center),
        ),
      );
    }
    return Column(
      children: [
        _buildFiltri(s),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildElenco(s),
              _buildAnalisi(s),
            ],
          ),
        ),
      ],
    );
  }

  // ── Filtri comuni alle due schede ─────────────────────────────────────

  Widget _buildFiltri(AppStrings s) {
    final anni = anniDisponibili(_items);
    final tipiPresenti =
        _items.map((a) => a.tipo).toSet().toList(growable: false);
    if (anni.length < 2 && tipiPresenti.length < 2) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (anni.length > 1) ...[
            _filtroChip(
              label: s.alimentazioniFiltroAnno,
              value: _annoFiltro?.toString(),
              options: {for (final y in anni) y.toString(): y.toString()},
              onSelected: (v) => setState(
                  () => _annoFiltro = v == null ? null : int.tryParse(v)),
              allLabel: s.labelAll,
            ),
            const SizedBox(width: 8),
          ],
          if (tipiPresenti.length > 1)
            _filtroChip(
              label: s.alimentazioniFiltroTipo,
              value: _tipoFiltro,
              options: {
                for (final t in tipiPresenti) t: s.alimentazioneTipoLabel(t)
              },
              onSelected: (v) => setState(() => _tipoFiltro = v),
              allLabel: s.labelAll,
            ),
        ],
      ),
    );
  }

  Widget _filtroChip({
    required String label,
    required String? value,
    required Map<String, String> options,
    required ValueChanged<String?> onSelected,
    required String allLabel,
  }) {
    final selectedLabel = value == null ? allLabel : (options[value] ?? value);
    return PopupMenuButton<String?>(
      onSelected: (v) => onSelected(v == '' ? null : v),
      itemBuilder: (_) => [
        PopupMenuItem<String?>(value: '', child: Text(allLabel)),
        ...options.entries.map(
          (e) => PopupMenuItem<String?>(value: e.key, child: Text(e.value)),
        ),
      ],
      child: Chip(
        avatar: Icon(
          value == null ? Icons.filter_list : Icons.filter_alt,
          size: 16,
          color: value == null ? Colors.grey : ThemeConstants.primaryColor,
        ),
        label: Text('$label: $selectedLabel'),
      ),
    );
  }

  // ── Scheda Elenco ─────────────────────────────────────────────────────

  Widget _buildElenco(AppStrings s) {
    final items = _filtrate;
    if (items.isEmpty) {
      return _emptyFiltri(s);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final a = items[i];
          final hasNote = a.note != null && a.note!.trim().isNotEmpty;
          final scopo = a.scopoDisplay;
          final dettagli = [
            a.data,
            if (scopo != null && scopo.isNotEmpty) scopo,
            if (a.coloniaDisplay != null) a.coloniaDisplay!,
            if (a.apiarioNome != null && a.apiarioNome!.isNotEmpty)
              a.apiarioNome!,
          ].join(' · ');
          return ListTile(
            leading: const Icon(Icons.restaurant, color: Colors.amber),
            title: Text(
              '${a.tipoDisplay ?? s.alimentazioneTipoLabel(a.tipo)}'
              ' · ${formatKg(a.quantitaKg)} kg',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dettagli),
                if (hasNote)
                  Text(
                    a.note!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            isThreeLine: hasNote,
            onTap: () => _showDetail(a, s),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                if (await _confirmDelete()) _delete(a);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _emptyFiltri(AppStrings s) => ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(s.alimentazioniEmptyFiltri, textAlign: TextAlign.center),
          ),
        ],
      );

  void _showDetail(Alimentazione a, AppStrings s) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${a.tipoDisplay ?? s.alimentazioneTipoLabel(a.tipo)}'
                  ' · ${formatKg(a.quantitaKg)} kg',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _detailRow(Icons.calendar_today, a.data),
                if (a.coloniaDisplay != null)
                  _detailRow(Icons.hive_outlined, a.coloniaDisplay!),
                if (a.apiarioNome != null && a.apiarioNome!.isNotEmpty)
                  _detailRow(Icons.location_on_outlined, a.apiarioNome!),
                if (a.scopoDisplay != null && a.scopoDisplay!.isNotEmpty)
                  _detailRow(Icons.flag_outlined, a.scopoDisplay!),
                if (a.utenteUsername != null)
                  _detailRow(Icons.person_outline, a.utenteUsername!),
                if (a.note != null && a.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(s.labelNotes,
                      style: Theme.of(ctx).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(a.note!.trim()),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        label: Text(s.btnDelete,
                            style: const TextStyle(color: Colors.red)),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          if (await _confirmDelete()) _delete(a);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: Text(s.btnEdit),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _edit(a);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // ── Scheda Analisi ────────────────────────────────────────────────────

  Widget _buildAnalisi(AppStrings s) {
    final items = _filtrate;
    if (items.isEmpty) {
      return _emptyFiltri(s);
    }
    final r = riepilogo(items);
    final apiari = perApiario(items);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        children: [
          _buildRiepilogoCard(s, r),
          const SizedBox(height: 12),
          _buildGruppoCard(s, s.alimentazioniPerTipo, perTipo(items),
              r.kgTotali, Icons.category_outlined),
          const SizedBox(height: 12),
          _buildGruppoCard(
            s,
            s.alimentazioniPerScopo,
            perScopo(items, senzaScopo: s.alimentazioniSenzaScopo),
            r.kgTotali,
            Icons.flag_outlined,
          ),
          // Solo se il backend espone l'apiario e c'è più di una postazione.
          if (apiari.length > 1) ...[
            const SizedBox(height: 12),
            _buildGruppoCard(s, s.alimentazioniPerApiario, apiari, r.kgTotali,
                Icons.location_on_outlined),
          ],
          // Con il pre-filtro per colonia il raggruppamento è ridondante.
          if (_coloniaId == null) ...[
            const SizedBox(height: 12),
            _buildGruppoCard(s, s.alimentazioniPerColonia, perColonia(items),
                r.kgTotali, Icons.hive_outlined,
                maxRighe: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildRiepilogoCard(AppStrings s, AlimentazioniSummary r) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _metrica(s.alimentazioniKgTotali, formatKg(r.kgTotali),
                    suffix: 'kg', evidenza: true),
                _metrica(
                    s.alimentazioniSomministrazioni, '${r.somministrazioni}'),
                _metrica(
                    s.alimentazioniColonieCoinvolte, '${r.colonieCoinvolte}'),
                _metrica(s.alimentazioniMediaPerColonia,
                    formatKg(r.kgPerColonia),
                    suffix: 'kg'),
              ],
            ),
            if (r.ultimaData != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.event_available,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('${s.alimentazioniUltima}: ${r.ultimaData}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metrica(String label, String value,
      {String? suffix, bool evidenza = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: evidenza ? 26 : 20,
                fontWeight: FontWeight.bold,
                color: evidenza ? ThemeConstants.primaryColor : null,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 3),
              Text(suffix, style: const TextStyle(color: Colors.grey)),
            ],
          ],
        ),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildGruppoCard(
    AppStrings s,
    String titolo,
    List<AlimentazioneGroup> gruppi,
    double totale,
    IconData icona, {
    int maxRighe = 0,
  }) {
    if (gruppi.isEmpty) return const SizedBox.shrink();
    final righe = maxRighe > 0 && gruppi.length > maxRighe
        ? gruppi.sublist(0, maxRighe)
        : gruppi;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icona, size: 18, color: ThemeConstants.primaryColor),
                const SizedBox(width: 8),
                Text(titolo,
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            ...righe.map((g) {
              final quota = totale > 0 ? (g.kg / totale).clamp(0.0, 1.0) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(g.label)),
                        Text(
                          '${(quota * 100).round()}%',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: quota,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            ThemeConstants.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.alimentazioniGroupSubtitle(formatKg(g.kg), g.count),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/colonia.dart';
import '../../services/api_service.dart';
import '../../services/colonia_service.dart';
import '../../services/controllo_service.dart';
import '../../services/language_service.dart';
import '../../models/controllo_arnia.dart';
import '../../models/colony_risk_prediction.dart';
import '../../models/production_prediction.dart';
import '../../widgets/skeleton_widgets.dart';
import 'colonia_form_screen.dart';

/// Schermata di dettaglio di una singola colonia.
/// Mostra: info ciclo di vita, controlli storici, regina, melari.
class ColoniaDetailScreen extends StatefulWidget {
  final int coloniaId;

  const ColoniaDetailScreen({Key? key, required this.coloniaId}) : super(key: key);

  @override
  State<ColoniaDetailScreen> createState() => _ColoniaDetailScreenState();
}

class _ColoniaDetailScreenState extends State<ColoniaDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Colonia? _colonia;
  List<ControlloArnia> _controlli = [];
  ColonyPredictions? _predictions;
  ProductionPrediction? _production;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final service = ColoniaService(api);
      _colonia = await service.getColonia(widget.coloniaId);

      // Carica controlli via ControlloService
      if (_colonia != null) {
        try {
          final cs = ControlloService(api);
          final raw = await cs.getControlliByColonia(widget.coloniaId);
          _controlli = raw
              .map((r) => ControlloArnia.fromJson(r))
              .toList();
          _controlli.sort((a, b) => b.data.compareTo(a.data));
        } catch (_) {}

        // Predizioni ML per-colonia (best-effort: non bloccano la schermata)
        try {
          final res = await api.getColoniaPrediction(widget.coloniaId);
          _predictions = ColonyPredictions.fromResponse(res);
          _production = ProductionPrediction.fromResponse(res);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('ColoniaDetail load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context).strings;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(s.coloniaDetailTitle)),
        body: const SingleChildScrollView(
          child: Column(
            children: [SkeletonDetailHeader(), SizedBox(height: 8), SkeletonDetailHeader()],
          ),
        ),
      );
    }

    if (_colonia == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.coloniaDetailTitle)),
        body: Center(child: Text(s.coloniaDetailNotFound)),
      );
    }

    final c = _colonia!;
    final statusColor = c.isAttiva ? Colors.green : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.coloniaId(c.id)),
        actions: [
          if (c.isAttiva)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'chiudi') _navigateToChiudiColonia();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'chiudi',
                  child: ListTile(
                    leading: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                    title: Text(s.coloniaDetailMenuChiudi),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.coloniaDetailTabInfo),
            Tab(text: s.coloniaDetailTabControlli),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab Info ───────────────────────────────────────────────────
          RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stato badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            c.statoLabel,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card predittive ML (mostrate solo quelle con dati)
                if (_predictions != null)
                  ..._predictions!.risks.where((r) => r.hasData).map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildRiskCard(r),
                        ),
                      ),
                if (_production != null && _production!.hasData) ...[
                  _buildProductionCard(_production!),
                  const SizedBox(height: 16),
                ],

                _infoRow(Icons.home_outlined, s.coloniaDetailLblContenitore, c.contenitoreLabel),
                _infoRow(Icons.location_on_outlined, s.coloniaDetailLblApiario, c.apiarioNome),
                _infoRow(Icons.calendar_today_outlined, s.coloniaDetailLblInsediataIl, c.dataInizio),
                if (c.dataFine != null)
                  _infoRow(Icons.event_busy_outlined, s.coloniaDetailLblChiusaIl, c.dataFine!),
                if (c.motivoFine != null && c.motivoFine!.isNotEmpty)
                  _infoRow(Icons.info_outline, s.coloniaDetailLblMotivoFine, c.motivoFine!),

                const Divider(height: 32),

                // Regina attiva
                if (c.reginaAttiva != null) ...[
                  Text(s.coloniaDetailSectionRegina, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _infoRow(Icons.emoji_nature_outlined, s.coloniaDetailLblRazza,
                      c.reginaAttiva!['razza'] ?? '—'),
                  _infoRow(Icons.info_outline, s.coloniaDetailLblOrigine,
                      c.reginaAttiva!['origine'] ?? '—'),
                  _infoRow(Icons.calendar_today_outlined, s.coloniaDetailLblIntrodottaIl,
                      c.reginaAttiva!['data_introduzione'] ?? '—'),
                  const Divider(height: 32),
                ],

                // Genealogia colonia
                if (c.coloniaOrigineId != null)
                  _infoRow(Icons.account_tree_outlined, s.coloniaDetailLblOrigineDa,
                      s.coloniaOrigineDaId(c.coloniaOrigineId!)),
                if (c.coloniaSuccessoreId != null)
                  _infoRow(Icons.call_merge_rounded, s.coloniaDetailLblConfluitaIn,
                      s.coloniaConfluitaInId(c.coloniaSuccessoreId!)),

                // Contatore controlli
                if (c.nControlli != null)
                  _infoRow(Icons.checklist_outlined, s.coloniaDetailLblTotaleControlli,
                      '${c.nControlli}'),

                // Note
                if (c.note != null && c.note!.isNotEmpty) ...[
                  const Divider(height: 32),
                  Text(s.coloniaDetailSectionNote, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(c.note!, style: const TextStyle(color: Colors.black87)),
                ],

                // Dataset ML per-colonia: scorciatoie a alimentazioni/nomadismo
                const Divider(height: 32),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.restaurant, size: 18),
                      label: const Text('Alimentazioni'),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppConstants.alimentazioniRoute,
                        arguments: c.id,
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Spostamenti'),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppConstants.nomadismiRoute,
                        arguments: c.id,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Tab Controlli ──────────────────────────────────────────────
          _controlli.isEmpty
              ? Center(child: Text(s.coloniaDetailNoControlli))
              : ListView.builder(
                  itemCount: _controlli.length,
                  itemBuilder: (ctx, i) {
                    final ctrl = _controlli[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            ctrl.problemiSanitari ? Colors.red.shade100 : Colors.green.shade100,
                        child: Icon(
                          ctrl.problemiSanitari ? Icons.warning_rounded : Icons.check_rounded,
                          color: ctrl.problemiSanitari ? Colors.red : Colors.green,
                          size: 18,
                        ),
                      ),
                      title: Text(ctrl.data),
                      subtitle: Text(
                        s.coloniaControlloSubtitle(ctrl.telainiScorte, ctrl.telainiCovata) +
                        (ctrl.sciamatura ? s.coloniaControlloSciamatura : ''),
                      ),
                      trailing: ctrl.presenzaRegina
                          ? const Icon(Icons.emoji_nature, color: Colors.amber, size: 16)
                          : const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Color _levelColor(String? level) {
    switch (level) {
      case 'critico':
        return Colors.red;
      case 'alto':
        return Colors.deepOrange;
      case 'medio':
        return Colors.amber.shade800;
      case 'basso':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _levelIcon(String? level) {
    switch (level) {
      case 'critico':
      case 'alto':
        return Icons.warning_amber_rounded;
      case 'medio':
        return Icons.info_outline;
      case 'basso':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildRiskCard(ColonyRiskPrediction p) {
    final color = _levelColor(p.level);
    final positives = p.factors.where((f) => f.impact > 0).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_levelIcon(p.level), color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(p.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              if (p.hasData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(p.level ?? '').toUpperCase()}${p.score != null ? ' · ${p.score}' : ''}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(p.summary, style: const TextStyle(color: Colors.black87, fontSize: 13)),
          if (positives.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: positives
                  .map((f) => Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(f.label,
                            style: const TextStyle(fontSize: 11, color: Colors.black87)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 14, color: Colors.black45),
              const SizedBox(width: 4),
              Text('Confidenza: ${p.confidence}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
              if (p.lowData) ...[
                const SizedBox(width: 8),
                const Text('· stima preliminare',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                        fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductionCard(ProductionPrediction p) {
    final color = Colors.amber.shade800;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_outlined, color: color, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Produzione miele attesa',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              if (p.year != null)
                Text('${p.year}',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('~${p.expectedKg!.toStringAsFixed(0)} kg',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 24, color: color)),
              const SizedBox(width: 8),
              if (p.kgLow != null && p.kgHigh != null)
                Text(
                  '(${p.kgLow!.toStringAsFixed(0)}–${p.kgHigh!.toStringAsFixed(0)} kg)',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
            ],
          ),
          if (p.drivers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: p.drivers
                  .map((d) => Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text('${d.label} · ~${d.kg.toStringAsFixed(0)} kg',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black87)),
                      ))
                  .toList(),
            ),
          ],
          if (p.lastSeasonKg != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.history, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text('Scorso raccolto: ${p.lastSeasonKg!.toStringAsFixed(0)} kg',
                    style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text('${p.basis} · confidenza ${p.confidence}',
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _navigateToChiudiColonia() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ColoniaChiudiScreen(colonia: _colonia!),
      ),
    );
    _load();
  }
}


/// Schermata che mostra la storia di tutte le colonie di un'arnia.
class StoriaColonieScreen extends StatefulWidget {
  final int arniaId;

  const StoriaColonieScreen({Key? key, required this.arniaId}) : super(key: key);

  @override
  State<StoriaColonieScreen> createState() => _StoriaColonieScreenState();
}

class _StoriaColonieScreenState extends State<StoriaColonieScreen> {
  bool _isLoading = true;
  List<Colonia> _colonie = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final service = ColoniaService(api);
      _colonie = await service.getStoriaColonieByArnia(widget.arniaId);
    } catch (e) {
      debugPrint('StoriaColonie load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context).strings;

    return Scaffold(
      appBar: AppBar(title: Text(s.storiaColonieTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _colonie.isEmpty
              ? Center(child: Text(s.storiaColonieEmpty))
              : ListView.builder(
                  itemCount: _colonie.length,
                  itemBuilder: (ctx, i) {
                    final c = _colonie[i];
                    final isAttiva = c.isAttiva;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isAttiva ? Colors.green.shade100 : Colors.grey.shade200,
                        child: Icon(
                          Icons.bug_report_rounded,
                          color: isAttiva ? Colors.green : Colors.grey,
                        ),
                      ),
                      title: Text(s.storiaColonieItem(c.id, c.statoLabel)),
                      subtitle: Text(s.storiaColonieDates(
                        c.dataInizio,
                        c.dataFine,
                      )),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ColoniaDetailScreen(coloniaId: c.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

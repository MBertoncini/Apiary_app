import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/colonia.dart';
import '../../services/api_service.dart';
import '../../services/colonia_service.dart';
import '../../services/controllo_service.dart';
import '../../models/controllo_arnia.dart';
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
              .map((r) => ControlloArnia.fromJson(r as Map<String, dynamic>))
              .toList();
          _controlli.sort((a, b) => b.data.compareTo(a.data));
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Colonia')),
        body: const SingleChildScrollView(
          child: Column(
            children: [SkeletonDetailHeader(), SizedBox(height: 8), SkeletonDetailHeader()],
          ),
        ),
      );
    }

    if (_colonia == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Colonia')),
        body: const Center(child: Text('Colonia non trovata')),
      );
    }

    final c = _colonia!;
    final statusColor = c.isAttiva ? Colors.green : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: Text('Colonia #${c.id}'),
        actions: [
          if (c.isAttiva)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'chiudi') _navigateToChiudiColonia();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'chiudi',
                  child: ListTile(
                    leading: Icon(Icons.stop_circle_outlined, color: Colors.red),
                    title: Text('Chiudi ciclo di vita'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Controlli'),
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

                // Contenitore
                _infoRow(Icons.home_outlined, 'Contenitore', c.contenitoreLabel),
                _infoRow(Icons.location_on_outlined, 'Apiario', c.apiarioNome),
                _infoRow(Icons.calendar_today_outlined, 'Insediata il', c.dataInizio),
                if (c.dataFine != null)
                  _infoRow(Icons.event_busy_outlined, 'Chiusa il', c.dataFine!),
                if (c.motivoFine != null && c.motivoFine!.isNotEmpty)
                  _infoRow(Icons.info_outline, 'Motivo fine', c.motivoFine!),

                const Divider(height: 32),

                // Regina attiva
                if (c.reginaAttiva != null) ...[
                  Text('Regina', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _infoRow(Icons.emoji_nature_outlined, 'Razza',
                      c.reginaAttiva!['razza'] ?? '—'),
                  _infoRow(Icons.info_outline, 'Origine',
                      c.reginaAttiva!['origine'] ?? '—'),
                  _infoRow(Icons.calendar_today_outlined, 'Introdotta il',
                      c.reginaAttiva!['data_introduzione'] ?? '—'),
                  const Divider(height: 32),
                ],

                // Genealogia colonia
                if (c.coloniaOrigineId != null)
                  _infoRow(Icons.account_tree_outlined, 'Origine da colonia',
                      'Colonia #${c.coloniaOrigineId}'),
                if (c.coloniaSuccessoreId != null)
                  _infoRow(Icons.call_merge_rounded, 'Confluita in',
                      'Colonia #${c.coloniaSuccessoreId}'),

                // Contatore controlli
                if (c.nControlli != null)
                  _infoRow(Icons.checklist_outlined, 'Totale controlli',
                      '${c.nControlli}'),

                // Note
                if (c.note != null && c.note!.isNotEmpty) ...[
                  const Divider(height: 32),
                  Text('Note', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(c.note!, style: const TextStyle(color: Colors.black87)),
                ],
              ],
            ),
          ),

          // ── Tab Controlli ──────────────────────────────────────────────
          _controlli.isEmpty
              ? const Center(child: Text('Nessun controllo registrato'))
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
                        'Scorte: ${ctrl.telainiScorte} · Covata: ${ctrl.telainiCovata}'
                        '${ctrl.sciamatura ? ' · ⚠ Sciamatura' : ''}',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Storia colonie')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _colonie.isEmpty
              ? const Center(child: Text('Nessuna colonia storica'))
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
                      title: Text('Colonia #${c.id} · ${c.statoLabel}'),
                      subtitle: Text(
                        'Dal ${c.dataInizio}'
                        '${c.dataFine != null ? ' al ${c.dataFine}' : ' · in corso'}',
                      ),
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

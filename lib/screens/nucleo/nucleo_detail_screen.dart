import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';

class NucleoDetailScreen extends StatefulWidget {
  final int nucleoId;
  const NucleoDetailScreen({Key? key, required this.nucleoId}) : super(key: key);

  @override
  _NucleoDetailScreenState createState() => _NucleoDetailScreenState();
}

class _NucleoDetailScreenState extends State<NucleoDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isRefreshing = true;
  Map<String, dynamic>? _nucleo;
  List<dynamic> _controlli = [];
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
    setState(() => _isRefreshing = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final nucleo = await api.getNucleoDetail(widget.nucleoId);
      final controlli = await api.getControlliByNucleo(widget.nucleoId);
      if (mounted) {
        setState(() {
          _nucleo = nucleo;
          _controlli = controlli;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore caricamento nucleo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Color _hexColor(String? hex) {
    if (hex == null) return Colors.grey;
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _nucleo;
    final conv = n?['convertito'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(n != null ? 'Nucleo ${n['numero'] ?? widget.nucleoId}' : 'Nucleo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Scheda'),
            Tab(icon: Icon(Icons.checklist), text: 'Controlli'),
          ],
        ),
        actions: [],
      ),
      body: Column(
        children: [
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _isRefreshing && n == null
                ? const SizedBox.shrink()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _SchedaTab(nucleo: n, onConvert: _convertNucleo, hexColor: _hexColor, fmt: _fmt),
                      _ControlliTab(
                        controlli: _controlli,
                        nucleoId: widget.nucleoId,
                        onAdd: _addControllo,
                        fmt: _fmt,
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: conv
          ? null
          : FloatingActionButton.extended(
              heroTag: 'nucleoDetailFab',
              icon: const Icon(Icons.upgrade),
              label: const Text('Converti in arnia'),
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
              onPressed: _confirmConvert,
            ),
    );
  }

  void _confirmConvert() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Converti in arnia'),
        content: Text(
            'Il nucleo ${_nucleo?['numero'] ?? ''} verrà trasformato in un\'arnia completa. Continuare?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Converti'),
          ),
        ],
      ),
    ).then((ok) {
      if (ok == true) _convertNucleo();
    });
  }

  Future<void> _convertNucleo() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final arnia = await api.convertNucleoToArnia(widget.nucleoId);
      if (arnia != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nucleo convertito in arnia!')),
        );
        Navigator.of(context).pop(true); // segnala refresh all'apiario
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  void _addControllo() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _NucleoControlloForm(
        nucleoId: widget.nucleoId,
        onSaved: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  TAB SCHEDA
// ─────────────────────────────────────────────────────────────────

class _SchedaTab extends StatelessWidget {
  final Map<String, dynamic>? nucleo;
  final VoidCallback onConvert;
  final Color Function(String?) hexColor;
  final String Function(String?) fmt;

  const _SchedaTab({
    required this.nucleo,
    required this.onConvert,
    required this.hexColor,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final n = nucleo;
    if (n == null) {
      return const Center(child: Text('Dati non disponibili'));
    }
    final conv = n['convertito'] == true;
    final colore = n['colore'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: hexColor(colore),
                  child: Text(
                    'N${n['numero'] ?? '?'}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nucleo ${n['numero'] ?? '—'}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      if (conv)
                        Chip(
                          label: const Text('Convertito in arnia'),
                          backgroundColor: Colors.green[100],
                          labelStyle: const TextStyle(color: Colors.green),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Dati principali
        Card(
          child: Column(
            children: [
              _InfoTile(Icons.calendar_today, 'Data installazione',
                  fmt(n['data_installazione'] as String?)),
              if (n['apiario_nome'] != null)
                _InfoTile(Icons.hive, 'Apiario', '${n['apiario_nome']}'),
              if (n['forza_colonia'] != null)
                _InfoTile(Icons.bar_chart, 'Forza colonia',
                    '${n['forza_colonia']}'),
              if (n['n_telaini'] != null)
                _InfoTile(Icons.grid_on, 'Telaini occupati',
                    '${n['n_telaini']}'),
              if (n['presenza_regina'] != null)
                _InfoTile(
                    Icons.stars,
                    'Presenza regina',
                    n['presenza_regina'] == true ? 'Sì' : 'No'),
              if (n['tipo_ape'] != null)
                _InfoTile(Icons.pest_control, 'Tipo ape', '${n['tipo_ape']}'),
            ],
          ),
        ),

        if (n['note'] != null && (n['note'] as String).isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.note_alt_outlined,
                          size: 18,
                          color: ThemeConstants.textSecondaryColor),
                      const SizedBox(width: 8),
                      Text('Note',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ThemeConstants.textSecondaryColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(n['note'] as String),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: ThemeConstants.primaryColor),
      title: Text(label,
          style: TextStyle(
              fontSize: 12, color: ThemeConstants.textSecondaryColor)),
      subtitle: Text(value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      dense: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  TAB CONTROLLI
// ─────────────────────────────────────────────────────────────────

class _ControlliTab extends StatelessWidget {
  final List<dynamic> controlli;
  final int nucleoId;
  final VoidCallback onAdd;
  final String Function(String?) fmt;

  const _ControlliTab({
    required this.controlli,
    required this.nucleoId,
    required this.onAdd,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    if (controlli.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist,
                size: 64, color: ThemeConstants.textSecondaryColor),
            const SizedBox(height: 16),
            const Text('Nessun controllo registrato',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi controllo'),
              onPressed: onAdd,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ...controlli.map((c) => _ControlloCard(c: c, fmt: fmt)),
        const SizedBox(height: 80), // spazio FAB
      ],
    );
  }
}

class _ControlloCard extends StatelessWidget {
  final dynamic c;
  final String Function(String?) fmt;
  const _ControlloCard({required this.c, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_note,
                    size: 18, color: ThemeConstants.primaryColor),
                const SizedBox(width: 8),
                Text(fmt(c['data'] as String?),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                if (c['forza_colonia'] != null)
                  Chip(
                    label: Text('Forza: ${c['forza_colonia']}'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            if (c['note'] != null && (c['note'] as String).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(c['note'] as String,
                  style: TextStyle(color: ThemeConstants.textSecondaryColor)),
            ],
            if (c['presenza_regina'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.stars,
                        size: 14,
                        color: c['presenza_regina'] == true
                            ? Colors.amber
                            : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                        c['presenza_regina'] == true
                            ? 'Regina presente'
                            : 'Regina non vista',
                        style:
                            const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  FORM NUOVO CONTROLLO NUCLEO
// ─────────────────────────────────────────────────────────────────

class _NucleoControlloForm extends StatefulWidget {
  final int nucleoId;
  final VoidCallback onSaved;
  const _NucleoControlloForm(
      {required this.nucleoId, required this.onSaved});

  @override
  _NucleoControlloFormState createState() => _NucleoControlloFormState();
}

class _NucleoControlloFormState extends State<_NucleoControlloForm> {
  final _noteCtrl = TextEditingController();
  DateTime _data = DateTime.now();
  int? _forzaColonia;
  bool? _presenzaRegina;
  int? _nTelaini;
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.createControlloNucleo(widget.nucleoId, {
        'data': _data.toIso8601String().split('T').first,
        'note': _noteCtrl.text.trim(),
        if (_forzaColonia != null) 'forza_colonia': _forzaColonia,
        if (_presenzaRegina != null) 'presenza_regina': _presenzaRegina,
        if (_nTelaini != null) 'n_telaini': _nTelaini,
      });
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore salvataggio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Nuovo controllo nucleo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Data
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text(DateFormat('dd/MM/yyyy').format(_data)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _data,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _data = picked);
            },
          ),

          // Telaini
          Row(
            children: [
              const Icon(Icons.grid_on, size: 20),
              const SizedBox(width: 8),
              const Text('Telaini:'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _nTelaini,
                hint: const Text('—'),
                items: List.generate(12, (i) => i + 1)
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: (v) => setState(() => _nTelaini = v),
              ),
              const SizedBox(width: 20),
              const Text('Forza:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _forzaColonia,
                hint: const Text('—'),
                items: List.generate(5, (i) => i + 1)
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: (v) => setState(() => _forzaColonia = v),
              ),
            ],
          ),

          // Regina
          Row(
            children: [
              const Icon(Icons.stars, size: 20),
              const SizedBox(width: 8),
              const Text('Regina:'),
              const SizedBox(width: 12),
              ToggleButtons(
                isSelected: [
                  _presenzaRegina == true,
                  _presenzaRegina == false,
                ],
                onPressed: (i) => setState(() => _presenzaRegina = i == 0),
                borderRadius: BorderRadius.circular(8),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Sì'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('No'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Text('Salva controllo'),
            ),
          ),
        ],
      ),
    );
  }
}

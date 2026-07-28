import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/api_constants.dart';
import '../../models/alimentazione.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

/// Form di creazione/modifica [Alimentazione].
///
/// Tre modalità:
/// - `alimentazione != null`: modifica del record esistente (PATCH);
/// - `arguments: coloniaId` (int): creazione per una colonia pre-selezionata;
/// - nessun argomento: creazione multipla — si sceglie l'apiario e una o più
///   colonie (anche tutte), viene creato un record per ciascuna colonia.
class AlimentazioneFormScreen extends StatefulWidget {
  final int? coloniaId;
  final Alimentazione? alimentazione;
  const AlimentazioneFormScreen({Key? key, this.coloniaId, this.alimentazione})
      : super(key: key);

  @override
  State<AlimentazioneFormScreen> createState() =>
      _AlimentazioneFormScreenState();
}

class _AlimentazioneFormScreenState extends State<AlimentazioneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ApiService _api;
  bool _saving = false;
  List<Map<String, dynamic>> _colonie = [];
  bool _loadingColonie = true;

  bool get _editing => widget.alimentazione != null;

  int? _apiarioSel;
  final Set<int> _selColonie = {};
  DateTime _data = DateTime.now();
  String _tipo = Alimentazione.tipiValidi.first;
  String? _scopo;
  final _quantitaCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  static const Map<String, String> _tipoLabel = {
    'sciroppo_1_1': 'Sciroppo 1:1 (stimolante)',
    'sciroppo_2_1': 'Sciroppo 2:1 (invernale)',
    'candito': 'Candito',
    'candito_proteico': 'Candito proteico',
    'polline': 'Polline / sostituti',
    'miele': 'Miele',
    'altro': 'Altro',
  };
  static const Map<String, String> _scopoLabel = {
    'stimolante': 'Stimolante primaverile',
    'sostentamento': 'Sostentamento estivo',
    'invernale': 'Riserve invernali',
    'emergenza': 'Emergenza (fame)',
    'introduzione': 'Introduzione regina / sciame',
    'altro': 'Altro',
  };

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    _api = ApiService(auth);

    final a = widget.alimentazione;
    if (a != null) {
      _data = DateTime.tryParse(a.data) ?? _data;
      if (Alimentazione.tipiValidi.contains(a.tipo)) _tipo = a.tipo;
      _scopo = (a.scopo != null && a.scopo!.isNotEmpty) ? a.scopo : null;
      _quantitaCtrl.text = _formatKg(a.quantitaKg);
      _noteCtrl.text = a.note ?? '';
      _loadingColonie = false;
    } else {
      _loadColonie();
    }
  }

  @override
  void dispose() {
    _quantitaCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  static String _formatKg(double v) {
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  int? get _preselectedColoniaId {
    if (widget.coloniaId != null) return widget.coloniaId;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is int ? args : null;
  }

  Future<void> _loadColonie() async {
    try {
      final list = await _api.getAll(ApiConstants.colonieUrl);
      if (!mounted) return;
      setState(() {
        _colonie = list.map((e) => e as Map<String, dynamic>).toList();
        _loadingColonie = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingColonie = false);
    }
  }

  /// Apiari distinti (id → nome) ricavati dalle colonie accessibili.
  Map<int, String> get _apiari {
    final map = <int, String>{};
    for (final c in _colonie) {
      final id = c['apiario'] as int?;
      if (id != null) {
        map[id] = c['apiario_nome']?.toString() ?? 'Apiario $id';
      }
    }
    return map;
  }

  List<Map<String, dynamic>> get _colonieApiario => _colonie
      .where((c) => c['apiario'] == _apiarioSel)
      .toList();

  double? _parseQta() {
    final qta = double.tryParse(_quantitaCtrl.text.replaceAll(',', '.'));
    return (qta == null || qta <= 0) ? null : qta;
  }

  Map<String, dynamic> _payload(int coloniaId, double qta) => {
        'colonia': coloniaId,
        'data': _data.toIso8601String().split('T')[0],
        'tipo': _tipo,
        'scopo': _scopo ?? '',
        'quantita_kg': qta,
        'note': _noteCtrl.text.trim(),
      };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final qta = _parseQta();
    if (qta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci una quantità in kg > 0.')),
      );
      return;
    }

    if (_editing) {
      await _saveEdit(qta);
      return;
    }

    final preselected = _preselectedColoniaId;
    final targets =
        preselected != null ? [preselected] : _selColonie.toList();
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno una colonia.')),
      );
      return;
    }

    setState(() => _saving = true);
    var ok = 0;
    Object? lastError;
    for (final coloniaId in targets) {
      try {
        await _api.post(ApiConstants.alimentazioniUrl, _payload(coloniaId, qta));
        ok++;
      } catch (e) {
        lastError = e;
      }
    }
    if (!mounted) return;

    if (ok == targets.length) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok == 1
            ? 'Alimentazione registrata.'
            : 'Alimentazione registrata per $ok colonie.'),
      ));
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
      final failed = targets.length - ok;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok == 0
            ? 'Errore: $lastError'
            : 'Registrate $ok su ${targets.length} '
                '($failed non riuscite). Errore: $lastError'),
      ));
      if (ok > 0) Navigator.pop(context, true);
    }
  }

  Future<void> _saveEdit(double qta) async {
    final a = widget.alimentazione!;
    setState(() => _saving = true);
    try {
      await _api.patch(
        '${ApiConstants.alimentazioniUrl}${a.id}/',
        _payload(a.colonia, qta),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alimentazione aggiornata.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preselected = _editing ? null : _preselectedColoniaId;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _editing ? 'Modifica alimentazione' : 'Nuova alimentazione'),
      ),
      body: _loadingColonie
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_editing) ...[
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Colonia',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(widget.alimentazione!.coloniaDisplay ??
                            'Colonia ${widget.alimentazione!.colonia}'),
                      ),
                      const SizedBox(height: 12),
                    ] else if (preselected == null) ...[
                      DropdownButtonFormField<int>(
                        value: _apiarioSel,
                        decoration: const InputDecoration(
                          labelText: 'Apiario *',
                          border: OutlineInputBorder(),
                        ),
                        items: _apiari.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _apiarioSel = v;
                          _selColonie.clear();
                        }),
                        validator: (v) =>
                            v == null ? 'Seleziona un apiario' : null,
                      ),
                      const SizedBox(height: 12),
                      if (_apiarioSel != null) ...[
                        _buildColonieSelector(),
                        const SizedBox(height: 12),
                      ],
                    ],
                    InkWell(
                      onTap: () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: _data,
                          firstDate: DateTime(2020),
                          lastDate:
                              DateTime.now().add(const Duration(days: 1)),
                        );
                        if (p != null) setState(() => _data = p);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                            '${_data.day.toString().padLeft(2, '0')}/${_data.month.toString().padLeft(2, '0')}/${_data.year}'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _tipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      items: Alimentazione.tipiValidi
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(_tipoLabel[t] ?? t),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _tipo = v ?? _tipo),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _scopo,
                      decoration: const InputDecoration(
                        labelText: 'Scopo (opzionale)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                            value: null, child: Text('—')),
                        ...Alimentazione.scopiValidi.map((s) =>
                            DropdownMenuItem(
                                value: s, child: Text(_scopoLabel[s] ?? s))),
                      ],
                      onChanged: (v) => setState(() => _scopo = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantitaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Quantità (kg) *',
                        helperText: preselected == null && !_editing
                            ? 'Quantità per ciascuna colonia selezionata'
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Inserisci la quantità';
                        }
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n <= 0) return 'Numero non valido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_editing ? 'Salva modifiche' : 'Salva'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildColonieSelector() {
    final colonie = _colonieApiario;
    if (colonie.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Nessuna colonia in questo apiario.'),
      );
    }
    final allSelected = _selColonie.length == colonie.length;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.shade400),
      ),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Colonie * (${_selColonie.length}/${colonie.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextButton(
                  onPressed: () => setState(() {
                    if (allSelected) {
                      _selColonie.clear();
                    } else {
                      _selColonie
                        ..clear()
                        ..addAll(colonie.map((c) => c['id'] as int));
                    }
                  }),
                  child: Text(allSelected ? 'Nessuna' : 'Tutte'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...colonie.map((c) {
            final id = c['id'] as int;
            return CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(c['contenitore']?.toString() ?? 'Colonia $id'),
              value: _selColonie.contains(id),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selColonie.add(id);
                } else {
                  _selColonie.remove(id);
                }
              }),
            );
          }),
        ],
      ),
    );
  }
}

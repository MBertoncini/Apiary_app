import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/api_constants.dart';
import '../../models/alimentazione.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../l10n/app_strings.dart';

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

  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  int? _apiarioSel;
  final Set<int> _selColonie = {};
  DateTime _data = DateTime.now();
  String _tipo = Alimentazione.tipiValidi.first;
  String? _scopo;
  final _quantitaCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

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

  /// Limite del campo `quantita_kg` lato backend: DecimalField(max_digits=6,
  /// decimal_places=2).
  static const double _maxKg = 9999.99;

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
      if (id != null && _isAttiva(c)) {
        map[id] = c['apiario_nome']?.toString() ?? 'Apiario $id';
      }
    }
    return map;
  }

  /// Etichetta leggibile di una colonia: "Arnia 7" / "Nucleo 3".
  ///
  /// `contenitore` dal backend vale la *stringa* 'arnia'/'nucleo'; il numero
  /// sta in `contenitore_numero`. Usare il solo `contenitore` rendeva tutte le
  /// caselle della lista identiche ("arnia"), impossibili da distinguere.
  static String coloniaLabel(Map<String, dynamic> c) {
    final numero = c['contenitore_numero'];
    final tipo = c['contenitore']?.toString();
    if (numero != null) {
      if (tipo == 'nucleo') return 'Nucleo $numero';
      if (tipo == 'arnia') return 'Arnia $numero';
      return '$numero';
    }
    return 'Colonia ${c['id']}';
  }

  /// Ordina per numero di contenitore, così l'elenco segue la numerazione in
  /// apiario invece dell'ordine arbitrario di ritorno dell'API.
  static int _compareColonie(Map<String, dynamic> a, Map<String, dynamic> b) {
    final na = a['contenitore_numero'];
    final nb = b['contenitore_numero'];
    if (na is int && nb is int) return na.compareTo(nb);
    if (na is int) return -1;
    if (nb is int) return 1;
    return (a['id'] as int).compareTo(b['id'] as int);
  }

  /// Colonie ancora vive: `/colonie/` restituisce anche quelle chiuse
  /// (morte, unite, sciamate) e non ha senso alimentarle.
  static bool _isAttiva(Map<String, dynamic> c) =>
      c['is_attiva'] == true || (c['is_attiva'] == null && c['data_fine'] == null);

  List<Map<String, dynamic>> get _colonieApiario => _colonie
      .where((c) => c['apiario'] == _apiarioSel && _isAttiva(c))
      .toList()
    ..sort(_compareColonie);

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
        SnackBar(content: Text(_s.alimentazioneFormQuantitaInvalid)),
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
        SnackBar(content: Text(_s.alimentazioneFormSelectColonia)),
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
            ? _s.alimentazioneFormSaved
            : _s.alimentazioneFormSavedMulti(ok)),
      ));
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok == 0
            ? _s.alimentazioneFormError('$lastError')
            : _s.alimentazioneFormPartial(
                ok, targets.length, '$lastError')),
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
        SnackBar(content: Text(_s.alimentazioneFormUpdated)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s.alimentazioneFormError(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    final preselected = _editing ? null : _preselectedColoniaId;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing
            ? s.alimentazioneFormTitleEdit
            : s.alimentazioneFormTitleNew),
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
                        decoration: InputDecoration(
                          labelText: s.alimentazioneFormColonia,
                          border: const OutlineInputBorder(),
                        ),
                        child: Text(widget.alimentazione!.coloniaDisplay ??
                            '${s.alimentazioneFormColonia} '
                                '${widget.alimentazione!.colonia}'),
                      ),
                      const SizedBox(height: 12),
                    ] else if (preselected == null && _apiari.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          s.alimentazioneFormNoColonieAttive,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ] else if (preselected == null) ...[
                      DropdownButtonFormField<int>(
                        value: _apiarioSel,
                        decoration: InputDecoration(
                          labelText: s.alimentazioneFormApiario,
                          border: const OutlineInputBorder(),
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
                            v == null ? s.alimentazioneFormSelectApiario : null,
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
                        decoration: InputDecoration(
                          labelText: s.alimentazioneFormData,
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                            '${_data.day.toString().padLeft(2, '0')}/${_data.month.toString().padLeft(2, '0')}/${_data.year}'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _tipo,
                      decoration: InputDecoration(
                        labelText: s.alimentazioneFormTipo,
                        border: const OutlineInputBorder(),
                      ),
                      items: Alimentazione.tipiValidi
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(s.alimentazioneTipoLabel(t)),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _tipo = v ?? _tipo),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _scopo,
                      decoration: InputDecoration(
                        labelText: s.alimentazioneFormScopo,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                            value: null, child: Text('—')),
                        ...Alimentazione.scopiValidi.map((k) =>
                            DropdownMenuItem(
                                value: k,
                                child: Text(s.alimentazioneScopoLabel(k)))),
                      ],
                      onChanged: (v) => setState(() => _scopo = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantitaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: s.alimentazioneFormQuantita,
                        helperText: preselected == null && !_editing
                            ? s.alimentazioneFormQuantitaHelper
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return s.alimentazioneFormQuantitaRequired;
                        }
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n <= 0) {
                          return s.alimentazioneFormQuantitaInvalid;
                        }
                        // Il backend salva quantita_kg come DecimalField(6,2):
                        // oltre 9999.99 la POST fallirebbe con un 400 opaco.
                        if (n > _maxKg) {
                          return s.alimentazioneFormQuantitaMax('$_maxKg');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: s.labelNotes,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: (_saving ||
                              (!_editing &&
                                  preselected == null &&
                                  _apiari.isEmpty))
                          ? null
                          : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(s.btnSave),
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
    final s = _s;
    final colonie = _colonieApiario;
    if (colonie.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(s.alimentazioneFormNoColonieApiario),
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
                  s.alimentazioneFormColonie(
                      _selColonie.length, colonie.length),
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
                  child: Text(allSelected
                      ? s.alimentazioneFormSelectNone
                      : s.alimentazioneFormSelectAll),
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
              title: Text(coloniaLabel(c)),
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

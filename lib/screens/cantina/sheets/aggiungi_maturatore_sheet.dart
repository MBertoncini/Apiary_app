import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/api_constants.dart';
import '../../../models/maturatore.dart';
import '../../../models/preferenza_maturazione.dart';
import '../../../services/api_service.dart';
import '../../../services/language_service.dart';

class AggiungiMaturatoreSheet extends StatefulWidget {
  final ApiService apiService;
  final Maturatore? existing;

  const AggiungiMaturatoreSheet({Key? key, required this.apiService, this.existing}) : super(key: key);

  @override
  State<AggiungiMaturatoreSheet> createState() => _AggiungiMaturatoreSheetState();
}

class _AggiungiMaturatoreSheetState extends State<AggiungiMaturatoreSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _tipoMieleCtrl = TextEditingController();
  final _capacitaCtrl = TextEditingController();
  final _kgCtrl = TextEditingController();
  final _giorniCtrl = TextEditingController();
  DateTime _dataInizio = DateTime.now();
  bool _saving = false;

  // Smielature attive (kg_residui > 0, archiviata=false), caricate da
  // /api/v1/smielature/?attive=true. Obbligatorie per i nuovi maturatori
  // perché ogni maturatore deve originare da una smielatura tracciabile.
  List<Map<String, dynamic>> _smielatureAttive = [];
  bool _loadingSmielature = true;
  int? _selectedSmielaturaId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nomeCtrl.text = e.nome;
      _tipoMieleCtrl.text = e.tipoMiele;
      _capacitaCtrl.text = e.capacitaKg.toString();
      _kgCtrl.text = e.kgAttuali.toString();
      _giorniCtrl.text = e.giorniMaturazione.toString();
      _dataInizio = DateTime.tryParse(e.dataInizio) ?? DateTime.now();
      _selectedSmielaturaId = e.smielatura;
    } else {
      _giorniCtrl.text = '21';
    }
    _loadSmielature();
  }

  Future<void> _loadSmielature() async {
    try {
      final res = await widget.apiService.get('${ApiConstants.produzioniUrl}?attive=true');
      final list = res is List
          ? res
          : (res is Map<String, dynamic> ? (res['results'] as List? ?? []) : []);
      if (!mounted) return;
      setState(() {
        _smielatureAttive = list.map((e) => e as Map<String, dynamic>).toList();
        _loadingSmielature = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSmielature = false);
    }
  }

  Map<String, dynamic>? get _selectedSmielatura {
    if (_selectedSmielaturaId == null) return null;
    for (final s in _smielatureAttive) {
      if (s['id'] == _selectedSmielaturaId) return s;
    }
    return null;
  }

  void _onSmielaturaSelected(int? id) {
    setState(() => _selectedSmielaturaId = id);
    final s = _selectedSmielatura;
    if (s == null) return;
    // Auto-prefill: tipo_miele dalla smielatura, kg suggeriti = residui
    if (_tipoMieleCtrl.text.trim().isEmpty) {
      _tipoMieleCtrl.text = (s['tipo_miele'] ?? '').toString();
      _onTipoMieleChanged(_tipoMieleCtrl.text);
    }
    final residui = double.tryParse(s['kg_residui']?.toString() ?? '');
    if (residui != null && _kgCtrl.text.trim().isEmpty) {
      _kgCtrl.text = residui.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose(); _tipoMieleCtrl.dispose(); _capacitaCtrl.dispose();
    _kgCtrl.dispose(); _giorniCtrl.dispose();
    super.dispose();
  }

  void _onTipoMieleChanged(String val) {
    final giorni = PreferenzaMaturazione.defaultForTipo(val);
    _giorniCtrl.text = giorni.toString();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.existing == null && _selectedSmielaturaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(Provider.of<LanguageService>(context, listen: false)
            .strings.aggiungiMaturatoreSelectSmielatura),
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final body = {
        'nome': _nomeCtrl.text.trim(),
        'tipo_miele': _tipoMieleCtrl.text.trim(),
        'capacita_kg': double.parse(_capacitaCtrl.text),
        'kg_attuali': double.parse(_kgCtrl.text),
        'giorni_maturazione': int.parse(_giorniCtrl.text),
        'data_inizio': _dataInizio.toIso8601String().split('T')[0],
        'stato': 'in_maturazione',
        if (_selectedSmielaturaId != null) 'smielatura': _selectedSmielaturaId,
      };
      if (widget.existing != null) {
        await widget.apiService.patch('${ApiConstants.maturatoriUrl}${widget.existing!.id}/', body);
      } else {
        await widget.apiService.post(ApiConstants.maturatoriUrl, body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Provider.of<LanguageService>(context, listen: false).strings.msgErrorGeneric(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    final isEditing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? s.aggiungiMaturatoreTitleEdit : s.aggiungiMaturatoreTitleNew,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Smielatura di origine — obbligatoria sui nuovi
              if (!isEditing) _buildSmielaturaPicker(s) else _buildSmielaturaReadonly(s),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nomeCtrl,
                decoration: InputDecoration(labelText: s.aggiungiMaturatoreHintNome, border: const OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? s.attrezzaturaFormValidateCampoObbligatorio : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tipoMieleCtrl,
                decoration: InputDecoration(labelText: s.aggiungiMaturatoreLblTipoMiele, border: const OutlineInputBorder()),
                onChanged: _onTipoMieleChanged,
                validator: (v) => v == null || v.isEmpty ? s.attrezzaturaFormValidateCampoObbligatorio : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capacitaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: s.aggiungiMaturatoreLblCapacita, border: const OutlineInputBorder(), suffixText: 'kg'),
                      validator: (v) => double.tryParse(v ?? '') == null ? s.attrezzaturaFormValidateNumero : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _kgCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: s.aggiungiMaturatoreLblKgAttuali, border: const OutlineInputBorder(), suffixText: 'kg'),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null) return s.attrezzaturaFormValidateNumero;
                        // Sanity: non superare i kg_residui della smielatura
                        // selezionata. Il backend rifiuta comunque, ma è UX
                        // migliore segnalarlo subito.
                        final residui = double.tryParse(_selectedSmielatura?['kg_residui']?.toString() ?? '');
                        if (!isEditing && residui != null && n > residui + 0.01) {
                          return s.aggiungiMaturatoreErrKgEccesso(residui.toStringAsFixed(2));
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _giorniCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: s.aggiungiMaturatoreLblGiorniMaturazione,
                        border: const OutlineInputBorder(),
                        suffixText: 'gg',
                        helperText: s.aggiungiMaturatoreHelperGiorni,
                      ),
                      validator: (v) => int.tryParse(v ?? '') == null ? s.attrezzaturaFormValidateNumero : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dataInizio,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) setState(() => _dataInizio = picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: s.aggiungiMaturatoreLblDataInizio, border: const OutlineInputBorder()),
                        child: Text(
                          '${_dataInizio.day.toString().padLeft(2, '0')}/${_dataInizio.month.toString().padLeft(2, '0')}/${_dataInizio.year}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEditing ? s.btnSave : s.btnAdd),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmielaturaPicker(s) {
    if (_loadingSmielature) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_smielatureAttive.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(s.aggiungiMaturatoreNoSmielatureAttive,
              style: TextStyle(color: Colors.orange.shade800))),
        ]),
      );
    }
    return DropdownButtonFormField<int>(
      value: _selectedSmielaturaId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: s.aggiungiMaturatoreLblSmielatura,
        border: const OutlineInputBorder(),
      ),
      items: _smielatureAttive.map((sm) {
        final residui = double.tryParse(sm['kg_residui']?.toString() ?? '0') ?? 0;
        final tipo = (sm['tipo_miele'] ?? '').toString();
        final apiario = (sm['apiario_nome'] ?? '').toString();
        final data = (sm['data'] ?? '').toString();
        return DropdownMenuItem<int>(
          value: sm['id'] as int?,
          child: Text(
            s.aggiungiMaturatoreSmielaturaItem(data, apiario, tipo, residui.toStringAsFixed(1)),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _onSmielaturaSelected,
      validator: (v) => v == null ? s.aggiungiMaturatoreSelectSmielatura : null,
    );
  }

  Widget _buildSmielaturaReadonly(s) {
    final info = widget.existing?.smielaturaInfo;
    if (info == null || info.isEmpty) return const SizedBox.shrink();
    return InputDecorator(
      decoration: InputDecoration(
        labelText: s.aggiungiMaturatoreLblSmielatura,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.lock, size: 18),
      ),
      child: Text(info, style: const TextStyle(fontSize: 14)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/api_constants.dart';
import '../../models/alimentazione.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

/// Form di creazione [Alimentazione] per una colonia.
///
/// Accetta `arguments: coloniaId` (int) per pre-selezione; altrimenti l'utente
/// sceglie tra le colonie accessibili.
class AlimentazioneFormScreen extends StatefulWidget {
  final int? coloniaId;
  const AlimentazioneFormScreen({Key? key, this.coloniaId}) : super(key: key);

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

  int? _coloniaId;
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
    _loadColonie();
  }

  @override
  void dispose() {
    _quantitaCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
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

  Future<void> _save() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final preselected = widget.coloniaId ?? (args is int ? args : null);
    final coloniaId = _coloniaId ?? preselected;

    if (!_formKey.currentState!.validate()) return;
    if (coloniaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona una colonia.')),
      );
      return;
    }
    final qta = double.tryParse(_quantitaCtrl.text.replaceAll(',', '.'));
    if (qta == null || qta <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci una quantità in kg > 0.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.post(ApiConstants.alimentazioniUrl, {
        'colonia': coloniaId,
        'data': _data.toIso8601String().split('T')[0],
        'tipo': _tipo,
        'scopo': _scopo ?? '',
        'quantita_kg': qta,
        if (_noteCtrl.text.trim().isNotEmpty) 'note': _noteCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alimentazione registrata.')),
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
    final args = ModalRoute.of(context)?.settings.arguments;
    final preselected = widget.coloniaId ?? (args is int ? args : null);
    return Scaffold(
      appBar: AppBar(title: const Text('Nuova alimentazione')),
      body: _loadingColonie
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (preselected == null) ...[
                      DropdownButtonFormField<int>(
                        value: _coloniaId,
                        decoration: const InputDecoration(
                          labelText: 'Colonia *',
                          border: OutlineInputBorder(),
                        ),
                        items: _colonie.map((c) {
                          final id = c['id'] as int;
                          final cont = c['contenitore']?.toString() ?? '—';
                          final apN = c['apiario_nome']?.toString() ?? '';
                          return DropdownMenuItem(
                            value: id,
                            child: Text('$cont · $apN'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _coloniaId = v),
                        validator: (v) =>
                            v == null ? 'Seleziona una colonia' : null,
                      ),
                      const SizedBox(height: 12),
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
                      decoration: const InputDecoration(
                        labelText: 'Quantità (kg) *',
                        border: OutlineInputBorder(),
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
                      icon: const Icon(Icons.save),
                      label: const Text('Salva'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

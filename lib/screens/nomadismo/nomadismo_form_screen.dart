import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

/// Form di registrazione di uno spostamento di nomadismo di una colonia.
class NomadismoFormScreen extends StatefulWidget {
  final int? coloniaId;
  const NomadismoFormScreen({Key? key, this.coloniaId}) : super(key: key);

  @override
  State<NomadismoFormScreen> createState() => _NomadismoFormScreenState();
}

class _NomadismoFormScreenState extends State<NomadismoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ApiService _api;
  bool _saving = false;
  bool _loading = true;

  List<Map<String, dynamic>> _colonie = [];
  List<Map<String, dynamic>> _apiari = [];

  int? _coloniaId;
  int? _apiarioOrigine;
  int? _apiarioDestinazione;
  DateTime _data = DateTime.now();
  final _motivoCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    _api = ApiService(auth);
    _load();
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.getAll(ApiConstants.colonieUrl),
        _api.getAll(ApiConstants.apiariUrl),
      ]);
      if (!mounted) return;
      setState(() {
        _colonie = results[0].map((e) => e as Map<String, dynamic>).toList();
        _apiari = results[1].map((e) => e as Map<String, dynamic>).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
    if (_apiarioDestinazione == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona apiario di destinazione.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.post(ApiConstants.nomadismiUrl, {
        'colonia': coloniaId,
        'apiario_origine': _apiarioOrigine,
        'apiario_destinazione': _apiarioDestinazione,
        'data_spostamento': _data.toIso8601String().split('T')[0],
        'motivo': _motivoCtrl.text.trim(),
        if (_noteCtrl.text.trim().isNotEmpty) 'note': _noteCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Spostamento registrato.')),
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
      appBar: AppBar(title: const Text('Nuovo spostamento')),
      body: _loading
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
                          final ap = c['apiario_nome']?.toString() ?? '';
                          return DropdownMenuItem(
                            value: id,
                            child: Text('$cont · $ap'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _coloniaId = v),
                        validator: (v) =>
                            v == null ? 'Seleziona una colonia' : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<int>(
                      value: _apiarioOrigine,
                      decoration: const InputDecoration(
                        labelText: 'Apiario di origine (opzionale)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                            value: null, child: Text('—')),
                        ..._apiari.map((a) => DropdownMenuItem(
                              value: a['id'] as int,
                              child: Text(a['nome']?.toString() ??
                                  'Apiario ${a["id"]}'),
                            )),
                      ],
                      onChanged: (v) => setState(() => _apiarioOrigine = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _apiarioDestinazione,
                      decoration: const InputDecoration(
                        labelText: 'Apiario di destinazione *',
                        border: OutlineInputBorder(),
                      ),
                      items: _apiari
                          .map((a) => DropdownMenuItem<int>(
                                value: a['id'] as int,
                                child: Text(a['nome']?.toString() ??
                                    'Apiario ${a["id"]}'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _apiarioDestinazione = v),
                      validator: (v) =>
                          v == null ? 'Seleziona destinazione' : null,
                    ),
                    const SizedBox(height: 12),
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
                          labelText: 'Data spostamento',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                            '${_data.day.toString().padLeft(2, '0')}/${_data.month.toString().padLeft(2, '0')}/${_data.year}'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _motivoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Motivo (es. fioritura acacia)',
                        border: OutlineInputBorder(),
                      ),
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

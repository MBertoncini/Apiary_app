import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/colonia.dart';
import '../../services/api_service.dart';
import '../../services/colonia_service.dart';
import '../../services/language_service.dart';

/// Form per insediare una nuova colonia in un'arnia.
class ColoniaFormScreen extends StatefulWidget {
  final int? arniaId;
  final int? nucleoId;

  const ColoniaFormScreen({Key? key, this.arniaId, this.nucleoId}) : super(key: key);

  @override
  State<ColoniaFormScreen> createState() => _ColoniaFormScreenState();
}

class _ColoniaFormScreenState extends State<ColoniaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dataCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
  }

  @override
  void dispose() {
    _dataCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final service = ColoniaService(api);
      final colonia = await service.creaColonia(
        arniaId:    widget.arniaId,
        nucleoId:   widget.nucleoId,
        dataInizio: _dataCtrl.text,
        note:       _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
      );
      if (colonia != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.coloniaFormCreatedOk)),
        );
        Navigator.of(context).pop(colonia);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.coloniaFormErrorSave)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.coloniaFormError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context).strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.coloniaFormTitle),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(s.btnSave, style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _dataCtrl,
              decoration: InputDecoration(
                labelText: s.coloniaFormLblData,
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                helperText: s.coloniaFormHintData,
              ),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(_dataCtrl.text) ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  _dataCtrl.text = picked.toIso8601String().substring(0, 10);
                }
              },
              validator: (v) =>
                  (v == null || v.isEmpty) ? s.coloniaFormValidateData : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: s.coloniaFormLblNote,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}


/// Form per chiudere il ciclo di vita di una colonia.
class ColoniaChiudiScreen extends StatefulWidget {
  final Colonia colonia;

  const ColoniaChiudiScreen({Key? key, required this.colonia}) : super(key: key);

  @override
  State<ColoniaChiudiScreen> createState() => _ColoniaChiudiScreenState();
}

class _ColoniaChiudiScreenState extends State<ColoniaChiudiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataCtrl    = TextEditingController();
  final _motivoCtrl  = TextEditingController();
  final _noteCtrl    = TextEditingController();
  bool _isLoading    = false;
  String _stato      = 'morta';

  static const _statoKeys = [
    'morta',
    'venduta',
    'sciamata',
    'unita',
    'nucleo',
    'eliminata',
  ];

  @override
  void initState() {
    super.initState();
    _dataCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
  }

  @override
  void dispose() {
    _dataCtrl.dispose();
    _motivoCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final service = ColoniaService(api);
      final updated = await service.chiudiColonia(
        widget.colonia.id,
        stato:      _stato,
        dataFine:   _dataCtrl.text,
        motivoFine: _motivoCtrl.text.isNotEmpty ? _motivoCtrl.text : null,
        noteFine:   _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
      );
      if (updated != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.coloniaChiusaOk)),
        );
        Navigator.of(context).pop(updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.coloniaChiudiError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DropdownMenuItem<String>> _buildStatoItems(dynamic s) {
    final labels = {
      'morta':     s.coloniaStatoMorta,
      'venduta':   s.coloniaStatoVenduta,
      'sciamata':  s.coloniaStatoSciamata,
      'unita':     s.coloniaStatoUnita,
      'nucleo':    s.coloniaStatoNucleo,
      'eliminata': s.coloniaStatoEliminata,
    };
    return _statoKeys
        .map((k) => DropdownMenuItem(value: k, child: Text(labels[k] ?? k)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context).strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.coloniaChiudiTitle(widget.colonia.id)),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
              label: Text(s.coloniaChiudiBtn, style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Warning card
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.coloniaChiudiWarning,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stato (motivo)
            DropdownButtonFormField<String>(
              value: _stato,
              decoration: InputDecoration(
                labelText: s.coloniaChiudiLblStato,
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: _buildStatoItems(s),
              onChanged: (v) => setState(() => _stato = v ?? _stato),
              validator: (v) => v == null ? s.coloniaChiudiValidateStato : null,
            ),
            const SizedBox(height: 16),

            // Data fine
            TextFormField(
              controller: _dataCtrl,
              decoration: InputDecoration(
                labelText: s.coloniaChiudiLblData,
                prefixIcon: const Icon(Icons.event_busy_outlined),
              ),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(_dataCtrl.text) ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) {
                  _dataCtrl.text = picked.toIso8601String().substring(0, 10);
                }
              },
              validator: (v) =>
                  (v == null || v.isEmpty) ? s.coloniaChiudiValidateData : null,
            ),
            const SizedBox(height: 16),

            // Motivo (testo libero)
            TextFormField(
              controller: _motivoCtrl,
              decoration: InputDecoration(
                labelText: s.coloniaChiudiLblMotivo,
                prefixIcon: const Icon(Icons.info_outline),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: s.coloniaChiudiLblNote,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

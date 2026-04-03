import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/colonia.dart';
import '../../services/api_service.dart';
import '../../services/colonia_service.dart';

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
          const SnackBar(content: Text('Colonia insediata con successo')),
        );
        Navigator.of(context).pop(colonia);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore durante il salvataggio')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insedia nuova colonia'),
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
              label: const Text('Salva', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Data inizio
            TextFormField(
              controller: _dataCtrl,
              decoration: const InputDecoration(
                labelText: 'Data insediamento *',
                prefixIcon: Icon(Icons.calendar_today_outlined),
                helperText: 'Formato: AAAA-MM-GG',
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
                  (v == null || v.isEmpty) ? 'Inserire la data' : null,
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note',
                prefixIcon: Icon(Icons.notes_outlined),
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

  static const _statoOptions = [
    ('morta',     'Colonia morta'),
    ('venduta',   'Ceduta / Venduta'),
    ('sciamata',  'Sciamata e non recuperata'),
    ('unita',     'Unita ad altra colonia'),
    ('nucleo',    'Ridotta a nucleo'),
    ('eliminata', 'Eliminata'),
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
          const SnackBar(content: Text('Ciclo di vita chiuso')),
        );
        Navigator.of(context).pop(updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chiudi Colonia #${widget.colonia.id}'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
              label: const Text('Chiudi', style: TextStyle(color: Colors.white)),
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
                        'Questa operazione chiude il ciclo di vita della colonia. '
                        'Tutti i dati storici (controlli, regina, melari) vengono conservati.',
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
              decoration: const InputDecoration(
                labelText: 'Motivo di fine *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _statoOptions
                  .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _stato = v ?? _stato),
              validator: (v) => v == null ? 'Selezionare un motivo' : null,
            ),
            const SizedBox(height: 16),

            // Data fine
            TextFormField(
              controller: _dataCtrl,
              decoration: const InputDecoration(
                labelText: 'Data di fine *',
                prefixIcon: Icon(Icons.event_busy_outlined),
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
                  (v == null || v.isEmpty) ? 'Inserire la data' : null,
            ),
            const SizedBox(height: 16),

            // Motivo (testo libero)
            TextFormField(
              controller: _motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrizione (opzionale)',
                prefixIcon: Icon(Icons.info_outline),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note aggiuntive',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/language_service.dart';
import '../../l10n/app_strings.dart';

class InvasettamentoFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  InvasettamentoFormScreen({this.initialData});
  @override
  _InvasettamentoFormScreenState createState() => _InvasettamentoFormScreenState();
}

class _InvasettamentoFormScreenState extends State<InvasettamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ApiService _apiService;
  late StorageService _storageService;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;
  bool _isLoading = false;
  bool _isLoadingData = true;

  List<Map<String, dynamic>> _smielature = [];

  int? _selectedSmielaturaId;
  DateTime _selectedDate = DateTime.now();
  final _tipoMieleController = TextEditingController();
  int _formatoVasetto = 500;
  final _numeroVasettiController = TextEditingController();
  final _lottoController = TextEditingController();
  final _noteController = TextEditingController();

  bool get _isEditing => widget.initialData != null;
  int? get _editId => widget.initialData?['id'];

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tipoMieleController.dispose();
    _numeroVasettiController.dispose();
    _lottoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // Mostra subito dalla cache
    final cached = await _storageService.getStoredData('smielature');
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _smielature = cached.map((e) => e as Map<String, dynamic>).toList();
        _isLoadingData = false;
      });
    }

    try {
      final smielatureResponse = await _apiService.get(ApiConstants.produzioniUrl);
      final smielatureList = smielatureResponse is List ? smielatureResponse : (smielatureResponse['results'] as List? ?? []);
      await _storageService.saveData('smielature', smielatureList);
      if (mounted) {
        setState(() {
          _smielature = smielatureList.map((e) => e as Map<String, dynamic>).toList();
          _isLoadingData = false;
        });
      }

      if (_isEditing) {
        final data = widget.initialData!;
        _selectedSmielaturaId = data['smielatura'];
        _selectedDate = DateTime.tryParse(data['data'] ?? '') ?? DateTime.now();
        _tipoMieleController.text = data['tipo_miele'] ?? '';
        _formatoVasetto = data['formato_vasetto'] ?? 500;
        _numeroVasettiController.text = data['numero_vasetti']?.toString() ?? '';
        _lottoController.text = data['lotto'] ?? '';
        _noteController.text = data['note'] ?? '';
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoadingData = false; });
      final isNetworkError = e is SocketException ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup');
      if (_smielature.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.smielaturaFormError(e.toString()))));
      } else if (isNetworkError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s.smielaturaFormOfflineMsg)),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) setState(() { _selectedDate = picked; });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSmielaturaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.invasettamentoFormValidateSmielatura)));
      return;
    }

    setState(() { _isLoading = true; });

    final data = {
      'smielatura': _selectedSmielaturaId,
      'data': _selectedDate.toIso8601String().split('T')[0],
      'tipo_miele': _tipoMieleController.text,
      'formato_vasetto': _formatoVasetto,
      'numero_vasetti': int.tryParse(_numeroVasettiController.text) ?? 0,
      'lotto': _lottoController.text.isEmpty ? null : _lottoController.text,
      'note': _noteController.text.isEmpty ? null : _noteController.text,
    };

    try {
      if (_isEditing) {
        await _apiService.put('${ApiConstants.invasettamentiUrl}$_editId/', data);
      } else {
        await _apiService.post(ApiConstants.invasettamentiUrl, data);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? _s.invasettamentoFormUpdatedOk : _s.invasettamentoFormCreatedOk)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.smielaturaFormError(e.toString()))));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? s.invasettamentoFormTitleEdit : s.invasettamentoFormTitleNew)),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Smielatura dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedSmielaturaId,
                      decoration: InputDecoration(labelText: s.invasettamentoFormLblSmielatura, border: const OutlineInputBorder()),
                      items: _smielature.map((sm) => DropdownMenuItem<int>(
                        value: sm['id'],
                        child: Text('${sm['data']} - ${sm['apiario_nome']} (${sm['quantita_miele']}kg)'),
                      )).toList(),
                      onChanged: (val) {
                        setState(() { _selectedSmielaturaId = val; });
                        // Auto-fill tipo_miele from smielatura
                        if (val != null) {
                          final smielatura = _smielature.firstWhere((sm) => sm['id'] == val);
                          if (_tipoMieleController.text.isEmpty) {
                            _tipoMieleController.text = smielatura['tipo_miele'] ?? '';
                          }
                        }
                      },
                      validator: (val) => val == null ? s.invasettamentoFormValidateSmielatura : null,
                    ),
                    const SizedBox(height: 16),

                    // Date
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: '${s.labelDate} *', border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today)),
                        child: Text('${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tipo miele
                    TextFormField(
                      controller: _tipoMieleController,
                      decoration: InputDecoration(labelText: s.smielaturaFormLblTipoMiele, border: const OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? s.trattamentoFormValidateCampoObbligatorio : null,
                    ),
                    const SizedBox(height: 16),

                    // Formato vasetto
                    DropdownButtonFormField<int>(
                      value: _formatoVasetto,
                      decoration: InputDecoration(labelText: s.invasettamentoFormLblFormato, border: const OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 250, child: Text('250g')),
                        DropdownMenuItem(value: 500, child: Text('500g')),
                        DropdownMenuItem(value: 1000, child: Text('1000g')),
                      ],
                      onChanged: (val) => setState(() { _formatoVasetto = val ?? 500; }),
                    ),
                    const SizedBox(height: 16),

                    // Numero vasetti
                    TextFormField(
                      controller: _numeroVasettiController,
                      decoration: InputDecoration(labelText: s.invasettamentoFormLblNumVasetti, border: const OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return s.trattamentoFormValidateCampoObbligatorio;
                        if (int.tryParse(val) == null) return s.invasettamentoFormValidateNumVasetti;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Calculated kg
                    Builder(builder: (ctx) {
                      final n = int.tryParse(_numeroVasettiController.text) ?? 0;
                      final kg = (_formatoVasetto * n) / 1000;
                      return Card(
                        color: Colors.amber.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(s.invasettamentoFormLblTotale(kg.toStringAsFixed(2)), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Lotto
                    TextFormField(
                      controller: _lottoController,
                      decoration: InputDecoration(labelText: s.invasettamentoFormLblLotto, border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    // Note
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(labelText: s.smielaturaFormLblNote, border: const OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isEditing ? s.smielaturaFormBtnUpdate : s.smielaturaFormBtnCreate),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

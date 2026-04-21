import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/language_service.dart';
import '../../l10n/app_strings.dart';

class SmielaturaFormScreen extends StatefulWidget {
  final dynamic initialData; // null for new, Map for edit, int for apiarioId pre-selection
  SmielaturaFormScreen({this.initialData});
  @override
  _SmielaturaFormScreenState createState() => _SmielaturaFormScreenState();
}

class _SmielaturaFormScreenState extends State<SmielaturaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ApiService _apiService;
  late StorageService _storageService;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;
  bool _isLoading = false;
  bool _isLoadingData = true;

  List<Map<String, dynamic>> _apiari = [];
  List<Map<String, dynamic>> _melari = [];

  int? _selectedApiarioId;
  DateTime _selectedDate = DateTime.now();
  final _tipoMieleController = TextEditingController();
  final _quantitaController = TextEditingController();
  final _noteController = TextEditingController();
  List<int> _selectedMelariIds = [];

  bool get _isEditing => widget.initialData is Map<String, dynamic>;
  int? get _editId => _isEditing ? (widget.initialData as Map<String, dynamic>)['id'] : null;

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
    _quantitaController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // Mostra subito dalla cache
    final cachedApiari = await _storageService.getStoredData('apiari');
    final cachedMelari = await _storageService.getStoredData('melari');
    if ((cachedApiari.isNotEmpty || cachedMelari.isNotEmpty) && mounted) {
      setState(() {
        if (cachedApiari.isNotEmpty) _apiari = cachedApiari.map((e) => e as Map<String, dynamic>).toList();
        if (cachedMelari.isNotEmpty) _melari = cachedMelari.map((e) => e as Map<String, dynamic>).toList();
        _isLoadingData = false;
      });
    }

    try {
      final results = await Future.wait([
        _apiService.get(ApiConstants.apiariUrl),
        _apiService.get(ApiConstants.melariUrl),
      ]);
      final apiariList = results[0] is List ? results[0] : (results[0]['results'] as List? ?? []);
      final melariList = results[1] is List ? results[1] : (results[1]['results'] as List? ?? []);

      await Future.wait([
        _storageService.saveData('apiari', apiariList),
        _storageService.saveData('melari', melariList),
      ]);

      if (mounted) {
        setState(() {
          _apiari = apiariList.map((e) => e as Map<String, dynamic>).toList();
          _melari = melariList.map((e) => e as Map<String, dynamic>).toList();
          _isLoadingData = false;
        });
      }

      if (_isEditing) {
        final data = widget.initialData as Map<String, dynamic>;
        _selectedApiarioId = data['apiario'];
        _selectedDate = DateTime.tryParse(data['data'] ?? '') ?? DateTime.now();
        _tipoMieleController.text = data['tipo_miele'] ?? '';
        _quantitaController.text = data['quantita_miele']?.toString() ?? '';
        _noteController.text = data['note'] ?? '';
        _selectedMelariIds = (data['melari'] as List?)?.map((e) => e as int).toList() ?? [];
      } else if (widget.initialData is int) {
        _selectedApiarioId = widget.initialData as int;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoadingData = false; });
      final isNetworkError = e is SocketException ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup');
      if (_apiari.isEmpty && _melari.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.smielaturaFormError(e.toString()))));
      } else if (isNetworkError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s.smielaturaFormOfflineMsg)),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredMelari {
    if (_selectedApiarioId == null) return [];
    return _melari.where((m) {
      final apiarioId = m['apiario_id'];
      final stato = m['stato'] as String?;
      return apiarioId == _selectedApiarioId && stato == 'in_smielatura';
    }).toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedApiarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.smielaturaFormSelectApiarioMsg)));
      return;
    }
    if (_selectedMelariIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.smielaturaFormSelectMelarioMsg)));
      return;
    }

    setState(() { _isLoading = true; });

    final data = {
      'apiario': _selectedApiarioId,
      'data': _selectedDate.toIso8601String().split('T')[0],
      'tipo_miele': _tipoMieleController.text,
      'quantita_miele': _quantitaController.text,
      'melari': _selectedMelariIds,
      'note': _noteController.text.isEmpty ? null : _noteController.text,
    };

    try {
      if (_isEditing) {
        await _apiService.put('${ApiConstants.produzioniUrl}$_editId/', data);
      } else {
        final result = await _apiService.post(ApiConstants.produzioniUrl, data);
        if (result != null && result['id'] != null) {
          final apiarioData = _apiari.firstWhere(
            (a) => a['id'] == _selectedApiarioId,
            orElse: () => <String, dynamic>{},
          );
          NotificationService().scheduleMaturazioneMieleReminder(
            smielaturaId: result['id'] as int,
            tipoMiele: _tipoMieleController.text.isNotEmpty
                ? _tipoMieleController.text
                : 'millefiori',
            apiarioNome: (apiarioData['nome'] as String?) ?? '',
            dataSmielatura: _selectedDate,
          );
          // Marca tutti i melari smielati come 'rimosso' così non appaiono più nel form
          final oggi = _selectedDate.toIso8601String().split('T')[0];
          await Future.wait(_selectedMelariIds.map((id) => _apiService.patch(
            '${ApiConstants.melariUrl}$id/',
            {'stato': 'rimosso', 'data_rimozione': oggi},
          )));
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? _s.smielaturaFormUpdatedOk : _s.smielaturaFormCreatedOk)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.smielaturaFormError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
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

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? s.smielaturaFormTitleEdit : s.smielaturaFormTitleNew)),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Apiario dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedApiarioId,
                      decoration: InputDecoration(labelText: s.smielaturaFormLblApiario, border: const OutlineInputBorder()),
                      items: _apiari
                          .map((a) => DropdownMenuItem<int>(
                                value: a['id'] as int?,
                                child: Text(a['nome']?.toString() ?? '${s.labelApiario} ${a["id"]}'),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() {
                        _selectedApiarioId = val;
                        _selectedMelariIds.clear();
                      }),
                      validator: (val) => val == null ? s.smielaturaFormSelectApiarioMsg : null,
                    ),
                    const SizedBox(height: 16),

                    // Date picker
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: s.smielaturaFormLblData, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today)),
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

                    // Quantita
                    TextFormField(
                      controller: _quantitaController,
                      decoration: InputDecoration(labelText: s.smielaturaFormLblQuantita, border: const OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.isEmpty) return s.trattamentoFormValidateCampoObbligatorio;
                        final parsed = double.tryParse(val);
                        if (parsed == null) return s.smielaturaFormValidateNumero;
                        if (parsed >= 100000) return s.smielaturaFormValidateQuantitaMax;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Melari checkboxes
                    if (_selectedApiarioId != null && _filteredMelari.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(s.smielaturaFormNoMelariDisp, style: TextStyle(color: Colors.orange.shade800))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_filteredMelari.isNotEmpty) ...[
                      Text(s.smielaturaFormLblMelariDisp, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._filteredMelari.map((m) {
                        final id = m['id'] as int;
                        return CheckboxListTile(
                          title: Text(s.smielaturaFormMelarioItem(id, m['arnia_numero']?.toString() ?? '')),
                          subtitle: Text(s.smielaturaFormMelarioStato(m['stato']?.toString() ?? '')),
                          value: _selectedMelariIds.contains(id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) { _selectedMelariIds.add(id); }
                              else { _selectedMelariIds.remove(id); }
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // Note
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(labelText: s.smielaturaFormLblNote, border: const OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Submit
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

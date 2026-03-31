import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';

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
      if (_apiari.isEmpty && _melari.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore caricamento dati: $e')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Modalità offline — dati aggiornati all\'ultimo accesso')),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seleziona un apiario')));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Smielatura aggiornata' : 'Smielatura registrata')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
    } finally {
      setState(() { _isLoading = false; });
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Modifica Smielatura' : 'Nuova Smielatura')),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Apiario dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedApiarioId,
                      decoration: InputDecoration(labelText: 'Apiario *', border: OutlineInputBorder()),
                      items: _apiari.map((a) => DropdownMenuItem<int>(value: a['id'], child: Text(a['nome']))).toList(),
                      onChanged: (val) => setState(() {
                        _selectedApiarioId = val;
                        _selectedMelariIds.clear();
                      }),
                      validator: (val) => val == null ? 'Seleziona un apiario' : null,
                    ),
                    SizedBox(height: 16),

                    // Date picker
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: 'Data *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                        child: Text('${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}'),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Tipo miele
                    TextFormField(
                      controller: _tipoMieleController,
                      decoration: InputDecoration(labelText: 'Tipo miele *', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Campo obbligatorio' : null,
                    ),
                    SizedBox(height: 16),

                    // Quantita
                    TextFormField(
                      controller: _quantitaController,
                      decoration: InputDecoration(labelText: 'Quantità miele (kg) *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Campo obbligatorio';
                        if (double.tryParse(val) == null) return 'Inserisci un numero valido';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Melari checkboxes
                    if (_filteredMelari.isNotEmpty) ...[
                      Text('Melari disponibili', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ..._filteredMelari.map((m) {
                        final id = m['id'] as int;
                        return CheckboxListTile(
                          title: Text('Melario #$id - Arnia ${m['arnia_numero']}'),
                          subtitle: Text('Stato: ${m['stato']}'),
                          value: _selectedMelariIds.contains(id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) { _selectedMelariIds.add(id); }
                              else { _selectedMelariIds.remove(id); }
                            });
                          },
                        );
                      }),
                      SizedBox(height: 16),
                    ],

                    // Note
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    SizedBox(height: 24),

                    // Submit
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isEditing ? 'AGGIORNA' : 'REGISTRA'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class InvasettamentoFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  InvasettamentoFormScreen({this.initialData});
  @override
  _InvasettamentoFormScreenState createState() => _InvasettamentoFormScreenState();
}

class _InvasettamentoFormScreenState extends State<InvasettamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ApiService _apiService;
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
    try {
      final smielatureResponse = await _apiService.get(ApiConstants.produzioniUrl);
      setState(() {
        _smielature = (smielatureResponse as List).map((e) => e as Map<String, dynamic>).toList();
        _isLoadingData = false;
      });

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
      setState(() { _isLoadingData = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore caricamento: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seleziona una smielatura')));
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
        SnackBar(content: Text(_isEditing ? 'Invasettamento aggiornato' : 'Invasettamento registrato')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Modifica Invasettamento' : 'Nuovo Invasettamento')),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Smielatura dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedSmielaturaId,
                      decoration: InputDecoration(labelText: 'Smielatura *', border: OutlineInputBorder()),
                      items: _smielature.map((s) => DropdownMenuItem<int>(
                        value: s['id'],
                        child: Text('${s['data']} - ${s['apiario_nome']} (${s['quantita_miele']}kg)'),
                      )).toList(),
                      onChanged: (val) {
                        setState(() { _selectedSmielaturaId = val; });
                        // Auto-fill tipo_miele from smielatura
                        if (val != null) {
                          final smielatura = _smielature.firstWhere((s) => s['id'] == val);
                          if (_tipoMieleController.text.isEmpty) {
                            _tipoMieleController.text = smielatura['tipo_miele'] ?? '';
                          }
                        }
                      },
                      validator: (val) => val == null ? 'Seleziona una smielatura' : null,
                    ),
                    SizedBox(height: 16),

                    // Date
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

                    // Formato vasetto
                    DropdownButtonFormField<int>(
                      value: _formatoVasetto,
                      decoration: InputDecoration(labelText: 'Formato vasetto *', border: OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(value: 250, child: Text('250g')),
                        DropdownMenuItem(value: 500, child: Text('500g')),
                        DropdownMenuItem(value: 1000, child: Text('1000g')),
                      ],
                      onChanged: (val) => setState(() { _formatoVasetto = val ?? 500; }),
                    ),
                    SizedBox(height: 16),

                    // Numero vasetti
                    TextFormField(
                      controller: _numeroVasettiController,
                      decoration: InputDecoration(labelText: 'Numero vasetti *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Campo obbligatorio';
                        if (int.tryParse(val) == null) return 'Inserisci un numero intero';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Calculated kg
                    Builder(builder: (context) {
                      final n = int.tryParse(_numeroVasettiController.text) ?? 0;
                      final kg = (_formatoVasetto * n) / 1000;
                      return Card(
                        color: Colors.amber.shade50,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Totale: ${kg.toStringAsFixed(2)} kg', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }),
                    SizedBox(height: 16),

                    // Lotto
                    TextFormField(
                      controller: _lottoController,
                      decoration: InputDecoration(labelText: 'Lotto', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 16),

                    // Note
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    SizedBox(height: 24),

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

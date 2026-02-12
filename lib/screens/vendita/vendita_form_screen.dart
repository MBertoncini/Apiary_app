import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/cliente.dart';

class VenditaFormScreen extends StatefulWidget {
  final int? venditaId;
  VenditaFormScreen({this.venditaId});
  @override
  _VenditaFormScreenState createState() => _VenditaFormScreenState();
}

class _DettaglioItem {
  final tipoMieleController = TextEditingController();
  int formatoVasetto = 500;
  final quantitaController = TextEditingController();
  final prezzoController = TextEditingController();

  void dispose() {
    tipoMieleController.dispose();
    quantitaController.dispose();
    prezzoController.dispose();
  }

  double get subtotale {
    final q = int.tryParse(quantitaController.text) ?? 0;
    final p = double.tryParse(prezzoController.text) ?? 0;
    return q * p;
  }
}

class _VenditaFormScreenState extends State<VenditaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ApiService _apiService;
  bool _isLoading = false;
  bool _isLoadingData = true;

  List<Cliente> _clienti = [];
  int? _selectedClienteId;
  DateTime _selectedDate = DateTime.now();
  final _noteController = TextEditingController();
  List<_DettaglioItem> _dettagli = [_DettaglioItem()];

  bool get _isEditing => widget.venditaId != null;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _loadInitialData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final d in _dettagli) d.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final clientiRes = await _apiService.get(ApiConstants.clientiUrl);
      setState(() {
        _clienti = (clientiRes as List).map((e) => Cliente.fromJson(e)).toList();
      });

      if (_isEditing) {
        final data = await _apiService.get('${ApiConstants.venditeUrl}${widget.venditaId}/');
        _selectedClienteId = data['cliente'];
        _selectedDate = DateTime.tryParse(data['data'] ?? '') ?? DateTime.now();
        _noteController.text = data['note'] ?? '';

        final dettagliList = data['dettagli'] as List? ?? [];
        if (dettagliList.isNotEmpty) {
          _dettagli = dettagliList.map((d) {
            final item = _DettaglioItem();
            item.tipoMieleController.text = d['tipo_miele'] ?? '';
            item.formatoVasetto = d['formato_vasetto'] ?? 500;
            item.quantitaController.text = d['quantita']?.toString() ?? '';
            item.prezzoController.text = d['prezzo_unitario']?.toString() ?? '';
            return item;
          }).toList();
        }
      }

      setState(() { _isLoadingData = false; });
    } catch (e) {
      setState(() { _isLoadingData = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }

  double get _totale => _dettagli.fold(0, (sum, d) => sum + d.subtotale);

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _selectedDate,
      firstDate: DateTime(2020), lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) setState(() { _selectedDate = picked; });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seleziona un cliente')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final venditaData = {
        'data': _selectedDate.toIso8601String().split('T')[0],
        'cliente': _selectedClienteId,
        'note': _noteController.text.isEmpty ? null : _noteController.text,
      };

      dynamic result;
      if (_isEditing) {
        result = await _apiService.put('${ApiConstants.venditeUrl}${widget.venditaId}/', venditaData);
      } else {
        result = await _apiService.post(ApiConstants.venditeUrl, venditaData);
      }

      final venditaId = result['id'];

      // Save dettagli
      for (final d in _dettagli) {
        final dettaglioData = {
          'tipo_miele': d.tipoMieleController.text,
          'formato_vasetto': d.formatoVasetto,
          'quantita': int.tryParse(d.quantitaController.text) ?? 0,
          'prezzo_unitario': d.prezzoController.text,
        };
        await _apiService.post('${ApiConstants.venditeUrl}$venditaId/aggiungi_dettaglio/', dettaglioData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Vendita aggiornata' : 'Vendita registrata')),
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
      appBar: AppBar(title: Text(_isEditing ? 'Modifica Vendita' : 'Nuova Vendita')),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedClienteId,
                      decoration: InputDecoration(labelText: 'Cliente *', border: OutlineInputBorder()),
                      items: _clienti.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.nome))).toList(),
                      onChanged: (val) => setState(() { _selectedClienteId = val; }),
                      validator: (val) => val == null ? 'Seleziona un cliente' : null,
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: 'Data *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                        child: Text('${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}'),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('Articoli', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ...List.generate(_dettagli.length, (i) => _buildDettaglioCard(i)),
                    SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Aggiungi articolo'),
                      onPressed: () => setState(() { _dettagli.add(_DettaglioItem()); }),
                    ),
                    SizedBox(height: 16),
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Totale: ${_totale.toStringAsFixed(2)} \u20AC', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(height: 16),
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

  Widget _buildDettaglioCard(int index) {
    final d = _dettagli[index];
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Articolo ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold))),
                if (_dettagli.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => setState(() { _dettagli[index].dispose(); _dettagli.removeAt(index); }),
                  ),
              ],
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: d.tipoMieleController,
              decoration: InputDecoration(labelText: 'Tipo miele *', border: OutlineInputBorder(), isDense: true),
              validator: (val) => val == null || val.isEmpty ? 'Obbligatorio' : null,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: d.formatoVasetto,
                    decoration: InputDecoration(labelText: 'Formato', border: OutlineInputBorder(), isDense: true),
                    items: [
                      DropdownMenuItem(value: 250, child: Text('250g')),
                      DropdownMenuItem(value: 500, child: Text('500g')),
                      DropdownMenuItem(value: 1000, child: Text('1000g')),
                    ],
                    onChanged: (val) => setState(() { d.formatoVasetto = val ?? 500; }),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: d.quantitaController,
                    decoration: InputDecoration(labelText: 'Qty *', border: OutlineInputBorder(), isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (val) => val == null || val.isEmpty ? 'Obbligatorio' : null,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: d.prezzoController,
                    decoration: InputDecoration(labelText: 'Prezzo \u20AC *', border: OutlineInputBorder(), isDense: true),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    validator: (val) => val == null || val.isEmpty ? 'Obbligatorio' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Subtotale: ${d.subtotale.toStringAsFixed(2)} \u20AC', style: TextStyle(color: Colors.grey[600])),
            ),
          ],
        ),
      ),
    );
  }
}

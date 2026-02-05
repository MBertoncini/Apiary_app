// lib/screens/attrezzatura/spesa_attrezzatura_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/spesa_attrezzatura.dart';
import '../../services/attrezzatura_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_widget.dart';

class SpesaAttrezzaturaFormScreen extends StatefulWidget {
  final int attrezzaturaId;
  final String? attrezzaturaNome;
  final bool condivisoConGruppo;
  final int? gruppoId;

  SpesaAttrezzaturaFormScreen({
    required this.attrezzaturaId,
    this.attrezzaturaNome,
    this.condivisoConGruppo = false,
    this.gruppoId,
  });

  @override
  _SpesaAttrezzaturaFormScreenState createState() => _SpesaAttrezzaturaFormScreenState();
}

class _SpesaAttrezzaturaFormScreenState extends State<SpesaAttrezzaturaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descrizioneController = TextEditingController();
  final _importoController = TextEditingController();
  final _fornitoreController = TextEditingController();
  final _numeroFatturaController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedTipo = 'altro';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descrizioneController.dispose();
    _importoController.dispose();
    _fornitoreController.dispose();
    _numeroFatturaController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveSpesa() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final service = AttrezzaturaService(apiService);
      final auth = Provider.of<AuthService>(context, listen: false);

      final importo = double.parse(_importoController.text.replaceAll(',', '.'));
      final dataStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final data = {
        'attrezzatura': widget.attrezzaturaId,
        'tipo': _selectedTipo,
        'descrizione': _descrizioneController.text,
        'importo': importo,
        'data': dataStr,
        'gruppo': widget.condivisoConGruppo ? widget.gruppoId : null,
        'fornitore': _fornitoreController.text.isNotEmpty ? _fornitoreController.text : null,
        'numero_fattura': _numeroFatturaController.text.isNotEmpty ? _numeroFatturaController.text : null,
        'note': _noteController.text.isNotEmpty ? _noteController.text : null,
      };

      // Crea la spesa - questo creerà automaticamente il Pagamento
      await service.createSpesaAttrezzatura(
        data,
        userId: auth.currentUser!.id,
        attrezzaturaNome: widget.attrezzaturaNome ?? 'Attrezzatura',
        condivisoConGruppo: widget.condivisoConGruppo,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Spesa registrata e pagamento creato automaticamente'),
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore durante il salvataggio: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatDate = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Nuova Spesa'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info attrezzatura
              if (widget.attrezzaturaNome != null)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.build, color: Colors.blue),
                    title: Text('Attrezzatura'),
                    subtitle: Text(widget.attrezzaturaNome!),
                  ),
                ),
              const SizedBox(height: 16),

              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Tipo spesa
              DropdownButtonFormField<String>(
                value: _selectedTipo,
                decoration: InputDecoration(
                  labelText: 'Tipo Spesa *',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: SpesaAttrezzatura.tipiSpesa.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(_getTipoDisplayName(tipo)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedTipo = value!);
                },
              ),
              const SizedBox(height: 16),

              // Descrizione
              TextFormField(
                controller: _descrizioneController,
                decoration: InputDecoration(
                  labelText: 'Descrizione *',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  hintText: 'Es: Riparazione pompa, Sostituzione filtro...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci una descrizione';
                  }
                  return null;
                },
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Importo
              TextFormField(
                controller: _importoController,
                decoration: InputDecoration(
                  labelText: 'Importo (€) *',
                  prefixIcon: Icon(Icons.euro),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci l\'importo';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Inserisci un importo valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Data
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Data',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(formatDate.format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Fornitore
              TextFormField(
                controller: _fornitoreController,
                decoration: InputDecoration(
                  labelText: 'Fornitore',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
                  hintText: 'Es: Nome fornitore',
                ),
              ),
              const SizedBox(height: 16),

              // Numero Fattura
              TextFormField(
                controller: _numeroFatturaController,
                decoration: InputDecoration(
                  labelText: 'Numero Fattura',
                  prefixIcon: Icon(Icons.receipt_long),
                  border: OutlineInputBorder(),
                  hintText: 'Es: FT-2024-001',
                ),
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (opzionale)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Info pagamento automatico
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Verrà creato automaticamente un pagamento per questa spesa.',
                          style: TextStyle(color: Colors.blue[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (widget.condivisoConGruppo)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Card(
                    color: Colors.green.withOpacity(0.1),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.group, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Questa spesa sarà condivisa con il gruppo.',
                              style: TextStyle(color: Colors.green[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Pulsante salva
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSpesa,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'REGISTRA SPESA',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTipoDisplayName(String tipo) {
    switch (tipo) {
      case 'acquisto':
        return 'Acquisto';
      case 'manutenzione':
        return 'Manutenzione';
      case 'riparazione':
        return 'Riparazione';
      case 'accessori':
        return 'Accessori';
      case 'consumabili':
        return 'Consumabili';
      case 'altro':
        return 'Altro';
      default:
        return tipo;
    }
  }
}

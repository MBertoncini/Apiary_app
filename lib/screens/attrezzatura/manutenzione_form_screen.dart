// lib/screens/attrezzatura/manutenzione_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/manutenzione.dart';
import '../../services/attrezzatura_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class ManutenzioneFormScreen extends StatefulWidget {
  final int attrezzaturaId;
  final String? attrezzaturaNome;
  final bool condivisoConGruppo;
  final int? gruppoId;

  ManutenzioneFormScreen({
    required this.attrezzaturaId,
    this.attrezzaturaNome,
    this.condivisoConGruppo = false,
    this.gruppoId,
  });

  @override
  _ManutenzioneFormScreenState createState() => _ManutenzioneFormScreenState();
}

class _ManutenzioneFormScreenState extends State<ManutenzioneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descrizioneController = TextEditingController();
  final _costoController = TextEditingController();
  final _noteController = TextEditingController();
  final _eseguitoDaController = TextEditingController();

  String _selectedTipo = 'ordinaria';
  String _selectedStato = 'programmata';
  DateTime? _dataProgrammata;
  DateTime? _dataEsecuzione;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dataProgrammata = DateTime.now().add(Duration(days: 7)); // Default: tra una settimana
  }

  DateTime? _prossimaManutenzione;

  @override
  void dispose() {
    _descrizioneController.dispose();
    _costoController.dispose();
    _noteController.dispose();
    _eseguitoDaController.dispose();
    super.dispose();
  }

  Future<void> _selectDataProgrammata(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataProgrammata ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _dataProgrammata = picked;
      });
    }
  }

  Future<void> _selectDataEsecuzione(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataEsecuzione ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dataEsecuzione = picked;
      });
    }
  }

  Future<void> _saveManutenzione() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validazione date
    if (_selectedStato == 'programmata' && _dataProgrammata == null) {
      setState(() {
        _errorMessage = 'Seleziona la data programmata';
      });
      return;
    }
    if (_selectedStato == 'completata' && _dataEsecuzione == null) {
      setState(() {
        _errorMessage = 'Seleziona la data di esecuzione';
      });
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

      final costo = _costoController.text.isNotEmpty
          ? double.tryParse(_costoController.text.replaceAll(',', '.'))
          : null;

      final data = {
        'attrezzatura': widget.attrezzaturaId,
        'tipo': _selectedTipo,
        'descrizione': _descrizioneController.text,
        'costo': costo,
        'data_programmata': _dataProgrammata != null
            ? DateFormat('yyyy-MM-dd').format(_dataProgrammata!)
            : DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'data_esecuzione': _dataEsecuzione != null
            ? DateFormat('yyyy-MM-dd').format(_dataEsecuzione!)
            : null,
        'stato': _selectedStato,
        'gruppo': widget.condivisoConGruppo ? widget.gruppoId : null,
        'eseguito_da': _eseguitoDaController.text.isNotEmpty
            ? _eseguitoDaController.text
            : null,
        'prossima_manutenzione': _prossimaManutenzione != null
            ? DateFormat('yyyy-MM-dd').format(_prossimaManutenzione!)
            : null,
        'note': _noteController.text.isNotEmpty ? _noteController.text : null,
      };

      // Crea la manutenzione - questo creerà automaticamente SpesaAttrezzatura e Pagamento
      // se costo > 0
      await service.createManutenzione(
        data,
        userId: auth.currentUser!.id,
        attrezzaturaNome: widget.attrezzaturaNome ?? 'Attrezzatura',
        condivisoConGruppo: widget.condivisoConGruppo,
      );

      String message = 'Manutenzione registrata con successo';
      if (costo != null && costo > 0) {
        message += '\nPagamento registrato automaticamente';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
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
        title: Text('Nuova Manutenzione'),
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
              SizedBox(height: 16),

              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Tipo manutenzione
              DropdownButtonFormField<String>(
                value: _selectedTipo,
                decoration: InputDecoration(
                  labelText: 'Tipo Manutenzione *',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: Manutenzione.tipiManutenzione.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(_getTipoDisplayName(tipo)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedTipo = value!);
                },
              ),
              SizedBox(height: 16),

              // Stato
              DropdownButtonFormField<String>(
                value: _selectedStato,
                decoration: InputDecoration(
                  labelText: 'Stato *',
                  prefixIcon: Icon(Icons.info),
                  border: OutlineInputBorder(),
                ),
                items: Manutenzione.statiManutenzione
                    .where((s) => s != 'annullata') // Non mostrare annullata in creazione
                    .map((stato) {
                  return DropdownMenuItem(
                    value: stato,
                    child: Text(_getStatoDisplayName(stato)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStato = value!;
                    // Reset date in base allo stato
                    if (value == 'completata' && _dataEsecuzione == null) {
                      _dataEsecuzione = DateTime.now();
                    }
                  });
                },
              ),
              SizedBox(height: 16),

              // Descrizione (required in Django)
              TextFormField(
                controller: _descrizioneController,
                decoration: InputDecoration(
                  labelText: 'Descrizione *',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  hintText: 'Es: Sostituzione parti usurate, Pulizia generale...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci una descrizione';
                  }
                  return null;
                },
                maxLines: 2,
              ),
              SizedBox(height: 16),

              // Data programmata (required in Django)
              InkWell(
                onTap: () => _selectDataProgrammata(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Data Programmata *',
                    prefixIcon: Icon(Icons.event),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _dataProgrammata != null
                        ? formatDate.format(_dataProgrammata!)
                        : 'Seleziona data',
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Data esecuzione (se stato = completata o in_corso)
              if (_selectedStato == 'completata' || _selectedStato == 'in_corso')
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => _selectDataEsecuzione(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: _selectedStato == 'completata'
                            ? 'Data Esecuzione *'
                            : 'Data Esecuzione',
                        prefixIcon: Icon(Icons.check_circle),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _dataEsecuzione != null
                            ? formatDate.format(_dataEsecuzione!)
                            : 'Seleziona data',
                      ),
                    ),
                  ),
                ),

              // Costo
              TextFormField(
                controller: _costoController,
                decoration: InputDecoration(
                  labelText: 'Costo (€)',
                  prefixIcon: Icon(Icons.euro),
                  border: OutlineInputBorder(),
                  helperText: 'Se inserisci un costo, verrà creato automaticamente un pagamento',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value.replaceAll(',', '.')) == null) {
                      return 'Inserisci un importo valido';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Eseguito da
              TextFormField(
                controller: _eseguitoDaController,
                decoration: InputDecoration(
                  labelText: 'Eseguito da',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  hintText: 'Nome di chi ha eseguito la manutenzione',
                ),
              ),
              SizedBox(height: 16),

              // Prossima manutenzione
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _prossimaManutenzione ?? DateTime.now().add(Duration(days: 90)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setState(() => _prossimaManutenzione = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Prossima Manutenzione',
                    prefixIcon: Icon(Icons.event_repeat),
                    border: OutlineInputBorder(),
                    suffixIcon: _prossimaManutenzione != null
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () => setState(() => _prossimaManutenzione = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _prossimaManutenzione != null
                        ? formatDate.format(_prossimaManutenzione!)
                        : 'Non programmata',
                  ),
                ),
              ),
              SizedBox(height: 16),

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
              SizedBox(height: 24),

              // Info pagamento automatico
              if (_costoController.text.isNotEmpty)
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
                            'Verrà creato automaticamente un pagamento e una spesa per questa manutenzione.',
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
                              'Questa manutenzione sarà condivisa con il gruppo.',
                              style: TextStyle(color: Colors.green[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 24),

              // Pulsante salva
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveManutenzione,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _selectedStato == 'programmata'
                              ? 'PROGRAMMA MANUTENZIONE'
                              : 'REGISTRA MANUTENZIONE',
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
      case 'ordinaria':
        return 'Manutenzione Ordinaria';
      case 'straordinaria':
        return 'Manutenzione Straordinaria';
      case 'riparazione':
        return 'Riparazione';
      case 'pulizia':
        return 'Pulizia';
      case 'revisione':
        return 'Revisione';
      case 'sostituzione_parti':
        return 'Sostituzione Parti';
      default:
        return tipo;
    }
  }

  String _getStatoDisplayName(String stato) {
    switch (stato) {
      case 'programmata':
        return 'Programmata';
      case 'in_corso':
        return 'In Corso';
      case 'completata':
        return 'Completata';
      case 'annullata':
        return 'Annullata';
      default:
        return stato;
    }
  }
}

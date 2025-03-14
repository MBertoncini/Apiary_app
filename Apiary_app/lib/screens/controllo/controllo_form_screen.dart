import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class ControlloFormScreen extends StatefulWidget {
  final int arniaId;
  final Map<String, dynamic>? controllo; // Null se è creazione, altrimenti è modifica
  
  ControlloFormScreen({required this.arniaId, this.controllo});
  
  @override
  _ControlloFormScreenState createState() => _ControlloFormScreenState();
}

class _ControlloFormScreenState extends State<ControlloFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _dataController = TextEditingController();
  final _telainiScorteController = TextEditingController();
  final _telainiCovataController = TextEditingController();
  final _dataSciamauturaController = TextEditingController();
  final _noteSciamauturaController = TextEditingController();
  final _noteProblemiController = TextEditingController();
  final _noteController = TextEditingController();
  final _numeroCelleRealiController = TextEditingController();
  
  // Flags
  bool _presenzaRegina = true;
  bool _sciamatura = false;
  bool _problemiSanitari = false;
  bool _reginaVista = false;
  bool _uovaFresche = false;
  bool _celleReali = false;
  bool _reginaSostituita = false;
  
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, dynamic>? _arnia;
  Map<String, dynamic>? _apiario;
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _loadArnia();
    
    // Imposta data di oggi nel controller
    final now = DateTime.now();
    _dataController.text = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Popolamento form se in modalità modifica
    if (widget.controllo != null) {
      _dataController.text = widget.controllo!['data'];
      _telainiScorteController.text = widget.controllo!['telaini_scorte'].toString();
      _telainiCovataController.text = widget.controllo!['telaini_covata'].toString();
      _presenzaRegina = widget.controllo!['presenza_regina'];
      _sciamatura = widget.controllo!['sciamatura'];
      _problemiSanitari = widget.controllo!['problemi_sanitari'];
      _reginaVista = widget.controllo!['regina_vista'];
      _uovaFresche = widget.controllo!['uova_fresche'];
      _celleReali = widget.controllo!['celle_reali'];
      _numeroCelleRealiController.text = widget.controllo!['numero_celle_reali'].toString();
      _reginaSostituita = widget.controllo!['regina_sostituita'];
      
      if (widget.controllo!['data_sciamatura'] != null) {
        _dataSciamauturaController.text = widget.controllo!['data_sciamatura'];
      }
      if (widget.controllo!['note_sciamatura'] != null) {
        _noteSciamauturaController.text = widget.controllo!['note_sciamatura'];
      }
      if (widget.controllo!['note_problemi'] != null) {
        _noteProblemiController.text = widget.controllo!['note_problemi'];
      }
      if (widget.controllo!['note'] != null) {
        _noteController.text = widget.controllo!['note'];
      }
    } else {
      // Valori di default per creazione
      _telainiScorteController.text = '0';
      _telainiCovataController.text = '0';
      _numeroCelleRealiController.text = '0';
    }
  }
  
  @override
  void dispose() {
    _dataController.dispose();
    _telainiScorteController.dispose();
    _telainiCovataController.dispose();
    _dataSciamauturaController.dispose();
    _noteSciamauturaController.dispose();
    _noteProblemiController.dispose();
    _noteController.dispose();
    _numeroCelleRealiController.dispose();
    super.dispose();
  }
  
  Future<void> _loadArnia() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Carica dati arnia
      final arnie = await storageService.getStoredData('arnie');
      _arnia = arnie.firstWhere(
        (a) => a['id'] == widget.arniaId,
        orElse: () => null,
      );
      
      if (_arnia != null) {
        // Carica dati apiario
        final apiari = await storageService.getStoredData('apiari');
        _apiario = apiari.firstWhere(
          (a) => a['id'] == _arnia!['apiario'],
          orElse: () => null,
        );
      }
    } catch (e) {
      print('Error loading arnia: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Preparazione dati
      final Map<String, dynamic> data = {
        'arnia': widget.arniaId,
        'data': _dataController.text,
        'telaini_scorte': int.parse(_telainiScorteController.text),
        'telaini_covata': int.parse(_telainiCovataController.text),
        'presenza_regina': _presenzaRegina,
        'sciamatura': _sciamatura,
        'problemi_sanitari': _problemiSanitari,
        'regina_vista': _reginaVista,
        'uova_fresche': _uovaFresche,
        'celle_reali': _celleReali,
        'numero_celle_reali': int.parse(_numeroCelleRealiController.text),
        'regina_sostituita': _reginaSostituita,
        'note': _noteController.text,
      };
      
      // Aggiungi campi opzionali se valorizzati
      if (_sciamatura && _dataSciamauturaController.text.isNotEmpty) {
        data['data_sciamatura'] = _dataSciamauturaController.text;
      }
      if (_sciamatura && _noteSciamauturaController.text.isNotEmpty) {
        data['note_sciamatura'] = _noteSciamauturaController.text;
      }
      if (_problemiSanitari && _noteProblemiController.text.isNotEmpty) {
        data['note_problemi'] = _noteProblemiController.text;
      }
      
      // Invio dati al server
      if (widget.controllo == null) {
        // Creazione
        await apiService.post(ApiConstants.controlliUrl, data);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Controllo registrato con successo'),
            backgroundColor: ThemeConstants.successColor,
          ),
        );
      } else {
        // Modifica
        await apiService.put('${ApiConstants.controlliUrl}${widget.controllo!['id']}/', data);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Controllo aggiornato con successo'),
            backgroundColor: ThemeConstants.successColor,
          ),
        );
      }
      
      Navigator.of(context).pop();
    } catch (e) {
      print('Error saving controllo: $e');
      setState(() {
        _errorMessage = 'Errore durante il salvataggio. Riprova più tardi.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading && _arnia == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Controllo arnia'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.controllo == null ? 'Registra controllo' : 'Modifica controllo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Messaggio di errore
            if (_errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: ThemeConstants.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ThemeConstants.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: ThemeConstants.errorColor),
                ),
              ),
            
            // Intestazione con info arnia
            if (_arnia != null)
              Card(
                color: Color(int.parse(_arnia!['colore_hex'].replaceAll('#', '0xFF'))).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(int.parse(_arnia!['colore_hex'].replaceAll('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _arnia!['numero'].toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(int.parse(_arnia!['colore_hex'].replaceAll('#', '0xFF'))).computeLuminance() > 0.5 ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Arnia ${_arnia!['numero']}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            if (_apiario != null)
                              Text(
                                _apiario!['nome'],
                                style: TextStyle(
                                  color: ThemeConstants.textSecondaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),
            
            // Informazioni generali
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informazioni generali',
                      style: ThemeConstants.subheadingStyle,
                    ),
                    SizedBox(height: 16),
                    
                    // Data controllo
                    InkWell(
                      onTap: () => _selectDate(context, _dataController),
                      child: IgnorePointer(
                        child: TextFormField(
                          controller: _dataController,
                          decoration: InputDecoration(
                            labelText: 'Data controllo',
                            hintText: 'YYYY-MM-DD',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci la data del controllo';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Telaini scorte
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _telainiScorteController,
                            decoration: InputDecoration(
                              labelText: 'Telaini scorte',
                              prefixIcon: Icon(Icons.grid_view),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Richiesto';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Numero intero';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _telainiCovataController,
                            decoration: InputDecoration(
                              labelText: 'Telaini covata',
                              prefixIcon: Icon(Icons.grid_view),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Richiesto';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Numero intero';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Informazioni regina
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Regina',
                      style: ThemeConstants.subheadingStyle,
                    ),
                    SizedBox(height: 16),
                    
                    // Presenza regina
                    SwitchListTile(
                      title: Text('Presenza regina'),
                      subtitle: Text('La colonia ha una regina'),
                      value: _presenzaRegina,
                      onChanged: (value) {
                        setState(() {
                          _presenzaRegina = value;
                          if (!value) {
                            // Se non c'è la regina, questi non possono essere true
                            _reginaVista = false;
                            _uovaFresche = false;
                          }
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),
                    
                    // Regina vista
                    if (_presenzaRegina)
                      SwitchListTile(
                        title: Text('Regina vista'),
                        subtitle: Text('La regina è stata vista durante il controllo'),
                        value: _reginaVista,
                        onChanged: (value) {
                          setState(() {
                            _reginaVista = value;
                          });
                        },
                        activeColor: ThemeConstants.primaryColor,
                      ),
                    
                    // Uova fresche
                    if (_presenzaRegina)
                      SwitchListTile(
                        title: Text('Uova fresche'),
                        subtitle: Text('Sono state viste uova fresche (indica presenza regina)'),
                        value: _uovaFresche,
                        onChanged: (value) {
                          setState(() {
                            _uovaFresche = value;
                          });
                        },
                        activeColor: ThemeConstants.primaryColor,
                      ),
                    
                    // Celle reali
                    SwitchListTile(
                      title: Text('Celle reali'),
                      subtitle: Text('Sono presenti celle reali'),
                      value: _celleReali,
                      onChanged: (value) {
                        setState(() {
                          _celleReali = value;
                          if (!value) {
                            _numeroCelleRealiController.text = '0';
                          }
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),
                    
                    // Numero celle reali
                    if (_celleReali)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                        child: TextFormField(
                          controller: _numeroCelleRealiController,
                          decoration: InputDecoration(
                            labelText: 'Numero celle reali',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_celleReali && (value == null || value.isEmpty)) {
                              return 'Inserisci il numero di celle reali';
                            }
                            if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                              return 'Inserisci un numero valido';
                            }
                            return null;
                          },
                        ),
                      ),
                    
                    // Regina sostituita
                    SwitchListTile(
                      title: Text('Regina sostituita'),
                      subtitle: Text('La regina è stata sostituita durante questo controllo'),
                      value: _reginaSostituita,
                      onChanged: (value) {
                        setState(() {
                          _reginaSostituita = value;
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Sciamatura
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sciamatura',
                      style: ThemeConstants.subheadingStyle,
                    ),
                    SizedBox(height: 16),
                    
                    // Flag sciamatura
                    SwitchListTile(
                      title: Text('Sciamatura'),
                      subtitle: Text('Si è verificata una sciamatura'),
                      value: _sciamatura,
                      onChanged: (value) {
                        setState(() {
                          _sciamatura = value;
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),
                    
                    if (_sciamatura) ...[
                      // Data sciamatura
                      InkWell(
                        onTap: () => _selectDate(context, _dataSciamauturaController),
                        child: IgnorePointer(
                          child: TextFormField(
                            controller: _dataSciamauturaController,
                            decoration: InputDecoration(
                              labelText: 'Data sciamatura',
                              hintText: 'YYYY-MM-DD',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Note sciamatura
                      TextFormField(
                        controller: _noteSciamauturaController,
                        decoration: InputDecoration(
                          labelText: 'Note sciamatura',
                          hintText: 'Dettagli sulla sciamatura...',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Problemi sanitari
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Problemi sanitari',
                      style: ThemeConstants.subheadingStyle,
                    ),
                    SizedBox(height: 16),
                    
                    // Flag problemi
                    SwitchListTile(
                      title: Text('Problemi sanitari'),
                      subtitle: Text('Sono stati rilevati problemi sanitari'),
                      value: _problemiSanitari,
                      onChanged: (value) {
                        setState(() {
                          _problemiSanitari = value;
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),
                    
                    if (_problemiSanitari) ...[
                      // Note problemi
                      TextFormField(
                        controller: _noteProblemiController,
                        decoration: InputDecoration(
                          labelText: 'Dettagli problemi sanitari',
                          hintText: 'Descrivi i problemi rilevati...',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (_problemiSanitari && (value == null || value.isEmpty)) {
                            return 'Inserisci i dettagli dei problemi sanitari';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Note generali
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note generali',
                      style: ThemeConstants.subheadingStyle,
                    ),
                    SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Note',
                        hintText: 'Inserisci eventuali note aggiuntive...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Pulsanti
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('ANNULLA'),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ThemeConstants.primaryColor),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(widget.controllo == null ? 'SALVA CONTROLLO' : 'AGGIORNA CONTROLLO'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
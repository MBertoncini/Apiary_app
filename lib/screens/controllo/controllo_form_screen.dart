import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';
import '../../utils/validators.dart';
import '../../services/controllo_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../database/database_helper.dart';

class ControlloArniaScreen extends StatefulWidget {
  final int arniaId;
  final Map<String, dynamic>? controlloEsistente; // Null se è creazione, altrimenti è modifica
  
  ControlloArniaScreen({required this.arniaId, this.controlloEsistente});
  
  @override
  _ControlloArniaScreenState createState() => _ControlloArniaScreenState();
}

class _ControlloArniaScreenState extends State<ControlloArniaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllori di testo
  final _dataController = TextEditingController();
  final _noteController = TextEditingController();
  final _noteSciamauturaController = TextEditingController();
  final _noteProblemiController = TextEditingController();
  final _numeroCelleRealiController = TextEditingController();
  
  // Valori del form
  DateTime _selectedDate = DateTime.now();
  bool _presenzaRegina = true;
  bool _reginaVista = false;
  bool _uovaFresche = false;
  bool _celleReali = false;
  bool _reginaSostituita = false;
  bool _sciamatura = false;
  bool _problemiSanitari = false;
  List<String> _telainiConfig = List.filled(10, 'vuoto');
  String _currentTool = 'covata';
  int _telainiScorte = 0;
  int _telainiCovata = 0;
  
  // Stato
  bool _isLoading = false;
  bool _isOnline = true;
  String _errorMessage = '';
  Map<String, dynamic>? _arnia;
  Map<String, dynamic>? _apiario;
  late ControlloService _controlloService;
  
  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadArnia();
    
    // Imposta la data di oggi come default
    _dataController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    // Se è un controllo esistente, popola i campi
    if (widget.controlloEsistente != null) {
      _populateFormWithExistingData();
    } else {
      // Valori di default per nuova creazione
      _numeroCelleRealiController.text = '0';
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inizializza i servizi
    final apiService = Provider.of<ApiService>(context, listen: false);
    _controlloService = ControlloService(apiService);
  }
  
  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
    
    // Ascolta i cambiamenti di connettività
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      
      // Se torniamo online, prova a sincronizzare
      if (_isOnline) {
        _controlloService.syncPendingControlli().then((success) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Dati sincronizzati con successo')),
            );
          }
        });
      }
    });
  }
  
  void _populateFormWithExistingData() {
    final controllo = widget.controlloEsistente!;
    
    _dataController.text = controllo['data'];
    _noteController.text = controllo['note'] ?? '';
    _presenzaRegina = controllo['presenza_regina'];
    _reginaVista = controllo['regina_vista'];
    _uovaFresche = controllo['uova_fresche'];
    _celleReali = controllo['celle_reali'];
    _numeroCelleRealiController.text = controllo['numero_celle_reali'].toString();
    _reginaSostituita = controllo['regina_sostituita'];
    _sciamatura = controllo['sciamatura'];
    _problemiSanitari = controllo['problemi_sanitari'];
    
    if (controllo['sciamatura']) {
      _noteSciamauturaController.text = controllo['note_sciamatura'] ?? '';
    }
    
    if (controllo['problemi_sanitari']) {
      _noteProblemiController.text = controllo['note_problemi'] ?? '';
    }
    
    // Carica configurazione dei telaini se disponibile
    if (controllo['telaini_config'] != null && controllo['telaini_config'].isNotEmpty) {
      try {
        final List<dynamic> config = json.decode(controllo['telaini_config']);
        _telainiConfig = List<String>.from(config);
      } catch (e) {
        debugPrint('Errore nel parsing della configurazione telaini: $e');
      }
    } else {
      // Distribuzione di default basata sui valori di telaini_scorte e telaini_covata
      _telainiScorte = controllo['telaini_scorte'];
      _telainiCovata = controllo['telaini_covata'];
      _distribuisciTelaini();
    }
    
    _updateTelainiCounters(); // Aggiorna i contatori basati sulla configurazione
  }
  
  void _distribuisciTelaini() {
    // Algoritmo semplice: mette la covata al centro e le scorte ai lati
    _telainiConfig = List.filled(10, 'vuoto');
    
    // Calcola la posizione centrale
    final middle = 10 ~/ 2;
    final halfCovata = _telainiCovata ~/ 2;
    
    // Posiziona la covata al centro
    for (int i = 0; i < _telainiCovata; i++) {
      final pos = middle - halfCovata + i;
      if (pos >= 0 && pos < 10) {
        _telainiConfig[pos] = 'covata';
      }
    }
    
    // Posiziona le scorte ai lati
    int scorteLeft = _telainiScorte ~/ 2;
    int scorteRight = _telainiScorte - scorteLeft;
    
    // Lato sinistro
    for (int i = 0; i < scorteLeft; i++) {
      final pos = middle - halfCovata - 1 - i;
      if (pos >= 0) {
        _telainiConfig[pos] = 'scorte';
      }
    }
    
    // Lato destro
    for (int i = 0; i < scorteRight; i++) {
      final pos = middle + halfCovata + i;
      if (pos < 10) {
        _telainiConfig[pos] = 'scorte';
      }
    }
  }
  
  Future<void> _loadArnia() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Carica l'arnia
      if (_isOnline) {
        try {
          final response = await apiService.get('${ApiConstants.arnieUrl}${widget.arniaId}/');
          setState(() {
            _arnia = response;
          });
          
          // Carica l'apiario
          if (_arnia != null) {
            final apiarioResponse = await apiService.get('${ApiConstants.apiariUrl}${_arnia!['apiario']}/');
            setState(() {
              _apiario = apiarioResponse;
            });
          }
        } catch (e) {
          debugPrint('Errore nel caricamento online dell\'arnia: $e');
          _loadArniaOffline();
        }
      } else {
        _loadArniaOffline();
      }
    } catch (e) {
      debugPrint('Errore generale nel caricamento dell\'arnia: $e');
      setState(() {
        _errorMessage = 'Impossibile caricare i dati dell\'arnia. Verifica la connessione.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadArniaOffline() async {
    try {
      // Carica l'arnia dal database locale usando DatabaseHelper
      final dbHelper = DatabaseHelper();
      final arnieList = await dbHelper.query(
        dbHelper.tableArnie,
        where: 'id = ?',
        whereArgs: [widget.arniaId],
      );
      
      if (arnieList.isNotEmpty) {
        setState(() {
          _arnia = arnieList.first;
        });
        
        // Carica l'apiario
        if (_arnia != null) {
          final apiariList = await dbHelper.query(
            dbHelper.tableApiari,
            where: 'id = ?',
            whereArgs: [_arnia!['apiario']],
          );
          
          if (apiariList.isNotEmpty) {
            setState(() {
              _apiario = apiariList.first;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Errore nel caricamento offline dell\'arnia: $e');
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ThemeConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: ThemeConstants.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dataController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }
  
  void _updateTelainiCounters() {
    int covata = 0;
    int scorte = 0;
    
    for (String tipo in _telainiConfig) {
      if (tipo == 'covata') covata++;
      if (tipo == 'scorte') scorte++;
    }
    
    setState(() {
      _telainiCovata = covata;
      _telainiScorte = scorte;
    });
  }
  
  void _applyTool(int position) {
    setState(() {
      _telainiConfig[position] = _currentTool;
      _updateTelainiCounters();
    });
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
      // Prepara i dati
      Map<String, dynamic> data = {
        'arnia': widget.arniaId,
        'data': _dataController.text,
        'telaini_scorte': _telainiScorte,
        'telaini_covata': _telainiCovata,
        'presenza_regina': _presenzaRegina,
        'regina_vista': _reginaVista,
        'uova_fresche': _uovaFresche,
        'celle_reali': _celleReali,
        'numero_celle_reali': int.parse(_numeroCelleRealiController.text),
        'regina_sostituita': _reginaSostituita,
        'sciamatura': _sciamatura,
        'problemi_sanitari': _problemiSanitari,
        'note': _noteController.text,
        'telaini_config': json.encode(_telainiConfig),
      };
      
      // Aggiungi campi opzionali
      if (_sciamatura && _noteSciamauturaController.text.isNotEmpty) {
        data['note_sciamatura'] = _noteSciamauturaController.text;
      }
      
      if (_problemiSanitari && _noteProblemiController.text.isNotEmpty) {
        data['note_problemi'] = _noteProblemiController.text;
      }
      
      // Crea o aggiorna controllo
      Map<String, dynamic> result;
      if (widget.controlloEsistente == null) {
        // Nuovo controllo
        result = await _controlloService.saveControllo(data);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isOnline 
                ? 'Controllo registrato con successo' 
                : 'Controllo salvato localmente. Sarà sincronizzato quando tornerai online'),
            backgroundColor: _isOnline ? Colors.green : Colors.orange,
          )
        );
      } else {
        // Aggiornamento controllo esistente
        int controlloId = widget.controlloEsistente!['id'];
        result = await _controlloService.updateControllo(controlloId, data);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isOnline 
                ? 'Controllo aggiornato con successo' 
                : 'Aggiornamento salvato localmente. Sarà sincronizzato quando tornerai online'),
            backgroundColor: _isOnline ? Colors.green : Colors.orange,
          )
        );
      }
      
      Navigator.of(context).pop(result);
      
    } catch (e) {
      debugPrint('Errore nel salvataggio del controllo: $e');
      setState(() {
        _errorMessage = 'Si è verificato un errore. Riprova più tardi.';
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
          title: Text('Controllo Arnia'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final Color arniaColor = _arnia != null 
        ? Color(int.parse(_arnia!['colore_hex'].replaceAll('#', '0xFF')))
        : Colors.brown;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.controlloEsistente == null ? 'Nuovo Controllo' : 'Modifica Controllo'),
        backgroundColor: arniaColor,
        actions: [
          // Indicatore connettività
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              _isOnline ? Icons.wifi : Icons.wifi_off,
              color: _isOnline ? Colors.white : Colors.orange,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner modalità offline
              if (!_isOnline)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sei offline. Le modifiche saranno salvate localmente e sincronizzate quando sarai di nuovo online.',
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Messaggio di errore
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Informazioni Arnia
              if (_arnia != null)
                Card(
                  color: arniaColor.withOpacity(0.1),
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: arniaColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _arnia!['numero'].toString(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: arniaColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_apiario != null)
                                Text(
                                  _apiario!['nome'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Il resto del form rimane uguale a prima
              // ...
              
              // Sezione Data
              Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Controllo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dataController,
                            decoration: InputDecoration(
                              labelText: 'Data',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            validator: (value) => Validators.required(value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Configuratore Telaini
              Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configurazione Telaini',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Strumenti di selezione
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildToolButton('covata', 'Covata', Colors.red, Icons.grid_4x4),
                          _buildToolButton('scorte', 'Scorte', Colors.amber, Icons.grid_4x4),
                          _buildToolButton('diaframma', 'Diaframma', Colors.black, Icons.vertical_split),
                          _buildToolButton('nutritore', 'Nutritore', Color(0xFFE8D4B9), Icons.coffee),
                          _buildToolButton('vuoto', 'Vuoto', Colors.grey.shade300, Icons.clear),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      Text('Tocca un telaino per cambiare il tipo', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      
                      // Visualizzazione Arnia
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.brown, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(10, (index) {
                            return _buildTelainoItem(index);
                          }),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Contatori
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCounter('Covata', _telainiCovata, Colors.red),
                          _buildCounter('Scorte', _telainiScorte, Colors.amber),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Sezione Regina
              Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Regina',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSwitchTile(
                        'Presenza regina',
                        'La colonia ha una regina',
                        Icons.star,
                        _presenzaRegina,
                        (value) {
                          setState(() {
                            _presenzaRegina = value;
                            if (!value) {
                              _reginaVista = false;
                              _uovaFresche = false;
                            }
                          });
                        },
                      ),
                      
                      if (_presenzaRegina) ...[
                        _buildSwitchTile(
                          'Regina vista',
                          'La regina è stata vista durante il controllo',
                          Icons.visibility,
                          _reginaVista,
                          (value) => setState(() => _reginaVista = value),
                        ),
                        
                        _buildSwitchTile(
                          'Uova fresche',
                          'Sono state viste uova fresche',
                          Icons.egg_alt,
                          _uovaFresche,
                          (value) => setState(() => _uovaFresche = value),
                        ),
                      ],
                      
                      _buildSwitchTile(
                        'Celle reali',
                        'Sono presenti celle reali',
                        Icons.change_history,
                        _celleReali,
                        (value) {
                          setState(() {
                            _celleReali = value;
                            if (!value) {
                              _numeroCelleRealiController.text = '0';
                            }
                          });
                        },
                      ),
                      
                      if (_celleReali)
                        Padding(
                          padding: EdgeInsets.only(left: 48, right: 16, top: 8, bottom: 8),
                          child: TextFormField(
                            controller: _numeroCelleRealiController,
                            decoration: InputDecoration(
                              labelText: 'Numero celle reali',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) => Validators.positiveInteger(value),
                          ),
                        ),
                      
                      _buildSwitchTile(
                        'Regina sostituita',
                        'La regina è stata sostituita durante questo controllo',
                        Icons.swap_horiz,
                        _reginaSostituita,
                        (value) => setState(() => _reginaSostituita = value),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Sezione Sciamatura
              Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sciamatura',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSwitchTile(
                        'Sciamatura rilevata',
                        'La colonia ha sciamato',
                        Icons.grain,
                        _sciamatura,
                        (value) => setState(() => _sciamatura = value),
                      ),
                      
                      if (_sciamatura)
                        Padding(
                          padding: EdgeInsets.only(left: 48, right: 16, top: 8, bottom: 8),
                          child: TextFormField(
                            controller: _noteSciamauturaController,
                            decoration: InputDecoration(
                              labelText: 'Note sciamatura',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            maxLines: 3,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Sezione Problemi Sanitari
              Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Problemi Sanitari',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSwitchTile(
                        'Problemi sanitari rilevati',
                        'Sono stati rilevati problemi sanitari',
                        Icons.healing,
                        _problemiSanitari,
                        (value) => setState(() => _problemiSanitari = value),
                      ),
                      
                      if (_problemiSanitari)
                        Padding(
                          padding: EdgeInsets.only(left: 48, right: 16, top: 8, bottom: 8),
                          child: TextFormField(
                            controller: _noteProblemiController,
                            decoration: InputDecoration(
                              labelText: 'Dettagli problemi sanitari',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (_problemiSanitari && (value == null || value.isEmpty)) {
                                return 'Inserisci i dettagli sui problemi sanitari';
                              }
                              return null;
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Sezione Note
              Card(
                margin: EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note Generali',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: 'Note',
                          hintText: 'Inserisci eventuali note aggiuntive...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Pulsanti
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'ANNULLA',
                          style: TextStyle(fontSize: 16),
                        ),
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
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                widget.controlloEsistente == null ? 'SALVA' : 'AGGIORNA',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildToolButton(String tool, String label, Color color, IconData icon) {
    final isSelected = _currentTool == tool;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTool = tool;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.8) : color.withOpacity(0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? (color.computeLuminance() > 0.5 ? Colors.black : Colors.white) : color,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? (color.computeLuminance() > 0.5 ? Colors.black : Colors.white) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTelainoItem(int position) {
    final tipo = _telainiConfig[position];
    Color color;
    double width;
    IconData icon;
    
    switch (tipo) {
      case 'covata':
        color = Colors.red;
        width = 24;
        icon = Icons.grid_4x4;
        break;
      case 'scorte':
        color = Colors.amber;
        width = 24;
        icon = Icons.grid_4x4;
        break;
      case 'diaframma':
        color = Colors.black;
        width = 10;
        icon = Icons.vertical_split;
        break;
      case 'nutritore':
        color = Color(0xFFE8D4B9);
        width = 24;
        icon = Icons.coffee;
        break;
      case 'vuoto':
      default:
        color = Colors.grey.shade300;
        width = 24;
        icon = Icons.clear;
    }
    
    return GestureDetector(
      onTap: () {
        _applyTool(position);
      },
      child: Container(
        width: width,
        height: 100,
        margin: EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: color.withOpacity(0.8),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top icon (very small)
            Icon(
              icon,
              size: 8,
              color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            ),
            
            // Number at bottom
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(1),
                  bottomRight: Radius.circular(1),
                ),
              ),
              child: Text(
                '${position + 1}',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCounter(String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.computeLuminance() > 0.5 ? Colors.black : color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color.computeLuminance() > 0.5 ? Colors.black : color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: value ? ThemeConstants.primaryColor : Colors.grey),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(left: 40),
          child: Text(subtitle),
        ),
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        activeColor: ThemeConstants.primaryColor,
      ),
    );
  }
  
  @override
  void dispose() {
    _dataController.dispose();
    _noteController.dispose();
    _noteSciamauturaController.dispose();
    _noteProblemiController.dispose();
    _numeroCelleRealiController.dispose();
    super.dispose();
  }
}
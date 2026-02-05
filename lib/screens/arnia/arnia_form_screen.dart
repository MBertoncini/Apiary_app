import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../models/arnia.dart';
import '../../models/apiario.dart';  // Import the Apiario model
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';  // Import StorageService

class ArniaFormScreen extends StatefulWidget {
  final int? apiarioId;
  final Arnia? arnia; // Se fornita, siamo in modalità modifica

  const ArniaFormScreen({Key? key, this.apiarioId, this.arnia}) : super(key: key);

  @override
  _ArniaFormScreenState createState() => _ArniaFormScreenState();
}

class _ArniaFormScreenState extends State<ArniaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  late ApiService _apiService;
  late StorageService _storageService;
  
  // Lista degli apiari disponibili
  List<Map<String, dynamic>> _apiari = [];
  bool _loadingApiari = true;
  
  // Campi del form
  int? _apiarioId;
  String? _apiarioNome;
  int _numero = 1;
  String _colore = 'bianco';
  String _coloreHex = '#FFFFFF';
  DateTime _dataInstallazione = DateTime.now();
  String _note = '';
  bool _attiva = true;
  
  // Opzioni per il colore
  final List<Map<String, dynamic>> _coloriDisponibili = [
    {'id': 'bianco', 'nome': 'Bianco', 'hex': '#FFFFFF'},
    {'id': 'giallo', 'nome': 'Giallo', 'hex': '#FFC107'},
    {'id': 'blu', 'nome': 'Blu', 'hex': '#0d6efd'},
    {'id': 'verde', 'nome': 'Verde', 'hex': '#198754'},
    {'id': 'rosso', 'nome': 'Rosso', 'hex': '#dc3545'},
    {'id': 'arancione', 'nome': 'Arancione', 'hex': '#fd7e14'},
    {'id': 'viola', 'nome': 'Viola', 'hex': '#6f42c1'},
    {'id': 'nero', 'nome': 'Nero', 'hex': '#212529'},
    {'id': 'altro', 'nome': 'Altro', 'hex': '#6c757d'},
  ];
  
  // Indicatore di caricamento
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _storageService = Provider.of<StorageService>(context, listen: false);
    
    // Carica tutti gli apiari disponibili
    _loadApiari();
    
    // Se siamo in modalità modifica, carica i dati dell'arnia
    if (widget.arnia != null) {
      _apiarioId = widget.arnia!.apiario;
      _apiarioNome = widget.arnia!.apiarioNome;
      _numero = widget.arnia!.numero;
      _colore = widget.arnia!.colore;
      _coloreHex = widget.arnia!.coloreHex;
      _dataInstallazione = DateTime.tryParse(widget.arnia!.dataInstallazione) ?? DateTime.now();
      _note = widget.arnia!.note ?? '';
      _attiva = widget.arnia!.attiva;
    } else if (widget.apiarioId != null) {
      // Se viene specificato un apiario, utilizza quello
      _apiarioId = widget.apiarioId;
      // Carica il nome dell'apiario
      _loadApiarioName();
    }
  }

  // Carica tutti gli apiari disponibili
  Future<void> _loadApiari() async {
    setState(() {
      _loadingApiari = true;
    });

    try {
      // Prima tenta di caricare dal local storage
      final apiariFromStorage = await _storageService.getStoredData('apiari');
      
      if (apiariFromStorage.isNotEmpty) {
        setState(() {
          _apiari = List<Map<String, dynamic>>.from(apiariFromStorage);
          _loadingApiari = false;
        });
      } else {
        // Se non ci sono dati in locale, carica dalla API
        final apiariFromApi = await _apiService.get(ApiConstants.apiariUrl);
        
        if (apiariFromApi is List) {
          setState(() {
            _apiari = List<Map<String, dynamic>>.from(apiariFromApi);
            _loadingApiari = false;
          });
          
          // Salva i dati per uso futuro
          await _storageService.saveData('apiari', _apiari);
        }
      }
    } catch (e) {
      debugPrint('Errore nel caricare gli apiari: $e');
      setState(() {
        _loadingApiari = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel caricare gli apiari')),
      );
    }
  }
  
  Future<void> _loadApiarioName() async {
    if (_apiarioId != null) {
      try {
        final apiario = await _apiService.get(ApiConstants.apiariUrl + _apiarioId.toString() + '/');
        setState(() {
          _apiarioNome = apiario['nome'];
        });
      } catch (e) {
        // In caso di errore, lascia il nome vuoto
        debugPrint('Errore nel caricare il nome dell\'apiario: $e');
      }
    }
  }

  // Gestisce il cambio di colore
  void _onColoreChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _colore = newValue;
        // Aggiorna il colore hex basato sulla selezione
        Map<String, dynamic>? selectedColor;
        try {
          selectedColor = _coloriDisponibili.firstWhere((color) => color['id'] == newValue);
        } catch (e) {
          // Se non trova corrispondenza, usa un colore di default
          selectedColor = {'hex': '#6c757d'};
        }
        
        if (selectedColor != null) {
          _coloreHex = selectedColor['hex'];
        }
      });
    }
  }

  // Gestisce il cambio di apiario
  void _onApiarioChanged(int? newValue) {
    if (newValue != null) {
      setState(() {
        _apiarioId = newValue;
        // Aggiorna il nome dell'apiario
        try {
          final apiario = _apiari.firstWhere((a) => a['id'] == newValue);
          _apiarioNome = apiario['nome'];
        } catch (e) {
          _apiarioNome = 'Apiario $newValue';
        }
      });
    }
  }

  Future<void> _saveArnia() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Prepara i dati da inviare
        Map<String, dynamic> data = {
          'apiario': _apiarioId,
          'numero': _numero,
          'colore': _colore,
          'colore_hex': _coloreHex,
          'data_installazione': dateFormat.format(_dataInstallazione),
          'note': _note,
          'attiva': _attiva,
        };
        
        if (widget.arnia != null) {
          // Modalità modifica
          await _apiService.put(ApiConstants.arnieUrl + widget.arnia!.id.toString() + '/', data);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Arnia aggiornata con successo')),
          );
        } else {
          // Modalità creazione
          await _apiService.post(ApiConstants.arnieUrl, data);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Arnia creata con successo')),
          );
        }
        
        // Torna indietro
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.arnia != null ? 'Modifica Arnia' : 'Nuova Arnia'),
      ),
      body: _isLoading || _loadingApiari
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo per la selezione dell'apiario
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Apiario',
                        hintText: 'Seleziona l\'apiario',
                        border: OutlineInputBorder(),
                      ),
                      value: _apiarioId,
                      items: _apiari.map((apiario) {
                        return DropdownMenuItem<int>(
                          value: apiario['id'],
                          child: Text(apiario['nome']),
                        );
                      }).toList(),
                      onChanged: _onApiarioChanged,
                      validator: (value) {
                        if (value == null) {
                          return 'Seleziona un apiario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Numero arnia
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Numero arnia',
                        hintText: 'Inserisci il numero dell\'arnia',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _numero.toString(),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci un numero';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Inserisci un numero valido';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _numero = int.parse(value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Colore arnia
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Colore arnia',
                        border: OutlineInputBorder(),
                      ),
                      value: _colore,
                      items: _coloriDisponibili.map((color) {
                        return DropdownMenuItem<String>(
                          value: color['id'],
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _colorFromHex(color['hex']),
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(color['nome']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: _onColoreChanged,
                    ),
                    const SizedBox(height: 16),
                    
                    // Data installazione
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _dataInstallazione,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        
                        if (pickedDate != null) {
                          setState(() {
                            _dataInstallazione = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data installazione',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateFormat.format(_dataInstallazione)),
                            Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Stato attivo
                    SwitchListTile(
                      title: Text('Arnia attiva'),
                      value: _attiva,
                      onChanged: (value) {
                        setState(() {
                          _attiva = value;
                        });
                      },
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Note
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Note',
                        hintText: 'Inserisci eventuali note (opzionale)',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _note,
                      maxLines: 3,
                      onSaved: (value) {
                        _note = value ?? '';
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Pulsante salva
                    ElevatedButton(
                      onPressed: _saveArnia,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          widget.arnia != null ? 'AGGIORNA ARNIA' : 'CREA ARNIA',
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
  
  // Helper per convertire colore hex in Color
  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
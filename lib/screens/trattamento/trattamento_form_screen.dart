import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_widget.dart';

class TrattamentoFormScreen extends StatefulWidget {
  final int? apiarioId;
  final int? trattamentoId; // Se fornito, siamo in modalità modifica

  const TrattamentoFormScreen({Key? key, this.apiarioId, this.trattamentoId}) : super(key: key);

  @override
  _TrattamentoFormScreenState createState() => _TrattamentoFormScreenState();
}

class _TrattamentoFormScreenState extends State<TrattamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  late ApiService _apiService;
  
  // Stato per il caricamento
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  // Dati del form
  int? _apiarioId;
  String? _apiarioNome;
  int? _tipoTrattamentoId;
  DateTime _dataInizio = DateTime.now();
  DateTime? _dataFine;
  String _note = '';
  bool _bloccoCovataAttivo = false;
  DateTime? _dataInizioBlocco;
  DateTime? _dataFineBlocco;
  String _metodoBlocco = '';
  String _noteBlocco = '';
  
  // Dati per i dropdown
  List<dynamic> _apiari = [];
  List<dynamic> _tipiTrattamento = [];

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Carica gli apiari e i tipi di trattamento
      final apiariResponse = await _apiService.get(ApiConstants.apiariUrl);
      final tipiTrattamentoResponse = await _apiService.get(ApiConstants.tipiTrattamentoUrl);
      
      setState(() {
        _apiari = apiariResponse is List ? apiariResponse : [];
        _tipiTrattamento = tipiTrattamentoResponse is List ? tipiTrattamentoResponse : [];
      });
      
      // Se viene fornito un ID apiario, imposta come selezionato
      if (widget.apiarioId != null) {
        _apiarioId = widget.apiarioId;
        
        // Cerca il nome dell'apiario
        for (var apiario in _apiari) {
          if (apiario['id'] == _apiarioId) {
            _apiarioNome = apiario['nome'];
            break;
          }
        }
      }
      
      // Se viene fornito un ID trattamento, carica i dati
      if (widget.trattamentoId != null) {
        final trattamentoResponse = await _apiService.get('${ApiConstants.trattamentiUrl}${widget.trattamentoId}/');
        
        setState(() {
          _apiarioId = trattamentoResponse['apiario'];
          _apiarioNome = trattamentoResponse['apiario_nome'];
          _tipoTrattamentoId = trattamentoResponse['tipo_trattamento'];
          _dataInizio = DateTime.parse(trattamentoResponse['data_inizio']);
          if (trattamentoResponse['data_fine'] != null) {
            _dataFine = DateTime.parse(trattamentoResponse['data_fine']);
          }
          _note = trattamentoResponse['note'] ?? '';
          _bloccoCovataAttivo = trattamentoResponse['blocco_covata_attivo'];
          if (trattamentoResponse['data_inizio_blocco'] != null) {
            _dataInizioBlocco = DateTime.parse(trattamentoResponse['data_inizio_blocco']);
          }
          if (trattamentoResponse['data_fine_blocco'] != null) {
            _dataFineBlocco = DateTime.parse(trattamentoResponse['data_fine_blocco']);
          }
          _metodoBlocco = trattamentoResponse['metodo_blocco'] ?? '';
          _noteBlocco = trattamentoResponse['note_blocco'] ?? '';
        });
      }
      
      // Se abbiamo selezionato un tipo di trattamento, verifica se richiede blocco covata
      if (_tipoTrattamentoId != null) {
        _checkBloccoCovataRequirement();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore nel caricamento dei dati: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkBloccoCovataRequirement() {
    if (_tipoTrattamentoId != null) {
      for (var tipo in _tipiTrattamento) {
        if (tipo['id'] == _tipoTrattamentoId) {
          if (tipo['richiede_blocco_covata'] && !_bloccoCovataAttivo) {
            setState(() {
              _bloccoCovataAttivo = true;
              
              // Imposta date predefinite se necessario
              if (_dataInizioBlocco == null) {
                _dataInizioBlocco = _dataInizio;
              }
              
              if (_dataFineBlocco == null && tipo['giorni_blocco_covata'] > 0) {
                _dataFineBlocco = _dataInizioBlocco!.add(Duration(days: tipo['giorni_blocco_covata']));
              }
              
              // Suggerimenti per metodo e note
              if (_metodoBlocco.isEmpty && tipo['nota_blocco_covata'] != null) {
                _metodoBlocco = 'Ingabbiamento regina'; // Valore predefinito
                _noteBlocco = tipo['nota_blocco_covata'];
              }
            });
          }
          break;
        }
      }
    }
  }

  Future<void> _saveTrattamento() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      
      if (_apiarioId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seleziona un apiario')),
        );
        return;
      }
      
      if (_tipoTrattamentoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seleziona un tipo di trattamento')),
        );
        return;
      }
      
      setState(() {
        _isSaving = true;
      });
      
      try {
        // Prepara i dati da inviare
        Map<String, dynamic> data = {
          'apiario': _apiarioId,
          'tipo_trattamento': _tipoTrattamentoId,
          'data_inizio': dateFormat.format(_dataInizio),
          'stato': 'programmato',
          'note': _note,
          'blocco_covata_attivo': _bloccoCovataAttivo,
        };
        
        if (_dataFine != null) {
          data['data_fine'] = dateFormat.format(_dataFine!);
        }
        
        if (_bloccoCovataAttivo) {
          if (_dataInizioBlocco != null) {
            data['data_inizio_blocco'] = dateFormat.format(_dataInizioBlocco!);
          }
          
          if (_dataFineBlocco != null) {
            data['data_fine_blocco'] = dateFormat.format(_dataFineBlocco!);
          }
          
          data['metodo_blocco'] = _metodoBlocco;
          data['note_blocco'] = _noteBlocco;
        }
        
        if (widget.trattamentoId != null) {
          // Modalità modifica
          await _apiService.put('${ApiConstants.trattamentiUrl}${widget.trattamentoId}/', data);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Trattamento aggiornato con successo')),
          );
        } else {
          // Modalità creazione
          await _apiService.post(ApiConstants.trattamentiUrl, data);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Trattamento creato con successo')),
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
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trattamentoId != null ? 'Modifica Trattamento' : 'Nuovo Trattamento'),
      ),
      body: _isLoading
          ? LoadingWidget(message: 'Caricamento dati...')
          : (_errorMessage != null)
              ? CustomErrorWidget(
                  errorMessage: _errorMessage!,
                  onRetry: _loadInitialData,
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Selezione apiario
                        if (_apiarioId == null)
                          DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Apiario',
                              border: OutlineInputBorder(),
                            ),
                            hint: Text('Seleziona un apiario'),
                            value: _apiarioId,
                            items: _apiari.map<DropdownMenuItem<int>>((apiario) {
                              return DropdownMenuItem<int>(
                                value: apiario['id'],
                                child: Text(apiario['nome']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _apiarioId = value;
                                // Trova il nome dell'apiario
                                for (var apiario in _apiari) {
                                  if (apiario['id'] == value) {
                                    _apiarioNome = apiario['nome'];
                                    break;
                                  }
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Seleziona un apiario';
                              }
                              return null;
                            },
                          )
                        else
                          // Mostra l'apiario selezionato (non modificabile)
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Apiario',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_apiarioNome ?? 'Apiario $_apiarioId'),
                                if (widget.apiarioId == null) // Solo se non è fissato dall'inizio
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() {
                                        _apiarioId = null;
                                        _apiarioNome = null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        
                        // Selezione tipo trattamento
                        DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: 'Tipo di trattamento',
                            border: OutlineInputBorder(),
                          ),
                          hint: Text('Seleziona un tipo di trattamento'),
                          value: _tipoTrattamentoId,
                          items: _tipiTrattamento.map<DropdownMenuItem<int>>((tipo) {
                            return DropdownMenuItem<int>(
                              value: tipo['id'],
                              child: Text(tipo['nome']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _tipoTrattamentoId = value;
                              // Controlla se richiede blocco covata
                              _checkBloccoCovataRequirement();
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Seleziona un tipo di trattamento';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Data inizio
                        InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _dataInizio,
                              firstDate: DateTime.now().subtract(Duration(days: 30)), // Consente date recenti
                              lastDate: DateTime.now().add(Duration(days: 365)), // Consente programmazione futura
                            );
                            
                            if (pickedDate != null) {
                              setState(() {
                                _dataInizio = pickedDate;
                                
                                // Aggiorna anche data inizio blocco se necessario
                                if (_bloccoCovataAttivo && _dataInizioBlocco == null) {
                                  _dataInizioBlocco = pickedDate;
                                }
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Data inizio',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dateFormat.format(_dataInizio)),
                                Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Data fine (opzionale)
                        InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _dataFine ?? _dataInizio.add(Duration(days: 7)),
                              firstDate: _dataInizio,
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            
                            if (pickedDate != null) {
                              setState(() {
                                _dataFine = pickedDate;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Data fine (opzionale)',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_dataFine != null ? dateFormat.format(_dataFine!) : 'Non specificata'),
                                Row(
                                  children: [
                                    if (_dataFine != null)
                                      IconButton(
                                        icon: Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _dataFine = null;
                                          });
                                        },
                                      ),
                                    Icon(Icons.calendar_today),
                                  ],
                                ),
                              ],
                            ),
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
                        
                        // Sezione blocco covata
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Blocco di covata',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SwitchListTile(
                                  title: Text('Blocco covata attivo'),
                                  value: _bloccoCovataAttivo,
                                  onChanged: (value) {
                                    setState(() {
                                      _bloccoCovataAttivo = value;
                                      
                                      // Se attivato, imposta data inizio blocco
                                      if (value && _dataInizioBlocco == null) {
                                        _dataInizioBlocco = _dataInizio;
                                      }
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                                if (_bloccoCovataAttivo) ...[
                                  const SizedBox(height: 16),
                                  
                                  // Data inizio blocco
                                  InkWell(
                                    onTap: () async {
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: _dataInizioBlocco ?? _dataInizio,
                                        firstDate: DateTime.now().subtract(Duration(days: 30)),
                                        lastDate: DateTime.now().add(Duration(days: 365)),
                                      );
                                      
                                      if (pickedDate != null) {
                                        setState(() {
                                          _dataInizioBlocco = pickedDate;
                                          
                                          // Aggiorna anche data fine blocco se necessario
                                          if (_dataFineBlocco != null) {
                                            // Mantieni la stessa durata
                                            final durata = _dataFineBlocco!.difference(_dataInizioBlocco!).inDays;
                                            _dataFineBlocco = pickedDate.add(Duration(days: durata));
                                          }
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Data inizio blocco',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_dataInizioBlocco != null ? dateFormat.format(_dataInizioBlocco!) : 'Non specificata'),
                                          Icon(Icons.calendar_today),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Data fine blocco
                                  InkWell(
                                    onTap: () async {
                                      if (_dataInizioBlocco == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Imposta prima la data di inizio blocco')),
                                        );
                                        return;
                                      }
                                      
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: _dataFineBlocco ?? _dataInizioBlocco!.add(Duration(days: 21)),
                                        firstDate: _dataInizioBlocco!,
                                        lastDate: DateTime.now().add(Duration(days: 365)),
                                      );
                                      
                                      if (pickedDate != null) {
                                        setState(() {
                                          _dataFineBlocco = pickedDate;
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Data fine blocco',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_dataFineBlocco != null ? dateFormat.format(_dataFineBlocco!) : 'Non specificata'),
                                          Row(
                                            children: [
                                              if (_dataFineBlocco != null)
                                                IconButton(
                                                  icon: Icon(Icons.clear),
                                                  onPressed: () {
                                                    setState(() {
                                                      _dataFineBlocco = null;
                                                    });
                                                  },
                                                ),
                                              Icon(Icons.calendar_today),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Metodo blocco
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Metodo di blocco',
                                      hintText: 'Es. ingabbiamento regina, rimozione regina...',
                                      border: OutlineInputBorder(),
                                    ),
                                    initialValue: _metodoBlocco,
                                    onSaved: (value) {
                                      _metodoBlocco = value ?? '';
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Note blocco
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Note blocco covata',
                                      hintText: 'Dettagli aggiuntivi sul blocco (opzionale)',
                                      border: OutlineInputBorder(),
                                    ),
                                    initialValue: _noteBlocco,
                                    maxLines: 3,
                                    onSaved: (value) {
                                      _noteBlocco = value ?? '';
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Pulsante salva
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveTrattamento,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: _isSaving
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    widget.trattamentoId != null ? 'AGGIORNA TRATTAMENTO' : 'CREA TRATTAMENTO',
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
}
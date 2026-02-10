import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class ApiarioFormScreen extends StatefulWidget {
  final Map<String, dynamic>? apiario; // Null se è creazione, altrimenti è modifica
  
  ApiarioFormScreen({this.apiario});
  
  @override
  _ApiarioFormScreenState createState() => _ApiarioFormScreenState();
}

class _ApiarioFormScreenState extends State<ApiarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nomeController = TextEditingController();
  final _latitudineController = TextEditingController();
  final _longitudineController = TextEditingController();
  final _noteController = TextEditingController();
  
  // Flags
  bool _monitoraggioMeteo = false;
  bool _condivisoConGruppo = false;
  String _visibilitaMappa = 'privato'; // default: privato

  // Map picker
  LatLng? _selectedMapPoint;
  MapController _mapController = MapController();

  // Group selection
  int? _selectedGruppoId;
  List<dynamic> _gruppi = [];
  bool _gruppiLoading = true;

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Popolamento form se in modalità modifica
    if (widget.apiario != null) {
      _nomeController.text = widget.apiario!['nome'] ?? '';
      _latitudineController.text = widget.apiario!['latitudine']?.toString() ?? '';
      _longitudineController.text = widget.apiario!['longitudine']?.toString() ?? '';
      _noteController.text = widget.apiario!['note'] ?? '';

      _monitoraggioMeteo = widget.apiario!['monitoraggio_meteo'] ?? false;
      _condivisoConGruppo = widget.apiario!['condiviso_con_gruppo'] ?? false;
      _visibilitaMappa = widget.apiario!['visibilita_mappa'] ?? 'privato';

      // Pre-select group in edit mode
      if (widget.apiario!['gruppo'] != null) {
        _selectedGruppoId = widget.apiario!['gruppo'];
      }

      // Set initial map point from existing coordinates
      if (widget.apiario!['latitudine'] != null && widget.apiario!['longitudine'] != null) {
        try {
          _selectedMapPoint = LatLng(
            double.parse(widget.apiario!['latitudine'].toString()),
            double.parse(widget.apiario!['longitudine'].toString()),
          );
        } catch (_) {}
      }
    }

    _loadGruppi();
  }
  
  @override
  void dispose() {
    _nomeController.dispose();
    _latitudineController.dispose();
    _longitudineController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  Future<void> _loadGruppi() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get('gruppi/');
      List<dynamic> gruppi;
      if (response is List) {
        gruppi = response;
      } else if (response is Map) {
        gruppi = response['results'] ?? [];
      } else {
        gruppi = [];
      }
      if (mounted) {
        setState(() {
          _gruppi = gruppi;
          _gruppiLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading gruppi: $e');
      if (mounted) {
        setState(() {
          _gruppiLoading = false;
        });
      }
    }
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _selectedMapPoint = point;
      _latitudineController.text = point.latitude.toStringAsFixed(6);
      _longitudineController.text = point.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _useCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Permessi di localizzazione negati')),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permessi negati permanentemente. Attivali dalle impostazioni.'),
              action: SnackBarAction(
                label: 'Impostazioni',
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedMapPoint = point;
        _latitudineController.text = point.latitude.toStringAsFixed(6);
        _longitudineController.text = point.longitude.toStringAsFixed(6);
      });
      _mapController.move(point, 14.0);
    } catch (e) {
      debugPrint('Error getting current position: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel recupero della posizione')),
        );
      }
    }
  }

  void _syncMapFromFields() {
    final lat = double.tryParse(_latitudineController.text);
    final lng = double.tryParse(_longitudineController.text);
    if (lat != null && lng != null) {
      final point = LatLng(lat, lng);
      setState(() {
        _selectedMapPoint = point;
      });
      _mapController.move(point, _mapController.zoom);
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
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Preparazione dati
      // Il campo 'posizione' è richiesto dal backend: lo deriviamo dalle coordinate
      String posizione = '';
      if (_latitudineController.text.isNotEmpty && _longitudineController.text.isNotEmpty) {
        posizione = '${_latitudineController.text}, ${_longitudineController.text}';
      }

      final Map<String, dynamic> data = {
        'nome': _nomeController.text,
        'posizione': posizione,
        'monitoraggio_meteo': _monitoraggioMeteo,
        'condiviso_con_gruppo': _condivisoConGruppo,
        'visibilita_mappa': _visibilitaMappa,
        'note': _noteController.text,
      };

      // Includi gruppo solo se condivisione attiva e gruppo selezionato
      if (_condivisoConGruppo && _selectedGruppoId != null) {
        data['gruppo'] = _selectedGruppoId;
      }

      // Aggiungi coordinate solo se entrambe sono state fornite
      if (_latitudineController.text.isNotEmpty && _longitudineController.text.isNotEmpty) {
        data['latitudine'] = double.parse(_latitudineController.text);
        data['longitudine'] = double.parse(_longitudineController.text);
      }
      
      // Invio dati al server
      Map<String, dynamic> response;
      if (widget.apiario == null) {
        // Creazione
        response = await apiService.post(ApiConstants.apiariUrl, data);
        
        // Aggiorna lo storage locale
        final apiari = await storageService.getStoredData('apiari');
        apiari.add(response);
        await storageService.saveSyncData({'apiari': apiari});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apiario creato con successo'),
            backgroundColor: ThemeConstants.successColor,
          ),
        );
      } else {
        // Modifica
        response = await apiService.put('${ApiConstants.apiariUrl}${widget.apiario!['id']}/', data);
        
        // Aggiorna lo storage locale
        final apiari = await storageService.getStoredData('apiari');
        final index = apiari.indexWhere((a) => a['id'] == widget.apiario!['id']);
        if (index != -1) {
          apiari[index] = response;
          await storageService.saveSyncData({'apiari': apiari});
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apiario aggiornato con successo'),
            backgroundColor: ThemeConstants.successColor,
          ),
        );
      }
      
      // Torna alla schermata precedente
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error saving apiario: $e');
      setState(() {
        _errorMessage = 'Errore durante il salvataggio: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.apiario == null ? 'Nuovo apiario' : 'Modifica apiario'),
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
            
            // Informazioni di base
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
                    const SizedBox(height: 16),
                    
                    // Nome
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        labelText: 'Nome apiario',
                        hintText: 'Es. Apiario montagna',
                        prefixIcon: Icon(Icons.hive),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci il nome dell\'apiario';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Coordinate geografiche + mappa interattiva
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Posizione sulla mappa',
                      style: ThemeConstants.subheadingStyle,
                    ),
                    const SizedBox(height: 12),

                    // Mappa interattiva
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 250,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            center: _selectedMapPoint ?? LatLng(41.9, 12.5),
                            zoom: _selectedMapPoint != null ? 14.0 : 6.0,
                            maxZoom: 18.0,
                            minZoom: 3.0,
                            onTap: (tapPosition, point) => _onMapTap(point),
                            interactiveFlags: InteractiveFlag.all,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.apiario_manager',
                            ),
                            if (_selectedMapPoint != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    width: 40.0,
                                    height: 40.0,
                                    point: _selectedMapPoint!,
                                    builder: (ctx) => Icon(
                                      Icons.location_pin,
                                      color: ThemeConstants.primaryColor,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Pulsante posizione attuale
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _useCurrentLocation,
                        icon: Icon(Icons.my_location, size: 18),
                        label: Text('Usa posizione attuale'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Tocca la mappa per posizionare il marcatore, oppure inserisci le coordinate manualmente.',
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeConstants.textSecondaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudineController,
                            decoration: InputDecoration(
                              labelText: 'Latitudine',
                              prefixIcon: Icon(Icons.map),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              _syncMapFromFields();
                            },
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (_longitudineController.text.isEmpty) {
                                  return 'Inserisci anche la longitudine';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Formato non valido';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudineController,
                            decoration: InputDecoration(
                              labelText: 'Longitudine',
                              prefixIcon: Icon(Icons.map),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              _syncMapFromFields();
                            },
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (_latitudineController.text.isEmpty) {
                                  return 'Inserisci anche la latitudine';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Formato non valido';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(),
                    const SizedBox(height: 8),

                    // Visibilità sulla mappa
                    Text(
                      'Visibilità sulla mappa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    RadioListTile<String>(
                      title: Text('Solo proprietario'),
                      value: 'privato',
                      groupValue: _visibilitaMappa,
                      onChanged: (value) {
                        setState(() {
                          _visibilitaMappa = value!;
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),

                    RadioListTile<String>(
                      title: Text('Membri del gruppo'),
                      value: 'gruppo',
                      groupValue: _visibilitaMappa,
                      onChanged: (value) {
                        setState(() {
                          _visibilitaMappa = value!;
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),

                    RadioListTile<String>(
                      title: Text('Tutti gli utenti'),
                      value: 'pubblico',
                      groupValue: _visibilitaMappa,
                      onChanged: (value) {
                        setState(() {
                          _visibilitaMappa = value!;
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Funzionalità aggiuntive
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Funzionalità aggiuntive',
                      style: ThemeConstants.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    
                    // Monitoraggio meteo
                    SwitchListTile(
                      title: Text('Monitoraggio meteo'),
                      subtitle: Text('Attiva il monitoraggio delle condizioni meteo'),
                      value: _monitoraggioMeteo,
                      onChanged: (value) {
                        setState(() {
                          _monitoraggioMeteo = value;
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),
                    
                    // Condivisione con gruppo
                    SwitchListTile(
                      title: Text('Condivisione con gruppo'),
                      subtitle: Text('Condividi questo apiario con un gruppo'),
                      value: _condivisoConGruppo,
                      onChanged: (value) {
                        setState(() {
                          _condivisoConGruppo = value;
                          if (!value) {
                            _selectedGruppoId = null;
                          }
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),

                    // Dropdown selezione gruppo
                    if (_condivisoConGruppo) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _gruppiLoading
                            ? Center(child: CircularProgressIndicator(strokeWidth: 2))
                            : _gruppi.isEmpty
                                ? Text(
                                    'Non fai parte di nessun gruppo. Crea o unisciti a un gruppo per condividere.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: ThemeConstants.textSecondaryColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : DropdownButtonFormField<int>(
                                    value: _selectedGruppoId,
                                    decoration: InputDecoration(
                                      labelText: 'Seleziona gruppo',
                                      prefixIcon: Icon(Icons.group),
                                    ),
                                    items: _gruppi.map<DropdownMenuItem<int>>((gruppo) {
                                      return DropdownMenuItem<int>(
                                        value: gruppo['id'],
                                        child: Text(gruppo['nome'] ?? 'Gruppo ${gruppo['id']}'),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedGruppoId = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (_condivisoConGruppo && value == null && _gruppi.isNotEmpty) {
                                        return 'Seleziona un gruppo';
                                      }
                                      return null;
                                    },
                                  ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Note
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note',
                      style: ThemeConstants.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Note',
                        hintText: 'Inserisci eventuali note su questo apiario...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
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
                          : Text(widget.apiario == null ? 'CREA APIARIO' : 'AGGIORNA APIARIO'),
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
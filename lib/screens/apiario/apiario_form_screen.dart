import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../constants/api_constants.dart';
import '../../l10n/app_strings.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';

class ApiarioFormScreen extends StatefulWidget {
  final Map<String, dynamic>? apiario; // Null se è creazione, altrimenti è modifica

  ApiarioFormScreen({this.apiario});

  @override
  _ApiarioFormScreenState createState() => _ApiarioFormScreenState();
}

class _ApiarioFormScreenState extends State<ApiarioFormScreen> {
  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nomeController = TextEditingController();
  final _latitudineController = TextEditingController();
  final _longitudineController = TextEditingController();
  final _noteController = TextEditingController();
  final _indirizzoController = TextEditingController();

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

  // Address search
  bool _isSearchingAddress = false;
  List<Map<String, dynamic>> _addressResults = [];

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
    _indirizzoController.dispose();
    super.dispose();
  }

  Future<void> _loadGruppi() async {
    final storageService = Provider.of<StorageService>(context, listen: false);

    // Mostra subito dalla cache
    final cached = await storageService.getStoredData('gruppi');
    if (cached.isNotEmpty && mounted) {
      setState(() { _gruppi = cached; _gruppiLoading = false; });
    }

    // Aggiorna sempre dal server
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get(ApiConstants.gruppiUrl);
      final gruppi = response is List ? response : (response['results'] as List? ?? []);
      await storageService.saveData('gruppi', gruppi);
      if (mounted) {
        setState(() { _gruppi = gruppi; _gruppiLoading = false; });
      }
    } catch (e) {
      debugPrint('Error loading gruppi: $e');
      if (mounted) setState(() { _gruppiLoading = false; });
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
              SnackBar(content: Text(_s.apiarioPermDenied)),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_s.apiarioPermDeniedPermanent),
              action: SnackBarAction(
                label: _s.navSettingsTooltip,
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
          SnackBar(content: Text(_s.apiarioErrorPos)),
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

  Future<void> _searchAddress() async {
    final query = _indirizzoController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearchingAddress = true;
      _addressResults = [];
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '5',
        'accept-language': 'it',
      });
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'ApiarioManagerApp/1.0'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _addressResults = data
              .map((e) => {
                    'display_name': e['display_name'] as String,
                    'lat': double.parse(e['lat'] as String),
                    'lon': double.parse(e['lon'] as String),
                  })
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Address search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s.apiarioErrorAddr)),
        );
      }
    } finally {
      if (mounted) setState(() { _isSearchingAddress = false; });
    }
  }

  void _selectAddressResult(Map<String, dynamic> result) {
    final point = LatLng(result['lat'] as double, result['lon'] as double);
    setState(() {
      _selectedMapPoint = point;
      _latitudineController.text = point.latitude.toStringAsFixed(6);
      _longitudineController.text = point.longitude.toStringAsFixed(6);
      _addressResults = [];
      _indirizzoController.clear();
    });
    _mapController.move(point, 14.0);
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
            content: Text(_s.apiarioCreatedOk),
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
            content: Text(_s.apiarioUpdatedOk),
            backgroundColor: ThemeConstants.successColor,
          ),
        );
      }

      // Torna alla schermata precedente
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error saving apiario: $e');
      setState(() {
        _errorMessage = _s.msgErrorGeneric(e.toString());
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context); // rebuild on language change
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.apiario == null
            ? _s.apiarioFormTitleNew
            : _s.apiarioFormTitleEdit),
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
                      _s.apiarioFormSectionGeneral,
                      style: ThemeConstants.subheadingStyle,
                    ),
                    const SizedBox(height: 16),

                    // Nome
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        labelText: _s.apiarioFormLblName,
                        hintText: _s.apiarioFormHintName,
                        prefixIcon: Icon(Icons.hive),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _s.apiarioFormValidateName;
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
                      _s.apiarioFormSectionPos,
                      style: ThemeConstants.subheadingStyle,
                    ),
                    const SizedBox(height: 12),

                    // Ricerca indirizzo
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _indirizzoController,
                            decoration: InputDecoration(
                              labelText: _s.apiarioFormLblSearchAddr,
                              hintText: _s.apiarioFormHintSearchAddr,
                              prefixIcon: Icon(Icons.search),
                              isDense: true,
                            ),
                            textInputAction: TextInputAction.search,
                            onFieldSubmitted: (_) => _searchAddress(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isSearchingAddress ? null : _searchAddress,
                          icon: _isSearchingAddress
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(Icons.arrow_forward),
                          tooltip: _s.apiarioFormTooltipSearch,
                          style: IconButton.styleFrom(
                            backgroundColor: ThemeConstants.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    // Risultati ricerca
                    if (_addressResults.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ThemeConstants.primaryColor.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _addressResults.length,
                          separatorBuilder: (_, __) => Divider(height: 1),
                          itemBuilder: (context, index) {
                            final r = _addressResults[index];
                            return ListTile(
                              dense: true,
                              leading: Icon(Icons.location_on, color: ThemeConstants.primaryColor, size: 20),
                              title: Text(
                                r['display_name'] as String,
                                style: TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _selectAddressResult(r),
                            );
                          },
                        ),
                      ),
                    ],
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
                        label: Text(_s.apiarioFormBtnUsePos),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      _s.apiarioFormMapHint,
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
                              labelText: _s.apiarioFormLblLat,
                              prefixIcon: Icon(Icons.map),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              _syncMapFromFields();
                            },
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (_longitudineController.text.isEmpty) {
                                  return _s.apiarioFormValidateLon;
                                }
                                if (double.tryParse(value) == null) {
                                  return _s.apiarioFormValidateFormat;
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
                              labelText: _s.apiarioFormLblLon,
                              prefixIcon: Icon(Icons.map),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              _syncMapFromFields();
                            },
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (_latitudineController.text.isEmpty) {
                                  return _s.apiarioFormValidateLat;
                                }
                                if (double.tryParse(value) == null) {
                                  return _s.apiarioFormValidateFormat;
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
                      _s.apiarioFormSectionVisib,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    RadioListTile<String>(
                      title: Text(_s.apiarioFormVisibOwner),
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
                      title: Text(_s.apiarioFormVisibGroup),
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
                      title: Text(_s.apiarioFormVisibAll),
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
                      _s.apiarioFormSectionFeatures,
                      style: ThemeConstants.subheadingStyle,
                    ),
                    const SizedBox(height: 16),

                    // Monitoraggio meteo
                    SwitchListTile(
                      title: Text(_s.apiarioFormMeteoTitle),
                      subtitle: Text(_s.apiarioFormMeteoSubtitle),
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
                      title: Text(_s.apiarioFormShareTitle),
                      subtitle: Text(_s.apiarioFormShareSubtitle),
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
                                    _s.apiarioFormNoGruppi,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: ThemeConstants.textSecondaryColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : DropdownButtonFormField<int>(
                                    value: _selectedGruppoId,
                                    decoration: InputDecoration(
                                      labelText: _s.apiarioFormLblGroup,
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
                                        return _s.apiarioFormValidateGroup;
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
                      _s.apiarioFormLblNotes,
                      style: ThemeConstants.subheadingStyle,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: _s.apiarioFormLblNotes,
                        hintText: _s.apiarioFormHintNotes,
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
                      child: Text(_s.btnCancel),
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
                          : Text(widget.apiario == null
                              ? _s.apiarioFormBtnCreate
                              : _s.apiarioFormBtnUpdate),
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

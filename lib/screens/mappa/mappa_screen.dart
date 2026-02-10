import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/api_cache_helper.dart';
import '../../services/storage_service.dart';
import '../../widgets/drawer_widget.dart';

class MappaScreen extends StatefulWidget {
  @override
  _MappaScreenState createState() => _MappaScreenState();
}

class _MappaScreenState extends State<MappaScreen> {
  bool _isLoading = true;
  bool _isOffline = false;
  List<dynamic> _apiari = [];
  List<dynamic> _fioriture = [];
  List<dynamic> _arnie = [];
  Position? _currentPosition;
  MapController _mapController = MapController();
  bool _permissionsChecked = false;
  StorageService? _storageService;
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Non chiamiamo _checkLocationPermissions() né _loadData() qui
    // Li sposteremo in didChangeDependencies()
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_storageService == null) {
      _storageService = Provider.of<StorageService>(context, listen: false);
    }
    
    // Controlla i permessi solo una volta
    if (!_permissionsChecked) {
      _permissionsChecked = true;
      _checkLocationPermissions();
      _loadData();
    }
  }
  
  Future<void> _checkLocationPermissions() async {
    try {
      // Verifica i permessi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Permessi di localizzazione negati')),
            );
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('I permessi di localizzazione sono negati permanentemente. Attivali dalle impostazioni.'),
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Impostazioni',
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      // Se abbiamo i permessi, ottieni la posizione
      await _getCurrentPosition();
    } catch (e) {
      debugPrint('Error checking location permissions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _getCurrentPosition() async {
    try {
      // Verifica se il servizio di localizzazione è attivo
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Servizio di localizzazione disattivato. Attivalo per usare questa funzione.'),
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Attiva',
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      // Ottieni posizione
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        // Centra mappa sulla posizione corrente (solo se il controller è già collegato)
        try {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            11.0,
          );
        } catch (_) {
          // Il controller non è ancora inizializzato, la mappa userà
          // _currentPosition come center al primo build
        }
      }
    } catch (e) {
      debugPrint('Error getting current position: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel recupero della posizione')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Funzione per orientare la mappa verso nord
  void _resetRotation() {
    _mapController.rotate(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mappa orientata verso Nord'))
    );
  }
  
  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Verifichiamo che StorageService sia inizializzato
      if (_storageService == null) {
        _storageService = Provider.of<StorageService>(context, listen: false);
      }

      debugPrint("Caricamento apiari e fioriture");

      // Verifica la connettività e carica dall'API se possibile
      final isConnected = await ApiCacheHelper.isConnected();
      List<dynamic> apiari = [];
      List<dynamic> fioriture = [];
      List<dynamic> arnie = [];

      if (isConnected) {
        try {
          final apiService = Provider.of<ApiService>(context, listen: false);

          // Carica apiari dall'API
          final apiariResponse = await apiService.get('apiari/');
          if (apiariResponse is List) {
            apiari = apiariResponse;
          } else if (apiariResponse is Map) {
            apiari = apiariResponse['results'] ?? [];
          }

          // Carica fioriture dall'API
          final fioritureResponse = await apiService.get('fioriture/');
          if (fioritureResponse is List) {
            fioriture = fioritureResponse;
          } else if (fioritureResponse is Map) {
            fioriture = fioritureResponse['results'] ?? [];
          }

          // Carica arnie dall'API
          final arnieResponse = await apiService.get('arnie/');
          if (arnieResponse is List) {
            arnie = arnieResponse;
          } else if (arnieResponse is Map) {
            arnie = arnieResponse['results'] ?? [];
          }

          // Salva nella cache per uso offline
          await ApiCacheHelper.saveToCache('apiari', apiari);
          await ApiCacheHelper.saveToCache('fioriture', fioriture);

          if (mounted) {
            setState(() {
              _isOffline = false;
            });
          }

          debugPrint("Apiari caricati dall'API: ${apiari.length}");
          debugPrint("Fioriture caricate dall'API: ${fioriture.length}");
        } catch (e) {
          debugPrint('Errore API, fallback su cache locale: $e');
          apiari = await _storageService!.getStoredData('apiari');
          fioriture = await _storageService!.getStoredData('fioriture');
          arnie = await _storageService!.getStoredData('arnie');
          if (mounted) {
            setState(() {
              _isOffline = true;
            });
          }
        }
      } else {
        // Offline: carica dalla cache locale
        apiari = await _storageService!.getStoredData('apiari');
        fioriture = await _storageService!.getStoredData('fioriture');
        arnie = await _storageService!.getStoredData('arnie');
        if (mounted) {
          setState(() {
            _isOffline = true;
          });
        }
        debugPrint("Modalità offline - Apiari dalla cache: ${apiari.length}");
      }

      // Filtra apiari: mostra tutti quelli con coordinate
      // Il backend filtra già per permessi utente, quindi lato client
      // filtriamo solo per la presenza di coordinate valide.
      // Per dati offline/cache applichiamo lo stesso criterio (i dati
      // in cache sono già stati ricevuti dall'API e quindi pre-filtrati).
      List<dynamic> apiariVisibili = [];

      for (var a in apiari) {
        bool hasCoordinates = a['latitudine'] != null && a['longitudine'] != null;
        if (!hasCoordinates) {
          debugPrint("Apiario senza coordinate: ${a['nome']}");
          continue;
        }
        apiariVisibili.add(a);
      }

      debugPrint("Apiari visibili: ${apiariVisibili.length}");

      // Filtra fioriture: mostra tutte, attive e non attive.
      // Per fioriture senza coordinate proprie, usa le coordinate dell'apiario associato.
      List<dynamic> fioritureVisibili = [];

      for (var f in fioriture) {
        bool hasCoordinates = f['latitudine'] != null && f['longitudine'] != null;

        if (!hasCoordinates) {
          // Fallback: usa coordinate dell'apiario associato
          final apiarioId = f['apiario'];
          if (apiarioId != null) {
            final parentApiario = apiari.firstWhere(
              (a) => a['id'] == apiarioId,
              orElse: () => null,
            );
            if (parentApiario != null &&
                parentApiario['latitudine'] != null &&
                parentApiario['longitudine'] != null) {
              f['latitudine'] = parentApiario['latitudine'];
              f['longitudine'] = parentApiario['longitudine'];
              hasCoordinates = true;
              debugPrint("Fioritura '${f['pianta']}': coordinate ereditate da apiario");
            }
          }
        }

        if (hasCoordinates) {
          // Segna se è attiva o meno per differenziare la visualizzazione
          f['_isActive'] = _isFiorituraActive(f);
          fioritureVisibili.add(f);
        } else {
          debugPrint("Fioritura senza coordinate (né proprie né apiario): ${f['pianta']}");
        }
      }

      debugPrint("Fioriture visibili: ${fioritureVisibili.length}");

      if (mounted) {
        setState(() {
          _apiari = apiariVisibili;
          _fioriture = fioritureVisibili;
          _arnie = arnie;
          _isLoading = false;
        });
      }

    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il caricamento dei dati: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Verifica se una fioritura è attiva
  bool _isFiorituraActive(Map<String, dynamic> fioritura) {
    // Controlla se la fioritura è marcata come attiva
    if (fioritura['is_active'] == true) {
      return true;
    }
    
    // Controlla in base alle date
    final oggi = DateTime.now();
    DateTime? dataInizio;
    DateTime? dataFine;
    
    try {
      if (fioritura['data_inizio'] != null) {
        dataInizio = DateTime.parse(fioritura['data_inizio']);
      }
      
      if (fioritura['data_fine'] != null) {
        dataFine = DateTime.parse(fioritura['data_fine']);
      }
      
      if (dataInizio == null) {
        return false;
      }
      
      if (dataInizio.isAfter(oggi)) {
        return false;
      }
      
      if (dataFine != null && dataFine.isBefore(oggi)) {
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Errore nella verifica delle date della fioritura: $e');
      return false;
    }
  }
  
  void _navigateToApiarioDetail(int apiarioId) {
    Navigator.of(context).pushNamed(
      AppConstants.apiarioDetailRoute,
      arguments: apiarioId,
    );
  }

  void _showApiarioInfo(Map<String, dynamic> apiario) {
    final arnieCount = _getArnieCountForApiario(apiario['id']);
    final posizione = apiario['posizione'] ?? '';
    final hasGroupAccess = apiario['condiviso_con_gruppo'] == true ||
        apiario['visibilita_mappa'] == 'pubblico' ||
        apiario['proprietario_username'] != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ThemeConstants.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con nome e icona
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ThemeConstants.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.hive, color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                apiario['nome'] ?? 'Apiario',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeConstants.textPrimaryColor,
                                ),
                              ),
                              if (posizione.isNotEmpty)
                                Text(
                                  posizione,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: ThemeConstants.textSecondaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Divider(height: 1, color: ThemeConstants.dividerColor),
                    SizedBox(height: 12),
                    // Info row
                    Row(
                      children: [
                        _infoChip(Icons.grid_view, '$arnieCount arnie'),
                        SizedBox(width: 12),
                        if (apiario['proprietario_username'] != null)
                          _infoChip(Icons.person_outline, '${apiario['proprietario_username']}'),
                        if (apiario['condiviso_con_gruppo'] == true) ...[
                          SizedBox(width: 12),
                          _infoChip(Icons.group, 'Gruppo'),
                        ],
                      ],
                    ),
                    if (apiario['note'] != null && apiario['note'].toString().isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        apiario['note'],
                        style: TextStyle(
                          fontSize: 13,
                          color: ThemeConstants.textSecondaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 16),
                    // Pulsante per navigare al dettaglio
                    if (hasGroupAccess)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _navigateToApiarioDetail(apiario['id']);
                          },
                          icon: Icon(Icons.open_in_new, size: 18),
                          label: Text('Apri dettaglio'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeConstants.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeConstants.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ThemeConstants.textSecondaryColor),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ThemeConstants.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  int _getArnieCountForApiario(int apiarioId) {
    return _arnie.where((a) => a['apiario'] == apiarioId).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Mappa Apiari'),
            if (_isOffline)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Tooltip(
                  message: 'Modalità offline - Dati caricati dalla cache',
                  child: Icon(Icons.offline_bolt, size: 18, color: Colors.amber),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            tooltip: 'Sincronizza dati',
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.mappaRoute),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : LatLng(41.9028, 12.4964), // Default a Roma
                    zoom: 9.0,
                    maxZoom: 18.0,
                    minZoom: 3.0,
                    interactiveFlags: InteractiveFlag.all,
                    enableMultiFingerGestureRace: true,
                    rotationThreshold: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.apiario_manager',
                    ),
                    // Marker per apiari
                    MarkerLayer(
                      markers: _apiari.map((apiario) {
                        try {
                          final lat = double.parse(apiario['latitudine'].toString());
                          final lng = double.parse(apiario['longitudine'].toString());

                          return Marker(
                            width: 50.0,
                            height: 50.0,
                            point: LatLng(lat, lng),
                            builder: (ctx) => GestureDetector(
                              onTap: () => _showApiarioInfo(apiario),
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: ThemeConstants.primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.hive,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      apiario['nome'] ?? "Apiario",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } catch (e) {
                          debugPrint("Errore nel creare marker per apiario: $e");
                          return Marker(
                            width: 0,
                            height: 0,
                            point: LatLng(0, 0),
                            builder: (ctx) => Container(),
                          );
                        }
                      }).toList(),
                    ),
                    // Circles per fioriture (opacità diversa per attive/inattive)
                    CircleLayer(
                      circles: _fioriture.map((fioritura) {
                        try {
                          final lat = double.parse(fioritura['latitudine'].toString());
                          final lng = double.parse(fioritura['longitudine'].toString());
                          final raggio = fioritura['raggio'] != null ? double.parse(fioritura['raggio'].toString()) : 500.0;
                          final isActive = fioritura['_isActive'] == true;

                          return CircleMarker(
                            point: LatLng(lat, lng),
                            radius: raggio,
                            color: (isActive ? Colors.green : Colors.grey).withOpacity(isActive ? 0.3 : 0.15),
                            borderColor: isActive ? Colors.green : Colors.grey,
                            borderStrokeWidth: isActive ? 2.0 : 1.0,
                            useRadiusInMeter: true,
                          );
                        } catch (e) {
                          debugPrint("Errore nel creare circle per fioritura: $e");
                          return CircleMarker(
                            point: LatLng(0, 0),
                            radius: 0,
                            color: Colors.transparent,
                            borderColor: Colors.transparent,
                            borderStrokeWidth: 0,
                          );
                        }
                      }).toList(),
                    ),
                    // Marker per fioriture (opacità diversa per attive/inattive)
                    MarkerLayer(
                      markers: _fioriture.map((fioritura) {
                        try {
                          final lat = double.parse(fioritura['latitudine'].toString());
                          final lng = double.parse(fioritura['longitudine'].toString());
                          final isActive = fioritura['_isActive'] == true;

                          return Marker(
                            width: 30.0,
                            height: 30.0,
                            point: LatLng(lat, lng),
                            builder: (ctx) => GestureDetector(
                              onTap: () {
                                _showFiorituraInfo(fioritura);
                              },
                              child: Opacity(
                                opacity: isActive ? 1.0 : 0.5,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.local_florist,
                                    color: isActive ? Colors.green : Colors.grey,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          );
                        } catch (e) {
                          debugPrint("Errore nel creare marker per fioritura: $e");
                          return Marker(
                            width: 0,
                            height: 0,
                            point: LatLng(0, 0),
                            builder: (ctx) => Container(),
                          );
                        }
                      }).toList(),
                    ),
                    // Marker per posizione attuale
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 30.0,
                            height: 30.0,
                            point: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            builder: (ctx) => Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                
                // Legenda
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Legenda',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: ThemeConstants.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.hive,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Apiario'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 1,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Fioritura attiva'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: 0.5,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Fioritura inattiva'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Posizione attuale'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                
                // Pulsante freccina del nord
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    children: [
                      // Pulsante per orientare la mappa verso nord
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        heroTag: "btnNord", // Hero tag unico
                        onPressed: _resetRotation,
                        child: Icon(
                          Icons.navigation,
                          color: Colors.black,
                        ),
                        tooltip: 'Orienta a Nord',
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btnPosition", // Hero tag unico
        onPressed: _getCurrentPosition,
        child: Icon(Icons.my_location),
        tooltip: 'Centra sulla posizione attuale',
      ),
    );
  }
  
  void _showFiorituraInfo(Map<String, dynamic> fioritura) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.local_florist, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text('${fioritura['pianta']}', overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fioritura['apiario_nome'] != null)
                  ListTile(
                    leading: Icon(Icons.hive, size: 18),
                    title: Text('Apiario'),
                    subtitle: Text('${fioritura['apiario_nome']}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ListTile(
                  leading: Icon(Icons.calendar_today, size: 18),
                  title: Text('Periodo'),
                  subtitle: Text(
                    fioritura['data_fine'] != null
                      ? 'Dal ${_formatDate(fioritura['data_inizio'])} al ${_formatDate(fioritura['data_fine'])}'
                      : 'Dal ${_formatDate(fioritura['data_inizio'])}'
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                if (fioritura['raggio'] != null)
                  ListTile(
                    leading: Icon(Icons.radio_button_checked, size: 18),
                    title: Text('Raggio'),
                    subtitle: Text('${fioritura['raggio']} metri'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                if (fioritura['note'] != null && fioritura['note'].toString().isNotEmpty)
                  ListTile(
                    leading: Icon(Icons.note, size: 18),
                    title: Text('Note'),
                    subtitle: Text('${fioritura['note']}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }
  
  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'N/D';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }
}
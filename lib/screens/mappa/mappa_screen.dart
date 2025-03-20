import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/drawer_widget.dart';

class MappaScreen extends StatefulWidget {
  @override
  _MappaScreenState createState() => _MappaScreenState();
}

class _MappaScreenState extends State<MappaScreen> {
  bool _isLoading = true;
  List<dynamic> _apiari = [];
  List<dynamic> _fioriture = [];
  Position? _currentPosition;
  MapController _mapController = MapController();
  AuthService? _authService;
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
    
    // Inizializza i servizi
    if (_authService == null) {
      _authService = Provider.of<AuthService>(context);
    }
    
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
      print('Error checking location permissions: $e');
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
        
        // Centra mappa sulla posizione corrente
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          11.0,
        );
      }
    } catch (e) {
      print('Error getting current position: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel recupero della posizione: ${e.toString()}')),
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
      
      // Verifichiamo che AuthService sia inizializzato
      if (_authService == null) {
        _authService = Provider.of<AuthService>(context);
      }
      
      final currentUser = _authService!.currentUser;
      final currentUserId = currentUser?.id;
      
      print("Caricamento apiari e fioriture. User ID: $currentUserId");
      
      // Carica apiari
      final apiari = await _storageService!.getStoredData('apiari');
      print("Apiari totali caricati: ${apiari.length}");
      
      // Debug: stampa i primi 2 apiari (se presenti)
      if (apiari.isNotEmpty) {
        print("Primo apiario: ${apiari[0]}");
        if (apiari.length > 1) {
          print("Secondo apiario: ${apiari[1]}");
        }
      }
      
      // Filtra apiari in base ai permessi
      List<dynamic> apiariVisibili = [];
      
      for (var a in apiari) {
        // Verifica le coordinate
        bool hasCoordinates = a['latitudine'] != null && a['longitudine'] != null;
        if (!hasCoordinates) {
          print("Apiario senza coordinate: ${a['nome']}");
          continue;
        }
        
        // Filtra in base alla visibilità e ai permessi
        final visibilita = a['visibilita_mappa'];
        final proprietarioId = a['proprietario'];
        final condivisoConGruppo = a['condiviso_con_gruppo'] == true;
        final gruppoId = a['gruppo'];
        
        bool visible = false;
        
        if (visibilita == 'pubblico') {
          // Visibile a tutti
          visible = true;
          print("Apiario pubblico: ${a['nome']}");
        } else if (visibilita == 'privato') {
          // Visibile solo al proprietario
          visible = proprietarioId == currentUserId;
          print("Apiario privato: ${a['nome']}, visibile: $visible");
        } else if (visibilita == 'gruppo' && condivisoConGruppo && gruppoId != null) {
          // Visibile agli utenti del gruppo
          visible = proprietarioId == currentUserId || _userBelongsToGroup(currentUserId, gruppoId);
          print("Apiario di gruppo: ${a['nome']}, visibile: $visible");
        } else {
          print("Apiario con visibilità non riconosciuta: ${a['nome']}, tipo: $visibilita");
        }
        
        if (visible) {
          apiariVisibili.add(a);
        }
      }
      
      print("Apiari visibili: ${apiariVisibili.length}");
      
      // Carica fioriture
      final fioriture = await _storageService!.getStoredData('fioriture');
      print("Fioriture totali caricate: ${fioriture.length}");
      
      // Debug: stampa le prime 2 fioriture (se presenti)
      if (fioriture.isNotEmpty) {
        print("Prima fioritura: ${fioriture[0]}");
        if (fioriture.length > 1) {
          print("Seconda fioritura: ${fioriture[1]}");
        }
      }
      
      List<dynamic> fioritureVisibili = [];
      
      for (var f in fioriture) {
        bool hasCoordinates = f['latitudine'] != null && f['longitudine'] != null;
        bool isActive = _isFiorituraActive(f);
        
        if (hasCoordinates && isActive) {
          fioritureVisibili.add(f);
        } else {
          if (!hasCoordinates) {
            print("Fioritura senza coordinate: ${f['pianta']}");
          }
          if (!isActive) {
            print("Fioritura non attiva: ${f['pianta']}");
          }
        }
      }
      
      print("Fioriture visibili: ${fioritureVisibili.length}");
      
      if (mounted) {
        setState(() {
          _apiari = apiariVisibili;
          _fioriture = fioritureVisibili;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('Error loading data: $e');
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
  
  // Verifica se l'utente appartiene a un gruppo
  bool _userBelongsToGroup(int? userId, int gruppoId) {
    if (userId == null) return false;
    
    // Per semplicità, assumiamo che l'utente appartenga a tutti i gruppi
    // con cui sono condivisi gli apiari
    return true;
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
      print('Errore nella verifica delle date della fioritura: $e');
      return false;
    }
  }
  
  void _navigateToApiarioDetail(int apiarioId) {
    Navigator.of(context).pushNamed(
      AppConstants.apiarioDetailRoute,
      arguments: apiarioId,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mappa Apiari'),
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
                    // Abilita le opzioni interattive per la mappa
                    interactiveFlags: InteractiveFlag.all,
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
                              onTap: () => _navigateToApiarioDetail(apiario['id']),
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: ThemeConstants.primaryColor,
                                      shape: BoxShape.circle,
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
                          print("Errore nel creare marker per apiario: $e");
                          return Marker(
                            width: 0,
                            height: 0,
                            point: LatLng(0, 0),
                            builder: (ctx) => Container(),
                          );
                        }
                      }).toList(),
                    ),
                    // Circles per fioriture
                    CircleLayer(
                      circles: _fioriture.map((fioritura) {
                        try {
                          final lat = double.parse(fioritura['latitudine'].toString());
                          final lng = double.parse(fioritura['longitudine'].toString());
                          final raggio = fioritura['raggio'] != null ? double.parse(fioritura['raggio'].toString()) : 500.0;
                          
                          return CircleMarker(
                            point: LatLng(lat, lng),
                            radius: raggio,
                            color: Colors.green.withOpacity(0.3),
                            borderColor: Colors.green,
                            borderStrokeWidth: 2.0,
                            useRadiusInMeter: true,
                          );
                        } catch (e) {
                          print("Errore nel creare circle per fioritura: $e");
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
                    // Marker per fioriture
                    MarkerLayer(
                      markers: _fioriture.map((fioritura) {
                        try {
                          final lat = double.parse(fioritura['latitudine'].toString());
                          final lng = double.parse(fioritura['longitudine'].toString());
                          
                          return Marker(
                            width: 30.0,
                            height: 30.0,
                            point: LatLng(lat, lng),
                            builder: (ctx) => GestureDetector(
                              onTap: () {
                                // Mostra info fioritura
                                _showFiorituraInfo(fioritura);
                              },
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
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ),
                            ),
                          );
                        } catch (e) {
                          print("Errore nel creare marker per fioritura: $e");
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
                  right: 16,
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
                          SizedBox(height: 8),
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
                          SizedBox(height: 4),
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
                              Text('Fioritura'),
                            ],
                          ),
                          SizedBox(height: 4),
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
                
                // Contatore elementi
                Positioned(
                  left: 16,
                  top: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Elementi sulla mappa',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('Apiari: ${_apiari.length}', style: TextStyle(fontSize: 12)),
                          Text('Fioriture: ${_fioriture.length}', style: TextStyle(fontSize: 12)),
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
                      SizedBox(height: 8),
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
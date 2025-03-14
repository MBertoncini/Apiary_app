import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/drawer_widget.dart';

class MappaScreen extends StatefulWidget {
  @override
  _MappaScreenState createState() => _MappaScreenState();
}

class _MappaScreenState extends State<MappaScreen> {
  bool _isLoading = false;
  List<dynamic> _apiari = [];
  List<dynamic> _fioriture = [];
  Position? _currentPosition;
  MapController _mapController = MapController();
  
  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
    _loadData();
  }
  
  Future<void> _getCurrentPosition() async {
    try {
      // Verifica i permessi
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return;
      }
      
      // Ottieni posizione
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
      
      // Centra mappa sulla posizione corrente
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        11.0,
      );
    } catch (e) {
      print('Error getting current position: $e');
    }
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Carica apiari
      final apiari = await storageService.getStoredData('apiari');
      _apiari = apiari.where((a) => 
        a['latitudine'] != null && a['longitudine'] != null).toList();
      
      // Carica fioriture
      final fioriture = await storageService.getStoredData('fioriture');
      _fioriture = fioriture.where((f) => f['is_active'] == true).toList();
    } catch (e) {
      print('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il caricamento dei dati')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      drawer: AppDrawer(currentRoute: '/mappa'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition != null 
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : LatLng(41.9028, 12.4964), // Default a Roma
                    initialZoom: 9.0,
                    maxZoom: 18.0,
                    minZoom: 3.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.apiario_manager',
                    ),
                    // Marker per apiari
                    MarkerLayer(
                      markers: _apiari.map((apiario) {
                        final lat = double.parse(apiario['latitudine'].toString());
                        final lng = double.parse(apiario['longitudine'].toString());
                        
                        return Marker(
                          width: 50.0,
                          height: 50.0,
                          point: LatLng(lat, lng),
                          child: GestureDetector(
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
                                    apiario['nome'],
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
                      }).toList(),
                    ),
                    // Circles per fioriture
                    CircleLayer(
                      circles: _fioriture.map((fioritura) {
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
                      }).toList(),
                    ),
                    // Marker per fioriture
                    MarkerLayer(
                      markers: _fioriture.map((fioritura) {
                        final lat = double.parse(fioritura['latitudine'].toString());
                        final lng = double.parse(fioritura['longitudine'].toString());
                        
                        return Marker(
                          width: 30.0,
                          height: 30.0,
                          point: LatLng(lat, lng),
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
                        );
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
                            child: Container(
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
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentPosition,
        child: Icon(Icons.my_location),
        tooltip: 'Centra sulla posizione attuale',
      ),
    );
  }
}
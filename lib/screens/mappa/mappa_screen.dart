import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/osm_vegetazione.dart';
import '../../services/api_service.dart';
import '../../services/api_cache_helper.dart';
import '../../services/osm_vegetazione_service.dart';
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
  bool _showRaggioVolo = true; // raggio di volo api ~3km
  bool _showOsmVegetazione = false;
  bool _isLoadingOsm = false;
  List<OsmVegetazione> _osmVegetazione = [];
  Timer? _osmDebounceTimer;
  final OsmVegetazioneService _osmService = OsmVegetazioneService();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Non chiamiamo _checkLocationPermissions() né _loadData() qui
    // Li sposteremo in didChangeDependencies()
  }
  
  @override
  void dispose() {
    _osmDebounceTimer?.cancel();
    super.dispose();
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

          // Carica apiari dall'API (propri + gruppo) e community (pubblici altrui)
          final results = await Future.wait([
            apiService.get('apiari/'),
            apiService.get('apiari/community/').catchError((e) {
              debugPrint('Errore community apiari: $e');
              return <dynamic>[];
            }),
          ]);
          final apiariResp = results[0];
          final communityResp = results[1];
          if (apiariResp is List) {
            apiari = apiariResp;
          } else if (apiariResp is Map) {
            apiari = apiariResp['results'] ?? [];
          }
          final List<dynamic> communityApiari = communityResp is List
              ? communityResp
              : (communityResp is Map ? communityResp['results'] ?? [] : []);
          // Aggiungi marker community agli apiari, evitando duplicati
          final Set<dynamic> existingIds = apiari.map((a) => a['id']).toSet();
          for (final a in communityApiari) {
            if (!existingIds.contains(a['id'])) {
              apiari.add({...a, '_community': true});
            }
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
  
  // ── OSM Vegetazione ─────────────────────────────────────────────────────────

  Future<void> _toggleOsmVegetazione() async {
    final show = !_showOsmVegetazione;
    setState(() => _showOsmVegetazione = show);
    if (!show) {
      setState(() => _osmVegetazione = []);
      return;
    }
    final zoom = _mapController.zoom;
    if (zoom < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avvicinati per vedere la vegetazione OSM (zoom ≥ 10)'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    final bounds = _mapController.bounds;
    if (bounds != null) await _loadOsmVegetazione(bounds);
  }

  Future<void> _loadOsmVegetazione(LatLngBounds bounds) async {
    if (_isLoadingOsm) return;
    if (mounted) setState(() => _isLoadingOsm = true);
    try {
      final features = await _osmService.fetchVegetazione(
        south: bounds.south,
        west: bounds.west,
        north: bounds.north,
        east: bounds.east,
      );
      if (mounted) setState(() => _osmVegetazione = features);
    } catch (e) {
      debugPrint('OSM vegetation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Errore nel caricamento vegetazione OSM')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingOsm = false);
    }
  }

  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    int count = 0;
    for (int i = 0; i < polygon.length; i++) {
      final a = polygon[i];
      final b = polygon[(i + 1) % polygon.length];
      if ((a.latitude <= point.latitude && b.latitude > point.latitude) ||
          (b.latitude <= point.latitude && a.latitude > point.latitude)) {
        final t = (point.latitude - a.latitude) / (b.latitude - a.latitude);
        if (point.longitude < a.longitude + t * (b.longitude - a.longitude)) {
          count++;
        }
      }
    }
    return count % 2 == 1;
  }

  void _showOsmFeatureInfo(OsmVegetazione feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.forest, color: feature.colore),
            const SizedBox(width: 8),
            Expanded(
              child: Text(feature.etichetta, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...feature.tags.entries
                  .where((e) => [
                        'natural', 'landuse', 'crop', 'trees',
                        'species', 'wood', 'leaf_type', 'name'
                      ].contains(e.key))
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(
                                text: '${e.key}: ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              TextSpan(
                                text: e.value,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )),
              const SizedBox(height: 8),
              Text(
                'Fonte: OpenStreetMap contributors',
                style: TextStyle(
                    fontSize: 11,
                    color: ThemeConstants.textSecondaryColor),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  // ── Fine OSM ─────────────────────────────────────────────────────────────────

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
    final isCommunity = apiario['_community'] == true;
    final canNavigate = !isCommunity;
    final isSharedWithGroup = apiario['condiviso_con_gruppo'] == true;

    final Color headerColor = isCommunity
        ? Colors.orange.shade700
        : (isSharedWithGroup ? Colors.indigo.shade600 : ThemeConstants.primaryColor);

    final String typeBadge = isCommunity
        ? 'Community'
        : (isSharedWithGroup ? 'Condiviso' : 'Mio');

    final IconData typeIcon = isCommunity
        ? Icons.public
        : (isSharedWithGroup ? Icons.group : Icons.person_outline);

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: ThemeConstants.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Colored header card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [headerColor, headerColor.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.hive, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apiario['nome'] ?? 'Apiario',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (isCommunity && apiario['proprietario_username'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person, color: Colors.white70, size: 13),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    '${apiario['proprietario_username']}',
                                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (posizione.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.white70, size: 13),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    posizione,
                                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            typeBadge,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (!isCommunity) ...[
                      Expanded(
                        child: _statCard(Icons.hive_outlined, '$arnieCount', 'Arnie'),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (apiario['proprietario_username'] != null) ...[
                      Expanded(
                        child: _statCard(
                          Icons.person_outline,
                          '${apiario['proprietario_username']}',
                          'Apicoltore',
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: _statCard(
                        isCommunity ? Icons.public : Icons.lock_open_outlined,
                        isCommunity ? 'Community' : 'Tuo/Gruppo',
                        'Tipo',
                      ),
                    ),
                  ],
                ),
              ),
              // Notes
              if (apiario['note'] != null && apiario['note'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ThemeConstants.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, size: 16, color: ThemeConstants.textSecondaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            apiario['note'],
                            style: TextStyle(
                              fontSize: 13,
                              color: ThemeConstants.textSecondaryColor,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // Action button
              Padding(
                padding: const EdgeInsets.all(16),
                child: canNavigate
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _navigateToApiarioDetail(apiario['id']);
                          },
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Apri Apiario'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: headerColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: ThemeConstants.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ThemeConstants.dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility_outlined,
                                size: 18, color: ThemeConstants.textSecondaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Solo visualizzazione',
                              style: TextStyle(
                                fontSize: 14,
                                color: ThemeConstants.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: ThemeConstants.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ThemeConstants.dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: ThemeConstants.primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: ThemeConstants.textPrimaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
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

  void _handleMapTap(LatLng tappedPoint) {
    // Il tap sugli apiari è ora gestito da onMarkerTap del MarkerClusterLayerWidget.
    // Qui gestiamo solo il tap sui poligoni OSM.
    try {
      if (_showOsmVegetazione) {
        for (final feat in _osmVegetazione) {
          if (_pointInPolygon(tappedPoint, feat.punti)) {
            _showOsmFeatureInfo(feat);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('_handleMapTap error: $e');
    }
  }

  /// Genera un colore stabile a partire da una stringa (es. username)
  Color _colorFromString(String s) {
    final hue = (s.codeUnits.fold(0, (a, b) => a + b) * 37) % 360;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.55, 0.45).toColor();
  }

  List<Marker> _buildApiariMarkers() {
    final result = <Marker>[];
    for (final apiario in _apiari) {
      try {
        final lat = double.parse(apiario['latitudine'].toString());
        final lng = double.parse(apiario['longitudine'].toString());
        final isCommunity = apiario['_community'] == true;
        final isGroup = apiario['condiviso_con_gruppo'] == true;
        final markerColor = isCommunity
            ? Colors.orange.shade700
            : (isGroup ? Colors.indigo.shade600 : ThemeConstants.primaryColor);
        final arnieNum = _getArnieCountForApiario(apiario['id']);
        final username = apiario['proprietario_username'] as String?;
        final avatarInitial = (username != null && username.isNotEmpty)
            ? username[0].toUpperCase()
            : null;
        final avatarColor = username != null ? _colorFromString(username) : null;
        // Campo immagine profilo proprietario (campo restituito dall'API)
        final proprietarioFoto =
            (apiario['proprietario_immagine_profilo'] as String?)?.trim().isNotEmpty == true
                ? apiario['proprietario_immagine_profilo'] as String
                : (apiario['proprietario_profile_image'] as String?)?.trim().isNotEmpty == true
                    ? apiario['proprietario_profile_image'] as String
                    : null;

        // Chiave: 'c_<id>' per community, 'a_<id>' per propri/gruppo
        final markerKey = isCommunity
            ? ValueKey('c_${apiario['id']}')
            : ValueKey('a_${apiario['id']}');

        result.add(Marker(
          key: markerKey,
          width: 64.0,
          height: 58.0,
          point: LatLng(lat, lng),
          builder: (ctx) => Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: markerColor.withOpacity(0.45),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.hive, color: Colors.white, size: 20),
                  ),
                ),
              ),
              // Avatar proprietario in alto a sinistra
              if (avatarInitial != null)
                Positioned(
                  top: 0,
                  left: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    child: ClipOval(
                      child: proprietarioFoto != null
                          ? CachedNetworkImage(
                              imageUrl: proprietarioFoto,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Center(
                                child: Text(
                                  avatarInitial,
                                  style: const TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              placeholder: (_, __) => const SizedBox.shrink(),
                            )
                          : Center(
                              child: Text(
                                avatarInitial,
                                style: const TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              if (arnieNum > 0)
                Positioned(
                  top: 0,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: markerColor, width: 1.5),
                    ),
                    child: Text(
                      '$arnieNum',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: markerColor,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 3),
                      ],
                    ),
                    child: Text(
                      apiario['nome'] ?? 'Apiario',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
      } catch (e) {
        debugPrint('Errore marker apiario: $e');
      }
    }
    return result;
  }

  List<Marker> _buildFioritureMarkers() {
    final result = <Marker>[];
    for (final fioritura in _fioriture) {
      try {
        final lat = double.parse(fioritura['latitudine'].toString());
        final lng = double.parse(fioritura['longitudine'].toString());
        final isActive = fioritura['_isActive'] == true;

        result.add(Marker(
          key: ValueKey('fioritura_${fioritura['id']}'),
          width: 26.0,
          height: 26.0,
          point: LatLng(lat, lng),
          builder: (ctx) => GestureDetector(
            onTap: () => _showFiorituraInfo(fioritura),
            child: Opacity(
              opacity: isActive ? 0.82 : 0.45,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 2),
                  ],
                ),
                child: Icon(
                  Icons.local_florist,
                  color: isActive ? Colors.green.shade600 : Colors.grey,
                  size: 14,
                ),
              ),
            ),
          ),
        ));
      } catch (e) {
        debugPrint('Errore marker fioritura: $e');
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'Mappa Apiari',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isOffline)
              Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: Tooltip(
                  message: 'Modalità offline - Dati caricati dalla cache',
                  child: Icon(Icons.offline_bolt, size: 16, color: Colors.amber),
                ),
              ),
          ],
        ),
        actions: [
          // Vegetazione OSM
          if (_isLoadingOsm)
            const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.forest,
                color: _showOsmVegetazione
                    ? Colors.green.shade300
                    : Colors.white,
              ),
              tooltip: _showOsmVegetazione
                  ? 'Nascondi vegetazione OSM'
                  : 'Mostra vegetazione OSM',
              onPressed: _toggleOsmVegetazione,
            ),
          IconButton(
            icon: Icon(
              _showRaggioVolo ? Icons.radar : Icons.radar_outlined,
              color: _showRaggioVolo ? Colors.amber : null,
            ),
            tooltip: _showRaggioVolo ? 'Nascondi raggio di volo' : 'Mostra raggio di volo (3 km)',
            onPressed: () => setState(() => _showRaggioVolo = !_showRaggioVolo),
          ),
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
                    onTap: (tapPosition, point) => _handleMapTap(point),
                    onPositionChanged: (MapPosition position, bool hasGesture) {
                      if (!_showOsmVegetazione || !hasGesture) return;
                      final zoom = position.zoom ?? 0;
                      if (zoom < 10) return;
                      _osmDebounceTimer?.cancel();
                      _osmDebounceTimer =
                          Timer(const Duration(milliseconds: 1500), () {
                        final bounds = position.bounds;
                        if (bounds != null && mounted) {
                          _loadOsmVegetazione(bounds);
                        }
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.apiario_manager',
                    ),
                    // Layer vegetazione OSM (sotto tutto il resto)
                    if (_showOsmVegetazione && _osmVegetazione.isNotEmpty)
                      PolygonLayer(
                        polygonCulling: true,
                        polygons: _osmVegetazione
                            .map((f) => Polygon(
                                  points: f.punti,
                                  color: f.colore.withOpacity(0.22),
                                  borderColor: f.colore.withOpacity(0.65),
                                  borderStrokeWidth: 1.5,
                                  isFilled: true,
                                ))
                            .toList(),
                      ),
                    // Raggio di volo (3 km) per ogni apiario
                    if (_showRaggioVolo)
                      CircleLayer(
                        circles: _apiari.map((apiario) {
                          try {
                            final lat = double.parse(apiario['latitudine'].toString());
                            final lng = double.parse(apiario['longitudine'].toString());
                            return CircleMarker(
                              point: LatLng(lat, lng),
                              radius: 3000,
                              color: Colors.amber.withOpacity(0.08),
                              borderColor: Colors.amber.withOpacity(0.55),
                              borderStrokeWidth: 1.5,
                              useRadiusInMeter: true,
                            );
                          } catch (_) {
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
                    // ── FIORITURE (sotto gli apiari) ───────────────────────────
                    // Cerchi area fioritura
                    CircleLayer(
                      circles: _fioriture.map((fioritura) {
                        try {
                          final lat = double.parse(fioritura['latitudine'].toString());
                          final lng = double.parse(fioritura['longitudine'].toString());
                          final raggio = fioritura['raggio'] != null
                              ? double.parse(fioritura['raggio'].toString())
                              : 500.0;
                          final isActive = fioritura['_isActive'] == true;
                          return CircleMarker(
                            point: LatLng(lat, lng),
                            radius: raggio,
                            color: (isActive ? Colors.green : Colors.grey)
                                .withOpacity(isActive ? 0.18 : 0.10),
                            borderColor: (isActive ? Colors.green : Colors.grey)
                                .withOpacity(isActive ? 0.55 : 0.30),
                            borderStrokeWidth: isActive ? 1.5 : 1.0,
                            useRadiusInMeter: true,
                          );
                        } catch (e) {
                          debugPrint("Errore cerchio fioritura: $e");
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
                    // Marker fioriture con clustering — semitrasparenti
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 70,
                        size: const Size(36, 36),
                        animationsOptions: const AnimationsOptions(
                          zoom: Duration(milliseconds: 300),
                          fitBound: Duration(milliseconds: 300),
                          centerMarker: Duration(milliseconds: 200),
                          spiderfy: Duration(milliseconds: 200),
                        ),
                        fitBoundsOptions: const FitBoundsOptions(
                          padding: EdgeInsets.all(60),
                          maxZoom: 15,
                        ),
                        markers: _buildFioritureMarkers(),
                        builder: (ctx, markers) {
                          final hasActive = markers.any(
                            (m) => (m.key as ValueKey?)?.value
                                    .toString()
                                    .startsWith('fioritura_') ==
                                true,
                          );
                          final clusterColor =
                              hasActive ? Colors.green.shade600 : Colors.grey;
                          return Opacity(
                            opacity: 0.82,
                            child: Container(
                              decoration: BoxDecoration(
                                color: clusterColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: clusterColor.withOpacity(0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.local_florist,
                                      color: Colors.white, size: 14),
                                  Text(
                                    '${markers.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // ── APIARI (sopra le fioriture) ────────────────────────────
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 90,
                        size: const Size(44, 44),
                        animationsOptions: const AnimationsOptions(
                          zoom: Duration(milliseconds: 300),
                          fitBound: Duration(milliseconds: 300),
                          centerMarker: Duration(milliseconds: 200),
                          spiderfy: Duration(milliseconds: 200),
                        ),
                        fitBoundsOptions: const FitBoundsOptions(
                          padding: EdgeInsets.all(60),
                          maxZoom: 14,
                        ),
                        markers: _buildApiariMarkers(),
                        onMarkerTap: (marker) {
                          final keyVal =
                              (marker.key as ValueKey?)?.value?.toString() ?? '';
                          final id = int.tryParse(keyVal.split('_').last);
                          if (id != null) {
                            final found = _apiari
                                .cast<Map<String, dynamic>?>()
                                .firstWhere(
                                  (a) => a != null && a['id'] == id,
                                  orElse: () => null,
                                );
                            if (found != null) {
                              _showApiarioInfo(Map<String, dynamic>.from(found));
                            }
                          }
                        },
                        builder: (ctx, markers) {
                          final allCommunity = markers.every(
                            (m) =>
                                (m.key as ValueKey?)
                                    ?.value
                                    ?.toString()
                                    .startsWith('c_') ==
                                true,
                          );
                          final clusterColor = allCommunity
                              ? Colors.orange.shade700
                              : ThemeConstants.primaryColor;
                          return Container(
                            decoration: BoxDecoration(
                              color: clusterColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: clusterColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.hive, color: Colors.white, size: 17),
                                Text(
                                  '${markers.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // ── Posizione attuale (piccola, non invasiva) ──────────────
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 18.0,
                            height: 18.0,
                            point: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            builder: (ctx) => Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.4),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
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
                          if (_showRaggioVolo)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.amber.withOpacity(0.55),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Raggio volo (3 km)'),
                              ],
                            ),
                          if (_showRaggioVolo) const SizedBox(height: 4),
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
                          if (_showOsmVegetazione) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32)
                                        .withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                        color: const Color(0xFF2E7D32)
                                            .withOpacity(0.65)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Bosco / Foresta'),
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
                                    color: const Color(0xFF689F38)
                                        .withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                        color: const Color(0xFF689F38)
                                            .withOpacity(0.65)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Macchia'),
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
                                    color: const Color(0xFF9CCC65)
                                        .withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                        color: const Color(0xFF9CCC65)
                                            .withOpacity(0.65)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Prato / Pascolo'),
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
                                    color: const Color(0xFF00897B)
                                        .withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                        color: const Color(0xFF00897B)
                                            .withOpacity(0.65)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Frutteto'),
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
                                    color: const Color(0xFFF9A825)
                                        .withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                        color: const Color(0xFFF9A825)
                                            .withOpacity(0.65)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Coltura'),
                              ],
                            ),
                          ],
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "btnNuovaFiorituraMappa",
            mini: true,
            tooltip: 'Aggiungi fioritura',
            onPressed: () async {
              final result = await Navigator.of(context)
                  .pushNamed(AppConstants.fiorituraCreateRoute);
              if (result == true) _loadData();
            },
            child: Icon(Icons.eco),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "btnPosition",
            onPressed: _getCurrentPosition,
            child: Icon(Icons.my_location),
            tooltip: 'Centra sulla posizione attuale',
          ),
        ],
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
                if ((fioritura['n_conferme'] ?? 0) > 0)
                  ListTile(
                    leading: Icon(Icons.people_outline, size: 18),
                    title: Text('Conferme community'),
                    subtitle: Text(
                      fioritura['intensita_media'] != null
                          ? '${fioritura['n_conferme']} apicoltori · intensità media ${(fioritura['intensita_media'] as num).toStringAsFixed(1)}/5'
                          : '${fioritura['n_conferme']} apicoltori',
                    ),
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
            ElevatedButton.icon(
              icon: Icon(Icons.open_in_new, size: 16),
              label: Text('Dettaglio'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(
                  AppConstants.fiorituraDetailRoute,
                  arguments: fioritura['id'] as int,
                );
              },
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../constants/api_constants.dart';
import '../../l10n/app_strings.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/drawer_widget.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/skeleton_widgets.dart';

class ApiarioListScreen extends StatefulWidget {
  @override
  _ApiarioListScreenState createState() => _ApiarioListScreenState();
}

class _ApiarioListScreenState extends State<ApiarioListScreen> {
  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  bool _isLoading = false;
  bool _isRefreshing = true;
  List<dynamic> _allApiari = [];  // Dati completi (non filtrati)
  String _searchQuery = '';

  /// Getter che filtra e ordina in modo efficiente senza ricreare la lista se la query è vuota
  List<dynamic> get _apiari {
    if (_searchQuery.isEmpty) return _allApiari;
    final query = _searchQuery.toLowerCase();
    return _allApiari.where((apiario) =>
      apiario['nome'].toLowerCase().contains(query) ||
      (apiario['posizione'] != null && apiario['posizione'].toLowerCase().contains(query))
    ).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadApiari();
  }

  /// Restituisce true se l'utente può modificare l'apiario:
  /// - è il proprietario, oppure
  /// - il gruppo che ha condiviso l'apiario esiste tra i gruppi dell'utente
  ///   e l'utente ha ruolo creatore/admin/editor in quel gruppo.
  bool _canEdit(dynamic apiario, int currentUserId, List<dynamic> gruppi) {
    if (apiario['proprietario'] == currentUserId) return true;
    if (apiario['condiviso_con_gruppo'] != true || apiario['gruppo'] == null) return false;

    final apiarioGruppoId = apiario['gruppo'];
    for (final g in gruppi) {
      final gId = g['id'] is String ? int.tryParse(g['id']) : g['id'];
      if (gId != apiarioGruppoId) continue;

      // Creatore del gruppo → sempre admin
      final creatoreId = g['creatore'] is Map
          ? g['creatore']['id']
          : (g['creatore'] is String ? int.tryParse(g['creatore'].toString()) : g['creatore']);
      if (creatoreId == currentUserId) return true;

      // Controlla i membri (presenti solo se il gruppo è stato caricato in dettaglio)
      final membri = g['membri'];
      if (membri is List) {
        for (final m in membri) {
          final utenteId = m['utente'] is String ? int.tryParse(m['utente'].toString()) : m['utente'];
          if (utenteId == currentUserId) {
            final ruolo = m['ruolo'] as String?;
            return ruolo == 'admin' || ruolo == 'editor';
          }
        }
      }
      // Il gruppo è presente ma senza dettaglio membri: l'utente non è creatore,
      // quindi non possiamo confermare i permessi → escludiamo per sicurezza.
      return false;
    }
    return false;
  }

  List<dynamic> _filterEditable(List<dynamic> apiari, int currentUserId, List<dynamic> gruppi) {
    return apiari.where((a) => _canEdit(a, currentUserId, gruppi)).toList();
  }

  Future<void> _loadApiari() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.id;
    if (currentUserId == null) {
      if (mounted) setState(() { _isLoading = false; _isRefreshing = false; });
      return;
    }

    // Fase 1: cache — mostra subito senza spinner
    final cachedApiari = await storageService.getStoredData('apiari');
    final cachedGruppi = await storageService.getStoredData('gruppi');
    if (cachedApiari.isNotEmpty) {
      _allApiari = _filterEditable(List<dynamic>.from(cachedApiari), currentUserId, cachedGruppi)
        ..sort((a, b) => a['nome'].compareTo(b['nome']));
      if (mounted) setState(() { _isLoading = false; _isRefreshing = true; });
    } else {
      if (mounted) setState(() { _isRefreshing = true; });
    }

    // Fase 2: aggiornamento dal server (apiari + gruppi in parallelo)
    try {
      final results = await Future.wait([
        apiService.get(ApiConstants.apiariUrl),
        apiService.get(ApiConstants.gruppiUrl).catchError((e) {
          debugPrint('Errore caricamento gruppi: $e');
          return cachedGruppi;
        }),
      ]);

      List<dynamic> apiariFromApi = _parseList(results[0]);
      List<dynamic> gruppiFromApi = _parseList(results[1] is List ? results[1] : cachedGruppi);

      if (gruppiFromApi.isNotEmpty) {
        await storageService.saveData('gruppi', gruppiFromApi);
      } else {
        gruppiFromApi = cachedGruppi;
      }

      // Per i gruppi dove l'utente NON è creatore, carica il dettaglio (con membri)
      // per verificare il ruolo admin/editor. Solo per gruppi che hanno apiari condivisi.
      final sharedGruppoIds = apiariFromApi
          .where((a) => a['proprietario'] != currentUserId && a['condiviso_con_gruppo'] == true && a['gruppo'] != null)
          .map((a) => a['gruppo'])
          .toSet();

      if (sharedGruppoIds.isNotEmpty) {
        final detailFutures = sharedGruppoIds.map((gId) async {
          // Se già creatore nel gruppo, non serve caricare i dettagli
          final cached = gruppiFromApi.firstWhere(
            (g) {
              final creatoreId = g['creatore'] is Map ? g['creatore']['id'] : g['creatore'];
              final gIdParsed = g['id'] is String ? int.tryParse(g['id']) : g['id'];
              return gIdParsed == gId && creatoreId == currentUserId;
            },
            orElse: () => null,
          );
          if (cached != null) return;

          try {
            final detail = await apiService.get('${ApiConstants.gruppiUrl}$gId/');
            if (detail is Map) {
              final idx = gruppiFromApi.indexWhere((g) {
                final gIdParsed = g['id'] is String ? int.tryParse(g['id']) : g['id'];
                return gIdParsed == gId;
              });
              if (idx >= 0) {
                gruppiFromApi[idx] = detail;
              }
            }
          } catch (e) {
            debugPrint('Errore caricamento dettaglio gruppo $gId: $e');
          }
        });
        await Future.wait(detailFutures);
      }

      if (apiariFromApi.isNotEmpty) {
        await storageService.saveData('apiari', apiariFromApi);
        _allApiari = _filterEditable(apiariFromApi, currentUserId, gruppiFromApi)
          ..sort((a, b) => a['nome'].compareTo(b['nome']));
      }
    } catch (e) {
      debugPrint('Error fetching apiari from API, using cache: $e');
    }

    if (mounted) setState(() { _isLoading = false; _isRefreshing = false; });
  }

  List<dynamic> _parseList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      if (response['results'] is List) return response['results'];
      for (final key in ['apiari', 'gruppi', 'data', 'items']) {
        if (response[key] is List) return response[key];
      }
      if (response.containsKey('id')) return [response];
    }
    return [];
  }

  void _navigateToApiarioDetail(int apiarioId) {
    Navigator.of(context).pushNamed(
      AppConstants.apiarioDetailRoute,
      arguments: apiarioId,
    );
  }

  void _navigateToApiarioCreate() {
    Navigator.of(context).pushNamed(AppConstants.apiarioCreateRoute);
  }

  /// Filtra localmente senza ricaricare dall'API
  void _searchApiari(String query) {
    setState(() {
      _searchQuery = query;
    });
  }
  
  Widget _buildApiarioCard(dynamic apiario) {
    bool hasCoordinates = apiario['latitudine'] != null && apiario['longitudine'] != null;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: () => _navigateToApiarioDetail(apiario['id']),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      apiario['nome'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      apiario['posizione'] ?? _s.dashPositionNone,
                      style: TextStyle(
                        color: ThemeConstants.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (hasCoordinates)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ThemeConstants.secondaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map,
                            size: 12,
                            color: ThemeConstants.secondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _s.apiarioBadgeMap,
                            style: TextStyle(
                              fontSize: 12,
                              color: ThemeConstants.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (apiario['monitoraggio_meteo'] == true)
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wb_sunny,
                            size: 12,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _s.apiarioBadgeMeteo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (apiario['condiviso_con_gruppo'] == true)
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.group,
                            size: 12,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _s.apiarioBadgeShared,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple,
                            ),
                          ),
                        ],
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
  
  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context); // rebuild on language change
    return Scaffold(
      appBar: AppBar(
        title: Text(_s.apiarioListTitle),
      ),
      drawer: AppDrawer(currentRoute: AppConstants.apiarioListRoute),
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: _s.apiarioSearchHint,
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchApiari('');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchApiari,
            ),
          ),
          
          // Lista apiari
          Expanded(
            child: _isRefreshing && _allApiari.isEmpty
                ? const SkeletonListView(itemCount: 4)
                : _apiari.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hive_outlined,
                              size: 64,
                              color: ThemeConstants.textSecondaryColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? _s.apiarioNotFoundForQuery(_searchQuery)
                                  : _s.dashNoApiari,
                              style: TextStyle(
                                color: ThemeConstants.textSecondaryColor,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            if (_searchQuery.isEmpty)
                              ElevatedButton.icon(
                                onPressed: _navigateToApiarioCreate,
                                icon: Icon(Icons.add),
                                label: Text(_s.dashBtnCreateApiario),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadApiari,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _apiari.length,
                          itemBuilder: (context, index) {
                            return _buildApiarioCard(_apiari[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToApiarioCreate,
        child: Icon(Icons.add),
        tooltip: _s.apiarioFabTooltip,
      ),
    );
  }
}
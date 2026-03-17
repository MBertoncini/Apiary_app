import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/drawer_widget.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/skeleton_widgets.dart';

class ApiarioListScreen extends StatefulWidget {
  @override
  _ApiarioListScreenState createState() => _ApiarioListScreenState();
}

class _ApiarioListScreenState extends State<ApiarioListScreen> {
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

  Future<void> _loadApiari() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);

    // Fase 1: cache — mostra subito senza spinner
    final cached = await storageService.getStoredData('apiari');
    if (cached.isNotEmpty) {
      _allApiari = List<dynamic>.from(cached)
        ..sort((a, b) => a['nome'].compareTo(b['nome']));
      if (mounted) setState(() { _isLoading = false; _isRefreshing = true; });
    } else {
      if (mounted) setState(() { _isRefreshing = true; });
    }

    // Fase 2: aggiornamento dal server
    try {
      final response = await apiService.get(ApiConstants.apiariUrl);
      List<dynamic> apiariFromApi = [];
      if (response is List) {
        apiariFromApi = response;
      } else if (response is Map) {
        if (response.containsKey('results') && response['results'] is List) {
          apiariFromApi = response['results'];
        } else {
          for (var key in ['apiari', 'data', 'items']) {
            if (response.containsKey(key) && response[key] is List) {
              apiariFromApi = response[key];
              break;
            }
          }
          if (apiariFromApi.isEmpty && response.containsKey('id')) {
            apiariFromApi = [response];
          }
        }
      }
      if (apiariFromApi.isNotEmpty) {
        await storageService.saveData('apiari', apiariFromApi);
        apiariFromApi.sort((a, b) => a['nome'].compareTo(b['nome']));
        _allApiari = apiariFromApi;
      }
    } catch (e) {
      debugPrint('Error fetching apiari from API, using cache: $e');
    }

    if (mounted) setState(() { _isLoading = false; _isRefreshing = false; });
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
                      apiario['posizione'] ?? 'Posizione non specificata',
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
                            'Mappa',
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
                            'Meteo',
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
                            'Condiviso',
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
    return Scaffold(
      appBar: AppBar(
        title: Text('I tuoi apiari'),
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
                hintText: 'Cerca per nome o posizione...',
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
                                  ? 'Nessun apiario trovato con "$_searchQuery"'
                                  : 'Nessun apiario disponibile',
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
                                label: Text('Crea nuovo apiario'),
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
        tooltip: 'Aggiungi apiario',
      ),
    );
  }
}
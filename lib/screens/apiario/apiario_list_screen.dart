import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/drawer_widget.dart';

class ApiarioListScreen extends StatefulWidget {
  @override
  _ApiarioListScreenState createState() => _ApiarioListScreenState();
}

class _ApiarioListScreenState extends State<ApiarioListScreen> {
  bool _isLoading = false;
  List<dynamic> _apiari = [];
  String _searchQuery = '';
  late ApiService _apiService;
  
  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiService>(context, listen: false);
    _loadApiari();
  }
  
  Future<void> _loadApiari() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Prima tenta di caricare i dati dall'API
      try {
        print('Fetching apiari from API...');
        final response = await apiService.get(ApiConstants.apiariUrl);
        print('API response for apiari: $response');
        
        List<dynamic> apiariFromApi = [];
        
        // Gestione robusta per diversi formati di risposta
        if (response is List) {
          apiariFromApi = response;
          print('Parsed ${apiariFromApi.length} apiari from API (direct array)');
        } else if (response is Map) {
          // Django REST Framework tipicamente usa questo formato di paginazione
          if (response.containsKey('results') && response['results'] is List) {
            apiariFromApi = response['results'];
            print('Parsed ${apiariFromApi.length} apiari from API (DRF pagination format)');
          } 
          // Potrebbe essere un oggetto che contiene un array in una proprietà
          else {
            bool found = false;
            for (var key in ['apiari', 'data', 'items']) {
              if (response.containsKey(key) && response[key] is List) {
                apiariFromApi = response[key];
                print('Parsed ${apiariFromApi.length} apiari from API (nested in "$key" property)');
                found = true;
                break;
              }
            }
            
            if (!found && response.containsKey('id')) {
              // Potrebbe essere un singolo apiario
              apiariFromApi = [response];
              print('Parsed a single apiario from API response');
            }
          }
        }
        
        // Salva i dati aggiornati nello storage locale
        await storageService.saveData('apiari', apiariFromApi);
        
        // Usa i dati dall'API
        _apiari = apiariFromApi;
        
      } catch (e) {
        print('Error fetching from API, falling back to local storage: $e');
        
        // Fallback: carica da storage locale se l'API fallisce
        _apiari = await storageService.getStoredData('apiari');
        print('Loaded ${_apiari.length} apiari from local storage');
      }
      
      // Filtra in base alla ricerca
      if (_searchQuery.isNotEmpty) {
        _apiari = _apiari.where((apiario) => 
          apiario['nome'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (apiario['posizione'] != null && apiario['posizione'].toLowerCase().contains(_searchQuery.toLowerCase()))
        ).toList();
      }
      
      // Ordina per nome
      _apiari.sort((a, b) => a['nome'].compareTo(b['nome']));
    } catch (e) {
      print('Error loading apiari: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il caricamento degli apiari')),
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
  
  void _navigateToApiarioCreate() {
    Navigator.of(context).pushNamed(AppConstants.apiarioCreateRoute);
  }
  
  void _searchApiari(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadApiari();
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
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                  SizedBox(width: 4),
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
              SizedBox(height: 8),
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
                          SizedBox(width: 4),
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
                          SizedBox(width: 4),
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
                          SizedBox(width: 4),
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
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
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
                            SizedBox(height: 16),
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
                            SizedBox(height: 16),
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
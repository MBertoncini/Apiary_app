import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/jokes_service.dart'; // Servizio per le freddure
import '../widgets/drawer_widget.dart';
import '../widgets/bee_joke_bubble.dart'; // Widget fumetto
import '../models/gruppo.dart'; // Import Gruppo model
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../screens/mobile_scanner_wrapper_screen.dart'; // Aggiorna percorso in base alla struttura del tuo progetto

// Create a separate StatefulWidget for the dashboard screen
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Variabili dati generali
  List<dynamic> _apiari = [];
  List<dynamic> _trattamenti = [];
  List<dynamic> _fioriture = [];
  DateTime _lastSyncTime = DateTime.now();
  Gruppo? _gruppo;
  
  // Variabili per la gestione del caricamento
  bool _isLoadingApiari = true;
  bool _isLoadingTrattamenti = true;
  bool _isLoadingFioriture = true;
  String? _apiariError;
  String? _trattamentiError;
  String? _fioritureError;
  
  // Variabili per funzionalità aggiuntive
  Map<String, dynamic>? _weatherData;
  Map<String, List<dynamic>> _calendarEvents = {};
  
  // Variabili per ricerca e filtri
  bool _isFiltering = false;
  List<dynamic> _filteredApiari = [];
  List<dynamic> _filteredTrattamenti = [];
  List<dynamic> _filteredFioriture = [];
  bool _filterApiari = false;
  bool _filterTrattamentiAttivi = false;
  bool _filterFioritureAttive = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  // METODI DI CARICAMENTO DATI
  
  Future<void> _loadData() async {
    setState(() {
      _isLoadingApiari = true;
      _isLoadingTrattamenti = true;
      _isLoadingFioriture = true;
    });
    
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    // Carica i vari dati in parallelo
    await Future.wait([
      _loadApiariData(apiService),
      _loadTrattamentiData(apiService),
      _loadFioritureData(apiService),
    ]);
    
    // Aggiorna l'orario di sincronizzazione
    setState(() {
      _lastSyncTime = DateTime.now();
    });
    
    // Prepara i dati per il calendario e altre visualizzazioni
    _prepareCalendarEvents();
    await _loadWeatherData();
  }

  Future<void> _loadApiariData(ApiService apiService) async {
    try {
      final apiariResponse = await apiService.get('apiari/');
      setState(() {
        _apiari = apiariResponse['results'] ?? [];
        _isLoadingApiari = false;
      });
    } catch (e) {
      print('Error fetching apiari: $e');
      setState(() {
        _apiariError = e.toString();
        _isLoadingApiari = false;
      });
    }
  }

  Future<void> _loadTrattamentiData(ApiService apiService) async {
    try {
      final trattamentiResponse = await apiService.get('trattamenti/');
      setState(() {
        _trattamenti = trattamentiResponse['results'] ?? [];
        _isLoadingTrattamenti = false;
      });
    } catch (e) {
      print('Error fetching trattamenti: $e');
      setState(() {
        _trattamentiError = e.toString();
        _isLoadingTrattamenti = false;
      });
    }
  }

  Future<void> _loadFioritureData(ApiService apiService) async {
    try {
      final fioritureResponse = await apiService.get('fioriture/');
      setState(() {
        _fioriture = fioritureResponse['results'] ?? [];
        _isLoadingFioriture = false;
      });
    } catch (e) {
      print('Error fetching fioriture: $e');
      setState(() {
        _fioritureError = e.toString();
        _isLoadingFioriture = false;
      });
    }
  }
  
  Future<void> _loadWeatherData() async {
    if (_apiari.isEmpty) return;
    
    try {
      // Utilizza la posizione del primo apiario
      var apiario = _apiari[0];
      if (apiario['latitudine'] != null && apiario['longitudine'] != null) {
        final apiService = Provider.of<ApiService>(context, listen: false);
        
        // Endpoint meteo (da implementare sul backend, o usare API esterna)
        final weatherResponse = await apiService.get(
          'meteo/?lat=${apiario['latitudine']}&lon=${apiario['longitudine']}',
        );
        
        setState(() {
          _weatherData = weatherResponse;
        });
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }
  
  Future<void> _refreshData() async {
    // Mostra messaggio di feedback durante la sincronizzazione
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 20, 
              width: 20, 
              child: CircularProgressIndicator(strokeWidth: 2)
            ),
            SizedBox(width: 12),
            Text('Sincronizzazione in corso...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );
    
    await _loadData();
    
    // Mostra conferma
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dati aggiornati!'),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  void _prepareCalendarEvents() {
    _calendarEvents = {};
    
    // Aggiungi i trattamenti al calendario
    for (var t in _trattamenti) {
      if (t['data_inizio'] != null) {
        DateTime date = DateTime.parse(t['data_inizio']);
        String day = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        
        if (!_calendarEvents.containsKey(day)) {
          _calendarEvents[day] = [];
        }
        
        _calendarEvents[day]!.add({
          'type': 'trattamento',
          'title': t['tipo_trattamento_nome'] ?? 'Trattamento',
          'id': t['id'],
          'color': Colors.orange,
        });
      }
    }
    
    // Aggiungi le fioriture al calendario
    for (var f in _fioriture) {
      if (f['data_inizio'] != null) {
        DateTime date = DateTime.parse(f['data_inizio']);
        String day = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        
        if (!_calendarEvents.containsKey(day)) {
          _calendarEvents[day] = [];
        }
        
        _calendarEvents[day]!.add({
          'type': 'fioritura',
          'title': f['pianta'] ?? 'Fioritura',
          'id': f['id'],
          'color': Colors.green,
        });
      }
    }
  }
  
  // METODI DI NAVIGAZIONE
  
  void _navigateToApiarioDetail(int apiarioId) {
    Navigator.of(context).pushNamed(
      AppConstants.apiarioDetailRoute,
      arguments: apiarioId,
    );
  }
  
  void _navigateToApiarioCreate() {
    Navigator.of(context).pushNamed(AppConstants.apiarioCreateRoute);
  }
  
  // Metodo per mostrare la freddura
  Future<void> _showBeeJoke() async {
    try {
      final joke = await JokesService.getRandomJoke();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return BeeJokeDialog(joke: joke);
        },
      );
    } catch (e) {
      print('Errore nel mostrare la freddura: $e');
    }
  }
  
  // METODI DI UTILITY
  
  String _formatLastSync() {
    return "${_lastSyncTime.day.toString().padLeft(2, '0')}/${_lastSyncTime.month.toString().padLeft(2, '0')}/${_lastSyncTime.year} ${_lastSyncTime.hour.toString().padLeft(2, '0')}:${_lastSyncTime.minute.toString().padLeft(2, '0')}";
  }
  
  int _getActiveTrattamentiCount() {
    return _trattamenti.where((t) => 
      t['stato'] == 'in_corso' || t['stato'] == 'programmato').length;
  }
  
  int _getActiveFioritureCount() {
    return _fioriture.where((f) => f['is_active'] == true).length;
  }
  
  // WIDGETS PER LA DASHBOARD
  
  Widget _buildSearchBar() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Cerca apiari, trattamenti...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
            suffixIcon: IconButton(
              icon: Icon(Icons.tune),
              onPressed: () {
                // Mostra opzioni filtro/ricerca avanzata
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _buildFilterOptions(),
                );
              },
            ),
          ),
          onChanged: (value) {
            // Implementa la ricerca locale nei dati esistenti
            if (value.length > 2) {
              setState(() {
                _filteredApiari = _apiari.where((a) => 
                  a['nome'].toString().toLowerCase().contains(value.toLowerCase())).toList();
                _filteredTrattamenti = _trattamenti.where((t) => 
                  (t['tipo_trattamento_nome']?.toString() ?? '').toLowerCase().contains(value.toLowerCase()) ||
                  (t['apiario_nome']?.toString() ?? '').toLowerCase().contains(value.toLowerCase())).toList();
                _filteredFioriture = _fioriture.where((f) => 
                  (f['pianta']?.toString() ?? '').toLowerCase().contains(value.toLowerCase()) ||
                  (f['apiario_nome']?.toString() ?? '').toLowerCase().contains(value.toLowerCase())).toList();
                _isFiltering = true;
              });
            } else if (_isFiltering) {
              setState(() {
                _isFiltering = false;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtra per',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text('Apiari'),
                selected: _filterApiari,
                onSelected: (selected) {
                  setState(() {
                    _filterApiari = selected;
                  });
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: Text('Trattamenti attivi'),
                selected: _filterTrattamentiAttivi,
                onSelected: (selected) {
                  setState(() {
                    _filterTrattamentiAttivi = selected;
                  });
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: Text('Fioriture attive'),
                selected: _filterFioritureAttive,
                onSelected: (selected) {
                  setState(() {
                    _filterFioritureAttive = selected;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterApiari = false;
                    _filterTrattamentiAttivi = false;
                    _filterFioritureAttive = false;
                    _isFiltering = false;
                  });
                  Navigator.pop(context);
                },
                child: Text('Resetta filtri'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionWithLoading({
    required String title, 
    required bool isLoading, 
    String? error,
    required Widget Function() builder,
    Widget Function()? emptyBuilder,
    Function()? onViewAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: ThemeConstants.subheadingStyle,
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: Text('Vedi tutti'),
              ),
          ],
        ),
        SizedBox(height: 8),
        if (isLoading)
          Container(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (error != null)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Errore nel caricamento dei dati: $error',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.red),
                  onPressed: _refreshData,
                ),
              ],
            ),
          )
        else
          builder(),
      ],
    );
  }
  
  // WIDGETS PER LE CARD E VISUALIZZAZIONI
  
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: ThemeConstants.textSecondaryColor,
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    // Replace with a default value or proper data source
                    '${_gruppo?.membri.length ?? 0} membri',
                    style: TextStyle(
                      color: ThemeConstants.textSecondaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8), // ridotto da 16
                Icon(
                  Icons.hive,
                  size: 16,
                  color: ThemeConstants.textSecondaryColor,
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    // Replace with a default value or proper data source
                    '${_gruppo?.apiariIds.length ?? 0} apiari',
                    style: TextStyle(
                      color: ThemeConstants.textSecondaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ThemeConstants.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildApiarioCard(dynamic apiario) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _navigateToApiarioDetail(apiario['id']),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Text(
                apiario['posizione'] ?? 'Posizione non specificata',
                style: TextStyle(
                  color: ThemeConstants.textSecondaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTrattamentoCard(dynamic trattamento) {
    // Formatta le date
    String dataInizio = trattamento['data_inizio'] ?? 'N/D';
    String dataFine = trattamento['data_fine'] ?? 'In corso';
    
    List<Widget> children = [];
    
    children.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              trattamento['tipo_trattamento_nome'] ?? 'Trattamento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: trattamento['stato'] == 'in_corso' 
                  ? Colors.orange.withOpacity(0.2) 
                  : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              trattamento['stato'] == 'in_corso' 
                  ? 'In corso' 
                  : trattamento['stato'] == 'programmato'
                      ? 'Programmato'
                      : 'Completato',
              style: TextStyle(
                fontSize: 12,
                color: trattamento['stato'] == 'in_corso' 
                    ? Colors.orange.shade800 
                    : Colors.green.shade800,
              ),
            ),
          ),
        ],
      )
    );
    
    children.add(SizedBox(height: 8));
    
    children.add(
      Row(
        children: [
          Icon(Icons.location_on, size: 16, color: ThemeConstants.textSecondaryColor),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              trattamento['apiario_nome'] ?? 'Apiario',
              style: TextStyle(color: ThemeConstants.textSecondaryColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      )
    );
    
    children.add(SizedBox(height: 4));
    
    children.add(
      Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: ThemeConstants.textSecondaryColor),
          SizedBox(width: 4),
          Text(
            'Dal $dataInizio al $dataFine',
            style: TextStyle(color: ThemeConstants.textSecondaryColor),
          ),
        ],
      )
    );
    
    // Aggiungi barra di progresso per trattamenti in corso
    if (trattamento['stato'] == 'in_corso') {
      // Calcola progresso basato sulle date
      DateTime dataInizioDate = DateTime.parse(trattamento['data_inizio']);
      DateTime dataFineDate = trattamento['data_fine'] != null ? 
          DateTime.parse(trattamento['data_fine']) : 
          dataInizioDate.add(Duration(days: 14)); // Default 2 settimane
      DateTime oggi = DateTime.now();
      
      double progress = dataFineDate.difference(dataInizioDate).inDays > 0 ?
          oggi.difference(dataInizioDate).inDays / dataFineDate.difference(dataInizioDate).inDays : 
          0.0;
      
      // Limita il progresso a 0.0-1.0
      progress = progress.clamp(0.0, 1.0);
      
      children.add(SizedBox(height: 8));
      children.add(
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        )
      );
    }
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildFiorituraCard(dynamic fioritura) {
    bool isActive = fioritura['is_active'] ?? false;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    fioritura['pianta'] ?? 'Fioritura',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? 'Attiva' : 'Terminata',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive
                          ? Colors.green.shade800
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (fioritura['apiario_nome'] != null)
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: ThemeConstants.textSecondaryColor),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      fioritura['apiario_nome'],
                      style: TextStyle(color: ThemeConstants.textSecondaryColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: ThemeConstants.textSecondaryColor),
                SizedBox(width: 4),
                Text(
                  'Dal ${fioritura['data_inizio']} ${fioritura['data_fine'] != null ? 'al ${fioritura['data_fine']}' : ''}',
                  style: TextStyle(color: ThemeConstants.textSecondaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // WIDGETS NUOVI
  
  Widget _buildActivityChart() {
    // Calcola dati per il grafico 
    final Map<String, int> activityData = {
      'Visite': _apiari.fold<int>(0, (sum, apiario) => sum + ((apiario['visite_count'] ?? 0) as num).toInt()),
      'Raccolti': _apiari.fold<int>(0, (sum, apiario) => sum + ((apiario['raccolti_count'] ?? 0) as num).toInt()),
      'Trattamenti': _trattamenti.length,
      'Fioriture': _fioriture.length,
    };

    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attività negli apiari',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: activityData.entries.map((entry) {
                        final double barHeight = constraints.maxHeight * 0.7 * (entry.value / 
                            (activityData.values.fold(0, (max, value) => value > max ? value : max) == 0 ? 1 : 
                            activityData.values.fold(0, (max, value) => value > max ? value : max)));
                        
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              entry.value.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              width: 30,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: _getBarColor(entry.key),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBarColor(String category) {
    switch (category) {
      case 'Visite': 
        return Colors.blue;
      case 'Raccolti': 
        return Colors.amber;
      case 'Trattamenti': 
        return Colors.orange;
      case 'Fioriture': 
        return Colors.green;
      default: 
        return ThemeConstants.primaryColor;
    }
  }
  
  Widget _buildWeatherCard() {
    if (_weatherData == null) {
      return SizedBox.shrink();
    }
    
    final weather = _weatherData!;
    
    // Icone per diversi stati del tempo
    IconData _getWeatherIcon() {
      final condition = weather['condition']?.toLowerCase() ?? '';
      if (condition.contains('pioggia') || condition.contains('rain')) {
        return Icons.umbrella;
      } else if (condition.contains('sereno') || condition.contains('clear')) {
        return Icons.wb_sunny;
      } else if (condition.contains('nuvol') || condition.contains('cloud')) {
        return Icons.cloud;
      } else if (condition.contains('neve') || condition.contains('snow')) {
        return Icons.ac_unit;
      } else {
        return Icons.wb_cloudy;
      }
    }
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              _getWeatherIcon(),
              size: 48,
              color: ThemeConstants.primaryColor,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather['location'] ?? 'Meteo locale',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    weather['condition'] ?? '',
                    style: TextStyle(
                      color: ThemeConstants.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${weather['temperature']}°C',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Umidità: ${weather['humidity']}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCalendarWidget() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendario attività',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 14, // Mostra 14 giorni
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                  final hasEvents = _calendarEvents.containsKey(dateStr) && _calendarEvents[dateStr]!.isNotEmpty;
                  
                  return GestureDetector(
                    onTap: () {
                      if (hasEvents) {
                        // Mostra gli eventi per questo giorno
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => _buildDayEventsSheet(date, _calendarEvents[dateStr]!),
                        );
                      }
                    },
                    child: Container(
                      width: 60,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: hasEvents ? ThemeConstants.primaryColor.withOpacity(0.1) : null,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: DateTime.now().day == date.day && 
                                 DateTime.now().month == date.month && 
                                 DateTime.now().year == date.year
                              ? ThemeConstants.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ['Dom', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab'][date.weekday % 7],
                            style: TextStyle(
                              fontSize: 12,
                              color: ThemeConstants.textSecondaryColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          if (hasEvents)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: ThemeConstants.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (_calendarEvents[dateStr]!.length > 1) ...[
                                  SizedBox(width: 2),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: ThemeConstants.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayEventsSheet(DateTime date, List<dynamic> events) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 8),
          Divider(),
          SizedBox(height: 8),
          ...events.map((event) => ListTile(
            leading: Icon(
              event['type'] == 'trattamento' ? Icons.medication : Icons.local_florist,
              color: event['color'],
            ),
            title: Text(event['title']),
            subtitle: Text(event['type'] == 'trattamento' ? 'Trattamento' : 'Fioritura'),
            onTap: () {
              Navigator.pop(context);
              // Naviga ai dettagli dell'evento
              if (event['type'] == 'trattamento') {
                // Navigator.of(context).pushNamed(..., arguments: event['id']);
              } else {
                // Navigator.of(context).pushNamed(..., arguments: event['id']);
              }
            },
          )),
        ],
      ),
    );
  }
  
  List<Map<String, dynamic>> _generateAlerts() {
    List<Map<String, dynamic>> alerts = [];
    
    // Controlla trattamenti che scadono a breve
    for (var t in _trattamenti) {
      if (t['stato'] == 'in_corso' && t['data_fine'] != null) {
        DateTime dataFine = DateTime.parse(t['data_fine']);
        DateTime oggi = DateTime.now();
        
        if (dataFine.difference(oggi).inDays <= 3) {
          alerts.add({
            'type': 'warning',
            'title': 'Trattamento in scadenza',
            'message': 'Il trattamento "${t['tipo_trattamento_nome']}" scadrà tra ${dataFine.difference(oggi).inDays} giorni.',
            'icon': Icons.timer,
            'color': Colors.orange,
            'action': () {
              // Navigazione ai dettagli del trattamento
            },
          });
        }
      }
    }
    
    // Controlla condizioni meteo avverse
    if (_weatherData != null) {
      final condition = _weatherData!['condition']?.toLowerCase() ?? '';
      final temperature = _weatherData!['temperature'] as double? ?? 0;
      
      if (condition.contains('temporale') || condition.contains('pioggia forte')) {
        alerts.add({
          'type': 'danger',
          'title': 'Allerta meteo',
          'message': 'Previste condizioni meteorologiche avverse nelle prossime ore. Verifica lo stato degli apiari.',
          'icon': Icons.thunderstorm,
          'color': Colors.red,
          'action': null,
        });
      } else if (temperature > 35) {
        alerts.add({
          'type': 'warning',
          'title': 'Temperature elevate',
          'message': 'Le temperature elevate possono mettere a rischio le api. Considera l\'ombreggiamento degli alveari.',
          'icon': Icons.wb_sunny,
          'color': Colors.orange,
          'action': null,
        });
      }
    }
    
    // Controlla se ci sono apiari senza visite recenti
    for (var apiario in _apiari) {
      if (apiario['ultima_visita'] != null) {
        DateTime ultimaVisita = DateTime.parse(apiario['ultima_visita']);
        if (DateTime.now().difference(ultimaVisita).inDays > 14) {
          alerts.add({
            'type': 'info',
            'title': 'Apiario da visitare',
            'message': 'L\'apiario "${apiario['nome']}" non viene visitato da più di 14 giorni.',
            'icon': Icons.calendar_today,
            'color': Colors.blue,
            'action': () {
              _navigateToApiarioDetail(apiario['id']);
            },
          });
        }
      }
    }
    
    // Aggiungi suggerimenti sulla produzione 
    alerts.add({
      'type': 'success',
      'title': 'Ottima produzione!',
      'message': 'La produzione media di miele è aumentata del 15% rispetto allo stesso periodo dello scorso anno.',
      'icon': Icons.trending_up,
      'color': Colors.green,
      'action': null,
    });
    
    return alerts;
  }

  Widget _buildAlertsWidget() {
    final alerts = _generateAlerts();
    
    if (alerts.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Avvisi e suggerimenti',
            style: ThemeConstants.subheadingStyle,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 160,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              
              return Container(
                width: 250,
                margin: EdgeInsets.only(right: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: alert['color'].withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: alert['action'] as Function()?,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                alert['icon'] as IconData,
                                color: alert['color'],
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  alert['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              alert['message'],
                              style: TextStyle(
                                fontSize: 14,
                                color: ThemeConstants.textSecondaryColor,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (alert['action'] != null) ...[
                            SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Vedi dettagli',
                                style: TextStyle(
                                  color: ThemeConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      drawer: AppDrawer(currentRoute: AppConstants.dashboardRoute),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoadingApiari && _isLoadingTrattamenti && _isLoadingFioriture
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: 16),
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con ricerca e fumetto per freddure
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Benvenuto, ${user?.fullName ?? 'Apicoltore'}',
                                  style: ThemeConstants.headingStyle,
                                ),
                              ),
                              // Fumetto per le freddure
                              BeeJokeBubble(
                                onTap: _showBeeJoke,
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ultima sincronizzazione: ${_formatLastSync()}',
                            style: TextStyle(
                              color: ThemeConstants.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Barra di ricerca
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSearchBar(),
                    ),
                    SizedBox(height: 24),
                    
                    // Meteo
                    if (_weatherData != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildWeatherCard(),
                      ),
                    
                    // Avvisi e suggerimenti
                    _buildAlertsWidget(),
                    SizedBox(height: 24),
                    
                    // Calendario attività
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildCalendarWidget(),
                    ),
                    SizedBox(height: 24),
                    
                    // Riepilogo con grid layout
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Riepilogo',
                        style: ThemeConstants.subheadingStyle,
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildSummaryCard('Apiari', _apiari.length.toString(), Icons.hive, ThemeConstants.primaryColor),
                          _buildSummaryCard('Trattamenti attivi', _getActiveTrattamentiCount().toString(), Icons.medication, Colors.orange),
                          _buildSummaryCard('Fioriture attive', _getActiveFioritureCount().toString(), Icons.local_florist, Colors.green),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Grafico attività
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildActivityChart(),
                    ),
                    SizedBox(height: 32),
                    
                    // Sezione Apiari
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSectionWithLoading(
                        title: 'I tuoi apiari',
                        isLoading: _isLoadingApiari,
                        error: _apiariError,
                        onViewAll: () => Navigator.of(context).pushNamed(AppConstants.apiarioListRoute),
                        builder: () {
                          if (_apiari.isEmpty) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.hive_outlined,
                                      size: 48,
                                      color: ThemeConstants.textSecondaryColor,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Nessun apiario disponibile',
                                      style: TextStyle(
                                        color: ThemeConstants.textSecondaryColor,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _navigateToApiarioCreate,
                                      child: Text('Crea nuovo apiario'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          return Column(
                            children: [
                              for (var i = 0; i < _apiari.length && i < 3; i++)
                                _buildApiarioCard(_apiari[i]),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Sezione Trattamenti
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSectionWithLoading(
                        title: 'Trattamenti sanitari attivi',
                        isLoading: _isLoadingTrattamenti,
                        error: _trattamentiError,
                        onViewAll: () {
                          // Navigate to trattamenti list
                        },
                        builder: () {
                          if (_getActiveTrattamentiCount() == 0) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.medication_outlined,
                                      size: 48,
                                      color: ThemeConstants.textSecondaryColor,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Nessun trattamento attivo',
                                      style: TextStyle(
                                        color: ThemeConstants.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          return Column(
                            children: [
                              for (var trattamento in _trattamenti.where((t) => 
                                t['stato'] == 'in_corso' || t['stato'] == 'programmato').take(3))
                                _buildTrattamentoCard(trattamento),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Sezione Fioriture
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSectionWithLoading(
                        title: 'Fioriture attive',
                        isLoading: _isLoadingFioriture,
                        error: _fioritureError,
                        onViewAll: () {
                          // Navigate to fioriture list
                        },
                        builder: () {
                          if (_getActiveFioritureCount() == 0) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.local_florist_outlined,
                                      size: 48,
                                      color: ThemeConstants.textSecondaryColor,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Nessuna fioritura attiva',
                                      style: TextStyle(
                                        color: ThemeConstants.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          return Column(
                            children: [
                              for (var fioritura in _fioriture.where((f) => f['is_active'] == true).take(3))
                                _buildFiorituraCard(fioritura),
                            ],
                          );
                        },
                      ),
                    ),
                    
                    SizedBox(height: 32),
                  ],
                ),
              ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).primaryColor,
        children: [
          SpeedDialChild(
            child: Icon(Icons.qr_code_scanner),
            label: 'Scansiona QR',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MobileScannerWrapperScreen()),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Nuovo apiario',
            onTap: _navigateToApiarioCreate,
          ),
        ],
      ),
    );
  }
}
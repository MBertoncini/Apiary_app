import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/jokes_service.dart';
import '../widgets/drawer_widget.dart';
import '../widgets/bee_joke_bubble.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../screens/mobile_scanner_wrapper_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Variabili dati generali
  List<dynamic> _apiari = [];
  List<dynamic> _trattamenti = [];
  List<dynamic> _fioriture = [];
  List<dynamic> _controlli = [];  DateTime _lastSyncTime = DateTime.now();


  // Variabili per la gestione del caricamento
  bool _isLoadingApiari = true;
  bool _isLoadingTrattamenti = true;
  bool _isLoadingFioriture = true;
  bool _isLoadingControlli = true;

  String? _apiariError;
  String? _trattamentiError;
  String? _fioritureError;
  String? _controlliError;  
  // Variabili per funzionalità aggiuntive
  Map<String, dynamic>? _weatherData;
  Map<String, List<dynamic>> _calendarEvents = {};
  
  // Variabili per ricerca
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Variabili per calendario
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _expandedCalendar = false;
  List<DateTime> _visibleDays = [];
  String _calendarFormat = 'week'; // 'week', 'month'
  
  List<dynamic> _filteredApiari = [];
  List<dynamic> _filteredTrattamenti = [];
  List<dynamic> _filteredFioriture = [];
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _generateVisibleDays();
    _loadData();
    // Aggiungi questo per forzare l'aggiornamento del profilo utente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthService>(context, listen: false).refreshUserProfile();
    });
  }
   
  void _generateVisibleDays() {
    _visibleDays = [];
    
    if (_calendarFormat == 'week') {
      // Start from the beginning of the week containing the focused day
      final int weekday = _focusedDay.weekday;
      final startDate = _focusedDay.subtract(Duration(days: weekday - 1));
      
      // Generate 14 days (2 weeks)
      for (int i = 0; i < 14; i++) {
        _visibleDays.add(startDate.add(Duration(days: i)));
      }
    } else {
      // Month view - start from the first day of the month
      DateTime firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      
      // Go back to the beginning of the week
      int weekday = firstDayOfMonth.weekday;
      DateTime startDate = firstDayOfMonth.subtract(Duration(days: weekday - 1));
      
      // Generate 42 days (6 weeks)
      for (int i = 0; i < 42; i++) {
        _visibleDays.add(startDate.add(Duration(days: i)));
      }
    }
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
      _loadControlliData(apiService),
    ]);
    
    // Aggiorna l'orario di sincronizzazione
    setState(() {
      _lastSyncTime = DateTime.now();
    });
    
    // Prepara i dati per il calendario
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
        
        // Endpoint meteo
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
  
  Future<void> _loadControlliData(ApiService apiService) async {
    try {
      final controlliResponse = await apiService.get('controlli/');
      setState(() {
        _controlli = controlliResponse['results'] ?? [];
        _isLoadingControlli = false;
      });
    } catch (e) {
      print('Error fetching controlli: $e');
      setState(() {
        _controlliError = e.toString();
        _isLoadingControlli = false;
      });
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
              child: CircularProgressIndicator(strokeWidth: 2),
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
    
    // Trattamenti (treatments)
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
          'color': Colors.purple,
        });
      }
    }
    
    // Fioriture (flowering)
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
          'color': Colors.orange,
        });
      }
    }
    
    // Controlli (inspections)
    if (_controlli != null) {
      for (var controllo in _controlli) {
        if (controllo['data'] != null) {
          DateTime date = DateTime.parse(controllo['data']);
          String day = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          
          if (!_calendarEvents.containsKey(day)) {
            _calendarEvents[day] = [];
          }
          
          _calendarEvents[day]!.add({
            'type': 'controllo',
            'title': 'Controllo arnia ${controllo['arnia_numero']}',
            'id': controllo['id'],
            'color': Colors.blue,
          });
        }
      }
    }

    // Note: The following collections (_regine, _melari, _smielature)
    // aren't defined in the current state. If you add them in the future,
    // you can uncomment these sections.
    
    /* 
    
    // Regine (queens)
    if (_regine != null) {
      for (var regina in _regine) {
        if (regina['data_introduzione'] != null) {
          DateTime date = DateTime.parse(regina['data_introduzione']);
          String day = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          
          if (!_calendarEvents.containsKey(day)) {
            _calendarEvents[day] = [];
          }
          
          _calendarEvents[day]!.add({
            'type': 'regina',
            'title': 'Regina introdotta',
            'id': regina['id'],
            'color': Colors.red,
          });
        }
      }
    }
    
    // Melari (honey supers)
    if (_melari != null) {
      for (var melario in _melari) {
        if (melario['data_posizionamento'] != null) {
          DateTime date = DateTime.parse(melario['data_posizionamento']);
          String day = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          
          if (!_calendarEvents.containsKey(day)) {
            _calendarEvents[day] = [];
          }
          
          _calendarEvents[day]!.add({
            'type': 'melario',
            'title': 'Melario posizionato',
            'id': melario['id'],
            'color': Colors.green,
          });
        }
      }
    }
    
    // Smielature (honey extractions)
    if (_smielature != null) {
      for (var smielatura in _smielature) {
        if (smielatura['data'] != null) {
          DateTime date = DateTime.parse(smielatura['data']);
          String day = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          
          if (!_calendarEvents.containsKey(day)) {
            _calendarEvents[day] = [];
          }
          
          _calendarEvents[day]!.add({
            'type': 'smielatura',
            'title': 'Smielatura',
            'id': smielatura['id'],
            'color': Colors.amber,
          });
        }
      }
    }
    */
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
  
  // Metodo per mostrare la ricerca
  void _showSearchView() {
    setState(() {
      _isSearching = true;
    });
  }
  
  // Metodo per nascondere la ricerca
  void _hideSearchView() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
      _showSearchResults = false;
    });
  }

  // Metodo per eseguire la ricerca
    void _performSearch() {
      if (_searchQuery.isEmpty) {
        setState(() {
          _showSearchResults = false;
        });
        return;
      }

      final query = _searchQuery.toLowerCase();
      
      // Filtra apiari
      final filteredApiari = _apiari.where((apiario) {
        return (apiario['nome']?.toString().toLowerCase().contains(query) ?? false) ||
              (apiario['posizione']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
      
      // Filtra trattamenti
      final filteredTrattamenti = _trattamenti.where((trattamento) {
        return (trattamento['tipo_trattamento_nome']?.toString().toLowerCase().contains(query) ?? false) ||
              (trattamento['apiario_nome']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
      
      // Filtra fioriture
      final filteredFioriture = _fioriture.where((fioritura) {
        return (fioritura['pianta']?.toString().toLowerCase().contains(query) ?? false) ||
              (fioritura['apiario_nome']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
      
      setState(() {
        _filteredApiari = filteredApiari;
        _filteredTrattamenti = filteredTrattamenti;
        _filteredFioriture = filteredFioriture;
        _showSearchResults = true;
      });
    }

  // CALENDARIO PERSONALIZZATO
  
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _focusedDay = day;
    });
  }
  
  void _nextMonth() {
    setState(() {
      // Compute the first day of the next month
      if (_focusedDay.month == 12) {
        _focusedDay = DateTime(_focusedDay.year + 1, 1, 1);
      } else {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
      }
      
      // Update visible days
      _generateVisibleDays();
    });
  }

  void _previousMonth() {
    setState(() {
      // Compute the first day of the previous month
      if (_focusedDay.month == 1) {
        _focusedDay = DateTime(_focusedDay.year - 1, 12, 1);
      } else {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      }
      
      // Update visible days
      _generateVisibleDays();
    });
  }
  
  void _toToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = _focusedDay;
      _generateVisibleDays();
    });
  }
  
  List<dynamic> _getEventsForDay(DateTime day) {
    final dateStr = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    return _calendarEvents[dateStr] ?? [];
  }
    
  Widget _buildCalendar() {
    List<dynamic> selectedDayEvents = [];
    
    if (_selectedDay != null) {
      selectedDayEvents = _getEventsForDay(_selectedDay!);
    }
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and expansion
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Calendario attività',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(_expandedCalendar ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _expandedCalendar = !_expandedCalendar;
                      if (_expandedCalendar) {
                        _generateVisibleDays();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Only show this when expanded - fixes overflow by making controls appear in a separate row
          if (_expandedCalendar) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Navigation row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: _previousMonth,
                        tooltip: 'Mese precedente',
                      ),
                      TextButton(
                        onPressed: _toToday,
                        child: Text('Oggi'),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: _nextMonth,
                        tooltip: 'Mese successivo',
                      ),
                    ],
                  ),
                  
                  // View selection row
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _calendarFormat = 'month';
                            _generateVisibleDays();
                          });
                        },
                        child: Text('Mese'),
                        style: TextButton.styleFrom(
                          foregroundColor: _calendarFormat == 'month'
                            ? ThemeConstants.primaryColor
                            : ThemeConstants.textSecondaryColor,
                          backgroundColor: _calendarFormat == 'month'
                            ? ThemeConstants.primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                      SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _calendarFormat = 'week';
                            _generateVisibleDays();
                          });
                        },
                        child: Text('Settimana'),
                        style: TextButton.styleFrom(
                          foregroundColor: _calendarFormat == 'week'
                            ? ThemeConstants.primaryColor
                            : ThemeConstants.textSecondaryColor,
                          backgroundColor: _calendarFormat == 'week'
                            ? ThemeConstants.primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                  
                  // Legend
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    children: [
                      _buildCalendarLegendItem('Controlli', Colors.blue),
                      _buildCalendarLegendItem('Trattamenti', Colors.purple),
                      _buildCalendarLegendItem('Fioriture', Colors.orange),
                      _buildCalendarLegendItem('Regine', Colors.red),
                      _buildCalendarLegendItem('Melari', Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          
          // Calendar
          _expandedCalendar
              ? _buildMonthCalendar()
              : _buildWeekView(),
                
          // Events for selected day
          if (_selectedDay != null && selectedDayEvents.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eventi del ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...selectedDayEvents.map((event) => _buildCalendarEventItem(event)).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
    
  Widget _buildMonthCalendar() {
    if (_visibleDays.isEmpty) {
      _generateVisibleDays();
    }
    
    final month = _focusedDay.month;
    final year = _focusedDay.year;
    
    return Column(
      children: [
        // Month and year heading
        Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Text(
            DateFormat('MMMM yyyy').format(_focusedDay),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        
        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              for (final day in ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'])
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      day,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: ThemeConstants.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Calendar days grid
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: _visibleDays.length,
            itemBuilder: (context, index) {
              final date = _visibleDays[index];
              final isToday = _isSameDay(date, DateTime.now());
              final isSelected = _isSameDay(date, _selectedDay);
              final isThisMonth = date.month == month;
              final events = _getEventsForDay(date);
              
              return InkWell(
                onTap: () => _selectDay(date),
                child: Container(
                  margin: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ThemeConstants.primaryColor.withOpacity(0.3)
                        : events.isNotEmpty
                            ? ThemeConstants.primaryColor.withOpacity(0.1)
                            : null,
                    borderRadius: BorderRadius.circular(4),
                    border: isToday
                        ? Border.all(
                            color: ThemeConstants.primaryColor,
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isThisMonth
                              ? isSelected
                                  ? Colors.black
                                  : Colors.black87
                              : Colors.grey.withOpacity(0.5),
                        ),
                      ),
                      if (events.isNotEmpty)
                        SizedBox(height: 4),
                      if (events.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < events.length.clamp(0, 3); i++)
                              Container(
                                width: 6,
                                height: 6,
                                margin: EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: events[i]['color'],
                                ),
                              ),
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
    );
  }
  
  Widget _buildWeekView() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, // Mostra 14 giorni
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final events = _getEventsForDay(date);
          final isSelected = _selectedDay != null && _isSameDay(_selectedDay!, date);
          final isToday = _isSameDay(date, DateTime.now());
          
          return GestureDetector(
            onTap: () => _selectDay(date),
            child: Container(
              width: 60,
              margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? ThemeConstants.primaryColor.withOpacity(0.3) 
                    : events.isNotEmpty 
                        ? ThemeConstants.primaryColor.withOpacity(0.1) 
                        : null,
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(
                        color: ThemeConstants.primaryColor,
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'][date.weekday - 1],
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
                  if (events.isNotEmpty)
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
                        if (events.length > 1) ...[
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
    );
  }
  
  Widget _buildCalendarLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: ThemeConstants.textSecondaryColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCalendarEventItem(Map<String, dynamic> event) {
    IconData icon;
    Color color = event['color'] ?? ThemeConstants.primaryColor;
    
    // Imposta l'icona in base al tipo di evento
    switch(event['type']) {
      case 'trattamento':
        icon = Icons.medical_services;
        break;
      case 'fioritura':
        icon = Icons.local_florist;
        break;
      case 'controllo':
        icon = Icons.check_circle;
        break;
      case 'regina':
        icon = Icons.star;
        break;
      case 'melario':
        icon = Icons.archive;
        break;
      default:
        icon = Icons.event;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              event['title'],
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: ThemeConstants.textSecondaryColor),
        ],
      ),
    );
  }
  
  // WIDGETS PER LA DASHBOARD
  
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
      margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
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

  Widget _buildSearchResultsView() {
    bool hasResults = _filteredApiari.isNotEmpty || 
                    _filteredTrattamenti.isNotEmpty || 
                    _filteredFioriture.isNotEmpty;
                    
    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: ThemeConstants.textSecondaryColor.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'Nessun risultato trovato per "$_searchQuery"',
              style: TextStyle(
                color: ThemeConstants.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 16),
      physics: AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risultati della ricerca: Apiari
          if (_filteredApiari.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Apiari (${_filteredApiari.length})',
                style: ThemeConstants.subheadingStyle,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  for (var apiario in _filteredApiari)
                    _buildApiarioCard(apiario),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
          
          // Risultati della ricerca: Trattamenti
          if (_filteredTrattamenti.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Trattamenti (${_filteredTrattamenti.length})',
                style: ThemeConstants.subheadingStyle,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  for (var trattamento in _filteredTrattamenti)
                    _buildTrattamentoCard(trattamento),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
          
          // Risultati della ricerca: Fioriture
          if (_filteredFioriture.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Fioriture (${_filteredFioriture.length})',
                style: ThemeConstants.subheadingStyle,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  for (var fioritura in _filteredFioriture)
                    _buildFiorituraCard(fioritura),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: _isSearching ? null : Text('Dashboard'),
        actions: [
          // Icona di ricerca
          _isSearching
            ? Container(
                width: 240, // Aumentato per dare più spazio
                margin: EdgeInsets.only(right: 16.0, left: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cerca...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                  ),
                  style: TextStyle(color: Colors.white), // Testo bianco solo su AppBar scura
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _performSearch(); // Nuova funzione per eseguire la ricerca
                    });
                  },
                  autofocus: true,
                ),
              )
            : IconButton(
                icon: Icon(Icons.search),
                onPressed: _showSearchView,
                tooltip: 'Cerca',
              ),
          
          // Pulsante per chiudere la ricerca
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _hideSearchView,
              tooltip: 'Chiudi ricerca',
            ),
        ],
      ),

      drawer: AppDrawer(currentRoute: AppConstants.dashboardRoute),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoadingApiari && _isLoadingTrattamenti && _isLoadingFioriture
            ? Center(child: CircularProgressIndicator())
            : _showSearchResults
                ? _buildSearchResultsView()
                : SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: 16),
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con benvenuto e fumetto per freddure
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Benvenuto, ${user?.fullName ?? user?.username ?? "Utente"}',
                                  style: ThemeConstants.headingStyle,
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
                          // Fumetto per le freddure
                          BeeJokeBubble(
                            onTap: _showBeeJoke,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Meteo
                    if (_weatherData != null)
                      _buildWeatherCard(),
                    
                    // Avvisi e suggerimenti
                    _buildAlertsWidget(),
                    SizedBox(height: 24),
                    
                    // Calendario attività
                    _buildCalendar(),
                    SizedBox(height: 24),
                    
                    // Sezione Apiari
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'I tuoi apiari',
                                style: ThemeConstants.subheadingStyle,
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pushNamed(AppConstants.apiarioListRoute),
                                child: Text('Vedi tutti'),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          
                          if (_isLoadingApiari)
                            Container(
                              height: 120,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_apiariError != null)
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
                                      'Errore nel caricamento dei dati: $_apiariError',
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
                          else if (_apiari.isEmpty)
                            Card(
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
                            )
                          else
                            Column(
                              children: [
                                for (var i = 0; i < _apiari.length && i < 3; i++)
                                  _buildApiarioCard(_apiari[i]),
                              ],
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Sezione Trattamenti
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Trattamenti sanitari attivi',
                                style: ThemeConstants.subheadingStyle,
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigate to trattamenti list
                                },
                                child: Text('Vedi tutti'),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          
                          if (_isLoadingTrattamenti)
                            Container(
                              height: 120,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_trattamentiError != null)
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
                                      'Errore nel caricamento dei dati: $_trattamentiError',
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
                          else if (_getActiveTrattamentiCount() == 0)
                            Card(
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
                            )
                          else
                            Column(
                              children: [
                                for (var trattamento in _trattamenti.where((t) => 
                                  t['stato'] == 'in_corso' || t['stato'] == 'programmato').take(3))
                                  _buildTrattamentoCard(trattamento),
                              ],
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Sezione Fioriture
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Fioriture attive',
                                style: ThemeConstants.subheadingStyle,
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigate to fioriture list
                                },
                                child: Text('Vedi tutti'),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          
                          if (_isLoadingFioriture)
                            Container(
                              height: 120,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_fioritureError != null)
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
                                      'Errore nel caricamento dei dati: $_fioritureError',
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
                          else if (_getActiveFioritureCount() == 0)
                            Card(
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
                            )
                          else
                            Column(
                              children: [
                                for (var fioritura in _fioriture.where((f) => f['is_active'] == true).take(3))
                                  _buildFiorituraCard(fioritura),
                              ],
                            ),
                        ],
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
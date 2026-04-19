import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/jokes_service.dart';
import '../services/chat_service.dart';
import '../services/ai_quota_service.dart';
import '../widgets/offline_banner.dart';
import '../widgets/drawer_widget.dart';
import '../widgets/bee_joke_bubble.dart';
import '../widgets/contextual_hint.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../screens/mobile_scanner_wrapper_screen.dart';
import '../screens/chat_screen.dart';
import 'package:intl/intl.dart';
import '../services/language_service.dart';
import '../l10n/app_strings.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Variabili dati generali
  List<dynamic> _apiari = [];
  List<dynamic> _trattamenti = [];
  List<dynamic> _fioriture = [];
  List<dynamic> _controlli = [];
  List<dynamic> _regine = [];
  List<dynamic> _melari = [];
  List<dynamic> _smielature = [];
  DateTime _lastSyncTime = DateTime.now();


  // true mentre si aggiorna dal server con dati cache già visibili
  bool _isRefreshing = false;

  // Variabili per la gestione del caricamento
  bool _isLoadingApiari = true;
  bool _isLoadingTrattamenti = true;
  bool _isLoadingFioriture = true;
  bool _isLoadingControlli = true;
  bool _isLoadingRegine = true;
  bool _isLoadingMelari = true;
  bool _isLoadingSmielature = true;

  String? _apiariError;
  String? _trattamentiError;
  String? _fioritureError;
  String? _controlliError;
  String? _regineError;
  String? _melariError;
  String? _smielatureError;

  // Variabili per funzionalità aggiuntive
  Map<String, dynamic>? _weatherData;
  Map<String, List<dynamic>> _calendarEvents = {};
  
  // Accesso corrente alle stringhe localizzate (listen: false — il rebuild è
  // innescato dall'ascolto esplicito in build())
  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  // Evita di refreshare il profilo ad ogni visita: max una volta ogni 5 minuti
  static DateTime? _lastProfileRefresh;

  // Chiave per accedere allo stato dello Scaffold (necessaria per rilevare drawer aperto)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    // Aggiorna il profilo utente al massimo una volta ogni 5 minuti
    final now = DateTime.now();
    if (_lastProfileRefresh == null ||
        now.difference(_lastProfileRefresh!) > const Duration(minutes: 5)) {
      _lastProfileRefresh = now;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<AuthService>(context, listen: false).refreshUserProfile();
        }
      });
    }
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
    final storageService = Provider.of<StorageService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);

    // === Fase 1: cache locale (istantaneo) ===
    final cached = await Future.wait([
      storageService.getStoredData('apiari'),
      storageService.getStoredData('trattamenti'),
      storageService.getStoredData('fioriture'),
      storageService.getStoredData('controlli'),
      storageService.getStoredData('regine'),
      storageService.getStoredData('melari'),
      storageService.getStoredData('smielature'),
    ]);

    _apiari        = cached[0];
    _trattamenti   = cached[1];
    _fioriture     = cached[2];
    _controlli     = cached[3];
    _regine        = cached[4];
    _melari        = cached[5];
    _smielature    = cached[6];

    final bool hasCache = _apiari.isNotEmpty || _trattamenti.isNotEmpty ||
        _fioriture.isNotEmpty || _controlli.isNotEmpty;

    if (hasCache) {
      // Mostra subito i dati cached e avvia un indicatore discreto di refresh
      _isLoadingApiari     = false;
      _isLoadingTrattamenti = false;
      _isLoadingFioriture  = false;
      _isLoadingControlli  = false;
      _isLoadingRegine     = false;
      _isLoadingMelari     = false;
      _isLoadingSmielature = false;
      _prepareCalendarEvents();
      if (mounted) setState(() { _isRefreshing = true; });
    } else {
      // Nessuna cache: mostra spinner finché l'API risponde
      if (mounted) setState(() {
        _isLoadingApiari     = true;
        _isLoadingTrattamenti = true;
        _isLoadingFioriture  = true;
        _isLoadingControlli  = true;
        _isLoadingRegine     = true;
        _isLoadingMelari     = true;
        _isLoadingSmielature = true;
      });
    }

    // === Fase 2: aggiornamento dal server ===
    await Future.wait([
      _loadApiariData(apiService),
      _loadTrattamentiData(apiService),
      _loadFioritureData(apiService),
      _loadControlliData(apiService),
      _loadRegineData(apiService),
      _loadMelariData(apiService),
      _loadSmielaturaData(apiService),
    ]);

    // Se l'API ha fallito ma c'è ancora cache, sopprimi l'errore
    if (_apiari.isNotEmpty)      _apiariError     = null;
    if (_trattamenti.isNotEmpty) _trattamentiError = null;
    if (_fioriture.isNotEmpty)   _fioritureError  = null;
    if (_controlli.isNotEmpty)   _controlliError  = null;
    if (_regine.isNotEmpty)      _regineError     = null;
    if (_melari.isNotEmpty)      _melariError     = null;
    if (_smielature.isNotEmpty)  _smielatureError = null;

    // Salva i dati freschi in cache per la prossima visita
    final saves = <Future>[];
    if (_apiari.isNotEmpty)      saves.add(storageService.saveData('apiari',      _apiari));
    if (_trattamenti.isNotEmpty) saves.add(storageService.saveData('trattamenti', _trattamenti));
    if (_fioriture.isNotEmpty)   saves.add(storageService.saveData('fioriture',   _fioriture));
    if (_controlli.isNotEmpty)   saves.add(storageService.saveData('controlli',   _controlli));
    if (_regine.isNotEmpty)      saves.add(storageService.saveData('regine',      _regine));
    if (_melari.isNotEmpty)      saves.add(storageService.saveData('melari',      _melari));
    if (_smielature.isNotEmpty)  saves.add(storageService.saveData('smielature',  _smielature));
    await Future.wait(saves);

    // Aggiorna dati derivati e ricostruisci UI
    _prepareCalendarEvents();
    _lastSyncTime = DateTime.now();
    if (mounted) setState(() { _isRefreshing = false; });
  }

  // --- Metodi di caricamento dati ---
  // Non chiamano setState individualmente; lo stato viene aggiornato in batch da _loadData()

  Future<void> _loadApiariData(ApiService apiService) async {
    try {
      final apiariResponse = await apiService.get('apiari/');
      if (apiariResponse is List) {
        _apiari = apiariResponse;
      } else if (apiariResponse is Map) {
        _apiari = apiariResponse['results'] ?? [];
      } else {
        _apiari = [];
      }
      _isLoadingApiari = false;
    } catch (e) {
      debugPrint('Error fetching apiari: $e');
      _apiariError = e.toString();
      _isLoadingApiari = false;
    }
  }

  Future<void> _loadTrattamentiData(ApiService apiService) async {
    try {
      final trattamentiResponse = await apiService.get('trattamenti/');
      if (trattamentiResponse is List) {
        _trattamenti = trattamentiResponse;
      } else if (trattamentiResponse is Map) {
        _trattamenti = trattamentiResponse['results'] ?? [];
      } else {
        _trattamenti = [];
      }
      _isLoadingTrattamenti = false;
    } catch (e) {
      debugPrint('Error fetching trattamenti: $e');
      _trattamentiError = e.toString();
      _isLoadingTrattamenti = false;
    }
  }

  Future<void> _loadFioritureData(ApiService apiService) async {
    try {
      final fioritureResponse = await apiService.get('fioriture/');
      if (fioritureResponse is List) {
        _fioriture = fioritureResponse;
      } else if (fioritureResponse is Map) {
        _fioriture = fioritureResponse['results'] ?? [];
      } else {
        _fioriture = [];
      }
      _isLoadingFioriture = false;
    } catch (e) {
      debugPrint('Error fetching fioriture: $e');
      _fioritureError = e.toString();
      _isLoadingFioriture = false;
    }
  }

  Future<void> _loadWeatherData() async {
    if (_apiari.isEmpty) return;

    try {
      var apiario = _apiari[0];
      if (apiario['latitudine'] != null && apiario['longitudine'] != null) {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final weatherResponse = await apiService.get(
          'meteo/?lat=${apiario['latitudine']}&lon=${apiario['longitudine']}',
        );
        _weatherData = weatherResponse;
      }
    } catch (e) {
      debugPrint('Error fetching weather data: $e');
    }
  }

  Future<void> _loadControlliData(ApiService apiService) async {
    try {
      final controlliResponse = await apiService.get('controlli/');
      if (controlliResponse is List) {
        _controlli = controlliResponse;
      } else if (controlliResponse is Map) {
        _controlli = controlliResponse['results'] ?? [];
      } else {
        _controlli = [];
      }
      _isLoadingControlli = false;
    } catch (e) {
      debugPrint('Error fetching controlli: $e');
      _controlliError = e.toString();
      _isLoadingControlli = false;
    }
  }

  Future<void> _loadRegineData(ApiService apiService) async {
    try {
      final response = await apiService.get('regine/');
      if (response is List) {
        _regine = response;
      } else if (response is Map) {
        _regine = response['results'] ?? [];
      } else {
        _regine = [];
      }
      _isLoadingRegine = false;
    } catch (e) {
      debugPrint('Error fetching regine: $e');
      _regineError = e.toString();
      _isLoadingRegine = false;
    }
  }

  Future<void> _loadMelariData(ApiService apiService) async {
    try {
      final response = await apiService.get('melari/');
      if (response is List) {
        _melari = response;
      } else if (response is Map) {
        _melari = response['results'] ?? [];
      } else {
        _melari = [];
      }
      _isLoadingMelari = false;
    } catch (e) {
      debugPrint('Error fetching melari: $e');
      _melariError = e.toString();
      _isLoadingMelari = false;
    }
  }

  Future<void> _loadSmielaturaData(ApiService apiService) async {
    try {
      final response = await apiService.get('smielature/');
      if (response is List) {
        _smielature = response;
      } else if (response is Map) {
        _smielature = response['results'] ?? [];
      } else {
        _smielature = [];
      }
      _isLoadingSmielature = false;
    } catch (e) {
      debugPrint('Error fetching smielature: $e');
      _smielatureError = e.toString();
      _isLoadingSmielature = false;
    }
  }

  Future<void> _refreshData() async {
    final s = _s;
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
            Text(s.dashSyncing),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    await _loadData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.dashSyncDone),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  void _addCalendarEvent(String dateStr, Map<String, dynamic> event) {
    if (!_calendarEvents.containsKey(dateStr)) {
      _calendarEvents[dateStr] = [];
    }
    _calendarEvents[dateStr]!.add(event);
  }

  String _dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _addDateRangeEvents({
    required String? startStr,
    required String? endStr,
    required Map<String, dynamic> eventTemplate,
    int maxDays = 90,
  }) {
    if (startStr == null) return;
    final start = DateTime.parse(startStr);
    final end = endStr != null ? DateTime.parse(endStr) : start;
    final days = end.difference(start).inDays.clamp(0, maxDays);
    for (int i = 0; i <= days; i++) {
      final d = start.add(Duration(days: i));
      _addCalendarEvent(_dateKey(d), Map<String, dynamic>.from(eventTemplate));
    }
  }

  void _prepareCalendarEvents() {
    _calendarEvents = {};
    final s = _s;

    // Trattamenti — span full date range + suspension + brood block
    for (var t in _trattamenti) {
      final apiarioNome = t['apiario_nome'] ?? '';

      // Main treatment period
      _addDateRangeEvents(
        startStr: t['data_inizio'],
        endStr: t['data_fine'],
        eventTemplate: {
          'type': 'trattamento',
          'title': '${t['tipo_trattamento_nome'] ?? s.dashEventTrattamento}${apiarioNome.isNotEmpty ? ' — $apiarioNome' : ''}',
          'id': t['id'],
          'color': Colors.purple,
        },
      );

      // Suspension period (data_fine → data_fine_sospensione)
      if (t['data_fine'] != null && t['data_fine_sospensione'] != null) {
        final suspStart = DateTime.parse(t['data_fine']).add(const Duration(days: 1));
        _addDateRangeEvents(
          startStr: suspStart.toIso8601String().split('T')[0],
          endStr: t['data_fine_sospensione'],
          eventTemplate: {
            'type': 'sospensione',
            'title': '${s.dashEventSospensione} — ${t['tipo_trattamento_nome'] ?? s.dashEventTrattamento}${apiarioNome.isNotEmpty ? ' ($apiarioNome)' : ''}',
            'id': t['id'],
            'color': Colors.deepOrange,
          },
        );
      }

      // Brood block period (data_inizio_blocco → data_fine_blocco)
      if (t['data_inizio_blocco'] != null && t['data_fine_blocco'] != null) {
        _addDateRangeEvents(
          startStr: t['data_inizio_blocco'],
          endStr: t['data_fine_blocco'],
          eventTemplate: {
            'type': 'blocco_covata',
            'title': '${s.dashEventBloccoCovata} — ${t['tipo_trattamento_nome'] ?? s.dashEventTrattamento}${apiarioNome.isNotEmpty ? ' ($apiarioNome)' : ''}',
            'id': t['id'],
            'color': Colors.brown,
          },
        );
      }
    }

    // Fioriture — span full date range
    for (var f in _fioriture) {
      final apiarioNome = f['apiario_nome'] ?? '';
      _addDateRangeEvents(
        startStr: f['data_inizio'],
        endStr: f['data_fine'],
        eventTemplate: {
          'type': 'fioritura',
          'title': '${f['pianta'] ?? s.dashEventFioritura}${apiarioNome.isNotEmpty ? ' — $apiarioNome' : ''}',
          'id': f['id'],
          'color': Colors.orange,
        },
      );
    }

    // Controlli
    for (var controllo in _controlli) {
      if (controllo['data'] != null) {
        final date = DateTime.parse(controllo['data']);
        _addCalendarEvent(_dateKey(date), {
          'type': 'controllo',
          'title': s.dashEventControlloArnia((controllo['arnia_numero'] ?? '').toString()),
          'id': controllo['id'],
          'arnia_id': controllo['arnia'],
          'color': Colors.blue,
        });
      }
    }

    // Regine
    for (var regina in _regine) {
      if (regina['data_introduzione'] != null) {
        final date = DateTime.parse(regina['data_introduzione']);
        final arniaNr = regina['arnia_numero'] ?? '';
        _addCalendarEvent(_dateKey(date), {
          'type': 'regina',
          'title': '${s.dashEventReginaIntrodotta}${arniaNr.toString().isNotEmpty ? '${s.dashEventArniaSep}$arniaNr' : ''}',
          'id': regina['id'],
          'color': Colors.red,
        });
      }
    }

    // Melari — index both placement and removal dates
    for (var melario in _melari) {
      final arniaNr = melario['arnia_numero'] ?? '';
      if (melario['data_posizionamento'] != null) {
        final date = DateTime.parse(melario['data_posizionamento']);
        _addCalendarEvent(_dateKey(date), {
          'type': 'melario',
          'title': '${s.dashEventMelarioPosizionato}${arniaNr.toString().isNotEmpty ? '${s.dashEventArniaSep}$arniaNr' : ''}',
          'id': melario['id'],
          'color': Colors.green,
        });
      }
      if (melario['data_rimozione'] != null) {
        final date = DateTime.parse(melario['data_rimozione']);
        _addCalendarEvent(_dateKey(date), {
          'type': 'melario',
          'title': '${s.dashEventMelarioRimosso}${arniaNr.toString().isNotEmpty ? '${s.dashEventArniaSep}$arniaNr' : ''}',
          'id': melario['id'],
          'color': Colors.green,
        });
      }
    }

    // Smielature
    for (var smielatura in _smielature) {
      if (smielatura['data'] != null) {
        final date = DateTime.parse(smielatura['data']);
        _addCalendarEvent(_dateKey(date), {
          'type': 'smielatura',
          'title': '${s.dashEventSmielatura}${smielatura['tipo_miele'] != null ? ' — ${smielatura['tipo_miele']}' : ''}',
          'id': smielatura['id'],
          'color': Colors.amber,
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
      debugPrint('Errore nel mostrare la freddura: $e');
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
      if (_calendarFormat == 'week') {
        _focusedDay = _focusedDay.add(const Duration(days: 7));
      } else {
        if (_focusedDay.month == 12) {
          _focusedDay = DateTime(_focusedDay.year + 1, 1, 1);
        } else {
          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
        }
      }
      _generateVisibleDays();
    });
  }

  void _previousMonth() {
    setState(() {
      if (_calendarFormat == 'week') {
        _focusedDay = _focusedDay.subtract(const Duration(days: 7));
      } else {
        if (_focusedDay.month == 1) {
          _focusedDay = DateTime(_focusedDay.year - 1, 12, 1);
        } else {
          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
        }
      }
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
    final s = _s;
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
                  s.dashCalendarTitle,
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
                        tooltip: _calendarFormat == 'week' ? s.dashCalendarPrevWeek : s.dashCalendarPrevMonth,
                      ),
                      TextButton(
                        onPressed: _toToday,
                        child: Text(s.dashCalendarToday),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: _nextMonth,
                        tooltip: _calendarFormat == 'week' ? s.dashCalendarNextWeek : s.dashCalendarNextMonth,
                      ),
                    ],
                  ),
                  
                  // View selection row
                  const SizedBox(height: 8),
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
                        child: Text(s.dashCalendarViewMonth),
                        style: TextButton.styleFrom(
                          foregroundColor: _calendarFormat == 'month'
                            ? ThemeConstants.primaryColor
                            : ThemeConstants.textSecondaryColor,
                          backgroundColor: _calendarFormat == 'month'
                            ? ThemeConstants.primaryColor10
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
                        child: Text(s.dashCalendarViewWeek),
                        style: TextButton.styleFrom(
                          foregroundColor: _calendarFormat == 'week'
                            ? ThemeConstants.primaryColor
                            : ThemeConstants.textSecondaryColor,
                          backgroundColor: _calendarFormat == 'week'
                            ? ThemeConstants.primaryColor10
                            : Colors.transparent,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                  
                  // Legend
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _buildCalendarLegendItem(s.dashCalendarLegendControlli, Colors.blue),
                      _buildCalendarLegendItem(s.dashCalendarLegendTrattamenti, Colors.purple),
                      _buildCalendarLegendItem(s.dashCalendarLegendFioriture, Colors.orange),
                      _buildCalendarLegendItem(s.dashCalendarLegendRegine, Colors.red),
                      _buildCalendarLegendItem(s.dashCalendarLegendMelari, Colors.green),
                      _buildCalendarLegendItem(s.dashCalendarLegendSmielature, Colors.amber),
                      _buildCalendarLegendItem(s.dashCalendarLegendSospensione, Colors.deepOrange),
                      _buildCalendarLegendItem(s.dashCalendarLegendBloccoCovata, Colors.brown),
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
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSameDay(_selectedDay!, DateTime.now())
                        ? s.dashCalendarTodayDate(DateFormat('dd/MM/yyyy').format(_selectedDay!))
                        : s.dashCalendarDateEvents(DateFormat('dd/MM/yyyy').format(_selectedDay!)),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (selectedDayEvents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            _isSameDay(_selectedDay!, DateTime.now())
                                ? s.dashCalendarNoEventsToday
                                : s.dashCalendarNoEvents,
                            style: TextStyle(color: ThemeConstants.textSecondaryColor),
                          ),
                        ],
                      ),
                    )
                  else
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
              for (final day in _s.dashWeekdayAbbr)
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
              return _CalendarDayCell(
                date: date,
                isToday: isToday,
                isSelected: isSelected,
                isThisMonth: isThisMonth,
                events: events,
                onTap: () => _selectDay(date),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildWeekView() {
    // Use _focusedDay as starting point, show 2 weeks starting from Monday
    final int weekday = _focusedDay.weekday;
    final startDate = _focusedDay.subtract(Duration(days: weekday - 1));

    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = startDate.add(Duration(days: index));
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
                    ? ThemeConstants.primaryColor30
                    : events.isNotEmpty
                        ? ThemeConstants.primaryColor10
                        : null,
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: ThemeConstants.primaryColor, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _s.dashWeekdayAbbr[date.weekday - 1],
                    style: TextStyle(
                      fontSize: 12,
                      color: ThemeConstants.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                              color: events[i]['color'],
                              shape: BoxShape.circle,
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
  
  void _navigateFromEvent(Map<String, dynamic> event) {
    final type = event['type'];
    switch (type) {
      case 'trattamento':
      case 'sospensione':
      case 'blocco_covata':
        Navigator.of(context).pushNamed(AppConstants.trattamentiRoute);
        break;
      case 'controllo':
        if (event['arnia_id'] != null) {
          Navigator.of(context).pushNamed(
            AppConstants.arniaDetailRoute,
            arguments: event['arnia_id'],
          );
        }
        break;
      case 'regina':
        Navigator.of(context).pushNamed(
          AppConstants.reginaDetailRoute,
          arguments: event['id'],
        );
        break;
      case 'melario':
      case 'smielatura':
        Navigator.of(context).pushNamed(AppConstants.melariRoute);
        break;
      case 'fioritura':
        if (event['id'] != null) {
          Navigator.of(context).pushNamed(
            AppConstants.fiorituraDetailRoute,
            arguments: event['id'] as int,
          );
        }
        break;
    }
  }

  Widget _buildCalendarEventItem(Map<String, dynamic> event) {
    IconData icon;
    Color color = event['color'] ?? ThemeConstants.primaryColor;
    final bool hasTap = true;

    switch (event['type']) {
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
      case 'smielatura':
        icon = Icons.opacity;
        break;
      case 'sospensione':
        icon = Icons.block;
        break;
      case 'blocco_covata':
        icon = Icons.egg_alt;
        break;
      default:
        icon = Icons.event;
    }

    return InkWell(
      onTap: hasTap ? () => _navigateFromEvent(event) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
            if (hasTap)
              Icon(Icons.arrow_forward_ios, size: 14, color: ThemeConstants.textSecondaryColor),
          ],
        ),
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
                    weather['location'] ?? _s.dashWeatherLocal,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                const SizedBox(height: 4),
                Text(
                  _s.dashWeatherHumidity('${weather['humidity']}'),
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
  
  List<Map<String, dynamic>> _generateAlerts(AppStrings s) {
    final List<Map<String, dynamic>> alerts = [];

    for (var t in _trattamenti) {
      if (t['stato'] == 'in_corso' && t['data_fine'] != null) {
        final dataFine = DateTime.parse(t['data_fine']);
        final oggi = DateTime.now();
        final daysLeft = dataFine.difference(oggi).inDays;
        if (daysLeft <= 3) {
          alerts.add({
            'type': 'warning',
            'title': s.dashAlertTrattamentoExpiringTitle,
            'message': s.dashAlertTrattamentoExpiringMsg(
                t['tipo_trattamento_nome'] ?? '', daysLeft),
            'icon': Icons.timer,
            'color': Colors.orange,
            'action': () {},
          });
        }
      }
    }

    for (var apiario in _apiari) {
      if (apiario['ultima_visita'] != null) {
        final ultimaVisita = DateTime.parse(apiario['ultima_visita']);
        if (DateTime.now().difference(ultimaVisita).inDays > 14) {
          alerts.add({
            'type': 'info',
            'title': s.dashAlertApiarioToVisitTitle,
            'message': s.dashAlertApiarioToVisitMsg(apiario['nome'] ?? ''),
            'icon': Icons.calendar_today,
            'color': Colors.blue,
            'action': () => _navigateToApiarioDetail(apiario['id']),
          });
        }
      }
    }

    return alerts;
  }

  Widget _buildAlertsWidget() {
    final s = _s;
    final alerts = _generateAlerts(s);

    if (alerts.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            s.dashAlertsTitle,
            style: ThemeConstants.subheadingStyle,
          ),
        ),
        const SizedBox(height: 8),
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
                          const SizedBox(height: 8),
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
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                s.dashAlertViewDetails,
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
              const SizedBox(height: 8),
              Text(
                apiario['posizione'] ?? _s.dashPositionNone,
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
    final s = _s;
    String dataInizio = trattamento['data_inizio'] ?? s.dashStatusNd;
    String dataFine = trattamento['data_fine'] ?? s.dashStatusInCorso;
    
    List<Widget> children = [];
    
    children.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              trattamento['tipo_trattamento_nome'] ?? s.dashEventTrattamento,
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
                  ? s.dashStatusInCorso
                  : trattamento['stato'] == 'programmato'
                      ? s.dashStatusProgrammato
                      : s.dashStatusCompletato,
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
    
    children.add(const SizedBox(height: 8));
    
    children.add(
      Row(
        children: [
          Icon(Icons.location_on, size: 16, color: ThemeConstants.textSecondaryColor),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              trattamento['apiario_nome'] ?? s.dashStatusApiario,
              style: TextStyle(color: ThemeConstants.textSecondaryColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      )
    );
    
    children.add(const SizedBox(height: 4));
    
    children.add(
      Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: ThemeConstants.textSecondaryColor),
          SizedBox(width: 4),
          Text(
            s.dashTrattamentoDates(dataInizio, dataFine),
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
      
      children.add(const SizedBox(height: 8));
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
    final s = _s;
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
                    fioritura['pianta'] ?? s.dashEventFioritura,
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
                    isActive ? s.dashFiorituraAttiva : s.dashFiorituraTerminata,
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: ThemeConstants.textSecondaryColor),
                SizedBox(width: 4),
                Text(
                  s.dashFiorituraDates(fioritura['data_inizio'] ?? '', fioritura['data_fine']),
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
    final s = _s;
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
            const SizedBox(height: 16),
            Text(
              s.dashSearchNoResults(_searchQuery),
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
                s.dashSearchSection(s.navApiari, _filteredApiari.length),
                style: ThemeConstants.subheadingStyle,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  for (var apiario in _filteredApiari)
                    _buildApiarioCard(apiario),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Risultati della ricerca: Trattamenti
          if (_filteredTrattamenti.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                s.dashSearchSection(s.navTrattamentiSanitari, _filteredTrattamenti.length),
                style: ThemeConstants.subheadingStyle,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  for (var trattamento in _filteredTrattamenti)
                    _buildTrattamentoCard(trattamento),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Risultati della ricerca: Fioriture
          if (_filteredFioriture.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                s.dashSearchSection(s.navFioriture, _filteredFioriture.length),
                style: ThemeConstants.subheadingStyle,
              ),
            ),
            const SizedBox(height: 8),
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
    // Ascolta i cambiamenti di lingua e ricostruisce l'intera widget
    Provider.of<LanguageService>(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Se il drawer è aperto, chiudilo
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState!.closeDrawer();
          return;
        }
        // Altrimenti mostra dialog di conferma uscita
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(_s.dashExitTitle),
            content: Text(_s.dashExitMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(_s.dashExitCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(_s.dashExitConfirm),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: _isSearching ? null : Text(_s.dashTitle),
        actions: [
          // Icona di ricerca
          _isSearching
            ? Container(
                width: 240, // Aumentato per dare più spazio
                margin: EdgeInsets.only(right: 16.0, left: 16.0),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: false,
                      border: InputBorder.none,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _s.dashSearchHint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                      hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.search, color: Colors.white70),
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    cursorColor: Colors.white,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _performSearch();
                      });
                    },
                    autofocus: true,
                  ),
                ),
              )
            : IconButton(
                icon: Icon(Icons.search),
                onPressed: _showSearchView,
                tooltip: _s.dashSearchTooltip,
              ),

          // Pulsante per chiudere la ricerca
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _hideSearchView,
              tooltip: _s.dashCloseSearchTooltip,
            ),
        ],
      ),

      drawer: AppDrawer(currentRoute: AppConstants.dashboardRoute),
      body: Column(
        children: [
          // Banner offline (scompare automaticamente quando torna la connessione)
          const OfflineBanner(),
          // Barra di progresso discreta durante refresh in background
          if (_isRefreshing)
            LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
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
                    ContextualHint(
                      prefKey: 'dashboard_v1',
                      message: _s.dashContextualHint,
                    ),
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
                                  _s.dashWelcomeUser((user?.firstName?.isNotEmpty == true) ? user!.firstName! : (user?.username ?? _s.defaultUserName)),
                                  style: ThemeConstants.headingStyle,
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
                    const SizedBox(height: 16),
                    
                    // Calendario attività
                    _buildCalendar(),
                    const SizedBox(height: 24),
                    
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
                                _s.dashSectionApiari,
                                style: ThemeConstants.subheadingStyle,
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pushNamed(AppConstants.apiarioListRoute),
                                child: Text(_s.dashBtnViewAll),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
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
                                      _s.dashLoadError(_apiariError ?? ''),
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
                                    const SizedBox(height: 16),
                                    Text(
                                      _s.dashNoApiari,
                                      style: TextStyle(
                                        color: ThemeConstants.textSecondaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _navigateToApiarioCreate,
                                      child: Text(_s.dashBtnCreateApiario),
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
                    const SizedBox(height: 24),
                    
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
                                _s.dashSectionTrattamenti,
                                style: ThemeConstants.subheadingStyle,
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pushNamed(AppConstants.trattamentiRoute),
                                child: Text(_s.dashBtnViewAll),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
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
                                      _s.dashLoadError(_trattamentiError ?? ''),
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
                                    const SizedBox(height: 16),
                                    Text(
                                      _s.dashNoTrattamenti,
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
                    const SizedBox(height: 24),
                    
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
                                _s.dashSectionFioriture,
                                style: ThemeConstants.subheadingStyle,
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pushNamed(AppConstants.fioritureListRoute),
                                child: Text(_s.dashBtnViewAll),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
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
                                      _s.dashLoadError(_fioritureError ?? ''),
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
                                    const SizedBox(height: 16),
                                    Text(
                                      _s.dashNoFioriture,
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
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
          ),
        ],
      ),
              floatingActionButton: SpeedDial(
                icon: Icons.add,
                activeIcon: Icons.close,
                backgroundColor: Theme.of(context).primaryColor,
                children: [
                  // Aggiungi questo elemento all'inizio della lista dei SpeedDialChild
                  SpeedDialChild(
                    child: Icon(Icons.mic),
                    label: _s.dashFabVoiceInput,
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    onTap: () {
                      Navigator.of(context).pushNamed(AppConstants.voiceCommandRoute);
                    },
                  ),
                  // Mantieni gli elementi esistenti
                  SpeedDialChild(
                    child: Icon(Icons.chat),
                    label: _s.dashFabAiAssistant,
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    onTap: () {
                    final apiService = Provider.of<ApiService>(context, listen: false);
                    final quotaService = Provider.of<AiQuotaService>(context, listen: false);
                    final chatService = ChatService(apiService, quotaService);

                    // Naviga alla ChatScreen con un ChangeNotifierProvider specifico
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider<ChatService>.value(
                          value: chatService,
                          child: ChatScreen(),
                        ),
                      ),
                    );
                  },
                ),
                SpeedDialChild(
                  child: Icon(Icons.qr_code_scanner),
                  label: _s.dashFabScanQr,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MobileScannerWrapperScreen()),
                    );
                  },
                ),
                SpeedDialChild(
                  child: Icon(Icons.add),
                  label: _s.dashFabNewApiario,
                  onTap: _navigateToApiarioCreate,
                ),
              ],
            ),
    ),
    );
  }
}

/// Extracted calendar cell – allows Flutter to skip rebuild for unchanged cells
class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool isThisMonth;
  final List<dynamic> events;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.isThisMonth,
    required this.events,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeConstants.primaryColor30
              : events.isNotEmpty
                  ? ThemeConstants.primaryColor10
                  : null,
          borderRadius: BorderRadius.circular(4),
          border: isToday
              ? Border.all(color: ThemeConstants.primaryColor, width: 1)
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
                    ? (isSelected ? Colors.black : Colors.black87)
                    : ThemeConstants.grey50,
              ),
            ),
            if (events.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < events.length.clamp(0, 3); i++)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: events[i]['color'] as Color,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
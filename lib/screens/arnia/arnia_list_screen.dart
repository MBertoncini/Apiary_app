import 'package:flutter/material.dart';
import '../../widgets/drawer_widget.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../models/arnia.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/hive_frame_visualizer.dart';
import '../../database/dao/controllo_arnia_dao.dart';
import '../../services/controllo_service.dart';
import '../../widgets/skeleton_widgets.dart';

class ArniaListScreen extends StatefulWidget {
  @override
  _ArniaListScreenState createState() => _ArniaListScreenState();
}

class _ArniaListScreenState extends State<ArniaListScreen> {
  late ApiService _apiService;
  late StorageService _storageService;
  Map<String, List<Arnia>> _arnieByApiario = {};
  bool _isLoading = true;
  bool _isRefreshing = true;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _refreshArnie();
  }

  /// Raggruppa le arnie per nome apiario e le ordina.
  Map<String, List<Arnia>> _groupArnie(List<Arnia> arnie) {
    final Map<String, List<Arnia>> byApiario = {};
    for (var arnia in arnie) {
      final nome = arnia.apiarioNome;
      byApiario.putIfAbsent(nome, () => []).add(arnia);
    }
    byApiario.forEach((_, list) => list.sort((a, b) => a.numero.compareTo(b.numero)));
    return byApiario;
  }

  List<Arnia> _parseArnieResponse(dynamic response) {
    if (response is List) return response.map((item) => Arnia.fromJson(item)).toList();
    if (response is Map && response.containsKey('results') && response['results'] is List) {
      return (response['results'] as List).map((item) => Arnia.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> _refreshArnie() async {
    // Fase 1: cache — mostra subito
    final cachedArnie = await _storageService.getStoredData('arnie');
    if (cachedArnie.isNotEmpty) {
      final arnie = cachedArnie.map((item) => Arnia.fromJson(item)).toList();
      _arnieByApiario = _groupArnie(arnie);
      _isLoading = false;
      if (mounted) setState(() { _isRefreshing = true; });
    } else {
      if (mounted) setState(() { _isRefreshing = true; });
    }

    // Fase 2: aggiornamento dal server
    try {
      final results = await Future.wait([
        _apiService.get(ApiConstants.arnieUrl),
        _apiService.get(ApiConstants.apiariUrl),
      ]);
      List<Arnia> arnie = _parseArnieResponse(results[0]);

      // Aggiorna nomi apiario dalle risposte API
      final apiariRaw = results[1];
      final Map<int, dynamic> apiariMap = {};
      if (apiariRaw is List) {
        for (var a in apiariRaw) { apiariMap[a['id']] = a; }
      } else if (apiariRaw is Map && apiariRaw.containsKey('results')) {
        for (var a in apiariRaw['results']) { apiariMap[a['id']] = a; }
      }
      if (apiariMap.isNotEmpty) {
        arnie = arnie.map((a) {
          if (apiariMap.containsKey(a.apiario)) {
            return Arnia(
              id: a.id, apiario: a.apiario,
              apiarioNome: apiariMap[a.apiario]['nome'],
              numero: a.numero, colore: a.colore, coloreHex: a.coloreHex,
              dataInstallazione: a.dataInstallazione, note: a.note, attiva: a.attiva,
            );
          }
          return a;
        }).toList();
      }

      if (arnie.isNotEmpty) {
        await _storageService.saveData('arnie', arnie.map((a) => a.toJson()).toList());
        _arnieByApiario = _groupArnie(arnie);
      }
    } catch (e) {
      debugPrint('Error fetching arnie from API: $e');
    }

    if (mounted) setState(() { _isLoading = false; _isRefreshing = false; });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Le mie Arnie'),
        actions: [],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.arniaListRoute),
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _isLoading
                ? const SkeletonListView(itemCount: 5)
                : _arnieByApiario.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hive_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text('Nessuna arnia trovata', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Non hai ancora creato arnie o non è stato possibile caricarle',
                                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: Icon(Icons.add),
                              label: Text('Crea arnia'),
                              onPressed: () => Navigator.of(context).pushNamed(AppConstants.creaArniaRoute),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              icon: Icon(Icons.refresh),
                              label: Text('Riprova a caricare'),
                              onPressed: _refreshArnie,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshArnie,
                        child: ListView.builder(
                          itemCount: _arnieByApiario.keys.length,
                          itemBuilder: (context, index) {
                            final apiarioNome = _arnieByApiario.keys.elementAt(index);
                            return ApiarioGroupWidget(
                              apiarioNome: apiarioNome,
                              arnie: _arnieByApiario[apiarioNome] ?? [],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushNamed(AppConstants.creaArniaRoute);
        },
        tooltip: 'Aggiungi arnia',
      ),
    );
  }
}

class ApiarioGroupWidget extends StatefulWidget {
  final String apiarioNome;
  final List<Arnia> arnie;
  
  const ApiarioGroupWidget({
    required this.apiarioNome,
    required this.arnie,
  });
  
  @override
  _ApiarioGroupWidgetState createState() => _ApiarioGroupWidgetState();
}

class _ApiarioGroupWidgetState extends State<ApiarioGroupWidget> {
  bool _isExpanded = true;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intestazione del gruppo con nome apiario
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: ThemeConstants.primaryColor,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.apiarioNome,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.arnie.length} ${widget.arnie.length == 1 ? 'arnia' : 'arnie'}',
                    style: TextStyle(
                      color: ThemeConstants.textSecondaryColor,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                ],
              ),
            ),
          ),
          
          // Legenda telaini (visibile solo se espanso)
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: HiveFrameVisualizer.legend(),
            ),

          // Lista delle arnie dell'apiario (se espanso)
          if (_isExpanded)
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.arnie.length,
              itemBuilder: (context, index) {
                return ArniaListItem(arnia: widget.arnie[index]);
              },
            ),
        ],
      ),
    );
  }
}

class ArniaListItem extends StatefulWidget {
  final Arnia arnia;

  const ArniaListItem({required this.arnia});

  @override
  _ArniaListItemState createState() => _ArniaListItemState();
}

class _ArniaListItemState extends State<ArniaListItem> {
  final _dao = ControlloArniaDao();
  Map<String, dynamic>? _ultimoControllo;

  @override
  void initState() {
    super.initState();
    _loadUltimoControllo();
  }

  Future<void> _loadUltimoControllo() async {
    // Sync dal server poi leggi il più recente da SQLite
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await ControlloService(apiService).getControlliByArnia(widget.arnia.id);
    } catch (e) {
      debugPrint('Error syncing controllo for arnia ${widget.arnia.id}: $e');
    }
    final c = await _dao.getLatestByArnia(widget.arnia.id);
    if (mounted) setState(() => _ultimoControllo = c);
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse(hexColor, radix: 16));
  }

  Color _getContrastColor(Color bg) =>
      bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  @override
  Widget build(BuildContext context) {
    final arniaColor = _getColorFromHex(widget.arnia.coloreHex);

    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(
        AppConstants.arniaDetailRoute,
        arguments: widget.arnia.id,
      ).then((_) => _loadUltimoControllo()),
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── riga principale ──────────────────────────────────
              Row(
                children: [
                  // Numero e colore
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: arniaColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        widget.arnia.numero.toString(),
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: _getContrastColor(arniaColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Informazioni
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Arnia ${widget.arnia.numero}',
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          'Installata il ${widget.arnia.dataInstallazione}',
                          style: TextStyle(fontSize: 12, color: ThemeConstants.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                  // Badge stato
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.arnia.attiva
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.arnia.attiva ? 'Attiva' : 'Inattiva',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.arnia.attiva
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
                  Icon(Icons.navigate_next, color: ThemeConstants.textSecondaryColor),
                ],
              ),

              // ── visualizzatore telaini ───────────────────────────
              const SizedBox(height: 6),
              HiveFrameVisualizer(controllo: _ultimoControllo),
            ],
          ),
        ),
      ),
    );
  }
}
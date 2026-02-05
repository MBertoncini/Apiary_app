import 'package:flutter/material.dart';
import '../../widgets/drawer_widget.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/api_cache_helper.dart';
import '../../models/regina.dart';
import 'package:provider/provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class ReginaListScreen extends StatefulWidget {
  @override
  _ReginaListScreenState createState() => _ReginaListScreenState();
}

class _ReginaListScreenState extends State<ReginaListScreen> {
  List<Regina> _regine = [];
  bool _isLoading = true;
  bool _isOffline = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      final isConnected = await ApiCacheHelper.isConnected();

      if (isConnected) {
        try {
          final response = await apiService.get(ApiConstants.regineUrl);
          debugPrint('API response for regine: $response');

          List<Regina> regine = [];

          if (response is List) {
            regine = response.map((item) => Regina.fromJson(item)).toList();
            debugPrint('Parsed ${regine.length} regine from API (direct array)');
          } else if (response is Map) {
            if (response.containsKey('results') && response['results'] is List) {
              regine = (response['results'] as List)
                  .map((item) => Regina.fromJson(item))
                  .toList();
              debugPrint('Parsed ${regine.length} regine from API (DRF pagination format)');
            } else {
              for (var key in ['regine', 'data', 'items']) {
                if (response.containsKey(key) && response[key] is List) {
                  regine = (response[key] as List)
                      .map((item) => Regina.fromJson(item))
                      .toList();
                  debugPrint('Parsed ${regine.length} regine from API (nested in "$key" property)');
                  break;
                }
              }

              if (regine.isEmpty && response.containsKey('id')) {
                regine = [Regina.fromJson(response as Map<String, dynamic>)];
                debugPrint('Parsed a single regina from response object');
              }
            }
          }

          setState(() {
            _regine = regine;
            _isLoading = false;
            _isOffline = false;
          });

          // Save to cache
          await ApiCacheHelper.saveToCache(
              'regine', _regine.map((r) => r.toJson()).toList());
        } catch (e) {
          debugPrint('Errore API regine, utilizzo cache: $e');
          await _loadFromCache();
        }
      } else {
        await _loadFromCache();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore durante il caricamento delle regine: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedRegine = await ApiCacheHelper.loadFromCache<List<Regina>>(
          'regine',
          (data) =>
              (data as List).map((json) => Regina.fromJson(json)).toList());

      setState(() {
        _regine = cachedRegine ?? [];
        _isLoading = false;
        _isOffline = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Errore durante il caricamento dei dati dalla cache: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Le mie Regine'),
            if (_isOffline)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Tooltip(
                  message: 'Modalità offline - Dati caricati dalla cache',
                  child:
                      Icon(Icons.offline_bolt, size: 18, color: Colors.amber),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            tooltip: 'Sincronizza dati',
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.reginaListRoute),
      body: _isLoading
          ? LoadingWidget(message: 'Caricamento regine...')
          : _errorMessage != null
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage!,
                  onRetry: _loadData,
                )
              : _regine.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_florist_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nessuna regina trovata',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aggiungi regine dalle schede delle singole arnie.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          TextButton.icon(
                            icon: Icon(Icons.refresh),
                            label: Text('Riprova a caricare'),
                            onPressed: _loadData,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        itemCount: _regine.length,
                        itemBuilder: (context, index) {
                          final regina = _regine[index];
                          return ReginaListItem(regina: regina);
                        },
                      ),
                    ),
    );
  }
}

class ReginaListItem extends StatelessWidget {
  final Regina regina;

  ReginaListItem({required this.regina});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text('Regina dell\'arnia ${regina.arniaNumero ?? regina.arniaId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Razza: ${_getRazzaDisplay(regina.razza)}'),
            Text('Origine: ${_getOrigineDisplay(regina.origine)}'),
            Text('Introdotta: ${regina.dataInserimento}'),
            if (regina.marcata)
              Text('Marcata: ${regina.colore ?? "Si"}'),
          ],
        ),
        isThreeLine: true,
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          if (regina.id != null) {
            Navigator.of(context).pushNamed(
              AppConstants.reginaDetailRoute,
              arguments: regina.id,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Dettaglio regina non disponibile')),
            );
          }
        },
      ),
    );
  }

  Widget _buildLeadingIcon() {
    Color reginaColor;

    if (regina.colore != null) {
      switch (regina.colore) {
        case 'bianco':
          reginaColor = Colors.white;
          break;
        case 'giallo':
          reginaColor = Colors.amber;
          break;
        case 'rosso':
          reginaColor = Colors.red;
          break;
        case 'verde':
          reginaColor = Colors.green;
          break;
        case 'blu':
          reginaColor = Colors.blue;
          break;
        default:
          reginaColor = Colors.grey;
          break;
      }
    } else {
      reginaColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: reginaColor,
      child:
          Icon(Icons.local_florist, color: _getContrastColor(reginaColor)),
    );
  }

  String _getRazzaDisplay(String razza) {
    switch (razza) {
      case 'ligustica':
        return 'Apis mellifera ligustica (Italiana)';
      case 'carnica':
        return 'Apis mellifera carnica (Carnica)';
      case 'buckfast':
        return 'Buckfast';
      case 'caucasica':
        return 'Apis mellifera caucasica';
      case 'sicula':
        return 'Apis mellifera sicula (Siciliana)';
      case 'ibrida':
        return 'Ibrida';
      case 'altro':
        return 'Altro';
      default:
        return razza;
    }
  }

  String _getOrigineDisplay(String origine) {
    switch (origine) {
      case 'acquistata':
        return 'Acquistata';
      case 'allevata':
        return 'Allevata';
      case 'sciamatura':
        return 'Sciamatura Naturale';
      case 'emergenza':
        return 'Celle di Emergenza';
      case 'sconosciuta':
        return 'Sconosciuta';
      default:
        return origine;
    }
  }

  Color _getContrastColor(Color backgroundColor) {
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

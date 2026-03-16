import 'package:flutter/material.dart';
import '../../widgets/drawer_widget.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../models/regina.dart';
import 'package:provider/provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/offline_banner.dart';

class ReginaListScreen extends StatefulWidget {
  @override
  _ReginaListScreenState createState() => _ReginaListScreenState();
}

class _ReginaListScreenState extends State<ReginaListScreen> {
  List<Regina> _regine = [];
  bool _isLoading = true;
  bool _isRefreshing = true;
  bool _isOffline = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    _errorMessage = null;

    // Fase 1: cache — mostra subito
    final cachedRaw = await storageService.getStoredData('regine');
    if (cachedRaw.isNotEmpty) {
      _regine = cachedRaw.map((item) => Regina.fromJson(item)).toList();
      _isLoading = false;
      if (mounted) setState(() { _isRefreshing = true; });
    } else {
      if (mounted) setState(() { _isLoading = true; });
    }

    // Fase 2: aggiornamento dal server
    try {
      final response = await apiService.get(ApiConstants.regineUrl);
      List<Regina> regine = [];
      if (response is List) {
        regine = response.map((item) => Regina.fromJson(item)).toList();
      } else if (response is Map && response.containsKey('results') && response['results'] is List) {
        regine = (response['results'] as List).map((item) => Regina.fromJson(item)).toList();
      }
      _regine = regine;
      _isLoading = false;
      _isOffline = false;
      await storageService.saveData('regine', regine.map((r) => r.toJson()).toList());
    } catch (e) {
      debugPrint('Errore API regine: $e');
      _isLoading = false;
      _isOffline = _regine.isNotEmpty; // offline solo se abbiamo mostrato dati cached
      if (_regine.isEmpty) _errorMessage = 'Errore durante il caricamento delle regine: $e';
    }

    if (mounted) setState(() { _isRefreshing = false; });
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
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _isLoading
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
          ),
        ],
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

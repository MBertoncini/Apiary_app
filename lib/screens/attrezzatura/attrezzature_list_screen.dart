// lib/screens/attrezzatura/attrezzature_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/attrezzatura.dart';
import '../../services/attrezzatura_service.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/drawer_widget.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class AttrezzatureListScreen extends StatefulWidget {
  @override
  _AttrezzatureListScreenState createState() => _AttrezzatureListScreenState();
}

class _AttrezzatureListScreenState extends State<AttrezzatureListScreen> {
  List<Attrezzatura> _attrezzature = [];
  bool _isLoading = true;
  bool _isRefreshing = true;
  String? _errorMessage;
  String _filtroStato = 'tutti';
  String _filtroCondizione = 'tutti';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _errorMessage = null; });

    // Phase 1: cache
    final storageService = Provider.of<StorageService>(context, listen: false);
    final cached = await storageService.getStoredData('attrezzature');
    if (cached.isNotEmpty) {
      _attrezzature = cached.map((e) => Attrezzatura.fromJson(e as Map<String, dynamic>)).toList();
      _isLoading = false;
      if (mounted) setState(() { _isRefreshing = true; });
    } else {
      if (mounted) setState(() { _isRefreshing = true; });
    }

    // Phase 2: API
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final attrezzaturaService = AttrezzaturaService(apiService);
      final attrezzature = await attrezzaturaService.getAttrezzature();
      await storageService.saveData('attrezzature', attrezzature.map((a) => a.toJson()).toList());
      _attrezzature = attrezzature;
    } catch (e) {
      debugPrint('Errore API attrezzature: $e');
      if (_attrezzature.isEmpty) {
        _errorMessage = 'Errore durante il caricamento dei dati: $e';
      }
    }

    if (mounted) setState(() { _isLoading = false; _isRefreshing = false; });
  }

  List<Attrezzatura> get _filteredAttrezzature {
    return _attrezzature.where((a) {
      // Filtro per stato
      if (_filtroStato != 'tutti' && a.stato != _filtroStato) {
        return false;
      }
      // Filtro per condizione
      if (_filtroCondizione != 'tutti' && a.condizione != _filtroCondizione) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attrezzature'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            tooltip: 'Filtri',
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: Icon(Icons.sync),
            tooltip: 'Sincronizza dati',
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.attrezzatureRoute),
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _isRefreshing && _attrezzature.isEmpty
                ? const SizedBox.shrink()
                : _errorMessage != null
                    ? ErrorDisplayWidget(
                        errorMessage: _errorMessage!,
                        onRetry: _loadData,
                      )
                    : _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppConstants.attrezzaturaCreateRoute)
              .then((_) => _loadData());
        },
        child: Icon(Icons.add),
        tooltip: 'Nuova Attrezzatura',
      ),
    );
  }

  Widget _buildBody() {
    final filtered = _filteredAttrezzature;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _attrezzature.isEmpty
                  ? 'Nessuna attrezzatura registrata'
                  : 'Nessuna attrezzatura corrisponde ai filtri',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (_attrezzature.isEmpty)
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Aggiungi Attrezzatura'),
                onPressed: () {
                  Navigator.pushNamed(context, AppConstants.attrezzaturaCreateRoute)
                      .then((_) => _loadData());
                },
              ),
          ],
        ),
      );
    }

    final formatCurrency = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final formatDate = DateFormat('dd/MM/yyyy');

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final attrezzatura = filtered[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatoColor(attrezzatura.stato).withOpacity(0.2),
                child: Icon(
                  Icons.build,
                  color: _getStatoColor(attrezzatura.stato),
                ),
              ),
              title: Text(
                attrezzatura.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${attrezzatura.categoriaNome ?? 'Non categorizzato'} - Qtà: ${attrezzatura.quantita}',
                    maxLines: 1,
                  ),
                  if (attrezzatura.dataAcquisto != null)
                    Text(
                      'Acquistato: ${formatDate.format(attrezzatura.dataAcquisto!)}',
                      style: TextStyle(fontSize: 12),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (attrezzatura.prezzoAcquisto != null && attrezzatura.prezzoAcquisto! > 0)
                    Text(
                      formatCurrency.format(attrezzatura.prezzoAcquisto),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ThemeConstants.primaryColor,
                      ),
                    ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatoColor(attrezzatura.stato).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      attrezzatura.getStatoDisplay(),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getStatoColor(attrezzatura.stato),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppConstants.attrezzaturaDetailRoute,
                  arguments: attrezzatura.id,
                ).then((_) => _loadData());
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatoColor(String? stato) {
    switch (stato) {
      case 'disponibile':
        return Colors.green;
      case 'in_uso':
        return Colors.blue;
      case 'manutenzione':
        return Colors.orange;
      case 'dismesso':
        return Colors.grey;
      case 'prestato':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempStato = _filtroStato;
        String tempCondizione = _filtroCondizione;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Filtra Attrezzature'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tempStato,
                    decoration: InputDecoration(
                      labelText: 'Stato',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'tutti', child: Text('Tutti')),
                      ...Attrezzatura.statiDisponibili.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.replaceAll('_', ' ').capitalize()),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => tempStato = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tempCondizione,
                    decoration: InputDecoration(
                      labelText: 'Condizione',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'tutti', child: Text('Tutti')),
                      ...Attrezzatura.condizioniDisponibili.map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.replaceAll('_', ' ').capitalize()),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => tempCondizione = value!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filtroStato = 'tutti';
                      _filtroCondizione = 'tutti';
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Reset'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annulla'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filtroStato = tempStato;
                      _filtroCondizione = tempCondizione;
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Applica'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Extension per capitalizzare le stringhe
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../models/vendita.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class VenditaDetailScreen extends StatefulWidget {
  final int venditaId;
  VenditaDetailScreen({required this.venditaId});

  @override
  _VenditaDetailScreenState createState() => _VenditaDetailScreenState();
}

class _VenditaDetailScreenState extends State<VenditaDetailScreen> {
  Vendita? _vendita;
  bool _isRefreshing = true;
  String? _errorMessage;
  late ApiService _apiService;
  late StorageService _storageService;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService     = ApiService(authService);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _loadVendita();
  }

  Future<void> _loadVendita() async {
    setState(() { _isRefreshing = true; _errorMessage = null; });

    // Fase 1: cache
    final cached = await _storageService.getStoredData('vendite');
    final cachedMap = cached.cast<Map<String, dynamic>>().firstWhere(
      (v) => v['id'] == widget.venditaId,
      orElse: () => <String, dynamic>{},
    );
    if (cachedMap.isNotEmpty && mounted) {
      setState(() { _vendita = Vendita.fromJson(cachedMap); });
    }

    // Fase 2: server
    try {
      final data = await _apiService.get('${ApiConstants.venditeUrl}${widget.venditaId}/');
      if (mounted) {
        setState(() { _vendita = Vendita.fromJson(data); _isRefreshing = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      if (_vendita != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Modalità offline — dati aggiornati all\'ultimo accesso')));
      } else {
        setState(() { _errorMessage = 'Errore: $e'; });
      }
    }
  }

  Future<void> _deleteVendita() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conferma eliminazione'),
        content: Text('Eliminare questa vendita?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ANNULLA')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: Text('ELIMINA')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _apiService.delete('${ApiConstants.venditeUrl}${widget.venditaId}/');
        await _storageService.saveData('vendite', []);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vendita eliminata')));
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────

  String _canaleLabel(String c) {
    const m = {'mercatino':'Mercatino','negozio':'Negozio','privato':'Privato','online':'Online','altro':'Altro'};
    return m[c] ?? c;
  }

  String _pagamentoLabel(String p) {
    const m = {'contanti':'Contanti','bonifico':'Bonifico','carta':'Carta','altro':'Altro'};
    return m[p] ?? p;
  }

  String _categoriaNome(String cat) {
    const map = {
      'miele':'Miele','propoli':'Propoli','cera':'Cera','polline':'Polline',
      'pappa_reale':'Pappa reale','nucleo':'Nucleo','regina':'Regina','altro':'Altro',
    };
    return map[cat] ?? cat;
  }

  IconData _categoriaIcon(String cat) {
    switch (cat) {
      case 'miele':      return Icons.local_dining;
      case 'propoli':    return Icons.science;
      case 'cera':       return Icons.light;
      case 'polline':    return Icons.filter_vintage;
      case 'nucleo':     return Icons.hive;
      case 'regina':     return Icons.star;
      default:           return Icons.inventory_2;
    }
  }

  String _dettaglioTitle(DettaglioVendita d) {
    if (d.categoria == 'miele') {
      final tipo = d.tipoMiele ?? 'Miele';
      final fmt  = d.formatoVasetto != null ? ' ${d.formatoVasetto}g' : '';
      return '$tipo$fmt';
    }
    return _categoriaNome(d.categoria);
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dettaglio Vendita'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _vendita == null ? null : () {
              Navigator.pushNamed(context, AppConstants.venditaCreateRoute,
                  arguments: _vendita!.id).then((_) => _loadVendita());
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _vendita == null ? null : _deleteVendita,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _isRefreshing && _vendita == null && _errorMessage == null
                ? const SizedBox.shrink()
                : _errorMessage != null
                    ? ErrorDisplayWidget(errorMessage: _errorMessage!, onRetry: _loadVendita)
                    : _vendita == null
                        ? const Center(child: Text('Vendita non trovata'))
                        : SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      '${_vendita!.totale?.toStringAsFixed(2) ?? '0.00'} €',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: ThemeConstants.primaryColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  _buildInfoRow('Data',      _vendita!.data),
                                  _buildInfoRow('Acquirente', _vendita!.displayName),
                                  _buildInfoRow('Canale',    _canaleLabel(_vendita!.canale)),
                                  _buildInfoRow('Pagamento', _pagamentoLabel(_vendita!.pagamento)),
                                  if (_vendita!.note != null && _vendita!.note!.isNotEmpty)
                                    _buildInfoRow('Note', _vendita!.note!),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('Articoli', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          ..._vendita!.dettagli.map((d) => Card(
                            child: ListTile(
                              leading: Icon(_categoriaIcon(d.categoria), size: 22,
                                  color: ThemeConstants.primaryColor),
                              title: Text(_dettaglioTitle(d)),
                              subtitle: Text(
                                '${d.quantita} x ${d.prezzoUnitario.toStringAsFixed(2)} €'),
                              trailing: Text(
                                '${(d.subtotale ?? d.quantita * d.prezzoUnitario).toStringAsFixed(2)} €',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

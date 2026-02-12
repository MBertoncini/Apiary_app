import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
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
  bool _isLoading = true;
  String? _errorMessage;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _loadVendita();
  }

  Future<void> _loadVendita() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final data = await _apiService.get('${ApiConstants.venditeUrl}${widget.venditaId}/');
      setState(() { _vendita = Vendita.fromJson(data); _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = 'Errore: $e'; _isLoading = false; });
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
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('ELIMINA')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _apiService.delete('${ApiConstants.venditeUrl}${widget.venditaId}/');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vendita eliminata')));
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dettaglio Vendita'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _vendita == null ? null : () {
              Navigator.pushNamed(context, AppConstants.venditaCreateRoute, arguments: _vendita!.id).then((_) => _loadVendita());
            },
          ),
          IconButton(icon: Icon(Icons.delete), onPressed: _vendita == null ? null : _deleteVendita),
        ],
      ),
      body: _isLoading
          ? LoadingWidget()
          : _errorMessage != null
              ? ErrorDisplayWidget(errorMessage: _errorMessage!, onRetry: _loadVendita)
              : _vendita == null
                  ? Center(child: Text('Vendita non trovata'))
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
                                      '${_vendita!.totale?.toStringAsFixed(2) ?? '0.00'} \u20AC',
                                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThemeConstants.primaryColor),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  _buildInfoRow('Data', _vendita!.data),
                                  _buildInfoRow('Cliente', _vendita!.clienteNome ?? ''),
                                  if (_vendita!.note != null && _vendita!.note!.isNotEmpty)
                                    _buildInfoRow('Note', _vendita!.note!),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('Dettagli', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          ..._vendita!.dettagli.map((d) => Card(
                            child: ListTile(
                              title: Text('${d.tipoMiele} - ${d.formatoVasetto}g'),
                              subtitle: Text('${d.quantita} x ${d.prezzoUnitario.toStringAsFixed(2)} \u20AC'),
                              trailing: Text('${d.subtotale?.toStringAsFixed(2) ?? (d.quantita * d.prezzoUnitario).toStringAsFixed(2)} \u20AC',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          )),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

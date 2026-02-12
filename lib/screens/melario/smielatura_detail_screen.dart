import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class SmielaturaDetailScreen extends StatefulWidget {
  final int smielaturaId;
  SmielaturaDetailScreen({required this.smielaturaId});
  @override
  _SmielaturaDetailScreenState createState() => _SmielaturaDetailScreenState();
}

class _SmielaturaDetailScreenState extends State<SmielaturaDetailScreen> {
  Map<String, dynamic>? _smielatura;
  bool _isLoading = true;
  String? _errorMessage;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _loadSmielatura();
  }

  Future<void> _loadSmielatura() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final data = await _apiService.get('${ApiConstants.produzioniUrl}${widget.smielaturaId}/');
      setState(() { _smielatura = data; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = 'Errore: $e'; _isLoading = false; });
    }
  }

  Future<void> _deleteSmielatura() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conferma eliminazione'),
        content: Text('Sei sicuro di voler eliminare questa smielatura?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ANNULLA')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('ELIMINA')),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() { _isLoading = true; });
      try {
        await _apiService.delete('${ApiConstants.produzioniUrl}${widget.smielaturaId}/');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Smielatura eliminata')));
        Navigator.pop(context, true);
      } catch (e) {
        setState(() { _errorMessage = 'Errore: $e'; _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dettaglio Smielatura'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _smielatura == null ? null : () {
              Navigator.pushNamed(context, AppConstants.smielaturaCreateRoute, arguments: _smielatura).then((_) => _loadSmielatura());
            },
          ),
          IconButton(icon: Icon(Icons.delete), onPressed: _smielatura == null ? null : _deleteSmielatura),
        ],
      ),
      body: _isLoading
          ? LoadingWidget()
          : _errorMessage != null
              ? ErrorDisplayWidget(errorMessage: _errorMessage!, onRetry: _loadSmielatura)
              : _smielatura == null
                  ? Center(child: Text('Smielatura non trovata'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final s = _smielatura!;
    final melariIds = s['melari'] as List? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main info card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      '${s['quantita_miele']} kg',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThemeConstants.primaryColor),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(s['tipo_miele'] ?? '', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow('Data', s['data'] ?? ''),
                  _buildInfoRow('Apiario', s['apiario_nome'] ?? ''),
                  _buildInfoRow('Melari', '${melariIds.length} melari'),
                  if (s['note'] != null && s['note'].toString().isNotEmpty)
                    _buildInfoRow('Note', s['note']),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          // Melari list
          if (melariIds.isNotEmpty) ...[
            Text('Melari associati', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...melariIds.map((id) => Card(
              child: ListTile(
                leading: Icon(Icons.view_module, color: Colors.amber),
                title: Text('Melario #$id'),
              ),
            )),
          ],
        ],
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

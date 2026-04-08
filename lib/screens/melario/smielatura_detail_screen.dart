import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../l10n/app_strings.dart';
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
  bool _isRefreshing = true;
  String? _errorMessage;
  late ApiService _apiService;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _loadSmielatura();
  }

  Future<void> _loadSmielatura() async {
    setState(() { _isRefreshing = true; _errorMessage = null; });
    try {
      final data = await _apiService.get('${ApiConstants.produzioniUrl}${widget.smielaturaId}/');
      setState(() { _smielatura = data; _isRefreshing = false; });
    } catch (e) {
      setState(() { _errorMessage = 'Errore: $e'; _isRefreshing = false; });
    }
  }

  Future<void> _deleteSmielatura() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_s.melariDeleteInvasettTitle),
        content: Text(_s.smielaturaDetailDeleteMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_s.dialogCancelBtn)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(_s.btnDeleteCaps)),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() { _isRefreshing = true; });
      try {
        await _apiService.delete('${ApiConstants.produzioniUrl}${widget.smielaturaId}/');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.smielaturaDetailDeletedOk)));
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        setState(() { _errorMessage = 'Errore: $e'; _isRefreshing = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.smielaturaDetailTitle),
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
      body: Column(
        children: [
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _isRefreshing && _smielatura == null && _errorMessage == null
                ? const SizedBox.shrink()
                : _errorMessage != null
                    ? ErrorDisplayWidget(errorMessage: _errorMessage!, onRetry: _loadSmielatura)
                    : _smielatura == null
                        ? Center(child: Text(s.smielaturaDetailNotFound))
                        : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final loc = _s;
    final data = _smielatura!;
    final melariIds = data['melari'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      '${data['quantita_miele']} kg',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThemeConstants.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(data['tipo_miele'] ?? '', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(loc.labelDate, data['data'] ?? ''),
                  _buildInfoRow(loc.labelApiario, data['apiario_nome'] ?? ''),
                  _buildInfoRow(loc.smielaturaDetailLblMelari, loc.smielaturaDetailMelariCount(melariIds.length)),
                  if (data['note'] != null && data['note'].toString().isNotEmpty)
                    _buildInfoRow(loc.labelNotes, data['note']),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Melari list
          if (melariIds.isNotEmpty) ...[
            Text(loc.smielaturaDetailMelariAssociati, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...melariIds.map((id) => Card(
              child: ListTile(
                leading: const Icon(Icons.view_module, color: Colors.amber),
                title: Text(loc.melariMelarioId(id as int)),
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

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

class TrattamentoDetailScreen extends StatefulWidget {
  final int trattamentoId;

  const TrattamentoDetailScreen({Key? key, required this.trattamentoId})
      : super(key: key);

  @override
  _TrattamentoDetailScreenState createState() =>
      _TrattamentoDetailScreenState();
}

class _TrattamentoDetailScreenState extends State<TrattamentoDetailScreen> {
  Map<String, dynamic>? _trattamento;
  bool _isLoading = true;
  String? _errorMessage;
  late ApiService _apiService;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _loadTrattamento();
  }

  Future<void> _loadTrattamento() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _apiService
          .get('${ApiConstants.trattamentiUrl}${widget.trattamentoId}/');
      setState(() {
        _trattamento = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore nel caricamento: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTrattamento() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content:
            const Text('Sei sicuro di voler eliminare questo trattamento?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ANNULLA')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ELIMINA',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _apiService
          .delete('${ApiConstants.trattamentiUrl}${widget.trattamentoId}/');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trattamento eliminato')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore eliminazione: $e')));
      }
    }
  }

  String _formatDate(String? date) {
    if (date == null) return '—';
    try {
      return _dateFormat.format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  Color _statusColor(String? stato) {
    switch (stato) {
      case 'in_corso':
        return Colors.orange;
      case 'programmato':
        return Colors.blue;
      case 'completato':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? stato) {
    switch (stato) {
      case 'in_corso':
        return 'In corso';
      case 'programmato':
        return 'Programmato';
      case 'completato':
        return 'Completato';
      case 'annullato':
        return 'Annullato';
      default:
        return stato ?? '—';
    }
  }

  String _metodoLabel(String? metodo) {
    const labels = {
      'strisce': 'Strisce',
      'gocciolato': 'Gocciolato',
      'sublimato': 'Sublimato',
      'altro': 'Altro',
    };
    return labels[metodo] ?? metodo ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    final stato = _trattamento?['stato'] as String?;
    final canEdit = stato == 'in_corso' || stato == 'programmato';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio Trattamento'),
        actions: [
          if (_trattamento != null && canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Modifica',
              onPressed: () => Navigator.of(context)
                  .pushNamed(
                    AppConstants.trattamentoCreateRoute,
                    arguments: {'trattamentoId': widget.trattamentoId},
                  )
                  .then((result) {
                if (result == true && mounted) _loadTrattamento();
              }),
            ),
          if (_trattamento != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Elimina',
              onPressed: _deleteTrattamento,
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Caricamento trattamento...')
          : _errorMessage != null
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage!, onRetry: _loadTrattamento)
              : _buildDetail(),
    );
  }

  Widget _buildDetail() {
    final t = _trattamento!;
    final stato = t['stato'] as String?;
    final statusColor = _statusColor(stato);
    final bloccoCovata =
        t['blocco_covata_attivo'] == true || t['blocco_covata_attivo'] == 1;
    final arnie = (t['arnie'] as List?)?.cast<dynamic>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: tipo trattamento + stato
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t['tipo_trattamento_nome'] ?? '—',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          _statusLabel(stato),
                          style: TextStyle(
                              color: statusColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (t['apiario_nome'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.hive_outlined,
                            size: 16,
                            color: ThemeConstants.textSecondaryColor),
                        const SizedBox(width: 6),
                        Text(
                          t['apiario_nome'] as String,
                          style: TextStyle(
                              color: ThemeConstants.textSecondaryColor),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Dettagli principali
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Dettagli trattamento'),
                  const SizedBox(height: 12),
                  _infoRow(Icons.science_outlined, 'Metodo di applicazione',
                      _metodoLabel(t['metodo_applicazione'] as String?)),
                  const Divider(height: 20),
                  _infoRow(Icons.calendar_today_outlined, 'Data inizio',
                      _formatDate(t['data_inizio'] as String?)),
                  if (t['data_fine'] != null) ...[
                    const Divider(height: 20),
                    _infoRow(Icons.event_available_outlined, 'Data fine',
                        _formatDate(t['data_fine'] as String?)),
                  ],
                  if (t['data_fine_sospensione'] != null) ...[
                    const Divider(height: 20),
                    _infoRow(Icons.warning_amber_outlined,
                        'Sospensione fino al',
                        _formatDate(t['data_fine_sospensione'] as String?),
                        color: Colors.orange),
                  ],
                ],
              ),
            ),
          ),

          // Arnie target
          if (arnie.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Arnie trattate'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: arnie
                          .map((id) => Chip(
                                label: Text('Arnia $id'),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.hive,
                        size: 18,
                        color: ThemeConstants.textSecondaryColor),
                    const SizedBox(width: 8),
                    Text('Applicato a tutto l\'apiario',
                        style: TextStyle(
                            color: ThemeConstants.textSecondaryColor)),
                  ],
                ),
              ),
            ),
          ],

          // Blocco covata
          if (bloccoCovata) ...[
            const SizedBox(height: 12),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.block, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        _sectionTitle('Blocco di covata'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (t['data_inizio_blocco'] != null)
                      _infoRow(Icons.calendar_today_outlined, 'Inizio blocco',
                          _formatDate(t['data_inizio_blocco'] as String?)),
                    if (t['data_fine_blocco'] != null) ...[
                      const Divider(height: 20),
                      _infoRow(Icons.event_available_outlined, 'Fine blocco',
                          _formatDate(t['data_fine_blocco'] as String?)),
                    ],
                    if (t['metodo_blocco'] != null &&
                        (t['metodo_blocco'] as String).isNotEmpty) ...[
                      const Divider(height: 20),
                      _infoRow(Icons.info_outline, 'Metodo',
                          t['metodo_blocco'] as String),
                    ],
                    if (t['note_blocco'] != null &&
                        (t['note_blocco'] as String).isNotEmpty) ...[
                      const Divider(height: 20),
                      _infoRow(Icons.notes, 'Note blocco',
                          t['note_blocco'] as String),
                    ],
                  ],
                ),
              ),
            ),
          ],

          // Note
          if (t['note'] != null && (t['note'] as String).isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Note'),
                    const SizedBox(height: 8),
                    Text(
                      t['note'] as String,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 18,
            color: color ?? ThemeConstants.textSecondaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: ThemeConstants.textSecondaryColor)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      color: color,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

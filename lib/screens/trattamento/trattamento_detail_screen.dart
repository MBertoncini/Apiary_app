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
import '../../l10n/app_strings.dart';
import '../../services/language_service.dart';

class TrattamentoDetailScreen extends StatefulWidget {
  final int trattamentoId;

  const TrattamentoDetailScreen({Key? key, required this.trattamentoId})
      : super(key: key);

  @override
  _TrattamentoDetailScreenState createState() =>
      _TrattamentoDetailScreenState();
}

class _TrattamentoDetailScreenState extends State<TrattamentoDetailScreen> {
  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

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
        _errorMessage = _s.trattamentoDetailDeleteError(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreTrattamento() async {
    final s = _s;
    try {
      await _apiService.patch(
        '${ApiConstants.trattamentiUrl}${widget.trattamentoId}/',
        {'stato': 'programmato'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.trattamentoRestoredOk)));
        _loadTrattamento();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.trattamentoRestoreError(e.toString()))));
      }
    }
  }

  Future<void> _deleteTrattamento() async {
    final s = _s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.trattamentoDetailDeleteTitle),
        content: Text(s.trattamentoDetailDeleteMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.dialogCancelBtn.toUpperCase())),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.btnDeleteCaps,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _apiService
          .delete('${ApiConstants.trattamentiUrl}${widget.trattamentoId}/');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.trattamentoDetailDeletedOk)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.trattamentoDetailDeleteError(e.toString()))));
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
      case 'annullato':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? stato, AppStrings s) {
    switch (stato) {
      case 'in_corso':    return s.dashStatusInCorso;
      case 'programmato': return s.dashStatusProgrammato;
      case 'completato':  return s.dashStatusCompletato;
      case 'annullato':   return s.trattamentoStatusAnnullato;
      default:            return stato ?? '—';
    }
  }

  String _metodoLabel(String? metodo, AppStrings s) {
    switch (metodo) {
      case 'strisce':    return s.trattamentiMetodoStrisce;
      case 'gocciolato': return s.trattamentiMetodoGocciolato;
      case 'sublimato':  return s.trattamentiMetodoSublimato;
      case 'altro':      return s.arniaDetailChangeMotivoAltro;
      default:           return metodo ?? '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context); // rebuild on language change
    final s = _s;
    final stato = _trattamento?['stato'] as String?;
    final canEdit =
        stato == 'in_corso' || stato == 'programmato' || stato == 'annullato';
    final canRestore = stato == 'annullato';

    return Scaffold(
      appBar: AppBar(
        title: Text(s.trattamentoDetailTitle),
        actions: [
          if (_trattamento != null && canRestore)
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: s.trattamentoDetailTooltipRestore,
              onPressed: _restoreTrattamento,
            ),
          if (_trattamento != null && canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: s.trattamentoDetailTooltipEdit,
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
              tooltip: s.trattamentoDetailTooltipDelete,
              onPressed: _deleteTrattamento,
            ),
        ],
      ),
      body: _isLoading
          ? LoadingWidget(message: s.trattamentoDetailLblCaricamento)
          : _errorMessage != null
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage!, onRetry: _loadTrattamento)
              : _buildDetail(),
    );
  }

  Widget _buildDetail() {
    final s = _s;
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
                          _statusLabel(stato, s),
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
                  _sectionTitle(s.trattamentoDetailSectionDettagli),
                  const SizedBox(height: 12),
                  _infoRow(Icons.science_outlined, s.trattamentoDetailLblMetodo,
                      _metodoLabel(t['metodo_applicazione'] as String?, s)),
                  const Divider(height: 20),
                  _infoRow(Icons.calendar_today_outlined, s.trattamentoDetailLblDataInizio,
                      _formatDate(t['data_inizio'] as String?)),
                  if (t['data_fine'] != null) ...[
                    const Divider(height: 20),
                    _infoRow(Icons.event_available_outlined, s.trattamentoDetailLblDataFine,
                        _formatDate(t['data_fine'] as String?)),
                  ],
                  if (t['data_fine_sospensione'] != null) ...[
                    const Divider(height: 20),
                    _infoRow(Icons.warning_amber_outlined,
                        s.trattamentoDetailLblSospFino,
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
                    _sectionTitle(s.trattamentoDetailLblArnieTrattate),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: arnie
                          .map((id) => Chip(
                                label: Text(s.trattamentoDetailArniaLabel(id.toString())),
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
                    Text(s.trattamentoDetailApplicatoTutto,
                        style: const TextStyle(
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
                        _sectionTitle(s.trattamentoDetailLblBloccoCovata),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (t['data_inizio_blocco'] != null)
                      _infoRow(Icons.calendar_today_outlined, s.trattamentoDetailLblInizioBlocko,
                          _formatDate(t['data_inizio_blocco'] as String?)),
                    if (t['data_fine_blocco'] != null) ...[
                      const Divider(height: 20),
                      _infoRow(Icons.event_available_outlined, s.trattamentoDetailLblFineBlocko,
                          _formatDate(t['data_fine_blocco'] as String?)),
                    ],
                    if (t['metodo_blocco'] != null &&
                        (t['metodo_blocco'] as String).isNotEmpty) ...[
                      const Divider(height: 20),
                      _infoRow(Icons.info_outline, s.trattamentoDetailLblMetodoBlocko,
                          t['metodo_blocco'] as String),
                    ],
                    if (t['note_blocco'] != null &&
                        (t['note_blocco'] as String).isNotEmpty) ...[
                      const Divider(height: 20),
                      _infoRow(Icons.notes, s.trattamentoDetailLblNoteBlocko,
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
                    _sectionTitle(s.labelNotes),
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

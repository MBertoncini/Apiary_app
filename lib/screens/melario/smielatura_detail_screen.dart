import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../l10n/app_strings.dart';
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
  /// Mappa pk Melario → numero_progressivo per-utente, letta dalla cache locale.
  /// Fallback all'`id` se il record non è in cache (es. legacy o cache vuota).
  Map<int, int> _melariNumByPk = {};

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
    // Leggi il provider PRIMA degli await per evitare context-across-async-gap.
    final storage = Provider.of<StorageService>(context, listen: false);
    try {
      final data = await _apiService.get('${ApiConstants.produzioniUrl}${widget.smielaturaId}/');
      // Carica anche la mappa pk -> numero_progressivo dalla cache locale
      // per mostrare il numero per-utente invece del pk SQL globale.
      final cached = await storage.getStoredData('melari');
      final map = <int, int>{};
      for (final raw in cached) {
        if (raw is Map<String, dynamic>) {
          final pk = raw['id'];
          final n = raw['numero_progressivo'];
          if (pk is int && n is int) map[pk] = n;
        }
      }
      setState(() {
        _smielatura = data;
        _melariNumByPk = map;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() { _errorMessage = 'Errore: $e'; _isRefreshing = false; });
    }
  }

  Future<void> _deleteSmielatura() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_s.smielaturaDetailDeleteTitle),
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

        // Aggiorna la cache locale leggendo gli stati VERI dei melari coinvolti
        // dal server. Il backend (signal pre_delete su Smielatura) ripristina
        // ciascun melario al suo `stato_origine` salvato nella through table:
        // può essere 'posizionato', 'rimosso', ecc. — non più sempre 'rimosso'.
        // Una patch ottimistica con stato hardcoded sarebbe corretta solo per
        // le smielature legacy (pre-migrazione 0045).
        final melariIds = ((_smielatura?['melari'] as List?) ?? const [])
            .map((e) => e as int)
            .toSet();
        if (mounted) {
          final storageService =
              Provider.of<StorageService>(context, listen: false);
          if (melariIds.isNotEmpty) {
            // GET puntuale con ?ids=… per leggere gli stati ripristinati.
            Map<int, Map<String, dynamic>> fresh = {};
            try {
              final url =
                  '${ApiConstants.melariUrl}?ids=${melariIds.join(',')}';
              final resp = await _apiService.get(url);
              final list = resp is List
                  ? resp
                  : (resp is Map && resp['results'] is List
                      ? resp['results'] as List
                      : const []);
              for (final raw in list) {
                if (raw is Map<String, dynamic> && raw['id'] is int) {
                  fresh[raw['id'] as int] = raw;
                }
              }
            } catch (_) {
              // Network/parse error: lasciamo `fresh` vuoto → la cache mostrerà
              // l'ultimo stato noto fino al refresh di MelariScreen.
            }
            final cached = await storageService.getStoredData('melari');
            if (cached.isNotEmpty) {
              final updated = cached.map<Map<String, dynamic>>((raw) {
                final m = raw as Map<String, dynamic>;
                final pk = m['id'];
                if (pk is int && fresh.containsKey(pk)) {
                  return fresh[pk]!;
                }
                return m;
              }).toList();
              await storageService.saveData('melari', updated);
            }
          }

          // Rimuovi la smielatura cancellata anche dalla cache 'smielature'.
          // Senza questo, MelariScreen in fase cache-first di _refreshAll
          // ricarica l'elemento appena eliminato finché non arriva il GET
          // /produzioni/ di fase 2.
          final cachedSm = await storageService.getStoredData('smielature');
          if (cachedSm.isNotEmpty) {
            final filtered = cachedSm
                .where((raw) => (raw as Map<String, dynamic>)['id'] !=
                    widget.smielaturaId)
                .toList();
            if (filtered.length != cachedSm.length) {
              await storageService.saveData('smielature', filtered);
            }
          }
        }

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
            ...melariIds.map((id) {
              final pk = id as int;
              final numDisplay = _melariNumByPk[pk] ?? pk;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.view_module, color: Colors.amber),
                  title: Text(loc.melariMelarioId(numDisplay)),
                ),
              );
            }),
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

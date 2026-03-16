import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import '../widgets/drawer_widget.dart';
import '../widgets/paper_widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  // Profilo
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // Gemini API key
  final _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;
  bool _isSavingApiKey = false;
  bool _isSavingProfile = false;

  // AI quota
  Map<String, dynamic>? _quotaData;
  bool _isLoadingQuota = false;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<AuthService>(context, listen: false).refreshUserProfile();
      _populateFields();
      _loadQuota();
    });
  }

  void _populateFields() {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;
    _firstNameController.text = user.firstName ?? '';
    _lastNameController.text = user.lastName ?? '';
    _apiKeyController.text = user.geminiApiKey;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() => _appVersion = info.version);
    } catch (_) {
      setState(() => _appVersion = AppConstants.appVersion);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final ok = await authService.updateProfile({
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
    });
    setState(() => _isSavingProfile = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Profilo aggiornato' : 'Errore nel salvataggio del profilo'),
      backgroundColor: ok ? ThemeConstants.successColor : ThemeConstants.errorColor,
    ));
  }

  Future<void> _saveApiKey() async {
    setState(() => _isSavingApiKey = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final key = _apiKeyController.text.trim();
    final ok = await authService.updateProfile({'gemini_api_key': key});
    setState(() => _isSavingApiKey = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (key.isEmpty ? 'Chiave API rimossa' : 'Chiave API salvata')
          : 'Errore nel salvataggio della chiave API'),
      backgroundColor: ok ? ThemeConstants.successColor : ThemeConstants.errorColor,
    ));
    if (ok) _loadQuota();
  }

  Future<void> _loadQuota() async {
    setState(() => _isLoadingQuota = true);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final data = await chatService.fetchQuota();
    if (mounted) setState(() { _quotaData = data; _isLoadingQuota = false; });
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancella cache', style: ThemeConstants.subheadingStyle),
        content: Text(
          'Sei sicuro di voler cancellare tutti i dati salvati localmente? Dovrai sincronizzare nuovamente.',
          style: ThemeConstants.bodyStyle,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULLA')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ThemeConstants.errorColor),
            child: const Text('CONFERMA'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final storageService = Provider.of<StorageService>(context, listen: false);
    await storageService.clearDataCache();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Cache cancellata'),
      backgroundColor: ThemeConstants.successColor,
    ));
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Logout', style: ThemeConstants.subheadingStyle),
        content: Text('Sei sicuro di voler effettuare il logout?', style: ThemeConstants.bodyStyle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULLA')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ThemeConstants.errorColor),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni'), elevation: 4),
      drawer: AppDrawer(currentRoute: AppConstants.settingsRoute),
      body: Container(
        decoration: BoxDecoration(
          color: ThemeConstants.backgroundColor,
          image: ThemeConstants.paperBackgroundTexture,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DiaryTitle(title: 'Impostazioni'),

            // ── PROFILO ──────────────────────────────────────────────────
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profilo', style: ThemeConstants.subheadingStyle),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ThemeConstants.primaryColor.withOpacity(0.2),
                          border: Border.all(color: ThemeConstants.primaryColor, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            (user?.username.isNotEmpty == true)
                                ? user!.username[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.caveat(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: ThemeConstants.secondaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.username ?? '',
                              style: ThemeConstants.handwrittenNotes.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              user?.email ?? '',
                              style: ThemeConstants.bodyStyle.copyWith(color: ThemeConstants.textSecondaryColor, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(labelText: 'Nome', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(labelText: 'Cognome', isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DiaryButton(
                        label: 'Salva nome',
                        onPressed: _isSavingProfile ? null : _saveProfile,
                        icon: _isSavingProfile ? null : Icons.save_outlined,
                        color: ThemeConstants.primaryColor,
                      ),
                      DiaryButton(
                        label: 'Esci',
                        onPressed: _logout,
                        icon: Icons.exit_to_app,
                        color: ThemeConstants.errorColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── AI ASSISTANT ─────────────────────────────────────────────
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy_outlined, color: ThemeConstants.secondaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text('ApiarioAI — Chiave Gemini', style: ThemeConstants.subheadingStyle),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ThemeConstants.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ThemeConstants.primaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perché inserire la tua chiave?',
                          style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '• Senza chiave personale, l\'app usa la chiave di sistema condivisa, soggetta a limiti di quota giornaliera.\n'
                          '• Con la tua chiave gratuita da Google AI Studio ottieni un limite indipendente: 1 500 richieste/giorno su Gemini 2.5 Flash.\n'
                          '• La chiave rimane sul server in modo sicuro e non viene mai condivisa.',
                          style: ThemeConstants.bodyStyle.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Come ottenerla: vai su aistudio.google.com → "Get API key" → crea una chiave gratuita e incollala qui sotto.',
                          style: ThemeConstants.bodyStyle.copyWith(
                            fontSize: 12,
                            color: ThemeConstants.textSecondaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _apiKeyObscured,
                    decoration: InputDecoration(
                      labelText: 'Gemini API Key',
                      hintText: 'AIzaSy...',
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(_apiKeyObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _apiKeyObscured = !_apiKeyObscured),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      DiaryButton(
                        label: _isSavingApiKey ? 'Salvataggio...' : 'Salva chiave',
                        onPressed: _isSavingApiKey ? null : _saveApiKey,
                        icon: _isSavingApiKey ? null : Icons.key,
                        color: ThemeConstants.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      DiaryButton(
                        label: 'Rimuovi',
                        onPressed: () {
                          _apiKeyController.clear();
                          _saveApiKey();
                        },
                        icon: Icons.delete_outline,
                        color: ThemeConstants.secondaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── QUOTA AI ──────────────────────────────────────────────────
            _buildQuotaCard(),
            const SizedBox(height: 16),

            // ── INFORMAZIONI ──────────────────────────────────────────────
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informazioni', style: ThemeConstants.subheadingStyle),
                  const SizedBox(height: 16),
                  _infoRow(Icons.info_outline, 'Versione app', _appVersion),
                  _infoRow(Icons.cloud_outlined, 'Server API', ApiConstants.baseUrl),
                  _infoRow(Icons.code, 'Sviluppato da', 'Cible99'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaCard() {
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: ThemeConstants.secondaryColor, size: 20),
              const SizedBox(width: 8),
              Text('ApiarioAI — Quota giornaliera', style: ThemeConstants.subheadingStyle),
              const Spacer(),
              if (_isLoadingQuota)
                const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: ThemeConstants.secondaryColor,
                  onPressed: _loadQuota,
                  tooltip: 'Aggiorna',
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_quotaData == null && !_isLoadingQuota)
            Text('Dati non disponibili (offline o errore di rete)',
                style: ThemeConstants.bodyStyle.copyWith(
                    fontSize: 13, color: ThemeConstants.textSecondaryColor))
          else if (_quotaData != null) ...[
            _buildQuotaSection(_quotaData!),
          ],
        ],
      ),
    );
  }

  Widget _buildQuotaSection(Map<String, dynamic> data) {
    final bool personalKeySet = data['personal_key_set'] == true;
    final String activeKey = data['active_key'] ?? 'system';
    final int dailyLimit = (data['daily_limit'] ?? 1500) as int;

    final Map<String, dynamic> personal = (data['personal'] ?? {}) as Map<String, dynamic>;
    final Map<String, dynamic> system = (data['system'] ?? {}) as Map<String, dynamic>;
    final int personalUsed = (personal['requests_today'] ?? 0) as int;
    final int systemUsed = (system['requests_today'] ?? 0) as int;
    final String? personalResetAt = personal['reset_at'] as String?;
    final String? systemResetAt = system['reset_at'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active key badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (activeKey == 'personal'
                    ? ThemeConstants.successColor
                    : ThemeConstants.primaryColor)
                .withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: activeKey == 'personal'
                  ? ThemeConstants.successColor
                  : ThemeConstants.primaryColor,
              width: 1,
            ),
          ),
          child: Text(
            activeKey == 'personal'
                ? 'Usando la tua chiave personale'
                : 'Usando la chiave di sistema condivisa',
            style: ThemeConstants.bodyStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: activeKey == 'personal'
                  ? ThemeConstants.successColor
                  : ThemeConstants.secondaryColor,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // System key quota
        _quotaBar(
          label: 'Chiave di sistema (condivisa)',
          used: systemUsed,
          limit: dailyLimit,
          resetAt: systemResetAt,
          isActive: activeKey == 'system',
          color: ThemeConstants.primaryColor,
        ),
        const SizedBox(height: 14),

        // Personal key quota
        _quotaBar(
          label: personalKeySet
              ? 'Tua chiave personale'
              : 'Tua chiave personale (non impostata)',
          used: personalUsed,
          limit: dailyLimit,
          resetAt: personalResetAt,
          isActive: activeKey == 'personal',
          color: ThemeConstants.successColor,
          dimmed: !personalKeySet,
        ),
      ],
    );
  }

  Widget _quotaBar({
    required String label,
    required int used,
    required int limit,
    required String? resetAt,
    required bool isActive,
    required Color color,
    bool dimmed = false,
  }) {
    final double fraction = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
    final int remaining = (limit - used).clamp(0, limit);
    final Color barColor = fraction >= 0.9
        ? ThemeConstants.errorColor
        : fraction >= 0.7
            ? ThemeConstants.primaryColor
            : color;

    DateTime? resetTime;
    String resetLabel = 'Reset: dati non ancora disponibili';
    if (resetAt != null) {
      resetTime = DateTime.tryParse(resetAt)?.toLocal();
      if (resetTime != null) {
        final Duration diff = resetTime.difference(DateTime.now());
        if (diff.isNegative) {
          resetLabel = 'Reset imminente';
        } else if (diff.inHours >= 1) {
          resetLabel = 'Reset tra ${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
        } else {
          resetLabel = 'Reset tra ${diff.inMinutes}m';
        }
      }
    }

    return Opacity(
      opacity: dimmed ? 0.45 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isActive)
                Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              Expanded(
                child: Text(label,
                    style: ThemeConstants.bodyStyle.copyWith(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
              ),
              Text('$used / $limit',
                  style: ThemeConstants.bodyStyle.copyWith(
                      fontSize: 12, color: ThemeConstants.textSecondaryColor)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: ThemeConstants.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$remaining rimaste',
                  style: ThemeConstants.bodyStyle.copyWith(
                      fontSize: 11, color: ThemeConstants.textSecondaryColor)),
              Text(resetLabel,
                  style: ThemeConstants.bodyStyle.copyWith(
                      fontSize: 11, color: ThemeConstants.textSecondaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: ThemeConstants.secondaryColor.withOpacity(0.8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: ThemeConstants.bodyStyle.copyWith(fontSize: 13, color: ThemeConstants.textSecondaryColor)),
                Text(value, style: ThemeConstants.handwrittenNotes.copyWith(fontSize: 17)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

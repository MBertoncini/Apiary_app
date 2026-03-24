import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import '../services/ai_quota_local_tracker.dart';
import '../services/voice_settings_service.dart';
import '../widgets/drawer_widget.dart';
import '../widgets/paper_widgets.dart';
import '../widgets/skeleton_widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  // Profilo
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // Gemini API key (ApiarioAI chat + inserimento vocale)
  final _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;
  bool _isSavingApiKey = false;
  bool _isSavingProfile = false;

  // Groq API key (statistiche NL query)
  final _groqKeyController = TextEditingController();
  bool _groqKeyObscured = true;
  bool _isSavingGroqKey = false;
  final _quotaTracker = AiQuotaLocalTracker();

  // Modalità inserimento vocale
  final _voiceSettings = VoiceSettingsService();
  String _voiceMode = VoiceSettingsService.modeStt;

  // AI quota
  Map<String, dynamic>? _quotaData;
  bool _isLoadingQuota = false;
  int _voiceCallsToday = 0;
  int _statsCallsToday = 0;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    // Populate immediately from cached user, then refresh in background.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _populateFields();
      _loadQuota();
      _loadLocalQuotas();
      _voiceSettings.getMode().then((m) {
        if (mounted) setState(() => _voiceMode = m);
      });
      await Provider.of<AuthService>(context, listen: false).refreshUserProfile();
      _populateFields();
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
    _groqKeyController.dispose();
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

  Future<void> _saveGroqApiKey() async {
    setState(() => _isSavingGroqKey = true);
    await _quotaTracker.setGroqApiKey(_groqKeyController.text.trim());
    setState(() => _isSavingGroqKey = false);
    if (!mounted) return;
    final saved = _groqKeyController.text.trim().isNotEmpty;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved ? 'Chiave Groq salvata' : 'Chiave Groq rimossa'),
      backgroundColor: ThemeConstants.successColor,
    ));
  }

  Future<void> _loadLocalQuotas() async {
    final voice = await _quotaTracker.getVoiceCallsToday();
    final stats = await _quotaTracker.getStatsCallsToday();
    final groqKey = await _quotaTracker.getGroqApiKey();
    if (mounted) {
      setState(() {
        _voiceCallsToday = voice;
        _statsCallsToday = stats;
        _groqKeyController.text = groqKey;
      });
    }
  }

  Future<void> _loadQuota() async {
    setState(() => _isLoadingQuota = true);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final data = await chatService.fetchQuota();
    if (mounted) setState(() { _quotaData = data; _isLoadingQuota = false; });
  }

  Future<void> _saveVoiceMode(String mode) async {
    await _voiceSettings.setMode(mode);
    if (mounted) setState(() => _voiceMode = mode);
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
                      Text('Chiavi API IA', style: ThemeConstants.subheadingStyle),
                    ],
                  ),
                  // ── Gemini (ApiarioAI chat + Inserimento vocale) ──────────
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: const Color(0xFF4285F4), size: 16),
                      const SizedBox(width: 6),
                      Text('Gemini — ApiarioAI & Inserimento Vocale',
                          style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                          '• Senza chiave personale l\'app usa la chiave di sistema condivisa (quota condivisa).\n'
                          '• Con la tua chiave ottieni quota indipendente: 20 richieste/giorno (piano gratuito Gemini 2.5 Flash).\n'
                          '• Usata per: chat ApiarioAI + trascrizione vocale.\n'
                          '• La chiave viene salvata sul server in modo sicuro.',
                          style: ThemeConstants.bodyStyle.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ottienila su aistudio.google.com → "Get API key"',
                          style: ThemeConstants.bodyStyle.copyWith(
                            fontSize: 11, color: ThemeConstants.textSecondaryColor, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 10),
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
                        onPressed: () { _apiKeyController.clear(); _saveApiKey(); },
                        icon: Icons.delete_outline,
                        color: ThemeConstants.secondaryColor,
                      ),
                    ],
                  ),

                  // ── Groq (Statistiche NL Query) ───────────────────────────
                  const Divider(height: 28),
                  Row(
                    children: [
                      Icon(Icons.bolt, color: const Color(0xFFF55036), size: 16),
                      const SizedBox(width: 6),
                      Text('Groq — Statistiche NL Query',
                          style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF55036).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF55036).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• Usata per le query AI nelle Statistiche (domande in linguaggio naturale).\n'
                          '• Senza chiave il backend usa la chiave di sistema condivisa.\n'
                          '• Salvata localmente sul dispositivo.',
                          style: ThemeConstants.bodyStyle.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ottienila su console.groq.com → "API Keys"',
                          style: ThemeConstants.bodyStyle.copyWith(
                            fontSize: 11, color: ThemeConstants.textSecondaryColor, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _groqKeyController,
                    obscureText: _groqKeyObscured,
                    decoration: InputDecoration(
                      labelText: 'Groq API Key',
                      hintText: 'gsk_...',
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(_groqKeyObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _groqKeyObscured = !_groqKeyObscured),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      DiaryButton(
                        label: _isSavingGroqKey ? 'Salvataggio...' : 'Salva chiave',
                        onPressed: _isSavingGroqKey ? null : _saveGroqApiKey,
                        icon: _isSavingGroqKey ? null : Icons.key,
                        color: const Color(0xFFF55036),
                      ),
                      const SizedBox(width: 8),
                      DiaryButton(
                        label: 'Rimuovi',
                        onPressed: () { _groqKeyController.clear(); _saveGroqApiKey(); },
                        icon: Icons.delete_outline,
                        color: ThemeConstants.secondaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── INSERIMENTO VOCALE ────────────────────────────────────────
            _buildVoiceModeCard(),
            const SizedBox(height: 16),

            // ── QUOTA AI ──────────────────────────────────────────────────
            _buildQuotaCard(),
            const SizedBox(height: 16),

            // ── GUIDA & TUTORIAL ──────────────────────────────────────────
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Guida & Tutorial', style: ThemeConstants.subheadingStyle),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline, color: Color(0xFFD3A121)),
                    title: Text('Tutorial', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF3A2E21))),
                    subtitle: Text('Rivedi il tour introduttivo', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => Navigator.pushNamed(context, '/onboarding'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.book_outlined, color: Color(0xFFD3A121)),
                    title: Text('Guida Completa', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF3A2E21))),
                    subtitle: Text('Istruzioni dettagliate per tutte le funzioni', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => Navigator.pushNamed(context, '/guida'),
                  ),
                ],
              ),
            ),
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
                  const Divider(height: 24),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.privacy_tip_outlined,
                              color: ThemeConstants.secondaryColor.withOpacity(0.8), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Informativa sulla Privacy',
                                style: ThemeConstants.bodyStyle),
                          ),
                          Icon(Icons.chevron_right,
                              color: ThemeConstants.textSecondaryColor, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceModeCard() {
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic_outlined,
                  color: ThemeConstants.secondaryColor, size: 20),
              const SizedBox(width: 8),
              Text('Inserimento Vocale', style: ThemeConstants.subheadingStyle),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Scegli come vengono catturati i dati vocali.',
            style: ThemeConstants.bodyStyle.copyWith(
                fontSize: 12, color: ThemeConstants.textSecondaryColor),
          ),
          const SizedBox(height: 16),

          // ── STT locale ──────────────────────────────────────────────────
          _buildVoiceModeOption(
            value: VoiceSettingsService.modeStt,
            icon: Icons.text_fields,
            title: 'Speech-to-text locale',
            subtitle: 'Il riconoscimento vocale del dispositivo trascrive '
                'il testo; Gemini lo struttura in dati. '
                'Consigliato: funziona anche con connessione lenta.',
          ),
          const SizedBox(height: 10),

          // ── Audio Gemini ─────────────────────────────────────────────────
          _buildVoiceModeOption(
            value: VoiceSettingsService.modeAudio,
            icon: Icons.graphic_eq,
            iconColor: const Color(0xFF4285F4),
            title: 'Registra audio → Gemini multimodale',
            subtitle: 'L\'audio viene inviato direttamente a Gemini che '
                'trascrive e struttura in un unico passaggio. '
                'Più preciso in ambienti rumorosi. Richiede connessione.',
            badge: 'Gemini Audio',
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceModeOption({
    required String value,
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    String? badge,
  }) {
    final selected = _voiceMode == value;
    final color = iconColor ?? ThemeConstants.primaryColor;
    return GestureDetector(
      onTap: () => _saveVoiceMode(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: value,
              groupValue: _voiceMode,
              onChanged: (v) => _saveVoiceMode(v!),
              activeColor: color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(title,
                            style: ThemeConstants.bodyStyle.copyWith(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4285F4).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    const Color(0xFF4285F4).withOpacity(0.4)),
                          ),
                          child: Text(badge,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF4285F4),
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: ThemeConstants.bodyStyle.copyWith(
                          fontSize: 12,
                          color: ThemeConstants.textSecondaryColor)),
                ],
              ),
            ),
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
              Flexible(
                child: Text('Quota AI — Uso giornaliero',
                    style: ThemeConstants.subheadingStyle, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 4),
              if (_isLoadingQuota)
                const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: ThemeConstants.secondaryColor,
                  onPressed: () { _loadQuota(); _loadLocalQuotas(); },
                  tooltip: 'Aggiorna',
                ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 1. ApiarioAI chat (Gemini, tracciata lato backend) ──────────
          Row(
            children: [
              Icon(Icons.smart_toy_outlined, color: const Color(0xFF4285F4), size: 15),
              const SizedBox(width: 6),
              Text('ApiarioAI Assistant (Gemini)',
                  style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingQuota && _quotaData == null)
            const SkeletonDashboardContent(height: 110)
          else if (_quotaData == null)
            Text('Dati non disponibili (offline o errore di rete)',
                style: ThemeConstants.bodyStyle.copyWith(
                    fontSize: 13, color: ThemeConstants.textSecondaryColor))
          else
            _buildQuotaSection(_quotaData!),

          const Divider(height: 28),

          // ── 2. Inserimento vocale (Gemini, tracciato localmente) ─────────
          Row(
            children: [
              Icon(Icons.mic_outlined, color: ThemeConstants.primaryColor, size: 15),
              const SizedBox(width: 6),
              Text('Inserimento Vocale (Gemini)',
                  style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          _quotaBar(
            label: 'Trascrizioni oggi',
            used: _voiceCallsToday,
            limit: 20,
            resetAt: null,
            isActive: true,
            color: ThemeConstants.primaryColor,
            subtitle: 'Piano gratuito: 20 richieste/giorno',
          ),

          const Divider(height: 28),

          // ── 3. Statistiche NL Query (Groq, tracciato localmente) ─────────
          Row(
            children: [
              Icon(Icons.bolt, color: const Color(0xFFF55036), size: 15),
              const SizedBox(width: 6),
              Text('Statistiche NL Query (Groq)',
                  style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          _quotaBar(
            label: 'Query oggi',
            used: _statsCallsToday,
            limit: 0,
            resetAt: null,
            isActive: true,
            color: const Color(0xFFF55036),
            subtitle: _groqKeyController.text.isNotEmpty
                ? 'Usando la tua chiave Groq personale'
                : 'Usando la chiave di sistema condivisa',
          ),
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
    String? subtitle,
  }) {
    final bool hasLimit = limit > 0;
    final double fraction = hasLimit ? (used / limit).clamp(0.0, 1.0) : 0.0;
    final int remaining = hasLimit ? (limit - used).clamp(0, limit) : 0;
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
              Text(hasLimit ? '$used / $limit' : '$used oggi',
                  style: ThemeConstants.bodyStyle.copyWith(
                      fontSize: 12, color: ThemeConstants.textSecondaryColor)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: ThemeConstants.bodyStyle.copyWith(
                    fontSize: 11, color: ThemeConstants.textSecondaryColor, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hasLimit ? fraction : 0.0,
              minHeight: 10,
              backgroundColor: ThemeConstants.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(hasLimit ? barColor : color.withOpacity(0.4)),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(hasLimit ? '$remaining rimaste' : 'Reset ogni giorno',
                  style: ThemeConstants.bodyStyle.copyWith(
                      fontSize: 11, color: ThemeConstants.textSecondaryColor)),
              Text(resetAt != null ? resetLabel : 'Reset a mezzanotte',
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

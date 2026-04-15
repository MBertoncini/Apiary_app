import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/language_service.dart';
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
  bool _isUploadingPhoto = false;

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

  // Attrezzatura prompt preference
  bool _skipAttrezzaturaPrompt = false;

  // AI quota
  Map<String, dynamic>? _quotaData;
  bool _isLoadingQuota = false;
  int _voiceCallsToday = 0;
  int _statsCallsToday = 0;
  Timer? _resetTimer;

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
      Provider.of<StorageService>(context, listen: false)
          .shouldSkipAttrezzaturaPrompt()
          .then((v) {
        if (mounted) setState(() => _skipAttrezzaturaPrompt = v);
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
    _resetTimer?.cancel();
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
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    setState(() => _isSavingProfile = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final ok = await authService.updateProfile({
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
    });
    setState(() => _isSavingProfile = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? s.msgProfileUpdated : s.msgProfileSaveError),
      backgroundColor: ok ? ThemeConstants.successColor : ThemeConstants.errorColor,
    ));
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _isUploadingPhoto = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final ok = await authService.uploadProfileImage(File(picked.path));
    setState(() => _isUploadingPhoto = false);
    if (!mounted) return;
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? s.settingsPhotoUpdated : s.settingsPhotoError),
      backgroundColor: ok ? ThemeConstants.successColor : ThemeConstants.errorColor,
    ));
  }

  Future<void> _saveApiKey() async {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    setState(() => _isSavingApiKey = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final key = _apiKeyController.text.trim();
    final ok = await authService.updateProfile({'gemini_api_key': key});
    setState(() => _isSavingApiKey = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (key.isEmpty ? s.msgApiKeyRemoved : s.msgApiKeySaved)
          : s.msgApiKeySaveError),
      backgroundColor: ok ? ThemeConstants.successColor : ThemeConstants.errorColor,
    ));
    if (ok) _loadQuota();
  }

  Future<void> _saveGroqApiKey() async {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    setState(() => _isSavingGroqKey = true);
    await _quotaTracker.setGroqApiKey(_groqKeyController.text.trim());
    setState(() => _isSavingGroqKey = false);
    if (!mounted) return;
    final saved = _groqKeyController.text.trim().isNotEmpty;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved ? s.msgGroqKeySaved : s.msgGroqKeyRemoved),
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
    if (mounted) {
      setState(() { _quotaData = data; _isLoadingQuota = false; });
      if (data != null) _scheduleResetRefresh(data);
    }
  }

  /// Programma un refresh automatico al momento del prossimo reset lato backend.
  void _scheduleResetRefresh(Map<String, dynamic> data) {
    _resetTimer?.cancel();
    final resets = [
      ((data['personal'] ?? {}) as Map<String, dynamic>)['reset_at'] as String?,
      ((data['system']   ?? {}) as Map<String, dynamic>)['reset_at'] as String?,
    ].whereType<String>();

    DateTime? earliest;
    for (final r in resets) {
      final normalized = r.endsWith('Z') || r.contains('+') ? r : '${r}Z';
      final dt = DateTime.tryParse(normalized)?.toLocal();
      if (dt != null && (earliest == null || dt.isBefore(earliest))) {
        earliest = dt;
      }
    }

    if (earliest != null) {
      final delay = earliest.difference(DateTime.now());
      if (delay > Duration.zero) {
        _resetTimer = Timer(delay, _loadQuota);
      }
    }
  }

  Future<void> _saveVoiceMode(String mode) async {
    // Per la modalità premium mostra un bottom sheet informativo prima di
    // salvare. L'utente può confermare o annullare.
    if (mode == VoiceSettingsService.modeAudio &&
        _voiceMode != VoiceSettingsService.modeAudio) {
      final confirmed = await _showAudioPremiumSheet();
      if (!confirmed) return;
    }
    await _voiceSettings.setMode(mode);
    if (mounted) setState(() => _voiceMode = mode);
  }

  Future<bool> _showAudioPremiumSheet() async {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PremiumFeatureSheet(
        title: s.voiceAudioPremiumSheetTitle,
        body: s.voiceAudioPremiumSheetBody,
        activateLabel: s.voiceAudioPremiumSheetActivate,
      ),
    );
    return confirmed == true;
  }

  Future<void> _clearCache() async {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.clearCacheTitle, style: ThemeConstants.subheadingStyle),
        content: Text(s.clearCacheMessage, style: ThemeConstants.bodyStyle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.btnCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ThemeConstants.errorColor),
            child: Text(s.btnConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final storageService = Provider.of<StorageService>(context, listen: false);
    await storageService.clearDataCache();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(s.msgCacheCleared),
      backgroundColor: ThemeConstants.successColor,
    ));
  }

  Future<void> _logout() async {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.logoutConfirmTitle, style: ThemeConstants.subheadingStyle),
        content: Text(s.logoutConfirmMessage, style: ThemeConstants.bodyStyle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.btnCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ThemeConstants.errorColor),
            child: Text(s.btnLogout),
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
    final s = Provider.of<LanguageService>(context).strings;

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle), elevation: 4),
      drawer: AppDrawer(currentRoute: AppConstants.settingsRoute),
      body: Container(
        decoration: BoxDecoration(
          color: ThemeConstants.backgroundColor,
          image: ThemeConstants.paperBackgroundTexture,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── PROFILO ──────────────────────────────────────────────────
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.sectionProfile, style: ThemeConstants.subheadingStyle),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                        child: Stack(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ThemeConstants.primaryColor.withOpacity(0.2),
                                border: Border.all(color: ThemeConstants.primaryColor, width: 2),
                              ),
                              child: ClipOval(
                                child: (user?.profileImage != null)
                                    ? CachedNetworkImage(
                                        imageUrl: user!.profileImage!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        errorWidget: (_, __, ___) => Center(
                                          child: Text(
                                            (user.username.isNotEmpty) ? user.username[0].toUpperCase() : 'U',
                                            style: GoogleFonts.caveat(fontSize: 32, fontWeight: FontWeight.bold, color: ThemeConstants.secondaryColor),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          (user?.username.isNotEmpty == true) ? user!.username[0].toUpperCase() : 'U',
                                          style: GoogleFonts.caveat(fontSize: 32, fontWeight: FontWeight.bold, color: ThemeConstants.secondaryColor),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ThemeConstants.primaryColor,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: _isUploadingPhoto
                                    ? const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              ),
                            ),
                          ],
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
                          decoration: InputDecoration(labelText: s.fieldFirstName, isDense: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lastNameController,
                          decoration: InputDecoration(labelText: s.fieldLastName, isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DiaryButton(
                        label: s.btnSaveName,
                        onPressed: _isSavingProfile ? null : _saveProfile,
                        icon: _isSavingProfile ? null : Icons.save_outlined,
                        color: ThemeConstants.primaryColor,
                      ),
                      DiaryButton(
                        label: s.btnExit,
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

            // ── LINGUA ───────────────────────────────────────────────────
            _buildLanguageCard(s),
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
                      Text(s.sectionAiApiKeys, style: ThemeConstants.subheadingStyle),
                    ],
                  ),
                  // ── Gemini (ApiarioAI chat + Inserimento vocale) ──────────
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: const Color(0xFF4285F4), size: 16),
                      const SizedBox(width: 6),
                      Text(s.geminiSectionLabel,
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
                          s.geminiDescription,
                          style: ThemeConstants.bodyStyle.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.geminiHowToGet,
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
                      Flexible(
                        child: DiaryButton(
                          label: _isSavingApiKey ? s.btnSaving : s.btnSaveKey,
                          onPressed: _isSavingApiKey ? null : _saveApiKey,
                          icon: _isSavingApiKey ? null : Icons.key,
                          color: ThemeConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: DiaryButton(
                          label: s.btnRemove,
                          onPressed: () { _apiKeyController.clear(); _saveApiKey(); },
                          icon: Icons.delete_outline,
                          color: ThemeConstants.secondaryColor,
                        ),
                      ),
                    ],
                  ),

                  // ── Groq (Statistiche NL Query) ───────────────────────────
                  const Divider(height: 28),
                  Row(
                    children: [
                      Icon(Icons.bolt, color: const Color(0xFFF55036), size: 16),
                      const SizedBox(width: 6),
                      Text(s.groqSectionLabel,
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
                          s.groqDescription,
                          style: ThemeConstants.bodyStyle.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.groqHowToGet,
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
                      Flexible(
                        child: DiaryButton(
                          label: _isSavingGroqKey ? s.btnSaving : s.btnSaveKey,
                          onPressed: _isSavingGroqKey ? null : _saveGroqApiKey,
                          icon: _isSavingGroqKey ? null : Icons.key,
                          color: const Color(0xFFF55036),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: DiaryButton(
                          label: s.btnRemove,
                          onPressed: () { _groqKeyController.clear(); _saveGroqApiKey(); },
                          icon: Icons.delete_outline,
                          color: ThemeConstants.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── INSERIMENTO VOCALE ────────────────────────────────────────
            _buildVoiceModeCard(s),
            const SizedBox(height: 16),

            // ── QUOTA AI ──────────────────────────────────────────────────
            _buildQuotaCard(s),
            const SizedBox(height: 16),

            // ── ATTREZZATURA PROMPT ───────────────────────────────────────
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.sectionEquipmentPrompt, style: ThemeConstants.subheadingStyle),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(Icons.inventory_2_outlined, color: const Color(0xFFD3A121)),
                    title: Text(s.settingsAttrezzaturaPrompt, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF3A2E21))),
                    subtitle: Text(s.settingsAttrezzaturaPromptSub, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    value: !_skipAttrezzaturaPrompt,
                    onChanged: (v) async {
                      setState(() => _skipAttrezzaturaPrompt = !v);
                      await Provider.of<StorageService>(context, listen: false)
                          .saveSkipAttrezzaturaPrompt(!v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── GUIDA & TUTORIAL ──────────────────────────────────────────
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.sectionGuideTutorial, style: ThemeConstants.subheadingStyle),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline, color: Color(0xFFD3A121)),
                    title: Text(s.tutorialTitle, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF3A2E21))),
                    subtitle: Text(s.tutorialSubtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => Navigator.pushNamed(context, '/onboarding'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.book_outlined, color: Color(0xFFD3A121)),
                    title: Text(s.completeGuideTitle, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF3A2E21))),
                    subtitle: Text(s.completeGuideSubtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
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
                  Text(s.sectionInfo, style: ThemeConstants.subheadingStyle),
                  const SizedBox(height: 16),
                  _infoRow(Icons.info_outline, s.infoAppVersion, _appVersion),
                  _infoRow(Icons.cloud_outlined, s.infoApiServer, ApiConstants.baseUrl),
                  _infoRow(Icons.code, s.infoDevelopedBy, 'Cible99'),
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
                            child: Text(s.infoPrivacyPolicy, style: ThemeConstants.bodyStyle),
                          ),
                          Icon(Icons.chevron_right,
                              color: ThemeConstants.textSecondaryColor, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  // Clear cache button
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.cleaning_services_outlined,
                        color: ThemeConstants.secondaryColor.withOpacity(0.8), size: 20),
                    title: Text(s.clearCacheTitle, style: ThemeConstants.bodyStyle),
                    trailing: Icon(Icons.chevron_right,
                        color: ThemeConstants.textSecondaryColor, size: 18),
                    onTap: _clearCache,
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

  // ── Language selection card ───────────────────────────────────────────────

  Widget _buildLanguageCard(dynamic s) {
    final languageService = Provider.of<LanguageService>(context);
    final currentCode = languageService.currentCode;

    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: ThemeConstants.secondaryColor, size: 20),
              const SizedBox(width: 8),
              Text(s.sectionLanguage, style: ThemeConstants.subheadingStyle),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s.labelLanguageSubtitle,
            style: ThemeConstants.bodyStyle.copyWith(
                fontSize: 12, color: ThemeConstants.textSecondaryColor),
          ),
          const SizedBox(height: 16),
          ...LanguageService.supportedLanguages.entries.map((entry) {
            final code = entry.key;
            final name = entry.value;
            final selected = currentCode == code;
            return GestureDetector(
              onTap: () => languageService.setLanguage(code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? ThemeConstants.primaryColor.withOpacity(0.10)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? ThemeConstants.primaryColor : Colors.grey.shade300,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: code,
                      groupValue: currentCode,
                      onChanged: (v) => languageService.setLanguage(v!),
                      activeColor: ThemeConstants.primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: ThemeConstants.bodyStyle.copyWith(
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Voice mode card ───────────────────────────────────────────────────────

  Widget _buildVoiceModeCard(dynamic s) {
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic_outlined, color: ThemeConstants.secondaryColor, size: 20),
              const SizedBox(width: 8),
              Text(s.sectionVoiceInput, style: ThemeConstants.subheadingStyle),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s.voiceInputSubtitle,
            style: ThemeConstants.bodyStyle.copyWith(
                fontSize: 12, color: ThemeConstants.textSecondaryColor),
          ),
          const SizedBox(height: 16),

          // ── STT locale ──────────────────────────────────────────────────
          _buildVoiceModeOption(
            value: VoiceSettingsService.modeStt,
            icon: Icons.text_fields,
            title: s.voiceModeSttTitle,
            subtitle: s.voiceModeSttSubtitle,
          ),
          const SizedBox(height: 10),

          // ── Audio Gemini ─────────────────────────────────────────────────
          _buildVoiceModeOption(
            value: VoiceSettingsService.modeAudio,
            icon: Icons.graphic_eq,
            iconColor: const Color(0xFF4285F4),
            title: s.voiceModeAudioTitle,
            subtitle: s.voiceModeAudioSubtitle,
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
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4285F4).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF4285F4).withOpacity(0.4)),
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
                          fontSize: 12, color: ThemeConstants.textSecondaryColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quota card ────────────────────────────────────────────────────────────

  Widget _buildQuotaCard(dynamic s) {
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: ThemeConstants.secondaryColor, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(s.sectionQuota,
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
                  tooltip: s.quotaRefreshTooltip,
                ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 1. ApiarioAI chat (Gemini, tracciata lato backend) ──────────
          Row(
            children: [
              Icon(Icons.smart_toy_outlined, color: const Color(0xFF4285F4), size: 15),
              const SizedBox(width: 6),
              Text(s.quotaApiarioAIAssistant,
                  style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingQuota && _quotaData == null)
            const SkeletonDashboardContent(height: 110)
          else if (_quotaData == null)
            Text(s.quotaDataUnavailable,
                style: ThemeConstants.bodyStyle.copyWith(
                    fontSize: 13, color: ThemeConstants.textSecondaryColor))
          else
            _buildQuotaSection(_quotaData!, s),

          const Divider(height: 28),

          // ── 2. Gemini Audio premium (tracciato localmente) ───────────────
          Row(
            children: [
              Icon(Icons.mic_outlined, color: ThemeConstants.primaryColor, size: 15),
              const SizedBox(width: 6),
              Text(s.quotaVoiceInput,
                  style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          _quotaBar(
            label: s.quotaTranscriptionsToday,
            used: _voiceCallsToday,
            limit: 20,
            resetAt: null,
            isActive: true,
            color: ThemeConstants.primaryColor,
            subtitle: s.quotaFreePlan,
            s: s,
          ),

          const Divider(height: 28),

          // ── 3. Statistiche NL Query (Groq, tracciato localmente) ─────────
          Row(
            children: [
              Icon(Icons.bolt, color: const Color(0xFFF55036), size: 15),
              const SizedBox(width: 6),
              Text(s.quotaStatsNlQuery,
                  style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          _quotaBar(
            label: s.quotaStatsToday,
            used: _statsCallsToday,
            limit: 0,
            resetAt: null,
            isActive: true,
            color: const Color(0xFFF55036),
            subtitle: _groqKeyController.text.isNotEmpty
                ? s.quotaUsingGroqPersonal
                : s.quotaUsingSystemKey,
            s: s,
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaSection(Map<String, dynamic> data, dynamic s) {
    final bool personalKeySet = data['personal_key_set'] == true;
    final String activeKey = data['active_key'] ?? 'system';
    final int dailyLimit = ((data['daily_limit'] ?? 1500) as num).toInt();

    final Map<String, dynamic> personal = (data['personal'] ?? {}) as Map<String, dynamic>;
    final Map<String, dynamic> system = (data['system'] ?? {}) as Map<String, dynamic>;
    final int personalUsed = ((personal['requests_today'] ?? 0) as num).toInt();
    final int systemUsed = ((system['requests_today'] ?? 0) as num).toInt();
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
            activeKey == 'personal' ? s.quotaUsingPersonalKey : s.quotaUsingSystemKey,
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
          label: s.quotaSystemKeyLabel,
          used: systemUsed,
          limit: dailyLimit,
          resetAt: systemResetAt,
          isActive: activeKey == 'system',
          color: ThemeConstants.primaryColor,
          s: s,
        ),
        const SizedBox(height: 14),

        // Personal key quota
        _quotaBar(
          label: personalKeySet ? s.quotaPersonalKeyLabel : s.quotaPersonalKeyNotSetLabel,
          used: personalUsed,
          limit: dailyLimit,
          resetAt: personalResetAt,
          isActive: activeKey == 'personal',
          color: ThemeConstants.successColor,
          dimmed: !personalKeySet,
          s: s,
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
    required dynamic s,
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

    String resetLabel = s.quotaResetNoData;
    if (resetAt != null) {
      // Normalizza a UTC: se il backend non include 'Z' o offset, assumiamo UTC.
      final normalized = resetAt.endsWith('Z') || resetAt.contains('+')
          ? resetAt
          : '${resetAt}Z';
      final resetTime = DateTime.tryParse(normalized)?.toLocal();
      if (resetTime != null) {
        final Duration diff = resetTime.difference(DateTime.now());
        if (diff.isNegative) {
          resetLabel = s.quotaResetSoon;
        } else if (diff.inHours >= 1) {
          resetLabel = s.quotaResetInHoursMinutes(diff.inHours, diff.inMinutes.remainder(60));
        } else {
          resetLabel = s.quotaResetInMinutes(diff.inMinutes);
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
              Text(hasLimit ? '$used / $limit' : s.quotaUsedToday(used),
                  style: ThemeConstants.bodyStyle.copyWith(
                      fontSize: 12, color: ThemeConstants.textSecondaryColor)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle,
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
              Text(hasLimit ? s.quotaRemaining(remaining) : s.quotaResetDaily,
                  style: ThemeConstants.bodyStyle.copyWith(
                      fontSize: 11, color: ThemeConstants.textSecondaryColor)),
              Text(resetAt != null ? resetLabel : s.quotaResetMidnight,
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

// ── Premium feature bottom sheet ─────────────────────────────────────────────

class _PremiumFeatureSheet extends StatelessWidget {
  final String title;
  final String body;
  final String activateLabel;

  const _PremiumFeatureSheet({
    required this.title,
    required this.body,
    required this.activateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Icona + titolo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Color(0xFF4285F4), size: 22),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: ThemeConstants.subheadingStyle
                      .copyWith(fontSize: 17)),
            ],
          ),
          const SizedBox(height: 16),

          // Corpo
          Text(body,
              style: ThemeConstants.bodyStyle.copyWith(
                  fontSize: 14,
                  color: ThemeConstants.textSecondaryColor,
                  height: 1.5)),
          const SizedBox(height: 24),

          // Bottoni
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(Provider.of<LanguageService>(context, listen: false).strings.btnCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bzzz! ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFFFFD600),
                          shadows: const [
                            Shadow(
                              color: Color(0xFFE65100),
                              offset: Offset(1.5, 1.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                      Text(activateLabel),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

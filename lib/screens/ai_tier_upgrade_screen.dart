// lib/screens/ai_tier_upgrade_screen.dart
//
// Tier upgrade screen.
// - Shows Pro features and current plan info
// - "Coming soon" badge for in-app purchases (not yet available)
// - Tester code input to activate Pro (backend validates the code)
// - Admin can also set ai_tier directly from Django admin

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/theme_constants.dart';
import '../l10n/app_strings.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/language_service.dart';
import '../widgets/paper_widgets.dart';

class AiTierUpgradeScreen extends StatefulWidget {
  const AiTierUpgradeScreen({super.key});

  @override
  State<AiTierUpgradeScreen> createState() => _AiTierUpgradeScreenState();
}

class _AiTierUpgradeScreenState extends State<AiTierUpgradeScreen> {
  final _codeController = TextEditingController();
  bool _isActivating = false;
  bool _showCodeInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatService =
          Provider.of<ChatService>(context, listen: false);
      if (chatService.allTierLimits == null) chatService.fetchQuota();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context).strings;
    final user = Provider.of<AuthService>(context).currentUser;
    final currentTier = user?.aiTier ?? AiTier.free;
    final allTierLimits = Provider.of<ChatService>(context).allTierLimits;
    final isProActive = currentTier != AiTier.free;

    return Scaffold(
      appBar: AppBar(title: Text(s.aiUpgradeTitle), elevation: 4),
      body: Container(
        decoration: BoxDecoration(
          color: ThemeConstants.backgroundColor,
          image: ThemeConstants.paperBackgroundTexture,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Header ──
            _buildHeader(s, isProActive),
            const SizedBox(height: 24),

            // ── Active Pro banner ──
            if (isProActive) ...[
              _buildActiveProBanner(s, currentTier),
              const SizedBox(height: 20),
            ],

            // ── Features card ──
            _buildFeaturesCard(s),
            const SizedBox(height: 20),

            // ── Cost explanation ──
            _buildCostExplanation(s),
            const SizedBox(height: 20),

            // ── Coming soon + tester code (only for free users) ──
            if (!isProActive) ...[
              _buildComingSoonCard(s),
              const SizedBox(height: 16),
              _buildActivateCodeSection(s),
              const SizedBox(height: 20),
            ],

            // ── Tier comparison ──
            _buildTierComparison(s, currentTier, allTierLimits),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(AppStrings s, bool isProActive) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isProActive
                  ? [const Color(0xFFFFB300), const Color(0xFFFFA000)]
                  : [ThemeConstants.primaryColor, const Color(0xFFE8B930)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(
            isProActive ? Icons.workspace_premium : Icons.auto_awesome,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          s.subPaywallTitle,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ThemeConstants.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.subPaywallSubtitle,
          style: ThemeConstants.bodyStyle.copyWith(
            fontSize: 14,
            color: ThemeConstants.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Active Pro banner ─────────────────────────────────────────────────

  Widget _buildActiveProBanner(AppStrings s, AiTier tier) {
    return PaperCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ThemeConstants.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle,
                color: ThemeConstants.successColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeConstants.successColor,
                  ),
                ),
                Text(
                  s.subCurrentPlan,
                  style: ThemeConstants.bodyStyle.copyWith(
                    fontSize: 12,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Features card ─────────────────────────────────────────────────────

  Widget _buildFeaturesCard(AppStrings s) {
    final features = [
      (Icons.chat, s.subFeatureUnlimitedChat),
      (Icons.mic, s.subFeatureVoice),
      (Icons.analytics, s.subFeatureAdvancedAI),
    ];

    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apiary Pro',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ThemeConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ThemeConstants.primaryColor10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(f.$1,
                          size: 18, color: ThemeConstants.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f.$2,
                        style: ThemeConstants.bodyStyle.copyWith(fontSize: 14),
                      ),
                    ),
                    const Icon(Icons.check,
                        size: 18, color: ThemeConstants.successColor),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Cost explanation ───────────────────────────────────────────────────

  Widget _buildCostExplanation(AppStrings s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ThemeConstants.successColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeConstants.successColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_outline,
              size: 20, color: ThemeConstants.successColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.subCostExplanation,
              style: ThemeConstants.bodyStyle.copyWith(
                fontSize: 13,
                color: ThemeConstants.textSecondaryColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Coming soon card ──────────────────────────────────────────────────

  Widget _buildComingSoonCard(AppStrings s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeConstants.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeConstants.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule,
                  size: 20, color: ThemeConstants.primaryColor),
              const SizedBox(width: 8),
              Text(
                s.subComingSoon,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            s.subComingSoonDesc,
            style: ThemeConstants.bodyStyle.copyWith(
              fontSize: 13,
              color: ThemeConstants.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Activate code section ─────────────────────────────────────────────

  Widget _buildActivateCodeSection(AppStrings s) {
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tap to expand
          GestureDetector(
            onTap: () => setState(() => _showCodeInput = !_showCodeInput),
            child: Row(
              children: [
                Icon(Icons.vpn_key_outlined,
                    size: 20, color: ThemeConstants.secondaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.subActivateCode,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ThemeConstants.textPrimaryColor,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _showCodeInput ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more, size: 24),
                ),
              ],
            ),
          ),

          // Expandable code input
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                children: [
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: s.subActivateCodeHint,
                      hintStyle: ThemeConstants.bodyStyle.copyWith(
                        fontSize: 13,
                        color: ThemeConstants.textSecondaryColor,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: ThemeConstants.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: ThemeConstants.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: ThemeConstants.primaryColor, width: 2),
                      ),
                      suffixIcon: _isActivating
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.arrow_forward,
                                  color: ThemeConstants.primaryColor),
                              onPressed: _codeController.text.trim().isNotEmpty
                                  ? _activateCode
                                  : null,
                            ),
                    ),
                    onSubmitted: (_) => _activateCode(),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (!_isActivating &&
                              _codeController.text.trim().isNotEmpty)
                          ? _activateCode
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConstants.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            ThemeConstants.primaryColor30,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isActivating
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                Text(s.subActivating),
                              ],
                            )
                          : Text(
                              s.subActivateBtn,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _showCodeInput
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // ── Tier comparison ───────────────────────────────────────────────────

  Widget _buildTierComparison(
    AppStrings s,
    AiTier currentTier,
    Map<String, dynamic>? allTierLimits,
  ) {
    return Column(
      children: [
        for (final tier in AiTier.values) ...[
          _TierInfoCard(
            tier: tier,
            isCurrent: tier == currentTier,
            allTierLimits: allTierLimits,
            s: s,
          ),
        ],
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────

  Future<void> _activateCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isActivating = true);

    try {
      final chatService =
          Provider.of<ChatService>(context, listen: false);
      final result = await chatService.activateCode(code);

      if (!mounted) return;

      // Refresh user profile to pick up the new tier.
      await Provider.of<AuthService>(context, listen: false)
          .refreshUserProfile();

      if (!mounted) return;

      _codeController.clear();
      setState(() {
        _isActivating = false;
        _showCodeInput = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            result['message'] as String? ?? _s.subActivateSuccess),
        backgroundColor: ThemeConstants.successColor,
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActivating = false);

      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg.contains('404') || msg.contains('invalid')
            ? _s.subActivateInvalid
            : _s.subActivateError),
        backgroundColor: ThemeConstants.errorColor,
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TierInfoCard — compact tier display for comparison
// ─────────────────────────────────────────────────────────────────────────────

class _TierInfoCard extends StatelessWidget {
  final AiTier tier;
  final bool isCurrent;
  final Map<String, dynamic>? allTierLimits;
  final AppStrings s;

  const _TierInfoCard({
    required this.tier,
    required this.isCurrent,
    required this.allTierLimits,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final limits = tier.resolvedLimits(allTierLimits);

    Color color;
    IconData icon;
    switch (tier) {
      case AiTier.free:
        color = Colors.grey.shade600;
        icon = Icons.eco_outlined;
        break;
      case AiTier.apicoltore:
        color = ThemeConstants.primaryColor;
        icon = Icons.hive;
        break;
      case AiTier.professionale:
        color = const Color(0xFFFFB300);
        icon = Icons.workspace_premium;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? color.withValues(alpha: 0.06)
            : ThemeConstants.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent
              ? color.withValues(alpha: 0.4)
              : ThemeConstants.dividerColor,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tier.label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color:
                              ThemeConstants.successColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: ThemeConstants.successColor, width: 1),
                        ),
                        child: Text(
                          s.subCurrentPlan,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: ThemeConstants.successColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Chat: ${limits.chat}/day  ·  Voice: ${limits.voice}/day  ·  Total: ${limits.total}/day',
                  style: ThemeConstants.bodyStyle.copyWith(
                    fontSize: 11,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

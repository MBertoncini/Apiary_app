import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../whats_new/whats_new_screen.dart' show getAppBuildNumber;
import '../../l10n/app_strings.dart';
import '../../services/language_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  static const String _prefKey = 'onboarding_completato';

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    _markOnboardingSeen();
  }

  Future<void> _markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  // Colori dal design system
  static const Color primaryColor = Color(0xFFD3A121);
  static const Color bgColor = Color(0xFFF8F5E6);
  static const Color darkBrown = Color(0xFF3A2E21);
  static const Color cardBorder = Color(0xFFEAD9BF);

  List<_OnboardingStep> _buildSteps(AppStrings s) => [
    _OnboardingStep(
      icon: '🐝',
      title: s.onboardingStep1Title,
      description: s.onboardingStep1Desc,
      features: null,
    ),
    _OnboardingStep(
      icon: '📍',
      title: s.onboardingStep2Title,
      description: s.onboardingStep2Desc,
      features: null,
    ),
    _OnboardingStep(
      icon: '🏠',
      title: s.onboardingStep3Title,
      description: s.onboardingStep3Desc,
      features: null,
    ),
    _OnboardingStep(
      icon: '✨',
      title: s.onboardingStep4Title,
      description: null,
      features: [
        _Feature('🎤', s.onboardingStep4F1Title, s.onboardingStep4F1Desc),
        _Feature('🤖', s.onboardingStep4F2Title, s.onboardingStep4F2Desc),
        _Feature('📊', s.onboardingStep4F3Title, s.onboardingStep4F3Desc),
        _Feature('👥', s.onboardingStep4F4Title, s.onboardingStep4F4Desc),
      ],
    ),
    _OnboardingStep(
      icon: '🚀',
      iconWidget: Image.asset(
        'assets/images/icons/icon.png',
        width: 96,
        height: 96,
      ),
      title: s.onboardingStep5Title,
      description: s.onboardingStep5Desc,
      features: null,
      isFinal: true,
    ),
  ];

  Future<void> _completeOnboarding({bool goToCreate = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    // Segna il build corrente come già visto, così what's new non appare dopo onboarding
    final currentBuild = await getAppBuildNumber();
    await prefs.setInt('last_seen_build_number', currentBuild);
    if (!mounted) return;
    if (goToCreate) {
      Navigator.pushReplacementNamed(context, '/apiario/create');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    final steps = _buildSteps(s);
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _completeOnboarding(),
                    child: Text(
                      s.onboardingSkip,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  return _buildStep(steps[index], s);
                },
              ),
            ),

            // Dots indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (i) => _buildDot(i)),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevPage,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(s.onboardingBack, style: GoogleFonts.poppins(color: darkBrown)),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  if (_currentPage < _totalPages - 1)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(s.onboardingNext, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(_OnboardingStep step, AppStrings s) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
          if (step.iconWidget != null) step.iconWidget! else Text(step.icon, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.caveat(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: darkBrown,
            ),
          ),
          const SizedBox(height: 16),
          if (step.description != null)
            Text(
              step.description!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF5A4030),
                height: 1.7,
              ),
            ),
          if (step.features != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: step.features!.asMap().entries.map((entry) {
                  final i = entry.key;
                  final f = entry.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.icon, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: darkBrown)),
                                  Text(f.description, style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF7A6050), height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < step.features!.length - 1)
                        Divider(height: 1, color: cardBorder),
                    ],
                  );
                }).toList(),
              ),
            ),
          // Final step CTAs
          if (step.isFinal) ...[
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _completeOnboarding(goToCreate: true),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(s.onboardingBtnCreate, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _completeOnboarding(),
              child: Text(
                s.onboardingBtnExplore,
                style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14),
              ),
            ),
          ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? primaryColor : cardBorder,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingStep {
  final String icon;
  final Widget? iconWidget;
  final String title;
  final String? description;
  final List<_Feature>? features;
  final bool isFinal;

  const _OnboardingStep({
    required this.icon,
    this.iconWidget,
    required this.title,
    this.description,
    this.features,
    this.isFinal = false,
  });
}

class _Feature {
  final String icon;
  final String title;
  final String description;

  const _Feature(this.icon, this.title, this.description);
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../services/language_service.dart';

class GuidaScreen extends StatefulWidget {
  const GuidaScreen({super.key});

  @override
  State<GuidaScreen> createState() => _GuidaScreenState();
}

class _GuidaScreenState extends State<GuidaScreen> {
  int? _expandedIndex;

  static const Color primaryColor = Color(0xFFD3A121);
  static const Color bgColor = Color(0xFFF8F5E6);
  static const Color darkBrown = Color(0xFF3A2E21);
  static const Color cardBorder = Color(0xFFEAD9BF);

  List<_GuidaSection> _buildSections(AppStrings s) => [
    _GuidaSection(icon: '🌱', title: s.guidaSection1Title, items: s.guidaSection1Items),
    _GuidaSection(icon: '🏠', title: s.guidaSection2Title, items: s.guidaSection2Items),
    _GuidaSection(icon: '👑', title: s.guidaSection3Title, items: s.guidaSection3Items),
    _GuidaSection(icon: '🍯', title: s.guidaSection4Title, items: s.guidaSection4Items),
    _GuidaSection(icon: '🤖', title: s.guidaSection5Title, items: s.guidaSection5Items),
    _GuidaSection(icon: '👥', title: s.guidaSection6Title, items: s.guidaSection6Items),
    _GuidaSection(icon: '📤', title: s.guidaSection7Title, items: s.guidaSection7Items),
  ];

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context).strings;
    final sections = _buildSections(s);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          s.guidaTitle,
          style: GoogleFonts.caveat(fontSize: 26, fontWeight: FontWeight.bold, color: darkBrown),
        ),
        iconTheme: const IconThemeData(color: darkBrown),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.guidaSubtitle,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ...sections.asMap().entries.map((entry) {
            final i = entry.key;
            final section = entry.value;
            final isExpanded = _expandedIndex == i;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
                    title: Text(
                      '${section.icon}  ${section.title}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5, color: darkBrown),
                    ),
                    trailing: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: primaryColor,
                    ),
                  ),
                  if (isExpanded) ...[
                    Divider(height: 1, color: cardBorder),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _GuidaContent(items: section.items),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding'),
              icon: const Icon(Icons.play_circle_outline, color: Color(0xFFD3A121)),
              label: Text(s.guidaBtnReview, style: GoogleFonts.poppins(color: const Color(0xFFD3A121))),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _GuidaSection {
  final String icon;
  final String title;
  final List<String> items;
  const _GuidaSection({required this.icon, required this.title, required this.items});
}

class _GuidaContent extends StatelessWidget {
  final List<String> items;
  const _GuidaContent({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((text) {
        final isNote = text.startsWith('💡');
        if (isNote) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD3A121)),
            ),
            child: Text(text, style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF5A4030))),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 7, right: 10),
                width: 6, height: 6,
                decoration: const BoxDecoration(color: Color(0xFFD3A121), shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(text, style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF3A2E21), height: 1.6)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

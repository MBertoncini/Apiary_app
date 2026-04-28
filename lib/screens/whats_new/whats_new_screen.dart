import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings.dart';
import '../../services/language_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG - aggiorna questa mappa prima di ogni release
// Chiave: build number (il numero dopo '+' in pubspec.yaml, es. 1.0.1+8 → 8)
// ─────────────────────────────────────────────────────────────────────────────
const Map<int, _ReleaseNotes> _changelog = {
  9: _ReleaseNotes(
    version: '1.0.1',
    buildNumber: 10,
    date: '27 Aprile 2026',
    notes: [
      _Note('🎙️', 'Nuovo', 'Audio multimodale - registrazione migliorata con gestione batch e code offline per i comandi vocali'),
      _Note('🔑', 'Nuovo', 'Personal Key - i tester e gli utenti esperti possono ora configurare la propria chiave API Gemini nelle impostazioni'),
      _Note('🍯', 'Miglioramento', 'Database Melari - upgrade v7 con nuovi campi per peso stimato, escludi-regina e stato dei favi'),
      _Note('📈', 'Miglioramento', 'Dashboard Statistiche - aggiunto widget "Andamento Covata" e ottimizzazione della cache per caricamenti più rapidi'),
    ],
  ),
  8: _ReleaseNotes(
    version: '1.0.1',
    buildNumber: 8,
    date: 'Aprile 2026',
    notes: [
      _Note('🗺️', 'Nuovo', 'Nomadismo - pianifica gli spostamenti dell\'apiario con mappa interattiva e suggerimenti fioriture'),
      _Note('🌿', 'Nuovo', 'Mappa vegetazione OSM - visualizza le fioriture selvatiche attorno ai tuoi apiari'),
      _Note('🎤', 'Miglioramento', 'Comandi vocali più precisi con migliore gestione del contesto arnia'),
      _Note('⚡', 'Miglioramento', 'Schermata di dettaglio apiario più veloce con caricamento scheletro'),
      _Note('🔧', 'Fix', 'Risolto problema di sincronizzazione controlli dopo aggiornamento offline'),
    ],
  ),
  // ── Template per release future ────────────────────────────────────────────
  // 9: _ReleaseNotes(
  //   version: '1.0.1',
  //   buildNumber: 11,
  //   date: 'Maggio 2026',
  //   notes: [
  //     _Note('✨', 'Nuovo', 'Descrizione funzionalità'),
  //     _Note('🔧', 'Fix', 'Descrizione correzione'),
  //   ],
  // ),
};

const String _prefKeyLastSeenBuild = 'last_seen_build_number';

// ─────────────────────────────────────────────────────────────────────────────

class WhatsNewScreen extends StatefulWidget {
  /// Build number fino al quale mostrare le note (inclusivo).
  final int currentBuild;

  /// Ultimo build che l'utente ha già visto (escluso dalla visualizzazione).
  final int lastSeenBuild;

  const WhatsNewScreen({
    super.key,
    required this.currentBuild,
    required this.lastSeenBuild,
  });

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen> {
  static const Color _primaryColor = Color(0xFFD3A121);
  static const Color _bgColor = Color(0xFFF8F5E6);
  static const Color _darkBrown = Color(0xFF3A2E21);
  static const Color _cardBorder = Color(0xFFEAD9BF);
  static const Color _textBody = Color(0xFF5A4030);

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  /// Raccoglie tutte le release da mostrare (build > lastSeen && <= current),
  /// ordinate dalla più recente alla più vecchia.
  List<_ReleaseNotes> get _releasesToShow {
    return _changelog.entries
        .where((e) => e.key > widget.lastSeenBuild && e.key <= widget.currentBuild)
        .map((e) => e.value)
        .toList()
      ..sort((a, b) => b.buildNumber.compareTo(a.buildNumber));
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyLastSeenBuild, widget.currentBuild);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final releases = _releasesToShow;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: releases.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: releases.length,
                      itemBuilder: (_, i) => _buildReleaseCard(releases[i], isFirst: i == 0),
                    ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _s.whatsNewBadge,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _s.whatsNewTitle,
            style: GoogleFonts.caveat(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: _darkBrown,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _s.whatsNewSubtitle,
            style: GoogleFonts.poppins(fontSize: 13, color: _textBody),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseCard(_ReleaseNotes release, {required bool isFirst}) {
    return Container(
      margin: EdgeInsets.only(top: isFirst ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Release header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(
                  'v${release.version}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _darkBrown,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '· ${release.date}',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _cardBorder),
          // Notes
          ...release.notes.asMap().entries.map((entry) {
            final i = entry.key;
            final note = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildCategoryBadge(note.category),
                                const SizedBox(width: 6),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              note.text,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _textBody,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < release.notes.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16, color: _cardBorder),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    final Color color;
    switch (category) {
      case 'Nuovo':
        color = const Color(0xFF2E7D32);
        break;
      case 'Miglioramento':
        color = const Color(0xFF1565C0);
        break;
      case 'Fix':
        color = const Color(0xFFC62828);
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _s.whatsNewCatLabel(category),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        _s.whatsNewEmpty,
        style: GoogleFonts.poppins(color: Colors.grey),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _cardBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _dismiss,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text(
            _s.whatsNewBtnExplore,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelli dati interni
// ─────────────────────────────────────────────────────────────────────────────

class _ReleaseNotes {
  final String version;
  final int buildNumber;
  final String date;
  final List<_Note> notes;

  const _ReleaseNotes({
    required this.version,
    required this.buildNumber,
    required this.date,
    required this.notes,
  });
}

class _Note {
  final String icon;
  final String category; // 'Nuovo' | 'Miglioramento' | 'Fix'
  final String text;

  const _Note(this.icon, this.category, this.text);
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper statico usato dallo splash screen
// ─────────────────────────────────────────────────────────────────────────────

/// Restituisce il build number corrente dell'app (il numero dopo '+').
Future<int> getAppBuildNumber() async {
  final info = await PackageInfo.fromPlatform();
  return int.tryParse(info.buildNumber) ?? 0;
}

/// Restituisce l'ultimo build number già visto dall'utente (0 se mai aperto).
Future<int> getLastSeenBuildNumber() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_prefKeyLastSeenBuild) ?? 0;
}

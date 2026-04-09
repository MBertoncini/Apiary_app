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

  final List<_GuidaSection> _sections = [
    _GuidaSection(
      icon: '🌱',
      title: 'Primi Passi — Creare il primo apiario',
      content: _buildPrimiPassi(),
    ),
    _GuidaSection(
      icon: '🏠',
      title: 'Arnie & Controlli — Registrare un\'ispezione',
      content: _buildArnieControlli(),
    ),
    _GuidaSection(
      icon: '👑',
      title: 'Regine — Gestire e tracciare le regine',
      content: _buildRegine(),
    ),
    _GuidaSection(
      icon: '🍯',
      title: 'Melari & Raccolti — Dal melario alla cantina',
      content: _buildMelari(),
    ),
    _GuidaSection(
      icon: '🤖',
      title: 'Funzioni AI — Chat, voce, analisi telaino',
      content: _buildAI(),
    ),
    _GuidaSection(
      icon: '👥',
      title: 'Collaborazione — Condividere con altri apicoltori',
      content: _buildCollaborazione(),
    ),
    _GuidaSection(
      icon: '📤',
      title: 'Esportazioni — PDF e CSV',
      content: _buildEsportazioni(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = Provider.of<LanguageService>(context, listen: false).strings;
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
          ..._sections.asMap().entries.map((entry) {
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
                      child: section.content,
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
              label: Text(s.guidaBtnReview, style: GoogleFonts.poppins(color: Color(0xFFD3A121))),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static Widget _buildPrimiPassi() {
    return _GuidaContent(items: [
      _GuidaItem(text: 'Tocca il menu e vai su Apiari → Nuovo Apiario'),
      _GuidaItem(text: 'Inserisci nome, posizione sulla mappa e tipo di apiario'),
      _GuidaItem(text: 'Salva — il tuo apiario è pronto'),
      _GuidaItem(text: 'Dall\'interno dell\'apiario, tocca + per aggiungere le arnie'),
      _GuidaItem(isNote: true, text: '💡 Dai nomi descrittivi alle arnie (es: "Arnia 1 — Ligustica") per ritrovarle facilmente.'),
    ]);
  }

  static Widget _buildArnieControlli() {
    return _GuidaContent(items: [
      _GuidaItem(text: 'Entra nell\'arnia che vuoi controllare'),
      _GuidaItem(text: 'Tocca Nuovo Controllo'),
      _GuidaItem(text: 'Compila: data, forza colonia (1–10), presenza regina, stato sanitario'),
      _GuidaItem(text: 'Aggiungi note libere per osservazioni specifiche'),
      _GuidaItem(isNote: true, text: '💡 Forza colonia: 1 = debolissima, 5 = media, 10 = fortissima che occupa tutti i favi.'),
    ]);
  }

  static Widget _buildRegine() {
    return _GuidaContent(items: [
      _GuidaItem(text: 'Ogni arnia può avere una regina associata — aggiungila dalla scheda dell\'arnia'),
      _GuidaItem(text: 'Registra: data nascita, razza, colore marcatura, origine'),
      _GuidaItem(text: 'Visualizza l\'albero genealogico per tracciare discendenze'),
      _GuidaItem(text: 'Usa Confronta Regine per valutare le prestazioni'),
      _GuidaItem(isNote: true, text: '💡 Colori internazionali: Bianco (1/6), Giallo (2/7), Rosso (3/8), Verde (4/9), Blu (5/0).'),
    ]);
  }

  static Widget _buildMelari() {
    return _GuidaContent(items: [
      _GuidaItem(text: 'Aggiungi un melario all\'arnia quando è il momento della raccolta'),
      _GuidaItem(text: 'Quando è pronto, registra la smielatura: data, peso grezzo, qualità'),
      _GuidaItem(text: 'Il miele estratto va in Cantina: maturatori e contenitori di stoccaggio'),
      _GuidaItem(text: 'Dall\'invasettamento, traccia i vasetti prodotti e il peso finale'),
    ]);
  }

  static Widget _buildAI() {
    return _GuidaContent(items: [
      _GuidaItem(text: '🗨️ Chat AI — Tocca il widget chat per fare domande all\'assistente Gemini'),
      _GuidaItem(text: '🎤 Controllo Vocale — Parla e l\'app trascrive automaticamente l\'ispezione'),
      _GuidaItem(text: '📷 Analisi Telaino — Carica una foto del telaio per rilevare api, covata e celle reali'),
      _GuidaItem(isNote: true, text: '💡 Per l\'analisi telaino usa luce naturale diffusa e tieni il telaio parallelo alla fotocamera.'),
    ]);
  }

  static Widget _buildCollaborazione() {
    return _GuidaContent(items: [
      _GuidaItem(text: 'Vai su Gruppi dal menu principale'),
      _GuidaItem(text: 'Crea un gruppo e invita altri apicoltori via email o link'),
      _GuidaItem(text: 'Assegna ruoli: Proprietario, Collaboratore, Visualizzatore'),
      _GuidaItem(text: 'Condividi uno o più apiari con il gruppo dall\'interno dell\'apiario'),
    ]);
  }

  static Widget _buildEsportazioni() {
    return _GuidaContent(items: [
      _GuidaItem(text: 'Ispezioni PDF: dall\'interno di un apiario → Esporta PDF'),
      _GuidaItem(text: 'Trattamenti CSV: da Gestione → Trattamenti → Esporta CSV'),
      _GuidaItem(text: 'Vendite CSV: da Gestione → Vendite → Esporta CSV'),
      _GuidaItem(isNote: true, text: '💡 I CSV sono compatibili con Excel e Google Sheets per tracciabilità e contabilità.'),
    ]);
  }
}

class _GuidaSection {
  final String icon;
  final String title;
  final Widget content;
  const _GuidaSection({required this.icon, required this.title, required this.content});
}

class _GuidaItem {
  final String text;
  final bool isNote;
  const _GuidaItem({required this.text, this.isNote = false});
}

class _GuidaContent extends StatelessWidget {
  final List<_GuidaItem> items;
  const _GuidaContent({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        if (item.isNote) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD3A121)),
            ),
            child: Text(item.text, style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF5A4030))),
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
                child: Text(item.text, style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF3A2E21), height: 1.6)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

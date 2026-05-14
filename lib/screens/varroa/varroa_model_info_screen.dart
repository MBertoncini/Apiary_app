import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/theme_constants.dart';
import '../../l10n/app_strings.dart';
import '../../services/language_service.dart';

class VarroaModelInfoScreen extends StatefulWidget {
  const VarroaModelInfoScreen({Key? key}) : super(key: key);

  @override
  State<VarroaModelInfoScreen> createState() => _VarroaModelInfoScreenState();
}

class _VarroaModelInfoScreenState extends State<VarroaModelInfoScreen> {
  static const _recipientEmail = 'michele.bertoncini@gmail.com';

  final _formKey  = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _mailCtrl = TextEditingController();
  final _msgCtrl  = TextEditingController();
  bool _isSending = false;

  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _mailCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isSending = true);

    final nome    = _nomeCtrl.text.trim();
    final mailMit = _mailCtrl.text.trim();
    final msg     = _msgCtrl.text.trim();

    final subject = Uri.encodeComponent('[Apiary Varroa Model] da $nome');
    final body = Uri.encodeComponent(
      'Nome: $nome\n'
      '${mailMit.isNotEmpty ? 'Reply-to: $mailMit\n' : ''}'
      '\n$msg',
    );
    final uri = Uri.parse(
        'mailto:$_recipientEmail?subject=$subject&body=$body');

    setState(() => _isSending = false);

    if (await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.donazioneTxOk),
          backgroundColor: ThemeConstants.successColor,
        ),
      );
      _nomeCtrl.clear();
      _mailCtrl.clear();
      _msgCtrl.clear();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.donazioneErrEmail(_recipientEmail)),
          backgroundColor: ThemeConstants.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeConstants.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          s.varroaModelInfoTitle,
          style: const TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIntroCard(s),
            const SizedBox(height: 12),
            _buildMethodsCard(s),
            const SizedBox(height: 12),
            _buildProjectionCard(s),
            const SizedBox(height: 12),
            _buildThresholdsCard(s),
            const SizedBox(height: 12),
            _buildIntegrationsCard(s),
            const SizedBox(height: 20),
            _buildFeedbackCard(s),
          ],
        ),
      ),
    );
  }

  // ── Intro ──────────────────────────────────────────────────────────────────

  Widget _buildIntroCard(AppStrings s) {
    return Card(
      color: ThemeConstants.primaryColor.withOpacity(0.06),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
            color: ThemeConstants.primaryColor.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.science_outlined,
                color: ThemeConstants.primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.varroaModelInfoIntro,
                style: const TextStyle(fontSize: 13, height: 1.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Methods ────────────────────────────────────────────────────────────────

  Widget _buildMethodsCard(AppStrings s) {
    return _SectionCard(
      icon: Icons.biotech_outlined,
      title: s.varroaModelSectionMetodi,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MethodBlock(
            color: Colors.blue.shade700,
            badge: 'LAV',
            title: s.varroaModelLavaggioTitle,
            confidence: '95%',
            desc: s.varroaModelLavaggioDesc,
            formulaLines: const ['% = (V / n) × 100'],
            formulaNote: s.varroaModelLavaggioNote,
          ),
          const SizedBox(height: 12),
          _MethodBlock(
            color: Colors.brown.shade500,
            badge: 'SUG',
            title: s.varroaModelSugarTitle,
            confidence: '75%',
            desc: s.varroaModelSugarDesc,
            formulaLines: const [
              '%₀ = (V / n) × 100',
              '% = %₀ × 1.54',
            ],
            formulaNote: s.varroaModelSugarNote,
          ),
          const SizedBox(height: 12),
          _MethodBlock(
            color: Colors.green.shade700,
            badge: 'CAD',
            title: s.varroaModelCadutaTitle,
            confidence: '~50%',
            desc: s.varroaModelCadutaDesc,
            formulaLines: const ['% ≈ (caduta_gg / K) × 100'],
            formulaNote: s.varroaModelCadutaNote,
          ),
        ],
      ),
    );
  }

  // ── Projection ─────────────────────────────────────────────────────────────

  Widget _buildProjectionCard(AppStrings s) {
    return _SectionCard(
      icon: Icons.trending_up,
      title: s.varroaModelSectionProiezione,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.varroaModelProiezioneDesc,
              style: const TextStyle(fontSize: 13, height: 1.55)),
          const SizedBox(height: 12),
          _FormulaBox(lines: [
            'r = ln(P₁ / P₀) / Δt   ${s.varroaModelProiezioneFormulaR}',
            'P(t) = Pₗ × e^(r·t)   ${s.varroaModelProiezioneFormulaP}',
          ]),
          const SizedBox(height: 6),
          Text(
            s.varroaModelProiezioneNote,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ── Thresholds ─────────────────────────────────────────────────────────────

  Widget _buildThresholdsCard(AppStrings s) {
    return _SectionCard(
      icon: Icons.warning_amber_outlined,
      title: s.varroaModelSectionSoglie,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.varroaModelSoglieDesc,
              style: const TextStyle(fontSize: 13, height: 1.55)),
          const SizedBox(height: 12),
          _ThresholdTable(
            colPeriodo: s.varroaModelSoglieColPeriodo,
            colGialla:  s.varroaModelSoglieColGialla,
            colRossa:   s.varroaModelSoglieColRossa,
            rows: [
              _ThresholdRow(
                  label: s.varroaModelSoglieRigaPrimavera,
                  gialla: '2.0 %',
                  rossa: '3.0 %'),
              _ThresholdRow(
                  label: s.varroaModelSoglieRigaAutunno,
                  gialla: '1.5 %',
                  rossa: '2.5 %'),
              _ThresholdRow(
                  label: s.varroaModelSoglieRigaInverno,
                  gialla: '1.0 %',
                  rossa: '2.0 %'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Integrations ───────────────────────────────────────────────────────────

  Widget _buildIntegrationsCard(AppStrings s) {
    return _SectionCard(
      icon: Icons.link,
      title: s.varroaModelSectionIntegrazioni,
      child: Column(
        children: [
          _IntegrationItem(
            icon: Icons.grid_view_outlined,
            color: Colors.teal.shade600,
            text: s.varroaModelIntTelaini,
          ),
          const SizedBox(height: 10),
          _IntegrationItem(
            icon: Icons.medical_services_outlined,
            color: Colors.green.shade700,
            text: s.varroaModelIntTrattamenti,
          ),
          const SizedBox(height: 10),
          _IntegrationItem(
            icon: Icons.smart_toy_outlined,
            color: Colors.indigo.shade500,
            text: s.varroaModelIntAI,
          ),
        ],
      ),
    );
  }

  // ── Feedback form ──────────────────────────────────────────────────────────

  Widget _buildFeedbackCard(AppStrings s) {
    return Card(
      color: const Color(0xFFFFFDF5),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.mark_email_unread_outlined,
                    color: ThemeConstants.primaryColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.varroaModelFeedbackTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ThemeConstants.textPrimaryColor,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              s.varroaModelFeedbackSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: ThemeConstants.textPrimaryColor.withOpacity(0.65),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeCtrl,
                    decoration: InputDecoration(
                      labelText: s.donazioneLblNome,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? s.donazioneErrNome : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mailCtrl,
                    decoration: InputDecoration(
                      labelText: s.donazioneLblEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final re = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      return re.hasMatch(v.trim())
                          ? null
                          : s.donazioneErrEmailInvalid;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      labelText: s.donazioneLblMsg,
                      hintText: s.varroaModelFeedbackMsgHint,
                      prefixIcon: const Icon(Icons.article_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                    maxLength: 3000,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? s.donazioneErrMsg : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendFeedback,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_outlined),
                      label: Text(
                          _isSending ? s.donazioneBtnInvio : s.donazioneBtnInvia),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
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
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFFDF5),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: ThemeConstants.secondaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: ThemeConstants.secondaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _MethodBlock extends StatelessWidget {
  final Color color;
  final String badge;
  final String title;
  final String confidence;
  final String desc;
  final List<String> formulaLines;
  final String formulaNote;

  const _MethodBlock({
    required this.color,
    required this.badge,
    required this.title,
    required this.confidence,
    required this.desc,
    required this.formulaLines,
    required this.formulaNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(badge,
                    style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('conf. $confidence',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 12, height: 1.5)),
          const SizedBox(height: 8),
          _FormulaBox(lines: formulaLines),
          const SizedBox(height: 4),
          Text(formulaNote,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _FormulaBox extends StatelessWidget {
  final List<String> lines;

  const _FormulaBox({required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((l) => Text(l,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 0.2)))
            .toList(),
      ),
    );
  }
}

class _ThresholdRow {
  final String label;
  final String gialla;
  final String rossa;

  const _ThresholdRow(
      {required this.label, required this.gialla, required this.rossa});
}

class _ThresholdTable extends StatelessWidget {
  final String colPeriodo;
  final String colGialla;
  final String colRossa;
  final List<_ThresholdRow> rows;

  const _ThresholdTable({
    required this.colPeriodo,
    required this.colGialla,
    required this.colRossa,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade200),
        columnWidths: const {
          0: FlexColumnWidth(5),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(3),
        },
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            children: [
              _headerCell(colPeriodo),
              _headerCell(colGialla),
              _headerCell(colRossa),
            ],
          ),
          // Data rows
          ...rows.asMap().entries.map((e) {
            final row = e.value;
            final bg = e.key.isEven ? Colors.white : Colors.grey.shade50;
            return TableRow(
              decoration: BoxDecoration(color: bg),
              children: [
                _dataCell(row.label, Colors.black87, align: TextAlign.start),
                _dataCell(row.gialla, Colors.amber.shade700),
                _dataCell(row.rossa, ThemeConstants.errorColor),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _headerCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 11)),
      );

  Widget _dataCell(String text, Color color,
          {TextAlign align = TextAlign.center}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Text(text,
            textAlign: align,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color)),
      );
}

class _IntegrationItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _IntegrationItem(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 12, height: 1.5)),
        ),
      ],
    );
  }
}

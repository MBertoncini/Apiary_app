import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/theme_constants.dart';
import '../../l10n/app_strings.dart';
import '../../models/varroa_checkpoint.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../../services/varroa_service.dart';

class VarroaFormScreen extends StatefulWidget {
  final int coloniaId;
  final String coloniaName;
  final VarroaCheckpoint? checkpoint;
  final double? initialTelainiCovata;

  const VarroaFormScreen({
    Key? key,
    required this.coloniaId,
    required this.coloniaName,
    this.checkpoint,
    this.initialTelainiCovata,
  }) : super(key: key);

  @override
  State<VarroaFormScreen> createState() => _VarroaFormScreenState();
}

class _VarroaFormScreenState extends State<VarroaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _displayFormat = DateFormat('d MMM yyyy');

  // Form state
  DateTime _data = DateTime.now();
  String _metodo = 'lavaggio_alcolico';
  final _apiController  = TextEditingController(text: '300');
  final _acariController = TextEditingController();
  final _giorniController = TextEditingController(text: '7');
  final _noteController   = TextEditingController();
  double _telainiCovata = 5.0;

  bool _isSaving = false;
  String? _errorMessage;

  // Computed preview
  double? _percentualePreview;
  double? _cadutaPreview;

  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  bool get _isEdit => widget.checkpoint != null;

  @override
  void initState() {
    super.initState();
    if (widget.checkpoint != null) {
      final cp = widget.checkpoint!;
      _data   = DateTime.parse(cp.dataCampionamento);
      _metodo = cp.metodo;
      _apiController.text    = cp.apiCampionate?.toString() ?? '300';
      _acariController.text  = cp.acariContati.toString();
      _giorniController.text = cp.giorniMisurazione?.toString() ?? '7';
      _noteController.text   = cp.note ?? '';
      _telainiCovata = cp.telainiCovata ?? 5.0;
    } else {
      _telainiCovata = widget.initialTelainiCovata ?? 5.0;
    }
    _apiController.addListener(_updatePreview);
    _acariController.addListener(_updatePreview);
    _giorniController.addListener(_updatePreview);
    _updatePreview();
  }

  @override
  void dispose() {
    _apiController.dispose();
    _acariController.dispose();
    _giorniController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    setState(() {
      _percentualePreview = null;
      _cadutaPreview = null;
      final acari = int.tryParse(_acariController.text.trim()) ?? 0;
      if (_metodo == 'lavaggio_alcolico') {
        final api = int.tryParse(_apiController.text.trim()) ?? 0;
        if (api > 0) _percentualePreview = (acari / api) * 100;
      } else if (_metodo == 'sugar_shake') {
        final api = int.tryParse(_apiController.text.trim()) ?? 0;
        if (api > 0) _percentualePreview = (acari / api) * 100 / 0.65;
      } else if (_metodo == 'caduta_naturale') {
        final giorni = int.tryParse(_giorniController.text.trim()) ?? 0;
        if (giorni > 0) {
          _cadutaPreview       = acari / giorni;
          _percentualePreview  = _cadutaPreview! / 10.0;
        }
      }
    });
  }

  String _rischioLivello(double pct) {
    final month = _data.month;
    double soglia;
    if ([3,4,5,6,7,8].contains(month))      soglia = 3.0;
    else if ([9,10].contains(month))         soglia = 2.5;
    else                                     soglia = 2.0;
    if (pct >= soglia)       return 'rosso';
    if (pct >= soglia - 1.0) return 'giallo';
    if (pct >= (soglia-1.0)*0.7) return 'arancione';
    return 'verde';
  }

  Color _rischioColor(String livello) {
    switch (livello) {
      case 'rosso':    return ThemeConstants.errorColor;
      case 'giallo':   return Colors.amber.shade700;
      case 'arancione':return Colors.orange;
      default:         return ThemeConstants.successColor;
    }
  }

  String _rischioLabel(String livello) {
    switch (livello) {
      case 'rosso':    return _s.varroaRischioRosso;
      case 'giallo':   return _s.varroaRischioGiallo;
      case 'arancione':return _s.varroaRischioArancione;
      default:         return _s.varroaRischioVerde;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2018),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: ThemeConstants.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() { _data = picked; });
      _updatePreview();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSaving = true; _errorMessage = null; });

    final payload = <String, dynamic>{
      'colonia':            widget.coloniaId,
      'data_campionamento': _dateFormat.format(_data),
      'metodo':             _metodo,
      'acari_contati':      int.parse(_acariController.text.trim()),
      'telaini_covata':     _telainiCovata,
      if (_noteController.text.trim().isNotEmpty) 'note': _noteController.text.trim(),
    };
    if (_metodo == 'lavaggio_alcolico' || _metodo == 'sugar_shake') {
      payload['api_campionate'] = int.parse(_apiController.text.trim());
    } else if (_metodo == 'caduta_naturale') {
      payload['giorni_misurazione'] = int.parse(_giorniController.text.trim());
    }

    try {
      final service = VarroaService(Provider.of<ApiService>(context, listen: false));
      if (_isEdit) {
        await service.updateCheckpoint(widget.checkpoint!.id, payload);
      } else {
        await service.createCheckpoint(payload);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isSaving    = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeConstants.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          _isEdit ? _s.varroaFormTitleEdit : _s.varroaFormTitleNew,
          style: const TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.bold),
        ),
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDateCard(),
            const SizedBox(height: 12),
            _buildMethodCard(),
            const SizedBox(height: 12),
            _buildMeasurementCard(),
            const SizedBox(height: 12),
            _buildBroodCard(),
            const SizedBox(height: 12),
            _buildNoteCard(),
            const SizedBox(height: 12),
            if (_percentualePreview != null) _buildPreviewCard(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              _buildErrorCard(),
            ],
            const SizedBox(height: 24),
            _buildSaveButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Date card ──────────────────────────────────────────────────────────────

  Widget _buildDateCard() {
    return _card(
      _s.varroaFormSectionData,
      Icons.calendar_today,
      InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: _s.varroaFormLblData,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.edit_calendar_outlined),
          ),
          child: Text(
            _displayFormat.format(_data),
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ),
    );
  }

  // ── Method card ────────────────────────────────────────────────────────────

  Widget _buildMethodCard() {
    return _card(
      _s.varroaFormSectionMetodo,
      Icons.science_outlined,
      Column(
        children: [
          _methodChip('lavaggio_alcolico', _s.varroaMetodoLavaggio,
              Icons.water_drop_outlined, Colors.blue.shade700),
          const SizedBox(height: 8),
          _methodChip('sugar_shake', _s.varroaMetodoSugar,
              Icons.grain, Colors.brown.shade500),
          const SizedBox(height: 8),
          _methodChip('caduta_naturale', _s.varroaMetodoCaduta,
              Icons.arrow_downward, Colors.green.shade700),
        ],
      ),
    );
  }

  Widget _methodChip(String value, String label, IconData icon, Color color) {
    final selected = _metodo == value;
    return InkWell(
      onTap: () {
        setState(() { _metodo = value; });
        _updatePreview();
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.transparent,
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : Colors.grey.shade500, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? color : Colors.black87,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Measurement card ───────────────────────────────────────────────────────

  Widget _buildMeasurementCard() {
    return _card(
      _s.varroaFormSectionMisurazione,
      Icons.bug_report_outlined,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_metodo == 'lavaggio_alcolico' || _metodo == 'sugar_shake') ...[
            _numericField(
              controller: _apiController,
              label: _s.varroaFormLblApiCampionate,
              hint: '300',
              suffix: _s.varroaFormSuffixApi,
            ),
            const SizedBox(height: 12),
            _numericField(
              controller: _acariController,
              label: _s.varroaFormLblAcariContati,
              hint: '0',
              suffix: _s.varroaFormSuffixAcari,
            ),
            if (_metodo == 'sugar_shake') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade200),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _s.varroaFormSugarShakeNote,
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            _numericField(
              controller: _acariController,
              label: _s.varroaFormLblAcariTotali,
              hint: '0',
              suffix: _s.varroaFormSuffixAcari,
            ),
            const SizedBox(height: 12),
            _numericField(
              controller: _giorniController,
              label: _s.varroaFormLblGiorniRilevazione,
              hint: '7',
              suffix: _s.varroaFormSuffixGiorni,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.green.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _s.varroaFormCadutaNaturaleNote,
                      style: TextStyle(fontSize: 12, color: Colors.green.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _numericField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
              ? _s.varroaFormValidazioneObbligatorio
              : null
          : null,
    );
  }

  // ── Brood card ─────────────────────────────────────────────────────────────

  Widget _buildBroodCard() {
    return _card(
      _s.varroaFormSectionCovata,
      Icons.grid_on_outlined,
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_s.varroaFormLblTelainiCovata,
                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ThemeConstants.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_telainiCovata.round()} / 10',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ThemeConstants.secondaryColor,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _telainiCovata,
            min: 0,
            max: 10,
            divisions: 10,
            activeColor: ThemeConstants.primaryColor,
            inactiveColor: ThemeConstants.primaryColor.withOpacity(0.25),
            label: '${_telainiCovata.round()}',
            onChanged: (v) {
              setState(() { _telainiCovata = v; });
              _updatePreview();
            },
          ),
          Text(
            _s.varroaFormCovataHint,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ── Note card ──────────────────────────────────────────────────────────────

  Widget _buildNoteCard() {
    return _card(
      _s.varroaFormSectionNote,
      Icons.note_outlined,
      TextFormField(
        controller: _noteController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: _s.varroaFormNoteHint,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  // ── Preview card ───────────────────────────────────────────────────────────

  Widget _buildPreviewCard() {
    final pct     = _percentualePreview!;
    final livello = _rischioLivello(pct);
    final color   = _rischioColor(livello);
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(
              child: Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _s.varroaFormPreviewTitolo,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _rischioLabel(livello),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                    if (_cadutaPreview != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${_cadutaPreview!.toStringAsFixed(1)} ${_s.varroaFormSuffixCaduta}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _s.varroaFormPreviewConfidenza(_metodo),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeConstants.errorColor.withOpacity(0.08),
        border: Border.all(color: ThemeConstants.errorColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: ThemeConstants.errorColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage!,
                style: TextStyle(color: ThemeConstants.errorColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _save,
        icon: _isSaving
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_outlined),
        label: Text(
          _isSaving ? _s.btnSaving : _s.varroaFormBtnSave,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  // ── Card helper ────────────────────────────────────────────────────────────

  Widget _card(String title, IconData icon, Widget child) {
    return Card(
      color: const Color(0xFFFFFDF5),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: ThemeConstants.secondaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: ThemeConstants.secondaryColor,
                    letterSpacing: 0.5,
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

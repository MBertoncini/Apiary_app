import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';

class ReginaFormScreen extends StatefulWidget {
  final int arniaId;
  final Map<String, dynamic>? reginaData; // non-null → edit mode
  final int? reginaId;                    // non-null → edit mode

  const ReginaFormScreen({
    Key? key,
    required this.arniaId,
    this.reginaData,
    this.reginaId,
  }) : super(key: key);

  @override
  _ReginaFormScreenState createState() => _ReginaFormScreenState();
}

class _ReginaFormScreenState extends State<ReginaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  late ApiService _apiService;
  late StorageService _storageService;

  // Form fields
  String _razza = 'ligustica';
  String _origine = 'acquistata';
  DateTime _dataIntroduzione = DateTime.now();
  DateTime? _dataNascita;
  bool _marcata = false;
  String _coloreMarcatura = 'non_marcata';
  bool _fecondata = false;
  bool _selezionata = false;
  String _note = '';
  bool _isLoading = false;

  // Genealogy
  int? _reginaMadreId;
  List<Map<String, dynamic>> _regineDisponibili = [];

  // Valutazioni (1–5, null = non compilata)
  int? _docilita;
  int? _produttivita;
  int? _resistenzaMalattie;
  int? _tendenzaSciamatura;

  static const List<Map<String, String>> _razzeOptions = [
    {'id': 'ligustica', 'label': 'Italiana (Ligustica)'},
    {'id': 'carnica',   'label': 'Carnica'},
    {'id': 'buckfast',  'label': 'Buckfast'},
    {'id': 'caucasica', 'label': 'Caucasica'},
    {'id': 'sicula',    'label': 'Siciliana'},
    {'id': 'ibrida',    'label': 'Ibrida'},
    {'id': 'altro',     'label': 'Altro'},
  ];


  static const List<Map<String, String>> _coloriMarcatura = [
    {'id': 'bianco', 'label': 'Bianco (anni 1,6)'},
    {'id': 'giallo', 'label': 'Giallo (anni 2,7)'},
    {'id': 'rosso',  'label': 'Rosso  (anni 3,8)'},
    {'id': 'verde',  'label': 'Verde  (anni 4,9)'},
    {'id': 'blu',    'label': 'Blu    (anni 5,0)'},
  ];

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiService>(context, listen: false);
    _storageService = Provider.of<StorageService>(context, listen: false);
    // Pre-fill fields when editing
    final r = widget.reginaData;
    if (r != null) {
      _razza = r['razza'] ?? 'ligustica';
      _origine = r['origine'] ?? 'acquistata';
      if (r['data_introduzione'] != null) {
        try { _dataIntroduzione = DateTime.parse(r['data_introduzione']); } catch (_) {}
      }
      if (r['data_nascita'] != null) {
        try { _dataNascita = DateTime.parse(r['data_nascita']); } catch (_) {}
      }
      _marcata = r['marcata'] ?? false;
      _coloreMarcatura = r['colore_marcatura'] ?? 'non_marcata';
      _fecondata = r['fecondata'] ?? false;
      _selezionata = r['selezionata'] ?? false;
      _note = r['note'] ?? '';
      _docilita = r['docilita'] as int?;
      _produttivita = r['produttivita'] as int?;
      _resistenzaMalattie = r['resistenza_malattie'] as int?;
      _tendenzaSciamatura = r['tendenza_sciamatura'] as int?;
      _reginaMadreId = r['regina_madre'] is int ? r['regina_madre'] as int : null;
    }
    _loadRegineDisponibili();
  }

  Future<void> _loadRegineDisponibili() async {
    // Mostra subito dalla cache
    final cached = await _storageService.getStoredData('regine');
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _regineDisponibili = cached
            .map((r) => Map<String, dynamic>.from(r as Map))
            .where((r) => r['arnia'] != widget.arniaId)
            .toList();
      });
    }

    // Aggiorna dal server
    try {
      final response = await _apiService.get(ApiConstants.regineUrl);
      List<dynamic> regine = response is List
          ? response
          : (response is Map ? (response['results'] as List? ?? []) : []);
      await _storageService.saveData('regine', regine);
      if (mounted) {
        setState(() {
          _regineDisponibili = regine
              .map((r) => Map<String, dynamic>.from(r as Map))
              .where((r) => r['arnia'] != widget.arniaId)
              .toList();
        });
      }
    } catch (_) {
      // Genealogy dropdown è opzionale – nessun errore bloccante
    }
  }

  Future<void> _pickDate({required bool isNascita}) async {
    final initial = isNascita ? (_dataNascita ?? DateTime.now()) : _dataIntroduzione;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isNascita) {
        _dataNascita = picked;
      } else {
        _dataIntroduzione = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    final s = Provider.of<LanguageService>(context, listen: false).strings;
    try {
      final data = <String, dynamic>{
        'arnia': widget.arniaId,
        'data_introduzione': _dateFormat.format(_dataIntroduzione),
        'origine': _origine,
        'razza': _razza,
        'marcata': _marcata,
        'colore_marcatura': _marcata ? _coloreMarcatura : 'non_marcata',
        'fecondata': _fecondata,
        'selezionata': _selezionata,
        if (_dataNascita != null) 'data_nascita': _dateFormat.format(_dataNascita!),
        if (_note.isNotEmpty) 'note': _note,
        if (_reginaMadreId != null) 'regina_madre': _reginaMadreId,
        if (_docilita != null) 'docilita': _docilita,
        if (_produttivita != null) 'produttivita': _produttivita,
        if (_resistenzaMalattie != null) 'resistenza_malattie': _resistenzaMalattie,
        if (_tendenzaSciamatura != null) 'tendenza_sciamatura': _tendenzaSciamatura,
      };

      if (widget.reginaId != null) {
        await _apiService.put('${ApiConstants.regineUrl}${widget.reginaId}/', data);
      } else {
        await _apiService.post(ApiConstants.regineUrl, data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.reginaId != null ? s.reginaFormUpdatedOk : s.reginaFormCreatedOk)),
      );
      Navigator.of(context).pop(true); // true = reload caller
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.reginaFormError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStarInput(
    String label,
    int? currentValue,
    ValueChanged<int> onChanged,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            children: [
              // 5 tappable stars
              ...List.generate(5, (i) {
                final filled = currentValue != null && i < currentValue;
                return GestureDetector(
                  onTap: () => onChanged(currentValue == i + 1 ? 0 : i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: filled ? color : Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                );
              }),
              if (currentValue != null && currentValue > 0) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onChanged(0),
                  child: const Icon(Icons.clear, size: 18, color: Colors.grey),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = Provider.of<LanguageService>(context, listen: false).strings;

    final origineItems = [
      {'id': 'acquistata',  'label': s.arniaDetailOrigineAcquistata},
      {'id': 'allevata',    'label': s.arniaDetailOrigineAllevata},
      {'id': 'sciamatura',  'label': s.arniaDetailOrigineSciamatura},
      {'id': 'emergenza',   'label': s.arniaDetailOrigineEmergenza},
      {'id': 'sconosciuta', 'label': s.arniaDetailOrigineSconosciuta},
    ];

    return Scaffold(
      appBar: AppBar(title: Text(widget.reginaId != null ? s.reginaFormTitleEdit : s.reginaFormTitleNew)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Razza
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: s.reginaFormLblRazza,
                        border: const OutlineInputBorder(),
                      ),
                      value: _razza,
                      items: _razzeOptions
                          .map((r) => DropdownMenuItem(value: r['id'], child: Text(r['label']!)))
                          .toList(),
                      onChanged: (v) => setState(() => _razza = v!),
                    ),
                    const SizedBox(height: 16),

                    // Origine
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: s.reginaFormLblOrigine,
                        border: const OutlineInputBorder(),
                      ),
                      value: _origine,
                      items: origineItems
                          .map((o) => DropdownMenuItem(value: o['id'], child: Text(o['label']!)))
                          .toList(),
                      onChanged: (v) => setState(() => _origine = v!),
                    ),
                    const SizedBox(height: 16),

                    // Data introduzione
                    InkWell(
                      onTap: () => _pickDate(isNascita: false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: s.reginaFormLblDataIntroduzione,
                          border: const OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_dateFormat.format(_dataIntroduzione)),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Data nascita (optional)
                    InkWell(
                      onTap: () => _pickDate(isNascita: true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: s.reginaFormLblDataNascita,
                          border: const OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_dataNascita != null
                                ? _dateFormat.format(_dataNascita!)
                                : s.reginaFormHintDataNascitaVuota),
                            Row(children: [
                              if (_dataNascita != null)
                                GestureDetector(
                                  onTap: () => setState(() => _dataNascita = null),
                                  child: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                ),
                              const SizedBox(width: 4),
                              const Icon(Icons.calendar_today, size: 18),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Marcata toggle
                    SwitchListTile(
                      title: Text(s.reginaFormMarcataTitle),
                      value: _marcata,
                      onChanged: (v) => setState(() => _marcata = v),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),

                    if (_marcata) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: s.reginaFormLblColoreMarcatura,
                          border: const OutlineInputBorder(),
                        ),
                        value: _coloreMarcatura == 'non_marcata' ? 'bianco' : _coloreMarcatura,
                        items: _coloriMarcatura
                            .map((c) => DropdownMenuItem(value: c['id'], child: Text(c['label']!)))
                            .toList(),
                        onChanged: (v) => setState(() => _coloreMarcatura = v!),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Fecondata toggle
                    SwitchListTile(
                      title: Text(s.reginaFormFecondataTitle),
                      value: _fecondata,
                      onChanged: (v) => setState(() => _fecondata = v),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Selezionata toggle
                    SwitchListTile(
                      title: Text(s.reginaFormSelezionataTitle),
                      value: _selezionata,
                      onChanged: (v) => setState(() => _selezionata = v),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Valutazioni
                    Text(
                      s.reginaFormValutazioniTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.reginaFormValutazioniHint,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    _buildStarInput(
                      s.arniaDetailRatingDocilita,
                      _docilita,
                      (v) => setState(() => _docilita = v == 0 ? null : v),
                      Colors.green,
                    ),
                    _buildStarInput(
                      s.arniaDetailRatingProduttivita,
                      _produttivita,
                      (v) => setState(() => _produttivita = v == 0 ? null : v),
                      Colors.amber,
                    ),
                    _buildStarInput(
                      s.arniaDetailRatingResistenza,
                      _resistenzaMalattie,
                      (v) => setState(() => _resistenzaMalattie = v == 0 ? null : v),
                      Colors.blue,
                    ),
                    _buildStarInput(
                      s.arniaDetailRatingTendenzaSciamatura,
                      _tendenzaSciamatura,
                      (v) => setState(() => _tendenzaSciamatura = v == 0 ? null : v),
                      Colors.orange,
                    ),
                    const SizedBox(height: 16),

                    // Regina madre (genealogia)
                    if (_regineDisponibili.isNotEmpty) ...[
                      DropdownButtonFormField<int?>(
                        decoration: InputDecoration(
                          labelText: s.reginaFormLblReginaMadre,
                          border: const OutlineInputBorder(),
                        ),
                        value: _reginaMadreId,
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(s.reginaFormHintNessunaRegina),
                          ),
                          ..._regineDisponibili.map((r) {
                            final label =
                                '${s.labelArnia} ${r['arnia_numero'] ?? '?'} – ${r['razza'] ?? ''}';
                            return DropdownMenuItem<int?>(
                              value: r['id'] as int?,
                              child: Text(label),
                            );
                          }),
                        ],
                        onChanged: (v) => setState(() => _reginaMadreId = v),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Note
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: s.reginaFormLblNote,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      initialValue: _note,
                      onSaved: (v) => _note = v?.trim() ?? '',
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _save,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(s.reginaFormBtnSave, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../l10n/app_strings.dart';
import '../../models/cliente.dart';
import '../../models/gruppo.dart';

// ────────────────────────────────────────────────────────────────────
// Dettaglio helper
// ────────────────────────────────────────────────────────────────────

class _DettaglioItem {
  String categoria = 'miele';
  final tipoMieleController = TextEditingController();
  int? formatoVasetto = 500;
  final quantitaController = TextEditingController();
  final prezzoController   = TextEditingController();

  void dispose() {
    tipoMieleController.dispose();
    quantitaController.dispose();
    prezzoController.dispose();
  }

  double get subtotale {
    final q = int.tryParse(quantitaController.text) ?? 0;
    final p = double.tryParse(prezzoController.text) ?? 0;
    return q * p;
  }
}

// ────────────────────────────────────────────────────────────────────
// Screen
// ────────────────────────────────────────────────────────────────────

class VenditaFormScreen extends StatefulWidget {
  final int? venditaId;
  final List<Map<String, dynamic>>? prefillMiele;
  VenditaFormScreen({this.venditaId, this.prefillMiele});

  @override
  _VenditaFormScreenState createState() => _VenditaFormScreenState();
}

class _VenditaFormScreenState extends State<VenditaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ApiService _apiService;
  late StorageService _storageService;
  bool _isLoading = false;
  bool _isLoadingData = true;

  List<Cliente> _clienti = [];
  int? _selectedClienteId;
  bool _clienteLibero = false;
  final _acquirenteNomeController = TextEditingController();

  List<Gruppo> _gruppi = [];
  int? _selectedGruppoId;

  DateTime _selectedDate = DateTime.now();
  String _selectedCanale   = 'privato';
  String _selectedPagamento = 'contanti';
  final _noteController = TextEditingController();

  List<_DettaglioItem> _dettagli = [_DettaglioItem()];

  bool get _isEditing => widget.venditaId != null;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  // ── Categorie ────────────────────────────────────────────────────
  List<String> get _categorieOptions => [
    'miele', 'propoli', 'cera', 'polline', 'pappa_reale', 'nucleo', 'regina', 'altro',
  ];

  Map<String, String> _categorieLabels(AppStrings s) => {
    'miele':       s.venditaCatMiele,
    'propoli':     s.venditaCatPropoli,
    'cera':        s.venditaCatCera,
    'polline':     s.venditaCatPolline,
    'pappa_reale': s.venditaCatPappaReale,
    'nucleo':      s.venditaCatNucleo,
    'regina':      s.venditaCatRegina,
    'altro':       s.venditaCatAltro,
  };

  Map<String, String> _canaleOptions(AppStrings s) => {
    'mercatino': s.venditaCanaleMercatino,
    'negozio':   s.venditaCanaleNegozio,
    'privato':   s.venditaCanalePrivato,
    'online':    s.venditaCanaleOnline,
    'altro':     s.venditaCanaleAltro,
  };

  Map<String, String> _pagamentoOptions(AppStrings s) => {
    'contanti': s.venditaPagamentoContanti,
    'bonifico': s.venditaPagamentoBonifico,
    'carta':    s.venditaPagamentoCarta,
    'altro':    s.venditaPagamentoAltro,
  };

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService   = ApiService(authService);
    _storageService = Provider.of<StorageService>(context, listen: false);
    if (widget.prefillMiele != null && widget.prefillMiele!.isNotEmpty) {
      _dettagli = widget.prefillMiele!.map((item) {
        final d = _DettaglioItem();
        d.categoria = 'miele';
        d.tipoMieleController.text = item['tipo_miele']?.toString() ?? '';
        d.formatoVasetto = (item['formato_vasetto'] as num?)?.toInt() ?? 500;
        d.quantitaController.text = (item['quantita'] ?? 0).toString();
        return d;
      }).toList();
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _acquirenteNomeController.dispose();
    _noteController.dispose();
    for (final d in _dettagli) d.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final cachedClienti = await _storageService.getStoredData('clienti');
    if (cachedClienti.isNotEmpty && mounted) {
      setState(() {
        _clienti = cachedClienti.map((e) => Cliente.fromJson(e as Map<String, dynamic>)).toList();
      });
    }

    if (_isEditing) {
      final cachedVendite = await _storageService.getStoredData('vendite');
      final found = cachedVendite.cast<Map<String, dynamic>>().firstWhere(
        (v) => v['id'] == widget.venditaId,
        orElse: () => <String, dynamic>{},
      );
      if (found.isNotEmpty && mounted) _populateFromVenditaJson(found);
    }

    try {
      final clientiRes = await _apiService.get(ApiConstants.clientiUrl);
      final clientiList = clientiRes is List ? clientiRes : (clientiRes['results'] as List? ?? []);
      await _storageService.saveData('clienti', clientiList);
      if (mounted) {
        setState(() {
          _clienti = clientiList.map((e) => Cliente.fromJson(e as Map<String, dynamic>)).toList();
        });
      }
    } catch (_) {}

    if (_isEditing) {
      try {
        final data = await _apiService.get('${ApiConstants.venditeUrl}${widget.venditaId}/');
        if (mounted) _populateFromVenditaJson(data as Map<String, dynamic>);
      } catch (_) {}
    }

    try {
      final res = await _apiService.get(ApiConstants.gruppiUrl);
      final list = res is List ? res : (res['results'] as List? ?? []);
      if (mounted) {
        setState(() {
          _gruppi = list.map((e) => Gruppo.fromJson(e as Map<String, dynamic>)).toList();
        });
      }
    } catch (_) {}

    if (mounted) setState(() { _isLoadingData = false; });
  }

  void _populateFromVenditaJson(Map<String, dynamic> data) {
    _selectedClienteId = data['cliente'];
    _clienteLibero     = (data['cliente'] == null);
    _acquirenteNomeController.text = data['acquirente_nome'] ?? '';
    _selectedCanale    = data['canale']    ?? 'privato';
    _selectedPagamento = data['pagamento'] ?? 'contanti';
    _selectedDate = DateTime.tryParse(data['data'] ?? '') ?? DateTime.now();
    _noteController.text = data['note'] ?? '';
    _selectedGruppoId  = data['gruppo'];

    final dettagliList = data['dettagli'] as List? ?? [];
    if (dettagliList.isNotEmpty) {
      for (final d in _dettagli) d.dispose();
      _dettagli = dettagliList.map((d) {
        final item = _DettaglioItem();
        item.categoria               = d['categoria'] ?? 'miele';
        item.tipoMieleController.text = d['tipo_miele'] ?? '';
        item.formatoVasetto          = d['formato_vasetto'] ?? 500;
        item.quantitaController.text  = d['quantita']?.toString() ?? '';
        item.prezzoController.text    = d['prezzo_unitario']?.toString() ?? '';
        return item;
      }).toList();
      setState(() {});
    }
  }

  double get _totale => _dettagli.fold(0, (sum, d) => sum + d.subtotale);

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) setState(() { _selectedDate = picked; });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final s = _s;

    if (_clienteLibero && _acquirenteNomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.venditaFormValidateAcquirente)));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final venditaData = {
        'data':      _selectedDate.toIso8601String().split('T')[0],
        'canale':    _selectedCanale,
        'pagamento': _selectedPagamento,
        if (!_clienteLibero && _selectedClienteId != null)
          'cliente':         _selectedClienteId,
        if (_clienteLibero)
          'acquirente_nome': _acquirenteNomeController.text.trim(),
        if (_noteController.text.isNotEmpty)
          'note': _noteController.text,
        'gruppo': _selectedGruppoId,
      };

      dynamic result;
      if (_isEditing) {
        result = await _apiService.put('${ApiConstants.venditeUrl}${widget.venditaId}/', venditaData);
      } else {
        result = await _apiService.post(ApiConstants.venditeUrl, venditaData);
      }

      final venditaId = result['id'];
      for (final d in _dettagli) {
        final dettaglioData = {
          'categoria':       d.categoria,
          if (d.categoria == 'miele' && d.tipoMieleController.text.isNotEmpty)
            'tipo_miele':    d.tipoMieleController.text,
          if (d.categoria == 'miele' && d.formatoVasetto != null)
            'formato_vasetto': d.formatoVasetto,
          'quantita':        int.tryParse(d.quantitaController.text) ?? 0,
          'prezzo_unitario': d.prezzoController.text,
        };
        await _apiService.post(
          '${ApiConstants.venditeUrl}$venditaId/aggiungi_dettaglio/', dettaglioData);
      }

      await _storageService.saveData('vendite', []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? s.venditaFormUpdatedOk : s.venditaFormCreatedOk)));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.msgErrorGeneric(e.toString()))));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? s.venditaFormTitleEdit : s.venditaFormTitleNew)),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAcquirenteSection(s),
                    SizedBox(height: 16),
                    _buildDatePicker(s),
                    SizedBox(height: 20),
                    _buildChipSection(s.venditaFormSectionCanale, _canaleOptions(s), _selectedCanale,
                        (val) => setState(() { _selectedCanale = val; }),
                        ThemeConstants.primaryColor),
                    SizedBox(height: 16),
                    _buildChipSection(s.venditaFormSectionPagamento, _pagamentoOptions(s), _selectedPagamento,
                        (val) => setState(() { _selectedPagamento = val; }),
                        Colors.green.shade700),
                    SizedBox(height: 20),
                    Text(s.venditaFormSectionArticoli, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ...List.generate(_dettagli.length, (i) => _buildDettaglioCard(i, s)),
                    SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text(s.venditaFormBtnAddArticolo),
                      onPressed: () => setState(() { _dettagli.add(_DettaglioItem()); }),
                    ),
                    SizedBox(height: 16),
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(s.venditaFormTotale(_totale.toStringAsFixed(2)),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(labelText: s.labelNotes, border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    if (_gruppi.isNotEmpty) ...[
                      SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        value: _selectedGruppoId,
                        decoration: InputDecoration(
                          labelText: s.venditaFormLblCondividi,
                          hintText: s.venditaFormHintSoloPersonale,
                          prefixIcon: Icon(Icons.group),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<int?>(value: null, child: Text(s.venditaFormHintSoloPersonale)),
                          ..._gruppi.map((g) => DropdownMenuItem<int?>(value: g.id, child: Text(g.nome))),
                        ],
                        onChanged: (val) => setState(() { _selectedGruppoId = val; }),
                      ),
                    ],
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                      child: _isLoading
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isEditing ? s.attrezzaturaFormBtnAggiorna : s.venditaFormCreatedOk.toUpperCase()),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAcquirenteSection(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(s.venditaFormLblAcquirente, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Spacer(),
            TextButton.icon(
              icon: Icon(_clienteLibero ? Icons.person_search : Icons.edit_note, size: 18),
              label: Text(_clienteLibero ? s.venditaFormBtnUsaClienteReg : s.venditaFormBtnNomeLibero,
                  style: TextStyle(fontSize: 13)),
              onPressed: () => setState(() {
                _clienteLibero = !_clienteLibero;
                _selectedClienteId = null;
                _acquirenteNomeController.clear();
              }),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (!_clienteLibero)
          DropdownButtonFormField<int?>(
            value: _selectedClienteId,
            decoration: InputDecoration(
              labelText: s.venditaFormLblClienteReg,
              hintText: s.venditaFormHintNessuno,
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text(s.venditaFormHintNessuno)),
              ..._clienti.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.nome))),
            ],
            onChanged: (val) => setState(() { _selectedClienteId = val; }),
          )
        else
          TextFormField(
            controller: _acquirenteNomeController,
            decoration: InputDecoration(
              labelText: s.venditaFormLblAcquirenteNome,
              border: OutlineInputBorder(),
            ),
            validator: (val) => _clienteLibero && (val == null || val.isEmpty)
                ? s.venditaFormValidateNome : null,
          ),
      ],
    );
  }

  Widget _buildDatePicker(AppStrings s) {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: s.venditaFormLblData,
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_selectedDate.day.toString().padLeft(2, '0')}/'
          '${_selectedDate.month.toString().padLeft(2, '0')}/'
          '${_selectedDate.year}',
        ),
      ),
    );
  }

  Widget _buildChipSection(
    String title,
    Map<String, String> options,
    String selected,
    void Function(String) onSelect,
    Color activeColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.entries.map((e) => ChoiceChip(
            label: Text(e.value),
            selected: selected == e.key,
            selectedColor: activeColor.withOpacity(0.25),
            onSelected: (_) => onSelect(e.key),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildDettaglioCard(int index, AppStrings s) {
    final d = _dettagli[index];
    final cats = _categorieLabels(s);
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(s.venditaFormArticoloLabel(index + 1),
                    style: TextStyle(fontWeight: FontWeight.bold))),
                if (_dettagli.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => setState(() {
                      _dettagli[index].dispose();
                      _dettagli.removeAt(index);
                    }),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _categorieOptions.map((cat) => ChoiceChip(
                label: Text(cats[cat]!),
                selected: d.categoria == cat,
                visualDensity: VisualDensity.compact,
                selectedColor: ThemeConstants.primaryColor.withOpacity(0.25),
                onSelected: (_) => setState(() { d.categoria = cat; }),
              )).toList(),
            ),
            SizedBox(height: 10),
            if (d.categoria == 'miele') ...[
              TextFormField(
                controller: d.tipoMieleController,
                decoration: InputDecoration(
                  labelText: s.venditaFormLblTipoMiele,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (val) => d.categoria == 'miele' && (val == null || val.isEmpty)
                    ? s.venditaFormValidateRequired : null,
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: d.formatoVasetto ?? 500,
                decoration: InputDecoration(
                  labelText: s.venditaFormLblFormatoVasetto,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 250,  child: Text('250g')),
                  DropdownMenuItem(value: 500,  child: Text('500g')),
                  DropdownMenuItem(value: 1000, child: Text('1000g')),
                ],
                onChanged: (val) => setState(() { d.formatoVasetto = val; }),
              ),
              SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: d.quantitaController,
                    decoration: InputDecoration(
                      labelText: s.venditaFormLblQty,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (val) => val == null || val.isEmpty ? s.venditaFormValidateRequired : null,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: d.prezzoController,
                    decoration: InputDecoration(
                      labelText: s.venditaFormLblPrezzo,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    validator: (val) => val == null || val.isEmpty ? s.venditaFormValidateRequired : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(s.venditaFormSubtotale(d.subtotale.toStringAsFixed(2)),
                  style: TextStyle(color: Colors.grey[600])),
            ),
          ],
        ),
      ),
    );
  }
}

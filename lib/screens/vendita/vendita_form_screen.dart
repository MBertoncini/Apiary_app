import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../models/cliente.dart';
import '../../models/gruppo.dart';

// ────────────────────────────────────────────────────────────────────
// Constants
// ────────────────────────────────────────────────────────────────────

const _canaleOptions = {
  'mercatino': 'Mercatino',
  'negozio':   'Negozio',
  'privato':   'Privato',
  'online':    'Online',
  'altro':     'Altro',
};

const _pagamentoOptions = {
  'contanti': 'Contanti',
  'bonifico': 'Bonifico',
  'carta':    'Carta',
  'altro':    'Altro',
};

const _categorieOptions = [
  'miele', 'propoli', 'cera', 'polline', 'pappa_reale', 'nucleo', 'regina', 'altro',
];

const _categorieLabels = {
  'miele':       'Miele',
  'propoli':     'Propoli',
  'cera':        'Cera',
  'polline':     'Polline',
  'pappa_reale': 'Pappa reale',
  'nucleo':      'Nucleo',
  'regina':      'Regina',
  'altro':       'Altro',
};

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
  VenditaFormScreen({this.venditaId});

  @override
  _VenditaFormScreenState createState() => _VenditaFormScreenState();
}

class _VenditaFormScreenState extends State<VenditaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ApiService _apiService;
  late StorageService _storageService;
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Acquirente
  List<Cliente> _clienti = [];
  int? _selectedClienteId;
  bool _clienteLibero = false;         // true = free text, false = dropdown
  final _acquirenteNomeController = TextEditingController();

  // Gruppo
  List<Gruppo> _gruppi = [];
  int? _selectedGruppoId;

  // Sale metadata
  DateTime _selectedDate = DateTime.now();
  String _selectedCanale   = 'privato';
  String _selectedPagamento = 'contanti';
  final _noteController = TextEditingController();

  // Dettagli
  List<_DettaglioItem> _dettagli = [_DettaglioItem()];

  bool get _isEditing => widget.venditaId != null;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService   = ApiService(authService);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _loadInitialData();
  }

  @override
  void dispose() {
    _acquirenteNomeController.dispose();
    _noteController.dispose();
    for (final d in _dettagli) d.dispose();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────

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

  // ── Computed ────────────────────────────────────────────────────

  double get _totale => _dettagli.fold(0, (sum, d) => sum + d.subtotale);

  // ── Actions ─────────────────────────────────────────────────────

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

    if (_clienteLibero && _acquirenteNomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inserisci il nome dell\'acquirente')));
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
        SnackBar(content: Text(_isEditing ? 'Vendita aggiornata' : 'Vendita registrata')));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Modifica Vendita' : 'Nuova Vendita')),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAcquirenteSection(),
                    SizedBox(height: 16),
                    _buildDatePicker(),
                    SizedBox(height: 20),
                    _buildChipSection('Canale di vendita', _canaleOptions, _selectedCanale,
                        (val) => setState(() { _selectedCanale = val; }),
                        ThemeConstants.primaryColor),
                    SizedBox(height: 16),
                    _buildChipSection('Metodo di pagamento', _pagamentoOptions, _selectedPagamento,
                        (val) => setState(() { _selectedPagamento = val; }),
                        Colors.green.shade700),
                    SizedBox(height: 20),
                    Text('Articoli', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ...List.generate(_dettagli.length, (i) => _buildDettaglioCard(i)),
                    SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Aggiungi articolo'),
                      onPressed: () => setState(() { _dettagli.add(_DettaglioItem()); }),
                    ),
                    SizedBox(height: 16),
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Totale: ${_totale.toStringAsFixed(2)} €',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    if (_gruppi.isNotEmpty) ...[
                      SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        value: _selectedGruppoId,
                        decoration: InputDecoration(
                          labelText: 'Condividi con gruppo',
                          hintText: '— solo personale —',
                          prefixIcon: Icon(Icons.group),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<int?>(value: null, child: Text('— solo personale —')),
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
                          : Text(_isEditing ? 'AGGIORNA' : 'REGISTRA'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Section builders ─────────────────────────────────────────────

  Widget _buildAcquirenteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Acquirente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Spacer(),
            TextButton.icon(
              icon: Icon(_clienteLibero ? Icons.person_search : Icons.edit_note, size: 18),
              label: Text(_clienteLibero ? 'Usa cliente registrato' : 'Nome libero',
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
              labelText: 'Cliente registrato',
              hintText: '— nessuno (vendita anonima) —',
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text('— nessuno —')),
              ..._clienti.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.nome))),
            ],
            onChanged: (val) => setState(() { _selectedClienteId = val; }),
          )
        else
          TextFormField(
            controller: _acquirenteNomeController,
            decoration: InputDecoration(
              labelText: 'Nome acquirente *',
              border: OutlineInputBorder(),
            ),
            validator: (val) => _clienteLibero && (val == null || val.isEmpty)
                ? 'Inserisci il nome' : null,
          ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Data *',
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

  Widget _buildDettaglioCard(int index) {
    final d = _dettagli[index];
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Articolo ${index + 1}',
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
            // Categoria chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _categorieOptions.map((cat) => ChoiceChip(
                label: Text(_categorieLabels[cat]!),
                selected: d.categoria == cat,
                visualDensity: VisualDensity.compact,
                selectedColor: ThemeConstants.primaryColor.withOpacity(0.25),
                onSelected: (_) => setState(() { d.categoria = cat; }),
              )).toList(),
            ),
            SizedBox(height: 10),
            // Tipo miele + formato (only for miele)
            if (d.categoria == 'miele') ...[
              TextFormField(
                controller: d.tipoMieleController,
                decoration: InputDecoration(
                  labelText: 'Tipo miele *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (val) => d.categoria == 'miele' && (val == null || val.isEmpty)
                    ? 'Obbligatorio' : null,
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: d.formatoVasetto ?? 500,
                decoration: InputDecoration(
                  labelText: 'Formato vasetto',
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
            // Qty + price
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: d.quantitaController,
                    decoration: InputDecoration(
                      labelText: 'Qty *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (val) => val == null || val.isEmpty ? 'Obbligatorio' : null,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: d.prezzoController,
                    decoration: InputDecoration(
                      labelText: 'Prezzo € *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    validator: (val) => val == null || val.isEmpty ? 'Obbligatorio' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Subtotale: ${d.subtotale.toStringAsFixed(2)} €',
                  style: TextStyle(color: Colors.grey[600])),
            ),
          ],
        ),
      ),
    );
  }
}

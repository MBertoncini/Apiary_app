import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../models/melario.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/language_service.dart';
import '../../l10n/app_strings.dart';

class MelarioFormScreen extends StatefulWidget {
  final int? preselectedApiarioId;
  final int? preselectedArniaId;
  // Se valorizzato, il form è in modalità edit (PATCH invece di POST). I
  // dropdown apiario/arnia sono read-only: per cambiare arnia si usa il
  // drag-and-drop nella vista alveari.
  final Melario? editingMelario;

  const MelarioFormScreen({
    Key? key,
    this.preselectedApiarioId,
    this.preselectedArniaId,
    this.editingMelario,
  }) : super(key: key);

  @override
  _MelarioFormScreenState createState() => _MelarioFormScreenState();
}

class _MelarioFormScreenState extends State<MelarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ApiService _apiService;
  late StorageService _storageService;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  List<Map<String, dynamic>> _apiari = [];
  List<Map<String, dynamic>> _arnie = [];
  bool _isLoadingData = true;
  bool _isSaving = false;

  int? _selectedApiarioId;
  int? _selectedArniaId;
  int? _selectedColoniaId;
  bool _isResolvingColonia = false;
  DateTime _dataPosizionamento = DateTime.now();
  int _numeroTelaini = 10;
  int _posizione = 1;
  String _tipoMelario = 'standard';
  String _statoFavi = 'costruiti';
  bool _escludiRegina = true;
  final _noteController = TextEditingController();
  // Posizioni già occupate da melari attivi sull'arnia selezionata.
  Set<int> _posizioniOccupate = {};
  Melario? get _editingMelario => widget.editingMelario;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _loadData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // In edit mode pre-popola i campi dal melario esistente.
    final editing = _editingMelario;
    if (editing != null) {
      _numeroTelaini = editing.numeroTelaini;
      _posizione = editing.posizione;
      _tipoMelario = editing.tipoMelario;
      _statoFavi = editing.statoFavi;
      _escludiRegina = editing.escludiRegina;
      _noteController.text = editing.note ?? '';
      _selectedColoniaId = editing.colonia ?? editing.coloniaId;
      _selectedApiarioId = editing.apiarioId;
      _selectedArniaId = editing.arnia;
      final parsed = DateTime.tryParse(editing.dataPosizionamento);
      if (parsed != null) _dataPosizionamento = parsed;
    }

    // Mostra apiari subito dalla cache
    final cachedApiari = await _storageService.getStoredData('apiari');
    if (cachedApiari.isNotEmpty && mounted) {
      setState(() {
        _apiari = cachedApiari.map((e) => e as Map<String, dynamic>).toList();
        _isLoadingData = false;
      });
    }

    final preselApiario = editing?.apiarioId ?? widget.preselectedApiarioId;
    final preselArnia = editing?.arnia ?? widget.preselectedArniaId;

    try {
      final res = await _apiService.get(ApiConstants.apiariUrl);
      final list = res is List ? res : (res['results'] as List? ?? []);
      await _storageService.saveData('apiari', list);
      if (mounted) {
        setState(() {
          _apiari = list.map((e) => e as Map<String, dynamic>).toList();
          _isLoadingData = false;
        });
      }
      if (preselApiario != null) {
        setState(() => _selectedApiarioId = preselApiario);
        await _loadArnie(preselApiario);
        if (preselArnia != null) {
          setState(() => _selectedArniaId = preselArnia);
          await _resolveColonia(preselArnia);
          await _loadOccupiedPositions(preselArnia);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        if (_apiari.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_s.melarioFormLoadError(e.toString()))),
          );
        }
        // If apiario was preselected, still try to load arnie from cache
        if (preselApiario != null) {
          setState(() => _selectedApiarioId = preselApiario);
          await _loadArnie(preselApiario);
          if (preselArnia != null) {
            setState(() => _selectedArniaId = preselArnia);
            await _resolveColonia(preselArnia);
            await _loadOccupiedPositions(preselArnia);
          }
        }
      }
    }
  }

  Future<void> _resolveColonia(int arniaId) async {
    if (!mounted) return;
    setState(() {
      _isResolvingColonia = true;
      _selectedColoniaId = null;
    });
    try {
      final res = await _apiService.get('${ApiConstants.arnieUrl}$arniaId/colonia_attiva/');
      if (!mounted) return;
      final id = (res is Map<String, dynamic>) ? res['id'] as int? : null;
      setState(() {
        _selectedColoniaId = id;
        _isResolvingColonia = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isResolvingColonia = false);
    }
  }

  Future<void> _loadOccupiedPositions(int arniaId) async {
    // In edit mode la posizione attuale del melario non va considerata occupata
    // (l'utente può lasciarla com'è).
    final editingId = _editingMelario?.id;

    // Prima dalla cache, poi prova ad aggiornare via API.
    final occupied = <int>{};
    try {
      final cached = await _storageService.getStoredData('melari');
      for (final raw in cached) {
        final m = Melario.fromJson(raw as Map<String, dynamic>);
        if (m.id == editingId) continue;
        if (m.arnia == arniaId &&
            (m.stato == 'posizionato' || m.stato == 'in_smielatura')) {
          occupied.add(m.posizione);
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _posizioniOccupate = occupied;
        // In edit mode mantieni la posizione attuale; in create scegli la
        // prima libera.
        if (_editingMelario == null) {
          _posizione = _firstFreePosition(occupied);
        }
      });
    }

    // Aggiornamento dal server (best-effort): le posizioni potrebbero essere
    // cambiate da un altro client. Il MelarioViewSet non espone un filtro
    // ?arnia_id=…, quindi si carica tutto e si filtra lato client.
    // Usiamo getAll per seguire la paginazione DRF: con >20 melari, prima
    // venivano lette solo le prime 20 posizioni occupate.
    try {
      final list = await _apiService.getAll(ApiConstants.melariUrl);
      final fresh = <int>{};
      for (final raw in list) {
        final m = Melario.fromJson(raw as Map<String, dynamic>);
        if (m.id == editingId) continue;
        if (m.arnia == arniaId &&
            (m.stato == 'posizionato' || m.stato == 'in_smielatura')) {
          fresh.add(m.posizione);
        }
      }
      if (mounted) {
        setState(() {
          _posizioniOccupate = fresh;
          if (fresh.contains(_posizione) && _editingMelario == null) {
            _posizione = _firstFreePosition(fresh);
          }
        });
      }
    } catch (_) {}
  }

  // Limite massimo "morbido" sullo stack di melari per arnia. Non c'è un
  // vincolo di dominio, ma oltre un certo numero la pratica apistica non ha
  // senso e la UI non sta più in colonna. Lo stepper può comunque arrivare a
  // [_maxStackedMelari] per permettere il recupero da stati anomali.
  static const int _maxStackedMelari = 8;

  int _firstFreePosition(Set<int> occupied) {
    for (var p = 1; p <= _maxStackedMelari; p++) {
      if (!occupied.contains(p)) return p;
    }
    // Fallback: tutti i 1..max occupati → proponi pos = max(occupate)+1
    final maxOcc =
        occupied.fold<int>(0, (acc, v) => v > acc ? v : acc);
    return maxOcc + 1;
  }

  Future<void> _loadArnie(int apiarioId) async {
    // Try cache first
    final cachedArnie = await _storageService.getStoredData('arnie');
    if (cachedArnie.isNotEmpty && mounted) {
      final filtered = cachedArnie
          .map((e) => e as Map<String, dynamic>)
          .where((a) => a['apiario'] == apiarioId)
          .toList();
      setState(() {
        _arnie = filtered;
        if (!_arnie.any((a) => a['id'] == _selectedArniaId)) _selectedArniaId = null;
      });
    }

    try {
      final res = await _apiService.get(ApiConstants.arnieUrl);
      final list = res is List ? res : (res['results'] as List? ?? []);
      await _storageService.saveData('arnie', list);
      if (mounted) {
        setState(() {
          _arnie = list
              .map((e) => e as Map<String, dynamic>)
              .where((a) => a['apiario'] == apiarioId)
              .toList();
          if (!_arnie.any((a) => a['id'] == _selectedArniaId)) _selectedArniaId = null;
        });
      }
    } catch (e) {
      if (mounted && _arnie.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s.melarioFormArnieLoadError(e.toString()))),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedArniaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.melarioFormValidateArnia)),
      );
      return;
    }
    if (_posizioniOccupate.contains(_posizione)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Posizione $_posizione già occupata su questa arnia. '
            'Scegli una posizione libera (occupate: '
            '${(_posizioniOccupate.toList()..sort()).join(", ")}).',
          ),
        ),
      );
      return;
    }
    // Attende la risoluzione della colonia in corso per l'arnia selezionata.
    if (_isResolvingColonia) {
      for (var i = 0; i < 20 && _isResolvingColonia && mounted; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    // Senza colonia il melario sarebbe orfano (arnia/apiario derivati da
    // colonia.arnia lato backend), invisibile in vista alveari. Blocca il save.
    if (_selectedColoniaId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s.melarioFormNoColoniaError)),
        );
      }
      return;
    }
    setState(() => _isSaving = true);

    try {
      final body = <String, dynamic>{
        'colonia': _selectedColoniaId,
        'numero_telaini': _numeroTelaini,
        'posizione': _posizione,
        'data_posizionamento':
            _dataPosizionamento.toIso8601String().split('T')[0],
        'tipo_melario': _tipoMelario,
        'stato_favi': _statoFavi,
        'escludi_regina': _escludiRegina,
        if (_noteController.text.trim().isNotEmpty)
          'note': _noteController.text.trim(),
      };
      if (_editingMelario != null) {
        await _apiService.patch(
            '${ApiConstants.melariUrl}${_editingMelario!.id}/', body);
      } else {
        await _apiService.post(ApiConstants.melariUrl, body);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editingMelario != null
              ? _s.melarioFormUpdatedOk
              : _s.melarioFormCreatedOk)),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s.melarioFormLoadError(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingMelario != null
            ? s.melarioFormTitleEdit
            : s.melarioFormTitle),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: s.btnSave,
                  onPressed: _save,
                ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCard(
                    s.melarioFormSectionId,
                    Icons.inventory_2,
                    [
                      _buildApiarioDropdown(s),
                      const SizedBox(height: 12),
                      _buildArniaDropdown(s),
                      const SizedBox(height: 16),
                      _buildLabel(s.melarioFormLblTipo),
                      const SizedBox(height: 6),
                      _buildTipoMelarioSelector(s),
                      const SizedBox(height: 16),
                      _buildLabel(s.melarioFormLblStatoFavi),
                      const SizedBox(height: 6),
                      _buildStatoFaviSelector(s),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCard(
                    s.melarioFormSectionProd,
                    Icons.local_drink,
                    [
                      _buildDataPicker(s),
                      const Divider(height: 24),
                      _buildStepper(
                        icon: Icons.view_week,
                        label: s.melarioFormLblNumTelaini,
                        value: _numeroTelaini,
                        min: 1,
                        max: 12,
                        display: '$_numeroTelaini',
                        onDecrement: () =>
                            setState(() => _numeroTelaini--),
                        onIncrement: () =>
                            setState(() => _numeroTelaini++),
                      ),
                      const SizedBox(height: 8),
                      _buildStepper(
                        icon: Icons.layers,
                        label: s.melarioFormLblPosizione,
                        value: _posizione,
                        min: 1,
                        // Permette di superare 5 quando ci sono già molti
                        // melari sull'arnia, evitando lo stallo "tutte le
                        // posizioni occupate".
                        max: _maxStackedMelari,
                        display: '$_posizione°',
                        onDecrement: () => setState(() => _posizione--),
                        onIncrement: () => setState(() => _posizione++),
                      ),
                      if (_posizioniOccupate.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 32, top: 4),
                          child: Text(
                            _posizioniOccupate.contains(_posizione)
                                ? '⚠ Posizione $_posizione già occupata. Occupate: ${(_posizioniOccupate.toList()..sort()).join(", ")}'
                                : 'Posizioni occupate: ${(_posizioniOccupate.toList()..sort()).join(", ")}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _posizioniOccupate.contains(_posizione)
                                  ? Colors.red.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      const Divider(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.block),
                        title: Text(s.melarioFormLblEscludiRegina),
                        subtitle: Text(s.melarioFormSubEscludiRegina),
                        value: _escludiRegina,
                        onChanged: (v) => setState(() => _escludiRegina = v),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: s.melarioFormLblNote,
                          border: const OutlineInputBorder(),
                          hintText: s.melarioFormHintNote,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(_editingMelario != null
                        ? s.melarioFormBtnUpdate
                        : s.melarioFormBtnAdd),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]));
  }

  Widget _buildApiarioDropdown(AppStrings s) {
    // In edit mode il dropdown è disabilitato: per spostare il melario su
    // un'altra arnia/apiario si usa il drag-and-drop nella vista alveari.
    final isEdit = _editingMelario != null;
    return DropdownButtonFormField<int>(
      value: _selectedApiarioId,
      decoration: InputDecoration(
          labelText: '${s.labelApiario} *', border: const OutlineInputBorder()),
      items: _apiari
          .map((a) => DropdownMenuItem<int>(
                value: a['id'] as int,
                child: Text(a['nome']?.toString() ?? '${s.labelApiario} ${a["id"]}'),
              ))
          .toList(),
      onChanged: isEdit
          ? null
          : (id) {
              setState(() {
                _selectedApiarioId = id;
                _selectedArniaId = null;
                _arnie = [];
              });
              if (id != null) _loadArnie(id);
            },
      validator: (v) => v == null ? s.smielaturaFormSelectApiarioMsg : null,
    );
  }

  Widget _buildArniaDropdown(AppStrings s) {
    final isEdit = _editingMelario != null;
    return DropdownButtonFormField<int>(
      value: _selectedArniaId,
      decoration: InputDecoration(
        labelText: '${s.labelArnia} *',
        border: const OutlineInputBorder(),
        hintText: _selectedApiarioId == null
            ? s.melarioFormHintSelectApiario
            : _arnie.isEmpty
                ? s.melarioFormNoArnie
                : null,
      ),
      items: _arnie
          .map((a) => DropdownMenuItem<int>(
                value: a['id'] as int,
                child: Text('${s.labelArnia} ${a["numero"] ?? a["id"]}'),
              ))
          .toList(),
      onChanged: (isEdit || _selectedApiarioId == null)
          ? null
          : (id) {
              setState(() {
                _selectedArniaId = id;
                _selectedColoniaId = null;
                _posizioniOccupate = {};
              });
              if (id != null) {
                _resolveColonia(id);
                _loadOccupiedPositions(id);
              }
            },
      validator: (v) => v == null ? s.melarioFormValidateArnia : null,
    );
  }

  Widget _buildTipoMelarioSelector(AppStrings s) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
            value: 'standard',
            label: Text('Standard'),
            icon: Icon(Icons.grid_on, size: 16)),
        ButtonSegment(
            value: 'tre_quarti',
            label: Text('3/4'),
            icon: Icon(Icons.grid_view, size: 16)),
        ButtonSegment(
            value: 'meta',
            label: Text('1/2'),
            icon: Icon(Icons.view_module, size: 16)),
      ],
      selected: {_tipoMelario},
      onSelectionChanged: (sel) => setState(() => _tipoMelario = sel.first),
    );
  }

  Widget _buildStatoFaviSelector(AppStrings s) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
            value: 'costruiti',
            label: Text(s.melarioFormFaviCostruiti),
            icon: const Icon(Icons.check_circle_outline, size: 16)),
        ButtonSegment(
            value: 'fogli_cerei',
            label: Text(s.melarioFormFaviCerei),
            icon: const Icon(Icons.radio_button_unchecked, size: 16)),
      ],
      selected: {_statoFavi},
      onSelectionChanged: (sel) => setState(() => _statoFavi = sel.first),
    );
  }

  Widget _buildDataPicker(AppStrings s) {
    final d = _dataPosizionamento;
    final formatted =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today),
      title: Text(s.melarioFormLblDataPos),
      subtitle: Text(formatted,
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dataPosizionamento,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null) setState(() => _dataPosizionamento = picked);
      },
    );
  }

  Widget _buildStepper({
    required IconData icon,
    required String label,
    required int value,
    required int min,
    required int max,
    required String display,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? onDecrement : null,
        ),
        SizedBox(
          width: 36,
          child: Text(display,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold)),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? onIncrement : null,
        ),
      ],
    );
  }
}

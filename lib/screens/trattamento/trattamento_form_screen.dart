import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/loading_widget.dart';
import '../apiario/widgets/apiario_map_widget.dart';

class TrattamentoFormScreen extends StatefulWidget {
  final int? apiarioId;
  final int? arniaId; // Pre-selezione arnia specifica
  final int? trattamentoId; // Se fornito, siamo in modalità modifica

  const TrattamentoFormScreen({
    Key? key,
    this.apiarioId,
    this.arniaId,
    this.trattamentoId,
  }) : super(key: key);

  @override
  _TrattamentoFormScreenState createState() => _TrattamentoFormScreenState();
}

class _TrattamentoFormScreenState extends State<TrattamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  late ApiService _apiService;
  late StorageService _storageService;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Dati del form
  int? _apiarioId;
  String? _apiarioNome;
  int? _tipoTrattamentoId;
  String _metodoApplicazione = 'altro';
  DateTime _dataInizio = DateTime.now();
  DateTime? _dataFine;
  String _note = '';
  bool _bloccoCovataAttivo = false;
  DateTime? _dataInizioBlocco;
  DateTime? _dataFineBlocco;
  String _metodoBlocco = '';
  String _noteBlocco = '';

  // Target: tutto l'apiario vs arnie specifiche
  bool _targetingSpecificArnie = false;
  List<dynamic> _arnieApiario = [];
  Set<int> _selectedArnieIds = {};
  bool _loadingArnie = false;

  // Dati per i dropdown
  List<dynamic> _apiari = [];
  List<dynamic> _tipiTrattamento = [];

  static const List<String> _metodiApplicazione = [
    'strisce',
    'gocciolato',
    'sublimato',
    'altro',
  ];

  static const Map<String, String> _metodiLabels = {
    'strisce': 'Strisce',
    'gocciolato': 'Gocciolato',
    'sublimato': 'Sublimato',
    'altro': 'Altro',
  };

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final cachedApiari = await _storageService.getStoredData('apiari');
    final cachedTipi = await _storageService.getStoredData('tipiTrattamento');
    if ((cachedApiari.isNotEmpty || cachedTipi.isNotEmpty) && mounted) {
      setState(() {
        if (cachedApiari.isNotEmpty) _apiari = cachedApiari;
        if (cachedTipi.isNotEmpty) _tipiTrattamento = cachedTipi;
        _isLoading = false;
      });
    }

    try {
      final results = await Future.wait([
        _apiService.get(ApiConstants.apiariUrl),
        _apiService.get(ApiConstants.tipiTrattamentoUrl),
      ]);
      final apiariResponse = results[0];
      final tipiTrattamentoResponse = results[1];
      final apiariList = apiariResponse is List
          ? apiariResponse
          : (apiariResponse['results'] as List? ?? []);
      final tipiList = tipiTrattamentoResponse is List
          ? tipiTrattamentoResponse
          : (tipiTrattamentoResponse['results'] as List? ?? []);

      await Future.wait([
        _storageService.saveData('apiari', apiariList),
        _storageService.saveData('tipiTrattamento', tipiList),
      ]);

      if (mounted) {
        setState(() {
          _apiari = apiariList;
          _tipiTrattamento = tipiList;
        });
      }

      if (widget.apiarioId != null) {
        _apiarioId = widget.apiarioId;
        for (var apiario in _apiari) {
          if (apiario['id'] == _apiarioId) {
            _apiarioNome = apiario['nome'];
            break;
          }
        }
        if (widget.arniaId != null) {
          _targetingSpecificArnie = true;
          await _loadArnieForApiario(_apiarioId!);
          _selectedArnieIds = {widget.arniaId!};
        }
      }

      if (widget.trattamentoId != null) {
        final t = await _apiService
            .get('${ApiConstants.trattamentiUrl}${widget.trattamentoId}/');
        setState(() {
          _apiarioId = t['apiario'];
          _apiarioNome = t['apiario_nome'];
          _tipoTrattamentoId = t['tipo_trattamento'];
          _metodoApplicazione = t['metodo_applicazione'] ?? 'altro';
          _dataInizio = DateTime.parse(t['data_inizio']);
          if (t['data_fine'] != null) _dataFine = DateTime.parse(t['data_fine']);
          _note = t['note'] ?? '';
          _bloccoCovataAttivo =
              t['blocco_covata_attivo'] == true || t['blocco_covata_attivo'] == 1;
          if (t['data_inizio_blocco'] != null)
            _dataInizioBlocco = DateTime.parse(t['data_inizio_blocco']);
          if (t['data_fine_blocco'] != null)
            _dataFineBlocco = DateTime.parse(t['data_fine_blocco']);
          _metodoBlocco = t['metodo_blocco'] ?? '';
          _noteBlocco = t['note_blocco'] ?? '';
          if (t['arnie'] != null && (t['arnie'] as List).isNotEmpty) {
            _targetingSpecificArnie = true;
            _selectedArnieIds = Set<int>.from((t['arnie'] as List).cast<int>());
          }
        });
        if (_tipoTrattamentoId != null) _checkBloccoCovataRequirement();
        if (_targetingSpecificArnie && _apiarioId != null) {
          await _loadArnieForApiario(_apiarioId!);
        }
      }

      if (_tipoTrattamentoId != null) _checkBloccoCovataRequirement();
    } catch (e) {
      if (!mounted) return;
      if (_apiari.isEmpty && _tipiTrattamento.isEmpty) {
        setState(() {
          _errorMessage = 'Errore nel caricamento dei dati: $e';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Modalità offline — dati aggiornati all\'ultimo accesso')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadArnieForApiario(int apiarioId) async {
    if (mounted) setState(() => _loadingArnie = true);
    try {
      final response = await _apiService
          .get('${ApiConstants.arnieUrl}?apiario=$apiarioId');
      final list = response is List
          ? response
          : (response['results'] as List? ?? []);
      if (mounted) setState(() => _arnieApiario = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingArnie = false);
    }
  }

  void _checkBloccoCovataRequirement() {
    if (_tipoTrattamentoId == null) return;
    for (var tipo in _tipiTrattamento) {
      if (tipo['id'] == _tipoTrattamentoId) {
        if (tipo['richiede_blocco_covata'] == true && !_bloccoCovataAttivo) {
          setState(() {
            _bloccoCovataAttivo = true;
            if (_dataInizioBlocco == null) _dataInizioBlocco = _dataInizio;
            if (_dataFineBlocco == null &&
                (tipo['giorni_blocco_covata'] ?? 0) > 0) {
              _dataFineBlocco = _dataInizioBlocco!
                  .add(Duration(days: tipo['giorni_blocco_covata']));
            }
            if (_metodoBlocco.isEmpty && tipo['nota_blocco_covata'] != null) {
              _metodoBlocco = 'Ingabbiamento regina';
              _noteBlocco = tipo['nota_blocco_covata'];
            }
          });
        }
        break;
      }
    }
  }

  Future<void> _showCreateTipoDialog() async {
    final formKey = GlobalKey<FormState>();
    final nomeCtrl = TextEditingController();
    final principioAttivoCtrl = TextEditingController();
    final tempoSospensioneCtrl = TextEditingController(text: '0');
    final descrizioneCtrl = TextEditingController();
    bool richiedeBlocco = false;
    int giorniBlocco = 21;
    final giorniBloccoCtrl = TextEditingController(text: '21');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuovo prodotto'),
          scrollable: true,
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nome prodotto — obbligatorio
                  TextFormField(
                    controller: nomeCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nome prodotto *',
                      hintText: 'Es. Acido ossalico, ApiLife VAR...',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
                  ),
                  const SizedBox(height: 12),

                  // Principio attivo — obbligatorio
                  TextFormField(
                    controller: principioAttivoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Principio attivo *',
                      hintText: 'Es. Acido ossalico, Timolo, Flumetrina...',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
                  ),
                  const SizedBox(height: 12),

                  // Tempo di sospensione — default 0, rilevante per sicurezza alimentare
                  TextFormField(
                    controller: tempoSospensioneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Giorni di sospensione',
                      hintText: '0 = nessuna sospensione',
                      border: OutlineInputBorder(),
                      suffixText: 'gg',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (int.tryParse(v.trim()) == null || int.parse(v.trim()) < 0)
                        return 'Inserisci un numero intero ≥ 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Descrizione — opzionale
                  TextFormField(
                    controller: descrizioneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descrizione (opzionale)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),

                  // Richiede blocco covata
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Richiede blocco covata'),
                    value: richiedeBlocco,
                    onChanged: (v) => setDialogState(() => richiedeBlocco = v),
                  ),

                  // Giorni blocco covata — visibile solo se richiede_blocco
                  if (richiedeBlocco) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: giorniBloccoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Durata consigliata blocco',
                        border: OutlineInputBorder(),
                        suffixText: 'gg',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          giorniBlocco = int.tryParse(v) ?? giorniBlocco,
                      validator: (v) {
                        if (!richiedeBlocco) return null;
                        if (v == null || int.tryParse(v.trim()) == null || int.parse(v.trim()) <= 0)
                          return 'Inserisci un numero intero > 0';
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(ctx);
                try {
                  final payload = <String, dynamic>{
                    'nome': nomeCtrl.text.trim(),
                    'principio_attivo': principioAttivoCtrl.text.trim(),
                    'tempo_sospensione':
                        int.tryParse(tempoSospensioneCtrl.text.trim()) ?? 0,
                    'richiede_blocco_covata': richiedeBlocco,
                    'giorni_blocco_covata':
                        richiedeBlocco ? (int.tryParse(giorniBloccoCtrl.text.trim()) ?? 21) : 0,
                  };
                  if (descrizioneCtrl.text.trim().isNotEmpty) {
                    payload['descrizione'] = descrizioneCtrl.text.trim();
                  }

                  final newTipo = await _apiService.post(
                    ApiConstants.tipiTrattamentoUrl,
                    payload,
                  );
                  if (newTipo != null && newTipo['id'] != null) {
                    setState(() {
                      _tipiTrattamento = [..._tipiTrattamento, newTipo];
                      _tipoTrattamentoId = newTipo['id'];
                    });
                    await _storageService.saveData(
                        'tipiTrattamento', _tipiTrattamento);
                    _checkBloccoCovataRequirement();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Errore creazione prodotto: $e')),
                    );
                  }
                }
              },
              child: const Text('Crea'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTrattamento() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();

    if (_apiarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona un apiario')));
      return;
    }
    if (_tipoTrattamentoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona un tipo di trattamento')));
      return;
    }
    if (_targetingSpecificArnie && _selectedArnieIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona almeno un\'arnia')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> data = {
        'apiario': _apiarioId,
        'tipo_trattamento': _tipoTrattamentoId,
        'metodo_applicazione': _metodoApplicazione,
        'data_inizio': dateFormat.format(_dataInizio),
        'stato': 'programmato',
        'note': _note,
        'blocco_covata_attivo': _bloccoCovataAttivo,
      };

      if (_targetingSpecificArnie && _selectedArnieIds.isNotEmpty) {
        data['arnie'] = _selectedArnieIds.toList();
      }
      if (_dataFine != null) data['data_fine'] = dateFormat.format(_dataFine!);
      if (_bloccoCovataAttivo) {
        if (_dataInizioBlocco != null)
          data['data_inizio_blocco'] = dateFormat.format(_dataInizioBlocco!);
        if (_dataFineBlocco != null)
          data['data_fine_blocco'] = dateFormat.format(_dataFineBlocco!);
        data['metodo_blocco'] = _metodoBlocco;
        data['note_blocco'] = _noteBlocco;
      }

      if (widget.trattamentoId != null) {
        await _apiService.put(
            '${ApiConstants.trattamentiUrl}${widget.trattamentoId}/', data);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Trattamento aggiornato')));
      } else {
        await _apiService.post(ApiConstants.trattamentiUrl, data);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Trattamento creato')));
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Errore: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trattamentoId != null
            ? 'Modifica Trattamento'
            : 'Nuovo Trattamento'),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Caricamento dati...')
          : _errorMessage != null
              ? CustomErrorWidget(
                  errorMessage: _errorMessage!, onRetry: _loadInitialData)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildApiarioSection(),
                        const SizedBox(height: 16),
                        _buildTargetSection(),
                        const SizedBox(height: 16),
                        _buildTipoTrattamentoSection(),
                        const SizedBox(height: 16),
                        _buildMetodoSection(),
                        const SizedBox(height: 16),
                        _buildDateSection(),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            hintText: 'Inserisci eventuali note (opzionale)',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _note,
                          maxLines: 3,
                          onSaved: (v) => _note = v ?? '',
                        ),
                        const SizedBox(height: 24),
                        _buildBloccoCovataCard(),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveTrattamento,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: _isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    widget.trattamentoId != null
                                        ? 'AGGIORNA TRATTAMENTO'
                                        : 'CREA TRATTAMENTO',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ──── Apiario ────

  Widget _buildApiarioSection() {
    if (_apiarioId == null) {
      return DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Apiario',
          border: OutlineInputBorder(),
        ),
        hint: const Text('Seleziona un apiario'),
        value: _apiarioId,
        items: _apiari.map<DropdownMenuItem<int>>((a) {
          return DropdownMenuItem<int>(
            value: a['id'] as int,
            child: Text(a['nome'] as String),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _apiarioId = value;
            _apiarioNome = _apiari
                .firstWhere((a) => a['id'] == value,
                    orElse: () => {'nome': ''})['nome'];
            _arnieApiario = [];
            _selectedArnieIds = {};
          });
          if (value != null && _targetingSpecificArnie) {
            _loadArnieForApiario(value);
          }
        },
        validator: (v) => v == null ? 'Seleziona un apiario' : null,
      );
    }
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Apiario',
        border: OutlineInputBorder(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_apiarioNome ?? 'Apiario $_apiarioId'),
          if (widget.apiarioId == null)
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => setState(() {
                _apiarioId = null;
                _apiarioNome = null;
                _arnieApiario = [];
                _selectedArnieIds = {};
              }),
            ),
        ],
      ),
    );
  }

  // ──── Target: tutto apiario vs arnie specifiche ────

  Widget _buildTargetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Applica a',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 6),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Tutto l\'apiario'),
              icon: Icon(Icons.hive),
            ),
            ButtonSegment(
              value: true,
              label: Text('Arnie specifiche'),
              icon: Icon(Icons.select_all),
            ),
          ],
          selected: {_targetingSpecificArnie},
          onSelectionChanged: (s) {
            final v = s.first;
            setState(() {
              _targetingSpecificArnie = v;
              if (v && _apiarioId != null && _arnieApiario.isEmpty) {
                _loadArnieForApiario(_apiarioId!);
              }
              if (!v) _selectedArnieIds = {};
            });
          },
        ),
        if (_targetingSpecificArnie) ...[
          const SizedBox(height: 12),
          _buildArnieSelector(),
        ],
      ],
    );
  }

  Widget _buildArnieSelector() {
    if (_apiarioId == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text('Seleziona prima un apiario',
            style: TextStyle(color: Colors.orange)),
      );
    }
    if (_loadingArnie) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_arnieApiario.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text('Nessuna arnia trovata in questo apiario',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 280,
        child: ApiarioMapWidget(
          arnie: _arnieApiario,
          apiarioId: _apiarioId!,
          selectionMode: true,
          selectedArnieIds: _selectedArnieIds,
          onArniaTap: (id) {
            setState(() {
              if (_selectedArnieIds.contains(id)) {
                _selectedArnieIds.remove(id);
              } else {
                _selectedArnieIds.add(id);
              }
            });
          },
          onAddArnia: () {},
        ),
      ),
    );
  }

  // ──── Tipo trattamento con pulsante "+" ────

  Widget _buildTipoTrattamentoSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Prodotto / Tipo trattamento',
              border: OutlineInputBorder(),
            ),
            hint: const Text('Seleziona un prodotto'),
            value: _tipoTrattamentoId,
            items: _tipiTrattamento.map<DropdownMenuItem<int>>((tipo) {
              return DropdownMenuItem<int>(
                value: tipo['id'] as int,
                child: Text(tipo['nome'] as String),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _tipoTrattamentoId = value);
              _checkBloccoCovataRequirement();
            },
            validator: (v) =>
                v == null ? 'Seleziona un tipo di trattamento' : null,
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Nuovo prodotto',
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: _showCreateTipoDialog,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  // ──── Metodo applicazione ────

  Widget _buildMetodoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Metodo di applicazione',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: _metodiApplicazione.map((m) {
            return ChoiceChip(
              label: Text(_metodiLabels[m]!),
              selected: _metodoApplicazione == m,
              onSelected: (_) => setState(() => _metodoApplicazione = m),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ──── Date ────

  Widget _buildDateSection() {
    return Column(
      children: [
        _buildDatePicker(
          label: 'Data inizio',
          value: _dataInizio,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          onPicked: (d) {
            setState(() {
              _dataInizio = d;
              if (_bloccoCovataAttivo && _dataInizioBlocco == null)
                _dataInizioBlocco = d;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildOptionalDatePicker(
          label: 'Data fine (opzionale)',
          value: _dataFine,
          firstDate: _dataInizio,
          lastDate: DateTime.now().add(const Duration(days: 365)),
          onPicked: (d) => setState(() => _dataFine = d),
          onCleared: () => setState(() => _dataFine = null),
        ),
      ],
    );
  }

  // ──── Blocco covata ────

  Widget _buildBloccoCovataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Blocco di covata',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Blocco covata attivo'),
              value: _bloccoCovataAttivo,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() {
                _bloccoCovataAttivo = v;
                if (v && _dataInizioBlocco == null)
                  _dataInizioBlocco = _dataInizio;
              }),
            ),
            if (_bloccoCovataAttivo) ...[
              const SizedBox(height: 16),
              _buildDatePicker(
                label: 'Data inizio blocco',
                value: _dataInizioBlocco ?? _dataInizio,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onPicked: (d) => setState(() {
                  final oldStart = _dataInizioBlocco;
                  _dataInizioBlocco = d;
                  if (_dataFineBlocco != null && oldStart != null) {
                    final dur = _dataFineBlocco!.difference(oldStart).inDays;
                    _dataFineBlocco = d.add(Duration(days: dur));
                  }
                }),
              ),
              const SizedBox(height: 16),
              _buildOptionalDatePicker(
                label: 'Data fine blocco',
                value: _dataFineBlocco,
                firstDate: _dataInizioBlocco ?? _dataInizio,
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onPicked: (d) => setState(() => _dataFineBlocco = d),
                onCleared: () => setState(() => _dataFineBlocco = null),
                firstDateError: 'Imposta prima la data di inizio blocco',
                requireFirstDate: _dataInizioBlocco == null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Metodo di blocco',
                  hintText: 'Es. ingabbiamento regina, rimozione regina...',
                  border: OutlineInputBorder(),
                ),
                initialValue: _metodoBlocco,
                onSaved: (v) => _metodoBlocco = v ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Note blocco covata',
                  hintText: 'Dettagli aggiuntivi (opzionale)',
                  border: OutlineInputBorder(),
                ),
                initialValue: _noteBlocco,
                maxLines: 3,
                onSaved: (v) => _noteBlocco = v ?? '',
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──── Helper date pickers ────

  Widget _buildDatePicker({
    required String label,
    required DateTime value,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (d != null) onPicked(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dateFormat.format(value)),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionalDatePicker({
    required String label,
    required DateTime? value,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onPicked,
    required VoidCallback onCleared,
    bool requireFirstDate = false,
    String firstDateError = '',
  }) {
    return InkWell(
      onTap: () async {
        if (requireFirstDate) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(firstDateError)));
          return;
        }
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? firstDate.add(const Duration(days: 7)),
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (d != null) onPicked(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value != null ? dateFormat.format(value) : 'Non specificata'),
            Row(children: [
              if (value != null)
                GestureDetector(
                  onTap: onCleared,
                  child: const Icon(Icons.clear, size: 20),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.calendar_today),
            ]),
          ],
        ),
      ),
    );
  }
}

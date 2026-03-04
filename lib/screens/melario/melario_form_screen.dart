import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

class MelarioFormScreen extends StatefulWidget {
  final int? preselectedApiarioId;
  final int? preselectedArniaId;

  const MelarioFormScreen({
    Key? key,
    this.preselectedApiarioId,
    this.preselectedArniaId,
  }) : super(key: key);

  @override
  _MelarioFormScreenState createState() => _MelarioFormScreenState();
}

class _MelarioFormScreenState extends State<MelarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ApiService _apiService;
  late StorageService _storageService;

  List<Map<String, dynamic>> _apiari = [];
  List<Map<String, dynamic>> _arnie = [];
  bool _isLoadingData = true;
  bool _isSaving = false;

  int? _selectedApiarioId;
  int? _selectedArniaId;
  DateTime _dataPosizionamento = DateTime.now();
  int _numeroTelaini = 10;
  int _posizione = 1;
  String _tipoMelario = 'standard';
  String _statoFavi = 'costruiti';
  bool _escludiRegina = true;
  final _noteController = TextEditingController();

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
    // Mostra apiari subito dalla cache
    final cachedApiari = await _storageService.getStoredData('apiari');
    if (cachedApiari.isNotEmpty && mounted) {
      setState(() {
        _apiari = cachedApiari.map((e) => e as Map<String, dynamic>).toList();
        _isLoadingData = false;
      });
    }

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
      if (widget.preselectedApiarioId != null) {
        setState(() => _selectedApiarioId = widget.preselectedApiarioId);
        await _loadArnie(widget.preselectedApiarioId!);
        if (widget.preselectedArniaId != null) {
          setState(() => _selectedArniaId = widget.preselectedArniaId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        if (_apiari.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore nel caricamento: $e')),
          );
        }
        // If apiario was preselected, still try to load arnie from cache
        if (widget.preselectedApiarioId != null) {
          setState(() => _selectedApiarioId = widget.preselectedApiarioId);
          await _loadArnie(widget.preselectedApiarioId!);
          if (widget.preselectedArniaId != null) {
            setState(() => _selectedArniaId = widget.preselectedArniaId);
          }
        }
      }
    }
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
          SnackBar(content: Text('Errore caricamento arnie: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedArniaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona un\'arnia')),
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      await _apiService.post(ApiConstants.melariUrl, {
        'arnia': _selectedArniaId,
        'numero_telaini': _numeroTelaini,
        'posizione': _posizione,
        'data_posizionamento':
            _dataPosizionamento.toIso8601String().split('T')[0],
        'tipo_melario': _tipoMelario,
        'stato_favi': _statoFavi,
        'escludi_regina': _escludiRegina,
        if (_noteController.text.trim().isNotEmpty)
          'note': _noteController.text.trim(),
      });
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Melario aggiunto con successo')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo Melario'),
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
                  tooltip: 'Salva',
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
                    'Identificazione e Tracciabilità',
                    Icons.inventory_2,
                    [
                      _buildApiarioDropdown(),
                      const SizedBox(height: 12),
                      _buildArniaDropdown(),
                      const SizedBox(height: 16),
                      _buildLabel('Tipo Melario'),
                      const SizedBox(height: 6),
                      _buildTipoMelarioSelector(),
                      const SizedBox(height: 16),
                      _buildLabel('Stato dei Favi'),
                      const SizedBox(height: 6),
                      _buildStatoFaviSelector(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCard(
                    'Dati di Produzione',
                    Icons.local_drink,
                    [
                      _buildDataPicker(),
                      const Divider(height: 24),
                      _buildStepper(
                        icon: Icons.view_week,
                        label: 'Numero Telaini',
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
                        label: 'Posizione (dal nido)',
                        value: _posizione,
                        min: 1,
                        max: 5,
                        display: '$_posizione°',
                        onDecrement: () => setState(() => _posizione--),
                        onIncrement: () => setState(() => _posizione++),
                      ),
                      const Divider(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.block),
                        title: const Text('Escludi Regina'),
                        subtitle: const Text(
                            'Posiziona un escludiregina per evitare covata'),
                        value: _escludiRegina,
                        onChanged: (v) => setState(() => _escludiRegina = v),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Note aggiuntive',
                          border: OutlineInputBorder(),
                          hintText: 'Osservazioni, fioritura in corso...',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Aggiungi Melario'),
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

  Widget _buildApiarioDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedApiarioId,
      decoration: const InputDecoration(
          labelText: 'Apiario *', border: OutlineInputBorder()),
      items: _apiari
          .map((a) => DropdownMenuItem<int>(
                value: a['id'] as int,
                child: Text(a['nome']?.toString() ?? 'Apiario ${a["id"]}'),
              ))
          .toList(),
      onChanged: (id) {
        setState(() {
          _selectedApiarioId = id;
          _selectedArniaId = null;
          _arnie = [];
        });
        if (id != null) _loadArnie(id);
      },
      validator: (v) => v == null ? 'Seleziona un apiario' : null,
    );
  }

  Widget _buildArniaDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedArniaId,
      decoration: InputDecoration(
        labelText: 'Arnia *',
        border: const OutlineInputBorder(),
        hintText: _selectedApiarioId == null
            ? 'Seleziona prima un apiario'
            : _arnie.isEmpty
                ? 'Nessuna arnia disponibile'
                : null,
      ),
      items: _arnie
          .map((a) => DropdownMenuItem<int>(
                value: a['id'] as int,
                child: Text('Arnia ${a["numero"] ?? a["id"]}'),
              ))
          .toList(),
      onChanged: _selectedApiarioId == null
          ? null
          : (id) => setState(() => _selectedArniaId = id),
      validator: (v) => v == null ? 'Seleziona un\'arnia' : null,
    );
  }

  Widget _buildTipoMelarioSelector() {
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
      onSelectionChanged: (s) => setState(() => _tipoMelario = s.first),
    );
  }

  Widget _buildStatoFaviSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
            value: 'costruiti',
            label: Text('Già costruiti'),
            icon: Icon(Icons.check_circle_outline, size: 16)),
        ButtonSegment(
            value: 'fogli_cerei',
            label: Text('Fogli cerei'),
            icon: Icon(Icons.radio_button_unchecked, size: 16)),
      ],
      selected: {_statoFavi},
      onSelectionChanged: (s) => setState(() => _statoFavi = s.first),
    );
  }

  Widget _buildDataPicker() {
    final d = _dataPosizionamento;
    final formatted =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today),
      title: const Text('Data posizionamento'),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/statistiche_service.dart';
import '../../../services/api_service.dart';
import '../nl_query/risultato_query_widget.dart';

class QueryBuilderTab extends StatefulWidget {
  const QueryBuilderTab({super.key});

  @override
  State<QueryBuilderTab> createState() => _QueryBuilderTabState();
}

class _QueryBuilderTabState extends State<QueryBuilderTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final StatisticheService _service;
  int _currentStep = 0;
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  // Step 1
  String? _entitaSelezionata;

  // Step 2 - filtri
  String? _dataDa;
  String? _dataA;
  String _aggregazione = 'count';
  String _raggruppa = 'mese';

  // Step 3
  String _visualizzazione = 'bar_chart';

  static const _entita = [
    {'id': 'controlli',  'label': 'Controlli arnie',   'icon': Icons.search},
    {'id': 'smielature', 'label': 'Smielature',         'icon': Icons.water_drop},
    {'id': 'regine',     'label': 'Regine',             'icon': Icons.local_florist},
    {'id': 'vendite',    'label': 'Vendite',            'icon': Icons.store},
    {'id': 'spese',      'label': 'Spese',              'icon': Icons.receipt},
    {'id': 'fioriture',  'label': 'Fioriture',          'icon': Icons.eco},
    {'id': 'arnie',      'label': 'Arnie',              'icon': Icons.hive},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service = StatisticheService(Provider.of<ApiService>(context, listen: false));
  }

  Future<void> _eseguiQuery() async {
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final payload = {
        'entita': _entitaSelezionata,
        'filtri': {
          if (_dataDa != null) 'data_da': _dataDa,
          if (_dataA != null) 'data_a': _dataA,
        },
        'aggregazione': _aggregazione,
        'raggruppa_per': _raggruppa,
        'visualizzazione': _visualizzazione,
      };
      final result = await _service.eseguiQueryBuilder(payload);
      setState(() { _result = result; _loading = false; _currentStep = 2; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stepper(
            currentStep: _currentStep,
            onStepTapped: (s) => setState(() => _currentStep = s),
            controlsBuilder: (context, details) => Row(
              children: [
                if (details.currentStep < 2)
                  ElevatedButton(
                    onPressed: _currentStep == 0 && _entitaSelezionata == null
                        ? null
                        : () {
                            if (_currentStep == 1) {
                              _eseguiQuery();
                            } else {
                              setState(() => _currentStep++);
                            }
                          },
                    child: Text(_currentStep == 1 ? 'Esegui analisi' : 'Avanti'),
                  ),
                if (details.currentStep > 0) ...[
                  const SizedBox(width: 8),
                  TextButton(onPressed: () => setState(() => _currentStep--), child: const Text('Indietro')),
                ],
              ],
            ),
            steps: [
              // Step 1: Scegli entità
              Step(
                title: const Text('Cosa analizzare?'),
                isActive: _currentStep >= 0,
                state: _entitaSelezionata != null ? StepState.complete : StepState.indexed,
                content: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _entita.map((e) => ChoiceChip(
                    label: Text(e['label'] as String),
                    avatar: Icon(e['icon'] as IconData, size: 16),
                    selected: _entitaSelezionata == e['id'],
                    onSelected: (_) => setState(() { _entitaSelezionata = e['id'] as String; _currentStep = 1; }),
                  )).toList(),
                ),
              ),

              // Step 2: Filtri e aggregazione
              Step(
                title: const Text('Filtri e aggregazione'),
                isActive: _currentStep >= 1,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _DateField(label: 'Data da', onChanged: (v) => setState(() => _dataDa = v))),
                        const SizedBox(width: 8),
                        Expanded(child: _DateField(label: 'Data a', onChanged: (v) => setState(() => _dataA = v))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _aggregazione,
                      decoration: const InputDecoration(labelText: 'Aggregazione', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'count', child: Text('Conteggio')),
                        DropdownMenuItem(value: 'sum', child: Text('Somma')),
                        DropdownMenuItem(value: 'avg', child: Text('Media')),
                        DropdownMenuItem(value: 'none', child: Text('Nessuna (tabella)')),
                      ],
                      onChanged: (v) => setState(() => _aggregazione = v!),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _raggruppa,
                      decoration: const InputDecoration(labelText: 'Raggruppa per', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'mese', child: Text('Mese')),
                        DropdownMenuItem(value: 'anno', child: Text('Anno')),
                      ],
                      onChanged: (v) => setState(() => _raggruppa = v!),
                    ),
                  ],
                ),
              ),

              // Step 3: Risultati
              Step(
                title: const Text('Risultati'),
                isActive: _currentStep >= 2,
                content: _buildRisultati(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRisultati() {
    if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    if (_error != null) return Text('Errore: $_error', style: const TextStyle(color: Colors.red));
    if (_result == null) return const Text('Esegui l\'analisi per vedere i risultati');

    // Selezione visualizzazione
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'bar_chart', icon: Icon(Icons.bar_chart), label: Text('Barre')),
            ButtonSegment(value: 'line_chart', icon: Icon(Icons.show_chart), label: Text('Linea')),
            ButtonSegment(value: 'table', icon: Icon(Icons.table_chart), label: Text('Tabella')),
          ],
          selected: {_visualizzazione},
          onSelectionChanged: (s) => setState(() => _visualizzazione = s.first),
        ),
        const SizedBox(height: 12),
        RisultatoQueryWidget(result: _result!, visualizzazione: _visualizzazione),
      ],
    );
  }
}

class _DateField extends StatefulWidget {
  final String label;
  final ValueChanged<String?> onChanged;
  const _DateField({required this.label, required this.onChanged});

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(labelText: widget.label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today, size: 18)),
      readOnly: true,
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2018),
          lastDate: DateTime(2030),
        );
        if (d != null) {
          final formatted = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          _controller.text = formatted;
          widget.onChanged(formatted);
        }
      },
    );
  }
}

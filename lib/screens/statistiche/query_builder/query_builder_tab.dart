import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/statistiche_service.dart';
import '../../../services/language_service.dart';
import '../../../l10n/app_strings.dart';
import '../nl_query/risultato_query_widget.dart';

class QueryBuilderTab extends StatefulWidget {
  const QueryBuilderTab({super.key});

  @override
  State<QueryBuilderTab> createState() => _QueryBuilderTabState();
}

class _QueryBuilderTabState extends State<QueryBuilderTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  StatisticheService? _service;
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

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  List<Map<String, dynamic>> get _entita => [
    {'id': 'controlli',  'label': _s.queryBuilderEntitaControlli,  'icon': Icons.search},
    {'id': 'smielature', 'label': _s.queryBuilderEntitaSmielature, 'icon': Icons.water_drop},
    {'id': 'regine',     'label': _s.queryBuilderEntitaRegine,     'icon': Icons.local_florist},
    {'id': 'vendite',    'label': _s.queryBuilderEntitaVendite,    'icon': Icons.store},
    {'id': 'spese',      'label': _s.queryBuilderEntitaSpese,      'icon': Icons.receipt},
    {'id': 'fioriture',  'label': _s.queryBuilderEntitaFioriture,  'icon': Icons.eco},
    {'id': 'arnie',      'label': _s.queryBuilderEntitaArnie,      'icon': Icons.hive},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service ??= context.read<StatisticheService>();
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
      final result = await _service!.eseguiQueryBuilder(payload);
      setState(() { _result = result; _loading = false; _currentStep = 2; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Provider.of<LanguageService>(context);
    final s = _s;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stepper(
            currentStep: _currentStep,
            onStepTapped: (step) => setState(() => _currentStep = step),
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
                    child: Text(_currentStep == 1 ? s.queryBuilderEseguiAnalisi : s.queryBuilderAvanti),
                  ),
                if (details.currentStep > 0) ...[
                  const SizedBox(width: 8),
                  TextButton(onPressed: () => setState(() => _currentStep--), child: Text(s.queryBuilderIndietro)),
                ],
              ],
            ),
            steps: [
              // Step 1: Scegli entità
              Step(
                title: Text(s.queryBuilderStepAnalizzare),
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
                title: Text(s.queryBuilderStepFiltri),
                isActive: _currentStep >= 1,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _DateField(label: s.queryBuilderDataDa, onChanged: (v) => setState(() => _dataDa = v))),
                        const SizedBox(width: 8),
                        Expanded(child: _DateField(label: s.queryBuilderDataA, onChanged: (v) => setState(() => _dataA = v))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _aggregazione,
                      decoration: InputDecoration(labelText: s.queryBuilderAggregazione, border: const OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(value: 'count', child: Text(s.queryBuilderAggCount)),
                        DropdownMenuItem(value: 'sum', child: Text(s.queryBuilderAggSum)),
                        DropdownMenuItem(value: 'avg', child: Text(s.queryBuilderAggAvg)),
                        DropdownMenuItem(value: 'none', child: Text(s.queryBuilderAggNone)),
                      ],
                      onChanged: (v) { if (v != null) setState(() => _aggregazione = v); },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _raggruppa,
                      decoration: InputDecoration(labelText: s.queryBuilderRaggruppaPer, border: const OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(value: 'mese', child: Text(s.queryBuilderRaggruppaMese)),
                        DropdownMenuItem(value: 'anno', child: Text(s.queryBuilderRagruppaAnno)),
                      ],
                      onChanged: (v) { if (v != null) setState(() => _raggruppa = v); },
                    ),
                  ],
                ),
              ),

              // Step 3: Risultati
              Step(
                title: Text(s.queryBuilderStepRisultati),
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
    final s = _s;
    if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    if (_error != null) return Text(s.queryBuilderErrore(_error!), style: const TextStyle(color: Colors.red));
    if (_result == null) return Text(s.queryBuilderRunFirst);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'bar_chart', icon: const Icon(Icons.bar_chart), label: Text(s.queryBuilderVizBarre)),
            ButtonSegment(value: 'line_chart', icon: const Icon(Icons.show_chart), label: Text(s.queryBuilderVizLinea)),
            ButtonSegment(value: 'table', icon: const Icon(Icons.table_chart), label: Text(s.queryBuilderVizTabella)),
          ],
          selected: {_visualizzazione},
          onSelectionChanged: (sel) => setState(() => _visualizzazione = sel.first),
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

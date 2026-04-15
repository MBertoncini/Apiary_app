// lib/screens/attrezzatura/attrezzature_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/attrezzatura.dart';
import '../../services/attrezzatura_service.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/drawer_widget.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/skeleton_widgets.dart';

// ---------------------------------------------------------------------------
// Smart local categorisation (no server category needed)
// ---------------------------------------------------------------------------

enum SmartCategoria {
  apiario,
  consumabile,
  protezione,
  strumento,
  altro,
}

extension SmartCategoriaExt on SmartCategoria {
  String get label {
    switch (this) {
      case SmartCategoria.apiario:    return 'Apiario';
      case SmartCategoria.consumabile: return 'Consumabili';
      case SmartCategoria.protezione: return 'Protezione';
      case SmartCategoria.strumento:  return 'Strumenti';
      case SmartCategoria.altro:      return 'Altro';
    }
  }

  IconData get icon {
    switch (this) {
      case SmartCategoria.apiario:    return Icons.hive;
      case SmartCategoria.consumabile: return Icons.science_outlined;
      case SmartCategoria.protezione: return Icons.health_and_safety_outlined;
      case SmartCategoria.strumento:  return Icons.straighten;
      case SmartCategoria.altro:      return Icons.build_outlined;
    }
  }

  Color get color {
    switch (this) {
      case SmartCategoria.apiario:    return const Color(0xFFF59E0B); // amber
      case SmartCategoria.consumabile: return const Color(0xFF10B981); // emerald
      case SmartCategoria.protezione: return const Color(0xFF3B82F6); // blue
      case SmartCategoria.strumento:  return const Color(0xFF8B5CF6); // violet
      case SmartCategoria.altro:      return const Color(0xFF6B7280); // gray
    }
  }
}

// Keyword lists (lowercase, partial match)
const _apiarioKw = [
  'arnia', 'alveare', 'melario', 'telaino', 'telai', 'apiscampo',
  'escludi', 'escludiregina', 'escludi-regina', 'leva', 'affumicatore',
  'fumigatore', 'portasciame', 'sciame', 'gabbietta', 'gabbia',
  'nutritore', 'posa', 'opercolo', 'disopercolo', 'uncino',
  'coltello', 'apiario', 'ape', 'queen', 'regina', 'spazzola',
  'smielatore', 'centrifuga', 'maturatore', 'filtro miele',
  'vasetto', 'barattolo',
];

const _consumabileKw = [
  'antivarroa', 'apibioxal', 'apivar', 'calistrip', 'oxalic',
  'ossalico', 'timolo', 'apiguard', 'maqs', 'acido', 'fogli cerei',
  'foglio cereo', 'cera', 'candito', 'sciroppo', 'zucchero',
  'alimentazione', 'colla', 'trappola', 'veleno', 'formico',
  'amitraz', 'coumafos', 'apistan', 'bayvarol',
];

const _protezioneKw = [
  'tuta', 'guant', 'maschera', 'velo', 'cappello', 'stival',
  'dpi', 'protezione', 'visiera', 'gilett',
];

const _strumentoKw = [
  'refractometr', 'bilancia', 'termometro', 'igrometro', 'microscopio',
  'contatore', 'timer', 'misuratore', 'igrometro', 'strumento',
  'rilevatore', 'sensore',
];

SmartCategoria detectCategoria(Attrezzatura a) {
  final text =
      '${a.nome} ${a.categoriaNome ?? ''} ${a.descrizione ?? ''}'.toLowerCase();

  bool has(List<String> kws) => kws.any((k) => text.contains(k));

  if (has(_protezioneKw)) return SmartCategoria.protezione;
  if (has(_consumabileKw)) return SmartCategoria.consumabile;
  if (has(_strumentoKw))   return SmartCategoria.strumento;
  if (has(_apiarioKw))     return SmartCategoria.apiario;
  return SmartCategoria.altro;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AttrezzatureListScreen extends StatefulWidget {
  @override
  _AttrezzatureListScreenState createState() => _AttrezzatureListScreenState();
}

class _AttrezzatureListScreenState extends State<AttrezzatureListScreen> {
  List<Attrezzatura> _attrezzature = [];
  bool _isRefreshing = false;
  bool _cacheChecked = false;
  String? _errorMessage;

  // --- filters ---
  final _searchController = TextEditingController();
  String _searchQuery = '';

  SmartCategoria? _filtroCategoria; // null = all

  // advanced filters (bottom sheet)
  String?   _filtroStato;
  String?   _filtroCondizione;
  DateTime? _dataAcquistoDa;
  DateTime? _dataAcquistoA;
  double?   _prezzoDa;
  double?   _prezzoA;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Data loading
  // -----------------------------------------------------------------------

  Future<void> _loadData() async {
    if (!mounted) return;
    _errorMessage = null;

    final storageService = Provider.of<StorageService>(context, listen: false);
    final apiService     = Provider.of<ApiService>(context, listen: false);

    // Phase 1: cache — read before any setState so skeleton doesn't flash
    try {
      final cached = await storageService.getStoredData('attrezzature');
      if (cached.isNotEmpty) {
        _attrezzature = cached.map((e) => Attrezzatura.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Cache attrezzature: $e');
    }
    if (mounted) setState(() { _cacheChecked = true; _isRefreshing = true; });

    // Phase 2: API
    try {
      final svc = AttrezzaturaService(apiService);
      final fresh = await svc.getAttrezzature();
      await storageService.saveData('attrezzature', fresh.map((a) => a.toJson()).toList());
      _attrezzature = fresh;
    } catch (e) {
      debugPrint('API attrezzature: $e');
      if (_attrezzature.isEmpty) {
        _errorMessage = '${Provider.of<LanguageService>(context, listen: false).strings.attrezzaturaErrLoading}: $e';
      }
    }
    if (mounted) setState(() { _isRefreshing = false; });
  }

  // -----------------------------------------------------------------------
  // Filtering
  // -----------------------------------------------------------------------

  List<Attrezzatura> get _filtered {
    return _attrezzature.where((a) {
      // search
      if (_searchQuery.isNotEmpty) {
        final hay =
            '${a.nome} ${a.marca ?? ''} ${a.modello ?? ''} '
            '${a.descrizione ?? ''} ${a.categoriaNome ?? ''} '
            '${a.fornitore ?? ''}'.toLowerCase();
        if (!hay.contains(_searchQuery)) return false;
      }
      // smart category
      if (_filtroCategoria != null && detectCategoria(a) != _filtroCategoria) {
        return false;
      }
      // stato
      if (_filtroStato != null && a.stato != _filtroStato) return false;
      // condizione
      if (_filtroCondizione != null && a.condizione != _filtroCondizione) return false;
      // date range
      if (_dataAcquistoDa != null && (a.dataAcquisto == null ||
          a.dataAcquisto!.isBefore(_dataAcquistoDa!))) { return false; }
      if (_dataAcquistoA != null && (a.dataAcquisto == null ||
          a.dataAcquisto!.isAfter(_dataAcquistoA!))) { return false; }
      // price range
      if (_prezzoDa != null && (a.prezzoAcquisto == null ||
          a.prezzoAcquisto! < _prezzoDa!)) { return false; }
      if (_prezzoA != null && (a.prezzoAcquisto == null ||
          a.prezzoAcquisto! > _prezzoA!)) { return false; }
      return true;
    }).toList();
  }

  int get _activeAdvancedFilters {
    int n = 0;
    if (_filtroStato != null)     n++;
    if (_filtroCondizione != null) n++;
    if (_dataAcquistoDa != null || _dataAcquistoA != null) n++;
    if (_prezzoDa != null || _prezzoA != null) n++;
    return n;
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  String _catLabel(SmartCategoria cat, dynamic s) {
    switch (cat) {
      case SmartCategoria.apiario:     return labelApiario ?? 'Apiario';
      case SmartCategoria.consumabile: return s.attrezzaturaCatConsumabili;
      case SmartCategoria.protezione:  return s.attrezzaturaCatProtezione;
      case SmartCategoria.strumento:   return s.attrezzaturaCatStrumenti;
      case SmartCategoria.altro:       return s.attrezzaturaCatAltro;
    }
  }

  String? get labelApiario => null; // resolved via LanguageService in build

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final s = Provider.of<LanguageService>(context).strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.attrezzatureTitle),
        actions: [
          // Advanced filters button with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: s.attrezzatureFiltriAvanzatiTooltip,
                onPressed: _showAdvancedFilters,
              ),
              if (_activeAdvancedFilters > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ThemeConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_activeAdvancedFilters',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: s.attrezzatureSincronizzaTooltip,
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.attrezzatureRoute),
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: s.attrezzaturaSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

          // Category chip row
          _buildCategoryChips(s),

          // List
          Expanded(
            child: !_cacheChecked
                ? const SizedBox.shrink()
                : _isRefreshing && _attrezzature.isEmpty
                ? const SkeletonListView(itemCount: 5)
                : _errorMessage != null
                    ? ErrorDisplayWidget(
                        errorMessage: _errorMessage!,
                        onRetry: _loadData,
                      )
                    : _buildList(filtered, s),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(
          context, AppConstants.attrezzaturaCreateRoute,
        ).then((_) => _loadData()),
        tooltip: s.attrezzaturaFabTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryChips(dynamic s) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _categoryChip(null, Icons.apps, s.attrezzaturaCatTutti, Colors.grey),
          ...SmartCategoria.values.map(
            (c) => _categoryChip(c, c.icon, _catLabel(c, s), c.color),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(SmartCategoria? cat, IconData icon, String label, Color color) {
    final selected = _filtroCategoria == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: selected,
        avatar: Icon(icon, size: 16, color: selected ? Colors.white : color),
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
        selectedColor: color,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filtroCategoria = selected ? null : cat),
      ),
    );
  }

  Widget _buildList(List<Attrezzatura> filtered, dynamic s) {
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _attrezzature.isEmpty
                  ? s.attrezzaturaNoRegistrata
                  : s.attrezzaturaNoFiltri,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_attrezzature.isEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(s.attrezzaturaBtnAggiungi),
                onPressed: () => Navigator.pushNamed(
                  context, AppConstants.attrezzaturaCreateRoute,
                ).then((_) => _loadData()),
              )
            else
              TextButton.icon(
                icon: const Icon(Icons.filter_list_off),
                label: Text(s.attrezzaturaBtnRimuoviFiltri),
                onPressed: _resetAllFilters,
              ),
          ],
        ),
      );
    }

    final fmtCur  = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final fmtDate = DateFormat('dd/MM/yyyy');

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final a = filtered[index];
          final cat = detectCategoria(a);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cat.color.withValues(alpha: 0.15),
                child: Icon(cat.icon, color: cat.color),
              ),
              title: Text(
                a.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _catLabel(cat, Provider.of<LanguageService>(context, listen: false).strings),
                          style: TextStyle(fontSize: 11, color: cat.color, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        Provider.of<LanguageService>(context, listen: false).strings.attrezzaturaQta(a.quantita),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  if (a.marca != null || a.modello != null)
                    Text(
                      [a.marca, a.modello].whereType<String>().join(' – '),
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (a.dataAcquisto != null)
                    Text(
                      Provider.of<LanguageService>(context, listen: false).strings.attrezzaturaAcquistatoDate(fmtDate.format(a.dataAcquisto!)),
                      style: const TextStyle(fontSize: 11),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (a.prezzoAcquisto != null && a.prezzoAcquisto! > 0)
                    Text(
                      fmtCur.format(a.prezzoAcquisto),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ThemeConstants.primaryColor,
                        fontSize: 13,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statoColor(a.stato).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      a.getStatoDisplay(s),
                      style: TextStyle(
                        fontSize: 10,
                        color: _statoColor(a.stato),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (a.condizione != null)
                    Text(
                      a.getCondizioneDisplay(s),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                ],
              ),
              isThreeLine: true,
              onTap: () => Navigator.pushNamed(
                context,
                AppConstants.attrezzaturaDetailRoute,
                arguments: a.id,
              ).then((_) => _loadData()),
            ),
          );
        },
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Advanced filter bottom sheet
  // -----------------------------------------------------------------------

  Future<void> _showAdvancedFilters() async {
    String? tempStato      = _filtroStato;
    String? tempCondizione = _filtroCondizione;
    DateTime? tempDa       = _dataAcquistoDa;
    DateTime? tempA        = _dataAcquistoA;
    final prezzoDaCtrl = TextEditingController(text: _prezzoDa?.toStringAsFixed(0) ?? '');
    final prezzoACtrl  = TextEditingController(text: _prezzoA?.toStringAsFixed(0) ?? '');

    final fmtDate = DateFormat('dd/MM/yyyy');

    final s = Provider.of<LanguageService>(context, listen: false).strings;

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.attrezzaturaFiltriAvanzatiTitle,
                        style: Theme.of(ctx).textTheme.titleLarge),
                    TextButton(
                      onPressed: () {
                        setSheet(() {
                          tempStato = null;
                          tempCondizione = null;
                          tempDa = null;
                          tempA = null;
                          prezzoDaCtrl.clear();
                          prezzoACtrl.clear();
                        });
                      },
                      child: Text(s.attrezzaturaFiltriReset),
                    ),
                  ],
                ),
                const Divider(),

                // Stato
                DropdownButtonFormField<String>(
                  value: tempStato,
                  decoration: InputDecoration(
                    labelText: s.attrezzaturaFiltriLblStato,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  hint: Text(s.attrezzaturaCatTutti),
                  items: [
                    DropdownMenuItem(value: null, child: Text(s.attrezzaturaCatTutti)),
                    ...Attrezzatura.statiDisponibili.map(
                      (st) => DropdownMenuItem(
                        value: st,
                        child: Text(st.replaceAll('_', ' ').capitalize()),
                      ),
                    ),
                  ],
                  onChanged: (v) => setSheet(() => tempStato = v),
                ),
                const SizedBox(height: 12),

                // Condizione
                DropdownButtonFormField<String>(
                  value: tempCondizione,
                  decoration: InputDecoration(
                    labelText: s.attrezzaturaFiltriLblCondizione,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  hint: Text(s.attrezzaturaCatTutte),
                  items: [
                    DropdownMenuItem(value: null, child: Text(s.attrezzaturaCatTutte)),
                    ...Attrezzatura.condizioniDisponibili.map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.replaceAll('_', ' ').capitalize()),
                      ),
                    ),
                  ],
                  onChanged: (v) => setSheet(() => tempCondizione = v),
                ),
                const SizedBox(height: 12),

                // Date range
                Text(s.attrezzaturaFiltriLblDataAcquisto, style: Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          tempDa != null ? fmtDate.format(tempDa!) : 'Dal',
                          style: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: tempDa ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setSheet(() => tempDa = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          tempA != null ? fmtDate.format(tempA!) : 'Al',
                          style: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: tempA ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setSheet(() => tempA = picked);
                        },
                      ),
                    ),
                    if (tempDa != null || tempA != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setSheet(() { tempDa = null; tempA = null; }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price range
                Text(s.attrezzaturaFiltriLblPrezzo, style: Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: prezzoDaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixText: '€ ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: prezzoACtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixText: '€ ',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _filtroStato      = tempStato;
                        _filtroCondizione = tempCondizione;
                        _dataAcquistoDa   = tempDa;
                        _dataAcquistoA    = tempA;
                        _prezzoDa = double.tryParse(prezzoDaCtrl.text);
                        _prezzoA  = double.tryParse(prezzoACtrl.text);
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(s.attrezzaturaFiltriApplica),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
    prezzoDaCtrl.dispose();
    prezzoACtrl.dispose();
  }

  void _resetAllFilters() {
    setState(() {
      _searchController.clear();
      _filtroCategoria  = null;
      _filtroStato      = null;
      _filtroCondizione = null;
      _dataAcquistoDa   = null;
      _dataAcquistoA    = null;
      _prezzoDa         = null;
      _prezzoA          = null;
    });
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  Color _statoColor(String? stato) {
    switch (stato) {
      case 'disponibile': return Colors.green;
      case 'in_uso':      return Colors.blue;
      case 'manutenzione': return Colors.orange;
      case 'dismesso':    return Colors.grey;
      case 'prestato':    return Colors.purple;
      default:            return Colors.grey;
    }
  }
}

extension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

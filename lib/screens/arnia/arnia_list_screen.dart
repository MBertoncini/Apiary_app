import 'package:flutter/material.dart';
import '../../widgets/drawer_widget.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../models/arnia.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/hive_frame_visualizer.dart';
import '../../database/dao/controllo_arnia_dao.dart';
import '../../services/controllo_service.dart';
import '../../widgets/skeleton_widgets.dart';

// ─── Mappa tipo → nome leggibile e icona emoji ───────────────────────────────
const Map<String, Map<String, String>> _tipiInfo = {
  'dadant':             {'nome': 'Dadant-Blatt',                    'icona': '🏠'},
  'langstroth':         {'nome': 'Langstroth',                      'icona': '📦'},
  'top_bar':            {'nome': 'Top Bar',                         'icona': '🛖'},
  'warre':              {'nome': 'Warré',                           'icona': '🗼'},
  'osservazione':       {'nome': 'Osservazione',                    'icona': '🔭'},
  'pappa_reale':        {'nome': 'Pappa Reale',                     'icona': '👑'},
  'nucleo_legno':       {'nome': 'Nucleo Legno',                    'icona': '📫'},
  'nucleo_polistirolo': {'nome': 'Nucleo Polistirolo',              'icona': '📮'},
  'portasciami':        {'nome': 'Portasciami',                     'icona': '🪤'},
  'apidea':             {'nome': 'Apidea / Kieler',                 'icona': '🔹'},
  'mini_plus':          {'nome': 'Mini-Plus',                       'icona': '🔸'},
};

// ─── Categorie di arnie ───────────────────────────────────────────────────────
class _Categoria {
  final String label;
  final IconData icon;
  final Color color;
  final List<String> types;
  const _Categoria({required this.label, required this.icon, required this.color, required this.types});
}

const _categorie = [
  _Categoria(
    label: 'Arnie',
    icon: Icons.hive,
    color: Color(0xFFD3A121),
    types: ['dadant', 'langstroth', 'top_bar', 'warre', 'osservazione'],
  ),
  _Categoria(
    label: 'Nuclei',
    icon: Icons.inbox,
    color: Color(0xFF688148),
    types: ['nucleo_legno', 'nucleo_polistirolo', 'apidea', 'mini_plus'],
  ),
  _Categoria(
    label: 'Speciali',
    icon: Icons.star_outline,
    color: Color(0xFF8B5E00),
    types: ['pappa_reale', 'portasciami'],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

class ArniaListScreen extends StatefulWidget {
  @override
  _ArniaListScreenState createState() => _ArniaListScreenState();
}

class _ArniaListScreenState extends State<ArniaListScreen> {
  late ApiService _apiService;
  late StorageService _storageService;
  Map<String, List<Arnia>> _arnieByApiario = {};
  bool _isLoading = true;
  bool _isRefreshing = true;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _refreshArnie();
  }

  Map<String, List<Arnia>> _groupArnie(List<Arnia> arnie) {
    final Map<String, List<Arnia>> byApiario = {};
    for (var arnia in arnie) {
      byApiario.putIfAbsent(arnia.apiarioNome, () => []).add(arnia);
    }
    byApiario.forEach((_, list) => list.sort((a, b) => a.numero.compareTo(b.numero)));
    return byApiario;
  }

  List<Arnia> _parseArnieResponse(dynamic response) {
    if (response is List) return response.map((item) => Arnia.fromJson(item)).toList();
    if (response is Map && response.containsKey('results') && response['results'] is List) {
      return (response['results'] as List).map((item) => Arnia.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> _refreshArnie() async {
    // Fase 1: cache — mostra subito
    final cachedArnie = await _storageService.getStoredData('arnie');
    if (cachedArnie.isNotEmpty) {
      final arnie = cachedArnie.map((item) => Arnia.fromJson(item)).toList();
      _arnieByApiario = _groupArnie(arnie);
      _isLoading = false;
      if (mounted) setState(() { _isRefreshing = true; });
    } else {
      if (mounted) setState(() { _isRefreshing = true; });
    }

    // Fase 2: aggiornamento dal server
    try {
      final results = await Future.wait([
        _apiService.get(ApiConstants.arnieUrl),
        _apiService.get(ApiConstants.apiariUrl),
      ]);
      List<Arnia> arnie = _parseArnieResponse(results[0]);

      // Aggiorna nomi apiario dalle risposte API
      final apiariRaw = results[1];
      final Map<int, dynamic> apiariMap = {};
      if (apiariRaw is List) {
        for (var a in apiariRaw) { apiariMap[a['id']] = a; }
      } else if (apiariRaw is Map && apiariRaw.containsKey('results')) {
        for (var a in apiariRaw['results']) { apiariMap[a['id']] = a; }
      }
      if (apiariMap.isNotEmpty) {
        arnie = arnie.map((a) {
          if (apiariMap.containsKey(a.apiario)) {
            return Arnia(
              id: a.id,
              apiario: a.apiario,
              apiarioNome: apiariMap[a.apiario]['nome'],
              numero: a.numero,
              colore: a.colore,
              coloreHex: a.coloreHex,
              tipoArnia: a.tipoArnia, // ← conserva il tipo
              dataInstallazione: a.dataInstallazione,
              note: a.note,
              attiva: a.attiva,
            );
          }
          return a;
        }).toList();
      }

      if (arnie.isNotEmpty) {
        await _storageService.saveData('arnie', arnie.map((a) => a.toJson()).toList());
        _arnieByApiario = _groupArnie(arnie);
      }
    } catch (e) {
      debugPrint('Error fetching arnie from API: $e');
    }

    if (mounted) setState(() { _isLoading = false; _isRefreshing = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Le mie Arnie'),
      ),
      drawer: AppDrawer(currentRoute: AppConstants.arniaListRoute),
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _isLoading
                ? const SkeletonListView(itemCount: 5)
                : _arnieByApiario.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _refreshArnie,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _arnieByApiario.keys.length,
                          itemBuilder: (context, index) {
                            final apiarioNome = _arnieByApiario.keys.elementAt(index);
                            return ApiarioGroupWidget(
                              apiarioNome: apiarioNome,
                              arnie: _arnieByApiario[apiarioNome] ?? [],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.of(context).pushNamed(AppConstants.creaArniaRoute),
        tooltip: 'Aggiungi arnia',
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hive_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Nessuna arnia trovata',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Non hai ancora creato arnie o non è stato possibile caricarle',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Crea arnia'),
            onPressed: () => Navigator.of(context).pushNamed(AppConstants.creaArniaRoute),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Riprova a caricare'),
            onPressed: _refreshArnie,
          ),
        ],
      ),
    );
  }
}

// ─── Gruppo per apiario ───────────────────────────────────────────────────────

class ApiarioGroupWidget extends StatefulWidget {
  final String apiarioNome;
  final List<Arnia> arnie;

  const ApiarioGroupWidget({
    required this.apiarioNome,
    required this.arnie,
  });

  @override
  _ApiarioGroupWidgetState createState() => _ApiarioGroupWidgetState();
}

class _ApiarioGroupWidgetState extends State<ApiarioGroupWidget> {
  bool _isExpanded = true;

  int get _totale => widget.arnie.length;

  @override
  Widget build(BuildContext context) {
    // Conta arnie attive per il badge nell'intestazione
    final attive = widget.arnie.where((a) => a.attiva).length;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Intestazione apiario ─────────────────────────────────
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: ThemeConstants.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.apiarioNome,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '$attive/$_totale attive',
                    style: TextStyle(color: ThemeConstants.textSecondaryColor, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            // Legenda telaini
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: HiveFrameVisualizer.legend(),
            ),

            // Sezioni per categoria
            for (final cat in _categorie) _buildCategoriaSection(cat),

            // Catch-all: tipi non in nessuna categoria (es. valori custom dal server)
            _buildAltriSection(),
          ],
        ],
      ),
    );
  }

  static final _tuttiITipi = _categorie.expand((c) => c.types).toSet();

  Widget _buildAltriSection() {
    final altri = widget.arnie.where((a) => !_tuttiITipi.contains(a.tipoArnia)).toList();
    if (altri.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.device_unknown_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              const Text('Altri', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(width: 6),
              Text('(${altri.length})', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: altri.length,
          itemBuilder: (context, i) => ArniaListItem(arnia: altri[i]),
        ),
      ],
    );
  }

  Widget _buildCategoriaSection(_Categoria cat) {
    final arnieCat = widget.arnie.where((a) => cat.types.contains(a.tipoArnia)).toList();
    if (arnieCat.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header categoria ────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: cat.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: cat.color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(cat.icon, size: 16, color: cat.color),
              const SizedBox(width: 6),
              Text(
                cat.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cat.color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${arnieCat.length})',
                style: TextStyle(fontSize: 12, color: cat.color.withOpacity(0.8)),
              ),
            ],
          ),
        ),

        // ── Lista arnie della categoria ─────────────────────────────
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: arnieCat.length,
          itemBuilder: (context, i) => ArniaListItem(arnia: arnieCat[i]),
        ),
      ],
    );
  }
}

// ─── Singola arnia ────────────────────────────────────────────────────────────

class ArniaListItem extends StatefulWidget {
  final Arnia arnia;
  const ArniaListItem({required this.arnia});

  @override
  _ArniaListItemState createState() => _ArniaListItemState();
}

class _ArniaListItemState extends State<ArniaListItem> {
  final _dao = ControlloArniaDao();
  Map<String, dynamic>? _ultimoControllo;

  @override
  void initState() {
    super.initState();
    _loadUltimoControllo();
  }

  Future<void> _loadUltimoControllo() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await ControlloService(apiService).getControlliByArnia(widget.arnia.id);
    } catch (e) {
      debugPrint('Error syncing controllo for arnia ${widget.arnia.id}: $e');
    }
    final c = await _dao.getLatestByArnia(widget.arnia.id);
    if (mounted) setState(() => _ultimoControllo = c);
  }

  Color _colorFromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Color _contrast(Color bg) =>
      bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  @override
  Widget build(BuildContext context) {
    final arniaColor = _colorFromHex(widget.arnia.coloreHex);
    final tipoInfo = _tipiInfo[widget.arnia.tipoArnia];
    final tipoLabel = tipoInfo != null
        ? '${tipoInfo['icona']} ${tipoInfo['nome']}'
        : widget.arnia.tipoArnia;

    return InkWell(
      onTap: () => Navigator.of(context)
          .pushNamed(AppConstants.arniaDetailRoute, arguments: widget.arnia.id)
          .then((_) => _loadUltimoControllo()),
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Riga principale ──────────────────────────────────
              Row(
                children: [
                  // Badge numero
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: arniaColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        widget.arnia.numero.toString(),
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: _contrast(arniaColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nome + tipo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arnia ${widget.arnia.numero}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        Text(
                          tipoLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeConstants.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge stato
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.arnia.attiva
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.arnia.attiva ? 'Attiva' : 'Inattiva',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.arnia.attiva
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
                  Icon(Icons.navigate_next, color: ThemeConstants.textSecondaryColor),
                ],
              ),

              // ── Riepilogo ultimo controllo ───────────────────────
              if (_ultimoControllo != null) ...[
                const SizedBox(height: 4),
                _ControlloSummary(controllo: _ultimoControllo!),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  'Nessun controllo registrato',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                ),
              ],

              // ── Visualizzatore telaini ───────────────────────────
              const SizedBox(height: 6),
              HiveFrameVisualizer(controllo: _ultimoControllo),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Riepilogo rapido dell'ultimo controllo ───────────────────────────────────

class _ControlloSummary extends StatelessWidget {
  final Map<String, dynamic> controllo;
  const _ControlloSummary({required this.controllo});

  String _formatData(String? iso) {
    if (iso == null || iso.isEmpty) return '–';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso; // non-null garantito dal check iniziale
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _formatData(controllo['data'] as String?);
    final problemi  = controllo['problemi_sanitari'] == 1 || controllo['problemi_sanitari'] == true;
    final sciamatura = controllo['sciamatura'] == 1 || controllo['sciamatura'] == true;

    return Row(
      children: [
        Icon(Icons.calendar_today, size: 11, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Text(
          'Controllo: $data',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        if (problemi) ...[
          const SizedBox(width: 8),
          _Chip(icon: '⚠', label: 'Problemi', color: Colors.red.shade800),
        ],
        if (sciamatura) ...[
          const SizedBox(width: 4),
          _Chip(icon: '🐝', label: 'Sciamatura', color: Colors.amber.shade800),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$icon $label',
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

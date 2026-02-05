import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/regina.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class ReginaDetailScreen extends StatefulWidget {
  final int reginaId;

  const ReginaDetailScreen({Key? key, required this.reginaId}) : super(key: key);

  @override
  _ReginaDetailScreenState createState() => _ReginaDetailScreenState();
}

class _ReginaDetailScreenState extends State<ReginaDetailScreen> with SingleTickerProviderStateMixin {
  late ApiService _apiService;
  late TabController _tabController;

  Regina? _regina;
  Map<String, dynamic>? _genealogia;
  bool _isLoading = true;
  bool _isLoadingGenealogia = true;
  String? _errorMessage;
  String? _genealogiaError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _apiService = Provider.of<ApiService>(context, listen: false);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.get('${ApiConstants.regineUrl}${widget.reginaId}/');
      debugPrint('Regina detail API response: $response');

      setState(() {
        _regina = Regina.fromJson(response);
        _isLoading = false;
      });

      // Carica la genealogia in parallelo
      _loadGenealogia();
    } catch (e) {
      debugPrint('Errore caricamento regina: $e');
      setState(() {
        _errorMessage = 'Errore nel caricamento della regina: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGenealogia() async {
    setState(() {
      _isLoadingGenealogia = true;
      _genealogiaError = null;
    });

    try {
      final url = ApiConstants.replaceParams(
        ApiConstants.reginaGenealogiaUrl,
        {'regina_id': widget.reginaId.toString()},
      );
      final response = await _apiService.get(url);
      debugPrint('Genealogia API response: $response');

      setState(() {
        _genealogia = response is Map<String, dynamic> ? response : null;
        _isLoadingGenealogia = false;
      });
    } catch (e) {
      debugPrint('Errore caricamento genealogia: $e');
      setState(() {
        _genealogiaError = 'Dati genealogia non disponibili';
        _isLoadingGenealogia = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Dettaglio Regina')),
        body: LoadingWidget(message: 'Caricamento regina...'),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Dettaglio Regina')),
        body: ErrorDisplayWidget(
          errorMessage: _errorMessage!,
          onRetry: _loadData,
        ),
      );
    }

    if (_regina == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Dettaglio Regina')),
        body: Center(child: Text('Nessun dato trovato per questa regina')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Regina - Arnia ${_regina!.arniaNumero ?? _regina!.arniaId}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Dettagli'),
            Tab(text: 'Genealogia'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDettagliTab(),
          _buildGenealogiaTab(),
        ],
      ),
    );
  }

  // ==================== TAB DETTAGLI ====================
  Widget _buildDettagliTab() {
    final regina = _regina!;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReginaHeader(regina),
            const SizedBox(height: 24),
            _buildInfoSection('Informazioni Generali', [
              _buildInfoRow('Arnia', 'Arnia ${regina.arniaNumero ?? regina.arniaId}'),
              _buildInfoRow('Razza', _getRazzaDisplay(regina.razza)),
              _buildInfoRow('Origine', _getOrigineDisplay(regina.origine)),
              if (regina.dataNascita != null)
                _buildInfoRow('Data nascita', regina.dataNascita!),
              _buildInfoRow('Data introduzione', regina.dataInserimento),
              _buildInfoRow('Fecondata', regina.fecondata ? 'Si' : 'No'),
              _buildInfoRow('Selezionata', regina.selezionata ? 'Si' : 'No'),
            ]),
            const SizedBox(height: 16),
            _buildInfoSection('Marcatura', [
              _buildInfoRow('Marcata', regina.marcata ? 'Si' : 'No'),
              if (regina.marcata && regina.colore != null && regina.colore != 'non_marcata')
                _buildInfoRow('Colore marcatura', _getColoreMarcaturaDisplay(regina.colore!)),
              if (regina.codiceMarcatura != null && regina.codiceMarcatura!.isNotEmpty)
                _buildInfoRow('Codice marcatura', regina.codiceMarcatura!),
            ]),
            if (regina.docilita != null ||
                regina.produttivita != null ||
                regina.resistenzaMalattie != null ||
                regina.tendenzaSciamatura != null) ...[
              const SizedBox(height: 16),
              _buildRatingSection('Valutazioni', [
                if (regina.docilita != null)
                  _buildRatingRow('Docilita', regina.docilita!),
                if (regina.produttivita != null)
                  _buildRatingRow('Produttivita', regina.produttivita!),
                if (regina.resistenzaMalattie != null)
                  _buildRatingRow('Resistenza malattie', regina.resistenzaMalattie!),
                if (regina.tendenzaSciamatura != null)
                  _buildRatingRow('Tendenza sciamatura', regina.tendenzaSciamatura!),
              ]),
            ],
            if (regina.note != null && regina.note!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoSection('Note', [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(regina.note!),
                ),
              ]),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.edit),
                  label: Text('Modifica'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Funzionalita di modifica non ancora implementata')),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.swap_horiz),
                  label: Text('Sostituisci'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Funzionalita di sostituzione non ancora implementata')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB GENEALOGIA ====================
  Widget _buildGenealogiaTab() {
    if (_isLoadingGenealogia) {
      return LoadingWidget(message: 'Caricamento genealogia...');
    }

    if (_genealogiaError != null && _genealogia == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _genealogiaError!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Riprova'),
              onPressed: _loadGenealogia,
            ),
          ],
        ),
      );
    }

    if (_genealogia == null || _genealogia!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nessun dato genealogico disponibile',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGenealogia,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header genealogia
            Card(
              color: Colors.deepPurple.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.account_tree, color: Colors.deepPurple, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Albero Genealogico',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lignaggio della regina dell\'arnia ${_regina!.arniaNumero ?? _regina!.arniaId}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Regina attuale
            _buildGenealogiaReginaCard(
              'Regina Attuale',
              _genealogia!,
              Colors.amber,
              Icons.star,
              isCurrentQueen: true,
            ),

            // Madre
            if (_genealogia!['madre'] != null) ...[
              _buildGenealogiaConnector(),
              _buildGenealogiaReginaCard(
                'Madre',
                _genealogia!['madre'],
                Colors.pink,
                Icons.favorite,
              ),
            ],

            // Nonna materna
            if (_genealogia!['nonna_materna'] != null) ...[
              _buildGenealogiaConnector(),
              _buildGenealogiaReginaCard(
                'Nonna Materna',
                _genealogia!['nonna_materna'],
                Colors.purple,
                Icons.elderly_woman,
              ),
            ],

            // Figlie
            if (_genealogia!['figlie'] != null &&
                (_genealogia!['figlie'] as List).isNotEmpty) ...[
              const SizedBox(height: 24),
              Divider(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'Figlie (${(_genealogia!['figlie'] as List).length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...(_genealogia!['figlie'] as List).map<Widget>((figlia) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildGenealogiaReginaCard(
                    'Figlia',
                    figlia,
                    Colors.teal,
                    Icons.child_care,
                  ),
                );
              }).toList(),
            ],

            // Sorelle
            if (_genealogia!['sorelle'] != null &&
                (_genealogia!['sorelle'] as List).isNotEmpty) ...[
              const SizedBox(height: 24),
              Divider(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'Sorelle (${(_genealogia!['sorelle'] as List).length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...(_genealogia!['sorelle'] as List).map<Widget>((sorella) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildGenealogiaReginaCard(
                    'Sorella',
                    sorella,
                    Colors.indigo,
                    Icons.people,
                  ),
                );
              }).toList(),
            ],

            // Dati aggiuntivi genealogia (chiavi non standard)
            ..._buildExtraGenealogiaFields(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Costruisce card per ogni parente nella genealogia, gestendo in modo flessibile
  /// qualsiasi formato di dati il server invii
  Widget _buildGenealogiaReginaCard(
    String parentela,
    dynamic data,
    Color color,
    IconData icon, {
    bool isCurrentQueen = false,
  }) {
    // Se data e' una mappa, estraiamo i campi
    if (data is Map<String, dynamic>) {
      final String razza = data['razza'] ?? '';
      final String origine = data['origine'] ?? '';
      final String? dataIntro = data['data_introduzione'] ?? data['data_inserimento'];
      final String? dataNascita = data['data_nascita'];
      final String? arniaNum = data['arnia_numero']?.toString();
      final int? arniaId = data['arnia'] ?? data['arnia_id'];
      final int? id = data['id'];
      final bool? marcata = data['marcata'];
      final String? coloreMarcatura = data['colore_marcatura'];
      final bool? fecondata = data['fecondata'];
      final bool? selezionata = data['selezionata'];
      final String? note = data['note'];
      final bool? attiva = data['is_attiva'] ?? data['attiva'];

      return Card(
        elevation: isCurrentQueen ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isCurrentQueen
              ? BorderSide(color: color, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: id != null && !isCurrentQueen
              ? () {
                  Navigator.of(context).pushNamed(
                    '/regina/detail',
                    arguments: id,
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con icona e parentela
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parentela,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          if (arniaNum != null || arniaId != null)
                            Text(
                              'Arnia ${arniaNum ?? arniaId}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                    if (attiva == true)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Attiva', style: TextStyle(fontSize: 11, color: Colors.green[700])),
                      ),
                    if (attiva == false)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Non attiva', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ),
                    if (id != null && !isCurrentQueen)
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 12),

                // Dettagli in wrap chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (razza.isNotEmpty)
                      _buildChip(_getRazzaDisplay(razza), Icons.bug_report, Colors.brown),
                    if (origine.isNotEmpty)
                      _buildChip(_getOrigineDisplay(origine), Icons.source, Colors.blue),
                    if (dataIntro != null)
                      _buildChip('Introdotta: $dataIntro', Icons.calendar_today, Colors.teal),
                    if (dataNascita != null)
                      _buildChip('Nata: $dataNascita', Icons.cake, Colors.pink),
                    if (marcata == true)
                      _buildChip(
                        'Marcata${coloreMarcatura != null && coloreMarcatura != "non_marcata" ? " ($coloreMarcatura)" : ""}',
                        Icons.colorize,
                        _getMarkerColor(coloreMarcatura),
                      ),
                    if (fecondata == true)
                      _buildChip('Fecondata', Icons.favorite, Colors.red),
                    if (selezionata == true)
                      _buildChip('Selezionata', Icons.verified, Colors.green),
                  ],
                ),

                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    note,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Se data non e' una mappa, visualizza come testo
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 12),
            Text('$parentela: $data'),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.9)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenealogiaConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 24,
            color: Colors.grey[300],
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_downward, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  /// Costruisce campi extra della genealogia che non sono nelle chiavi standard
  List<Widget> _buildExtraGenealogiaFields() {
    if (_genealogia == null) return [];

    final standardKeys = {'id', 'arnia', 'arnia_id', 'arnia_numero', 'razza', 'origine',
      'data_introduzione', 'data_inserimento', 'data_nascita', 'data_rimozione',
      'note', 'is_attiva', 'attiva', 'marcata', 'colore_marcatura', 'codice_marcatura',
      'fecondata', 'selezionata', 'docilita', 'produttivita', 'resistenza_malattie',
      'tendenza_sciamatura', 'madre', 'nonna_materna', 'figlie', 'sorelle'};

    final extraKeys = _genealogia!.keys.where((k) => !standardKeys.contains(k)).toList();

    if (extraKeys.isEmpty) return [];

    List<Widget> widgets = [
      const SizedBox(height: 24),
      Divider(),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          'Informazioni Aggiuntive',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
      ),
      const SizedBox(height: 8),
    ];

    for (final key in extraKeys) {
      final value = _genealogia![key];
      if (value == null) continue;

      // Se il valore e' una lista di mappe (es. altre regine)
      if (value is List && value.isNotEmpty && value.first is Map) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 8),
            child: Text(
              _formatFieldName(key) + ' (${value.length})',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey),
            ),
          ),
        );
        for (final item in value) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildGenealogiaReginaCard(
                _formatFieldName(key),
                item,
                Colors.blueGrey,
                Icons.local_florist,
              ),
            ),
          );
        }
      } else if (value is Map<String, dynamic>) {
        // Se il valore e' una singola mappa (un'altra regina)
        widgets.add(
          _buildGenealogiaReginaCard(
            _formatFieldName(key),
            value,
            Colors.blueGrey,
            Icons.local_florist,
          ),
        );
      } else {
        // Se il valore e' un tipo semplice
        widgets.add(
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
                  SizedBox(width: 8),
                  Text(
                    '${_formatFieldName(key)}: $value',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  String _formatFieldName(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  Color _getMarkerColor(String? colore) {
    switch (colore) {
      case 'bianco': return Colors.grey;
      case 'giallo': return Colors.amber;
      case 'rosso': return Colors.red;
      case 'verde': return Colors.green;
      case 'blu': return Colors.blue;
      default: return Colors.grey;
    }
  }

  // ==================== WIDGETS COMUNI ====================
  Widget _buildReginaHeader(Regina regina) {
    Color reginaColor;

    switch (regina.colore) {
      case 'bianco':
        reginaColor = Colors.white;
        break;
      case 'giallo':
        reginaColor = Colors.amber;
        break;
      case 'rosso':
        reginaColor = Colors.red;
        break;
      case 'verde':
        reginaColor = Colors.green;
        break;
      case 'blu':
        reginaColor = Colors.blue;
        break;
      case 'non_marcata':
      default:
        reginaColor = Colors.grey;
        break;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: reginaColor,
              child: regina.marcata
                  ? Icon(Icons.local_florist, color: _getContrastColor(reginaColor), size: 36)
                  : Icon(Icons.local_florist_outlined, color: _getContrastColor(reginaColor), size: 36),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Regina dell\'arnia ${regina.arniaNumero ?? regina.arniaId}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRazzaDisplay(regina.razza),
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  if (regina.dataNascita != null)
                    Text(
                      'Eta: ${_calculateAge(regina.dataNascita!)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRatingRow(String label, int rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: index < rating ? Colors.amber : Colors.grey,
                  size: 20,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _getRazzaDisplay(String razza) {
    switch (razza) {
      case 'ligustica':
        return 'Italiana (Ligustica)';
      case 'carnica':
        return 'Carnica';
      case 'buckfast':
        return 'Buckfast';
      case 'caucasica':
        return 'Caucasica';
      case 'sicula':
        return 'Siciliana';
      case 'ibrida':
        return 'Ibrida';
      case 'altro':
        return 'Altro';
      default:
        return razza.isNotEmpty ? razza : 'N/D';
    }
  }

  String _getOrigineDisplay(String origine) {
    switch (origine) {
      case 'acquistata':
        return 'Acquistata';
      case 'allevata':
        return 'Allevata';
      case 'sciamatura':
        return 'Sciamatura Naturale';
      case 'emergenza':
        return 'Celle di Emergenza';
      case 'sconosciuta':
        return 'Sconosciuta';
      default:
        return origine.isNotEmpty ? origine : 'N/D';
    }
  }

  String _getColoreMarcaturaDisplay(String colore) {
    switch (colore) {
      case 'bianco':
        return 'Bianco (anni terminanti in 1,6)';
      case 'giallo':
        return 'Giallo (anni terminanti in 2,7)';
      case 'rosso':
        return 'Rosso (anni terminanti in 3,8)';
      case 'verde':
        return 'Verde (anni terminanti in 4,9)';
      case 'blu':
        return 'Blu (anni terminanti in 5,0)';
      case 'non_marcata':
        return 'Non Marcata';
      default:
        return colore;
    }
  }

  String _calculateAge(String birthDateString) {
    try {
      final birthDate = DateTime.parse(birthDateString);
      final now = DateTime.now();

      final difference = now.difference(birthDate);
      final years = (difference.inDays / 365).floor();
      final months = ((difference.inDays % 365) / 30).floor();

      if (years > 0) {
        return '$years ${years == 1 ? 'anno' : 'anni'}';
      } else if (months > 0) {
        return '$months ${months == 1 ? 'mese' : 'mesi'}';
      } else {
        return '${difference.inDays} ${difference.inDays == 1 ? 'giorno' : 'giorni'}';
      }
    } catch (e) {
      return 'N/D';
    }
  }

  Color _getContrastColor(Color backgroundColor) {
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

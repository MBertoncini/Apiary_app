import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../constants/app_constants.dart';
import '../../l10n/app_strings.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../models/regina.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/skeleton_widgets.dart';
import '../../widgets/beehive_illustrations.dart';
import 'regina_form_screen.dart';

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
  bool _isRefreshing = false;
  bool _cacheChecked = false;
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
    if (!mounted) return;
    _errorMessage = null;

    final storageService = Provider.of<StorageService>(context, listen: false);

    // Fase 1: cache — leggi prima di setState per evitare flash skeleton
    try {
      final cachedRaw = await storageService.getStoredData('regine');
      final cachedMap = cachedRaw.cast<Map<String, dynamic>>().firstWhere(
        (r) => r['id'] == widget.reginaId,
        orElse: () => <String, dynamic>{},
      );
      if (cachedMap.isNotEmpty) {
        _regina = Regina.fromJson(cachedMap);
      }
    } catch (e) {
      debugPrint('Cache regine: $e');
    }
    if (mounted) setState(() { _cacheChecked = true; _isRefreshing = true; });

    // Fase 2: server
    try {
      final response = await _apiService.get('${ApiConstants.regineUrl}${widget.reginaId}/');
      if (!mounted) return;
      final regina = Regina.fromJson(response);

      // Aggiorna cache
      final cachedRaw = await storageService.getStoredData('regine');
      final list = cachedRaw.cast<Map<String, dynamic>>().toList();
      final idx = list.indexWhere((r) => r['id'] == widget.reginaId);
      if (idx >= 0) {
        list[idx] = response as Map<String, dynamic>;
      } else {
        list.add(response as Map<String, dynamic>);
      }
      await storageService.saveData('regine', list);

      if (mounted) setState(() { _regina = regina; _isRefreshing = false; });
      _loadGenealogia();
    } catch (e) {
      debugPrint('Errore caricamento regina: $e');
      if (mounted) {
        setState(() {
          if (_regina == null) _errorMessage = 'Errore nel caricamento della regina: $e';
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadGenealogia() async {
    if (!mounted) return;
    setState(() {
      _isLoadingGenealogia = true;
      _genealogiaError = null;
    });

    try {
      final response = await _apiService.get(
        '${ApiConstants.regineUrl}${widget.reginaId}/genealogy/',
      );
      debugPrint('Genealogia API response: $response');

      if (!mounted) return;
      setState(() {
        _genealogia = response is Map<String, dynamic> ? response : null;
        _isLoadingGenealogia = false;
      });
    } catch (e) {
      debugPrint('Errore caricamento genealogia: $e');
      if (!mounted) return;
      setState(() {
        _genealogiaError = 'Dati genealogia non disponibili';
        _isLoadingGenealogia = false;
      });
    }
  }

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;

    if (!_cacheChecked) {
      return Scaffold(
        appBar: AppBar(title: Text(s.reginaDetailTitle)),
        body: const SizedBox.shrink(),
      );
    }

    if (_isRefreshing && _regina == null && _errorMessage == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.reginaDetailTitle)),
        body: const SingleChildScrollView(child: SkeletonDetailHeader()),
      );
    }

    if (_errorMessage != null && _regina == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.reginaDetailTitle)),
        body: ErrorDisplayWidget(
          errorMessage: _errorMessage!,
          onRetry: _loadData,
        ),
      );
    }

    if (_regina == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.reginaDetailTitle)),
        body: Center(child: Text(s.reginaDetailNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.reginaDetailTitleArnia((_regina!.arniaNumero ?? _regina!.arniaId).toString())),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: s.reginaDetailTooltipDelete,
            onPressed: _confirmDeleteRegina,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.reginaDetailTabDettagli),
            Tab(text: s.reginaDetailTabGenealogia),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDettagliTab(),
                _buildGenealogiaTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB DETTAGLI ====================
  Widget _buildDettagliTab() {
    final s = _s;
    final regina = _regina!;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (regina.sospettaAssente)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.reginaDetailSospettaAssenteMsg,
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            _buildReginaHeader(s, regina),
            const SizedBox(height: 24),
            _buildInfoSection(s.reginaDetailSectionGeneral, [
              _buildInfoRow(s.labelArnia, '${s.labelArnia} ${regina.arniaNumero ?? regina.arniaId}'),
              _buildInfoRow(s.reginaListRazza, _getRazzaDisplay(s, regina.razza)),
              _buildInfoRow(s.reginaListOrigine, _getOrigineDisplay(s, regina.origine)),
              if (regina.dataNascita != null)
                _buildInfoRow(s.reginaDetailLblDataNascita, regina.dataNascita!),
              _buildInfoRow(s.reginaFormLblDataIntroduzione, regina.dataInserimento),
              _buildInfoRow(s.reginaFormFecondataTitle, regina.fecondata ? s.labelYes : s.labelNo),
              _buildInfoRow(s.reginaDetailLblSelezionata, regina.selezionata ? s.labelYes : s.labelNo),
            ]),
            const SizedBox(height: 16),
            _buildInfoSection(s.reginaDetailSectionMarcatura, [
              _buildInfoRow(s.reginaFormMarcataTitle, regina.marcata ? s.labelYes : s.labelNo),
              if (regina.marcata && regina.colore != null && regina.colore != 'non_marcata')
                _buildInfoRow(s.reginaFormLblColoreMarcatura, _getColoreMarcaturaDisplay(s, regina.colore!)),
              if (regina.codiceMarcatura != null && regina.codiceMarcatura!.isNotEmpty)
                _buildInfoRow(s.reginaDetailLblCodiceMarcatura, regina.codiceMarcatura!),
            ]),
            if (regina.docilita != null ||
                regina.produttivita != null ||
                regina.resistenzaMalattie != null ||
                regina.tendenzaSciamatura != null) ...[
              const SizedBox(height: 16),
              _buildRatingSection(s.arniaDetailLblValutazioni, [
                if (regina.docilita != null)
                  _buildRatingRow(s.arniaDetailRatingDocilita, regina.docilita!),
                if (regina.produttivita != null)
                  _buildRatingRow(s.arniaDetailRatingProduttivita, regina.produttivita!),
                if (regina.resistenzaMalattie != null)
                  _buildRatingRow(s.arniaDetailRatingResistenza, regina.resistenzaMalattie!),
                if (regina.tendenzaSciamatura != null)
                  _buildRatingRow(s.arniaDetailRatingTendenzaSciamatura, regina.tendenzaSciamatura!),
              ]),
            ],
            if (regina.note != null && regina.note!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoSection(s.labelNotes, [
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
                  icon: const Icon(Icons.edit),
                  label: Text(s.reginaDetailBtnEdit),
                  onPressed: _editRegina,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(s.reginaDetailBtnReplace),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _showSostituisciDialog,
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
    final s = _s;

    if (_isLoadingGenealogia) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_genealogiaError != null && _genealogia == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              s.reginaDetailGenealogiaNonDisp,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(s.reginaDetailBtnRetry),
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
              s.reginaDetailNoGenealogia,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGenealogia,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
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
                    const Icon(Icons.account_tree, color: Colors.deepPurple, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.reginaDetailAlberoGenealogia,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.reginaDetailAlberoSubtitle((_regina!.arniaNumero ?? _regina!.arniaId).toString()),
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
              s.reginaDetailReginaAttuale,
              _genealogia!,
              Colors.amber,
              Icons.star,
              isCurrentQueen: true,
            ),

            // Madre
            if (_genealogia!['madre'] != null) ...[
              _buildGenealogiaConnector(),
              _buildGenealogiaReginaCard(
                s.arniaDetailLblMadre,
                _genealogia!['madre'],
                Colors.pink,
                Icons.favorite,
              ),
            ],

            // Figlie
            if (_genealogia!['figlie'] != null &&
                (_genealogia!['figlie'] as List).isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  s.reginaDetailFiglie((_genealogia!['figlie'] as List).length),
                  style: const TextStyle(
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
                    s.arniaDetailLblFiglie,
                    figlia,
                    Colors.teal,
                    Icons.child_care,
                  ),
                );
              }).toList(),
            ],

            // Storia nelle arnie
            if (_genealogia!['storia_arnia'] != null &&
                (_genealogia!['storia_arnia'] as List).isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  s.reginaDetailStoriaArnie,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...(_genealogia!['storia_arnia'] as List).map<Widget>((entry) {
                final m = entry as Map<String, dynamic>;
                final arniaNum = m['arnia_numero']?.toString() ?? m['arnia']?.toString() ?? '?';
                final inizio = m['data_inizio'] ?? '';
                final fine = m['data_fine'];
                final motivo = m['motivo_fine'];
                final nota = m['note'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.home, size: 18, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Text(
                              '${s.labelArnia} $arniaNum',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            if (fine == null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(s.reginaDetailStatusAttuale, style: TextStyle(fontSize: 11, color: Colors.green[700])),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${s.reginaDetailLblDal}: $inizio', style: const TextStyle(fontSize: 13)),
                        if (fine != null)
                          Text('${s.reginaDetailLblAl}: $fine', style: const TextStyle(fontSize: 13)),
                        if (motivo != null && motivo.toString().isNotEmpty)
                          Text('${s.reginaDetailLblMotivoCambio}: $motivo', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        if (nota != null && nota.toString().isNotEmpty)
                          Text(nota.toString(), style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic)),
                      ],
                    ),
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
                    AppConstants.reginaDetailRoute,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_s.reginaDetailStatusAttiva, style: TextStyle(fontSize: 11, color: Colors.green[700])),
                      ),
                    if (attiva == false)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_s.reginaDetailStatusNonAttiva, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
                      _buildChip(_getRazzaDisplay(_s, razza), Icons.bug_report, Colors.brown),
                    if (origine.isNotEmpty)
                      _buildChip(_getOrigineDisplay(_s, origine), Icons.source, Colors.blue),
                    if (dataIntro != null)
                      _buildChip(_s.reginaDetailChipIntrodotta(dataIntro), Icons.calendar_today, Colors.teal),
                    if (dataNascita != null)
                      _buildChip(_s.reginaDetailChipNata(dataNascita), Icons.cake, Colors.pink),
                    if (marcata == true)
                      _buildChip(
                        '${_s.reginaFormMarcataTitle}${coloreMarcatura != null && coloreMarcatura != "non_marcata" ? " ($coloreMarcatura)" : ""}',
                        Icons.colorize,
                        _getMarkerColor(coloreMarcatura),
                      ),
                    if (fecondata == true)
                      _buildChip(_s.reginaFormFecondataTitle, Icons.favorite, Colors.red),
                    if (selezionata == true)
                      _buildChip(_s.reginaDetailLblSelezionata, Icons.verified, Colors.green),
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
      'tendenza_sciamatura', 'madre', 'figlie', 'storia_arnia'};

    final extraKeys = _genealogia!.keys.where((k) => !standardKeys.contains(k)).toList();

    if (extraKeys.isEmpty) return [];

    final s = _s;
    List<Widget> widgets = [
      const SizedBox(height: 24),
      const Divider(),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          s.reginaDetailInfoAggiuntive,
          style: const TextStyle(
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
  Widget _buildReginaHeader(AppStrings s, Regina regina) {
    final Color inkColor = regina.marcata ? reginaInkColorFor(regina.colore) : Colors.grey;
    final Color avatarBg = (regina.colore == 'bianco' ? Colors.grey : inkColor).withOpacity(0.2);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: avatarBg,
              child: HandDrawnQueenBee(size: 42, color: inkColor),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.reginaListItemTitle((regina.arniaNumero ?? regina.arniaId).toString()),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRazzaDisplay(s, regina.razza),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  if (regina.dataNascita != null)
                    Text(
                      s.reginaDetailLblEta(_calculateAge(s, regina.dataNascita!)),
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

  String _getRazzaDisplay(AppStrings s, String razza) {
    switch (razza) {
      case 'ligustica':  return 'Apis mellifera ligustica';
      case 'carnica':    return 'Apis mellifera carnica';
      case 'buckfast':   return 'Buckfast';
      case 'caucasica':  return 'Apis mellifera caucasica';
      case 'sicula':     return 'Apis mellifera sicula';
      default:           return razza.isNotEmpty ? razza : s.labelNa;
    }
  }

  String _getOrigineDisplay(AppStrings s, String origine) {
    switch (origine) {
      case 'acquistata':  return s.arniaDetailOrigineAcquistata;
      case 'allevata':    return s.arniaDetailOrigineAllevata;
      case 'sciamatura':  return s.arniaDetailOrigineSciamatura;
      case 'emergenza':   return s.arniaDetailOrigineEmergenza;
      case 'sconosciuta': return s.arniaDetailOrigineSconosciuta;
      default:            return origine.isNotEmpty ? origine : s.labelNa;
    }
  }

  String _getColoreMarcaturaDisplay(AppStrings s, String colore) {
    switch (colore) {
      case 'bianco':      return s.reginaDetailColoreBianco;
      case 'giallo':      return s.reginaDetailColoreGiallo;
      case 'rosso':       return s.reginaDetailColoreRosso;
      case 'verde':       return s.reginaDetailColoreVerde;
      case 'blu':         return s.reginaDetailColoreBlu;
      case 'non_marcata': return s.reginaDetailColoreNonMarcata;
      default:            return colore;
    }
  }

  String _calculateAge(AppStrings s, String birthDateString) {
    try {
      final birthDate = DateTime.parse(birthDateString);
      final now = DateTime.now();
      final difference = now.difference(birthDate);
      final years = (difference.inDays / 365).floor();
      final months = ((difference.inDays % 365) / 30).floor();

      if (years > 0) return s.reginaDetailAgeAnni(years);
      if (months > 0) return s.reginaDetailAgeMesi(months);
      return s.reginaDetailAgeGiorni(difference.inDays);
    } catch (_) {
      return s.labelNa;
    }
  }

  Future<void> _editRegina() async {
    if (_regina == null) return;
    // Costruiamo il payload includendo l'id della regina madre (oggi non
    // serializzato in toJson() di default), così il form pre-popola la
    // dropdown e un PUT non azzera l'associazione.
    final reginaData = _regina!.toJson();
    if (_regina!.reginaMadreId != null) {
      reginaData['regina_madre'] = _regina!.reginaMadreId;
    }
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReginaFormScreen(
          arniaId: _regina!.arniaId,
          coloniaId: _regina!.coloniaId,
          reginaData: reginaData,
          reginaId: widget.reginaId,
        ),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _showSostituisciDialog() async {
    if (_regina == null) return;
    final s = _s;
    final fmt = DateFormat('yyyy-MM-dd');
    String motivoFine = 'sostituzione';
    DateTime dataFine = DateTime.now();
    bool isLoading = false;

    final motiviOptions = [
      {'id': 'sostituzione',      'label': s.arniaDetailChangeMotivoSostituzione},
      {'id': 'morte',             'label': s.arniaDetailChangeMotivoMorte},
      {'id': 'sciamatura',        'label': s.arniaDetailChangeMotivoSciamatura},
      {'id': 'problema_sanitario','label': s.arniaDetailChangeMotivoProblemaSanitario},
      {'id': 'altro',             'label': s.arniaDetailChangeMotivoAltro},
    ];

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.reginaDetailReplaceTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                s.arniaDetailReplaceReginaMsg,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                    labelText: s.reginaDetailLblMotivo, border: const OutlineInputBorder()),
                value: motivoFine,
                items: motiviOptions
                    .map((m) => DropdownMenuItem(
                        value: m['id'], child: Text(m['label']!)))
                    .toList(),
                onChanged: (v) => setSheetState(() => motivoFine = v!),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dataFine,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setSheetState(() => dataFine = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                      labelText: s.reginaDetailLblDataRimozione, border: const OutlineInputBorder()),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fmt.format(dataFine)),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white),
                onPressed: isLoading
                    ? null
                    : () async {
                        setSheetState(() => isLoading = true);
                        try {
                          await _apiService.post(
                            '${ApiConstants.regineUrl}${widget.reginaId}/sostituisci/',
                            {'motivo_fine': motivoFine, 'data_fine': fmt.format(dataFine)},
                          );

                          // Ripulisci la cache locale: la regina sostituita
                          // non deve più comparire come attiva nelle liste
                          // finché il prossimo refresh non aggiorna i dati.
                          final storageService =
                              Provider.of<StorageService>(context, listen: false);
                          final cached =
                              await storageService.getStoredData('regine');
                          await storageService.saveData(
                            'regine',
                            cached.where((r) => r['id'] != widget.reginaId).toList(),
                          );

                          if (!mounted) return;
                          Navigator.of(ctx).pop();
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReginaFormScreen(
                                arniaId: _regina!.arniaId,
                                coloniaId: _regina!.coloniaId,
                              ),
                            ),
                          );
                          if (!mounted) return;
                          Navigator.of(context).pop(true);
                        } catch (e) {
                          setSheetState(() => isLoading = false);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.reginaDetailError(e.toString()))));
                        }
                      },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(s.reginaDetailReplaceBtn,
                          style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(s.dialogCancelBtn),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteRegina() {
    final s = _s;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.reginaDetailDeleteTitle),
        content: Text(s.reginaDetailDeleteMsg((_regina!.arniaNumero ?? _regina!.arniaId).toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.dialogCancelBtn),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteRegina();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(s.btnDelete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRegina() async {
    final s = _s;
    try {
      await _apiService.delete('${ApiConstants.regineUrl}${widget.reginaId}/');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.reginaDetailDeletedOk)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.reginaDetailDeleteError(e.toString()))),
      );
    }
  }
}

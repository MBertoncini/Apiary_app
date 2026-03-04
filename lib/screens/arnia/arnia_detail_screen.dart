import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/analisi_telaino_service.dart';
import '../../services/controllo_service.dart';
import '../../models/analisi_telaino.dart';
import '../mobile_scanner_wrapper_screen.dart';
import '../regina/regina_form_screen.dart';
import '../../widgets/qr_generator_widget.dart';
import '../../services/mobile_scanner_service.dart';
import '../../models/arnia.dart';
import 'arnia_form_screen.dart';

class ArniaDetailScreen extends StatefulWidget {
  final int arniaId;
  
  ArniaDetailScreen({required this.arniaId});
  
  @override
  _ArniaDetailScreenState createState() => _ArniaDetailScreenState();
}

class _ArniaDetailScreenState extends State<ArniaDetailScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  Map<String, dynamic>? _arnia;
  Map<String, dynamic>? _apiario;
  Map<String, dynamic>? _regina;
  Map<String, dynamic>? _reginaGenealogia;
  List<dynamic> _controlli = [];
  List<dynamic> _melari = [];
  List<AnalisiTelaino> _analisiTelaini = [];
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadArnia();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadArnia() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Carica dati locali
      final arnie = await storageService.getStoredData('arnie');
      final arnia = arnie.firstWhere(
        (a) => a['id'] == widget.arniaId,
        orElse: () => null,
      );
      
      if (arnia != null) {
        _arnia = arnia;
        
        // Carica apiario
        final apiari = await storageService.getStoredData('apiari');
        _apiario = apiari.firstWhere(
          (a) => a['id'] == arnia['apiario'],
          orElse: () => null,
        );
        
        // Carica regina - prima da storage locale, poi dal server se non trovata
        final regine = await storageService.getStoredData('regine');
        _regina = regine.firstWhere(
          (r) => r['arnia'] == widget.arniaId,
          orElse: () => null,
        );

        // Prova sempre a caricare la regina dal server (aggiornata dopo ogni creazione/sostituzione)
        try {
          final reginaData = await apiService.get('${ApiConstants.arnieUrl}${widget.arniaId}/regina/');
          if (reginaData != null && reginaData is Map<String, dynamic> && reginaData.containsKey('id')) {
            _regina = reginaData;
            // Aggiorna lo StorageService locale per i prossimi accessi offline
            final regineAggiornate = [...regine.where((r) => r['arnia'] != widget.arniaId), reginaData];
            await storageService.saveData('regine', regineAggiornate);

            // Carica genealogia della regina
            try {
              final genealogiaData = await apiService.get(
                '${ApiConstants.regineUrl}${reginaData['id']}/genealogy/',
              );
              if (genealogiaData is Map<String, dynamic>) {
                _reginaGenealogia = genealogiaData;
              }
            } catch (_) {
              // Genealogia non disponibile (endpoint non ancora deployato)
            }
          }
        } catch (e) {
          // Nessuna regina sul server – usa il dato locale se presente
          if (_regina == null) {
            debugPrint('Regina non trovata per arnia ${widget.arniaId}: $e');
          }
        }
        
        // Carica controlli dal ControlloService (SQLite DAO – stessa sorgente usata dal form)
        try {
          final controlloService = ControlloService(apiService);
          _controlli = await controlloService.getControlliByArnia(widget.arniaId);
          _controlli.sort((a, b) => (b['data'] ?? '').compareTo(a['data'] ?? ''));
        } catch (e) {
          debugPrint('Error loading controlli: $e');
          _controlli = [];
        }
        
        // Carica melari
        final allMelari = await storageService.getStoredData('melari');
        _melari = allMelari.where((m) => m['arnia'] == widget.arniaId).toList();
        _melari.sort((a, b) => b['data_posizionamento'].compareTo(a['data_posizionamento']));

        // Carica analisi telaini
        try {
          final analisiService = Provider.of<AnalisiTelainoService>(context, listen: false);
          _analisiTelaini = await analisiService.getAnalisiByArnia(widget.arniaId);
        } catch (e) {
          debugPrint('Error loading analisi telaini: $e');
        }
      } else {
        // Se non troviamo l'arnia in locale, prova a caricarla dal server
        try {
          final arniaData = await apiService.get('${ApiConstants.arnieUrl}${widget.arniaId}/');
          _arnia = arniaData;
          
          // Carica apiario
          final apiarioData = await apiService.get('${ApiConstants.apiariUrl}${arniaData['apiario']}/');
          _apiario = apiarioData;
          
          // Carica regina
          try {
            final reginaData = await apiService.get('${ApiConstants.arnieUrl}${widget.arniaId}/regina/');
            _regina = reginaData;
          } catch (e) {
            debugPrint('Regina non trovata: $e');
          }
          
          // Carica controlli
          final controlliData = await apiService.get('${ApiConstants.arnieUrl}${widget.arniaId}/controlli/');
          _controlli = controlliData;
          _controlli.sort((a, b) => b['data'].compareTo(a['data']));
        } catch (e) {
          debugPrint('Errore caricamento arnia dal server: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Arnia non trovata')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error loading arnia: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il caricamento dei dati')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _navigateToControlloCreate() async {
    await Navigator.of(context).pushNamed(
      AppConstants.controlloCreateRoute,
      arguments: widget.arniaId,
    );
    _loadArnia();
  }
  
  void _navigateToAnalisiTelaino() async {
    final result = await Navigator.of(context).pushNamed(
      AppConstants.analisiTelainoRoute,
      arguments: widget.arniaId,
    );
    if (result == true) _loadArnia();
  }

  Future<void> _navigateToReginaCreate() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReginaFormScreen(arniaId: widget.arniaId),
      ),
    );
    if (result == true) _loadArnia();
  }

  Future<void> _navigateToReginaEdit() async {
    if (_regina == null) return;
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReginaFormScreen(
          arniaId: widget.arniaId,
          reginaData: Map<String, dynamic>.from(_regina!),
          reginaId: _regina!['id'] as int,
        ),
      ),
    );
    if (result == true) _loadArnia();
  }

  Future<void> _showSostituisciDialog() async {
    if (_regina == null) return;
    final int reginaId = _regina!['id'] as int;
    final apiService = Provider.of<ApiService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    final fmt = DateFormat('yyyy-MM-dd');

    String motivoFine = 'sostituzione';
    DateTime dataFine = DateTime.now();
    bool isLoading = false;

    const motiviOptions = [
      {'id': 'sostituzione', 'label': 'Sostituzione programmata'},
      {'id': 'morte', 'label': 'Morte naturale'},
      {'id': 'sciamatura', 'label': 'Sciamatura'},
      {'id': 'problema_sanitario', 'label': 'Problema sanitario'},
      {'id': 'altro', 'label': 'Altro'},
    ];

    await showModalBottomSheet(
      context: context,
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
              const Text('Sostituisci Regina',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'La regina attuale verrà rimossa. Potrai subito aggiungerne una nuova.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'Motivo', border: OutlineInputBorder()),
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
                  decoration: const InputDecoration(
                      labelText: 'Data rimozione', border: OutlineInputBorder()),
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
                          await apiService.post(
                            '${ApiConstants.regineUrl}$reginaId/sostituisci/',
                            {'motivo_fine': motivoFine, 'data_fine': fmt.format(dataFine)},
                          );
                          // Rimuovi dal cache locale
                          final regine = await storageService.getStoredData('regine');
                          await storageService.saveData('regine',
                              regine.where((r) => r['id'] != reginaId).toList());
                          if (!mounted) return;
                          Navigator.of(ctx).pop();
                          // Aggiungi subito la nuova regina
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReginaFormScreen(arniaId: widget.arniaId),
                            ),
                          );
                          if (result == true || result == null) _loadArnia();
                        } catch (e) {
                          setSheetState(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Errore: $e')));
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
                      : const Text('CONFERMA SOSTITUZIONE',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annulla'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _navigateToMelarioCreate() {
    if (_arnia == null) return;
    Navigator.of(context).pushNamed(
      AppConstants.melarioCreateRoute,
      arguments: {
        'arniaId': _arnia!['id'] as int,
        'apiarioId': _arnia!['apiario'] as int?,
      },
    ).then((result) { if (result == true) _loadArnia(); });
  }
  
  void _editArnia() {
    if (_arnia == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArniaFormScreen(arnia: Arnia.fromJson(_arnia!)),
      ),
    ).then((_) => _loadArnia());
  }

  void _confirmDeleteArnia() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Elimina Arnia'),
        content: Text(
          'Sei sicuro di voler eliminare "Arnia ${_arnia?['numero']}"?\n\n'
          'Verranno eliminati anche tutti i controlli, la regina e i melari associati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteArnia();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Elimina'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteArnia() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.delete('${ApiConstants.arnieUrl}${widget.arniaId}/');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arnia eliminata con successo')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
      );
    }
  }

  void _confirmDeleteControllo(dynamic controllo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Elimina Controllo'),
        content: Text(
          'Sei sicuro di voler eliminare il controllo del ${controllo['data']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteControllo(controllo['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Elimina'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteControllo(int controlloId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.delete('${ApiConstants.controlliUrl}$controlloId/');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Controllo eliminato con successo')),
      );

      _loadArnia();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Dettaglio Arnia'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_arnia == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Dettaglio Arnia'),
        ),
        body: Center(
          child: Text('Arnia non trovata'),
        ),
      );
    }
    
    final colorHex = _arnia!['colore_hex'] ?? '#FFFFFF';
    final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Arnia ${_arnia!['numero']}'),
        backgroundColor: color,
        actions: [
          // Pulsante di modifica esistente
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editArnia,
            tooltip: 'Modifica arnia',
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _confirmDeleteArnia,
            tooltip: 'Elimina arnia',
          ),
          // Nuovo pulsante QR
          IconButton(
            icon: Icon(Icons.qr_code),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => Padding(
                  padding: EdgeInsets.all(16),
                  child: QrGeneratorWidget(
                    entity: _arnia!,
                    service: MobileScannerService(),
                  ),
                ),
              );
            },
            tooltip: 'Genera QR Code',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Info'),
            Tab(text: 'Controlli'),
            Tab(text: 'Regina'),
            Tab(text: 'Analisi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Info
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Anteprima arnia
                Card(
                  color: color.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _arnia!['numero'].toString(),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Arnia ${_arnia!['numero']}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _apiario?['nome'] ?? 'Apiario sconosciuto',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: ThemeConstants.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _arnia!['attiva'] ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _arnia!['attiva'] ? 'Attiva' : 'Inattiva',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _arnia!['attiva'] ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Informazioni generali
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informazioni generali',
                          style: ThemeConstants.subheadingStyle,
                        ),
                        const SizedBox(height: 16),
                        
                        // Data installazione
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: ThemeConstants.textSecondaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Data installazione',
                                    style: TextStyle(
                                      color: ThemeConstants.textSecondaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _arnia!['data_installazione'] ?? 'Non specificata',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Colore
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.color_lens,
                              color: ThemeConstants.textSecondaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Colore',
                                    style: TextStyle(
                                      color: ThemeConstants.textSecondaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: color,
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        _arnia!['colore'].toString().toUpperCase(),
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Note
                        if (_arnia!['note'] != null && _arnia!['note'].isNotEmpty) 
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              Text(
                                'Note',
                                style: TextStyle(
                                  color: ThemeConstants.textSecondaryColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(_arnia!['note']),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Ultimo controllo
                if (_controlli.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ultimo controllo',
                            style: ThemeConstants.subheadingStyle,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: ThemeConstants.textSecondaryColor,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Data: ${_controlli[0]['data']}',
                                style: TextStyle(
                                  color: ThemeConstants.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildControlloStatusItem(
                                  'Telaini con scorte',
                                  _controlli[0]['telaini_scorte'].toString(),
                                ),
                              ),
                              Expanded(
                                child: _buildControlloStatusItem(
                                  'Telaini con covata',
                                  _controlli[0]['telaini_covata'].toString(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildControlloStatusItem(
                                  'Regina',
                                  _controlli[0]['presenza_regina'] ? 'Presente' : 'Assente',
                                  color: _controlli[0]['presenza_regina'] 
                                      ? Colors.green 
                                      : Colors.red,
                                ),
                              ),
                              Expanded(
                                child: _buildControlloStatusItem(
                                  'Problemi sanitari',
                                  _controlli[0]['problemi_sanitari'] ? 'Rilevati' : 'Nessuno',
                                  color: _controlli[0]['problemi_sanitari'] 
                                      ? Colors.red 
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          
                          if (_controlli[0]['note'] != null && _controlli[0]['note'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Note:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_controlli[0]['note']),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 16),
                          
                          OutlinedButton(
                            onPressed: () {
                              _tabController.animateTo(1); // Vai alla tab controlli
                            },
                            child: Text('Vedi tutti i controlli'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(double.infinity, 40),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Tab Controlli
          _controlli.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: ThemeConstants.textSecondaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nessun controllo registrato',
                        style: TextStyle(
                          color: ThemeConstants.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _navigateToControlloCreate,
                        icon: Icon(Icons.add),
                        label: Text('Registra controllo'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _controlli.length,
                  itemBuilder: (context, index) {
                    final controllo = _controlli[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: ThemeConstants.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: ThemeConstants.primaryColor,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Controllo del ${controllo['data']}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Effettuato da ${controllo['utente_username']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: ThemeConstants.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Elimina controllo',
                                  onPressed: () => _confirmDeleteControllo(controllo),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildControlloTag(
                                  'Scorte: ${controllo['telaini_scorte']}', 
                                  Icons.grid_view,
                                  Colors.orange,
                                ),
                                _buildControlloTag(
                                  'Covata: ${controllo['telaini_covata']}', 
                                  Icons.grid_view,
                                  Colors.blue,
                                ),
                                _buildControlloTag(
                                  controllo['presenza_regina'] ? 'Regina presente' : 'Regina assente', 
                                  Icons.star,
                                  controllo['presenza_regina'] ? Colors.green : Colors.red,
                                ),
                                if (controllo['regina_vista'])
                                  _buildControlloTag(
                                    'Regina vista', 
                                    Icons.visibility,
                                    Colors.purple,
                                  ),
                                if (controllo['uova_fresche'])
                                  _buildControlloTag(
                                    'Uova fresche', 
                                    Icons.egg_alt,
                                    Colors.green,
                                  ),
                                if (controllo['celle_reali'])
                                  _buildControlloTag(
                                    'Celle reali: ${controllo['numero_celle_reali']}', 
                                    Icons.cell_tower,
                                    Colors.amber,
                                  ),
                                if (controllo['problemi_sanitari'])
                                  _buildControlloTag(
                                    'Problemi sanitari', 
                                    Icons.warning,
                                    Colors.red,
                                  ),
                                if (controllo['sciamatura'])
                                  _buildControlloTag(
                                    'Sciamatura', 
                                    Icons.grain,
                                    Colors.deepOrange,
                                  ),
                              ],
                            ),
                            
                            if (controllo['note'] != null && controllo['note'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Note:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(controllo['note']),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
          // Tab Regina
          _regina == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_outline,
                        size: 64,
                        color: ThemeConstants.textSecondaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nessuna regina registrata',
                        style: TextStyle(
                          color: ThemeConstants.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _navigateToReginaCreate,
                        icon: Icon(Icons.add),
                        label: Text('Aggiungi regina'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Anteprima regina
                      Card(
                        color: Colors.amber.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Regina ${_regina!['razza']}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Introdotta il ${_regina!['data_introduzione']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: ThemeConstants.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Informazioni generali
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informazioni generali',
                                style: ThemeConstants.subheadingStyle,
                              ),
                              const SizedBox(height: 16),
                              
                              // Data di nascita
                              if (_regina!['data_nascita'] != null)
                                _buildReginaInfoItem(
                                  'Data di nascita',
                                  _regina!['data_nascita'],
                                  Icons.cake,
                                ),
                              
                              // Origine
                              _buildReginaInfoItem(
                                'Origine',
                                _getOrigineRegina(_regina!['origine']),
                                Icons.source,
                              ),
                              
                              // Marcata
                              _buildReginaInfoItem(
                                'Marcata',
                                _regina!['marcata'] ? 'Sì' : 'No',
                                Icons.colorize,
                              ),
                              
                              // Colore marcatura
                              if (_regina!['marcata'] && _regina!['colore_marcatura'] != 'non_marcata')
                                _buildReginaInfoItem(
                                  'Colore marcatura',
                                  _regina!['colore_marcatura'].toString().toUpperCase(),
                                  Icons.color_lens,
                                ),
                              
                              // Fecondata
                              _buildReginaInfoItem(
                                'Fecondata',
                                _regina!['fecondata'] ? 'Sì' : 'No',
                                Icons.favorite,
                              ),
                              
                              // Selezionata
                              _buildReginaInfoItem(
                                'Selezionata',
                                _regina!['selezionata'] ? 'Sì' : 'No',
                                Icons.verified,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Valutazioni
                      if (_regina!['docilita'] != null || 
                          _regina!['produttivita'] != null || 
                          _regina!['resistenza_malattie'] != null || 
                          _regina!['tendenza_sciamatura'] != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Valutazioni',
                                  style: ThemeConstants.subheadingStyle,
                                ),
                                const SizedBox(height: 16),
                                
                                if (_regina!['docilita'] != null)
                                  _buildRatingBar('Docilità', _regina!['docilita'], Colors.green),
                                
                                if (_regina!['produttivita'] != null)
                                  _buildRatingBar('Produttività', _regina!['produttivita'], Colors.amber),
                                
                                if (_regina!['resistenza_malattie'] != null)
                                  _buildRatingBar('Resistenza malattie', _regina!['resistenza_malattie'], Colors.blue),
                                
                                if (_regina!['tendenza_sciamatura'] != null)
                                  _buildRatingBar('Tendenza sciamatura', _regina!['tendenza_sciamatura'], Colors.orange, invertRating: true),
                              ],
                            ),
                          ),
                        ),
                      
                      // Note
                      if (_regina!['note'] != null && _regina!['note'].isNotEmpty)
                        Card(
                          margin: EdgeInsets.only(top: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Note',
                                  style: ThemeConstants.subheadingStyle,
                                ),
                                const SizedBox(height: 8),
                                Text(_regina!['note']),
                              ],
                            ),
                          ),
                        ),

                      // Azioni regina
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text('Modifica'),
                              onPressed: _navigateToReginaEdit,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.swap_horiz),
                              label: const Text('Sostituisci'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white),
                              onPressed: _showSostituisciDialog,
                            ),
                          ),
                        ],
                      ),

                      // Genealogia
                      if (_reginaGenealogia != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Genealogia', style: ThemeConstants.subheadingStyle),
                                const SizedBox(height: 12),

                                // Madre
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_upward, size: 18, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Madre: ',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _reginaGenealogia!['madre'] != null
                                            ? '${_reginaGenealogia!['madre']['razza']} – Arnia ${_reginaGenealogia!['madre']['arnia_numero']}'
                                            : 'Regina fondatrice',
                                        style: TextStyle(
                                          color: _reginaGenealogia!['madre'] != null
                                              ? Colors.black87
                                              : ThemeConstants.textSecondaryColor,
                                          fontStyle: _reginaGenealogia!['madre'] != null
                                              ? FontStyle.normal
                                              : FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Figlie
                                if ((_reginaGenealogia!['figlie'] as List?)?.isNotEmpty == true) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.arrow_downward, size: 18, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Figlie: ',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Expanded(
                                        child: Text(
                                          (_reginaGenealogia!['figlie'] as List)
                                              .map((f) => '${f['razza']} (Arnia ${f['arnia_numero']})')
                                              .join(', '),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                // Storia nell'arnia
                                if ((_reginaGenealogia!['storia_arnia'] as List?)?.isNotEmpty == true) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Storia nell\'arnia',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  ...(_reginaGenealogia!['storia_arnia'] as List).map((s) {
                                    final fine = s['data_fine'] as String?;
                                    final periodo = '${s['data_inizio']}'
                                        '${fine != null ? ' → $fine' : ' → in corso'}';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.history, size: 14, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              periodo,
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ),
                                          if (s['motivo_fine'] != null)
                                            Text(
                                              s['motivo_fine'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: ThemeConstants.textSecondaryColor,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

          // Tab Analisi Telaini
          _analisiTelaini.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: ThemeConstants.textSecondaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nessuna analisi registrata',
                        style: TextStyle(
                          color: ThemeConstants.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToAnalisiTelaino(),
                        icon: Icon(Icons.camera_alt),
                        label: Text('Avvia Analisi'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _analisiTelaini.length,
                  itemBuilder: (context, index) {
                    final analisi = _analisiTelaini[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.analytics, color: Colors.amber),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Telaino ${analisi.numeroTelaino} - Facciata ${analisi.facciata}',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        analisi.data ?? '',
                                        style: TextStyle(fontSize: 13, color: ThemeConstants.textSecondaryColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _buildControlloTag('Api: ${analisi.conteggioApi}', Icons.bug_report, Colors.orange),
                                _buildControlloTag('Regine: ${analisi.conteggioRegine}', Icons.star, Colors.purple),
                                _buildControlloTag('Fuchi: ${analisi.conteggioFuchi}', Icons.circle, Colors.blue),
                                _buildControlloTag('Celle R.: ${analisi.conteggioCelleReali}', Icons.hexagon_outlined, Colors.amber),
                              ],
                            ),
                            if (analisi.note != null && analisi.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  analisi.note!,
                                  style: TextStyle(fontSize: 13, color: ThemeConstants.textSecondaryColor),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        children: [
          SpeedDialChild(
            child: Icon(Icons.check_circle),
            label: 'Registra Controllo',
            onTap: _navigateToControlloCreate,
          ),
          SpeedDialChild(
            child: Icon(Icons.analytics),
            label: 'Analisi Telaino',
            onTap: () => _navigateToAnalisiTelaino(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlloStatusItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: ThemeConstants.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildControlloTag(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReginaInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: ThemeConstants.textSecondaryColor,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ThemeConstants.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRatingBar(String label, int rating, Color color, {bool invertRating = false}) {
    final effectiveRating = invertRating ? 6 - rating : rating;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Row(
            children: List.generate(5, (index) {
              return Container(
                width: 24,
                height: 8,
                margin: EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: index < effectiveRating ? color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
  
  String _getOrigineRegina(String origine) {
    switch (origine) {
      case 'acquistata':
        return 'Acquistata';
      case 'allevata':
        return 'Allevata';
      case 'sciamatura':
        return 'Sciamatura naturale';
      case 'emergenza':
        return 'Celle di emergenza';
      case 'sconosciuta':
        return 'Sconosciuta';
      default:
        return origine.toString().toUpperCase();
    }
  }
}
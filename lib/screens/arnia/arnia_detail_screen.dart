import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

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
  List<dynamic> _controlli = [];
  List<dynamic> _melari = [];
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        
        // Carica regina
        final regine = await storageService.getStoredData('regine');
        _regina = regine.firstWhere(
          (r) => r['arnia'] == widget.arniaId,
          orElse: () => null,
        );
        
        // Carica controlli e ordina per data (più recenti prima)
        final allControlli = await storageService.getStoredData('controlli');
        _controlli = allControlli.where((c) => c['arnia'] == widget.arniaId).toList();
        _controlli.sort((a, b) => b['data'].compareTo(a['data']));
        
        // Carica melari
        final allMelari = await storageService.getStoredData('melari');
        _melari = allMelari.where((m) => m['arnia'] == widget.arniaId).toList();
        _melari.sort((a, b) => b['data_posizionamento'].compareTo(a['data_posizionamento']));
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
            print('Regina non trovata: $e');
          }
          
          // Carica controlli
          final controlliData = await apiService.get('${ApiConstants.arnieUrl}${widget.arniaId}/controlli/');
          _controlli = controlliData;
          _controlli.sort((a, b) => b['data'].compareTo(a['data']));
        } catch (e) {
          print('Errore caricamento arnia dal server: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Arnia non trovata')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('Error loading arnia: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il caricamento dei dati')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _navigateToControlloCreate() {
    Navigator.of(context).pushNamed(
      AppConstants.controlloCreateRoute,
      arguments: widget.arniaId,
    );
  }
  
  void _navigateToReginaCreate() {
    // TODO: navigazione alla creazione regina con arnia preimpostata
  }
  
  void _navigateToMelarioCreate() {
    // TODO: navigazione alla creazione melario con arnia preimpostata
  }
  
  void _editArnia() {
    // TODO: navigazione alla modifica arnia
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
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editArnia,
            tooltip: 'Modifica arnia',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Info'),
            Tab(text: 'Controlli'),
            Tab(text: 'Regina'),
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
                              SizedBox(height: 4),
                              Text(
                                _apiario?['nome'] ?? 'Apiario sconosciuto',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: ThemeConstants.textSecondaryColor,
                                ),
                              ),
                              SizedBox(height: 8),
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
                SizedBox(height: 16),
                
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
                        SizedBox(height: 16),
                        
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
                        SizedBox(height: 16),
                        
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
                              SizedBox(height: 16),
                              Text(
                                'Note',
                                style: TextStyle(
                                  color: ThemeConstants.textSecondaryColor,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(_arnia!['note']),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
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
                          SizedBox(height: 16),
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
                          SizedBox(height: 8),
                          
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
                          SizedBox(height: 8),
                          
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
                                  SizedBox(height: 4),
                                  Text(_controlli[0]['note']),
                                ],
                              ),
                            ),
                          
                          SizedBox(height: 16),
                          
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
                
                // Button per aggiungere controllo
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _navigateToControlloCreate,
                  icon: Icon(Icons.add),
                  label: Text('Nuovo controllo'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
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
                      SizedBox(height: 16),
                      Text(
                        'Nessun controllo registrato',
                        style: TextStyle(
                          color: ThemeConstants.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 16),
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
                                      SizedBox(height: 4),
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
                              ],
                            ),
                            SizedBox(height: 16),
                            
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
                                    Icons.swarm,
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
                                    SizedBox(height: 4),
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
                      SizedBox(height: 16),
                      Text(
                        'Nessuna regina registrata',
                        style: TextStyle(
                          color: ThemeConstants.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 16),
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
                                    SizedBox(height: 4),
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
                      SizedBox(height: 16),
                      
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
                              SizedBox(height: 16),
                              
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
                      SizedBox(height: 16),
                      
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
                                SizedBox(height: 16),
                                
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
                                SizedBox(height: 8),
                                Text(_regina!['note']),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToControlloCreate,
        child: Icon(Icons.add),
        tooltip: 'Registra controllo',
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
        SizedBox(height: 4),
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
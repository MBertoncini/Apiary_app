import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class ApiarioDetailScreen extends StatefulWidget {
  final int apiarioId;
  
  ApiarioDetailScreen({required this.apiarioId});
  
  @override
  _ApiarioDetailScreenState createState() => _ApiarioDetailScreenState();
}

class _ApiarioDetailScreenState extends State<ApiarioDetailScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  Map<String, dynamic>? _apiario;
  List<dynamic> _arnie = [];
  List<dynamic> _trattamenti = [];
  List<dynamic> _fioriture = [];
  List<dynamic> _datiMeteo = [];
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadApiario();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadApiario() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Carica dati locali
      final apiari = await storageService.getStoredData('apiari');
      final apiario = apiari.firstWhere(
        (a) => a['id'] == widget.apiarioId,
        orElse: () => null,
      );
      
      if (apiario != null) {
        _apiario = apiario;
        
        // Carica dati correlati
        final allArnie = await storageService.getStoredData('arnie');
        _arnie = allArnie.where((a) => a['apiario'] == widget.apiarioId).toList();
        
        final allTrattamenti = await storageService.getStoredData('trattamenti');
        _trattamenti = allTrattamenti.where((t) => t['apiario'] == widget.apiarioId).toList();
        
        final allFioriture = await storageService.getStoredData('fioriture');
        _fioriture = allFioriture.where((f) => f['apiario'] == widget.apiarioId).toList();
        
        // Carica dati dal server
        try {
          final meteoData = await apiService.get('${ApiConstants.apiariUrl}${widget.apiarioId}/meteo/');
          _datiMeteo = meteoData;
        } catch (e) {
          print('Error loading meteo data: $e');
        }
      } else {
        // Se non troviamo l'apiario in locale, prova a caricarlo dal server
        final apiarioData = await apiService.get('${ApiConstants.apiariUrl}${widget.apiarioId}/');
        _apiario = apiarioData;
        
        // Carica dati correlati
        final arnieData = await apiService.get('${ApiConstants.apiariUrl}${widget.apiarioId}/arnie/');
        _arnie = arnieData;
        
        final controlliData = await apiService.get('${ApiConstants.apiariUrl}${widget.apiarioId}/controlli/');
        
        final meteoData = await apiService.get('${ApiConstants.apiariUrl}${widget.apiarioId}/meteo/');
        _datiMeteo = meteoData;
      }
      
      // Ordina arnie per numero
      _arnie.sort((a, b) => a['numero'].compareTo(b['numero']));
      
      // Ordina trattamenti per data (più recenti prima)
      _trattamenti.sort((a, b) => b['data_inizio'].compareTo(a['data_inizio']));
      
      // Ordina fioriture per data (attive prima)
      _fioriture.sort((a, b) {
        if (a['is_active'] == b['is_active']) {
          return b['data_inizio'].compareTo(a['data_inizio']);
        }
        return a['is_active'] ? -1 : 1;
      });
      
    } catch (e) {
      print('Error loading apiario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il caricamento dei dati')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _navigateToArniaDetail(int arniaId) {
    Navigator.of(context).pushNamed(
      AppConstants.arniaDetailRoute,
      arguments: arniaId,
    );
  }
  
  void _navigateToArniaCreate() {
    // TODO: navigazione alla creazione arnia con apiario preimpostato
  }
  
  void _navigateToControlloCreate(int arniaId) {
    Navigator.of(context).pushNamed(
      AppConstants.controlloCreateRoute,
      arguments: arniaId,
    );
  }
  
  void _editApiario() {
    // TODO: navigazione alla modifica apiario
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Dettaglio Apiario'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_apiario == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Dettaglio Apiario'),
        ),
        body: Center(
          child: Text('Apiario non trovato'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_apiario!['nome']),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editApiario,
            tooltip: 'Modifica apiario',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Info'),
            Tab(text: 'Arnie'),
            Tab(text: 'Trattamenti'),
            Tab(text: 'Meteo'),
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
                        
                        // Posizione
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: ThemeConstants.textSecondaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Posizione',
                                    style: TextStyle(
                                      color: ThemeConstants.textSecondaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _apiario!['posizione'] ?? 'Non specificata',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // Coordinate
                        if (_apiario!['latitudine'] != null && _apiario!['longitudine'] != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.map,
                                color: ThemeConstants.textSecondaryColor,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Coordinate',
                                      style: TextStyle(
                                        color: ThemeConstants.textSecondaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Lat: ${_apiario!['latitudine']}, Long: ${_apiario!['longitudine']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        
                        if (_apiario!['latitudine'] != null && _apiario!['longitudine'] != null)
                          SizedBox(height: 16),
                        
                        // Monitoraggio meteo
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.wb_sunny,
                              color: ThemeConstants.textSecondaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monitoraggio meteo',
                                    style: TextStyle(
                                      color: ThemeConstants.textSecondaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _apiario!['monitoraggio_meteo'] ? 'Attivo' : 'Disattivato',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // Visibilità
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.visibility,
                              color: ThemeConstants.textSecondaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Visibilità sulla mappa',
                                    style: TextStyle(
                                      color: ThemeConstants.textSecondaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _apiario!['visibilita_mappa'] == 'privato'
                                        ? 'Solo proprietario'
                                        : _apiario!['visibilita_mappa'] == 'gruppo'
                                            ? 'Membri del gruppo'
                                            : 'Tutti gli utenti',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // Condivisione
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.group,
                              color: ThemeConstants.textSecondaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Condivisione con gruppi',
                                    style: TextStyle(
                                      color: ThemeConstants.textSecondaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _apiario!['condiviso_con_gruppo']
                                        ? 'Condiviso con il gruppo'
                                        : 'Non condiviso',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Note
                if (_apiario!['note'] != null && _apiario!['note'].isNotEmpty)
                  Card(
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
                          Text(_apiario!['note']),
                        ],
                      ),
                    ),
                  ),
                
                SizedBox(height: 16),
                
                // Statistiche
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistiche',
                          style: ThemeConstants.subheadingStyle,
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    _arnie.length.toString(),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: ThemeConstants.primaryColor,
                                    ),
                                  ),
                                  Text(
                                    'Arnie',
                                    style: TextStyle(
                                      color: ThemeConstants.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    _arnie.where((a) => a['attiva'] == true).length.toString(),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: ThemeConstants.secondaryColor,
                                    ),
                                  ),
                                  Text(
                                    'Arnie attive',
                                    style: TextStyle(
                                      color: ThemeConstants.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    _trattamenti.where((t) => 
                                      t['stato'] == 'in_corso' || t['stato'] == 'programmato').length.toString(),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    'Trattamenti',
                                    style: TextStyle(
                                      color: ThemeConstants.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Arnie
          _arnie.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.grid_view_outlined,
                        size: 64,
                        color: ThemeConstants.textSecondaryColor.withOpacity(0.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nessuna arnia in questo apiario',
                        style: TextStyle(
                          color: ThemeConstants.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _navigateToArniaCreate,
                        icon: Icon(Icons.add),
                        label: Text('Aggiungi arnia'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _arnie.length,
                  itemBuilder: (context, index) {
                    final arnia = _arnie[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _navigateToArniaDetail(arnia['id']),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 20,
                              color: Color(int.parse(arnia['colore_hex'].replaceAll('#', '0xFF'))),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Arnia ${arnia['numero']}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (!arnia['attiva'])
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Inattiva',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Installata il ${arnia['data_installazione']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ThemeConstants.textSecondaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => _navigateToArniaDetail(arnia['id']),
                                        child: Text('Dettagli'),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: Size(80, 36),
                                          padding: EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _navigateToControlloCreate(arnia['id']),
                                        child: Text('Controllo'),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: Size(80, 36),
                                          padding: EdgeInsets.symmetric(horizontal: 8),
                                          backgroundColor: ThemeConstants.secondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          
          // Tab Trattamenti
          _trattamenti.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 64,
                        color: ThemeConstants.textSecondaryColor.withOpacity(0.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nessun trattamento sanitario registrato',
                        style: TextStyle(
                          color: ThemeConstants.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: navigazione alla creazione trattamento
                        },
                        icon: Icon(Icons.add),
                        label: Text('Aggiungi trattamento'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _trattamenti.length,
                  itemBuilder: (context, index) {
                    final trattamento = _trattamenti[index];
                    final stato = trattamento['stato'];
                    
                    // Colore in base allo stato
                    Color statusColor;
                    if (stato == 'in_corso') {
                      statusColor = Colors.orange;
                    } else if (stato == 'programmato') {
                      statusColor = Colors.blue;
                    } else if (stato == 'completato') {
                      statusColor = Colors.green;
                    } else {
                      statusColor = Colors.grey;
                    }
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    trattamento['tipo_trattamento_nome'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    stato == 'in_corso' 
                                        ? 'In corso' 
                                        : stato == 'programmato'
                                            ? 'Programmato'
                                            : stato == 'completato'
                                                ? 'Completato'
                                                : 'Annullato',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: ThemeConstants.textSecondaryColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Dal ${trattamento['data_inizio']}',
                                  style: TextStyle(
                                    color: ThemeConstants.textSecondaryColor,
                                  ),
                                ),
                                if (trattamento['data_fine'] != null)
                                  Text(
                                    ' al ${trattamento['data_fine']}',
                                    style: TextStyle(
                                      color: ThemeConstants.textSecondaryColor,
                                    ),
                                  ),
                              ],
                            ),
                            
                            if (trattamento['data_fine_sospensione'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Sospensione fino al ${trattamento['data_fine_sospensione']}',
                                      style: TextStyle(
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            if (trattamento['blocco_covata_attivo'] == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.block,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Blocco covata attivo',
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            SizedBox(height: 8),
                            
                            if (trattamento['note'] != null && trattamento['note'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  trattamento['note'],
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            
                            SizedBox(height: 8),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    // TODO: navigazione al dettaglio trattamento
                                  },
                                  child: Text('Dettagli'),
                                ),
                                SizedBox(width: 8),
                                if (stato == 'in_corso' || stato == 'programmato')
                                  TextButton(
                                    onPressed: () {
                                      // TODO: navigazione alla modifica trattamento
                                    },
                                    child: Text('Modifica'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          
          // Tab Meteo
          _apiario!['monitoraggio_meteo'] == false
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        size: 64,
                        color: ThemeConstants.textSecondaryColor.withOpacity(0.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Monitoraggio meteo non attivato',
                        style: TextStyle(
                          color: ThemeConstants.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _editApiario,
                        icon: Icon(Icons.settings),
                        label: Text('Attiva monitoraggio meteo'),
                      ),
                    ],
                  ),
                )
              : _datiMeteo.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 64,
                            color: ThemeConstants.textSecondaryColor.withOpacity(0.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nessun dato meteo disponibile',
                            style: TextStyle(
                              color: ThemeConstants.textSecondaryColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Meteo attuale
                        Card(
                          margin: EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Meteo attuale',
                                  style: ThemeConstants.subheadingStyle,
                                ),
                                SizedBox(height: 16),
                                
                                Row(
                                  children: [
                                    // Placeholder per icona meteo
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.wb_sunny,
                                        size: 48,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${_datiMeteo.isNotEmpty ? _datiMeteo[0]['temperatura'] : "--"}°C',
                                            style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _datiMeteo.isNotEmpty ? _datiMeteo[0]['descrizione'] : "Non disponibile",
                                            style: TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: 16),
                                Divider(),
                                SizedBox(height: 8),
                                
                                // Dettagli meteo
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.water_drop,
                                          color: Colors.blue,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Umidità',
                                          style: TextStyle(
                                            color: ThemeConstants.textSecondaryColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '${_datiMeteo.isNotEmpty ? _datiMeteo[0]['umidita'] : "--"}%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.air,
                                          color: Colors.blueGrey,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Vento',
                                          style: TextStyle(
                                            color: ThemeConstants.textSecondaryColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '${_datiMeteo.isNotEmpty ? _datiMeteo[0]['velocita_vento'] : "--"} km/h',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.compress,
                                          color: Colors.purple,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Pressione',
                                          style: TextStyle(
                                            color: ThemeConstants.textSecondaryColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '${_datiMeteo.isNotEmpty ? _datiMeteo[0]['pressione'] : "--"} hPa',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Dati storici',
                              style: ThemeConstants.subheadingStyle,
                            ),
                          ),
                        ),
                        
                        // Lista dati storici
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: _datiMeteo.length,
                            itemBuilder: (context, index) {
                              if (index == 0) return SizedBox.shrink(); // Skip current data
                              
                              final meteo = _datiMeteo[index];
                              
                              // Extract date and time
                              final dateTime = DateTime.parse(meteo['data']);
                              final formattedDate = "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
                              final formattedTime = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
                              
                              return Card(
                                margin: EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Icon(
                                          Icons.wb_sunny,
                                          size: 24,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  formattedTime,
                                                  style: TextStyle(
                                                    color: ThemeConstants.textSecondaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              meteo['descrizione'] ?? 'Non disponibile',
                                              style: TextStyle(
                                                color: ThemeConstants.textSecondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        '${meteo['temperatura']}°C',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToArniaCreate,
        child: Icon(Icons.add),
        tooltip: 'Aggiungi arnia',
      ),
    );
  }
}
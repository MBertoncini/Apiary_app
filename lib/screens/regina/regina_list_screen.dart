import 'package:flutter/material.dart';
import '../../widgets/drawer_widget.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/regina.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ReginaListScreen extends StatefulWidget {
  @override
  _ReginaListScreenState createState() => _ReginaListScreenState();
}

class _ReginaListScreenState extends State<ReginaListScreen> {
  late Future<List<Regina>> _regineFuture;
  late ApiService _apiService;
  
  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _refreshRegine();
  }
  
  Future<void> _refreshRegine() async {
    setState(() {
      _regineFuture = _loadRegine();
    });
  }
  
  Future<List<Regina>> _loadRegine() async {
    try {
      // Per ora utilizziamo un approccio alternativo visto che il modello Regina
      // potrebbe non essere pienamente compatibile con l'API
      // In una implementazione completa, bisognerebbe adattare il modello Regina
      // per corrispondere esattamente alla risposta dell'API
      
      final response = await _apiService.syncData();
      final List<Regina> regine = [];
      
      // Qui stiamo simulando il caricamento delle regine cercando dati negli arnie
      // Nel sistema reale, dovresti usare l'endpoint regine dedicato
      if (response.containsKey('arnie')) {
        final List<dynamic> arnie = response['arnie'];
        for (var arnia in arnie) {
          if (arnia.containsKey('regina')) {
            // Estrai i dati della regina dall'arnia
            final reginaData = arnia['regina'];
            // Crea un oggetto Regina
            regine.add(Regina(
              id: reginaData['id'],
              arniaId: arnia['id'],
              razza: reginaData['razza'] ?? 'sconosciuta',
              origine: reginaData['origine'] ?? 'sconosciuta',
              dataInserimento: reginaData['data_introduzione'],
              isAttiva: true,
            ));
          }
        }
      }
      
      return regine;
    } catch (e) {
      print('Error loading regine: $e');
      throw e;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Le mie Regine'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshRegine,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.reginaListRoute),
      body: FutureBuilder<List<Regina>>(
        future: _regineFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Errore nel caricamento delle regine: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Nessuna regina trovata.\nAggiungi regine dalle schede delle singole arnie.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          } else {
            return RefreshIndicator(
              onRefresh: _refreshRegine,
              child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final regina = snapshot.data![index];
                  return ReginaListItem(regina: regina);
                },
              ),
            );
          }
        },
      ),
    );
  }
}

class ReginaListItem extends StatelessWidget {
  final Regina regina;
  
  ReginaListItem({required this.regina});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text('Regina dell\'arnia ${regina.arniaId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Razza: ${_getRazzaDisplay(regina.razza)}'),
            Text('Origine: ${_getOrigineDisplay(regina.origine)}'),
            Text('Introdotta: ${regina.dataInserimento}'),
          ],
        ),
        isThreeLine: true,
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          // In una implementazione completa, qui si navigherebbe
          // alla schermata di dettaglio della regina
          if (regina.id != null) {
            Navigator.of(context).pushNamed(
              AppConstants.reginaDetailRoute,
              arguments: regina.id,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Dettaglio regina non disponibile')),
            );
          }
        },
      ),
    );
  }
  
  Widget _buildLeadingIcon() {
    Color reginaColor;
    
    // Colore basato sul colore della regina
    if (regina.colore != null) {
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
        default:
          reginaColor = Colors.grey;
          break;
      }
    } else {
      reginaColor = Colors.grey;
    }
    
    return CircleAvatar(
      backgroundColor: reginaColor,
      child: Icon(Icons.local_florist, color: _getContrastColor(reginaColor)),
    );
  }
  
  String _getRazzaDisplay(String razza) {
    switch (razza) {
      case 'ligustica':
        return 'Apis mellifera ligustica (Italiana)';
      case 'carnica':
        return 'Apis mellifera carnica (Carnica)';
      case 'buckfast':
        return 'Buckfast';
      case 'caucasica':
        return 'Apis mellifera caucasica';
      case 'sicula':
        return 'Apis mellifera sicula (Siciliana)';
      case 'ibrida':
        return 'Ibrida';
      case 'altro':
        return 'Altro';
      default:
        return razza;
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
        return origine;
    }
  }
  
  Color _getContrastColor(Color backgroundColor) {
    // Calcola se il testo dovrebbe essere chiaro o scuro
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
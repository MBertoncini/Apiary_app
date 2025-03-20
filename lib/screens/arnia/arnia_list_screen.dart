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

class ArniaListScreen extends StatefulWidget {
  @override
  _ArniaListScreenState createState() => _ArniaListScreenState();
}

class _ArniaListScreenState extends State<ArniaListScreen> {
  late Future<Map<String, List<Arnia>>> _arnieByApiarioFuture;
  late ApiService _apiService;
  late StorageService _storageService;
  
  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _refreshArnie();
  }
  
  Future<void> _refreshArnie() async {
    setState(() {
      _arnieByApiarioFuture = _loadArnieGrouped();
    });
  }
  
  Future<Map<String, List<Arnia>>> _loadArnieGrouped() async {
    try {
      // Prima, proviamo a caricare da storage locale se c'è un problema di connessione
      List<Arnia> arnie = [];
      Map<int, dynamic> apiariMap = {};
      
      try {
        // Tenta di caricare le arnie dall'API
        print('Fetching arnie from API...');
        final response = await _apiService.get(ApiConstants.arnieUrl);
        print('API response for arnie: $response');
        
        // Gestione robusta per diversi formati di risposta
        if (response is List) {
          // Formato diretto: array di arnie
          arnie = response.map((item) => Arnia.fromJson(item)).toList();
          print('Parsed ${arnie.length} arnie from API (direct array)');
        } else if (response is Map) {
          // Django REST Framework tipicamente usa questo formato di paginazione
          if (response.containsKey('results') && response['results'] is List) {
            arnie = (response['results'] as List).map((item) => Arnia.fromJson(item)).toList();
            print('Parsed ${arnie.length} arnie from API (DRF pagination format)');
          } 
          // Potrebbe essere un oggetto che contiene un array in una proprietà
          else {
            bool found = false;
            for (var key in ['arnie', 'data', 'items']) {
              if (response.containsKey(key) && response[key] is List) {
                arnie = (response[key] as List).map((item) => Arnia.fromJson(item)).toList();
                print('Parsed ${arnie.length} arnie from API (nested in "$key" property)');
                found = true;
                break;
              }
            }
            
            if (!found) {
              print('Unexpected response format for arnie: could not find array in object properties');
              // Prova a controllare se l'oggetto stesso può essere interpretato come un'arnia
              try {
                var singleArnia = Arnia.fromJson(response as Map<String, dynamic>);
                arnie = [singleArnia];
                print('Parsed a single arnia from response object');
              } catch (e) {
                print('Could not parse response as a single arnia: $e');
              }
            }
          }
        } else {
          print('Unexpected response format for arnie: ${response.runtimeType}');
        }
        
        // Carica i dati degli apiari
        print('Fetching apiari from API...');
        final apiariResponse = await _apiService.get(ApiConstants.apiariUrl);
        print('API response for apiari: $apiariResponse');
        
        // Stessa gestione robusta per gli apiari
        if (apiariResponse is List) {
          for (var apiario in apiariResponse) {
            apiariMap[apiario['id']] = apiario;
          }
          print('Parsed ${apiariMap.length} apiari from API (direct array)');
        } else if (apiariResponse is Map) {
          // Django REST Framework tipicamente usa questo formato di paginazione
          if (apiariResponse.containsKey('results') && apiariResponse['results'] is List) {
            for (var apiario in apiariResponse['results']) {
              apiariMap[apiario['id']] = apiario;
            }
            print('Parsed ${apiariMap.length} apiari from API (DRF pagination format)');
          }
          // Cerca proprietà che potrebbero contenere un array di apiari
          else {
            bool found = false;
            for (var key in ['apiari', 'data', 'items']) {
              if (apiariResponse.containsKey(key) && apiariResponse[key] is List) {
                for (var apiario in apiariResponse[key]) {
                  apiariMap[apiario['id']] = apiario;
                }
                print('Parsed ${apiariMap.length} apiari from API (nested in "$key" property)');
                found = true;
                break;
              }
            }
            
            if (!found && apiariResponse.containsKey('id')) {
              // Potrebbe essere un singolo apiario
              apiariMap[apiariResponse['id']] = apiariResponse;
              print('Parsed a single apiario from response object');
            } else if (!found) {
              print('Unexpected response format for apiari: could not find array in object properties');
            }
          }
        } else {
          print('Unexpected response format for apiari: ${apiariResponse.runtimeType}');
        }
      } catch (e) {
        print('Error fetching from API, falling back to local storage: $e');
        
        // Fallback: carica da storage locale se l'API fallisce
        final storedArnie = await _storageService.getStoredData('arnie');
        if (storedArnie.isNotEmpty) {
          arnie = storedArnie.map((item) => Arnia.fromJson(item)).toList();
          print('Loaded ${arnie.length} arnie from local storage');
        }
        
        final storedApiari = await _storageService.getStoredData('apiari');
        if (storedApiari.isNotEmpty) {
          for (var apiario in storedApiari) {
            apiariMap[apiario['id']] = apiario;
          }
          print('Loaded ${apiariMap.length} apiari from local storage');
        }
      }
      
      // Se ancora non abbiamo arnie, restituisci una mappa vuota
      if (arnie.isEmpty) {
        print('No arnie found in API or local storage');
        return {};
      }
      
      // Aggiorna le informazioni delle arnie con i nomi corretti degli apiari
      for (var i = 0; i < arnie.length; i++) {
        if (apiariMap.containsKey(arnie[i].apiario)) {
          arnie[i] = Arnia(
            id: arnie[i].id,
            apiario: arnie[i].apiario,
            apiarioNome: apiariMap[arnie[i].apiario]['nome'],
            numero: arnie[i].numero,
            colore: arnie[i].colore,
            coloreHex: arnie[i].coloreHex,
            dataInstallazione: arnie[i].dataInstallazione,
            note: arnie[i].note,
            attiva: arnie[i].attiva,
          );
        }
      }
      
      // Salva le arnie aggiornate nel storage locale
      await _storageService.saveData('arnie', arnie.map((a) => a.toJson()).toList());
      
      // Raggruppa le arnie per apiario
      Map<String, List<Arnia>> arniaByApiario = {};
      
      for (var arnia in arnie) {
        String apiarioNome = arnia.apiarioNome ?? 'Apiario sconosciuto';
        if (!arniaByApiario.containsKey(apiarioNome)) {
          arniaByApiario[apiarioNome] = [];
        }
        arniaByApiario[apiarioNome]!.add(arnia);
      }
      
      // Ordina le arnie all'interno di ogni apiario per numero
      arniaByApiario.forEach((apiario, arnieList) {
        arnieList.sort((a, b) => a.numero.compareTo(b.numero));
      });
      
      print('Returning ${arniaByApiario.length} apiario groups with arnie');
      return arniaByApiario;
    } catch (e) {
      print('Error loading arnie: $e');
      // Invece di propagare l'errore, proviamo a recuperare i dati locali
      try {
        final storedArnie = await _storageService.getStoredData('arnie');
        if (storedArnie.isNotEmpty) {
          print('Fallback: loading ${storedArnie.length} arnie from local storage after error');
          
          List<Arnia> arnie = storedArnie.map((item) => Arnia.fromJson(item)).toList();
          Map<String, List<Arnia>> arniaByApiario = {};
          
          for (var arnia in arnie) {
            String apiarioNome = arnia.apiarioNome ?? 'Apiario sconosciuto';
            if (!arniaByApiario.containsKey(apiarioNome)) {
              arniaByApiario[apiarioNome] = [];
            }
            arniaByApiario[apiarioNome]!.add(arnia);
          }
          
          // Ordina le arnie all'interno di ogni apiario per numero
          arniaByApiario.forEach((apiario, arnieList) {
            arnieList.sort((a, b) => a.numero.compareTo(b.numero));
          });
          
          return arniaByApiario;
        }
      } catch (localError) {
        print('Error loading from local storage: $localError');
      }
      
      // Se tutto fallisce, restituisci una mappa vuota
      return {};
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Le mie Arnie'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshArnie,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.arniaListRoute),
      body: FutureBuilder<Map<String, List<Arnia>>>(
        future: _arnieByApiarioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Mostra errore con pulsante di retry
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Errore nel caricamento delle arnie',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Riprova'),
                    onPressed: _refreshArnie,
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Nessuna arnia trovata
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hive_outlined,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nessuna arnia trovata',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Non hai ancora creato arnie o non è stato possibile caricarle',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Crea arnia'),
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppConstants.creaArniaRoute);
                    },
                  ),
                  SizedBox(height: 12),
                  TextButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Riprova a caricare'),
                    onPressed: _refreshArnie,
                  ),
                ],
              ),
            );
          } else {
            // Mostra arnie raggruppate per apiario
            return RefreshIndicator(
              onRefresh: _refreshArnie,
              child: ListView.builder(
                itemCount: snapshot.data!.keys.length,
                itemBuilder: (context, index) {
                  String apiarioNome = snapshot.data!.keys.elementAt(index);
                  List<Arnia> arnieInApiario = snapshot.data![apiarioNome] ?? [];
                  
                  return ApiarioGroupWidget(
                    apiarioNome: apiarioNome,
                    arnie: arnieInApiario,
                  );
                },
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushNamed(AppConstants.creaArniaRoute);
        },
        tooltip: 'Aggiungi arnia',
      ),
    );
  }
}

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
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intestazione del gruppo con nome apiario
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: ThemeConstants.primaryColor,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.apiarioNome,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.arnie.length} ${widget.arnie.length == 1 ? 'arnia' : 'arnie'}',
                    style: TextStyle(
                      color: ThemeConstants.textSecondaryColor,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                ],
              ),
            ),
          ),
          
          // Lista delle arnie dell'apiario (se espanso)
          if (_isExpanded)
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.arnie.length,
              itemBuilder: (context, index) {
                return ArniaListItem(arnia: widget.arnie[index]);
              },
            ),
        ],
      ),
    );
  }
}

class ArniaListItem extends StatelessWidget {
  final Arnia arnia;
  
  const ArniaListItem({required this.arnia});
  
  @override
  Widget build(BuildContext context) {
    Color arniaColor = _getColorFromHex(arnia.coloreHex);
    
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppConstants.arniaDetailRoute,
          arguments: arnia.id,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade300,
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              // Numero e colore dell'arnia
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: arniaColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    arnia.numero.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getContrastColor(arniaColor),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              
              // Informazioni arnia
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arnia ${arnia.numero}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Installata il ${arnia.dataInstallazione}',
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeConstants.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Indicatore stato attivo
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: arnia.attiva 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  arnia.attiva ? 'Attiva' : 'Inattiva',
                  style: TextStyle(
                    fontSize: 12,
                    color: arnia.attiva ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
              
              // Icona per dettaglio
              Icon(
                Icons.navigate_next,
                color: ThemeConstants.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }
  
  Color _getContrastColor(Color backgroundColor) {
    // Calcola se il testo dovrebbe essere chiaro o scuro
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
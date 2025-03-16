import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/gruppo.dart';
import '../../services/gruppo_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../widgets/error_widget.dart';

class GruppoDetailScreen extends StatefulWidget {
  final int gruppoId;

  GruppoDetailScreen({required this.gruppoId});

  @override
  _GruppoDetailScreenState createState() => _GruppoDetailScreenState();
}

class _GruppoDetailScreenState extends State<GruppoDetailScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Gruppo? _gruppo;
  List<dynamic> _apiariCondivisi = [];
  String? _errorMessage;
  late GruppoService _gruppoService;
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    _gruppoService = GruppoService(apiService, storageService);
    _tabController = TabController(length: 2, vsync: this); // Solo 2 tab ora: Membri e Apiari
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
          print('Tab cambiato a: $_currentIndex');
        });
      }
    });
    
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
      // Carica gruppo e apiari (non più inviti)
      final results = await Future.wait([
        _gruppoService.getGruppoDetail(widget.gruppoId),
        _gruppoService.getApiariGruppo(widget.gruppoId),
      ]);

      setState(() {
        _gruppo = results[0] as Gruppo;
        
        // Salva gli apiari
        try {
          var apiari = results[1];
          if (apiari is List) {
            print('Apiari caricati: ${apiari.length}');
            _apiariCondivisi = apiari;
          } else {
            print('Formato apiari non riconosciuto: ${apiari.runtimeType}');
            _apiariCondivisi = [];
          }
        } catch (e) {
          print('Errore nel processare gli apiari: $e');
          _apiariCondivisi = [];
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore nel caricamento dei dati: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _navigateToApiarioDetail(dynamic apiarioId) {
    print('_navigateToApiarioDetail chiamato con: $apiarioId (${apiarioId.runtimeType})');
    try {
      // Converti l'ID in intero
      int id;
      if (apiarioId is String) {
        try {
          id = int.parse(apiarioId);
          print('Convertito ID da String a int: $apiarioId -> $id');
        } catch (e) {
          print('Errore nella conversione dell\'ID: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ID apiario non valido: $apiarioId'),
              backgroundColor: ThemeConstants.errorColor,
            ),
          );
          return;
        }
      } else if (apiarioId is int) {
        id = apiarioId;
        print('ID già intero: $id');
      } else {
        print('Tipo ID non supportato: ${apiarioId.runtimeType}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Formato ID apiario non supportato'),
            backgroundColor: ThemeConstants.errorColor,
          ),
        );
        return;
      }
      
      // Naviga alla pagina di dettaglio
      print('Navigazione a dettaglio apiario con ID: $id');
      Navigator.of(context).pushNamed(
        AppConstants.apiarioDetailRoute,
        arguments: id,
      );
    } catch (e, stackTrace) {
      print('Errore in _navigateToApiarioDetail: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nell\'accesso ai dettagli dell\'apiario: $e'),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      print('=== INIZIO BUILD CON INDICE: $_currentIndex ===');
      
      final authService = Provider.of<AuthService>(context);
      final user = authService.currentUser;
      
      bool isAdmin = false;
      bool isCreator = false;
      
      try {
        isAdmin = user != null && (_gruppo?.isAdmin(user.id) ?? false);
        isCreator = user != null && (_gruppo?.isCreator(user.id) ?? false);
      } catch (e) {
        print('Errore nella verifica dei permessi: $e');
        isAdmin = false;
        isCreator = false;
      }
      
      return Scaffold(
        appBar: AppBar(
          title: Text(_gruppo?.nome ?? 'Dettaglio Gruppo'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Aggiorna',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Membri'),
              Tab(icon: Icon(Icons.hive), text: 'Apiari'),
            ],
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                print('onTap: cambiato tab a $_currentIndex');
              });
            },
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ErrorDisplayWidget(
                    errorMessage: _errorMessage!,
                    onRetry: _loadData,
                  )
                : _gruppo == null
                    ? Center(child: Text('Gruppo non trovato'))
                    : IndexedStack(
                        index: _currentIndex,
                        children: [
                          _buildMembriTab(),
                          _buildApiariTab(),
                        ],
                      ),
        bottomNavigationBar: isCreator
            ? BottomAppBar(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showDeleteGruppoDialog(context);
                    },
                    icon: Icon(Icons.delete_forever),
                    label: Text('ELIMINA GRUPPO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConstants.errorColor,
                    ),
                  ),
                ),
              )
            : null,
      );
    } catch (e, stackTrace) {
      print('=== ERRORE CRITICO IN BUILD ===');
      print('$e');
      print('=== STACK TRACE ===');
      print('$stackTrace');
      
      return Scaffold(
        appBar: AppBar(
          title: Text('Errore'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: ThemeConstants.errorColor),
              SizedBox(height: 16),
              Text('Si è verificato un errore: $e'),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('TORNA INDIETRO'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _showDeleteGruppoDialog(BuildContext context) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Elimina gruppo'),
        content: Text('Sei sicuro di voler eliminare questo gruppo? Questa azione non può essere annullata.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('ELIMINA'),
            style: TextButton.styleFrom(
              foregroundColor: ThemeConstants.errorColor,
            ),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmDelete) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _gruppoService.deleteGruppo(widget.gruppoId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gruppo eliminato'),
        ),
      );
      
      // Torna alla lista gruppi
      Navigator.of(context).pushReplacementNamed(AppConstants.gruppiListRoute);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: ${e.toString()}'),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Tab Membri
  Widget _buildMembriTab() {
    try {
      if (_gruppo == null) return Container();

      final authService = Provider.of<AuthService>(context);
      final user = authService.currentUser;
      
      final bool isAdmin = user != null && _gruppo!.isAdmin(user.id);

      if (_gruppo!.membri.isEmpty) {
        return Center(
          child: Text('Nessun membro trovato'),
        );
      }

      return ListView.builder(
        itemCount: _gruppo!.membri.length,
        itemBuilder: (context, index) {
          try {
            final membro = _gruppo!.membri[index];
            
            // Controllo aggiuntivo per gestire diversi tipi di membri
            String username = '';
            String ruolo = '';
            bool isCreator = false;
            int membroId = 0;
            int utenteId = 0;
            
            if (membro is MembroGruppo) {
              username = membro.username;
              ruolo = membro.ruolo;
              membroId = membro.id;
              utenteId = membro.utenteId;
            } else if (membro is Map<String, dynamic>) {
              username = membro['username'] ?? membro['utente_username'] ?? 'Sconosciuto';
              ruolo = membro['ruolo'] ?? 'Sconosciuto';
              
              // Estrai l'ID del membro in modo sicuro
              var id = membro['id'];
              if (id is int) {
                membroId = id;
              } else if (id is String) {
                try {
                  membroId = int.parse(id);
                } catch (e) {
                  print('Errore nel parsing dell\'ID membro: $e');
                }
              }
              
              // Estrai l'ID dell'utente in modo sicuro
              var utente = membro['utente'];
              if (utente is int) {
                utenteId = utente;
              } else if (utente is String) {
                try {
                  utenteId = int.parse(utente);
                } catch (e) {
                  print('Errore nel parsing dell\'ID utente: $e');
                }
              } else if (utente is Map) {
                utenteId = utente['id'] ?? 0;
              }
            } else {
              print('Tipo membro non riconosciuto: ${membro.runtimeType}');
              return ListTile(
                title: Text('Membro non valido'),
                subtitle: Text('Errore nel formato dei dati'),
              );
            }
            
            // Verifica se il membro è il creatore del gruppo
            isCreator = utenteId == _gruppo!.creatoreId;
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: ThemeConstants.primaryColor,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(username),
              subtitle: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ThemeConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRuoloDisplay(ruolo),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ThemeConstants.primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  if (isCreator)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Creatore',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: isAdmin && !isCreator
                  ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'cambiaRuolo') {
                          _showCambiaRuoloDialog(context, membro, membroId);
                        } else if (value == 'rimuovi') {
                          _showRimuoviMembroDialog(context, membro, membroId, username);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'cambiaRuolo',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Cambia ruolo'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'rimuovi',
                          child: Row(
                            children: [
                              Icon(Icons.person_remove, size: 18, color: ThemeConstants.errorColor),
                              SizedBox(width: 8),
                              Text(
                                'Rimuovi dal gruppo',
                                style: TextStyle(color: ThemeConstants.errorColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : null,
            );
          } catch (e) {
            print('Errore nella costruzione della tile membro[$index]: $e');
            return ListTile(
              title: Text('Errore'),
              subtitle: Text('$e'),
              textColor: ThemeConstants.errorColor,
            );
          }
        },
      );
    } catch (e, stackTrace) {
      print('Errore nel tab membri: $e');
      print('Stack trace: $stackTrace');
      return Center(
        child: Text('Errore nel caricamento dei membri: $e'),
      );
    }
  }
  
  String _getRuoloDisplay(String ruolo) {
    switch (ruolo) {
      case 'admin':
        return 'Amministratore';
      case 'editor':
        return 'Editor';
      case 'viewer':
        return 'Visualizzatore';
      default:
        return ruolo;
    }
  }
  
  Future<void> _showCambiaRuoloDialog(BuildContext context, dynamic membro, int membroId) async {
    // Implementazione sicura ma semplificata
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funzionalità temporaneamente disabilitata'),
      ),
    );
  }
  
  Future<void> _showRimuoviMembroDialog(BuildContext context, dynamic membro, int membroId, String username) async {
    // Implementazione sicura ma semplificata
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funzionalità temporaneamente disabilitata'),
      ),
    );
  }
  
  // Tab Apiari
  Widget _buildApiariTab() {
    try {
      print('=== INIZIO COSTRUZIONE TAB APIARI ===');
      
      if (_apiariCondivisi.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hive_outlined,
                size: 64,
                color: ThemeConstants.textSecondaryColor.withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                'Nessun apiario condiviso con questo gruppo',
                style: TextStyle(
                  color: ThemeConstants.textSecondaryColor,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      print('Numero apiari condivisi: ${_apiariCondivisi.length}');

      return ListView.builder(
        itemCount: _apiariCondivisi.length,
        itemBuilder: (context, index) {
          try {
            final apiario = _apiariCondivisi[index];
            
            // Estrai in modo sicuro le informazioni necessarie
            String nome = '';
            String posizione = '';
            String proprietarioNome = '';
            dynamic apiarioId;
            
            if (apiario is Map<String, dynamic>) {
              nome = apiario['nome'] ?? 'Apiario senza nome';
              posizione = apiario['posizione'] ?? 'Posizione non specificata';
              proprietarioNome = apiario['proprietario_username'] ?? 'N/D';
              apiarioId = apiario['id'];
            } else {
              print('Tipo apiario non riconosciuto: ${apiario.runtimeType}');
              return ListTile(
                title: Text('Apiario non valido'),
                subtitle: Text('Errore nel formato dei dati'),
              );
            }
            
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () {
                  if (apiarioId != null) {
                    _navigateToApiarioDetail(apiarioId);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Impossibile visualizzare i dettagli: ID apiario mancante'),
                        backgroundColor: ThemeConstants.errorColor,
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              nome,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.chevron_right),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        posizione,
                        style: TextStyle(
                          color: ThemeConstants.textSecondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: ThemeConstants.textSecondaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Proprietario: $proprietarioNome',
                            style: TextStyle(
                              color: ThemeConstants.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          } catch (e) {
            print('Errore nella costruzione della card apiario[$index]: $e');
            return Card(
              color: Colors.red.shade50,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Errore nel caricamento dell\'apiario: $e'),
              ),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      print('=== ERRORE NEL TAB APIARI ===');
      print('$e');
      print('=== STACK TRACE ===');
      print('$stackTrace');
      return Center(
        child: Text('Errore nel caricamento degli apiari: $e'),
      );
    }
  }
}
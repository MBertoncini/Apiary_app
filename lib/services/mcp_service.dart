// lib/services/mcp_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class MCPService {
  final ApiService _apiService;
  
  MCPService(this._apiService);
  
  // Definisce gli strumenti disponibili per l'LLM
  Map<String, Function> get tools => {
    'getApiarioInfo': (int apiarioId) => _getApiarioInfo(apiarioId),
    'getArniaInfo': (int arniaId) => _getArniaInfo(arniaId),
    'getTrattamentiAttivi': () => _getTrattamentiAttivi(),
    'getControlliRecenti': (int? daysBack) => _getControlliRecenti(daysBack ?? 30),
    'getFioritureAttive': () => _getFioritureAttive(),
    'searchArnie': (String query) => _searchArnie(query),
    'getControlloDettagliato': (int controlloId) => _getControlloDettagliato(controlloId),
    'getRiepilogoArniaTelaini': (int arniaId) => _getRiepilogoArniaTelaini(arniaId),
    'generateArniaPopulationChart': (int arniaId, {int? months}) => 
      _generateArniaPopulationChart(arniaId, months ?? 6),
    'generateApiarioHealthChart': (int apiarioId) => 
      _generateApiarioHealthChart(apiarioId),
    'generateTrattamentiEffectivenessChart': (int apiarioId) => 
      _generateTrattamentiEffectivenessChart(apiarioId),
    'generateHoneyProductionChart': (int apiarioId, {int? years}) => 
      _generateHoneyProductionChart(apiarioId, years ?? 3),
  };
  
  // Metodo principale per preparare il contesto per il modello
  Future<Map<String, dynamic>> prepareContext(String userId) async {
    // Raccogli tutti i dati necessari in parallelo
    final resultsFutures = await Future.wait([
      _getApiari(),
      _getArnie(),
      _getTrattamenti(),
      _getControlliDettagliati(),  // Modificato per ottenere i controlli con dettagli
      _getRegine(),
    ]);
    
    // Compila il contesto completo
    return {
      'apiari': resultsFutures[0],
      'arnie': resultsFutures[1],
      'trattamenti': resultsFutures[2],
      'controlli': resultsFutures[3],
      'regine': resultsFutures[4],
      'timestamp': DateTime.now().toIso8601String(),
      'tools': tools.keys.toList(), // Aggiungiamo la lista degli strumenti disponibili
    };
  }
  
  // Metodo per eseguire una chiamata a strumento (tool call) da parte dell'LLM
  Future<Map<String, dynamic>> executeToolCall(String toolName, Map<String, dynamic> parameters) async {
    if (!tools.containsKey(toolName)) {
      return {'error': 'Tool not found: $toolName'};
    }
    
    try {
      switch (toolName) {
        case 'getApiarioInfo':
          if (!parameters.containsKey('apiarioId')) {
            return {'error': 'Missing parameter: apiarioId'};
          }
          return await _getApiarioInfo(parameters['apiarioId']);
          
        case 'getArniaInfo':
          if (!parameters.containsKey('arniaId')) {
            return {'error': 'Missing parameter: arniaId'};
          }
          return await _getArniaInfo(parameters['arniaId']);
        
        case 'getTrattamentiAttivi':
          return {'trattamenti': await _getTrattamentiAttivi()};
        
        case 'getControlliRecenti':
          int daysBack = parameters['daysBack'] ?? 30;
          return {'controlli': await _getControlliRecenti(daysBack)};
          
        case 'getFioritureAttive':
          return {'fioriture': await _getFioritureAttive()};
          
        case 'searchArnie':
          if (!parameters.containsKey('query')) {
            return {'error': 'Missing parameter: query'};
          }
          return {'results': await _searchArnie(parameters['query'])};
          
        case 'getControlloDettagliato':
          if (!parameters.containsKey('controlloId')) {
            return {'error': 'Missing parameter: controlloId'};
          }
          return await _getControlloDettagliato(parameters['controlloId']);
          
        case 'getRiepilogoArniaTelaini':
          if (!parameters.containsKey('arniaId')) {
            return {'error': 'Missing parameter: arniaId'};
          }
          return await _getRiepilogoArniaTelaini(parameters['arniaId']);
          case 'generateArniaPopulationChart':
        if (!parameters.containsKey('arniaId')) {
          return {'error': 'Missing parameter: arniaId'};
        }
        int months = parameters['months'] ?? 6;
        return await _generateArniaPopulationChart(parameters['arniaId'], months);
          
        case 'generateApiarioHealthChart':
          if (!parameters.containsKey('apiarioId')) {
            return {'error': 'Missing parameter: apiarioId'};
          }
          return await _generateApiarioHealthChart(parameters['apiarioId']);
          
        case 'generateTrattamentiEffectivenessChart':
          if (!parameters.containsKey('apiarioId')) {
            return {'error': 'Missing parameter: apiarioId'};
          }
          return await _generateTrattamentiEffectivenessChart(parameters['apiarioId']);
          
        case 'generateHoneyProductionChart':
          if (!parameters.containsKey('apiarioId')) {
            return {'error': 'Missing parameter: apiarioId'};
          }
          int years = parameters['years'] ?? 3;
          return await _generateHoneyProductionChart(parameters['apiarioId'], years);
        
      default:
        return {'error': 'Tool implementation not found: $toolName'};
    }
  } catch (e) {
    return {'error': 'Error executing tool $toolName: $e'};
  }
}

  
  // === STRUMENTI MCP (TOOLS) ===
  
  // Strumento: Ottieni informazioni sugli apiari
  Future<List<dynamic>> _getApiari() async {
    try {
      final response = await _apiService.get('apiari/');
      final List<dynamic> apiari = response is List ? response : (response['results'] ?? []);
      return apiari;
    } catch (e) {
      print('Errore nel recupero degli apiari: $e');
      return [];
    }
  }
  
  // Strumento: Ottieni informazioni sulle arnie
  Future<List<dynamic>> _getArnie() async {
    try {
      final response = await _apiService.get('arnie/');
      final List<dynamic> arnie = response is List ? response : (response['results'] ?? []);
      return arnie;
    } catch (e) {
      print('Errore nel recupero delle arnie: $e');
      return [];
    }
  }
  
  // Strumento: Ottieni informazioni sui trattamenti
  Future<List<dynamic>> _getTrattamenti() async {
    try {
      final response = await _apiService.get('trattamenti/');
      final List<dynamic> trattamenti = response is List ? response : (response['results'] ?? []);
      
      // Ordina i trattamenti per data di inizio (decrescente)
      trattamenti.sort((a, b) {
        final dateA = a['data_inizio'] != null ? DateTime.parse(a['data_inizio']) : DateTime(1970);
        final dateB = b['data_inizio'] != null ? DateTime.parse(b['data_inizio']) : DateTime(1970);
        return dateB.compareTo(dateA);
      });
      
      // Limita a trattamenti recenti e in corso
      return trattamenti.where((t) => 
        t['stato'] == 'in_corso' || 
        t['stato'] == 'programmato' ||
        (t['data_fine'] != null && 
          DateTime.parse(t['data_fine']).isAfter(DateTime.now().subtract(Duration(days: 30))))
      ).take(10).toList();
    } catch (e) {
      print('Errore nel recupero dei trattamenti: $e');
      return [];
    }
  }
  
  // Strumento: Ottieni solo trattamenti attivi
  Future<List<dynamic>> _getTrattamentiAttivi() async {
    try {
      final response = await _apiService.get('trattamenti/attivi/');
      final List<dynamic> trattamenti = response is List ? response : (response['results'] ?? []);
      return trattamenti;
    } catch (e) {
      print('Errore nel recupero dei trattamenti attivi: $e');
      return [];
    }
  }
  
  // MODIFICATO: Ottieni informazioni dettagliate sui controlli
  Future<List<dynamic>> _getControlliDettagliati() async {
    try {
      final response = await _apiService.get('controlli/');
      final List<dynamic> controlli = response is List ? response : (response['results'] ?? []);
      
      // Ordina i controlli per data (decrescente)
      controlli.sort((a, b) {
        final dateA = a['data'] != null ? DateTime.parse(a['data']) : DateTime(1970);
        final dateB = b['data'] != null ? DateTime.parse(b['data']) : DateTime(1970);
        return dateB.compareTo(dateA);
      });
      
      // Arricchisci i controlli con informazioni aggiuntive
      List<dynamic> controlliDettagliati = [];
      
      for (var controllo in controlli.take(10)) {
        // Decodifica la configurazione dei telaini se presente
        List<String> telainiConfig = [];
        if (controllo['telaini_config'] != null && controllo['telaini_config'].isNotEmpty) {
          try {
            final List<dynamic> config = json.decode(controllo['telaini_config']);
            telainiConfig = List<String>.from(config);
          } catch (e) {
            print('Errore nel parsing della configurazione telaini: $e');
            telainiConfig = List.filled(10, 'vuoto');
          }
        } else {
          // Se non c'è configurazione, crea una distribuzione di default
          telainiConfig = _generaConfigurazioneDiDefault(
            controllo['telaini_scorte'] ?? 0, 
            controllo['telaini_covata'] ?? 0
          );
        }
        
        // Conta i diversi tipi di telaini
        int telainiVuoti = telainiConfig.where((t) => t == 'vuoto').length;
        int telainiDiaframma = telainiConfig.where((t) => t == 'diaframma').length;
        int telainiNutritore = telainiConfig.where((t) => t == 'nutritore').length;
        
        // Crea un riepilogo con maggiori informazioni
        Map<String, dynamic> controlloDettagliato = Map<String, dynamic>.from({
          ...controllo,
          'telaini_config_decoded': telainiConfig,
          'telaini_vuoti': telainiVuoti,
          'telaini_diaframma': telainiDiaframma,
          'telaini_nutritore': telainiNutritore,
          'stato_regina': {
            'presente': controllo['presenza_regina'] ?? false,
            'vista': controllo['regina_vista'] ?? false,
            'uova_fresche': controllo['uova_fresche'] ?? false,
            'celle_reali': controllo['celle_reali'] ?? false,
            'numero_celle_reali': controllo['numero_celle_reali'] ?? 0,
            'sostituita': controllo['regina_sostituita'] ?? false,
          }
        });
        
        controlliDettagliati.add(controlloDettagliato);
      }
      
      return controlliDettagliati;
    } catch (e) {
      print('Errore nel recupero dei controlli dettagliati: $e');
      return [];
    }
  }
  
  // Lista per vedere i controlli degli ultimi X giorni (con informazioni dettagliate)
  Future<List<dynamic>> _getControlliRecenti(int daysBack) async {
    try {
      final response = await _apiService.get('controlli/');
      final List<dynamic> controlli = response is List ? response : (response['results'] ?? []);
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));
      
      // Filtra per data
      final recenti = controlli.where((c) {
        if (c['data'] == null) return false;
        final date = DateTime.parse(c['data']);
        return date.isAfter(cutoffDate);
      }).toList();
      
      // Ordina per data (più recenti prima)
      recenti.sort((a, b) {
        final dateA = DateTime.parse(a['data']);
        final dateB = DateTime.parse(b['data']);
        return dateB.compareTo(dateA);
      });
      
      // Arricchisci i controlli con informazioni aggiuntive
      List<dynamic> controlliDettagliati = [];
      
      for (var controllo in recenti) {
        // Decodifica la configurazione dei telaini se presente
        List<String> telainiConfig = [];
        if (controllo['telaini_config'] != null && controllo['telaini_config'].isNotEmpty) {
          try {
            final List<dynamic> config = json.decode(controllo['telaini_config']);
            telainiConfig = List<String>.from(config);
          } catch (e) {
            print('Errore nel parsing della configurazione telaini: $e');
            telainiConfig = List.filled(10, 'vuoto');
          }
        } else {
          // Se non c'è configurazione, crea una distribuzione di default
          telainiConfig = _generaConfigurazioneDiDefault(
            controllo['telaini_scorte'] ?? 0, 
            controllo['telaini_covata'] ?? 0
          );
        }
        
        // Conta i diversi tipi di telaini
        int telainiVuoti = telainiConfig.where((t) => t == 'vuoto').length;
        int telainiDiaframma = telainiConfig.where((t) => t == 'diaframma').length;
        int telainiNutritore = telainiConfig.where((t) => t == 'nutritore').length;
        
        // Crea un riepilogo con maggiori informazioni
        Map<String, dynamic> controlloDettagliato = Map<String, dynamic>.from({
          ...controllo,
          'telaini_config_decoded': telainiConfig,
          'telaini_vuoti': telainiVuoti,
          'telaini_diaframma': telainiDiaframma,
          'telaini_nutritore': telainiNutritore,
          'stato_regina': {
            'presente': controllo['presenza_regina'] ?? false,
            'vista': controllo['regina_vista'] ?? false,
            'uova_fresche': controllo['uova_fresche'] ?? false,
            'celle_reali': controllo['celle_reali'] ?? false,
            'numero_celle_reali': controllo['numero_celle_reali'] ?? 0,
            'sostituita': controllo['regina_sostituita'] ?? false,
          }
        });
        
        controlliDettagliati.add(controlloDettagliato);
      }
      
      return controlliDettagliati;
    } catch (e) {
      print('Errore nel recupero dei controlli recenti dettagliati: $e');
      return [];
    }
  }
  
  // NUOVO: Ottieni dettagli specifici di un controllo
  Future<Map<String, dynamic>> _getControlloDettagliato(int controlloId) async {
    try {
      final response = await _apiService.get('controlli/$controlloId/');
      
      // Decodifica la configurazione dei telaini se presente
      List<String> telainiConfig = [];
      if (response['telaini_config'] != null && response['telaini_config'].isNotEmpty) {
        try {
          final List<dynamic> config = json.decode(response['telaini_config']);
          telainiConfig = List<String>.from(config);
        } catch (e) {
          print('Errore nel parsing della configurazione telaini: $e');
          telainiConfig = List.filled(10, 'vuoto');
        }
      } else {
        // Se non c'è configurazione, crea una distribuzione di default
        telainiConfig = _generaConfigurazioneDiDefault(
          response['telaini_scorte'] ?? 0, 
          response['telaini_covata'] ?? 0
        );
      }
      
      // Conta i diversi tipi di telaini
      int telainiVuoti = telainiConfig.where((t) => t == 'vuoto').length;
      int telainiDiaframma = telainiConfig.where((t) => t == 'diaframma').length;
      int telainiNutritore = telainiConfig.where((t) => t == 'nutritore').length;
      
      // Crea un riepilogo con dati completi
      return {
        'controllo': {
          ...response,
          'telaini_config_decoded': telainiConfig,
          'telaini_vuoti': telainiVuoti,
          'telaini_diaframma': telainiDiaframma,
          'telaini_nutritore': telainiNutritore,
          'stato_regina': {
            'presente': response['presenza_regina'] ?? false,
            'vista': response['regina_vista'] ?? false,
            'uova_fresche': response['uova_fresche'] ?? false,
            'celle_reali': response['celle_reali'] ?? false,
            'numero_celle_reali': response['numero_celle_reali'] ?? 0,
            'sostituita': response['regina_sostituita'] ?? false,
          },
          'problemi': {
            'sciamatura': response['sciamatura'] ?? false,
            'note_sciamatura': response['note_sciamatura'],
            'problemi_sanitari': response['problemi_sanitari'] ?? false,
            'note_problemi': response['note_problemi'],
          }
        }
      };
    } catch (e) {
      print('Errore nel recupero dei dettagli del controllo: $e');
      return {'error': e.toString()};
    }
  }
  
  // NUOVO: Ottieni riepilogo sulla situazione dei telaini di un'arnia
  Future<Map<String, dynamic>> _getRiepilogoArniaTelaini(int arniaId) async {
    try {
      // Recupera l'ultimo controllo dell'arnia
      final controlliResponse = await _apiService.get('arnie/$arniaId/controlli/');
      final List<dynamic> controlli = controlliResponse['results'] ?? [];
      
      if (controlli.isEmpty) {
        return {
          'message': 'Nessun controllo disponibile per questa arnia',
          'arnia_id': arniaId
        };
      }
      
      // Ordina per data (più recenti prima)
      controlli.sort((a, b) {
        final dateA = DateTime.parse(a['data']);
        final dateB = DateTime.parse(b['data']);
        return dateB.compareTo(dateA);
      });
      
      // Prendi l'ultimo controllo
      final ultimoControllo = controlli.first;
      
      // Decodifica la configurazione dei telaini
      List<String> telainiConfig = [];
      if (ultimoControllo['telaini_config'] != null && ultimoControllo['telaini_config'].isNotEmpty) {
        try {
          final List<dynamic> config = json.decode(ultimoControllo['telaini_config']);
          telainiConfig = List<String>.from(config);
        } catch (e) {
          print('Errore nel parsing della configurazione telaini: $e');
          telainiConfig = List.filled(10, 'vuoto');
        }
      } else {
        // Se non c'è configurazione, crea una distribuzione di default
        telainiConfig = _generaConfigurazioneDiDefault(
          ultimoControllo['telaini_scorte'] ?? 0, 
          ultimoControllo['telaini_covata'] ?? 0
        );
      }
      
      // Prepara una descrizione testuale della configurazione
      String descrizioneTelaini = _generaDescrizioneTelaini(telainiConfig);
      
      // Conta i diversi tipi di telaini
      int telainiScorte = telainiConfig.where((t) => t == 'scorte').length;
      int telainiCovata = telainiConfig.where((t) => t == 'covata').length;
      int telainiVuoti = telainiConfig.where((t) => t == 'vuoto').length;
      int telainiDiaframma = telainiConfig.where((t) => t == 'diaframma').length;
      int telainiNutritore = telainiConfig.where((t) => t == 'nutritore').length;
      
      // Calcola lo stato e tendenza
      String statoFamiglia = "normale";
      if (telainiCovata >= 5) statoFamiglia = "forte";
      else if (telainiCovata <= 2) statoFamiglia = "debole";
      
      // Confronta con il controllo precedente se disponibile
      String tendenza = "stabile";
      if (controlli.length > 1) {
        final controlloPrecedente = controlli[1];
        final telainiCovataPrecedente = controlloPrecedente['telaini_covata'] ?? 0;
        final differenza = telainiCovata - telainiCovataPrecedente;
        
        if (differenza >= 2) tendenza = "in crescita";
        else if (differenza <= -2) tendenza = "in diminuzione";
      }
      
      return {
        'arnia_id': arniaId,
        'ultimo_controllo_data': ultimoControllo['data'],
        'giorni_da_ultimo_controllo': DateTime.now().difference(DateTime.parse(ultimoControllo['data'])).inDays,
        'configurazione_telaini': telainiConfig,
        'descrizione_telaini': descrizioneTelaini,
        'conteggio': {
          'telaini_scorte': telainiScorte,
          'telaini_covata': telainiCovata,
          'telaini_vuoti': telainiVuoti,
          'telaini_diaframma': telainiDiaframma,
          'telaini_nutritore': telainiNutritore,
          'totale_telaini': telainiConfig.length
        },
        'stato_famiglia': statoFamiglia,
        'tendenza_famiglia': tendenza,
        'presenza_regina': ultimoControllo['presenza_regina'] ?? false,
        'regina_vista': ultimoControllo['regina_vista'] ?? false,
        'uova_fresche': ultimoControllo['uova_fresche'] ?? false,
        'celle_reali': ultimoControllo['celle_reali'] ?? false,
        'problemi_sanitari': ultimoControllo['problemi_sanitari'] ?? false,
        'note': ultimoControllo['note']
      };
    } catch (e) {
      print('Errore nel recupero del riepilogo telaini: $e');
      return {'error': e.toString()};
    }
  }
  
  // Strumento: Ottieni fioriture attive
  Future<List<dynamic>> _getFioritureAttive() async {
    try {
      final response = await _apiService.get('fioriture/');
      final List<dynamic> fioriture = response is List ? response : (response['results'] ?? []);
      
      // Filtra per fioriture attive
      return fioriture.where((f) => f['is_active'] == true).toList();
    } catch (e) {
      print('Errore nel recupero delle fioriture attive: $e');
      return [];
    }
  }
  
  // Strumento: Ottieni informazioni sulle regine
  Future<List<dynamic>> _getRegine() async {
    try {
      final response = await _apiService.get('regine/');
      final List<dynamic> regine = response is List ? response : (response['results'] ?? []);
      return regine;
    } catch (e) {
      print('Errore nel recupero delle regine: $e');
      return [];
    }
  }
  
  // Strumento: Cerca arnie per nome o numero
  Future<List<dynamic>> _searchArnie(String query) async {
    try {
      final response = await _apiService.get('arnie/');
      final List<dynamic> arnie = response is List ? response : (response['results'] ?? []);
      
      // Filtra le arnie in base alla query
      return arnie.where((arnia) {
        final numero = arnia['numero']?.toString() ?? '';
        final stato = arnia['stato']?.toString() ?? '';
        final apiarioNome = arnia['apiario_nome']?.toString() ?? '';
        
        return numero.toLowerCase().contains(query.toLowerCase()) ||
               stato.toLowerCase().contains(query.toLowerCase()) ||
               apiarioNome.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      print('Errore nella ricerca delle arnie: $e');
      return [];
    }
  }
  
  // MODIFICATO: Metodo per recuperare dati specifici per un apiario (con dettagli sui controlli)
  Future<Map<String, dynamic>> _getApiarioInfo(int apiarioId) async {
    try {
      // Recupera dettagli dell'apiario
      final apiarioDetails = await _apiService.get('apiari/$apiarioId/');
      
      // Recupera le arnie dell'apiario
      final arnieResponse = await _apiService.get('apiari/$apiarioId/arnie/');
      final List<dynamic> arnie = arnieResponse['results'] ?? [];
      
      // Recupera i trattamenti dell'apiario
      final trattamentiResponse = await _apiService.get('apiari/$apiarioId/trattamenti/');
      final List<dynamic> trattamenti = trattamentiResponse['results'] ?? [];
      
      // Recupera controlli recenti per tutte le arnie dell'apiario
      List<dynamic> controlliApiario = [];
      for (var arnia in arnie) {
        try {
          final controlliResponse = await _apiService.get('arnie/${arnia['id']}/controlli/');
          final List<dynamic> controlli = controlliResponse['results'] ?? [];
          
          if (controlli.isNotEmpty) {
            // Ordina per data (più recenti prima)
            controlli.sort((a, b) {
              final dateA = DateTime.parse(a['data']);
              final dateB = DateTime.parse(b['data']);
              return dateB.compareTo(dateA);
            });
            
            // Aggiungi solo l'ultimo controllo di ciascuna arnia
            var controllo = controlli.first;
            
            // Decodifica la configurazione dei telaini
            List<String> telainiConfig = [];
            if (controllo['telaini_config'] != null && controllo['telaini_config'].isNotEmpty) {
              try {
                final List<dynamic> config = json.decode(controllo['telaini_config']);
                telainiConfig = List<String>.from(config);
              } catch (e) {
                print('Errore nel parsing della configurazione telaini: $e');
                telainiConfig = List.filled(10, 'vuoto');
              }
            }
            
            controlliApiario.add(Map<String, dynamic>.from({
              ...controllo,
              'arnia_numero': arnia['numero'],
              'telaini_config_decoded': telainiConfig,
              'stato_regina': {
                'presente': controllo['presenza_regina'] ?? false,
                'vista': controllo['regina_vista'] ?? false,
                'uova_fresche': controllo['uova_fresche'] ?? false,
              }
            }));
          }
        } catch (e) {
          print('Errore nel recupero dei controlli per arnia ${arnia['id']}: $e');
        }
      }
      
      return {
        'apiario': apiarioDetails,
        'arnie': arnie,
        'trattamenti': trattamenti,
        'ultimi_controlli': controlliApiario,
      };
    } catch (e) {
      print('Errore nel recupero delle informazioni dell\'apiario: $e');
      return {'error': e.toString()};
    }
  }
  
  // MODIFICATO: Metodo per recuperare dati specifici per un'arnia (con dettagli sul controllo)
  Future<Map<String, dynamic>> _getArniaInfo(int arniaId) async {
    try {
      // Recupera dettagli dell'arnia
      final arniaDetails = await _apiService.get('arnie/$arniaId/');
      
      // Recupera la regina dell'arnia
      final reginaResponse = await _apiService.get('arnie/$arniaId/regina/');
      
      // Recupera i controlli dell'arnia
      final controlliResponse = await _apiService.get('arnie/$arniaId/controlli/');
      final List<dynamic> controlli = controlliResponse['results'] ?? [];
      
      // Ordina i controlli per data (più recenti prima)
      controlli.sort((a, b) {
        final dateA = DateTime.parse(a['data']);
        final dateB = DateTime.parse(b['data']);
        return dateB.compareTo(dateA);
      });
      
      // Arricchisci i controlli con informazioni aggiuntive
      List<dynamic> controlliDettagliati = [];
      
      for (var controllo in controlli) {
        // Decodifica la configurazione dei telaini se presente
        List<String> telainiConfig = [];
        if (controllo['telaini_config'] != null && controllo['telaini_config'].isNotEmpty) {
          try {
            final List<dynamic> config = json.decode(controllo['telaini_config']);
            telainiConfig = List<String>.from(config);
          } catch (e) {
            print('Errore nel parsing della configurazione telaini: $e');
            telainiConfig = List.filled(10, 'vuoto');
          }
        } else {
          // Se non c'è configurazione, crea una distribuzione di default
          telainiConfig = _generaConfigurazioneDiDefault(
            controllo['telaini_scorte'] ?? 0, 
            controllo['telaini_covata'] ?? 0
          );
        }
        
        // Crea un riepilogo con maggiori informazioni
        Map<String, dynamic> controlloDettagliato = Map<String, dynamic>.from({
          ...controllo,
          'telaini_config_decoded': telainiConfig,
          'stato_regina': {
            'presente': controllo['presenza_regina'] ?? false,
            'vista': controllo['regina_vista'] ?? false,
            'uova_fresche': controllo['uova_fresche'] ?? false,
            'celle_reali': controllo['celle_reali'] ?? false,
            'numero_celle_reali': controllo['numero_celle_reali'] ?? 0,
            'sostituita': controllo['regina_sostituita'] ?? false,
          },
          'problemi': {
            'sciamatura': controllo['sciamatura'] ?? false,
            'note_sciamatura': controllo['note_sciamatura'],
            'problemi_sanitari': controllo['problemi_sanitari'] ?? false,
            'note_problemi': controllo['note_problemi'],
          }
        });
        
        controlliDettagliati.add(controlloDettagliato);
      }
      
      // Estrai l'ultimo controllo per un accesso rapido
      Map<String, dynamic>? ultimoControllo = null;
      if (controlliDettagliati.isNotEmpty) {
        ultimoControllo = Map<String, dynamic>.from(controlliDettagliati.first);
      }
      
      return {
        'arnia': arniaDetails,
        'regina': reginaResponse,
        'controlli': controlliDettagliati,
        'ultimo_controllo': ultimoControllo,
      };
    } catch (e) {
      print('Errore nel recupero delle informazioni dell\'arnia: $e');
      return {'error': e.toString()};
    }
  }
  
  // NUOVO: Metodo helper per generare una configurazione di default per i telaini
  List<String> _generaConfigurazioneDiDefault(int telainiScorte, int telainiCovata) {
    List<String> telainiConfig = List.filled(10, 'vuoto');
    
    // Calcola la posizione centrale
    final middle = 10 ~/ 2;
    final halfCovata = telainiCovata ~/ 2;
    
    // Posiziona la covata al centro
    for (int i = 0; i < telainiCovata; i++) {
      final pos = middle - halfCovata + i;
      if (pos >= 0 && pos < 10) {
        telainiConfig[pos] = 'covata';
      }
    }
    
    // Posiziona le scorte ai lati
    int scorteLeft = telainiScorte ~/ 2;
    int scorteRight = telainiScorte - scorteLeft;
    
    // Lato sinistro
    for (int i = 0; i < scorteLeft; i++) {
      final pos = middle - halfCovata - 1 - i;
      if (pos >= 0) {
        telainiConfig[pos] = 'scorte';
      }
    }
    
    // Lato destro
    for (int i = 0; i < scorteRight; i++) {
      final pos = middle + halfCovata + i;
      if (pos < 10) {
        telainiConfig[pos] = 'scorte';
      }
    }
    
    return telainiConfig;
  }
  
  // NUOVO: Metodo helper per generare una descrizione testuale della configurazione dei telaini
  String _generaDescrizioneTelaini(List<String> telainiConfig) {
    // Conta i diversi tipi di telaini
    int telainiScorte = telainiConfig.where((t) => t == 'scorte').length;
    int telainiCovata = telainiConfig.where((t) => t == 'covata').length;
    int telainiVuoti = telainiConfig.where((t) => t == 'vuoto').length;
    int telainiDiaframma = telainiConfig.where((t) => t == 'diaframma').length;
    int telainiNutritore = telainiConfig.where((t) => t == 'nutritore').length;
    
    List<String> parti = [];
    
    // Aggiungi descrizioni per i diversi tipi
    if (telainiCovata > 0) {
      parti.add('$telainiCovata telaini di covata');
    }
    
    if (telainiScorte > 0) {
      parti.add('$telainiScorte telaini di scorte');
    }
    
    if (telainiVuoti > 0) {
      parti.add('$telainiVuoti telaini vuoti');
    }
    
    if (telainiDiaframma > 0) {
      parti.add('$telainiDiaframma diaframma/i');
    }
    
    if (telainiNutritore > 0) {
      parti.add('$telainiNutritore nutritore/i');
    }
    
    // Descrivi la distribuzione
    String distribuzione = '';
    if (telainiCovata > 0 && telainiScorte > 0) {
      bool covataAlCentro = _isCovataAlCentro(telainiConfig);
      if (covataAlCentro) {
        distribuzione = ' (covata al centro, scorte ai lati)';
      } else {
        distribuzione = ' (distribuzione mista)';
      }
    }
    
    return parti.join(', ') + distribuzione;
  }
  
  // NUOVO: Metodo helper per verificare se la covata è disposta al centro
  bool _isCovataAlCentro(List<String> telainiConfig) {
    int firstCovata = telainiConfig.indexOf('covata');
    int lastCovata = telainiConfig.lastIndexOf('covata');
    
    if (firstCovata == -1) return false; // Non c'è covata
    
    // Verifica se tutti i telaini di covata sono contigui
    for (int i = firstCovata; i <= lastCovata; i++) {
      if (telainiConfig[i] != 'covata') return false;
    }
    
    // Verifica se la covata è grossomodo al centro
    int middle = telainiConfig.length ~/ 2;
    int covataCenter = (firstCovata + lastCovata) ~/ 2;
    
    return (covataCenter - middle).abs() <= 1; // Tollera una leggera asimmetria
  }

  // Implementazione per grafico andamento popolazione di un'arnia
  Future<Map<String, dynamic>> _generateArniaPopulationChart(int arniaId, int months) async {
    try {
      // Recupera i controlli dell'arnia
      final controlliResponse = await _apiService.get('arnie/$arniaId/controlli/');
      final List<dynamic> controlli = controlliResponse['results'] ?? [];
      
      // Calcola la data di inizio per il periodo richiesto
      final startDate = DateTime.now().subtract(Duration(days: 30 * months));
      
      // Filtra i controlli per il periodo richiesto e ordinali per data
      final filteredControlli = controlli.where((controllo) {
        if (controllo['data'] == null) return false;
        final date = DateTime.parse(controllo['data']);
        return date.isAfter(startDate);
      }).toList();
      
      filteredControlli.sort((a, b) {
        final dateA = DateTime.parse(a['data']);
        final dateB = DateTime.parse(b['data']);
        return dateA.compareTo(dateB);
      });
      
      // Prepara i dati per il grafico
      List<Map<String, dynamic>> chartData = [];
      for (var controllo in filteredControlli) {
        chartData.add({
          'date': controllo['data'],
          'telaini_covata': controllo['telaini_covata'] ?? 0,
          'telaini_scorte': controllo['telaini_scorte'] ?? 0,
          'telaini_totali': (controllo['telaini_covata'] ?? 0) + (controllo['telaini_scorte'] ?? 0),
        });
      }
      
      // Restituisci i dati e metadati per il grafico
      return {
        'arnia_id': arniaId,
        'title': 'Andamento popolazione arnia $arniaId',
        'x_axis': 'Data',
        'y_axis': 'Numero telaini',
        'data': chartData,
        'series': [
          {'name': 'Telaini di covata', 'data_key': 'telaini_covata', 'color': '#4e79a7'},
          {'name': 'Telaini di scorte', 'data_key': 'telaini_scorte', 'color': '#f28e2c'},
          {'name': 'Telaini totali', 'data_key': 'telaini_totali', 'color': '#59a14f'},
        ],
        'chart_type': 'line',
      };
    } catch (e) {
      print('Errore nella generazione del grafico: $e');
      return {'error': e.toString()};
    }
  }

  // Implementazione per grafico stato di salute delle arnie in un apiario
  Future<Map<String, dynamic>> _generateApiarioHealthChart(int apiarioId) async {
    try {
      // Recupera le arnie dell'apiario
      final arnieResponse = await _apiService.get('apiari/$apiarioId/arnie/');
      final List<dynamic> arnie = arnieResponse['results'] ?? [];
      
      // Prepara i dati per il grafico
      List<Map<String, dynamic>> chartData = [];
      for (var arnia in arnie) {
        // Ottieni l'ultimo controllo per ogni arnia
        final controlliResponse = await _apiService.get('arnie/${arnia['id']}/controlli/?limit=1');
        final List<dynamic> controlli = controlliResponse['results'] ?? [];
        
        if (controlli.isNotEmpty) {
          final controllo = controlli.first;
          
          // Calcola un punteggio di salute basato su vari fattori
          int healthScore = 0;
          
          // Presenza regina e covata contribuiscono al punteggio
          if (controllo['presenza_regina'] == true) healthScore += 30;
          if (controllo['uova_fresche'] == true) healthScore += 20;
          
          // Problemi sanitari riducono il punteggio
          if (controllo['problemi_sanitari'] == true) healthScore -= 30;
          
          // Telaini di covata contribuiscono al punteggio
          int telainiCovata = controllo['telaini_covata'] ?? 0;
          healthScore += telainiCovata * 5; // 5 punti per ogni telaino di covata
          
          // Limita il punteggio tra 0 e 100
          healthScore = healthScore.clamp(0, 100);
          
          chartData.add({
            'arnia_numero': arnia['numero'],
            'health_score': healthScore,
            'telaini_covata': telainiCovata,
            'presenza_regina': controllo['presenza_regina'] ?? false,
            'problemi_sanitari': controllo['problemi_sanitari'] ?? false,
          });
        } else {
          // Se non ci sono controlli, indichiamo uno stato sconosciuto
          chartData.add({
            'arnia_numero': arnia['numero'],
            'health_score': null, // null indica che non abbiamo dati
            'note': 'Nessun controllo disponibile'
          });
        }
      }
      
      // Ordina i dati per numero arnia
      chartData.sort((a, b) => a['arnia_numero'].compareTo(b['arnia_numero']));
      
      return {
        'apiario_id': apiarioId,
        'title': 'Stato di salute delle arnie',
        'data': chartData,
        'chart_type': 'bar',
        'x_axis': 'Arnia',
        'y_axis': 'Punteggio di salute (0-100)',
      };
    } catch (e) {
      print('Errore nella generazione del grafico: $e');
      return {'error': e.toString()};
    }
  }

  // Implementazione per grafico efficacia trattamenti
  Future<Map<String, dynamic>> _generateTrattamentiEffectivenessChart(int apiarioId) async {
    try {
      // Recupera i trattamenti dell'apiario
      final trattamentiResponse = await _apiService.get('apiari/$apiarioId/trattamenti/');
      final List<dynamic> trattamenti = trattamentiResponse['results'] ?? [];
      
      // Filtra solo i trattamenti completati
      final completedTrattamenti = trattamenti.where((t) => t['stato'] == 'completato').toList();
      
      // Raggruppa per tipo di trattamento
      Map<String, List<dynamic>> groupedTrattamenti = {};
      
      for (var trattamento in completedTrattamenti) {
        final tipoNome = trattamento['tipo_trattamento_nome'] ?? 'Sconosciuto';
        if (!groupedTrattamenti.containsKey(tipoNome)) {
          groupedTrattamenti[tipoNome] = [];
        }
        groupedTrattamenti[tipoNome]!.add(trattamento);
      }
      
      // Prepara i dati per il grafico
      List<Map<String, dynamic>> chartData = [];
      
      groupedTrattamenti.forEach((tipoNome, treatments) {
        // Calcola la percentuale di efficacia (esempio semplificato)
        int totale = treatments.length;
        int efficaci = treatments.where((t) => 
          t['efficace'] == true || 
          (t['note_completamento'] != null && 
          !t['note_completamento'].toLowerCase().contains('fallito') && 
          !t['note_completamento'].toLowerCase().contains('inefficace'))
        ).length;
        
        double efficaciaPerc = totale > 0 ? (efficaci / totale) * 100 : 0;
        
        chartData.add({
          'tipo_trattamento': tipoNome,
          'totale': totale,
          'efficaci': efficaci,
          'efficacia_perc': efficaciaPerc.round(),
        });
      });
      
      return {
        'apiario_id': apiarioId,
        'title': 'Efficacia dei trattamenti',
        'data': chartData,
        'chart_type': 'bar',
        'x_axis': 'Tipo di trattamento',
        'y_axis': 'Efficacia (%)',
      };
    } catch (e) {
      print('Errore nella generazione del grafico: $e');
      return {'error': e.toString()};
    }
  }

  // Implementazione per grafico produzione miele
  Future<Map<String, dynamic>> _generateHoneyProductionChart(int apiarioId, int years) async {
    try {
      // Recupera le smielature dell'apiario
      final smielatureResponse = await _apiService.get('apiari/$apiarioId/smielature/');
      final List<dynamic> smielature = smielatureResponse['results'] ?? [];
      
      // Calcola la data di inizio per il periodo richiesto
      final startDate = DateTime(DateTime.now().year - years, 1, 1);
      
      // Filtra le smielature per il periodo richiesto
      final filteredSmielature = smielature.where((smielatura) {
        if (smielatura['data'] == null) return false;
        final date = DateTime.parse(smielatura['data']);
        return date.isAfter(startDate);
      }).toList();
      
      // Raggruppa per anno e tipo di miele
      Map<int, Map<String, double>> productionyByYearAndType = {};
      
      for (var smielatura in filteredSmielature) {
        final date = DateTime.parse(smielatura['data']);
        final year = date.year;
        final tipoMiele = smielatura['tipo_miele'] ?? 'Millefiori';
        final quantita = smielatura['quantita'] ?? 0.0;
        
        if (!productionyByYearAndType.containsKey(year)) {
          productionyByYearAndType[year] = {};
        }
        
        if (!productionyByYearAndType[year]!.containsKey(tipoMiele)) {
          productionyByYearAndType[year]![tipoMiele] = 0.0;
        }
        
        productionyByYearAndType[year]![tipoMiele] = 
            productionyByYearAndType[year]![tipoMiele]! + quantita;
      }
      
      // Prepara i dati per il grafico
      List<Map<String, dynamic>> chartData = [];
      
      // Ordina gli anni in modo crescente
      final sortedYears = productionyByYearAndType.keys.toList()..sort();
      
      // Trova tutti i tipi di miele presenti
      Set<String> allHoneyTypes = {};
      productionyByYearAndType.forEach((year, typeMap) {
        allHoneyTypes.addAll(typeMap.keys);
      });
      
      // Crea dati strutturati per ogni anno
      for (var year in sortedYears) {
        Map<String, dynamic> yearData = {'year': year};
        
        // Aggiungi ogni tipo di miele, usando 0 se non presente
        for (var honeyType in allHoneyTypes) {
          yearData[honeyType] = productionyByYearAndType[year]![honeyType] ?? 0.0;
        }
        
        // Aggiungi anche il totale
        double totalForYear = 0.0;
        productionyByYearAndType[year]!.forEach((type, quantity) {
          totalForYear += quantity;
        });
        yearData['total'] = totalForYear;
        
        chartData.add(yearData);
      }
      
      // Prepara le serie per il grafico
      List<Map<String, dynamic>> series = [
        {'name': 'Totale', 'data_key': 'total', 'color': '#000000'}
      ];
      
      // Aggiungi una serie per ogni tipo di miele
      List<String> colors = ['#4e79a7', '#f28e2c', '#59a14f', '#e15759', '#76b7b2', '#edc949'];
      int colorIndex = 0;
      
      for (var honeyType in allHoneyTypes) {
        series.add({
          'name': honeyType,
          'data_key': honeyType,
          'color': colors[colorIndex % colors.length],
        });
        colorIndex++;
      }
      
      return {
        'apiario_id': apiarioId,
        'title': 'Produzione di miele negli ultimi $years anni',
        'data': chartData,
        'series': series,
        'chart_type': 'bar',
        'x_axis': 'Anno',
        'y_axis': 'Kg di miele',
      };
    } catch (e) {
      print('Errore nella generazione del grafico: $e');
      return {'error': e.toString()};
    }
  }
}

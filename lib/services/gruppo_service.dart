// File: lib/services/gruppo_service.dart
import 'dart:convert';
import '../constants/api_constants.dart';
import '../models/gruppo.dart';
import 'api_service.dart';
import 'storage_service.dart';

class GruppoService {
  final ApiService _apiService;
  final StorageService _storageService;

  GruppoService(this._apiService, this._storageService);

  // Ottiene la lista dei gruppi dell'utente
  Future<List<Gruppo>> getGruppi() async {
    try {
      final response = await _apiService.get(ApiConstants.gruppiUrl);
      
      if (response['results'] != null) {
        List<Gruppo> gruppi = (response['results'] as List)
            .map((gruppoJson) => Gruppo.fromJson(gruppoJson))
            .toList();
        
        // Salva i gruppi in locale
        await _storageService.saveData('gruppi', response['results']);
        
        return gruppi;
      }
      
      return [];
    } catch (e) {
      // Se c'è un errore, prova a recuperare i dati locali
      final localData = await _storageService.getStoredData('gruppi');
      
      if (localData.isNotEmpty) {
        return localData.map((gruppoJson) => Gruppo.fromJson(gruppoJson)).toList();
      }
      
      rethrow;
    }
  }

// Modifica il metodo getGruppoDetail in gruppo_service.dart

  Future<Gruppo> getGruppoDetail(int gruppoId) async {
    try {
      // 1. Carica i dati base del gruppo
      final String endpoint = '${ApiConstants.gruppiUrl}$gruppoId/';
      print('=== CARICAMENTO GRUPPO DETAIL ===');
      final response = await _apiService.get(endpoint);
      Gruppo gruppoBase = Gruppo.fromJson(response);
      
      List<dynamic> membri = [];
      List<int> apiariIds = [];
      
      // 2. Carica i membri (chiamata separata)
      try {
        membri = await getGruppoMembri(gruppoId);
        print('=== MEMBRI CARICATI ===');
        print('Membri tipo: ${membri.runtimeType}');
        print('Membri: $membri');
      } catch (e, stackTrace) {
        print('=== ERRORE NEL CARICAMENTO MEMBRI ===');
        print('$e');
        print('=== STACK TRACE ===');
        print('$stackTrace');
      }
      
      // 3. Carica gli apiari condivisi (chiamata separata)
      try {
        final apiari = await getApiariGruppo(gruppoId);
        print('Apiari ricevuti: ${apiari.runtimeType} - ${apiari.length} elementi');
        
        // Versione ancora più sicura e robusta per estrarre gli ID
        apiariIds = [];
        
        for (var apiario in apiari) {
          try {
            // Estrai l'ID con la certezza che sia un intero
            var id = apiario['id'];
            if (id != null) {
              if (id is int) {
                apiariIds.add(id);
              } else {
                print('ATTENZIONE: ID apiario non è un intero: $id (${id.runtimeType})');
                // Non aggiungerlo alla lista
              }
            }
          } catch (e) {
            print('Errore nell\'estrazione dell\'ID apiario: $e');
          }
        }
        
        print('ID apiari estratti: $apiariIds');
      } catch (e) {
        print('Errore nel caricamento degli apiari: $e');
      }
      
      // Crea un nuovo gruppo con tutti i dati combinati
      print('=== CREAZIONE GRUPPO COMBINATO ===');
      try {
        return Gruppo(
          id: gruppoBase.id,
          nome: gruppoBase.nome,
          descrizione: gruppoBase.descrizione,
          dataCreazione: gruppoBase.dataCreazione,
          creatoreId: gruppoBase.creatoreId,
          creatoreName: gruppoBase.creatoreName,
          membri: membri,
          immagineProfilo: gruppoBase.immagineProfilo,
          apiariIds: apiariIds,
        );
      } catch (e, stackTrace) {
        print('=== ERRORE NELLA CREAZIONE DEL GRUPPO COMBINATO ===');
        print('$e');
        print('=== STACK TRACE ===');
        print('$stackTrace');
        rethrow;
      }
    } catch (e, stackTrace) {
      print('=== ERRORE GLOBALE IN GETGRUPPODETAIL ===');
      print('$e');
      print('=== STACK TRACE ===');
      print('$stackTrace');
      
      // Tenta di recuperare dai dati locali
      try {
        final localData = await _storageService.getStoredData('gruppi');
        
        final gruppoData = localData.firstWhere(
          (grupo) => grupo['id'] == gruppoId,
          orElse: () => throw Exception('Gruppo non trovato'),
        );
        
        return Gruppo.fromJson(gruppoData);
      } catch (fallbackError) {
        print('=== ERRORE ANCHE NEL FALLBACK ===');
        print('$fallbackError');
        rethrow; // Rilancia l'errore originale
      }
    }
  }

  // Crea un nuovo gruppo
  Future<Gruppo> createGruppo(String nome, String descrizione) async {
    final data = {
      'nome': nome,
      'descrizione': descrizione,
    };
    
    final response = await _apiService.post(ApiConstants.gruppiUrl, data);
    return Gruppo.fromJson(response);
  }

  // Aggiorna un gruppo esistente
  Future<Gruppo> updateGruppo(int gruppoId, String nome, String descrizione) async {
    final data = {
      'nome': nome,
      'descrizione': descrizione,
    };
    
    final String endpoint = '${ApiConstants.gruppiUrl}$gruppoId/';
    final response = await _apiService.put(endpoint, data);
    return Gruppo.fromJson(response);
  }

  // Elimina un gruppo
  Future<void> deleteGruppo(int gruppoId) async {
    final String endpoint = '${ApiConstants.gruppiUrl}$gruppoId/';
    await _apiService.delete(endpoint);
  }

  // Ottiene i membri di un gruppo
  Future<List<MembroGruppo>> getGruppoMembri(int gruppoId) async {
    try {
      final String endpoint = '${ApiConstants.gruppiUrl}$gruppoId/membri/';
      final response = await _apiService.get(endpoint);
      
      // Debug
      print('Membri risposta: $response');
      
      if (response is List) {
        return response
            .map((membroJson) => MembroGruppo.fromJson(membroJson))
            .toList();
      } else if (response['results'] != null) {
        return (response['results'] as List)
            .map((membroJson) => MembroGruppo.fromJson(membroJson))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Errore nel caricamento dei membri: $e');
      // IMPORTANTE: NON chiamare più getGruppoDetail qui!
      // Restituisci una lista vuota invece di utilizzare il fallback
      return [];
    }
  }

  // Aggiorna il ruolo di un membro
  Future<MembroGruppo> updateMembroRuolo(int gruppoId, int membroId, String ruolo) async {
    final data = {
      'ruolo': ruolo,
    };
    
    final String endpoint = '${ApiConstants.gruppiUrl}$gruppoId/membri/$membroId/';
    final response = await _apiService.put(endpoint, data);
    return MembroGruppo.fromJson(response);
  }

  // Rimuove un membro dal gruppo
  Future<void> removeMembro(int gruppoId, int membroId) async {
    final String endpoint = '${ApiConstants.gruppiUrl}$gruppoId/membri/$membroId/';
    await _apiService.delete(endpoint);
  }

  // Invia un invito a un utente
  Future<InvitoGruppo> invitaUtente(int gruppoId, String email, String ruolo) async {
    final data = {
      'email': email,
      'ruolo_proposto': ruolo,
    };
    
    final String endpoint = '${ApiConstants.gruppiUrl}$gruppoId/inviti/';
    final response = await _apiService.post(endpoint, data);
    return InvitoGruppo.fromJson(response);
  }

  // Ottiene gli inviti attivi per un gruppo
  Future<List<InvitoGruppo>> getGruppoInviti(int gruppoId) async {
    final String endpoint = '${ApiConstants.gruppiUrl}$gruppoId/inviti/';
    final response = await _apiService.get(endpoint);
    
    if (response['results'] != null) {
      return (response['results'] as List)
          .map((invitoJson) => InvitoGruppo.fromJson(invitoJson))
          .toList();
    }
    
    return [];
  }

  // Annulla un invito
  Future<void> annullaInvito(int gruppoId, int invitoId) async {
    final String endpoint = '${ApiConstants.gruppiUrl}$gruppoId/inviti/$invitoId/';
    await _apiService.delete(endpoint);
  }

  // Ottiene inviti ricevuti dall'utente corrente
  Future<List<InvitoGruppo>> getInvitiRicevuti() async {
    final String endpoint = '${ApiConstants.invitiUrl}ricevuti/';
    final response = await _apiService.get(endpoint);
    
    if (response['results'] != null) {
      return (response['results'] as List)
          .map((invitoJson) => InvitoGruppo.fromJson(invitoJson))
          .toList();
    }
    
    return [];
  }

  // Accetta un invito
  Future<void> accettaInvito(String token) async {
    final String endpoint = '${ApiConstants.invitiUrl}accetta/$token/';
    await _apiService.post(endpoint, {});
  }

  // Rifiuta un invito
  Future<void> rifiutaInvito(String token) async {
    final String endpoint = '${ApiConstants.invitiUrl}rifiuta/$token/';
    await _apiService.post(endpoint, {});
  }

  // Condividi un apiario con un gruppo
  Future<void> condividiApiario(int apiarioId, int gruppoId, bool condiviso) async {
    final data = {
      'gruppo': gruppoId,
      'condiviso_con_gruppo': condiviso,
    };
    
    final String endpoint = '${ApiConstants.apiariUrl}$apiarioId/condivisione/';
    await _apiService.put(endpoint, data);
  }

// Sostituisci completamente il metodo getApiariGruppo in gruppo_service.dart

  Future<List<Map<String, dynamic>>> getApiariGruppo(int gruppoId) async {
    try {
      final String endpoint = '${ApiConstants.gruppiUrl}$gruppoId/apiari/';
      final response = await _apiService.get(endpoint);
      
      print('Risposta API apiari: $response');
      
      List<Map<String, dynamic>> risultati = [];
      
      if (response is List) {
        // Trasforma tutti gli elementi in Map<String, dynamic> normalizzati
        for (var item in response) {
          if (item is Map) {
            // Assicurati che tutte le chiavi siano String
            Map<String, dynamic> normalizedItem = {};
            
            item.forEach((key, value) {
              String stringKey = key.toString(); // Converti la chiave in stringa
              
              // Converti ID in interi se sono stringhe
              if (stringKey == 'id' && value is String) {
                try {
                  normalizedItem[stringKey] = int.parse(value);
                  print('Convertito ID da String a int: $value -> ${normalizedItem[stringKey]}');
                } catch (e) {
                  normalizedItem[stringKey] = 0;
                  print('Errore convertendo ID: $e, impostato a 0');
                }
              } 
              // Converti gruppo in intero se è una stringa
              else if (stringKey == 'gruppo' && value is String) {
                try {
                  normalizedItem[stringKey] = int.parse(value);
                  print('Convertito gruppo da String a int: $value -> ${normalizedItem[stringKey]}');
                } catch (e) {
                  normalizedItem[stringKey] = 0;
                  print('Errore convertendo gruppo: $e, impostato a 0');
                }
              }
              // Converti proprietario in intero se è una stringa
              else if (stringKey == 'proprietario' && value is String) {
                try {
                  normalizedItem[stringKey] = int.parse(value);
                  print('Convertito proprietario da String a int: $value -> ${normalizedItem[stringKey]}');
                } catch (e) {
                  normalizedItem[stringKey] = 0;
                  print('Errore convertendo proprietario: $e, impostato a 0');
                }
              }
              else {
                normalizedItem[stringKey] = value;
              }
            });
            
            risultati.add(normalizedItem);
          }
        }
      } else if (response is Map && response['results'] != null && response['results'] is List) {
        List<dynamic> resultsList = response['results'];
        
        // Stessa logica di normalizzazione di cui sopra
        for (var item in resultsList) {
          if (item is Map) {
            Map<String, dynamic> normalizedItem = {};
            
            item.forEach((key, value) {
              String stringKey = key.toString();
              
              if (stringKey == 'id' && value is String) {
                try {
                  normalizedItem[stringKey] = int.parse(value);
                } catch (e) {
                  normalizedItem[stringKey] = 0;
                }
              } 
              else if (stringKey == 'gruppo' && value is String) {
                try {
                  normalizedItem[stringKey] = int.parse(value);
                } catch (e) {
                  normalizedItem[stringKey] = 0;
                }
              }
              else if (stringKey == 'proprietario' && value is String) {
                try {
                  normalizedItem[stringKey] = int.parse(value);
                } catch (e) {
                  normalizedItem[stringKey] = 0;
                }
              }
              else {
                normalizedItem[stringKey] = value;
              }
            });
            
            risultati.add(normalizedItem);
          }
        }
      } else {
        print('Formato apiari inaspettato: ${response.runtimeType}');
      }
      
      if (risultati.isNotEmpty) {
        print('Primo elemento apiari normalizzato: ${risultati.first}');
      }
      
      return risultati;
    } catch (e) {
      print('Errore nel caricamento degli apiari: $e');
      return [];
    }
  }
}
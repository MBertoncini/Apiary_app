// File: lib/models/gruppo.dart
import 'package:flutter/foundation.dart';
class Gruppo {
  final int id;
  final String nome;
  final String? descrizione;
  final String dataCreazione;
  final int creatoreId;
  final String creatoreName;
  final List<dynamic> membri; // Cambiato da MembroGruppo a dynamic
  final String? immagineProfilo;
  final List<dynamic> apiariIds; // Cambiato da List<int> a List<dynamic>
  final int? membriCountFromApi;
  final int? apiariCountFromApi;

  Gruppo({
    required this.id,
    required this.nome,
    this.descrizione,
    required this.dataCreazione,
    required this.creatoreId,
    required this.creatoreName,
    required this.membri,
    this.immagineProfilo,
    required this.apiariIds,
    this.membriCountFromApi,
    this.apiariCountFromApi,
  });

  factory Gruppo.fromJson(Map<String, dynamic> json) {
    // Log di debug
    debugPrint('Gruppo - JSON ricevuto: $json');
    
    // Gestione del creatore
    int creatoreId = 0;
    String creatoreName = 'Sconosciuto';
    
    if (json['creatore'] != null) {
        if (json['creatore'] is Map) {
        creatoreId = json['creatore']['id'] ?? 0;
        creatoreName = json['creatore']['username'] ?? 'Sconosciuto';
        } else if (json['creatore'] is int) {
        creatoreId = json['creatore'];
        creatoreName = json['creatore_username'] ?? 'Utente $creatoreId';
        } else if (json['creatore'] is String) {
          try {
            creatoreId = int.parse(json['creatore']);
          } catch (e) {
            debugPrint('Errore parsing creatore ID: $e');
          }
          creatoreName = json['creatore_username'] ?? 'Utente $creatoreId';
        }
    }

    // Inizializza liste vuote - saranno popolate da chiamate API separate
    List<dynamic> membri = [];
    List<dynamic> apiariIds = []; // Cambiato da List<int> a List<dynamic>

    // Gestione sicura del conteggio membri e apiari dall'API
    int? membriCount = json['membri_count'];
    int? apiariCount = json['apiari_count'];

    return Gruppo(
        id: json['id'] is String ? int.parse(json['id']) : json['id'],
        nome: json['nome'] ?? 'Senza nome',
        descrizione: json['descrizione'] ?? '',
        dataCreazione: json['data_creazione'] ?? DateTime.now().toIso8601String(),
        creatoreId: creatoreId,
        creatoreName: creatoreName,
        membri: membri,            // Lista vuota, da popolare con chiamata API separata
        immagineProfilo: null,     // Non presente nella risposta
        apiariIds: apiariIds,      // Lista vuota, da popolare con chiamata API separata
        membriCountFromApi: membriCount,
        apiariCountFromApi: apiariCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descrizione': descrizione,
      'data_creazione': dataCreazione,
      'creatore_id': creatoreId,
    };
  }

  // Verifica se l'utente è creatore del gruppo
  bool isCreator(int userId) {
    try {
      return creatoreId == userId;
    } catch (e) {
      debugPrint('Errore in isCreator: $e');
      return false;
    }
  }

  // FIX #9 - Helper per ottenere il ruolo di un utente nel gruppo
  String? _getUserRole(int userId) {
    try {
      for (var membro in membri) {
        if (membro is Map<String, dynamic>) {
          var utenteId = membro['utente'];
          if (utenteId != null) {
            if (utenteId is String) {
              try { utenteId = int.parse(utenteId); } catch (e) { continue; }
            }
            if (utenteId == userId) return membro['ruolo'] as String?;
          }
        } else if (membro is MembroGruppo) {
          if (membro.utenteId == userId) return membro.ruolo;
        }
      }
    } catch (e) {
      debugPrint('Errore in _getUserRole: $e');
    }
    return null;
  }

  bool isAdmin(int userId) {
    // FIX #9 - Se la lista membri è vuota (es. dalla lista gruppi),
    // il creatore è sempre admin (come da logica server perform_create).
    if (membri.isEmpty) {
      return isCreator(userId);
    }
    return _getUserRole(userId) == 'admin';
  }

  bool isEditor(int userId) {
    if (membri.isEmpty) return false;
    return _getUserRole(userId) == 'editor';
  }

  // Metodo helper per ottenere il numero di membri
  int getMembriCount() {
    try {
      if (membri.isNotEmpty) return membri.length;
      return membriCountFromApi ?? 0;
    } catch (e) {
      debugPrint('Errore nel conteggio membri: $e');
      return membriCountFromApi ?? 0;
    }
  }

  // Metodo helper per ottenere il numero di apiari
  int getApiariCount() {
    try {
      if (apiariIds.isNotEmpty) return apiariIds.length;
      return apiariCountFromApi ?? 0;
    } catch (e) {
      debugPrint('Errore nel conteggio apiari: $e');
      return apiariCountFromApi ?? 0;
    }
  }

  // Metodo per ottenere un apiarioId come intero
  int getApiarioIdAsInt(int index) {
    try {
      if (index < 0 || index >= apiariIds.length) {
        return 0;
      }
      
      var id = apiariIds[index];
      if (id is int) {
        return id;
      } else if (id is String) {
        try {
          return int.parse(id);
        } catch (e) {
          debugPrint('Errore parsing apiarioId: $e');
          return 0;
        }
      } else {
        return 0;
      }
    } catch (e) {
      debugPrint('Errore in getApiarioIdAsInt: $e');
      return 0;
    }
  }

  // Verifica se un apiario specifico è contenuto nella lista
  bool containsApiario(dynamic apiarioId) {
    try {
      if (apiarioId is int) {
        for (var id in apiariIds) {
          if (id is int && id == apiarioId) return true;
          if (id is String && int.tryParse(id) == apiarioId) return true;
        }
      } else if (apiarioId is String) {
        int? apiarioIdInt = int.tryParse(apiarioId);
        for (var id in apiariIds) {
          if (id is String && id == apiarioId) return true;
          if (id is int && apiarioIdInt != null && id == apiarioIdInt) return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Errore in containsApiario: $e');
      return false;
    }
  }

  // Verifica se l'utente ha permessi di scrittura
  bool hasWritePermissions(int userId) {
    return isCreator(userId) || isAdmin(userId) || isEditor(userId);
  }
}

// Estendi la classe per il membro e l'invito direttamente in questo file

class MembroGruppo {
  final int id;
  final int utenteId;
  final String username;
  final String? fullName;
  final String? email;
  final String ruolo;
  final String dataAggiunta;
  final String? immagineProfilo;

  MembroGruppo({
    required this.id,
    required this.utenteId,
    required this.username,
    this.fullName,
    this.email,
    required this.ruolo,
    required this.dataAggiunta,
    this.immagineProfilo,
  });

  factory MembroGruppo.fromJson(Map<String, dynamic> json) {
    // Debug
    debugPrint('MembroGruppo - JSON ricevuto: $json');
    
    // Gestione sicura per id
    int id = json['id'] is String ? int.parse(json['id']) : json['id'];

    // Dai log, vediamo che utente è l'ID, ma anche utente_username è fornito direttamente
    int utenteId;
    String username;
    
    // Utente potrebbe essere un ID o un oggetto
    if (json['utente'] is Map<String, dynamic>) {
        var utente = json['utente'] as Map<String, dynamic>;
        utenteId = utente['id'] is String ? int.parse(utente['id']) : utente['id'];
        username = utente['username'] ?? 'Sconosciuto';
    } else {
        // Quando 'utente' è solo l'ID (questo è il nostro caso attuale)
        utenteId = json['utente'] is String ? int.parse(json['utente'].toString()) : json['utente'];
        username = json['utente_username'] ?? 'Utente $utenteId';
    }

    return MembroGruppo(
        id: id,
        utenteId: utenteId,
        username: username,
        fullName: null,  // Non fornito nell'API
        email: null,     // Non fornito nell'API
        ruolo: json['ruolo'],
        dataAggiunta: json['data_aggiunta'],
        immagineProfilo: null,  // Non fornito nell'API
    );
  }
}

class InvitoGruppo {
  final int id;
  final int gruppoId;
  final String gruppoNome;
  final String email;
  final String ruoloProposto;
  final String token;
  final String dataInvio;
  final String dataScadenza;
  final String stato;
  final int invitatoDaId;
  final String invitatoDaUsername;

  InvitoGruppo({
    required this.id,
    required this.gruppoId,
    required this.gruppoNome,
    required this.email,
    required this.ruoloProposto,
    required this.token,
    required this.dataInvio,
    required this.dataScadenza,
    required this.stato,
    required this.invitatoDaId,
    required this.invitatoDaUsername,
  });

  factory InvitoGruppo.fromJson(Map<String, dynamic> json) {
    debugPrint('InvitoGruppo - JSON ricevuto: $json');
    // Gestione per id
    int id = json['id'] is String ? int.parse(json['id']) : json['id'];
    
    // Gestione per gruppo
    int gruppoId;
    String gruppoNome = 'Sconosciuto';
    
    if (json['gruppo'] is Map<String, dynamic>) {
        var gruppo = json['gruppo'] as Map<String, dynamic>;
        gruppoId = gruppo['id'] is String ? int.parse(gruppo['id']) : gruppo['id'];
        gruppoNome = gruppo['nome'] ?? 'Gruppo sconosciuto';
    } else {
        gruppoId = json['gruppo'] is String ? int.parse(json['gruppo'].toString()) : json['gruppo'];
        gruppoNome = json['gruppo_nome'] ?? 'Gruppo $gruppoId';
    }
    
    // Gestione per invitato_da
    int invitatoDaId;
    String invitatoDaUsername = 'Sconosciuto';
    
    if (json['invitato_da'] is Map<String, dynamic>) {
        var invitato = json['invitato_da'] as Map<String, dynamic>;
        invitatoDaId = invitato['id'] is String ? int.parse(invitato['id']) : invitato['id'];
        invitatoDaUsername = invitato['username'] ?? 'Utente sconosciuto';
    } else {
        invitatoDaId = json['invitato_da'] is String ? int.parse(json['invitato_da'].toString()) : json['invitato_da'];
        invitatoDaUsername = json['invitato_da_username'] ?? 'Utente $invitatoDaId';
    }
    
    return InvitoGruppo(
        id: id,
        gruppoId: gruppoId,
        gruppoNome: gruppoNome,
        email: json['email'],
        ruoloProposto: json['ruolo_proposto'],
        token: json['token'],
        dataInvio: json['data_invio'],
        dataScadenza: json['data_scadenza'],
        stato: json['stato'],
        invitatoDaId: invitatoDaId,
        invitatoDaUsername: invitatoDaUsername,
    );
  }

  // Restituisce il ruolo proposto in formato leggibile
  String getRuoloPropDisplay() {
    switch (ruoloProposto) {
      case 'admin':
        return 'Amministratore';
      case 'editor':
        return 'Editor';
      case 'viewer':
        return 'Visualizzatore';
      default:
        return ruoloProposto;
    }
  }

  // Verifica se l'invito è ancora valido
  bool isValid() {
    return stato == 'inviato' && DateTime.parse(dataScadenza).isAfter(DateTime.now());
  }
}
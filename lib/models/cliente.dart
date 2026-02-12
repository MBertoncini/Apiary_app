class Cliente {
  final int id;
  final String nome;
  final String? telefono;
  final String? email;
  final String? indirizzo;
  final String? note;
  final int utente;
  final String? utenteUsername;
  final int? venditeCount;

  Cliente({
    required this.id,
    required this.nome,
    this.telefono,
    this.email,
    this.indirizzo,
    this.note,
    required this.utente,
    this.utenteUsername,
    this.venditeCount,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      nome: json['nome'],
      telefono: json['telefono'],
      email: json['email'],
      indirizzo: json['indirizzo'],
      note: json['note'],
      utente: json['utente'],
      utenteUsername: json['utente_username'],
      venditeCount: json['vendite_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'telefono': telefono,
      'email': email,
      'indirizzo': indirizzo,
      'note': note,
    };
  }
}

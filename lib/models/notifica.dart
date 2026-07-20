/// Notifica nel centro notifiche dell'utente.
///
/// Mantiene compatibilità con le notifiche legacy (inviti, scaduto, ecc.) e
/// supporta il rich content delle broadcast admin (`messaggioHtml`,
/// `immagineUrl`, `linkRoute` + `linkParam`).
class Notifica {
  final int id;
  final String tipo;
  final String titolo;
  final String messaggio;
  final String messaggioHtml; // vuoto se non c'è HTML
  final String? immagineUrl;
  final String? link; // legacy free-form path
  final String linkRoute; // destinazione dropdown (vuoto = nessuna)
  final String linkParam; // parametro opzionale del link
  final bool letta;
  final String priorita;
  final String dataCreazione;
  final String? mittenteUsername;

  const Notifica({
    required this.id,
    required this.tipo,
    required this.titolo,
    required this.messaggio,
    this.messaggioHtml = '',
    this.immagineUrl,
    this.link,
    this.linkRoute = '',
    this.linkParam = '',
    this.letta = false,
    this.priorita = 'media',
    required this.dataCreazione,
    this.mittenteUsername,
  });

  bool get hasHtml => messaggioHtml.trim().isNotEmpty;

  bool get isBroadcast => tipo == 'broadcast';

  Notifica copyWith({bool? letta}) => Notifica(
        id: id,
        tipo: tipo,
        titolo: titolo,
        messaggio: messaggio,
        messaggioHtml: messaggioHtml,
        immagineUrl: immagineUrl,
        link: link,
        linkRoute: linkRoute,
        linkParam: linkParam,
        letta: letta ?? this.letta,
        priorita: priorita,
        dataCreazione: dataCreazione,
        mittenteUsername: mittenteUsername,
      );

  factory Notifica.fromJson(Map<String, dynamic> json) {
    return Notifica(
      id: json['id'] as int,
      tipo: (json['tipo'] as String?) ?? 'sistema',
      titolo: (json['titolo'] as String?) ?? '',
      messaggio: (json['messaggio'] as String?) ?? '',
      messaggioHtml: (json['messaggio_html'] as String?) ?? '',
      immagineUrl: json['immagine_url'] as String?,
      link: json['link'] as String?,
      linkRoute: (json['link_route'] as String?) ?? '',
      linkParam: (json['link_param'] as String?) ?? '',
      letta: (json['letta'] as bool?) ?? false,
      priorita: (json['priorita'] as String?) ?? 'media',
      dataCreazione: (json['data_creazione'] as String?) ?? '',
      mittenteUsername: json['mittente_username'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo,
        'titolo': titolo,
        'messaggio': messaggio,
        'messaggio_html': messaggioHtml,
        'immagine_url': immagineUrl,
        'link': link,
        'link_route': linkRoute,
        'link_param': linkParam,
        'letta': letta,
        'priorita': priorita,
        'data_creazione': dataCreazione,
        'mittente_username': mittenteUsername,
      };
}

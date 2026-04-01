import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informativa sulla Privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _header('Informativa sulla Privacy'),
          _updated('Ultimo aggiornamento: 12 marzo 2026'),
          _highlight(
            'La presente Informativa sulla Privacy descrive come Apiary '
            'raccoglie, utilizza e protegge i dati degli utenti. '
            'Ti invitiamo a leggerla attentamente prima di utilizzare l\'applicazione.',
          ),
          _h2('1. Titolare del trattamento'),
          _body(
            'Il titolare del trattamento è lo sviluppatore dell\'applicazione Apiary.\n'
            'Per qualsiasi richiesta relativa alla privacy puoi contattarci all\'indirizzo:',
          ),
          _emailLink('michele.bertoncini@gmail.com'),
          _h2('2. Dati raccolti'),
          _body('L\'applicazione può raccogliere le seguenti categorie di dati, a seconda delle funzionalità utilizzate:'),
          _h2('2.1 Dati inseriti volontariamente dall\'utente'),
          _bullets([
            'Dati apicoltura: informazioni su apiari, arnie, regine, melari, sciamature, fioriture, controlli periodici e analisi dei telaini (covata, scorte, diaframmi, nutritori).',
            'Dati di account: nome utente e password per l\'autenticazione al servizio backend.',
            'Indirizzo e-mail (funzionalità in arrivo): potrà essere richiesto per la registrazione, il recupero password o l\'invio di notifiche inerenti l\'applicazione.',
          ]),
          _h2('2.2 Dati raccolti automaticamente'),
          _bullets([
            'Dati di utilizzo: informazioni tecniche sull\'uso dell\'app (es. versione, sistema operativo, lingua del dispositivo) per scopi diagnostici e di miglioramento. Questi dati non identificano personalmente l\'utente.',
            'Identificatori del dispositivo: possono essere raccolti in forma anonima o pseudonima per garantire il corretto funzionamento dell\'app.',
          ]),
          _h2('2.3 Dati raccolti tramite fotocamera'),
          _body(
            'L\'applicazione richiede l\'accesso alla fotocamera del dispositivo per la funzionalità '
            'di analisi fotografica dei telaini tramite intelligenza artificiale (rilevamento di api, '
            'fuchi, celle reali e covata). Le immagini scattate vengono elaborate localmente sul '
            'dispositivo e/o inviate al server backend per l\'analisi. '
            'Le immagini non vengono condivise con terze parti né utilizzate per scopi diversi dall\'analisi apistica.',
          ),
          _h2('3. Finalità del trattamento'),
          _bullets([
            'Erogazione del servizio: gestione dei dati degli apiari, sincronizzazione tra dispositivi tramite il backend remoto, analisi AI dei telaini.',
            'Miglioramento dell\'app: analisi aggregate e anonime per identificare malfunzionamenti e ottimizzare le funzionalità.',
            'Comunicazioni di servizio: notifiche relative al proprio account o al funzionamento dell\'app.',
            'Marketing e newsletter (previsto): previo consenso esplicito, l\'indirizzo e-mail potrà essere usato per inviare aggiornamenti o offerte relative all\'applicazione.',
            'Pubblicità (prevista): in futuro potranno essere integrati servizi pubblicitari di terze parti (es. Google AdMob). Gli utenti saranno informati e, ove richiesto dalla normativa, sarà richiesto il loro consenso.',
          ]),
          _h2('4. Base giuridica del trattamento'),
          _bullets([
            'Esecuzione del contratto (art. 6, par. 1, lett. b GDPR): per i dati necessari al funzionamento dell\'app e alla gestione dell\'account.',
            'Consenso (art. 6, par. 1, lett. a GDPR): per l\'accesso alla fotocamera, per comunicazioni marketing e per la pubblicità personalizzata. Il consenso può essere revocato in qualsiasi momento.',
            'Legittimo interesse (art. 6, par. 1, lett. f GDPR): per scopi diagnostici e di sicurezza del servizio.',
          ]),
          _h2('5. Conservazione dei dati'),
          _bullets([
            'I dati dell\'apiario sono conservati sul server backend (cible99.pythonanywhere.com) per tutta la durata dell\'account attivo, più un ulteriore periodo di 30 giorni dopo la cancellazione, salvo obblighi di legge.',
            'I dati memorizzati localmente sul dispositivo (SQLite e SharedPreferences) rimangono sul dispositivo fino alla disinstallazione dell\'app o alla cancellazione manuale da parte dell\'utente.',
            'I dati e-mail raccolti per finalità di marketing saranno conservati fino alla revoca del consenso.',
          ]),
          _h2('6. Condivisione con terze parti'),
          _body('I dati personali non vengono venduti né ceduti a terzi. Possono essere condivisi esclusivamente con:'),
          _bullets([
            'Provider di hosting: PythonAnywhere (server backend), che tratta i dati come responsabile del trattamento nel rispetto del GDPR.',
            'Servizi di analisi e pubblicità (in futuro): es. Google AdMob / Google Analytics, che dispongono di proprie informative sulla privacy.',
            'Autorità competenti: ove richiesto dalla legge o per tutelare diritti legittimi.',
          ]),
          _h2('7. Diritti dell\'utente (GDPR)'),
          _body('In qualità di interessato, hai il diritto di:'),
          _bullets([
            'Accesso – ottenere conferma del trattamento e copia dei tuoi dati.',
            'Rettifica – correggere dati inesatti o incompleti.',
            'Cancellazione ("diritto all\'oblio") – richiedere la cancellazione dei tuoi dati, salvo obblighi di conservazione previsti dalla legge.',
            'Limitazione del trattamento – richiedere la sospensione del trattamento in determinati casi.',
            'Portabilità – ricevere i tuoi dati in formato strutturato e leggibile da macchina.',
            'Opposizione – opporti al trattamento basato su legittimo interesse o per finalità di marketing diretto.',
            'Revoca del consenso – ritirare in qualsiasi momento il consenso precedentemente accordato.',
          ]),
          _body('Per esercitare questi diritti, contatta:'),
          _emailLink('michele.bertoncini@gmail.com'),
          _body('Hai inoltre il diritto di proporre reclamo all\'Autorità Garante per la protezione dei dati personali:'),
          _urlLink('www.garanteprivacy.it', 'https://www.garanteprivacy.it'),
          _h2('8. Sicurezza'),
          _body(
            'Adottiamo misure tecniche e organizzative adeguate per proteggere i dati da accesso '
            'non autorizzato, perdita o distruzione, incluso l\'uso di connessioni HTTPS per la '
            'trasmissione dei dati tra app e server.',
          ),
          _h2('9. Minori'),
          _body(
            'L\'applicazione non è destinata a minori di 16 anni. Non raccogliamo consapevolmente '
            'dati di minori. Qualora dovessimo venire a conoscenza di una raccolta accidentale di '
            'tali dati, procederemo alla loro cancellazione immediata.',
          ),
          _h2('10. Modifiche alla presente informativa'),
          _body(
            'Ci riserviamo il diritto di aggiornare questa informativa. In caso di modifiche '
            'sostanziali, l\'utente sarà informato tramite notifica nell\'app o via e-mail. '
            'L\'uso continuato dell\'app successivo alla pubblicazione delle modifiche '
            'costituisce accettazione delle stesse.',
          ),
          _h2('11. Contatti'),
          _body('Per qualsiasi domanda relativa alla privacy:'),
          _emailLink('michele.bertoncini@gmail.com'),
          const SizedBox(height: 32),
          Text(
            '© 2026 Apiary – Tutti i diritti riservati.',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      );

  Widget _updated(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      );

  Widget _highlight(String text) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Color(0xFFE8F5E9),
          borderRadius: BorderRadius.all(Radius.circular(6)),
          border: Border(left: BorderSide(color: Color(0xFF2E7D32), width: 4)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 14, height: 1.6)),
      );

  Widget _h2(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
      );

  Widget _body(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 14, height: 1.6)),
      );

  Widget _bullets(List<String> items) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 14)),
                        Expanded(
                            child: Text(item,
                                style: const TextStyle(fontSize: 14, height: 1.5))),
                      ],
                    ),
                  ))
              .toList(),
        ),
      );

  Widget _emailLink(String email) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => launchUrl(Uri.parse('mailto:$email')),
          child: Text(
            email,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2E7D32),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );

  Widget _urlLink(String label, String url) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2E7D32),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );
}

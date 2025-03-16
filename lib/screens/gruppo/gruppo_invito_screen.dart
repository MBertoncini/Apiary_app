import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/gruppo.dart';
import '../../services/gruppo_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../utils/validators.dart';

class GruppoInvitoScreen extends StatefulWidget {
  final int gruppoId;

  GruppoInvitoScreen({required this.gruppoId});

  @override
  _GruppoInvitoScreenState createState() => _GruppoInvitoScreenState();
}

class _GruppoInvitoScreenState extends State<GruppoInvitoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late GruppoService _gruppoService;
  Gruppo? _gruppo;

  // Controller per il campo email
  final TextEditingController _emailController = TextEditingController();

  // Ruolo selezionato
  String _ruoloSelezionato = 'viewer';

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    _gruppoService = GruppoService(apiService, storageService);
    
    _loadGruppo();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadGruppo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _gruppo = await _gruppoService.getGruppoDetail(widget.gruppoId);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nel caricamento del gruppo: ${e.toString()}'),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _inviaInvito() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      
      await _gruppoService.invitaUtente(widget.gruppoId, email, _ruoloSelezionato);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invito inviato con successo'),
          backgroundColor: ThemeConstants.successColor,
        ),
      );
      
      // Torna alla schermata precedente
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: ${e.toString()}'),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRuoloSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ruolo del nuovo membro:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        RadioListTile<String>(
          title: Text('Amministratore'),
          subtitle: Text('Può gestire membri, inviti e modificare il gruppo'),
          value: 'admin',
          groupValue: _ruoloSelezionato,
          onChanged: (value) {
            setState(() {
              _ruoloSelezionato = value!;
            });
          },
          activeColor: ThemeConstants.primaryColor,
        ),
        RadioListTile<String>(
          title: Text('Editor'),
          subtitle: Text('Può modificare dati ma non gestire membri'),
          value: 'editor',
          groupValue: _ruoloSelezionato,
          onChanged: (value) {
            setState(() {
              _ruoloSelezionato = value!;
            });
          },
          activeColor: ThemeConstants.primaryColor,
        ),
        RadioListTile<String>(
          title: Text('Visualizzatore'),
          subtitle: Text('Può solo visualizzare dati senza modificarli'),
          value: 'viewer',
          groupValue: _ruoloSelezionato,
          onChanged: (value) {
            setState(() {
              _ruoloSelezionato = value!;
            });
          },
          activeColor: ThemeConstants.primaryColor,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invita al gruppo'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _gruppo == null
              ? Center(child: Text('Gruppo non trovato'))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.all(16.0),
                    children: [
                      // Intestazione con info gruppo
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invita al gruppo: ${_gruppo!.nome}',
                                style: ThemeConstants.subheadingStyle,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Inserisci l\'indirizzo email della persona che vuoi invitare.',
                                style: TextStyle(
                                  color: ThemeConstants.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Campo email
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          hintText: 'Inserisci indirizzo email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 24),
                      
                      // Selettore ruolo
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildRuoloSelector(),
                        ),
                      ),
                      SizedBox(height: 32),
                      
                      // Pulsante invita
                      ElevatedButton(
                        onPressed: _isLoading ? null : _inviaInvito,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'INVIA INVITO',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 0),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Informazione aggiuntiva
                      Text(
                        'L\'invito rimarrà valido per 7 giorni. La persona dovrà avere un account per accettarlo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ThemeConstants.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
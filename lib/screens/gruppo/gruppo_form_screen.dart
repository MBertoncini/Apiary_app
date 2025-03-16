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

class GruppoFormScreen extends StatefulWidget {
  final Gruppo? gruppo; // Se non null, è una modifica

  GruppoFormScreen({this.gruppo});

  @override
  _GruppoFormScreenState createState() => _GruppoFormScreenState();
}

class _GruppoFormScreenState extends State<GruppoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late GruppoService _gruppoService;

  // Controller per i campi del form
  late TextEditingController _nomeController;
  late TextEditingController _descrizioneController;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    _gruppoService = GruppoService(apiService, storageService);
    
    // Inizializza i controller
    _nomeController = TextEditingController(text: widget.gruppo?.nome ?? '');
    _descrizioneController = TextEditingController(text: widget.gruppo?.descrizione ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }

  Future<void> _saveGruppo() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final nome = _nomeController.text.trim();
      final descrizione = _descrizioneController.text.trim();
      
      if (widget.gruppo == null) {
        // Creazione nuovo gruppo
        await _gruppoService.createGruppo(nome, descrizione);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gruppo creato con successo'),
            backgroundColor: ThemeConstants.successColor,
          ),
        );
      } else {
        // Modifica gruppo esistente
        await _gruppoService.updateGruppo(widget.gruppo!.id, nome, descrizione);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gruppo aggiornato con successo'),
            backgroundColor: ThemeConstants.successColor,
          ),
        );
      }
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gruppo == null ? 'Nuovo Gruppo' : 'Modifica Gruppo'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  // Istruzioni
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informazioni sul gruppo',
                            style: ThemeConstants.subheadingStyle,
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.gruppo == null
                                ? 'Crea un nuovo gruppo per collaborare con altri apicoltori. Potrai invitare membri e condividere apiari.'
                                : 'Modifica le informazioni del gruppo esistente.',
                            style: TextStyle(
                              color: ThemeConstants.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Campo nome
                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome del gruppo *',
                      hintText: 'Es. Apicoltura Toscana',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    validator: Validators.required,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 16),
                  
                  // Campo descrizione
                  TextFormField(
                    controller: _descrizioneController,
                    decoration: InputDecoration(
                      labelText: 'Descrizione',
                      hintText: 'Es. Gruppo per la gestione degli apiari in Toscana',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  SizedBox(height: 32),
                  
                  // Pulsante salva
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveGruppo,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        widget.gruppo == null ? 'CREA GRUPPO' : 'SALVA MODIFICHE',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 0),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
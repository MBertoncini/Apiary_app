import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class ApiarioFormScreen extends StatefulWidget {
  final Map<String, dynamic>? apiario; // Null se è creazione, altrimenti è modifica
  
  ApiarioFormScreen({this.apiario});
  
  @override
  _ApiarioFormScreenState createState() => _ApiarioFormScreenState();
}

class _ApiarioFormScreenState extends State<ApiarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nomeController = TextEditingController();
  final _posizioneController = TextEditingController();
  final _latitudineController = TextEditingController();
  final _longitudineController = TextEditingController();
  final _noteController = TextEditingController();
  
  // Flags
  bool _monitoraggioMeteo = false;
  bool _condivisoConGruppo = false;
  String _visibilitaMappa = 'privato'; // default: privato
  
  bool _isLoading = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    
    // Popolamento form se in modalità modifica
    if (widget.apiario != null) {
      _nomeController.text = widget.apiario!['nome'] ?? '';
      _posizioneController.text = widget.apiario!['posizione'] ?? '';
      _latitudineController.text = widget.apiario!['latitudine']?.toString() ?? '';
      _longitudineController.text = widget.apiario!['longitudine']?.toString() ?? '';
      _noteController.text = widget.apiario!['note'] ?? '';
      
      _monitoraggioMeteo = widget.apiario!['monitoraggio_meteo'] ?? false;
      _condivisoConGruppo = widget.apiario!['condiviso_con_gruppo'] ?? false;
      _visibilitaMappa = widget.apiario!['visibilita_mappa'] ?? 'privato';
    }
  }
  
  @override
  void dispose() {
    _nomeController.dispose();
    _posizioneController.dispose();
    _latitudineController.dispose();
    _longitudineController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Preparazione dati
      final Map<String, dynamic> data = {
        'nome': _nomeController.text,
        'posizione': _posizioneController.text,
        'monitoraggio_meteo': _monitoraggioMeteo,
        'condiviso_con_gruppo': _condivisoConGruppo,
        'visibilita_mappa': _visibilitaMappa,
        'note': _noteController.text,
      };
      
      // Aggiungi coordinate solo se entrambe sono state fornite
      if (_latitudineController.text.isNotEmpty && _longitudineController.text.isNotEmpty) {
        data['latitudine'] = double.parse(_latitudineController.text);
        data['longitudine'] = double.parse(_longitudineController.text);
      }
      
      // Invio dati al server
      Map<String, dynamic> response;
      if (widget.apiario == null) {
        // Creazione
        response = await apiService.post(ApiConstants.apiariUrl, data);
        
        // Aggiorna lo storage locale
        final apiari = await storageService.getStoredData('apiari');
        apiari.add(response);
        await storageService.saveSyncData({'apiari': apiari});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apiario creato con successo'),
            backgroundColor: ThemeConstants.successColor,
          ),
        );
      } else {
        // Modifica
        response = await apiService.put('${ApiConstants.apiariUrl}${widget.apiario!['id']}/', data);
        
        // Aggiorna lo storage locale
        final apiari = await storageService.getStoredData('apiari');
        final index = apiari.indexWhere((a) => a['id'] == widget.apiario!['id']);
        if (index != -1) {
          apiari[index] = response;
          await storageService.saveSyncData({'apiari': apiari});
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apiario aggiornato con successo'),
            backgroundColor: ThemeConstants.successColor,
          ),
        );
      }
      
      // Torna alla schermata precedente
      Navigator.of(context).pop();
    } catch (e) {
      print('Error saving apiario: $e');
      setState(() {
        _errorMessage = 'Errore durante il salvataggio. Riprova più tardi.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.apiario == null ? 'Nuovo apiario' : 'Modifica apiario'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Messaggio di errore
            if (_errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: ThemeConstants.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ThemeConstants.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: ThemeConstants.errorColor),
                ),
              ),
            
            // Informazioni di base
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informazioni generali',
                      style: ThemeConstants.subheadingStyle,
                    ),
                    SizedBox(height: 16),
                    
                    // Nome
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        labelText: 'Nome apiario',
                        hintText: 'Es. Apiario montagna',
                        prefixIcon: Icon(Icons.hive),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci il nome dell\'apiario';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Posizione
                    TextFormField(
                      controller: _posizioneController,
                      decoration: InputDecoration(
                        labelText: 'Posizione',
                        hintText: 'Es. Via delle api, 123',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Coordinate geografiche
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Posizione sulla mappa',
                      style: ThemeConstants.subheadingStyle,
                    ),
                    SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudineController,
                            decoration: InputDecoration(
                              labelText: 'Latitudine',
                              prefixIcon: Icon(Icons.map),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (_longitudineController.text.isEmpty) {
                                  return 'Inserisci anche la longitudine';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Formato non valido';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudineController,
                            decoration: InputDecoration(
                              labelText: 'Longitudine',
                              prefixIcon: Icon(Icons.map),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (_latitudineController.text.isEmpty) {
                                  return 'Inserisci anche la latitudine';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Formato non valido';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    
                    Text(
                      'Lascia vuoti i campi se non vuoi specificare le coordinate.',
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeConstants.textSecondaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),
                    
                    // Visibilità sulla mappa
                    Text(
                      'Visibilità sulla mappa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    RadioListTile<String>(
                      title: Text('Solo proprietario'),
                      value: 'privato',
                      groupValue: _visibilitaMappa,
                      onChanged: (value) {
                        setState(() {
                          _visibilitaMappa = value!;
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),
                    
                    RadioListTile<String>(
                      title: Text('Membri del gruppo'),
                      value: 'gruppo',
                      groupValue: _visibilitaMappa,
                      onChanged: (value) {
                        setState(() {
                          _visibilitaMappa = value!;
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),
                    
                    RadioListTile<String>(
                      title: Text('Tutti gli utenti'),
                      value: 'pubblico',
                      groupValue: _visibilitaMappa,
                      onChanged: (value) {
                        setState(() {
                          _visibilitaMappa = value!;
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Funzionalità aggiuntive
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Funzionalità aggiuntive',
                      style: ThemeConstants.subheadingStyle,
                    ),
                    SizedBox(height: 16),
                    
                    // Monitoraggio meteo
                    SwitchListTile(
                      title: Text('Monitoraggio meteo'),
                      subtitle: Text('Attiva il monitoraggio delle condizioni meteo'),
                      value: _monitoraggioMeteo,
                      onChanged: (value) {
                        setState(() {
                          _monitoraggioMeteo = value;
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),
                    
                    // Condivisione con gruppo
                    SwitchListTile(
                      title: Text('Condivisione con gruppo'),
                      subtitle: Text('Condividi questo apiario con il tuo gruppo'),
                      value: _condivisoConGruppo,
                      onChanged: (value) {
                        setState(() {
                          _condivisoConGruppo = value;
                        });
                      },
                      activeColor: ThemeConstants.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Note
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note',
                      style: ThemeConstants.subheadingStyle,
                    ),
                    SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Note',
                        hintText: 'Inserisci eventuali note su questo apiario...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Pulsanti
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('ANNULLA'),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ThemeConstants.primaryColor),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(widget.apiario == null ? 'CREA APIARIO' : 'AGGIORNA APIARIO'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
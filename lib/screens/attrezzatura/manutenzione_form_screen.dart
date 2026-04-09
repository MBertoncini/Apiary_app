// lib/screens/attrezzatura/manutenzione_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/manutenzione.dart';
import '../../services/attrezzatura_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/notification_service.dart';
import '../../l10n/app_strings.dart';

class ManutenzioneFormScreen extends StatefulWidget {
  final int attrezzaturaId;
  final String? attrezzaturaNome;
  final bool condivisoConGruppo;
  final int? gruppoId;

  ManutenzioneFormScreen({
    required this.attrezzaturaId,
    this.attrezzaturaNome,
    this.condivisoConGruppo = false,
    this.gruppoId,
  });

  @override
  _ManutenzioneFormScreenState createState() => _ManutenzioneFormScreenState();
}

class _ManutenzioneFormScreenState extends State<ManutenzioneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descrizioneController = TextEditingController();
  final _costoController = TextEditingController();
  final _noteController = TextEditingController();
  final _eseguitoDaController = TextEditingController();

  String _selectedTipo = 'ordinaria';
  String _selectedStato = 'programmata';
  DateTime? _dataProgrammata;
  DateTime? _dataEsecuzione;
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _membriGruppo = [];
  int? _selectedPagatoDaId;
  DateTime? _prossimaManutenzione;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    _dataProgrammata = DateTime.now().add(Duration(days: 7));
    if (widget.condivisoConGruppo && widget.gruppoId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembriGruppo(widget.gruppoId!));
    }
  }

  Future<void> _loadMembriGruppo(int gruppoId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get('/gruppi/$gruppoId/membri/');
      final List<dynamic> list = response is List
          ? response
          : (response['results'] as List? ?? []);
      if (mounted) {
        setState(() {
          _membriGruppo = list.map((m) => {
            'id': m['utente'],
            'username': m['utente_username'] ?? '—',
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Errore caricamento membri gruppo: $e');
    }
  }

  @override
  void dispose() {
    _descrizioneController.dispose();
    _costoController.dispose();
    _noteController.dispose();
    _eseguitoDaController.dispose();
    super.dispose();
  }

  Future<void> _selectDataProgrammata(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataProgrammata ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _dataProgrammata = picked;
      });
    }
  }

  Future<void> _selectDataEsecuzione(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataEsecuzione ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dataEsecuzione = picked;
      });
    }
  }

  Future<void> _saveManutenzione() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final s = _s;
    if (_selectedStato == 'programmata' && _dataProgrammata == null) {
      setState(() { _errorMessage = s.manutenzioneFormValidateDataProgrammata; });
      return;
    }
    if (_selectedStato == 'completata' && _dataEsecuzione == null) {
      setState(() { _errorMessage = s.manutenzioneFormValidateDataEsecuzione; });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final service = AttrezzaturaService(apiService);
      final auth = Provider.of<AuthService>(context, listen: false);

      final costo = _costoController.text.isNotEmpty
          ? double.tryParse(_costoController.text.replaceAll(',', '.'))
          : null;

      final data = {
        'attrezzatura': widget.attrezzaturaId,
        'tipo': _selectedTipo,
        'descrizione': _descrizioneController.text,
        'costo': costo,
        'data_programmata': _dataProgrammata != null
            ? DateFormat('yyyy-MM-dd').format(_dataProgrammata!)
            : DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'data_esecuzione': _dataEsecuzione != null
            ? DateFormat('yyyy-MM-dd').format(_dataEsecuzione!)
            : null,
        'stato': _selectedStato,
        'gruppo': widget.condivisoConGruppo ? widget.gruppoId : null,
        'eseguito_da': _eseguitoDaController.text.isNotEmpty
            ? _eseguitoDaController.text
            : null,
        'prossima_manutenzione': _prossimaManutenzione != null
            ? DateFormat('yyyy-MM-dd').format(_prossimaManutenzione!)
            : null,
        'note': _noteController.text.isNotEmpty ? _noteController.text : null,
      };

      await service.createManutenzione(
        data,
        userId: auth.currentUser!.id,
        attrezzaturaNome: widget.attrezzaturaNome ?? 'Attrezzatura',
        condivisoConGruppo: widget.condivisoConGruppo,
        pagatoDaId: _selectedPagatoDaId,
      );

      if (_selectedStato == 'programmata' && _dataProgrammata != null) {
        final notifId =
            'manut_${widget.attrezzaturaId}_${_dataProgrammata!.millisecondsSinceEpoch}'
                .hashCode;
        NotificationService().scheduleManutenzioneReminder(
          notificationId: notifId,
          attrezzaturaNome: widget.attrezzaturaNome ?? 'Attrezzatura',
          tipoManutenzione: _selectedTipo,
          dataProgrammata: _dataProgrammata!,
        );
      }

      String message = s.manutenzioneFormCreatedOk;
      if (costo != null && costo > 0) {
        message += '\n${s.attrezzaturaFormPagamentoAuto}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: Duration(seconds: 3)),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = _s.attrezzaturaFormSaveError(e.toString());
        _isLoading = false;
      });
    }
  }

  String _getTipoDisplayName(String tipo, AppStrings s) {
    switch (tipo) {
      case 'ordinaria':         return s.manutenzioneFormTipoOrdinaria;
      case 'straordinaria':     return s.manutenzioneFormTipoStraordinaria;
      case 'riparazione':       return s.manutenzioneFormTipoRiparazione;
      case 'pulizia':           return s.manutenzioneFormTipoPulizia;
      case 'revisione':         return s.manutenzioneFormTipoRevisione;
      case 'sostituzione_parti': return s.manutenzioneFormTipoSostituzioneParti;
      default:                  return tipo;
    }
  }

  String _getStatoDisplayName(String stato, AppStrings s) {
    switch (stato) {
      case 'programmata': return s.manutenzioneFormStatoProgrammata;
      case 'in_corso':    return s.manutenzioneFormStatoInCorso;
      case 'completata':  return s.manutenzioneFormStatoCompletata;
      case 'annullata':   return s.manutenzioneFormStatoAnnullata;
      default:            return stato;
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    final formatDate = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(s.manutenzioneFormTitle),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info attrezzatura
              if (widget.attrezzaturaNome != null)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.build, color: Colors.blue),
                    title: Text(s.manutenzioneFormLblAttrezzatura),
                    subtitle: Text(widget.attrezzaturaNome!),
                  ),
                ),
              const SizedBox(height: 16),

              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Tipo manutenzione
              DropdownButtonFormField<String>(
                value: _selectedTipo,
                decoration: InputDecoration(
                  labelText: s.manutenzioneFormLblTipo,
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: Manutenzione.tipiManutenzione.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(_getTipoDisplayName(tipo, s)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedTipo = value!);
                },
              ),
              const SizedBox(height: 16),

              // Stato
              DropdownButtonFormField<String>(
                value: _selectedStato,
                decoration: InputDecoration(
                  labelText: s.attrezzaturaFormLblStato,
                  prefixIcon: Icon(Icons.info),
                  border: OutlineInputBorder(),
                ),
                items: Manutenzione.statiManutenzione
                    .where((st) => st != 'annullata')
                    .map((stato) {
                  return DropdownMenuItem(
                    value: stato,
                    child: Text(_getStatoDisplayName(stato, s)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStato = value!;
                    if (value == 'completata' && _dataEsecuzione == null) {
                      _dataEsecuzione = DateTime.now();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Descrizione
              TextFormField(
                controller: _descrizioneController,
                decoration: InputDecoration(
                  labelText: s.attrezzaturaDetailLblDescrizione + ' *',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  hintText: s.manutenzioneFormHintDescrizione,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return s.manutenzioneFormValidateDescrizione;
                  }
                  return null;
                },
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Data programmata
              InkWell(
                onTap: () => _selectDataProgrammata(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: s.manutenzioneFormLblDataProgrammata,
                    prefixIcon: Icon(Icons.event),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _dataProgrammata != null
                        ? formatDate.format(_dataProgrammata!)
                        : s.manutenzioneFormHintSelezionaData,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Data esecuzione
              if (_selectedStato == 'completata' || _selectedStato == 'in_corso')
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => _selectDataEsecuzione(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: _selectedStato == 'completata'
                            ? s.manutenzioneFormLblDataEsecuzioneReq
                            : s.manutenzioneFormLblDataEsecuzione,
                        prefixIcon: Icon(Icons.check_circle),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _dataEsecuzione != null
                            ? formatDate.format(_dataEsecuzione!)
                            : s.manutenzioneFormHintSelezionaData,
                      ),
                    ),
                  ),
                ),

              // Costo
              TextFormField(
                controller: _costoController,
                decoration: InputDecoration(
                  labelText: s.manutenzioneFormLblCosto,
                  prefixIcon: Icon(Icons.euro),
                  border: OutlineInputBorder(),
                  helperText: s.manutenzioneFormHelperCosto,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value.replaceAll(',', '.')) == null) {
                      return s.attrezzaturaFormValidateImporto;
                    }
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Eseguito da
              TextFormField(
                controller: _eseguitoDaController,
                decoration: InputDecoration(
                  labelText: s.manutenzioneFormLblEseguitoDa,
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  hintText: s.manutenzioneFormHintEseguitoDa,
                ),
              ),
              const SizedBox(height: 16),

              // Prossima manutenzione
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _prossimaManutenzione ?? DateTime.now().add(Duration(days: 90)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setState(() => _prossimaManutenzione = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: s.manutenzioneFormLblProssimaManutenzione,
                    prefixIcon: Icon(Icons.event_repeat),
                    border: OutlineInputBorder(),
                    suffixIcon: _prossimaManutenzione != null
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () => setState(() => _prossimaManutenzione = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _prossimaManutenzione != null
                        ? formatDate.format(_prossimaManutenzione!)
                        : s.manutenzioneFormHintNonProgrammata,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: s.manutenzioneFormLblNote,
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Chi ha pagato
              if (widget.condivisoConGruppo && _membriGruppo.isNotEmpty) ...[
                DropdownButtonFormField<int?>(
                  value: _selectedPagatoDaId,
                  decoration: InputDecoration(
                    labelText: s.attrezzaturaFormLblChiHaPagato,
                    hintText: s.attrezzaturaFormHintIoStesso,
                    prefixIcon: Icon(Icons.payments),
                    border: OutlineInputBorder(),
                    helperText: s.attrezzaturaFormHelperChiPaga,
                  ),
                  items: [
                    DropdownMenuItem<int?>(value: null, child: Text(s.attrezzaturaFormHintIoStesso)),
                    ..._membriGruppo.map((m) => DropdownMenuItem<int?>(
                      value: m['id'] as int,
                      child: Text(m['username'] as String),
                    )),
                  ],
                  onChanged: (val) => setState(() { _selectedPagatoDaId = val; }),
                ),
                const SizedBox(height: 16),
              ],

              // Info pagamento automatico
              if (_costoController.text.isNotEmpty)
                Card(
                  color: Colors.blue.withOpacity(0.1),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(s.manutenzioneFormInfoPagamento,
                              style: TextStyle(color: Colors.blue[800])),
                        ),
                      ],
                    ),
                  ),
                ),

              if (widget.condivisoConGruppo)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Card(
                    color: Colors.green.withOpacity(0.1),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.group, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(s.manutenzioneFormInfoCondivisa,
                                style: TextStyle(color: Colors.green[800])),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Pulsante salva
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveManutenzione,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _selectedStato == 'programmata'
                              ? s.manutenzioneFormBtnProgramma
                              : s.manutenzioneFormBtnRegistra,
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

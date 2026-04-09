// lib/screens/attrezzatura/attrezzatura_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attrezzatura.dart';
import '../../models/gruppo.dart';
import '../../services/attrezzatura_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class AttrezzaturaFormScreen extends StatefulWidget {
  final int? attrezzaturaId;

  AttrezzaturaFormScreen({this.attrezzaturaId});

  @override
  _AttrezzaturaFormScreenState createState() => _AttrezzaturaFormScreenState();
}

class _AttrezzaturaFormScreenState extends State<AttrezzaturaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descrizioneController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modelloController = TextEditingController();
  final _quantitaController = TextEditingController(text: '1');
  final _prezzoController = TextEditingController();
  final _fornitoreController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedStato = 'disponibile';
  String _selectedCondizione = 'buono';
  DateTime _selectedDate = DateTime.now();
  bool _condivisoConGruppo = false;
  List<Gruppo> _gruppi = [];
  Gruppo? _selectedGruppo;

  List<Map<String, dynamic>> _membriGruppo = [];
  int? _selectedPagatoDaId;

  bool _isLoading = false;
  bool _isInitLoading = false;
  String? _errorMessage;

  bool get isEditing => widget.attrezzaturaId != null;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    _loadGruppi();
    if (isEditing) {
      _loadAttrezzatura();
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descrizioneController.dispose();
    _marcaController.dispose();
    _modelloController.dispose();
    _quantitaController.dispose();
    _prezzoController.dispose();
    _fornitoreController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAttrezzatura() async {
    setState(() {
      _isInitLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final service = AttrezzaturaService(apiService);

      final attrezzatura = await service.getAttrezzatura(widget.attrezzaturaId!);

      _nomeController.text = attrezzatura.nome;
      _descrizioneController.text = attrezzatura.descrizione ?? '';
      _marcaController.text = attrezzatura.marca ?? '';
      _modelloController.text = attrezzatura.modello ?? '';
      _quantitaController.text = attrezzatura.quantita.toString();
      if (attrezzatura.prezzoAcquisto != null) {
        _prezzoController.text = attrezzatura.prezzoAcquisto.toString();
      }
      _fornitoreController.text = attrezzatura.fornitore ?? '';
      _noteController.text = attrezzatura.note ?? '';
      _selectedStato = attrezzatura.stato ?? 'disponibile';
      _selectedCondizione = attrezzatura.condizione ?? 'buono';
      if (attrezzatura.dataAcquisto != null) {
        _selectedDate = attrezzatura.dataAcquisto!;
      }
      _condivisoConGruppo = attrezzatura.condivisoConGruppo;

      if (attrezzatura.gruppo != null && _gruppi.isNotEmpty) {
        try {
          _selectedGruppo = _gruppi.firstWhere((g) => g.id == attrezzatura.gruppo);
        } catch (_) {}
      }

      setState(() {
        _isInitLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = _s.attrezzaturaFormLoadError(e.toString());
        _isInitLoading = false;
      });
    }
  }

  Future<void> _loadGruppi() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get('/gruppi/');

      List<dynamic> gruppiJson = [];
      if (response is List) {
        gruppiJson = response;
      } else if (response is Map && response.containsKey('results')) {
        gruppiJson = response['results'] as List;
      }

      final gruppi = gruppiJson.map((json) => Gruppo.fromJson(json)).toList();

      setState(() {
        _gruppi = gruppi;
        if (_gruppi.isNotEmpty && _selectedGruppo == null) {
          _selectedGruppo = _gruppi.first;
        }
      });
    } catch (e) {
      debugPrint('Errore caricamento gruppi: $e');
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
          if (_selectedPagatoDaId != null &&
              !_membriGruppo.any((m) => m['id'] == _selectedPagatoDaId)) {
            _selectedPagatoDaId = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Errore caricamento membri gruppo: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveAttrezzatura() async {
    if (!_formKey.currentState!.validate()) {
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

      final prezzo = _prezzoController.text.isNotEmpty
          ? double.tryParse(_prezzoController.text.replaceAll(',', '.'))
          : null;

      final data = {
        'nome': _nomeController.text,
        'descrizione': _descrizioneController.text.isNotEmpty ? _descrizioneController.text : null,
        'marca': _marcaController.text.isNotEmpty ? _marcaController.text : null,
        'modello': _modelloController.text.isNotEmpty ? _modelloController.text : null,
        'quantita': int.parse(_quantitaController.text),
        'stato': _selectedStato,
        'condizione': _selectedCondizione,
        'data_acquisto': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'prezzo_acquisto': prezzo,
        'fornitore': _fornitoreController.text.isNotEmpty ? _fornitoreController.text : null,
        'note': _noteController.text.isNotEmpty ? _noteController.text : null,
        'condiviso_con_gruppo': _condivisoConGruppo,
        'gruppo': _condivisoConGruppo ? _selectedGruppo?.id : null,
        if (!isEditing && _condivisoConGruppo && _selectedPagatoDaId != null)
          'pagato_da': _selectedPagatoDaId,
      };

      final s = _s;
      if (isEditing) {
        await service.updateAttrezzatura(widget.attrezzaturaId!, data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.attrezzaturaFormUpdatedOk)),
        );
      } else {
        await service.createAttrezzatura(data, userId: auth.currentUser!.id);

        String message = s.attrezzaturaFormCreatedOk;
        if (prezzo != null && prezzo > 0) {
          message += '\n${s.attrezzaturaFormPagamentoAuto}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: Duration(seconds: 3)),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = _s.attrezzaturaFormSaveError(e.toString());
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    final formatDate = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? s.attrezzaturaFormTitleEdit : s.attrezzaturaFormTitleNew),
      ),
      body: _isInitLoading
          ? LoadingWidget()
          : _errorMessage != null && isEditing
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage!,
                  onRetry: _loadAttrezzatura,
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null)
                          Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),

                        // Nome
                        TextFormField(
                          controller: _nomeController,
                          decoration: InputDecoration(
                            labelText: s.attrezzaturaFormLblNome,
                            prefixIcon: Icon(Icons.label),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return s.attrezzaturaFormValidateNome;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Descrizione
                        TextFormField(
                          controller: _descrizioneController,
                          decoration: InputDecoration(
                            labelText: s.attrezzaturaDetailLblDescrizione,
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Marca e Modello in Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _marcaController,
                                decoration: InputDecoration(
                                  labelText: s.attrezzaturaFormLblMarca,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _modelloController,
                                decoration: InputDecoration(
                                  labelText: s.attrezzaturaFormLblModello,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Quantità
                        TextFormField(
                          controller: _quantitaController,
                          decoration: InputDecoration(
                            labelText: s.attrezzaturaFormLblQuantita,
                            prefixIcon: Icon(Icons.numbers),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return s.attrezzaturaFormValidateQuantita;
                            }
                            if (int.tryParse(value) == null || int.parse(value) < 1) {
                              return s.attrezzaturaFormValidateNumero;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Stato e Condizione in Row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedStato,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: s.attrezzaturaFormLblStato,
                                  border: OutlineInputBorder(),
                                ),
                                items: Attrezzatura.statiDisponibili.map((stato) {
                                  return DropdownMenuItem(
                                    value: stato,
                                    child: Text(_displayStato(stato, s), overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedStato = value!);
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCondizione,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: s.attrezzaturaFormLblCondizione,
                                  border: OutlineInputBorder(),
                                ),
                                items: Attrezzatura.condizioniDisponibili.map((cond) {
                                  return DropdownMenuItem(
                                    value: cond,
                                    child: Text(_displayCondizione(cond, s), overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedCondizione = value!);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Data acquisto
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: s.attrezzaturaFormLblDataAcquisto,
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(formatDate.format(_selectedDate)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Prezzo acquisto
                        TextFormField(
                          controller: _prezzoController,
                          decoration: InputDecoration(
                            labelText: s.attrezzaturaFormLblPrezzoAcquisto,
                            prefixIcon: Icon(Icons.euro),
                            border: OutlineInputBorder(),
                            helperText: isEditing ? null : s.attrezzaturaFormHelperPrezzo,
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
                        ),
                        const SizedBox(height: 16),

                        // Fornitore
                        TextFormField(
                          controller: _fornitoreController,
                          decoration: InputDecoration(
                            labelText: s.attrezzaturaFormLblFornitore,
                            prefixIcon: Icon(Icons.store),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Condivisione con gruppo
                        if (_gruppi.isNotEmpty) ...[
                          Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.attrezzaturaFormSectionCondivisione, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  SwitchListTile(
                                    title: Text(s.attrezzaturaFormLblCondividi),
                                    subtitle: Text(s.attrezzaturaFormSubCondividi),
                                    value: _condivisoConGruppo,
                                    onChanged: (value) {
                                      setState(() {
                                        _condivisoConGruppo = value;
                                        if (value && _selectedGruppo != null) {
                                          _loadMembriGruppo(_selectedGruppo!.id);
                                        } else if (!value) {
                                          _membriGruppo = [];
                                          _selectedPagatoDaId = null;
                                        }
                                      });
                                    },
                                  ),
                                  if (_condivisoConGruppo) ...[
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<Gruppo>(
                                      value: _selectedGruppo,
                                      decoration: InputDecoration(
                                        labelText: s.attrezzaturaDetailLblGruppo,
                                        prefixIcon: Icon(Icons.group),
                                        border: OutlineInputBorder(),
                                      ),
                                      items: _gruppi.map((gruppo) {
                                        return DropdownMenuItem(value: gruppo, child: Text(gruppo.nome));
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() => _selectedGruppo = value);
                                        if (value != null) _loadMembriGruppo(value.id);
                                      },
                                    ),
                                    if (!isEditing && _membriGruppo.isNotEmpty) ...[
                                      const SizedBox(height: 12),
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
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Note
                        TextFormField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            labelText: s.attrezzaturaFormLblNote,
                            prefixIcon: Icon(Icons.note),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // Info pagamento automatico
                        if (!isEditing)
                          Card(
                            color: Colors.blue.withOpacity(0.1),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.info, color: Colors.blue),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      s.attrezzaturaFormInfoPagamento,
                                      style: TextStyle(color: Colors.blue[800]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Pulsante salva
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveAttrezzatura,
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    isEditing ? s.attrezzaturaFormBtnAggiorna : s.attrezzaturaFormBtnSalva,
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

  String _displayStato(String stato, AppStrings s) {
    switch (stato) {
      case 'disponibile': return s.attrezzaturaStatoDisponibile;
      case 'in_uso':      return s.attrezzaturaStatoInUso;
      case 'manutenzione': return s.attrezzaturaStatoManutenzione;
      case 'dismesso':    return s.attrezzaturaStatoDismesso;
      case 'prestato':    return s.attrezzaturaStatoPrestato;
      default:            return stato;
    }
  }

  String _displayCondizione(String cond, AppStrings s) {
    switch (cond) {
      case 'nuovo':       return s.attrezzaturaCondizioneNuovo;
      case 'ottimo':      return s.attrezzaturaCondizioneOttimo;
      case 'buono':       return s.attrezzaturaCondizioneBuono;
      case 'discreto':    return s.attrezzaturaCondizioneDiscreto;
      case 'usurato':     return s.attrezzaturaCondizioneUsurato;
      case 'da_riparare': return s.attrezzaturaCondizioneDaRiparare;
      default:            return cond;
    }
  }
}

// lib/screens/pagamento/pagamento_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/gruppo.dart';
import '../../services/pagamento_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class PagamentoFormScreen extends StatefulWidget {
  final int? pagamentoId;
  /// Dati pre-compilati quando si registra un saldo bilancio
  final Map<String, dynamic>? prefill;

  PagamentoFormScreen({this.pagamentoId, this.prefill});

  @override
  _PagamentoFormScreenState createState() => _PagamentoFormScreenState();
}

class _PagamentoFormScreenState extends State<PagamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _importoController = TextEditingController();
  final _descrizioneController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isInitLoading = false;
  String? _errorMessage;
  List<Gruppo> _gruppi = [];
  Gruppo? _selectedGruppo;
  List<Map<String, dynamic>> _membriGruppo = [];
  int? _selectedPagatoDaId;
  bool _isSaldoPagamento = false;
  int? _selectedDestinatarioId;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    if (widget.pagamentoId != null) {
      _loadPagamento();
    } else {
      _loadGruppi().then((_) => _applyPrefill());
    }
  }

  void _applyPrefill() {
    final p = widget.prefill;
    if (p == null) return;
    setState(() {
      if (p['importo'] != null) {
        _importoController.text = (p['importo'] as double).toStringAsFixed(2);
      }
      if (p['descrizione'] != null) {
        _descrizioneController.text = p['descrizione'] as String;
      }
      if (p['isSaldo'] == true) _isSaldoPagamento = true;
      if (p['utenteId'] != null) _selectedPagatoDaId = p['utenteId'] as int;
      if (p['destinatarioId'] != null) _selectedDestinatarioId = p['destinatarioId'] as int;
      if (p['gruppoId'] != null && _gruppi.isNotEmpty) {
        _selectedGruppo = _gruppi.firstWhere(
          (g) => g.id == p['gruppoId'],
          orElse: () => _gruppi.first,
        );
      }
    });
    if (_selectedGruppo != null) {
      _loadMembriGruppo(_selectedGruppo!.id);
    }
  }

  @override
  void dispose() {
    _importoController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }

  Future<void> _loadPagamento() async {
    setState(() {
      _isInitLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final pagamentoService = PagamentoService(apiService);

      final pagamento = await pagamentoService.getPagamento(widget.pagamentoId!);

      _importoController.text = pagamento.importo.toString();
      _descrizioneController.text = pagamento.descrizione;
      _selectedDate = DateTime.parse(pagamento.data);

      await _loadGruppi();

      if (pagamento.gruppo != null) {
        _selectedGruppo = _gruppi.firstWhere(
          (g) => g.id == pagamento.gruppo,
          orElse: () => _gruppi.first,
        );
        await _loadMembriGruppo(_selectedGruppo!.id);
      }

      setState(() {
        _selectedPagatoDaId = pagamento.utente;
        _isSaldoPagamento = pagamento.isSaldo;
        _selectedDestinatarioId = pagamento.destinatario;
        _isInitLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = _s.pagamentoDetailErrLoading(e.toString());
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
        // Seleziona il primo gruppo come default se ce ne sono
        if (_gruppi.isNotEmpty && _selectedGruppo == null) {
          _selectedGruppo = _gruppi.first;
        }
      });

      if (_selectedGruppo != null) {
        await _loadMembriGruppo(_selectedGruppo!.id);
      }
    } catch (e) {
      debugPrint('Errore caricamento gruppi: $e');
      // Non blocchiamo il form se i gruppi non sono disponibili
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _savePagamento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final pagamentoService = PagamentoService(apiService);
      final auth = Provider.of<AuthService>(context, listen: false);

      final importo = double.parse(_importoController.text.replaceAll(',', '.'));
      final data = {
        'importo': importo,
        'descrizione': _descrizioneController.text,
        'data': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'utente': _selectedPagatoDaId ?? auth.currentUser!.id,
        'gruppo': _selectedGruppo?.id,
        if (_isSaldoPagamento && _selectedDestinatarioId != null)
          'destinatario': _selectedDestinatarioId,
      };

      if (widget.pagamentoId != null) {
        await pagamentoService.updatePagamento(widget.pagamentoId!, data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s.pagamentoFormUpdatedOk)),
        );
      } else {
        await pagamentoService.createPagamento(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s.pagamentoFormCreatedOk)),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = _s.pagamentoFormErrSave(e.toString());
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatDate = DateFormat('dd/MM/yyyy');
    Provider.of<LanguageService>(context);
    final s = _s;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pagamentoId != null ? s.pagamentoFormTitleEdit : s.pagamentoFormTitleNew),
      ),
      body: _isInitLoading
          ? LoadingWidget()
          : _errorMessage != null && widget.pagamentoId != null
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage!,
                  onRetry: _loadPagamento,
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
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        // Importo
                        TextFormField(
                          controller: _importoController,
                          decoration: InputDecoration(
                            labelText: s.pagamentoFormLabelImporto,
                            prefixIcon: Icon(Icons.euro),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return s.pagamentoFormValidImportoRequired;
                            }
                            if (double.tryParse(value.replaceAll(',', '.')) == null) {
                              return s.pagamentoFormValidImportoInvalid;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Data
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: s.labelDate,
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(formatDate.format(_selectedDate)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Descrizione
                        TextFormField(
                          controller: _descrizioneController,
                          decoration: InputDecoration(
                            labelText: s.pagamentoDetailLabelDescrizione,
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return s.pagamentoFormValidDescRequired;
                            }
                            return null;
                          },
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // Gruppo (opzionale)
                        if (_gruppi.isNotEmpty)
                          DropdownButtonFormField<Gruppo>(
                            value: _selectedGruppo,
                            decoration: InputDecoration(
                              labelText: s.pagamentoFormLabelGruppo,
                              prefixIcon: Icon(Icons.group),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                            ),
                            items: [
                              DropdownMenuItem<Gruppo>(
                                value: null,
                                child: Text(s.pagamentoFormNoGruppo),
                              ),
                              ..._gruppi.map((gruppo) => DropdownMenuItem<Gruppo>(
                                value: gruppo,
                                child: Text(gruppo.nome),
                              )).toList(),
                            ],
                            onChanged: (Gruppo? value) {
                              setState(() {
                                _selectedGruppo = value;
                                _selectedPagatoDaId = null;
                                _membriGruppo = [];
                              });
                              if (value != null) {
                                _loadMembriGruppo(value.id);
                              }
                            },
                          ),
                        const SizedBox(height: 16),

                        // Chi ha pagato (solo se gruppo selezionato e ci sono membri)
                        if (_selectedGruppo != null && _membriGruppo.isNotEmpty) ...[
                          DropdownButtonFormField<int?>(
                            value: _selectedPagatoDaId,
                            decoration: InputDecoration(
                              labelText: s.pagamentoFormLabelChiPaga,
                              hintText: s.pagamentoFormIoStesso,
                              prefixIcon: Icon(Icons.payments),
                              border: OutlineInputBorder(),
                              helperText: s.pagamentoFormHelperChiPaga,
                            ),
                            items: [
                              DropdownMenuItem<int?>(value: null, child: Text(s.pagamentoFormIoStesso)),
                              ..._membriGruppo.map((m) => DropdownMenuItem<int?>(
                                value: m['id'] as int,
                                child: Text(m['username'] as String),
                              )),
                            ],
                            onChanged: (val) => setState(() { _selectedPagatoDaId = val; }),
                          ),
                          const SizedBox(height: 16),

                          // Toggle pagamento di saldo
                          SwitchListTile(
                            value: _isSaldoPagamento,
                            onChanged: (val) => setState(() {
                              _isSaldoPagamento = val;
                              if (!val) _selectedDestinatarioId = null;
                            }),
                            title: Text(s.pagamentoFormSaldoTitle),
                            subtitle: Text(
                              s.pagamentoFormSaldoSubtitle,
                              style: TextStyle(fontSize: 12),
                            ),
                            secondary: Icon(Icons.swap_horiz, color: Colors.blue),
                            contentPadding: EdgeInsets.zero,
                          ),

                          // A chi? (destinatario, solo saldo)
                          if (_isSaldoPagamento) ...[
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int?>(
                              value: _selectedDestinatarioId,
                              decoration: InputDecoration(
                                labelText: s.pagamentoFormLabelDestinatario,
                                prefixIcon: Icon(Icons.person_pin, color: Colors.blue),
                                border: OutlineInputBorder(),
                                helperText: s.pagamentoFormHelperDestinatario,
                              ),
                              items: _membriGruppo
                                  .where((m) => m['id'] != _selectedPagatoDaId)
                                  .map((m) => DropdownMenuItem<int?>(
                                        value: m['id'] as int,
                                        child: Text(m['username'] as String),
                                      ))
                                  .toList(),
                              validator: (val) {
                                if (_isSaldoPagamento && val == null) {
                                  return s.pagamentoFormValidDestinatarioRequired;
                                }
                                return null;
                              },
                              onChanged: (val) => setState(() { _selectedDestinatarioId = val; }),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],

                        const SizedBox(height: 32),

                        // Pulsante salva
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _savePagamento,
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    widget.pagamentoId != null ? s.controlloFormBtnAggiorna : s.controlloFormBtnSalva,
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

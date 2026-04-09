// lib/screens/attrezzatura/spesa_attrezzatura_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/spesa_attrezzatura.dart';
import '../../services/attrezzatura_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/loading_widget.dart';

class SpesaAttrezzaturaFormScreen extends StatefulWidget {
  final int attrezzaturaId;
  final String? attrezzaturaNome;
  final bool condivisoConGruppo;
  final int? gruppoId;

  SpesaAttrezzaturaFormScreen({
    required this.attrezzaturaId,
    this.attrezzaturaNome,
    this.condivisoConGruppo = false,
    this.gruppoId,
  });

  @override
  _SpesaAttrezzaturaFormScreenState createState() => _SpesaAttrezzaturaFormScreenState();
}

class _SpesaAttrezzaturaFormScreenState extends State<SpesaAttrezzaturaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descrizioneController = TextEditingController();
  final _importoController = TextEditingController();
  final _fornitoreController = TextEditingController();
  final _numeroFatturaController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedTipo = 'altro';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _membriGruppo = [];
  int? _selectedPagatoDaId;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
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
    _importoController.dispose();
    _fornitoreController.dispose();
    _numeroFatturaController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() { _selectedDate = picked; });
    }
  }

  Future<void> _saveSpesa() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final service = AttrezzaturaService(apiService);
      final auth = Provider.of<AuthService>(context, listen: false);

      final importo = double.parse(_importoController.text.replaceAll(',', '.'));
      final dataStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final data = {
        'attrezzatura': widget.attrezzaturaId,
        'tipo': _selectedTipo,
        'descrizione': _descrizioneController.text,
        'importo': importo,
        'data': dataStr,
        'gruppo': widget.condivisoConGruppo ? widget.gruppoId : null,
        'fornitore': _fornitoreController.text.isNotEmpty ? _fornitoreController.text : null,
        'numero_fattura': _numeroFatturaController.text.isNotEmpty ? _numeroFatturaController.text : null,
        'note': _noteController.text.isNotEmpty ? _noteController.text : null,
      };

      await service.createSpesaAttrezzatura(
        data,
        userId: auth.currentUser!.id,
        attrezzaturaNome: widget.attrezzaturaNome ?? 'Attrezzatura',
        condivisoConGruppo: widget.condivisoConGruppo,
        pagatoDaId: _selectedPagatoDaId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.spesaAttrezzaturaFormCreatedOk),
          duration: Duration(seconds: 3),
        ),
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
      case 'acquisto':     return s.spesaAttrezzaturaFormTipoAcquisto;
      case 'manutenzione': return s.spesaAttrezzaturaFormTipoManutenzione;
      case 'riparazione':  return s.spesaAttrezzaturaFormTipoRiparazione;
      case 'accessori':    return s.spesaAttrezzaturaFormTipoAccessori;
      case 'consumabili':  return s.spesaAttrezzaturaFormTipoConsumabili;
      case 'altro':        return s.spesaAttrezzaturaFormTipoAltro;
      default:             return tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    final formatDate = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(s.spesaAttrezzaturaFormTitle),
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
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),

              // Tipo spesa
              DropdownButtonFormField<String>(
                value: _selectedTipo,
                decoration: InputDecoration(
                  labelText: s.spesaAttrezzaturaFormLblTipo,
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: SpesaAttrezzatura.tipiSpesa.map((tipo) {
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

              // Importo
              TextFormField(
                controller: _importoController,
                decoration: InputDecoration(
                  labelText: s.spesaAttrezzaturaFormLblImporto,
                  prefixIcon: Icon(Icons.euro),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return s.spesaAttrezzaturaFormValidateImporto;
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return s.attrezzaturaFormValidateImporto;
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
                    labelText: s.spesaAttrezzaturaFormLblData,
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(formatDate.format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Fornitore
              TextFormField(
                controller: _fornitoreController,
                decoration: InputDecoration(
                  labelText: s.spesaAttrezzaturaFormLblFornitore,
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
                  hintText: s.spesaAttrezzaturaFormHintFornitore,
                ),
              ),
              const SizedBox(height: 16),

              // Numero Fattura
              TextFormField(
                controller: _numeroFatturaController,
                decoration: InputDecoration(
                  labelText: s.spesaAttrezzaturaFormLblNumFattura,
                  prefixIcon: Icon(Icons.receipt_long),
                  border: OutlineInputBorder(),
                  hintText: s.spesaAttrezzaturaFormHintNumFattura,
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
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(s.spesaAttrezzaturaFormInfoPagamento,
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
                            child: Text(s.spesaAttrezzaturaFormInfoCondivisa,
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
                  onPressed: _isLoading ? null : _saveSpesa,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(s.spesaAttrezzaturaFormBtnSave, style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../models/arnia.dart';
import '../../services/api_service.dart';
import '../../services/nfc_service.dart';
import '../../services/storage_service.dart';  // Import StorageService
import '../../widgets/attrezzatura_prompt_dialog.dart';
import '../../widgets/field_help_icon.dart';
import '../../l10n/app_strings.dart';
import '../../services/language_service.dart';

class ArniaFormScreen extends StatefulWidget {
  final int? apiarioId;
  final Arnia? arnia; // Se fornita, siamo in modalità modifica

  const ArniaFormScreen({Key? key, this.apiarioId, this.arnia}) : super(key: key);

  @override
  _ArniaFormScreenState createState() => _ArniaFormScreenState();
}

class _ArniaFormScreenState extends State<ArniaFormScreen> {
  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  final _formKey = GlobalKey<FormState>();
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  late ApiService _apiService;
  late StorageService _storageService;

  // Lista degli apiari disponibili
  List<Map<String, dynamic>> _apiari = [];
  bool _loadingApiari = true;

  // Numeri arnia già usati nell'apiario selezionato
  Set<int> _numeriUsati = {};
  late TextEditingController _numeroController;

  // Campi del form
  int? _apiarioId;
  int _numero = 1;
  String _colore = 'bianco';
  String _coloreHex = '#FFFFFF';
  String _tipoArnia = 'dadant';
  DateTime _dataInstallazione = DateTime.now();
  String _note = '';
  bool _attiva = true;

  // Nomi localizzati via AppStrings.arniaTypeName; qui solo id + icona.
  static const List<Map<String, String>> _tipiArnia = [
    {'id': 'dadant',             'icona': '🏠'},
    {'id': 'langstroth',         'icona': '📦'},
    {'id': 'top_bar',            'icona': '🛖'},
    {'id': 'warre',              'icona': '🗼'},
    {'id': 'osservazione',       'icona': '🔭'},
    {'id': 'pappa_reale',        'icona': '👑'},
    {'id': 'nucleo_legno',       'icona': '📫'},
    {'id': 'nucleo_polistirolo', 'icona': '📮'},
    {'id': 'portasciami',        'icona': '📦'},
    {'id': 'apidea',             'icona': '🔹'},
    {'id': 'mini_plus',          'icona': '🔸'},
  ];
  
  // Opzioni per il colore
  final List<Map<String, dynamic>> _coloriDisponibili = [
    {'id': 'bianco', 'nome': 'Bianco', 'hex': '#FFFFFF'},
    {'id': 'giallo', 'nome': 'Giallo', 'hex': '#FFC107'},
    {'id': 'blu', 'nome': 'Blu', 'hex': '#0d6efd'},
    {'id': 'verde', 'nome': 'Verde', 'hex': '#198754'},
    {'id': 'rosso', 'nome': 'Rosso', 'hex': '#dc3545'},
    {'id': 'arancione', 'nome': 'Arancione', 'hex': '#fd7e14'},
    {'id': 'viola', 'nome': 'Viola', 'hex': '#6f42c1'},
    {'id': 'nero', 'nome': 'Nero', 'hex': '#212529'},
    {'id': 'altro', 'nome': 'Altro', 'hex': '#6c757d'},
  ];
  
  // NFC chip associato a questa arnia
  String? _nfcId;
  bool _isScanningNfc = false;
  final NfcService _nfcService = NfcService();

  // Indicatore di caricamento
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiService>(context, listen: false);
    _storageService = Provider.of<StorageService>(context, listen: false);

    // Se siamo in modalità modifica, carica i dati dell'arnia
    if (widget.arnia != null) {
      _apiarioId = widget.arnia!.apiario;
      _numero = widget.arnia!.numero;
      _colore = widget.arnia!.colore;
      _coloreHex = widget.arnia!.coloreHex;
      _dataInstallazione = DateTime.tryParse(widget.arnia!.dataInstallazione) ?? DateTime.now();
      _note = widget.arnia!.note ?? '';
      _tipoArnia = widget.arnia!.tipoArnia;
      _attiva = widget.arnia!.attiva;
      _nfcId = widget.arnia!.nfcId;
    } else if (widget.apiarioId != null) {
      _apiarioId = widget.apiarioId;
    }

    _numeroController = TextEditingController(text: _numero.toString());

    // Carica apiari e poi aggiorna il numero suggerito
    _loadApiari();
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  // Carica tutti gli apiari disponibili
  Future<void> _loadApiari() async {
    setState(() { _loadingApiari = true; });

    // Mostra subito dati dalla cache
    final cached = await _storageService.getStoredData('apiari');
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _apiari = List<Map<String, dynamic>>.from(cached);
        _loadingApiari = false;
      });
    }

    // Aggiorna sempre dal server
    try {
      final res = await _apiService.get(ApiConstants.apiariUrl);
      final list = res is List ? res : (res['results'] as List? ?? []);
      await _storageService.saveData('apiari', list);
      if (mounted) {
        setState(() {
          _apiari = List<Map<String, dynamic>>.from(list);
          _loadingApiari = false;
        });
      }
    } catch (e) {
      debugPrint('Errore nel caricare gli apiari: $e');
      if (mounted) {
        setState(() { _loadingApiari = false; });
        if (_apiari.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_s.arniaLoadApiariError)),
          );
        }
      }
    }

    // Dopo aver caricato gli apiari, carica i numeri usati
    if (_apiarioId != null) {
      await _loadNumeriUsati(_apiarioId!);
    }
  }

  /// Carica i numeri arnia già usati nell'apiario e suggerisce il prossimo disponibile.
  Future<void> _loadNumeriUsati(int apiarioId) async {
    try {
      final arnie = await _storageService.getStoredData('arnie');
      final numeri = arnie
          .where((a) => a['apiario'] == apiarioId)
          .map((a) => a['numero'] as int? ?? 0)
          .toSet();
      if (mounted) {
        setState(() { _numeriUsati = numeri; });
        // In modalità creazione, suggerisci il primo numero disponibile
        if (widget.arnia == null) {
          int next = 1;
          while (numeri.contains(next)) next++;
          _numero = next;
          _numeroController.text = next.toString();
        }
      }
    } catch (e) {
      debugPrint('Errore nel caricare i numeri arnia: $e');
    }
  }
  
  // Gestisce il cambio di colore
  void _onColoreChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _colore = newValue;
        // Aggiorna il colore hex basato sulla selezione
        Map<String, dynamic> selectedColor;
        try {
          selectedColor = _coloriDisponibili.firstWhere((color) => color['id'] == newValue);
        } catch (e) {
          // Se non trova corrispondenza, usa un colore di default
          selectedColor = {'hex': '#6c757d'};
        }

        _coloreHex = selectedColor['hex'];
      });
    }
  }

  // Gestisce il cambio di apiario
  void _onApiarioChanged(int? newValue) {
    if (newValue != null) {
      setState(() {
        _apiarioId = newValue;
        _numeriUsati = {};
      });
      _loadNumeriUsati(newValue);
    }
  }

  Future<void> _scanNfcForPairing() async {
    final s = _s;
    final available = await _nfcService.isAvailable();
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.nfcNotAvailable)),
      );
      return;
    }

    setState(() => _isScanningNfc = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.nfcScanning),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    final tagId = await _nfcService.scanTag();

    if (!mounted) return;
    setState(() => _isScanningNfc = false);

    if (tagId != null) {
      setState(() => _nfcId = tagId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.nfcChipAssignSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.nfcChipScanFailed)),
      );
    }
  }

  Future<void> _saveArnia() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Prepara i dati da inviare
        Map<String, dynamic> data = {
          'apiario': _apiarioId,
          'numero': _numero,
          'colore': _colore,
          'colore_hex': _coloreHex,
          'tipo_arnia': _tipoArnia,
          'data_installazione': dateFormat.format(_dataInstallazione),
          'note': _note,
          'attiva': _attiva,
          'nfc_id': _nfcId,
        };
        
        if (widget.arnia != null) {
          // Modalità modifica
          await _apiService.put(ApiConstants.arnieUrl + widget.arnia!.id.toString() + '/', data);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_s.arniaUpdatedOk)),
          );
        } else {
          // Modalità creazione
          final resp = await _apiService.post(ApiConstants.arnieUrl, data);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_s.arniaCreatedOk)),
          );

          // Popup lite: registra come attrezzatura?
          if (resp != null && resp['id'] != null) {
            await showAttrezzaturaPrompt(
              context: context,
              tipoArnia: _tipoArnia,
              numero: _numero,
              apiarioId: _apiarioId!,
              arniaId: resp['id'] as int,
            );
          }
        }

        if (!mounted) return;
        // Torna indietro
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s.arniaFormError(e.toString()))),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context); // rebuild on language change
    final s = _s;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.arnia != null ? s.arniaFormTitleEdit : s.arniaFormTitleNew),
      ),
      body: _isLoading || _loadingApiari
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo per la selezione dell'apiario
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: s.arniaFormLblApiario,
                        hintText: s.arniaFormHintApiario,
                        border: const OutlineInputBorder(),
                      ),
                      value: _apiarioId,
                      items: _apiari.map((apiario) {
                        return DropdownMenuItem<int>(
                          value: apiario['id'],
                          child: Text(apiario['nome']),
                        );
                      }).toList(),
                      onChanged: _onApiarioChanged,
                      validator: (value) {
                        if (value == null) {
                          return s.arniaFormValidateApiario;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Numero arnia
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: s.arniaFormLblNumero,
                        hintText: s.arniaFormHintNumero,
                        border: const OutlineInputBorder(),
                      ),
                      controller: _numeroController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return s.arniaFormValidateNumero;
                        }
                        final n = int.tryParse(value);
                        if (n == null) {
                          return s.arniaFormValidateNumeroFormat;
                        }
                        if (widget.arnia == null && _numeriUsati.contains(n)) {
                          return s.arniaFormValidateNumeroUsato(n);
                        }
                        if (widget.arnia != null && n != widget.arnia!.numero && _numeriUsati.contains(n)) {
                          return s.arniaFormValidateNumeroUsato(n);
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _numero = int.parse(value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Colore arnia
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: s.arniaFormLblColore,
                        border: const OutlineInputBorder(),
                      ),
                      value: _colore,
                      items: _coloriDisponibili.map((color) {
                        return DropdownMenuItem<String>(
                          value: color['id'],
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _colorFromHex(color['hex']),
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(color['nome']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: _onColoreChanged,
                    ),
                    const SizedBox(height: 16),

                    // Tipo arnia
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              s.arniaFormLblTipoArnia,
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                            FieldHelpIcon(
                              '🏠 Dadant-Blatt: la più diffusa in Italia, telaio grande.\n'
                              '📦 Langstroth: standard internazionale, verticale.\n'
                              '🛖 Top Bar (Kenyana): orizzontale con listelli, naturale.\n'
                              '🗼 Warré: verticale a moduli sovrapposti, gestione minimale.\n'
                              '🔭 Arnia da Osservazione: pareti trasparenti per studio.\n'
                              '👑 Pappa Reale / Allevamento Regine: per produzione pappa reale o allevamento.\n'
                              '📫 Nucleo in Legno: nucleo tradizionale 5-6 telaini.\n'
                              '📮 Nucleo in Polistirolo: nucleo leggero per sciami e regine.\n'
                              '📦 Portasciami / Prendisciame: raccolta sciami temporanea.\n'
                              '🔹 Apidea / Kieler: arnia miniatura per fecondazione regine.\n'
                              '🔸 Mini-Plus: formato ridotto per nuclei e fecondazione.',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          value: _tipoArnia,
                          items: _tipiArnia.map((t) {
                            return DropdownMenuItem<String>(
                              value: t['id'],
                              child: Text('${t['icona']}  ${s.arniaTypeName(t['id']!)}'),
                            );
                          }).toList(),
                          onChanged: (v) { if (v != null) setState(() => _tipoArnia = v); },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Data installazione
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _dataInstallazione,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        
                        if (pickedDate != null) {
                          setState(() {
                            _dataInstallazione = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: s.arniaFormLblDataInstall,
                          border: const OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateFormat.format(_dataInstallazione)),
                            Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Stato attivo
                    SwitchListTile(
                      title: Text(s.arniaFormActiveTitle),
                      value: _attiva,
                      onChanged: (value) {
                        setState(() {
                          _attiva = value;
                        });
                      },
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Note
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: s.arniaFormLblNotes,
                        hintText: s.arniaFormHintNotes,
                        border: const OutlineInputBorder(),
                      ),
                      initialValue: _note,
                      maxLines: 3,
                      onSaved: (value) {
                        _note = value ?? '';
                      },
                    ),
                    const SizedBox(height: 16),

                    // Chip NFC
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.nfc,
                            color: _nfcId != null ? Colors.green : Colors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.nfcChipPairing,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _nfcId != null
                                      ? '${s.nfcChipAssigned}: $_nfcId'
                                      : s.nfcChipNone,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _nfcId != null ? Colors.green[800] : Colors.grey[600],
                                    fontWeight: _nfcId != null ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_nfcId != null)
                            TextButton(
                              onPressed: () => setState(() => _nfcId = null),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Text(s.nfcChipRemoveBtn),
                            ),
                          if (_isScanningNfc)
                            const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            TextButton(
                              onPressed: _scanNfcForPairing,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Text(s.nfcScanToAssign),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pulsante salva
                    ElevatedButton(
                      onPressed: _saveArnia,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          widget.arnia != null ? s.arniaFormBtnUpdate : s.arniaFormBtnCreate,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  // Helper per convertire colore hex in Color
  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
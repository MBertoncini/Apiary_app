// lib/screens/pagamento/quote_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../models/quota_utente.dart';
import '../../models/gruppo.dart';
import '../../services/pagamento_service.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/offline_banner.dart';

class QuoteScreen extends StatefulWidget {
  @override
  _QuoteScreenState createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  List<QuotaUtente> _quote = [];
  List<Gruppo> _gruppi = [];
  Gruppo? _selectedGruppo;
  bool _isLoading = true;
  String? _errorMessage;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    _loadDati();
  }

  Future<void> _loadDati() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final pagamentoService = PagamentoService(apiService);

      // Carica i gruppi
      try {
        final response = await apiService.get('/gruppi/');

        List<dynamic> gruppiJson = [];
        if (response is List) {
          gruppiJson = response;
        } else if (response is Map && response.containsKey('results')) {
          gruppiJson = response['results'] as List;
        }

        setState(() {
          _gruppi = gruppiJson.map((json) => Gruppo.fromJson(json)).toList();
          if (_gruppi.isNotEmpty && _selectedGruppo == null) {
            _selectedGruppo = _gruppi.first;
          }
        });
      } catch (e) {
        debugPrint('Errore caricamento gruppi: $e');
        // Non bloccante
      }

      // Carica le quote
      final quote = await pagamentoService.getQuote();

      setState(() {
        _quote = quote;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = _s.quoteErrLoading(e.toString());
        _isLoading = false;
      });
    }
  }

  List<QuotaUtente> _getQuoteFiltered() {
    if (_selectedGruppo == null) {
      return _quote;
    }
    return _quote.where((quota) => quota.gruppo == _selectedGruppo!.id).toList();
  }

  Future<void> _editQuota(QuotaUtente quota) async {
    final percentuale = await _showEditDialog(quota);

    if (percentuale == null) return;

    if (!await _validateGroupSum(
      gruppoId: quota.gruppo,
      newPercentuale: percentuale,
      excludeQuotaId: quota.id,
    )) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final pagamentoService = PagamentoService(apiService);

      await pagamentoService.updateQuota(
        quota.id,
        {
          'percentuale': percentuale,
          'utente': quota.utente,
          'gruppo': quota.gruppo,
        }
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.quoteUpdatedOk)),
      );

      _loadDati();
    } catch (e) {
      setState(() {
        _errorMessage = _s.quoteErrUpdate(e.toString());
        _isLoading = false;
      });
    }
  }

  /// Restituisce true se la somma è valida o l'utente ha confermato.
  /// Restituisce false (e non procede col salvataggio) se la somma supererebbe
  /// 100% o se l'utente ha annullato la conferma per somma != 100.
  Future<bool> _validateGroupSum({
    required int? gruppoId,
    required double newPercentuale,
    int? excludeQuotaId,
  }) async {
    if (gruppoId == null) return true;
    final altreQuote = _quote.where(
      (q) => q.gruppo == gruppoId && q.id != excludeQuotaId,
    );
    final sommaAltre = altreQuote.fold<double>(0, (s, q) => s + q.percentuale);
    final sommaTotale = sommaAltre + newPercentuale;

    // Tolleranza arrotondamento: 0.01%.
    if (sommaTotale > 100.0 + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.quoteValidSommaSupera100(sommaTotale.toStringAsFixed(2)))),
      );
      return false;
    }

    if ((sommaTotale - 100.0).abs() > 0.01) {
      final s = _s;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.quoteConfirmSommaNon100Title(sommaTotale.toStringAsFixed(2))),
          content: Text(s.quoteConfirmSommaNon100Msg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.dialogCancelBtn),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.quoteConfirmSommaNon100Continue),
            ),
          ],
        ),
      );
      return confirmed == true;
    }

    return true;
  }

  Future<double?> _showEditDialog(QuotaUtente quota) async {
    final s = _s;
    final controller = TextEditingController(text: quota.percentuale.toString());
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.quoteEditTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.quoteEditMsg(quota.utenteUsername)),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: s.quoteLabelPercentuale,
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return s.quoteValidPercRequired;
                }
                if (double.tryParse(value.replaceAll(',', '.')) == null) {
                  return s.quoteValidPercInvalid;
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.dialogCancelBtn),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.replaceAll(',', '.');
              final percentuale = double.tryParse(value);
              if (percentuale != null) {
                Navigator.pop(context, percentuale);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.quoteValidPercInvalid)),
                );
              }
            },
            child: Text(s.controlloFormBtnSalva),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuota(QuotaUtente quota) async {
    final s = _s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.dialogConfirmDeleteTitle),
        content: Text(s.quoteDeleteMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.dialogCancelBtn),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.dialogConfirmDeleteBtn),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final pagamentoService = PagamentoService(apiService);

        final success = await pagamentoService.deleteQuota(quota.id);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_s.quoteDeletedOk)),
          );
          _loadDati();
        } else {
          setState(() {
            _errorMessage = _s.quoteErrDelete;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = _s.quoteErrDeleteE(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  /// Carica la lista dei membri di un gruppo dal backend.
  /// Ritorna lista di {id, username}. Throws on errore di rete.
  Future<List<Map<String, dynamic>>> _fetchMembriGruppo(int gruppoId) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final response = await apiService.get('/gruppi/$gruppoId/membri/');
    final List<dynamic> list = response is List
        ? response
        : (response is Map ? (response['results'] as List? ?? const []) : const []);
    return list
        .where((m) => m is Map && m['utente'] is int)
        .map((m) => {
              'id': m['utente'] as int,
              'username': (m['utente_username'] as String?) ?? '—',
            })
        .toList();
  }

  Future<void> _addQuota() async {
    if (_selectedGruppo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.quoteAddNoGruppo)),
      );
      return;
    }

    final gruppoId = _selectedGruppo!.id;

    // Carica i membri del gruppo dal backend (single source of truth: l'API).
    // Niente input testuale di ID, niente match locale fragile.
    final List<Map<String, dynamic>> membri;
    try {
      membri = await _fetchMembriGruppo(gruppoId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.quoteAddErrCaricamentoMembri(e.toString()))),
      );
      return;
    }

    // Filtra membri che hanno già una quota in questo gruppo: una quota per
    // utente per gruppo è il vincolo del modello (la formula del bilancio
    // assume quote distinte per utente).
    final utentiConQuota = _quote
        .where((q) => q.gruppo == gruppoId)
        .map((q) => q.utente)
        .toSet();
    final membriDisponibili = membri.where((m) => !utentiConQuota.contains(m['id'])).toList();

    if (membriDisponibili.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.quoteAddNoMembriDisponibili)),
      );
      return;
    }

    final quota = await _showAddDialog(membriDisponibili);

    if (quota != null) {
      if (!await _validateGroupSum(
        gruppoId: quota['gruppo'] as int?,
        newPercentuale: (quota['percentuale'] as num?)?.toDouble() ?? 0.0,
      )) {
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final pagamentoService = PagamentoService(apiService);

        await pagamentoService.createQuota(quota);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s.quoteAddedOk)),
        );

        _loadDati();
      } catch (e) {
        setState(() {
          _errorMessage = _s.quoteErrAdd(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _showAddDialog(List<Map<String, dynamic>> membriDisponibili) async {
    final s = _s;
    final percentualeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int? selectedUtenteId = membriDisponibili.length == 1
        ? membriDisponibili.first['id'] as int
        : null;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(s.quoteAddTitle),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedUtenteId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: s.quoteAddLabelUtente,
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                  ),
                  items: membriDisponibili
                      .map((m) => DropdownMenuItem<int>(
                            value: m['id'] as int,
                            child: Text(m['username'] as String, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  validator: (val) => val == null ? s.quoteValidUtenteRequired : null,
                  onChanged: (val) => setDialogState(() => selectedUtenteId = val),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: percentualeController,
                  decoration: InputDecoration(
                    labelText: s.quoteLabelPercentuale,
                    border: const OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return s.quoteValidPercRequired;
                    }
                    final perc = double.tryParse(value.replaceAll(',', '.'));
                    if (perc == null) {
                      return s.quoteValidPercInvalid;
                    }
                    if (perc <= 0 || perc > 100) {
                      return s.quoteValidPercRange;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.dialogCancelBtn),
            ),
            TextButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final percentuale = double.tryParse(percentualeController.text.replaceAll(',', '.'));

                Navigator.pop(
                  context,
                  {
                    'percentuale': percentuale,
                    'utente': selectedUtenteId,
                    'gruppo': _selectedGruppo!.id,
                  },
                );
              },
              child: Text(s.btnAdd),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.quoteTitle),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _isLoading
                ? LoadingWidget()
                : _errorMessage != null
                    ? ErrorDisplayWidget(
                        errorMessage: _errorMessage!,
                        onRetry: _loadDati,
                      )
                    : Column(
                        children: [
                          if (_gruppi.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: DropdownButtonFormField<Gruppo>(
                                value: _selectedGruppo,
                                decoration: InputDecoration(
                                  labelText: s.quoteLabelFiltroGruppo,
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.filter_list),
                                ),
                                items: [
                                  DropdownMenuItem<Gruppo>(
                                    value: null,
                                    child: Text(s.quoteTuttiGruppi),
                                  ),
                                  ..._gruppi.map((gruppo) => DropdownMenuItem<Gruppo>(
                                    value: gruppo,
                                    child: Text(gruppo.nome),
                                  )).toList(),
                                ],
                                onChanged: (Gruppo? value) {
                                  setState(() {
                                    _selectedGruppo = value;
                                  });
                                },
                              ),
                            ),
                          Expanded(
                            child: _buildQuoteList(),
                          ),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuota,
        child: Icon(Icons.add),
        tooltip: s.quoteTooltipAdd,
      ),
    );
  }

  Widget _buildQuoteList() {
    final s = _s;
    final quoteFiltered = _getQuoteFiltered();

    if (quoteFiltered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              s.quoteEmptyTitle,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text(s.quoteTooltipAdd),
              onPressed: _addQuota,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: quoteFiltered.length,
      itemBuilder: (context, index) {
        final quota = quoteFiltered[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(quota.utenteUsername),
            subtitle: Text(quota.gruppoNome ?? 'Gruppo ${quota.gruppo}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${quota.percentuale}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editQuota(quota),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteQuota(quota),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

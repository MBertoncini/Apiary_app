// lib/screens/pagamento/quote_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../models/quota_utente.dart';
import '../../models/gruppo.dart';
import '../../services/pagamento_service.dart';
import '../../services/api_service.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

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
        print('Errore caricamento gruppi: $e');
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
        _errorMessage = 'Errore durante il caricamento delle quote: $e';
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
    
    if (percentuale != null) {
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
          SnackBar(content: Text('Quota aggiornata con successo')),
        );
        
        _loadDati();
      } catch (e) {
        setState(() {
          _errorMessage = 'Errore durante l\'aggiornamento della quota: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<double?> _showEditDialog(QuotaUtente quota) async {
    final controller = TextEditingController(text: quota.percentuale.toString());
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifica quota'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Modifica la percentuale per ${quota.utenteUsername}'),
            SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Percentuale',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci una percentuale';
                }
                if (double.tryParse(value.replaceAll(',', '.')) == null) {
                  return 'Inserisci una percentuale valida';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.replaceAll(',', '.');
              final percentuale = double.tryParse(value);
              if (percentuale != null) {
                Navigator.pop(context, percentuale);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Inserisci una percentuale valida')),
                );
              }
            },
            child: Text('SALVA'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteQuota(QuotaUtente quota) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conferma eliminazione'),
        content: Text('Sei sicuro di voler eliminare questa quota?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('ELIMINA'),
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
            SnackBar(content: Text('Quota eliminata con successo')),
          );
          _loadDati();
        } else {
          setState(() {
            _errorMessage = 'Errore durante l\'eliminazione della quota';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Errore durante l\'eliminazione della quota: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _addQuota() async {
    if (_selectedGruppo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seleziona un gruppo prima di aggiungere una quota')),
      );
      return;
    }
    
    // Mostra dialog per inserire nuova quota
    final quota = await _showAddDialog();
    
    if (quota != null) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final pagamentoService = PagamentoService(apiService);
        
        await pagamentoService.createQuota(quota);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quota aggiunta con successo')),
        );
        
        _loadDati();
      } catch (e) {
        setState(() {
          _errorMessage = 'Errore durante l\'aggiunta della quota: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<Map<String, dynamic>?> _showAddDialog() async {
    final percentualeController = TextEditingController();
    final utenteIdController = TextEditingController();
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aggiungi quota'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: utenteIdController,
              decoration: InputDecoration(
                labelText: 'ID Utente',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: percentualeController,
              decoration: InputDecoration(
                labelText: 'Percentuale',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () {
              final percentuale = double.tryParse(percentualeController.text.replaceAll(',', '.'));
              final utenteId = int.tryParse(utenteIdController.text);
              
              if (percentuale == null || utenteId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Inserisci valori validi')),
                );
                return;
              }
              
              Navigator.pop(
                context, 
                {
                  'percentuale': percentuale,
                  'utente': utenteId,
                  'gruppo': _selectedGruppo!.id,
                }
              );
            },
            child: Text('AGGIUNGI'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestione Quote'),
      ),
      body: _isLoading 
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
                            labelText: 'Filtra per gruppo',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.filter_list),
                          ),
                          items: [
                            DropdownMenuItem<Gruppo>(
                              value: null,
                              child: Text('Tutti i gruppi'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuota,
        child: Icon(Icons.add),
        tooltip: 'Aggiungi Quota',
      ),
    );
  }
  
  Widget _buildQuoteList() {
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
            SizedBox(height: 16),
            Text(
              'Nessuna quota trovata',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Aggiungi Quota'),
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
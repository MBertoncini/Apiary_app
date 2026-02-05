// lib/screens/pagamento/pagamento_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/pagamento.dart';
import '../../services/pagamento_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class PagamentoDetailScreen extends StatefulWidget {
  final int pagamentoId;
  
  PagamentoDetailScreen({required this.pagamentoId});
  
  @override
  _PagamentoDetailScreenState createState() => _PagamentoDetailScreenState();
}

class _PagamentoDetailScreenState extends State<PagamentoDetailScreen> {
  Pagamento? _pagamento;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadPagamento();
  }
  
  Future<void> _loadPagamento() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final pagamentoService = PagamentoService(apiService);
      
      final pagamento = await pagamentoService.getPagamento(widget.pagamentoId);
      
      setState(() {
        _pagamento = pagamento;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore durante il caricamento del pagamento: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deletePagamento() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conferma eliminazione'),
        content: Text('Sei sicuro di voler eliminare questo pagamento?'),
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
        
        final success = await pagamentoService.deletePagamento(widget.pagamentoId);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pagamento eliminato con successo')),
          );
          Navigator.pop(context, true);
        } else {
          setState(() {
            _errorMessage = 'Errore durante l\'eliminazione del pagamento';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Errore durante l\'eliminazione del pagamento: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final formatDate = DateFormat('dd/MM/yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Dettaglio Pagamento'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _pagamento == null ? null : () {
              Navigator.pushNamed(
                context,
                AppConstants.pagamentoCreateRoute,
                arguments: _pagamento!.id,
              ).then((_) => _loadPagamento());
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _pagamento == null ? null : _deletePagamento,
          ),
        ],
      ),
      body: _isLoading 
          ? LoadingWidget()
          : _errorMessage != null
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage!,
                  onRetry: _loadPagamento,
                )
              : _pagamento == null
                  ? Center(child: Text('Pagamento non trovato'))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      formatCurrency.format(_pagamento!.importo),
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: ThemeConstants.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow('Descrizione', _pagamento!.descrizione),
                                  _buildInfoRow('Data', formatDate.format(DateTime.parse(_pagamento!.data))),
                                  _buildInfoRow('Utente', _pagamento!.utenteUsername),
                                  if (_pagamento!.gruppo != null)
                                    _buildInfoRow('Gruppo', _pagamento!.gruppoNome ?? 'Gruppo ${_pagamento!.gruppo}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
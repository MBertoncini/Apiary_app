// lib/screens/pagamento/pagamento_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/pagamento.dart';
import '../../services/pagamento_service.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/error_widget.dart';

class PagamentoDetailScreen extends StatefulWidget {
  final int pagamentoId;
  
  PagamentoDetailScreen({required this.pagamentoId});
  
  @override
  _PagamentoDetailScreenState createState() => _PagamentoDetailScreenState();
}

class _PagamentoDetailScreenState extends State<PagamentoDetailScreen> {
  Pagamento? _pagamento;
  bool _isRefreshing = true;
  String? _errorMessage;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;
  
  @override
  void initState() {
    super.initState();
    _loadPagamento();
  }
  
  Future<void> _loadPagamento() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final pagamentoService = PagamentoService(apiService);

      final pagamento = await pagamentoService.getPagamento(widget.pagamentoId);

      setState(() {
        _pagamento = pagamento;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = _s.pagamentoDetailErrLoading(e.toString());
        _isRefreshing = false;
      });
    }
  }
  
  Future<void> _deletePagamento() async {
    final s = _s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.dialogConfirmDeleteTitle),
        content: Text(s.pagamentoDetailDeleteMsg),
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
        _isRefreshing = true;
      });
      
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final pagamentoService = PagamentoService(apiService);
        
        final success = await pagamentoService.deletePagamento(widget.pagamentoId);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_s.pagamentoDetailDeletedOk)),
          );
          Navigator.pop(context, true);
        } else {
          setState(() {
            _errorMessage = _s.pagamentoDetailErrDelete;
            _isRefreshing = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = '${_s.pagamentoDetailErrDelete}: $e';
          _isRefreshing = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final formatDate = DateFormat('dd/MM/yyyy');
    
    Provider.of<LanguageService>(context);
    final s = _s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.pagamentoDetailTitle),
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
      body: Column(
        children: [
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _isRefreshing && _pagamento == null && _errorMessage == null
                ? const SizedBox.shrink()
                : _errorMessage != null
                    ? ErrorDisplayWidget(
                        errorMessage: _errorMessage!,
                        onRetry: _loadPagamento,
                      )
                    : _pagamento == null
                        ? Center(child: Text(s.pagamentoDetailNotFound))
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
                                  _buildInfoRow(s.pagamentoDetailLabelDescrizione, _pagamento!.descrizione),
                                  _buildInfoRow(s.labelDate, formatDate.format(DateTime.parse(_pagamento!.data))),
                                  _buildInfoRow(s.pagamentoDetailLabelUtente, _pagamento!.utenteUsername),
                                  if (_pagamento!.gruppo != null)
                                    _buildInfoRow(s.pagamentoDetailLabelGruppo, _pagamento!.gruppoNome ?? '${s.pagamentoDetailLabelGruppo} ${_pagamento!.gruppo}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
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
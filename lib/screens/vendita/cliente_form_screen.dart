import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class ClienteFormScreen extends StatefulWidget {
  final int? clienteId;
  ClienteFormScreen({this.clienteId});
  @override
  _ClienteFormScreenState createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ApiService _apiService;
  bool _isLoading = false;
  bool _isLoadingData = false;

  final _nomeController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _indirizzoController = TextEditingController();
  final _noteController = TextEditingController();

  bool get _isEditing => widget.clienteId != null;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    if (_isEditing) _loadCliente();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _indirizzoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCliente() async {
    setState(() { _isLoadingData = true; });
    try {
      final data = await _apiService.get('${ApiConstants.clientiUrl}${widget.clienteId}/');
      _nomeController.text = data['nome'] ?? '';
      _telefonoController.text = data['telefono'] ?? '';
      _emailController.text = data['email'] ?? '';
      _indirizzoController.text = data['indirizzo'] ?? '';
      _noteController.text = data['note'] ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
    setState(() { _isLoadingData = false; });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    final data = {
      'nome': _nomeController.text,
      'telefono': _telefonoController.text.isEmpty ? null : _telefonoController.text,
      'email': _emailController.text.isEmpty ? null : _emailController.text,
      'indirizzo': _indirizzoController.text.isEmpty ? null : _indirizzoController.text,
      'note': _noteController.text.isEmpty ? null : _noteController.text,
    };

    try {
      if (_isEditing) {
        await _apiService.put('${ApiConstants.clientiUrl}${widget.clienteId}/', data);
      } else {
        await _apiService.post(ApiConstants.clientiUrl, data);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Cliente aggiornato' : 'Cliente creato')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _deleteCliente() async {
    if (!_isEditing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conferma eliminazione'),
        content: Text('Eliminare questo cliente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ANNULLA')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('ELIMINA')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _apiService.delete('${ApiConstants.clientiUrl}${widget.clienteId}/');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cliente eliminato')));
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica Cliente' : 'Nuovo Cliente'),
        actions: [
          if (_isEditing)
            IconButton(icon: Icon(Icons.delete), onPressed: _deleteCliente),
        ],
      ),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(labelText: 'Nome *', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Campo obbligatorio' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: InputDecoration(labelText: 'Telefono', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _indirizzoController,
                      decoration: InputDecoration(labelText: 'Indirizzo', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isEditing ? 'AGGIORNA' : 'CREA CLIENTE'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

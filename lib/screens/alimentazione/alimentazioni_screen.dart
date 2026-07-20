import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/api_constants.dart';
import '../../constants/app_constants.dart';
import '../../models/alimentazione.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

/// Lista delle alimentazioni somministrate (filtrabile per colonia).
///
/// Aperta da [ColoniaDetailScreen] passando `arguments: coloniaId` (int) per
/// pre-filtrare. Senza arg mostra tutte le alimentazioni accessibili.
class AlimentazioniScreen extends StatefulWidget {
  final int? coloniaId;
  const AlimentazioniScreen({Key? key, this.coloniaId}) : super(key: key);

  @override
  State<AlimentazioniScreen> createState() => _AlimentazioniScreenState();
}

class _AlimentazioniScreenState extends State<AlimentazioniScreen> {
  late ApiService _api;
  bool _loading = true;
  String? _error;
  List<Alimentazione> _items = [];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    _api = ApiService(auth);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = widget.coloniaId != null
          ? '${ApiConstants.alimentazioniUrl}?colonia=${widget.coloniaId}'
          : ApiConstants.alimentazioniUrl;
      final list = await _api.getAll(url);
      if (!mounted) return;
      setState(() {
        _items = list
            .map((e) => Alimentazione.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete(Alimentazione a) async {
    try {
      await _api.delete('${ApiConstants.alimentazioniUrl}${a.id}/');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alimentazione eliminata')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final coloniaId = widget.coloniaId ?? (args is int ? args : null);
    return Scaffold(
      appBar: AppBar(
        title: Text(coloniaId == null
            ? 'Alimentazioni'
            : 'Alimentazioni · colonia $coloniaId'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuova'),
        onPressed: () async {
          final ok = await Navigator.pushNamed(
            context,
            AppConstants.alimentazioneCreateRoute,
            arguments: coloniaId,
          );
          if (ok == true) _load();
        },
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Errore: $_error', textAlign: TextAlign.center),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nessuna alimentazione registrata.\n'
            'Aggiungile per migliorare i modelli predittivi sulla produzione miele.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final a = _items[i];
          return ListTile(
            leading: const Icon(Icons.restaurant, color: Colors.amber),
            title: Text(
              '${a.tipoDisplay ?? a.tipo} · ${a.quantitaKg.toStringAsFixed(2)} kg',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${a.data}'
              '${a.scopoDisplay != null && a.scopoDisplay!.isNotEmpty ? " · ${a.scopoDisplay}" : ""}'
              '${a.coloniaDisplay != null ? " · ${a.coloniaDisplay}" : ""}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final c = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminare?'),
                    content: const Text(
                        'Questa alimentazione verrà rimossa dal dataset.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annulla')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Elimina')),
                    ],
                  ),
                );
                if (c == true) _delete(a);
              },
            ),
          );
        },
      ),
    );
  }
}

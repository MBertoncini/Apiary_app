import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/api_constants.dart';
import '../../constants/app_constants.dart';
import '../../models/nomadismo_event.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

/// Storico spostamenti di nomadismo per una colonia (o globale).
class NomadismiScreen extends StatefulWidget {
  final int? coloniaId;
  const NomadismiScreen({Key? key, this.coloniaId}) : super(key: key);

  @override
  State<NomadismiScreen> createState() => _NomadismiScreenState();
}

class _NomadismiScreenState extends State<NomadismiScreen> {
  late ApiService _api;
  bool _loading = true;
  String? _error;
  List<NomadismoEvent> _items = [];

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
          ? '${ApiConstants.nomadismiUrl}?colonia=${widget.coloniaId}'
          : ApiConstants.nomadismiUrl;
      final list = await _api.getAll(url);
      if (!mounted) return;
      setState(() {
        _items = list
            .map((e) => NomadismoEvent.fromJson(e as Map<String, dynamic>))
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

  Future<void> _delete(NomadismoEvent n) async {
    try {
      await _api.delete('${ApiConstants.nomadismiUrl}${n.id}/');
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final coloniaId = widget.coloniaId ?? (args is int ? args : null);
    return Scaffold(
      appBar: AppBar(
        title: Text(coloniaId == null
            ? 'Spostamenti (nomadismo)'
            : 'Nomadismo · colonia $coloniaId'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuovo'),
        onPressed: () async {
          final ok = await Navigator.pushNamed(
            context,
            AppConstants.nomadismoCreateRoute,
            arguments: coloniaId,
          );
          if (ok == true) _load();
        },
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
            'Nessuno spostamento registrato.',
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
          final n = _items[i];
          return ListTile(
            leading: const Icon(Icons.swap_horiz, color: Colors.blue),
            title: Text(
              '${n.apiarioOrigineNome ?? "—"} → ${n.apiarioDestinazioneNome ?? "(${n.apiarioDestinazione})"}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${n.dataSpostamento}'
              '${n.motivo != null && n.motivo!.isNotEmpty ? " · ${n.motivo}" : ""}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final c = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminare?'),
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
                if (c == true) _delete(n);
              },
            ),
          );
        },
      ),
    );
  }
}

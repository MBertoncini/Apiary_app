import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/analisi_telaino.dart';
import '../../services/analisi_telaino_service.dart';

class AnalisiTelainoListScreen extends StatefulWidget {
  final int arniaId;

  const AnalisiTelainoListScreen({required this.arniaId});

  @override
  _AnalisiTelainoListScreenState createState() => _AnalisiTelainoListScreenState();
}

class _AnalisiTelainoListScreenState extends State<AnalisiTelainoListScreen> {
  List<AnalisiTelaino> _analisi = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalisi();
  }

  Future<void> _loadAnalisi() async {
    setState(() => _isLoading = true);
    try {
      final service = Provider.of<AnalisiTelainoService>(context, listen: false);
      final analisi = await service.getAnalisiByArnia(widget.arniaId);
      setState(() => _analisi = analisi);
    } catch (e) {
      debugPrint('Error loading analisi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisi Telaini'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analisi.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAnalisi,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _analisi.length,
                    itemBuilder: (context, index) => _buildAnalisiCard(_analisi[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            AppConstants.analisiTelainoRoute,
            arguments: widget.arniaId,
          );
          if (result == true) _loadAnalisi();
        },
        child: const Icon(Icons.add),
        tooltip: 'Nuova analisi',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessuna analisi registrata',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                AppConstants.analisiTelainoRoute,
                arguments: widget.arniaId,
              );
              if (result == true) _loadAnalisi();
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Avvia Analisi'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalisiCard(AnalisiTelaino analisi) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Telaino ${analisi.numeroTelaino} - Facciata ${analisi.facciata}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        analisi.data ?? '',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildTag('Api: ${analisi.conteggioApi}', Colors.orange),
                _buildTag('Regine: ${analisi.conteggioRegine}', Colors.purple),
                _buildTag('Fuchi: ${analisi.conteggioFuchi}', Colors.blue),
                _buildTag('Celle R.: ${analisi.conteggioCelleReali}', Colors.amber),
              ],
            ),
            if (analisi.note != null && analisi.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                analisi.note!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color.shade700),
      ),
    );
  }
}

extension _ColorExt on Color {
  Color get shade700 => HSLColor.fromColor(this).withLightness(0.35).toColor();
}

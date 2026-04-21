import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/contenitore_stoccaggio.dart';
import '../../../services/language_service.dart';

class ContenitoreCard extends StatelessWidget {
  final ContenitoreStoccaggio contenitore;
  final VoidCallback onInvasetta;
  final VoidCallback onDelete;

  const ContenitoreCard({
    Key? key,
    required this.contenitore,
    required this.onInvasetta,
    required this.onDelete,
  }) : super(key: key);

  static const double _cardW = 130.0;

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    final c = contenitore;
    final pct = c.percentualePieno;
    final color = _colorForTipo(c.tipo);

    return SizedBox(
      width: _cardW,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.35), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_iconForTipo(c.tipo), style: const TextStyle(fontSize: 22)),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    onSelected: (v) { if (v == 'delete') onDelete(); },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'delete', child: Text(s.btnDelete)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                c.nome.isNotEmpty ? c.nome : c.tipoDisplay,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('${c.kgAttuali.toStringAsFixed(1)}/${c.capacitaKg.toStringAsFixed(0)} kg',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              const SizedBox(height: 6),
              // Fill bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 7,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: c.isVuoto ? null : onInvasetta,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    backgroundColor: color.withOpacity(0.1),
                  ),
                  child: Text(s.contenitoreCardBtnInvasetta,
                      style: TextStyle(fontSize: 11, color: c.isVuoto ? Colors.grey : color)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorForTipo(String tipo) {
    switch (tipo) {
      case 'bidone': return Colors.blueGrey;
      case 'fusto': return Colors.brown;
      default: return Colors.amber.shade700;
    }
  }

  String _iconForTipo(String tipo) {
    switch (tipo) {
      case 'bidone': return '🛢️';
      case 'fusto': return '🪣';
      default: return '🪣';
    }
  }
}

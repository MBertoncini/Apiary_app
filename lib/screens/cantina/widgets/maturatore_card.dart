import 'package:flutter/material.dart';
import '../../../models/maturatore.dart';

class MaturatoreCard extends StatelessWidget {
  final Maturatore maturatore;
  final VoidCallback onTrasferisci;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const MaturatoreCard({
    Key? key,
    required this.maturatore,
    required this.onTrasferisci,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final m = maturatore;
    final isPronto = m.isPronto;
    final color = isPronto ? Colors.green : Colors.orange;
    final pct = m.percentualePieno;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.nome,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(m.tipoMiele,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                _StatusBadge(isPronto: isPronto, giorniRimanenti: m.giorniRimanenti),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                    const PopupMenuItem(value: 'delete', child: Text('Elimina')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fill level
            Row(
              children: [
                Text('${m.kgAttuali.toStringAsFixed(1)} kg',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                Text(' / ${m.capacitaKg.toStringAsFixed(0)} kg',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const Spacer(),
                Text('${(pct * 100).toInt()}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 12),

            // Action button
            if (isPronto)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTrasferisci,
                  icon: const Icon(Icons.move_down, size: 18),
                  label: const Text('Trasferisci in contenitori'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Icon(Icons.hourglass_bottom, size: 14, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    m.giorniRimanenti == 0
                        ? 'Pronto oggi'
                        : 'Pronto tra ${m.giorniRimanenti} giorn${m.giorniRimanenti == 1 ? "o" : "i"}',
                    style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onTrasferisci,
                    icon: const Icon(Icons.move_down, size: 14),
                    label: const Text('Trasferisci ora', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isPronto;
  final int giorniRimanenti;
  const _StatusBadge({required this.isPronto, required this.giorniRimanenti});

  @override
  Widget build(BuildContext context) {
    if (isPronto) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('✅ Pronto',
            style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('⏳ ${giorniRimanenti}gg',
          style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

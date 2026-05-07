import 'package:flutter/material.dart';
import '../../../constants/theme_constants.dart';
import '../../../models/regina.dart';
import '../../../widgets/beehive_illustrations.dart';

/// Nodo minimale dell'albero genealogico: cerchio colorato (colore di
/// marcatura) con icona regina e una label compatta sotto (numero arnia).
class ReginaNodeWidget extends StatelessWidget {
  final Regina regina;
  final VoidCallback onTap;
  final double size;
  final bool madreFuoriVista;

  const ReginaNodeWidget({
    Key? key,
    required this.regina,
    required this.onTap,
    required this.size,
    this.madreFuoriVista = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _coloreToColor(regina.colore);
    final isInactive = !regina.isAttiva;
    final label = regina.arniaNumero ?? regina.arniaId.toString();
    final year = _yearFromDate(regina.dataInserimento);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size + 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (madreFuoriVista)
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                width: 2,
                height: 8,
                decoration: BoxDecoration(
                  color: ThemeConstants.dividerColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              )
            else
              const SizedBox(height: 10),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: isInactive ? 0.45 : 1.0,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.18),
                      border: Border.all(
                        color: regina.sospettaAssente ? Colors.red : color,
                        width: regina.sospettaAssente ? 2.5 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: HandDrawnQueenBee(
                        size: size * 0.65,
                        color: color,
                      ),
                    ),
                  ),
                ),
                if (regina.sospettaAssente)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.priority_high,
                          color: Colors.white, size: 12),
                    ),
                  ),
                if (regina.selezionata)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: ThemeConstants.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: ThemeConstants.cardColor, width: 1.5),
                      ),
                      child: const Icon(Icons.star,
                          color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'A. $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isInactive
                    ? ThemeConstants.textSecondaryColor
                    : ThemeConstants.textPrimaryColor,
              ),
            ),
            if (year != null)
              Text(
                year,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 10,
                  color: ThemeConstants.textSecondaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Color _coloreToColor(String? c) {
    switch (c) {
      case 'bianco':
        return Colors.grey.shade300;
      case 'giallo':
        return Colors.amber;
      case 'rosso':
        return Colors.red;
      case 'verde':
        return Colors.green;
      case 'blu':
        return Colors.blue;
      default:
        return Colors.grey.shade400;
    }
  }

  static String? _yearFromDate(String? date) {
    if (date == null || date.length < 4) return null;
    final y = date.substring(0, 4);
    return RegExp(r'^\d{4}$').hasMatch(y) ? y : null;
  }
}

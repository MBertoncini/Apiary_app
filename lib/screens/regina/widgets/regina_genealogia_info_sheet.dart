import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../constants/theme_constants.dart';
import '../../../l10n/app_strings.dart';
import '../../../models/regina.dart';
import '../../../services/language_service.dart';
import '../../../widgets/beehive_illustrations.dart';

class ReginaGenealogiaInfoSheet extends StatelessWidget {
  final Regina regina;
  final int figlieCount;
  final bool madreFuoriVista;

  const ReginaGenealogiaInfoSheet({
    Key? key,
    required this.regina,
    required this.figlieCount,
    required this.madreFuoriVista,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    final reginaColor = _coloreToColor(regina.colore);

    return Container(
      decoration: const BoxDecoration(
        color: ThemeConstants.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ThemeConstants.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reginaColor.withOpacity(0.18),
                      border: Border.all(color: reginaColor, width: 2),
                    ),
                    child: Center(
                      child: HandDrawnQueenBee(size: 38, color: reginaColor),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.reginaListItemTitle(
                            (regina.arniaNumero ?? regina.arniaId.toString()).toString(),
                          ),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: ThemeConstants.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getRazzaDisplay(s, regina.razza),
                          style: const TextStyle(
                            fontSize: 13,
                            color: ThemeConstants.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (regina.sospettaAssente)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.warning_amber_rounded,
                          color: Colors.red, size: 22),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (regina.sospettaAssente)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red, size: 16),
                      SizedBox(width: 6),
                      Text('Sospetta assente',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              _InfoRow(
                  label: s.reginaListOrigine,
                  value: _getOrigineDisplay(s, regina.origine)),
              _InfoRow(
                  label: s.reginaListIntrodotta,
                  value: regina.dataInserimento),
              if (regina.dataNascita != null && regina.dataNascita!.isNotEmpty)
                _InfoRow(label: 'Nascita', value: regina.dataNascita!),
              if (regina.codiceMarcatura != null &&
                  regina.codiceMarcatura!.isNotEmpty)
                _InfoRow(label: 'Codice', value: regina.codiceMarcatura!),
              _InfoRow(
                label: 'Madre',
                value: regina.reginaMadreId == null
                    ? '—'
                    : madreFuoriVista
                        ? '#${regina.reginaMadreId} (fuori vista)'
                        : '#${regina.reginaMadreId}',
              ),
              _InfoRow(
                label: 'Figlie',
                value: figlieCount == 0 ? '—' : figlieCount.toString(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: regina.id == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(
                            AppConstants.reginaDetailRoute,
                            arguments: regina.id,
                          );
                        },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Apri scheda'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _coloreToColor(String? c) {
    switch (c) {
      case 'bianco':
        return Colors.white;
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

  static String _getRazzaDisplay(AppStrings s, String razza) {
    switch (razza.toLowerCase()) {
      case 'ligustica':
        return 'A. m. ligustica';
      case 'carnica':
        return 'A. m. carnica';
      case 'buckfast':
        return 'Buckfast';
      case 'caucasica':
        return 'A. m. caucasica';
      case 'sicula':
        return 'A. m. sicula';
      default:
        return razza.isNotEmpty ? razza : s.labelNa;
    }
  }

  static String _getOrigineDisplay(AppStrings s, String origine) {
    switch (origine.toLowerCase()) {
      case 'acquistata':
        return s.arniaDetailOrigineAcquistata;
      case 'allevata':
        return s.arniaDetailOrigineAllevata;
      case 'sciamatura':
        return s.arniaDetailOrigineSciamatura;
      case 'emergenza':
        return s.arniaDetailOrigineEmergenza;
      case 'sconosciuta':
        return s.arniaDetailOrigineSconosciuta;
      default:
        return origine.isNotEmpty ? origine : s.labelNa;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: ThemeConstants.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: ThemeConstants.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

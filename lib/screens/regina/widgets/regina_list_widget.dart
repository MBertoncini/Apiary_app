import 'package:flutter/material.dart';
import '../../../models/regina.dart';
import '../../../l10n/app_strings.dart';
import '../../../services/language_service.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/beehive_illustrations.dart';
import 'package:provider/provider.dart';

class ReginaListWidget extends StatelessWidget {
  final List<Regina> regine;
  final VoidCallback? onRefresh;

  const ReginaListWidget({
    Key? key, 
    required this.regine, 
    this.onRefresh
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (regine.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_florist_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Nessuna regina registrata',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    final list = ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: regine.length,
      itemBuilder: (context, index) {
        return ReginaListItem(regina: regine[index]);
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh!(),
        child: list,
      );
    }

    return list;
  }
}

class ReginaListItem extends StatelessWidget {
  final Regina regina;

  const ReginaListItem({Key? key, required this.regina}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    
    final Color reginaColor = reginaInkColorFor(regina.colore);
    final Color avatarBg = (regina.colore == 'bianco' ? Colors.grey : reginaColor).withOpacity(0.2);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: regina.sospettaAssente ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: regina.sospettaAssente
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: avatarBg,
          child: HandDrawnQueenBee(size: 35, color: reginaColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                s.reginaListItemTitle((regina.arniaNumero ?? regina.arniaId.toString()).toString()),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (regina.sospettaAssente)
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${s.reginaListRazza}: ${_getRazzaDisplay(s, regina.razza)}'),
            Text('${s.reginaListOrigine}: ${_getOrigineDisplay(s, regina.origine)}'),
            Text('${s.reginaListIntrodotta}: ${regina.dataInserimento}'),
            if (regina.sospettaAssente)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'SOSPETTA ASSENTE',
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (regina.id != null) {
            Navigator.of(context).pushNamed(
              AppConstants.reginaDetailRoute,
              arguments: regina.id,
            );
          }
        },
      ),
    );
  }

  String _getRazzaDisplay(AppStrings s, String razza) {
    switch (razza.toLowerCase()) {
      case 'ligustica':  return 'A. m. ligustica';
      case 'carnica':    return 'A. m. carnica';
      case 'buckfast':   return 'Buckfast';
      case 'caucasica':  return 'A. m. caucasica';
      case 'sicula':     return 'A. m. sicula';
      default:           return razza.isNotEmpty ? razza : s.labelNa;
    }
  }

  String _getOrigineDisplay(AppStrings s, String origine) {
    switch (origine.toLowerCase()) {
      case 'acquistata':  return s.arniaDetailOrigineAcquistata;
      case 'allevata':    return s.arniaDetailOrigineAllevata;
      case 'sciamatura':  return s.arniaDetailOrigineSciamatura;
      case 'emergenza':   return s.arniaDetailOrigineEmergenza;
      case 'sconosciuta': return s.arniaDetailOrigineSconosciuta;
      default:            return origine.isNotEmpty ? origine : s.labelNa;
    }
  }
}

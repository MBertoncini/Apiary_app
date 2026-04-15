import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/api_constants.dart';
import '../services/api_service.dart';
import '../services/attrezzatura_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';

/// Mappa tipo_arnia → label leggibile per il nome pre-compilato.
const _tipoArniaLabels = {
  'dadant': 'Dadant-Blatt',
  'langstroth': 'Langstroth',
  'top_bar': 'Top Bar',
  'warre': 'Warré',
  'osservazione': 'Osservazione',
  'pappa_reale': 'Pappa Reale',
  'nucleo_legno': 'Nucleo (legno)',
  'nucleo_polistirolo': 'Nucleo (polistirolo)',
  'portasciami': 'Portasciami',
  'apidea': 'Apidea',
  'mini_plus': 'Mini-Plus',
};

/// Mostra il popup lite "Registra come attrezzatura?" dopo la creazione di un'arnia.
///
/// Restituisce `true` se l'utente ha registrato l'attrezzatura, `false` altrimenti.
/// Controlla internamente la preferenza "Non chiedere più".
Future<bool> showAttrezzaturaPrompt({
  required BuildContext context,
  required String tipoArnia,
  required int numero,
  required int apiarioId,
  required int arniaId,
}) async {
  final storageService = Provider.of<StorageService>(context, listen: false);
  if (await storageService.shouldSkipAttrezzaturaPrompt()) return false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _AttrezzaturaPromptDialog(
      tipoArnia: tipoArnia,
      numero: numero,
      apiarioId: apiarioId,
      arniaId: arniaId,
    ),
  );
  return result ?? false;
}

class _AttrezzaturaPromptDialog extends StatefulWidget {
  final String tipoArnia;
  final int numero;
  final int apiarioId;
  final int arniaId;

  const _AttrezzaturaPromptDialog({
    required this.tipoArnia,
    required this.numero,
    required this.apiarioId,
    required this.arniaId,
  });

  @override
  State<_AttrezzaturaPromptDialog> createState() =>
      _AttrezzaturaPromptDialogState();
}

class _AttrezzaturaPromptDialogState extends State<_AttrezzaturaPromptDialog> {
  late final TextEditingController _nomeCtrl;
  final _prezzoCtrl = TextEditingController();
  String _condizione = 'nuovo';
  bool _dontAskAgain = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final label = _tipoArniaLabels[widget.tipoArnia] ?? widget.tipoArnia;
    _nomeCtrl = TextEditingController(text: '$label #${widget.numero}');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _prezzoCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _isSaving = true);
    final s = Provider.of<LanguageService>(context, listen: false).strings;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final svc = AttrezzaturaService(apiService);

      final prezzo = _prezzoCtrl.text.isNotEmpty
          ? double.tryParse(_prezzoCtrl.text.replaceAll(',', '.'))
          : null;

      final data = {
        'nome': _nomeCtrl.text.trim(),
        'stato': 'in_uso',
        'condizione': _condizione,
        'apiario': widget.apiarioId,
        'quantita': 1,
        'data_acquisto': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        if (prezzo != null && prezzo > 0) 'prezzo_acquisto': prezzo,
      };

      final attrezzatura = await svc.createAttrezzatura(
        data,
        userId: authService.currentUser!.id,
      );

      // Link arnia → attrezzatura via PATCH
      try {
        await apiService.patch(
          '${ApiConstants.arnieUrl}${widget.arniaId}/',
          {'attrezzatura': attrezzatura.id},
        );
      } catch (e) {
        debugPrint('PATCH arnia attrezzatura FK: $e');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.attrezzaturaPromptSuccess)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.attrezzaturaPromptError(e.toString()))),
      );
    }
  }

  void _dismiss() async {
    if (_dontAskAgain) {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      await storageService.saveSkipAttrezzaturaPrompt(true);
    }
    if (mounted) Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: Colors.amber[700], size: 24),
          const SizedBox(width: 8),
          Expanded(child: Text(s.attrezzaturaPromptTitle, style: const TextStyle(fontSize: 17))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.attrezzaturaPromptBody,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Nome
            TextField(
              controller: _nomeCtrl,
              decoration: InputDecoration(
                labelText: s.attrezzaturaPromptNome,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Condizione
            DropdownButtonFormField<String>(
              value: _condizione,
              decoration: InputDecoration(
                labelText: s.attrezzaturaPromptCondizione,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'nuovo', child: Text('Nuovo / New')),
                DropdownMenuItem(value: 'ottimo', child: Text('Ottimo / Excellent')),
                DropdownMenuItem(value: 'buono', child: Text('Buono / Good')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _condizione = v);
              },
            ),
            const SizedBox(height: 12),

            // Prezzo
            TextField(
              controller: _prezzoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: s.attrezzaturaPromptPrezzo,
                prefixText: '€ ',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),

            // Don't ask again
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _dontAskAgain,
                    onChanged: (v) =>
                        setState(() => _dontAskAgain = v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _dontAskAgain = !_dontAskAgain),
                    child: Text(
                      s.attrezzaturaPromptSkip,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : _dismiss,
          child: Text(s.attrezzaturaPromptBtnNo),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _register,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(s.attrezzaturaPromptBtnYes),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/api_constants.dart';
import '../../../models/contenitore_stoccaggio.dart';
import '../../../services/api_service.dart';
import '../../../services/language_service.dart';
import '../../../l10n/app_strings.dart';

class InvasettaSheet extends StatefulWidget {
  final ApiService apiService;
  final ContenitoreStoccaggio contenitore;

  const InvasettaSheet({Key? key, required this.apiService, required this.contenitore}) : super(key: key);

  @override
  State<InvasettaSheet> createState() => _InvasettaSheetState();
}

class _InvasettaSheetState extends State<InvasettaSheet> {
  int _formato = 500;
  int _numero = 0;
  final _lottoCtrl = TextEditingController();
  bool _saving = false;

  double get _kgUsati => (_formato * _numero) / 1000;
  double get _disponibile => widget.contenitore.kgAttuali;
  int get _maxVasetti => widget.contenitore.vasettiDisponibili(_formato);

  @override
  void dispose() {
    _lottoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_numero <= 0) return;
    setState(() => _saving = true);
    try {
      await widget.apiService.post(
        '${ApiConstants.contenitoriStoccaggioUrl}${widget.contenitore.id}/invasetta/',
        {
          'formato_vasetto': _formato,
          'numero_vasetti': _numero,
          if (_lottoCtrl.text.isNotEmpty) 'lotto': _lottoCtrl.text.trim(),
          'data': DateTime.now().toIso8601String().split('T')[0],
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Provider.of<LanguageService>(context, listen: false).strings.msgErrorGeneric(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.invasettaTitle(widget.contenitore.nome.isEmpty ? widget.contenitore.tipoDisplay : widget.contenitore.nome),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          Text(
            '${widget.contenitore.tipoMiele} · ${s.trasferisciKgDisponibili(_disponibile.toStringAsFixed(1))}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Formato selector
          Text(s.invasettaLblFormato, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 250, label: Text('250g')),
              ButtonSegment(value: 500, label: Text('500g')),
              ButtonSegment(value: 1000, label: Text('1 kg')),
            ],
            selected: {_formato},
            onSelectionChanged: (s) => setState(() { _formato = s.first; _numero = 0; }),
          ),
          const SizedBox(height: 16),

          // Number stepper
          Row(
            children: [
              Text(s.invasettaLblNumeroVasetti, style: const TextStyle(fontSize: 14)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _numero > 0 ? () => setState(() => _numero--) : null,
              ),
              SizedBox(
                width: 50,
                child: Text(
                  '$_numero',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _numero < _maxVasetti ? () => setState(() => _numero++) : null,
              ),
              TextButton(
                onPressed: () => setState(() => _numero = _maxVasetti),
                child: Text(s.invasettaBtnMax),
              ),
            ],
          ),

          // Kg preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.invasettaKgUsati(_numero, _formato, _kgUsati.toStringAsFixed(2))),
                Text(s.invasettaRimangono((_disponibile - _kgUsati).clamp(0, _disponibile).toStringAsFixed(2)),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Lotto
          TextField(
            controller: _lottoCtrl,
            decoration: InputDecoration(
              labelText: s.invasettaLblLotto,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_saving || _numero <= 0) ? null : _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(s.invasettaBtnConferma(_numero)),
            ),
          ),
        ],
      ),
    );
  }
}

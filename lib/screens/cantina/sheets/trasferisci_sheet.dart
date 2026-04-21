import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/api_constants.dart';
import '../../../models/maturatore.dart';
import '../../../services/api_service.dart';
import '../../../services/language_service.dart';

class TrasferisciSheet extends StatefulWidget {
  final ApiService apiService;
  final Maturatore maturatore;

  const TrasferisciSheet({Key? key, required this.apiService, required this.maturatore}) : super(key: key);

  @override
  State<TrasferisciSheet> createState() => _TrasferisciSheetState();
}

class _TrasferisciSheetState extends State<TrasferisciSheet> {
  // Each entry: {tipo, nome, capacita_kg, kg_attuali}
  final List<Map<String, dynamic>> _contenitori = [];
  bool _saving = false;

  double get _totaleAssegnato =>
      _contenitori.fold(0, (s, c) => s + (double.tryParse(c['kg_attuali'].toString()) ?? 0));

  double get _disponibile => widget.maturatore.kgAttuali;

  void _addContenitore() {
    final cap = (_disponibile - _totaleAssegnato).clamp(0, _disponibile);
    setState(() => _contenitori.add({
      'tipo': 'secchio',
      'nome': 'Secchio ${_contenitori.length + 1}',
      'capacita_kg': cap > 0 ? cap : 30.0,
      'kg_attuali': cap > 0 ? cap : 30.0,
    }));
  }

  Future<void> _save() async {
    if (_contenitori.isEmpty) return;
    if (_totaleAssegnato > _disponibile + 0.001) {
      final s = Provider.of<LanguageService>(context, listen: false).strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.trasferisciErrSupera(_totaleAssegnato.toStringAsFixed(1), _disponibile.toStringAsFixed(1)))),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.apiService.post(
        '${ApiConstants.maturatoriUrl}${widget.maturatore.id}/trasferisci/',
        {'contenitori': _contenitori},
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
          Text(s.trasferisciTitle(widget.maturatore.nome),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          Text(
            '${widget.maturatore.tipoMiele} · ${s.trasferisciKgDisponibili(_disponibile.toStringAsFixed(1))}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: _disponibile > 0 ? (_totaleAssegnato / _disponibile).clamp(0, 1) : 0,
            backgroundColor: Colors.grey.shade200,
            color: _totaleAssegnato > _disponibile ? Colors.red : Colors.green,
          ),
          Text(
            s.trasferisciKgAssegnati(_totaleAssegnato.toStringAsFixed(1), _disponibile.toStringAsFixed(1)),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          if (_contenitori.isEmpty)
            Center(child: Text(s.trasferisciNoContenitori, style: TextStyle(color: Colors.grey[500]))),
          ..._contenitori.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            return _ContenitoreRow(
              data: c,
              onChanged: (updated) => setState(() => _contenitori[i] = updated),
              onRemove: () => setState(() => _contenitori.removeAt(i)),
            );
          }),
          TextButton.icon(
            onPressed: _addContenitore,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(s.trasferisciBtnAggiungiContenitore),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_saving || _contenitori.isEmpty) ? null : _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(s.trasferisciBtnConferma),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContenitoreRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onRemove;

  const _ContenitoreRow({required this.data, required this.onChanged, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: data['tipo'],
                          decoration: InputDecoration(labelText: Provider.of<LanguageService>(context, listen: false).strings.trasferisciLblTipo, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                          items: const [
                            DropdownMenuItem(value: 'secchio', child: Text('🪣 Secchio')),
                            DropdownMenuItem(value: 'bidone', child: Text('🛢️ Bidone')),
                            DropdownMenuItem(value: 'fusto', child: Text('🪣 Fusto')),
                          ],
                          onChanged: (v) => onChanged({...data, 'tipo': v}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          initialValue: data['kg_attuali'].toString(),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: Provider.of<LanguageService>(context, listen: false).strings.trasferisciLblKg, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), suffixText: 'kg'),
                          onChanged: (v) {
                            final kg = double.tryParse(v) ?? 0;
                            onChanged({...data, 'kg_attuali': kg, 'capacita_kg': kg});
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: onRemove),
          ],
        ),
      ),
    );
  }
}

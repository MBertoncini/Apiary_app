import 'package:flutter/material.dart';
import '../../../constants/api_constants.dart';
import '../../../models/maturatore.dart';
import '../../../models/preferenza_maturazione.dart';
import '../../../services/api_service.dart';

class AggiungiMaturatoreSheet extends StatefulWidget {
  final ApiService apiService;
  final Maturatore? existing;

  const AggiungiMaturatoreSheet({Key? key, required this.apiService, this.existing}) : super(key: key);

  @override
  State<AggiungiMaturatoreSheet> createState() => _AggiungiMaturatoreSheetState();
}

class _AggiungiMaturatoreSheetState extends State<AggiungiMaturatoreSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _tipoMieleCtrl = TextEditingController();
  final _capacitaCtrl = TextEditingController();
  final _kgCtrl = TextEditingController();
  final _giorniCtrl = TextEditingController();
  DateTime _dataInizio = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nomeCtrl.text = e.nome;
      _tipoMieleCtrl.text = e.tipoMiele;
      _capacitaCtrl.text = e.capacitaKg.toString();
      _kgCtrl.text = e.kgAttuali.toString();
      _giorniCtrl.text = e.giorniMaturazione.toString();
      _dataInizio = DateTime.tryParse(e.dataInizio) ?? DateTime.now();
    } else {
      _giorniCtrl.text = '21';
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose(); _tipoMieleCtrl.dispose(); _capacitaCtrl.dispose();
    _kgCtrl.dispose(); _giorniCtrl.dispose();
    super.dispose();
  }

  void _onTipoMieleChanged(String val) {
    final giorni = PreferenzaMaturazione.defaultForTipo(val);
    _giorniCtrl.text = giorni.toString();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = {
        'nome': _nomeCtrl.text.trim(),
        'tipo_miele': _tipoMieleCtrl.text.trim(),
        'capacita_kg': double.parse(_capacitaCtrl.text),
        'kg_attuali': double.parse(_kgCtrl.text),
        'giorni_maturazione': int.parse(_giorniCtrl.text),
        'data_inizio': _dataInizio.toIso8601String().split('T')[0],
        'stato': 'in_maturazione',
      };
      if (widget.existing != null) {
        await widget.apiService.patch('${ApiConstants.maturatoriUrl}${widget.existing!.id}/', body);
      } else {
        await widget.apiService.post(ApiConstants.maturatoriUrl, body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'Nuovo Maturatore' : 'Modifica Maturatore',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome (es. Maturatore 200L)', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tipoMieleCtrl,
              decoration: const InputDecoration(labelText: 'Tipo miele', border: OutlineInputBorder()),
              onChanged: _onTipoMieleChanged,
              validator: (v) => v == null || v.isEmpty ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _capacitaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Capacità (kg)', border: OutlineInputBorder(), suffixText: 'kg'),
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Numero non valido' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _kgCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Kg attuali', border: OutlineInputBorder(), suffixText: 'kg'),
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Numero non valido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _giorniCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giorni maturazione',
                      border: OutlineInputBorder(),
                      suffixText: 'gg',
                      helperText: 'Auto da tipo miele',
                    ),
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Numero non valido' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dataInizio,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) setState(() => _dataInizio = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data inizio', border: OutlineInputBorder()),
                      child: Text(
                        '${_dataInizio.day.toString().padLeft(2, '0')}/${_dataInizio.month.toString().padLeft(2, '0')}/${_dataInizio.year}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.existing == null ? 'Aggiungi' : 'Salva'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

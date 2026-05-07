import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/invasettamento.dart';
import '../../../services/language_service.dart';

class LottoVasettiSection extends StatefulWidget {
  final String tipoMiele;
  final List<Invasettamento> invasettamenti;
  /// [selected] = items per il form vendita: [{tipo_miele, formato_vasetto, quantita}].
  /// La distribuzione FIFO sui lotti avviene server-side via
  /// POST /api/v1/invasettamenti/vendi/, quindi non servono deductions.
  final void Function(List<Map<String, dynamic>> selected) onSell;

  const LottoVasettiSection({
    Key? key,
    required this.tipoMiele,
    required this.invasettamenti,
    required this.onSell,
  }) : super(key: key);

  @override
  State<LottoVasettiSection> createState() => _LottoVasettiSectionState();
}

class _LottoVasettiSectionState extends State<LottoVasettiSection> {
  // formato -> qty selected
  final Map<int, int> _selected = {};

  int get _totalSelected => _selected.values.fold(0, (s, v) => s + v);

  // Group by formato — somma vasetti DISPONIBILI (non venduti).
  // I venduti restano nel DB per lo storico annuale, ma non si possono
  // ri-vendere e non si vedono più in cantina.
  Map<int, int> get _vasettiPerFormato {
    final map = <int, int>{};
    for (final inv in widget.invasettamenti) {
      map[inv.formatoVasetto] =
          (map[inv.formatoVasetto] ?? 0) + inv.vasettiDisponibili;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final strings = Provider.of<LanguageService>(context, listen: false).strings;
    final byFormato = _vasettiPerFormato;
    final totalVasetti = byFormato.values.fold(0, (s, v) => s + v);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.tipoMiele,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                strings.lottoVasettiCount(totalVasetti),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: byFormato.entries.map((e) {
              final formato = e.key;
              final disponibili = e.value;
              final selQty = _selected[formato] ?? 0;
              return _VasettoGroup(
                formatoG: formato,
                disponibili: disponibili,
                selected: selQty,
                onChanged: (v) => setState(() => _selected[formato] = v),
              );
            }).toList(),
          ),
          if (_totalSelected > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _onVendi,
                icon: const Icon(Icons.shopping_cart, size: 16),
                label: Text(strings.lottoVasettiiBtnVendi(_totalSelected)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onVendi() {
    final items = _selected.entries
        .where((e) => e.value > 0)
        .map((e) => {'formato_vasetto': e.key, 'quantita': e.value, 'tipo_miele': widget.tipoMiele})
        .toList();
    widget.onSell(items);
    setState(() => _selected.clear());
  }
}

class _VasettoGroup extends StatelessWidget {
  final int formatoG;
  final int disponibili;
  final int selected;
  final ValueChanged<int> onChanged;

  const _VasettoGroup({
    required this.formatoG,
    required this.disponibili,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final strings = Provider.of<LanguageService>(context, listen: false).strings;
    final isSelected = selected > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.amber.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? Colors.amber.shade700 : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🫙 ${formatoG}g', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(strings.lottoVasettiDisponibili(disponibili), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _btn(Icons.remove, selected > 0 ? () => onChanged(selected - 1) : null),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('$selected',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.amber.shade800 : Colors.grey)),
              ),
              _btn(Icons.add, selected < disponibili ? () => onChanged(selected + 1) : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 18, color: onTap == null ? Colors.grey.shade300 : Colors.amber.shade700),
      ),
    );
  }
}

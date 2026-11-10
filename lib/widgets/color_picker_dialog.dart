import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

/// Converte un colore in stringa `#RRGGBB` (maiuscolo, senza alpha).
String colorToHex(Color c) {
  final rgb = c.value & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Converte `#RRGGBB` (o `RRGGBB`) in Color; null se il formato non è valido.
Color? colorFromHexOrNull(String hex) {
  final clean = hex.trim().replaceAll('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(clean)) return null;
  return Color(int.parse('FF$clean', radix: 16));
}

/// Mostra un selettore colore (tonalità / saturazione / luminosità + codice
/// esadecimale). Restituisce `#RRGGBB`, oppure null se l'utente annulla.
Future<String?> showColorPickerDialog(
  BuildContext context, {
  required String initialHex,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ColorPickerDialog(initialHex: initialHex),
  );
}

class _ColorPickerDialog extends StatefulWidget {
  final String initialHex;
  const _ColorPickerDialog({required this.initialHex});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    final initial =
        colorFromHexOrNull(widget.initialHex) ?? const Color(0xFF6C757D);
    _hsv = HSVColor.fromColor(initial);
    _hexController = TextEditingController(text: colorToHex(initial));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _setHsv(HSVColor hsv) {
    setState(() {
      _hsv = hsv;
      _hexController.text = colorToHex(hsv.toColor());
    });
  }

  void _onHexChanged(String value) {
    final c = colorFromHexOrNull(value);
    if (c != null) {
      // Non riscrive il campo: l'utente sta digitando.
      setState(() => _hsv = HSVColor.fromColor(c));
    }
  }

  Widget _slider({
    required String label,
    required double value,
    required double max,
    required List<Color> gradient,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade400),
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 12,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: Colors.white,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(value: value, max: max, onChanged: onChanged),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    final color = _hsv.toColor();
    final pureHue = HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor();

    return AlertDialog(
      title: Text(s.colorPickerTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            _slider(
              label: s.colorPickerHue,
              value: _hsv.hue,
              max: 360,
              gradient: [
                for (double h = 0; h <= 360; h += 60)
                  HSVColor.fromAHSV(1, h, 1, 1).toColor(),
              ],
              onChanged: (v) => _setHsv(_hsv.withHue(v)),
            ),
            const SizedBox(height: 8),
            _slider(
              label: s.colorPickerSaturation,
              value: _hsv.saturation,
              max: 1,
              gradient: [Colors.white, pureHue],
              onChanged: (v) => _setHsv(_hsv.withSaturation(v)),
            ),
            const SizedBox(height: 8),
            _slider(
              label: s.colorPickerBrightness,
              value: _hsv.value,
              max: 1,
              gradient: [Colors.black, pureHue],
              onChanged: (v) => _setHsv(_hsv.withValue(v)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hexController,
              decoration: InputDecoration(
                labelText: s.colorPickerHex,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              maxLength: 7,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
              ],
              onChanged: _onHexChanged,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.btnCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(colorToHex(color)),
          child: Text(s.btnConfirm),
        ),
      ],
    );
  }
}

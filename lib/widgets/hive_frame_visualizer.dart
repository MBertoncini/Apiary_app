import 'dart:convert';
import 'package:flutter/material.dart';

/// Visualizzazione grafica dei telaini dell'arnia + indicatore regina + allarme celle reali.
class HiveFrameVisualizer extends StatelessWidget {
  /// Dati grezzi dell'ultimo controllo (from ControlloArniaDao).
  final Map<String, dynamic>? controllo;

  const HiveFrameVisualizer({Key? key, this.controllo}) : super(key: key);

  // ─── colori per tipo telaino ───────────────────────────────────
  static const Map<String, Color> _colors = {
    'covata':    Color(0xFFFF8C42), // arancione caldo
    'scorte':    Color(0xFFFFD166), // giallo miele
    'diaframma': Color(0xFF9E9E9E), // grigio
    'nutritore': Color(0xFF74B3CE), // azzurro
    'vuoto':     Color(0xFFEEEEEE), // grigio chiaro
  };

  static const Map<String, String> _labels = {
    'covata':    'Covata',
    'scorte':    'Scorte',
    'diaframma': 'Diaframma',
    'nutritore': 'Nutritore',
    'vuoto':     'Vuoto',
  };

  static Color _colorFor(String type) => _colors[type] ?? const Color(0xFFEEEEEE);

  // ─── legenda statica (chiamata una volta sola per gruppo) ──────
  static Widget legend() {
    const types = ['covata', 'scorte', 'diaframma', 'nutritore', 'vuoto'];
    return Wrap(
      spacing: 10,
      runSpacing: 2,
      children: types.map((t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: _colors[t],
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.black26, width: 0.5),
            ),
          ),
          const SizedBox(width: 3),
          Text(_labels[t]!, style: const TextStyle(fontSize: 10)),
        ],
      )).toList(),
    );
  }

  // ─── costruisce la lista di 10 slot telaini ────────────────────
  List<String> _buildFrameConfig() {
    if (controllo == null) return List.filled(10, 'vuoto');

    // Usa telaini_config se disponibile (JSON array da controllo_form_screen)
    final raw = controllo!['telaini_config'];
    if (raw != null && raw.toString().isNotEmpty) {
      try {
        final decoded = json.decode(raw.toString()) as List;
        if (decoded.length == 10) return List<String>.from(decoded);
      } catch (_) {}
    }

    // Fallback: genera dalla coppia scorte+covata
    final scorte = (controllo!['telaini_scorte'] as num?)?.toInt() ?? 0;
    final covata = (controllo!['telaini_covata'] as num?)?.toInt() ?? 0;
    final config = List.filled(10, 'vuoto');
    // covata al centro
    int start = ((10 - covata) / 2).floor().clamp(0, 9);
    for (int i = 0; i < covata && start + i < 10; i++) {
      config[start + i] = 'covata';
    }
    // scorte ai lati
    int left = scorte;
    for (int i = 0; i < 10 && left > 0; i++) {
      if (config[i] == 'vuoto') { config[i] = 'scorte'; left--; }
    }
    for (int i = 9; i >= 0 && left > 0; i--) {
      if (config[i] == 'vuoto') { config[i] = 'scorte'; left--; }
    }
    return config;
  }

  @override
  Widget build(BuildContext context) {
    if (controllo == null) {
      return Text(
        'Nessun controllo registrato',
        style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
      );
    }

    final frames = _buildFrameConfig();
    final presenzaRegina = controllo!['presenza_regina'] == true;
    final celleReali    = controllo!['celle_reali']    == true;
    final numeroCelle   = (controllo!['numero_celle_reali'] as num?)?.toInt() ?? 0;
    final dataControllo = controllo!['data'] as String?;

    return Row(
      children: [
        // ── 10 slot telaini ────────────────────────────────────────
        Expanded(
          child: Row(
            children: List.generate(10, (i) => Expanded(
              child: Container(
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                decoration: BoxDecoration(
                  color: _colorFor(frames[i]),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.black12, width: 0.5),
                ),
              ),
            )),
          ),
        ),
        const SizedBox(width: 6),
        // ── icona regina ───────────────────────────────────────────
        Tooltip(
          message: presenzaRegina ? 'Regina presente' : 'Regina assente',
          child: Text(
            '♛',
            style: TextStyle(
              fontSize: 17,
              color: presenzaRegina ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ),
        // ── allerta celle reali ────────────────────────────────────
        if (celleReali) ...[
          const SizedBox(width: 4),
          _QueenCellAlert(dataControllo: dataControllo, numeroCelle: numeroCelle),
        ],
      ],
    );
  }
}

// ─── badge di allerta celle reali ─────────────────────────────────────────
class _QueenCellAlert extends StatelessWidget {
  final String? dataControllo;
  final int numeroCelle;

  const _QueenCellAlert({required this.dataControllo, required this.numeroCelle});

  @override
  Widget build(BuildContext context) {
    int daysSince = 0;
    if (dataControllo != null) {
      try {
        daysSince = DateTime.now().difference(DateTime.parse(dataControllo!)).inDays;
      } catch (_) {}
    }

    // Urgenza crescente: le celle reali emergono ~16 giorni dopo la deposizione.
    // 0-4 gg → bassa (giallo), 5-9 gg → media (arancio),
    // 10-13 gg → alta (rosso-arancio), 14+ gg → critica (rosso).
    final Color color;
    final double fontSize;
    final String mark;

    if (daysSince < 5) {
      color = Colors.amber.shade700;  fontSize = 11; mark = '!';
    } else if (daysSince < 10) {
      color = Colors.orange.shade800; fontSize = 12; mark = '!!';
    } else if (daysSince < 14) {
      color = Colors.deepOrange.shade800; fontSize = 13; mark = '!!!';
    } else {
      color = Colors.red.shade800;    fontSize = 14; mark = '!!!';
    }

    return Tooltip(
      message: 'Celle reali${numeroCelle > 0 ? ": $numeroCelle" : ""} — rilevate $daysSince giorni fa',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mark,
              style: TextStyle(
                color: color, fontWeight: FontWeight.bold,
                fontSize: fontSize, height: 1.1,
              ),
            ),
            if (numeroCelle > 0) ...[
              const SizedBox(width: 2),
              Text(
                '$numeroCelle',
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

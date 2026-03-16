import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RisultatoQueryWidget extends StatelessWidget {
  final Map<String, dynamic> result;
  final String visualizzazione;

  const RisultatoQueryWidget({
    super.key,
    required this.result,
    this.visualizzazione = 'table',
  });

  @override
  Widget build(BuildContext context) {
    final dati = result['dati'] as Map<String, dynamic>?;
    final colonne = result['colonne'] as List?;
    final righe = result['righe'] as List?;
    final totale = result['totale_righe'] ?? 0;

    // Risultato da NL query (ha colonne e righe dirette)
    if (colonne != null && righe != null) {
      return _buildTable(List<String>.from(colonne), righe);
    }

    // Risultato da query builder (ha dati.labels e dati.valori)
    if (dati != null) {
      final labels = List<String>.from(dati['labels'] ?? []);
      final valori = List<double>.from((dati['valori'] as List? ?? []).map((v) => (v as num).toDouble()));
      final colonneTabella = dati['colonne'] as List?;
      final righeTabella = dati['righe'] as List?;

      if (visualizzazione == 'table' && colonneTabella != null && righeTabella != null) {
        return Column(
          children: [
            _buildTable(List<String>.from(colonneTabella), righeTabella),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('$totale righe', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
        );
      }

      if (labels.isEmpty || valori.isEmpty) {
        return const Text('Nessun dato disponibile', style: TextStyle(color: Colors.grey));
      }

      if (visualizzazione == 'bar_chart') return _buildBarChart(labels, valori, result['titolo'] ?? '');
      if (visualizzazione == 'line_chart') return _buildLineChart(labels, valori);
      if (visualizzazione == 'pie_chart') return _buildPieChart(labels, valori);
    }

    return const Text('Nessun risultato', style: TextStyle(color: Colors.grey));
  }

  Widget _buildTable(List<String> colonne, List righe) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.all(const Color(0xFF1A1A2E)),
        columns: colonne.map((c) => DataColumn(
          label: Text(c, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        )).toList(),
        rows: righe.take(50).map((row) {
          final values = row is Map ? row.values.toList() : (row as List);
          return DataRow(
            cells: values.map((v) => DataCell(Text('${v ?? ''}', style: const TextStyle(fontSize: 12)))).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart(List<String> labels, List<double> valori, String titolo) {
    final maxY = valori.fold(0.0, (m, v) => v > m ? v : m) * 1.2;
    return SizedBox(
      height: 200,
      child: BarChart(BarChartData(
        maxY: maxY > 0 ? maxY : 10,
        barGroups: valori.asMap().entries.map((e) => BarChartGroupData(
          x: e.key,
          barRods: [BarChartRodData(toY: e.value, color: const Color(0xFFD4A017), width: 20, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))],
        )).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= labels.length) return const SizedBox();
              return Text(labels[i].length > 8 ? labels[i].substring(0, 8) : labels[i], style: const TextStyle(fontSize: 9));
            },
          )),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
      )),
    );
  }

  Widget _buildLineChart(List<String> labels, List<double> valori) {
    return SizedBox(
      height: 200,
      child: LineChart(LineChartData(
        lineBarsData: [LineChartBarData(
          spots: valori.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
          isCurved: true,
          color: const Color(0xFFD4A017),
          dotData: const FlDotData(show: false),
        )],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: (labels.length / 4).ceilToDouble(), getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox();
            return Text(labels[i].substring(labels[i].length > 7 ? labels[i].length - 5 : 0), style: const TextStyle(fontSize: 9));
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
      )),
    );
  }

  Widget _buildPieChart(List<String> labels, List<double> valori) {
    const colors = [Color(0xFFD4A017), Colors.blue, Colors.green, Colors.red, Colors.purple, Colors.teal];
    return SizedBox(
      height: 200,
      child: PieChart(PieChartData(
        sections: valori.asMap().entries.map((e) => PieChartSectionData(
          value: e.value,
          color: colors[e.key % colors.length],
          title: labels[e.key].length > 8 ? '${labels[e.key].substring(0, 7)}…' : labels[e.key],
          titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          radius: 70,
        )).toList(),
        sectionsSpace: 2,
      )),
    );
  }
}

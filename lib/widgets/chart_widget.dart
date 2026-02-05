// widgets/chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../constants/theme_constants.dart';

class ChartWidget extends StatelessWidget {
  final Map<String, dynamic> chartData;
  
  const ChartWidget({Key? key, required this.chartData}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final chartType = chartData['chart_type'] ?? 'line';
    final title = chartData['title'] ?? 'Grafico';
    final data = chartData['data'] ?? [];
    
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Nessun dato disponibile per il grafico',
          style: TextStyle(color: ThemeConstants.textSecondaryColor),
        ),
      );
    }
    
    switch (chartType) {
      case 'line':
        return _buildLineChart(chartData);
      case 'bar':
        return _buildBarChart(chartData);
      default:
        return Center(
          child: Text(
            'Tipo di grafico non supportato: $chartType',
            style: TextStyle(color: ThemeConstants.textSecondaryColor),
          ),
        );
    }
  }
  
  Widget _buildLineChart(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Grafico';
    final xAxisLabel = data['x_axis'] ?? 'X';
    final yAxisLabel = data['y_axis'] ?? 'Y';
    final chartData = data['data'] ?? [];
    final series = data['series'] ?? [];
    
    if (chartData.isEmpty || series.isEmpty) {
      return Center(child: Text('Dati insufficienti per il grafico'));
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                          // Se abbiamo date nel dataset, formattale
                          if (chartData[value.toInt()].containsKey('date')) {
                            final date = DateTime.parse(chartData[value.toInt()]['date']);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('dd/MM').format(date),
                                style: TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          
                          // Altrimenti usa l'indice come etichetta
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                    axisNameWidget: Text(xAxisLabel),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                    axisNameWidget: Text(yAxisLabel),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: _createLineBarsData(chartData, series),
              ),
            ),
          ),
        ),
        // Legenda
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              for (var serie in series)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _hexToColor(serie['color'] ?? '#000000'),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      serie['name'] ?? '',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  List<LineChartBarData> _createLineBarsData(List<dynamic> chartData, List<dynamic> series) {
    List<LineChartBarData> result = [];
    
    for (var serie in series) {
      final dataKey = serie['data_key'];
      final color = _hexToColor(serie['color'] ?? '#000000');
      
      List<FlSpot> spots = [];
      for (int i = 0; i < chartData.length; i++) {
        if (chartData[i].containsKey(dataKey) && chartData[i][dataKey] != null) {
          spots.add(FlSpot(i.toDouble(), chartData[i][dataKey].toDouble()));
        }
      }
      
      if (spots.isNotEmpty) {
        result.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    }
    
    return result;
  }
  
  Widget _buildBarChart(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Grafico';
    final xAxisLabel = data['x_axis'] ?? 'X';
    final yAxisLabel = data['y_axis'] ?? 'Y';
    final chartData = data['data'] ?? [];
    
    if (chartData.isEmpty) {
      return Center(child: Text('Dati insufficienti per il grafico'));
    }
    
    // Determina la chiave principale (x) e la chiave del valore (y)
    String xKey = chartData.first.keys.where((k) => 
      k != 'health_score' && k != 'efficacia_perc' && 
      k != 'totale' && k != 'efficaci' && k != 'total').first;
    
    String yKey = chartData.first.containsKey('health_score') ? 'health_score' : 
                 chartData.first.containsKey('efficacia_perc') ? 'efficacia_perc' : 'total';
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              chartData[value.toInt()][xKey].toString(),
                              style: TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                    axisNameWidget: Text(xAxisLabel),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                    axisNameWidget: Text(yAxisLabel),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                barGroups: _createBarGroups(chartData, xKey, yKey),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  List<BarChartGroupData> _createBarGroups(List<dynamic> chartData, String xKey, String yKey) {
    List<BarChartGroupData> result = [];
    
    final baseColor = ThemeConstants.primaryColor;
    
    for (int i = 0; i < chartData.length; i++) {
      if (chartData[i].containsKey(yKey) && chartData[i][yKey] != null) {
        // Determina il colore in base al valore
        Color barColor;
        
        double value = chartData[i][yKey].toDouble();
        
        // Per i grafici di "salute", usiamo una scala di colori
        if (yKey == 'health_score') {
          if (value < 30) barColor = Colors.red;
          else if (value < 60) barColor = Colors.orange;
          else barColor = Colors.green;
        } else {
          barColor = baseColor;
        }
        
        result.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: value,
                color: barColor,
                width: 20,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        );
      }
    }
    
    return result;
  }
  
  // Helper per convertire colori esadecimali in Color
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/meteo_service.dart';
import '../services/language_service.dart';
import '../constants/theme_constants.dart';

class WeatherWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;

  const WeatherWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  }) : super(key: key);

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final _meteoService = MeteoService();
  MeteoData? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final data = await _meteoService.fetchMeteo(widget.latitude, widget.longitude);
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _error = 'error';
        _isLoading = false;
      });
    } else {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final s = Provider.of<LanguageService>(context, listen: false).strings;

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              Text(s.weatherErrorNoData, textAlign: TextAlign.center,
                  style: TextStyle(color: ThemeConstants.textSecondaryColor)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: Text(s.btnRetry),
              ),
            ],
          ),
        ),
      );
    }

    final cur = _data!.current;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Meteo attuale ──────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Localizzazione e orario aggiornamento
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14,
                        color: ThemeConstants.textSecondaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.locationName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ThemeConstants.textSecondaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      s.weatherUpdatedAt(DateFormat('HH:mm').format(cur.time)),
                      style: const TextStyle(
                        fontSize: 12,
                        color: ThemeConstants.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Icona + temperatura principale
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _iconColor(cur.weatherCode, isDay: cur.isDay).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _weatherIcon(cur.weatherCode, isDay: cur.isDay),
                        size: 44,
                        color: _iconColor(cur.weatherCode, isDay: cur.isDay),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cur.temperature.toStringAsFixed(1)}°C',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            MeteoService.descriptionFromCode(cur.weatherCode, isDay: cur.isDay),
                            style: const TextStyle(fontSize: 15),
                          ),
                          Text(
                            s.weatherFeelsLike(cur.apparentTemperature.toStringAsFixed(1)),
                            style: const TextStyle(
                              fontSize: 12,
                              color: ThemeConstants.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Dettagli: umidità, vento, precipitazioni, pressione
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _detailCol(s.weatherHumidity, '${cur.humidity.toStringAsFixed(0)}%',
                        Icons.water_drop, Colors.blue),
                    _detailCol(s.weatherWind,
                        '${cur.windSpeed.toStringAsFixed(1)} km/h',
                        Icons.air, Colors.blueGrey),
                    _detailCol(s.weatherRain,
                        '${cur.precipitation.toStringAsFixed(1)} mm',
                        Icons.umbrella, Colors.indigo),
                    _detailCol(s.weatherPressure,
                        '${cur.pressure.toStringAsFixed(0)} hPa',
                        Icons.compress, Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Previsioni 7 giorni ────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.weatherForecast7Days, style: ThemeConstants.subheadingStyle),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _data!.daily.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final day = _data!.daily[i];
                      final isToday = i == 0;
                      return Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isToday
                              ? ThemeConstants.primaryColor.withOpacity(0.15)
                              : Colors.blue.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: isToday
                              ? Border.all(
                                  color: ThemeConstants.primaryColor
                                      .withOpacity(0.4))
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              isToday
                                  ? s.weatherToday
                                  : s.weatherDayNamesShort[(day.date.weekday - 1) % 7],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isToday
                                    ? ThemeConstants.primaryColor
                                    : ThemeConstants.textPrimaryColor,
                              ),
                            ),
                            Icon(
                              _weatherIcon(day.weatherCode),
                              size: 26,
                              color: _iconColor(day.weatherCode),
                            ),
                            Text(
                              '${day.tempMax.toStringAsFixed(0)}°',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '${day.tempMin.toStringAsFixed(0)}°',
                              style: const TextStyle(
                                fontSize: 12,
                                color: ThemeConstants.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailCol(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: ThemeConstants.textSecondaryColor)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  /// Icona Material corrispondente al codice WMO
  /// [isDay] = false → per i codici sereni/poco nuvolosi mostra luna invece del sole
  IconData _weatherIcon(int code, {bool isDay = true}) {
    if (code == 0) return isDay ? Icons.wb_sunny : Icons.nightlight_round;
    if (code == 1) return isDay ? Icons.wb_sunny : Icons.nightlight_round;
    if (code == 2) return isDay ? Icons.wb_cloudy : Icons.cloud_queue;
    if (code == 3) return Icons.cloud;
    if (code == 45 || code == 48) return Icons.blur_on;
    if (code >= 51 && code <= 57) return Icons.grain;
    if (code >= 61 && code <= 67) return Icons.water_drop;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 80 && code <= 82) return Icons.water_drop;
    if (code >= 85 && code <= 86) return Icons.ac_unit;
    if (code >= 95) return Icons.thunderstorm;
    return isDay ? Icons.wb_sunny : Icons.nightlight_round;
  }

  /// Colore icona per il codice WMO
  Color _iconColor(int code, {bool isDay = true}) {
    if (code == 0 || code == 1) return isDay ? Colors.orange : Colors.indigo.shade300;
    if (code == 2 || code == 3) return Colors.blueGrey;
    if (code == 45 || code == 48) return Colors.grey;
    if (code >= 51 && code <= 67) return Colors.blue;
    if (code >= 71 && code <= 77) return Colors.lightBlue;
    if (code >= 80 && code <= 82) return Colors.blue.shade700;
    if (code >= 95) return Colors.deepPurple;
    return Colors.grey;
  }
}

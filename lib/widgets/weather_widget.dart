import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weather/weather.dart';
import '../services/sensor_service.dart';
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
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  late SensorService _sensorService;
  Weather? _currentWeather;
  List<Weather> _forecast = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _sensorService = SensorService();
    _loadWeatherData();
  }
  
  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Ottieni meteo attuale
      final weather = await _sensorService.fetchWeatherData(
        widget.latitude,
        widget.longitude,
      );
      
      if (weather != null) {
        setState(() {
          _currentWeather = weather;
        });
        
        // Ottieni previsioni
        final forecast = await _sensorService.fetchForecast(
          widget.latitude,
          widget.longitude,
        );
        
        setState(() {
          _forecast = forecast;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Impossibile ottenere i dati meteo';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              TextButton.icon(
                icon: Icon(Icons.refresh),
                label: Text('Riprova'),
                onPressed: _loadWeatherData,
              ),
            ],
          ),
        ),
      );
    }
    
    if (_currentWeather == null) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Text('Nessun dato meteo disponibile'),
        ),
      );
    }
    
    return Column(
      children: [
        // Meteo attuale
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: ThemeConstants.textSecondaryColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      widget.locationName,
                      style: TextStyle(
                        fontSize: 14,
                        color: ThemeConstants.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icona meteo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _getWeatherIcon(_currentWeather!.weatherIcon ?? ''),
                    ),
                    SizedBox(width: 16),
                    
                    // Dati meteo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_currentWeather!.temperature?.celsius?.toStringAsFixed(1) ?? "N/A"}°C',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _currentWeather!.weatherDescription ?? 'N/A',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Aggiornato: ${DateFormat('HH:mm').format(_currentWeather!.date ?? DateTime.now())}',
                            style: TextStyle(
                              fontSize: 12,
                              color: ThemeConstants.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 8),
                
                // Dettagli
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailColumn(
                      'Umidità',
                      '${_currentWeather!.humidity?.toStringAsFixed(0) ?? "N/A"}%',
                      Icons.water_drop,
                      Colors.blue,
                    ),
                    _buildDetailColumn(
                      'Vento',
                      '${_currentWeather!.windSpeed?.toStringAsFixed(1) ?? "N/A"} km/h',
                      Icons.air,
                      Colors.blueGrey,
                    ),
                    _buildDetailColumn(
                      'Pressione',
                      '${_currentWeather!.pressure?.toStringAsFixed(0) ?? "N/A"} hPa',
                      Icons.compress,
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Previsioni
        if (_forecast.isNotEmpty)
          Card(
            margin: EdgeInsets.only(top: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Previsioni prossimi giorni',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _buildForecastItems(),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildDetailColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: ThemeConstants.textSecondaryColor,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  List<Widget> _buildForecastItems() {
    final uniqueDates = <String>{};
    final dailyForecasts = <Weather>[];
    
    // Raggruppa previsioni per giorno
    for (var weather in _forecast) {
      final date = DateFormat('yyyy-MM-dd').format(weather.date!);
      if (!uniqueDates.contains(date)) {
        uniqueDates.add(date);
        dailyForecasts.add(weather);
      }
    }
    
    // Costruisci items di previsione
    return dailyForecasts.map((weather) {
      return Container(
        margin: EdgeInsets.only(right: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              DateFormat('E dd/MM').format(weather.date!),
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _getWeatherIcon(weather.weatherIcon ?? '', size: 32),
            SizedBox(height: 8),
            Text('${weather.temperature?.celsius?.toStringAsFixed(1) ?? "N/A"}°C'),
            SizedBox(height: 4),
            Text(
              '${weather.tempMin?.celsius?.toStringAsFixed(0) ?? "N/A"}° | ${weather.tempMax?.celsius?.toStringAsFixed(0) ?? "N/A"}°',
              style: TextStyle(
                fontSize: 12,
                color: ThemeConstants.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
  
  Widget _getWeatherIcon(String iconCode, {double size = 48}) {
    // Mapping delle icone OpenWeatherMap a icone Material
    Map<String, IconData> iconMapping = {
      '01d': Icons.wb_sunny,          // cielo sereno (giorno)
      '01n': Icons.nightlight_round,  // cielo sereno (notte)
      '02d': Icons.wb_cloudy,         // poche nuvole (giorno)
      '02n': Icons.cloud_queue,       // poche nuvole (notte)
      '03d': Icons.cloud,             // nuvole sparse
      '03n': Icons.cloud,
      '04d': Icons.cloud,             // nuvole
      '04n': Icons.cloud,
      '09d': Icons.grain,             // pioggia leggera
      '09n': Icons.grain,
      '10d': Icons.beach_access,      // pioggia (giorno)
      '10n': Icons.beach_access,      // pioggia (notte)
      '11d': Icons.flash_on,          // temporale
      '11n': Icons.flash_on,
      '13d': Icons.ac_unit,           // neve
      '13n': Icons.ac_unit,
      '50d': Icons.blur_on,           // nebbia
      '50n': Icons.blur_on,
    };
    
    return Icon(
      iconMapping[iconCode] ?? Icons.wb_sunny,
      size: size,
      color: iconCode.startsWith('01') || iconCode.startsWith('02') 
          ? Colors.orange 
          : iconCode.startsWith('09') || iconCode.startsWith('10') || iconCode.startsWith('11')
              ? Colors.blue
              : iconCode.startsWith('13')
                  ? Colors.blueGrey
                  : Colors.grey,
    );
  }
}

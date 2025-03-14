import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:light/light.dart';
import 'package:weather/weather.dart';
import '../constants/app_constants.dart';

class SensorData {
  final double? temperature; // °C
  final double? humidity; // %
  final double? pressure; // hPa
  final double? light; // lux
  final double? anemometer; // km/h (vento)
  final double? precipitationRate; // mm/h (pioggia)
  final DateTime timestamp;
  
  SensorData({
    this.temperature,
    this.humidity,
    this.pressure,
    this.light,
    this.anemometer,
    this.precipitationRate,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'pressure': pressure,
      'light': light,
      'anemometer': anemometer,
      'precipitation_rate': precipitationRate,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  
  // Sensori integrati
  Light? _lightSensor;
  StreamSubscription? _lightSubscription;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  StreamSubscription? _userAccelerometerSubscription;
  
  // API meteo
  final WeatherFactory _weatherFactory = WeatherFactory(AppConstants.openWeatherMapApiKey);
  
  // Stream controller per dati combinati
  final _sensorDataController = StreamController<SensorData>.broadcast();
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  
  // Stato
  bool _isLightSensorAvailable = false;
  bool _isMonitoring = false;
  double? _currentLux;
  AccelerometerEvent? _currentAccelerometer;
  GyroscopeEvent? _currentGyroscope;
  UserAccelerometerEvent? _currentUserAccelerometer;
  Weather? _currentWeather;
  
  SensorService._internal();
  
  // Inizializzazione
  Future<void> init() async {
    try {
      _lightSensor = Light();
      _isLightSensorAvailable = true;
    } catch (e) {
      print('Light sensor not available: $e');
      _isLightSensorAvailable = false;
    }
  }
  
  // Avvia monitoraggio sensori
  Future<bool> startMonitoring() async {
    if (_isMonitoring) return true;
    
    try {
      // Sensore luce
      if (_isLightSensorAvailable) {
        _lightSubscription = _lightSensor!.lightSensorStream.listen((luxValue) {
          _currentLux = luxValue.toDouble();
          _emitSensorData();
        });
      }
      
      // Accelerometro
      _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
        _currentAccelerometer = event;
        _emitSensorData();
      });
      
      // Giroscopio
      _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
        _currentGyroscope = event;
        _emitSensorData();
      });
      
      // Accelerometro utente
      _userAccelerometerSubscription = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
        _currentUserAccelerometer = event;
        _emitSensorData();
      });
      
      _isMonitoring = true;
      return true;
    } catch (e) {
      print('Error starting sensor monitoring: $e');
      _stopAllSubscriptions();
      _isMonitoring = false;
      return false;
    }
  }
  
  // Ferma monitoraggio sensori
  void stopMonitoring() {
    _stopAllSubscriptions();
    _isMonitoring = false;
  }
  
  // Ferma tutte le sottoscrizioni
  void _stopAllSubscriptions() {
    _lightSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _userAccelerometerSubscription?.cancel();
    
    _lightSubscription = null;
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _userAccelerometerSubscription = null;
  }
  
  // Emetti dati sensori combinati
  void _emitSensorData() {
    // Estrai valori rilevanti
    double? temperature;
    double? humidity;
    double? pressure;
    
    // Ottieni dati meteo se disponibili
    if (_currentWeather != null) {
      temperature = _currentWeather!.temperature?.celsius;
      humidity = _currentWeather!.humidity;
      pressure = _currentWeather!.pressure;
    }
    
    // Crea oggetto dati
    final sensorData = SensorData(
      temperature: temperature,
      humidity: humidity,
      pressure: pressure,
      light: _currentLux,
      // Gli altri valori richiederebbero sensori esterni specializzati
      anemometer: null,
      precipitationRate: null,
    );
    
    // Emetti dati
    _sensorDataController.add(sensorData);
  }
  
  // Ottieni dati meteo attuali da API
  Future<Weather?> fetchWeatherData(double latitude, double longitude) async {
    try {
      final weather = await _weatherFactory.currentWeatherByLocation(
        latitude,
        longitude,
      );
      
      _currentWeather = weather;
      _emitSensorData();
      
      return weather;
    } catch (e) {
      print('Error fetching weather data: $e');
      return null;
    }
  }
  
  // Ottieni previsioni meteo
  Future<List<Weather>> fetchForecast(double latitude, double longitude, {int days = 5}) async {
    try {
      return await _weatherFactory.fiveDayForecastByLocation(
        latitude,
        longitude,
      );
    } catch (e) {
      print('Error fetching forecast: $e');
      return [];
    }
  }
  
  // Rilascia risorse
  void dispose() {
    _stopAllSubscriptions();
    _sensorDataController.close();
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
  StreamSubscription? _lightSubscription;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  StreamSubscription? _userAccelerometerSubscription;
  
  // Stream controller per dati combinati
  final _sensorDataController = StreamController<SensorData>.broadcast();
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  
  // Stato
  // ignore: unused_field
  bool _isLightSensorAvailable = false;
  bool _isMonitoring = false;
  double? _currentLux;
  // ignore: unused_field
  AccelerometerEvent? _currentAccelerometer;
  // ignore: unused_field
  GyroscopeEvent? _currentGyroscope;
  // ignore: unused_field
  UserAccelerometerEvent? _currentUserAccelerometer;
  
  SensorService._internal();
  
  // Inizializzazione
  Future<void> init() async {
    // Sensor initialization placeholder
  }

  // Avvia monitoraggio sensori
  Future<bool> startMonitoring() async {
    if (_isMonitoring) return true;

    try {
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
      debugPrint('Error starting sensor monitoring: $e');
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
    final sensorData = SensorData(
      light: _currentLux,
      anemometer: null,
      precipitationRate: null,
    );
    _sensorDataController.add(sensorData);
  }

  // Rilascia risorse
  void dispose() {
    _stopAllSubscriptions();
    _sensorDataController.close();
  }
}
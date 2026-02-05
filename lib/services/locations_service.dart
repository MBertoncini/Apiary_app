import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  final _locationController = StreamController<Position>.broadcast();
  
  Stream<Position> get locationStream => _locationController.stream;
  
  // Chiedi i permessi di localizzazione
  Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;
    
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    
    return status.isGranted;
  }
  
  // Verifica se la localizzazione è abilitata
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  // Ottieni la posizione corrente
  Future<Position?> getCurrentPosition() async {
    if (!await requestLocationPermission()) {
      return null;
    }
    
    if (!await isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return null;
    }
    
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }
  
  // Avvia il tracciamento continuo della posizione
  Future<bool> startLocationTracking() async {
    if (!await requestLocationPermission() || !await isLocationServiceEnabled()) {
      return false;
    }
    
    try {
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Aggiorna solo se l'utente si è spostato di almeno 10 metri
        ),
      ).listen((position) {
        _locationController.add(position);
      });
      
      return true;
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      return false;
    }
  }
  
  // Arresta il tracciamento della posizione
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
  
  // Calcola la distanza tra due punti (in metri)
  double calculateDistance(
    double startLatitude, double startLongitude,
    double endLatitude, double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude, startLongitude,
      endLatitude, endLongitude,
    );
  }
  
  // Verifica se una posizione è all'interno di un raggio (in metri)
  bool isWithinRadius(
    double centerLatitude, double centerLongitude,
    double pointLatitude, double pointLongitude,
    double radiusInMeters,
  ) {
    double distance = calculateDistance(
      centerLatitude, centerLongitude,
      pointLatitude, pointLongitude,
    );
    
    return distance <= radiusInMeters;
  }
  
  // Pulisci le risorse
  void dispose() {
    stopLocationTracking();
    _locationController.close();
  }
}
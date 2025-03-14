import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

// Provider per lo stato di connettività
final connectivityStateProvider = StateNotifierProvider<ConnectivityStateNotifier, ConnectivityState>((ref) {
  return ConnectivityStateNotifier();
});

class ConnectivityStateNotifier extends StateNotifier<ConnectivityState> {
  StreamSubscription? _connectivitySubscription;
  
  ConnectivityStateNotifier() : super(ConnectivityState.initial()) {
    _initConnectivity();
    _setupConnectionListener();
  }
  
  Future<void> _initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await Connectivity().checkConnectivity();
    } catch (e) {
      result = ConnectivityResult.none;
    }
    
    if (!mounted) return;
    
    _updateConnectionStatus(result);
  }
  
  void _setupConnectionListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  void _updateConnectionStatus(ConnectivityResult result) {
    final isConnected = result != ConnectivityResult.none;
    state = state.copyWith(
      connectionType: result,
      isConnected: isConnected,
      lastUpdated: DateTime.now(),
    );
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

// Stato di connettività
class ConnectivityState {
  final bool isConnected;
  final ConnectivityResult connectionType;
  final DateTime lastUpdated;
  
  ConnectivityState({
    required this.isConnected,
    required this.connectionType,
    required this.lastUpdated,
  });
  
  factory ConnectivityState.initial() {
    return ConnectivityState(
      isConnected: false,
      connectionType: ConnectivityResult.none,
      lastUpdated: DateTime.now(),
    );
  }
  
  ConnectivityState copyWith({
    bool? isConnected,
    ConnectivityResult? connectionType,
    DateTime? lastUpdated,
  }) {
    return ConnectivityState(
      isConnected: isConnected ?? this.isConnected,
      connectionType: connectionType ?? this.connectionType,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  String get connectionTypeString {
    switch (connectionType) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.none:
      default:
        return 'Offline';
    }
  }
}
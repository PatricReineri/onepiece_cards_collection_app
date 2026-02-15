import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

/// Service to monitor network connectivity
class ConnectionService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;

  bool get isOffline => _isOffline;

  ConnectionService() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    // Check initial state
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      if (kDebugMode) debugPrint('Connectivity check failed: $e');
    }

    // Listen to updates
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // Use the latest result if multiple (flutter 3.22+ returns List)
    // If any result is NOT none, we are connected.
    // However, connectivity_plus recently changed to return List<ConnectivityResult>.
    // Usually only one result is relevant.
    
    // Check if ANY of the results is mobile, wifi, ethernet, or vpn
    final hasConnection = results.any((result) => 
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn
    );

    // If NO connection type is found, we are offline
    final isNowOffline = !hasConnection;

    if (_isOffline != isNowOffline) {
      _isOffline = isNowOffline;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

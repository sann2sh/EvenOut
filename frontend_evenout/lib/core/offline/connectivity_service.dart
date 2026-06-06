import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a simple interface to check and stream network connectivity.
/// Uses `connectivity_plus` under the hood.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Returns `true` if the device currently has a network connection
  /// (Wi-Fi, mobile data, ethernet). Does NOT guarantee internet reachability.
  Future<bool> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  /// A broadcast stream that emits `true`/`false` whenever connectivity changes.
  Stream<bool> get isOnline {
    return _connectivity.onConnectivityChanged.map(_isConnected);
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

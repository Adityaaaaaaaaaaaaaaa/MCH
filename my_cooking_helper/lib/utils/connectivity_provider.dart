import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Internal cache
  bool _isOnline = true;
  List<ConnectivityResult> _lastResults = [];

  // Expose last known state
  bool get isOnline => _isOnline;
  List<ConnectivityResult> get lastResults => _lastResults;

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChange => _controller.stream;

  /// Initializes the connectivity listener and checks the current state.
  Future<void> init() async {
    final results = await _connectivity.checkConnectivity(); // Now a List
    _lastResults = results;
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    _controller.add(_isOnline);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _lastResults = results;
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
      }
    });
  }

  Future<bool> checkOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<ConnectivityResult> getCurrentConnectionType() async {
    final results = await _connectivity.checkConnectivity();
    return results.firstWhere(
      (r) => r != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );
  }

  Future<bool> isWifi() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  Future<bool> isMobile() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.mobile);
  }

  Future<bool> isOffline() async {
    final results = await _connectivity.checkConnectivity();
    return results.every((r) => r == ConnectivityResult.none);
  }

  void logStatus() {
    print('[Connectivity] isOnline: $_isOnline');
    print('[Connectivity] Current: $_lastResults');
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

//
// Riverpod Providers
//

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

/// Reactive online status: true = online, false = offline
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.read(connectivityServiceProvider);
  await service.init();
  yield* service.onStatusChange;
});

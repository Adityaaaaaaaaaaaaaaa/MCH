import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _initialized = false;
  bool _isOnline = true;
  List<ConnectivityResult> _lastResults = [];

  bool get isOnline => _isOnline;
  List<ConnectivityResult> get lastResults => _lastResults;

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChange => _controller.stream;

  Future<void> init() async {
    if (_initialized) return; // idempotent
    _initialized = true;

    final results = await _connectivity.checkConnectivity();
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
    return results.firstWhere((r) => r != ConnectivityResult.none,
        orElse: () => ConnectivityResult.none);
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

  void blueDebugPrint(String msg) {
    for (final line in msg.split('\n')) {
      // ignore: avoid_print
      print('\x1B[34m[Connectivity] $line\x1B[0m');
    }
  }

  void logStatus() {
    blueDebugPrint('isOnline: $_isOnline');
    blueDebugPrint('Current: $_lastResults');
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  service.init();                 // fire-and-forget; happens on first read
  ref.onDispose(service.dispose);
  return service;
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onStatusChange;  // stream only; no extra init here
});

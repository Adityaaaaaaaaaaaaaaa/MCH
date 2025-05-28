import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityProvider = StateProvider<bool>((ref) => true);

void listenToConnectivity(WidgetRef ref) {
  final connectivity = Connectivity();
  connectivity.onConnectivityChanged.listen((result) {
    print('\x1B[31mConnectivity changed: $result \x1B[0m');
    ref.read(connectivityProvider.notifier).state = result != ConnectivityResult.none;
  });
}

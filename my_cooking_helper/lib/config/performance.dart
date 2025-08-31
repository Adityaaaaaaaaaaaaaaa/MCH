import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

/// Global Navigator key (needed for precaching context)
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Background images to precache for the home screen
const List<String> kHomeBgAssets = [
  'assets/images/home/food_plate_1.png',
  'assets/images/home/food_plate_2.png',
  'assets/images/home/food_plate_3.png',
  'assets/images/home/food_plate_4.png',
  'assets/images/home/food_plate_5.png',
];

/// Runs at startup to apply system-level tweaks
Future<void> perfBootstrap() async {
  // 1) Smoother touch on variable refresh-rate screens (no-op if unsupported)
  try {
    GestureBinding.instance.resamplingEnabled = true;
  } catch (_) {}

  _setAdaptiveRefresh(high: true);

  // 2) Right-size global image cache for 4GB devices
  final cache = PaintingBinding.instance.imageCache;
  cache.maximumSize = 200;            // number of decoded images to keep
  cache.maximumSizeBytes = 120 << 20; // ~120MB

  // 3) (Optional) Hide frame banners in DEBUG ONLY — these are top-level vars.
  assert(() {
    debugPrintBeginFrameBanner = false;
    debugPrintEndFrameBanner = false;
    return true;
  }());

  // 4) Pre-warm a frame to reduce first-navigation hitch
  WidgetsBinding.instance.scheduleWarmUpFrame();

  // 5) Network: bump HTTP keep-alive/connection limits a bit
  HttpOverrides.global = _HttpTuningOverrides();
}

/// Lifecycle observer to clear/shrink caches when backgrounded
class PerfLifecycle with WidgetsBindingObserver {
  void attach() => WidgetsBinding.instance.addObserver(this);
  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      final cache = PaintingBinding.instance.imageCache;
      cache.clear();            // drop decoded images
      cache.clearLiveImages();  // drop strongly-held frames
      // Optionally shrink the cap while backgrounded (will grow again on resume)
      cache.maximumSize = 120;
      cache.maximumSizeBytes = 80 << 20; // ~80MB
    }
    if (state == AppLifecycleState.resumed) {
      // restore your normal cap from _perfBootstrap (200 / 120MB, etc.)
      final cache = PaintingBinding.instance.imageCache;
      cache.maximumSize = 200;
      cache.maximumSizeBytes = 120 << 20;
    }
  }
}

final perfObserver = PerfLifecycle();

/// Scroll behavior tweak
class TightScrollBehavior extends MaterialScrollBehavior {
  const TightScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();
}

/// Adaptive refresh rate (Android only)
Future<void> _setAdaptiveRefresh({bool high = true}) async {
  try {
    final modes = await FlutterDisplayMode.supported;
    if (modes.isEmpty) return;
    modes.sort((a, b) => b.refreshRate.compareTo(a.refreshRate));
    final best = modes.first;                         // highest Hz
    final native60 = modes.firstWhere(
      (m) => m.refreshRate.round() == 60, orElse: () => modes.last,
    );
    await FlutterDisplayMode.setPreferredMode(high ? best : native60);
  } catch (_) {}
}

/// HTTP connection tuning
class _HttpTuningOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final c = super.createHttpClient(context);
    c.autoUncompress = true;                         // prefer gzip/br when server supports
    c.maxConnectionsPerHost = 6;                     // avoid connection stampedes
    c.connectionTimeout = const Duration(seconds: 30);
    c.idleTimeout = const Duration(seconds: 30);     // only for idle pooled sockets
    return c;
  }
}

/// Precache home-screen background images
Future<void> precacheHomeImages() async {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return;

  // Target a safe logical width for decoding (adjust if your cards are bigger)
  final double logicalWidth = MediaQuery.of(ctx).size.width;     // full width
  final double devicePixelRatio = MediaQuery.of(ctx).devicePixelRatio;
  final int decodeWidth = (logicalWidth * devicePixelRatio).clamp(600, 1440).toInt();

  for (final path in kHomeBgAssets) {
    final provider = ResizeImage(AssetImage(path), width: decodeWidth);
    await precacheImage(provider, ctx);
  }
}

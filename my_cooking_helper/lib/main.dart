import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/firebase_options.dart';
import 'features/cravings/craving_recipe.dart';
import 'models/cravings.dart';
import 'models/recipe_detail.dart';
import 'theme/theme_provider.dart';  
import 'theme/app_theme.dart';
import 'features/smart_scan/scan_food.dart';
import 'features/smart_scan/scan_receipt.dart';
import 'features/smart_scan/smart_scan.dart';
import 'features/smart_scan/manual_input.dart';
import 'features/smart_scan/review_screen.dart';
import 'features/home/home.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/auth/sign_in_page.dart';
import 'features/preferences/preferences_flow.dart';
import 'features/splash/splash_screen.dart';
import 'features/settings/settings.dart'; 
import 'features/cook/recipe_page.dart';
import 'features/cook/cook.dart';
import 'features/history/recipe_history.dart';
import 'features/cook/recipe_search.dart';
import 'features/inventory/inventory.dart';
import 'features/history/recipe_favourites.dart';
import 'features/meal_planner/planner.dart';
import 'features/cravings/cravings.dart';

Future<void> _perfBootstrap() async {
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

final _perfObserver = PerfLifecycle();

class TightScrollBehavior extends MaterialScrollBehavior {
  const TightScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();
}

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

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

const List<String> kHomeBgAssets = [
  'assets/images/home/food_plate_1.png',
  'assets/images/home/food_plate_2.png',
  'assets/images/home/food_plate_3.png',
  'assets/images/home/food_plate_4.png',
  'assets/images/home/food_plate_5.png',
];

Future<void> _precacheHomeImages() async {
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


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _perfObserver.attach();
  await _perfBootstrap();                                // ⬅️ add this
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize();
  await dotenv.load(fileName: ".env");
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);
  debugPrint = (String? message, {int? wrapWidth}) {};   // keep if you like
  runApp(const ProviderScope(child: MyApp()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _precacheHomeImages();  // fire-and-forget
  });
}

final GoRouter _router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const OnboardingPage(), //3 page onboarding
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/preferences',
      builder: (context, state) => const PreferencesFlow(),
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const Settings(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const SmartScan(),
    ),
    GoRoute(
      path: '/scanFood',
      builder: (context, state) => const ScanFood(),
    ),
    GoRoute(
      path: '/scanReceipt',
      builder: (context, state) => const ScanReceipt(),
    ),
    GoRoute(
      path: '/reviewScreen',
      builder: (context, state) => const ReviewScreen(),
    ),
    GoRoute(
      path: '/manualInput',
      builder: (context, state) => const ManualInputScreen(),
    ),
    GoRoute(
      path: '/inventory', 
      builder: (context, state) => const InventoryPage()
    ),
    GoRoute(
      path: '/cook',
      builder: (context, state) => const CookScreen()
    ),
    GoRoute(
      path: '/searchRecipe',
      builder: (context, state) => const SearchRecipeScreen()
    ),
    GoRoute(
      path: '/recipePage',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is RecipeDetail) {
          // fallback for older navigation
          return RecipePage(recipe: extra, fromHistory: false);
        } else if (extra is Map<String, dynamic>) {
          return RecipePage(
            recipe: extra['recipe'] as RecipeDetail,
            fromHistory: extra['fromHistory'] == true,
          );
        } else {
          // error fallback
          return Scaffold(body: Center(child: Text('Invalid data')));
        }
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const RecipeHistoryPage(),
    ),
    GoRoute(
      path: '/favourites',
      builder: (context, state) => const RecipeFavouritesPage(),
    ),
    GoRoute(
      path: '/planner',
      builder: (context, state) => const PlannerScreen(),
    ),
    GoRoute(
      path: '/cravings',
      builder: (context, state) => const CravingsScreen(),
    ),
    GoRoute(
      path: '/cravingRecipe',
      builder: (ctx, state) {
        final extra = state.extra;

        // Back-compat: older callers pass the model directly
        if (extra is CravingRecipeModel) {
          return CravingRecipePage(recipe: extra);
        }

        // New path: callers pass a Map
        if (extra is Map) {
          // Ensure typed map to avoid _Map<String,Object> casting issues
          final m = Map<String, dynamic>.from(extra);

          final model = m['recipe'] as CravingRecipeModel;
          final fromHistory = (m['fromHistory'] == true);
          final recipeKey = m['recipeKey'] as String?;

          return CravingRecipePage(
            recipe: model,
            openedFromHistory: fromHistory,
            recipeKey: recipeKey,
          );
        }

        // Graceful fallback (helps during dev)
        throw ArgumentError('Invalid /cravingRecipe extra: ${state.extra}');
      },
    ),
  ],
);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          scrollBehavior: const TightScrollBehavior(),
          debugShowCheckedModeBanner: false,
          title: 'My Cooking Helper',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}

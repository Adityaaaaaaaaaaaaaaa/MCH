import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/firebase_options.dart';
import 'config/performance.dart';
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
import 'features/settings/settings.dart' as appsettings; 
import 'features/cook/recipe_page.dart';
import 'features/cook/cook.dart';
import 'features/history/recipe_history.dart';
import 'features/cook/recipe_search.dart';
import 'features/inventory/inventory.dart';
import 'features/history/recipe_favourites.dart';
import 'features/meal_planner/planner.dart';
import 'features/cravings/cravings.dart';
import 'features/cravings/craving_recipe.dart';
import 'features/shopping/shopping.dart';
import 'utils/adaptive_transition.dart';
import 'utils/snackbar.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  perfObserver.attach();
  await perfBootstrap();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  await GoogleSignIn.instance.initialize();
  await dotenv.load(fileName: ".env");
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);
  debugPrint = (String? message, {int? wrapWidth}) {};
  runApp(const ProviderScope(child: MyApp()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
    precacheHomeImages();  // fire-and-forget
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
      builder: (context, state) => const appsettings.Settings(),
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
    // GoRoute(
    //   path: '/recipePage',
    //   builder: (context, state) {
    //     final extra = state.extra;
    //     if (extra is RecipeDetail) {
    //       // fallback for older navigation
    //       return RecipePage(recipe: extra, fromHistory: false);
    //     } else if (extra is Map<String, dynamic>) {
    //       return RecipePage(
    //         recipe: extra['recipe'] as RecipeDetail,
    //         fromHistory: extra['fromHistory'] == true,
    //       );
    //     } else {
    //       // error fallback
    //       return Scaffold(body: Center(child: Text('Invalid data')));
    //     }
    //   },
    // ),
    GoRoute(
      path: '/recipePage',
      builder: (context, state) {
        final extra = state.extra;

        if (extra is RecipeDetail) {
          // Directly a RecipeDetail (from search, API, etc.)
          return RecipePage(recipe: extra, fromHistory: false);
        } 
        else if (extra is Map<String, dynamic>) {
          final recipeRaw = extra['recipe'];

          // Handle both RecipeDetail and Map<String,dynamic>
          final recipe = recipeRaw is RecipeDetail
              ? recipeRaw
              : RecipeDetail.fromJson(Map<String, dynamic>.from(recipeRaw));

          return RecipePage(
            recipe: recipe,
            fromHistory: extra['fromHistory'] == true,
          );
        } 
        else {
          // 🚑 Instead of error page → snackbar + safe fallback with delay
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            SnackbarUtils.show(
              context, 
              "Recipe not available, please try again!",
              duration: 750, 
              behavior: SnackBarBehavior.floating,
              icon: Icons.error_outline_rounded,
              iconColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
              backgroundColor: Colors.grey.withOpacity(0.5),
              width: 250.w,
            );

            // small delay so snackbar is noticeable before going back
            await Future.delayed(const Duration(milliseconds: 500));

            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });

          return const SizedBox.shrink(); // temporary widget until pop
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

        // 🚑 Safe fallback instead of throw
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          SnackbarUtils.show(
            ctx,
            "AI recipe not available, please try again!",
            duration: 750,
            behavior: SnackBarBehavior.floating,
            icon: Icons.error_outline_rounded,
            iconColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            backgroundColor: Colors.grey.withOpacity(0.5),
            width: 250,
          );

          // delay so snackbar shows before going back
          await Future.delayed(const Duration(milliseconds: 500));

          if (Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });

        return const SizedBox.shrink(); // temp widget until pop
      },
    ),
    GoRoute(
      path: '/shopping',
      name: 'shopping',
      builder: (context, state) => const ShoppingPage(),
    ),
  ],
);

// Safe, version-agnostic way to read the current path without poking notifiers.
String _readLocation() {
  try {
    // Newer go_router: RouteMatchList has a `uri` (Uri)
    final cfg = _router.routerDelegate.currentConfiguration;
    final Uri? uri = (cfg as dynamic).uri as Uri?;
    if (uri != null) return uri.path;

    // Some versions expose a `location` (String) instead
    final String? loc = (cfg as dynamic).location as String?;
    if (loc != null) return Uri.parse(loc).path;
  } catch (_) {
    // fall through
  }
  try {
    // Last resort (may notify) — used only if the above fails
    return _router.routeInformationProvider.value.uri.path;
  } catch (_) {
    return '/';
  }
}

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
          title: 'Cookgenix',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeMode,
          routerConfig: _router,
          builder: (context, child) {
            // ✅ Use the global _router; do NOT use GoRouter.of(context) here
            // Replace these two lines:
            // final routeInfo = _router.routeInformationProvider.value;
            // final location  = routeInfo.uri.path;

            // With this single line:
            final location = _readLocation();   // read-only and safe

            final weight = kRouteWeights[location] ?? PageWeight.light;

            return ValueListenableBuilder<bool>(
              valueListenable: JankMonitor.isStressed,
              builder: (context, stressed, _) {
                final spec = TransitionSpec.from(weight, stressed: stressed);

                return AnimatedSwitcher(
                  duration: spec.duration,
                  switchInCurve: spec.curveIn,
                  switchOutCurve: spec.curveOut,

                  // ✅ Keep only the current child (prevents two Navigators with same GlobalKey)
                  layoutBuilder: (current, previous) => current ?? const SizedBox.shrink(),

                  // 'widget' is non-null here; no '!' needed
                  transitionBuilder: (widget, animation) => spec.builder(widget, animation),
                  child: KeyedSubtree(
                    key: ValueKey(location),               // forces switch on route change
                    child: child ?? const SizedBox.shrink(), // guard during router boot
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

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
import 'features/cook/recipe_history.dart';
import 'features/cook/recipe_search.dart';
import 'features/inventory/inventory.dart';
import 'features/cook/recipe_favourites.dart';
import 'features/meal_planner/planner.dart';
import 'features/cravings/cravings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize();
  await dotenv.load(fileName: ".env");
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);
  debugPrint = (String? message, {int? wrapWidth}) {};
  runApp(const ProviderScope(child: MyApp()));
}

final GoRouter _router = GoRouter(
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
        final model = state.extra as CravingRecipeModel;
        return CravingRecipePage(recipe: model);
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

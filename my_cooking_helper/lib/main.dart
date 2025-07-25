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
import 'models/recipe_detail.dart';
// import 'models/recipe.dart';
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
import 'features/cook/search_recipe.dart';
import 'features/inventory/inventory.dart';

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
        late RecipeDetail recipe;
        // Accept either a Map or RecipeDetail directly
        if (state.extra is Map<String, dynamic> && (state.extra as Map<String, dynamic>).containsKey('recipe')) {
          recipe = (state.extra as Map<String, dynamic>)['recipe'] as RecipeDetail;
        } else if (state.extra is RecipeDetail) {
          recipe = state.extra as RecipeDetail;
        } else {
          throw Exception('No recipe detail found in route extra');
        }
        return RecipePage(recipe: recipe);
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const RecipeHistoryPage(),
    )
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

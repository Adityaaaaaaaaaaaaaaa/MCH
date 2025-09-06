// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import '/models/recipe_detail.dart';
import '/theme/app_theme.dart';
import '/utils/emoji_animation.dart';
import '/models/recipe.dart';
import '/widgets/recipe/recipe_timeXingredient_picker.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/utils/colors.dart';
import '/utils/loader.dart';
import '/services/recipe_search_service.dart';
import '/utils/lottie_animation.dart';
import '/widgets/recipe/recipe_card.dart';
import '/widgets/recipe/recipe_detail_modal.dart';
import '/utils/recipe_webview_dialog.dart';
import '/services/recipe_rotation_service.dart'; 
class SearchRecipeScreen extends StatefulWidget {
  const SearchRecipeScreen({Key? key}) : super(key: key);

  @override
  State<SearchRecipeScreen> createState() => _SearchRecipeScreenState();
}

class _SearchRecipeScreenState extends State<SearchRecipeScreen> {
  final RecipeSearchService service = RecipeSearchService();
  bool loading = false;
  bool processing = false;
  int? selectedTime;
  List<String> ingredientList = [];
  Set<String> unwantedIngredients = {};
  List<Recipe> recipeResults = [];
  List<RecipeDetail> recipeDetails = [];
  String? errorMsg;

  int visibleRecipes = 3;
  Set<String> selectedRecipes = {};

  ///////////////////////////////////////////////////////////////////////////////////////////// for testing //////////////////
  Map<String, dynamic> deepConvertToStringKeyedMap(Map map) {
    return map.map((key, value) {
      if (value is Map) return MapEntry(key.toString(), deepConvertToStringKeyedMap(value));
      if (value is List) return MapEntry(key.toString(), value.map((e) => e is Map ? deepConvertToStringKeyedMap(e) : e).toList());
      return MapEntry(key.toString(), value);
    });
  }

  final Map<String, dynamic> sampleRecipeDetailMap = {
    'id': 641759,
      'title': 'Dutch Baby',
      'image': 'https://img.spoonacular.com/recipes/641759-556x370.jpg',
      'imageType': 'jpg',
      'readyInMinutes': 45,
      'servings': 4,
      'sourceUrl': 'http://www.foodista.com/recipe/WVMGFLGF/dutch-baby',
      'vegetarian': true,
      'vegan': false,
      'nutrition': {
        'nutrients': [
          {'name': 'Calories', 'amount': 309.59, 'unit': 'kcal', 'percentOfDailyNeeds': 15.48},
          {'name': 'Fat', 'amount': 11.27, 'unit': 'g', 'percentOfDailyNeeds': 17.35},
          {'name': 'Saturated Fat', 'amount': 5.83, 'unit': 'g', 'percentOfDailyNeeds': 36.45},
          {'name': 'Carbohydrates', 'amount': 43.92, 'unit': 'g', 'percentOfDailyNeeds': 14.64},
          {'name': 'Net Carbohydrates', 'amount': 41.57, 'unit': 'g', 'percentOfDailyNeeds': 15.12},
          {'name': 'Sugar', 'amount': 16.47, 'unit': 'g', 'percentOfDailyNeeds': 18.3},
          {'name': 'Cholesterol', 'amount': 145.13, 'unit': 'mg', 'percentOfDailyNeeds': 48.38},
          {'name': 'Sodium', 'amount': 72.64, 'unit': 'mg', 'percentOfDailyNeeds': 3.16},
          {'name': 'Alcohol', 'amount': 0.0, 'unit': 'g', 'percentOfDailyNeeds': 100.0},
          {'name': 'Alcohol %', 'amount': 0.0, 'unit': '%', 'percentOfDailyNeeds': 100.0},
          {'name': 'Protein', 'amount': 10.04, 'unit': 'g', 'percentOfDailyNeeds': 20.08},
          {'name': 'Vitamin C', 'amount': 28.62, 'unit': 'mg', 'percentOfDailyNeeds': 34.69},
          {'name': 'Selenium', 'amount': 22.24, 'unit': 'µg', 'percentOfDailyNeeds': 31.77},
          {'name': 'Vitamin B2', 'amount': 0.4, 'unit': 'mg', 'percentOfDailyNeeds': 23.81},
          {'name': 'Vitamin B1', 'amount': 0.31, 'unit': 'mg', 'percentOfDailyNeeds': 20.97},
          {'name': 'Folate', 'amount': 78.85, 'unit': 'µg', 'percentOfDailyNeeds': 19.71},
          {'name': 'Phosphorus', 'amount': 171.02, 'unit': 'mg', 'percentOfDailyNeeds': 17.1},
          {'name': 'Iron', 'amount': 2.36, 'unit': 'mg', 'percentOfDailyNeeds': 13.11},
          {'name': 'Manganese', 'amount': 0.24, 'unit': 'mg', 'percentOfDailyNeeds': 12.09},
          {'name': 'Calcium', 'amount': 114.04, 'unit': 'mg', 'percentOfDailyNeeds': 11.4},
          {'name': 'Vitamin B12', 'amount': 0.63, 'unit': 'µg', 'percentOfDailyNeeds': 10.58},
          {'name': 'Vitamin B3', 'amount': 1.99, 'unit': 'mg', 'percentOfDailyNeeds': 9.95},
          {'name': 'Vitamin B5', 'amount': 0.98, 'unit': 'mg', 'percentOfDailyNeeds': 9.81},
          {'name': 'Vitamin D', 'amount': 1.44, 'unit': 'µg', 'percentOfDailyNeeds': 9.57},
          {'name': 'Fiber', 'amount': 2.36, 'unit': 'g', 'percentOfDailyNeeds': 9.42},
          {'name': 'Vitamin A', 'amount': 463.83, 'unit': 'IU', 'percentOfDailyNeeds': 9.28},
          {'name': 'Vitamin B6', 'amount': 0.15, 'unit': 'mg', 'percentOfDailyNeeds': 7.52},
          {'name': 'Potassium', 'amount': 246.92, 'unit': 'mg', 'percentOfDailyNeeds': 7.05},
          {'name': 'Zinc', 'amount': 0.93, 'unit': 'mg', 'percentOfDailyNeeds': 6.23},
          {'name': 'Magnesium', 'amount': 22.61, 'unit': 'mg', 'percentOfDailyNeeds': 5.65},
          {'name': 'Copper', 'amount': 0.09, 'unit': 'mg', 'percentOfDailyNeeds': 4.57},
          {'name': 'Vitamin E', 'amount': 0.64, 'unit': 'mg', 'percentOfDailyNeeds': 4.26}
        ],
        'caloricBreakdown': {
          'percentProtein': 12.66,
          'percentFat': 31.98,
          'percentCarbs': 55.36
        },
        'weightPerServing': {'amount': 198.0, 'unit': 'g'}
      },
      'glutenFree': false,
      'dairyFree': false,
      'veryHealthy': false,
      'cheap': false,
      'veryPopular': false,
      'sustainable': false,
      'lowFodmap': false,
      'weightWatcherSmartPoints': 11,
      'gaps': 'no',
      'preparationMinutes': null,
      'cookingMinutes': null,
      'aggregateLikes': 22,
      'healthScore': 5.0,
      'creditsText': 'Foodista.com – The Cooking Encyclopedia Everyone Can Edit',
      'license': 'CC BY 3.0',
      'sourceName': 'Foodista',
      'pricePerServing': 63.09,
      'extendedIngredients': [
        {
          'id': 1123,
          'aisle': 'Milk, Eggs, Other Dairy',
          'image': 'egg.png',
          'consistency': 'SOLID',
          'name': 'eggs',
          'nameClean': 'eggs',
          'original': '3 Eggs',
          'originalName': 'Eggs',
          'amount': 3.0,
          'unit': '',
          'meta': [],
          'measures': {
            'us': {'amount': 3.0, 'unitShort': '', 'unitLong': ''},
            'metric': {'amount': 3.0, 'unitShort': '', 'unitLong': ''}
          }
        },
        {
          'id': 20081,
          'aisle': 'Baking',
          'image': 'flour.png',
          'consistency': 'SOLID',
          'name': 'flour',
          'nameClean': 'flour',
          'original': '1 cup all-purpose flour',
          'originalName': 'all-purpose flour',
          'amount': 1.0,
          'unit': 'cup',
          'meta': ['all-purpose'],
          'measures': {
            'us': {'amount': 1.0, 'unitShort': 'cup', 'unitLong': 'cup'},
            'metric': {'amount': 125.0, 'unitShort': 'g', 'unitLong': 'grams'}
          }
        },
        {
          'id': 9150,
          'aisle': 'Produce',
          'image': 'lemon.png',
          'consistency': 'SOLID',
          'name': 'lemons',
          'nameClean': 'lemons',
          'original': '2 lemons',
          'originalName': 'lemons',
          'amount': 2.0,
          'unit': '',
          'meta': [],
          'measures': {
            'us': {'amount': 2.0, 'unitShort': '', 'unitLong': ''},
            'metric': {'amount': 2.0, 'unitShort': '', 'unitLong': ''}
          }
        },
        {
          'id': 1077,
          'aisle': 'Milk, Eggs, Other Dairy',
          'image': 'milk.png',
          'consistency': 'LIQUID',
          'name': 'milk',
          'nameClean': 'milk',
          'original': '1 cup milk',
          'originalName': 'milk',
          'amount': 1.0,
          'unit': 'cup',
          'meta': [],
          'measures': {
            'us': {'amount': 1.0, 'unitShort': 'cup', 'unitLong': 'cup'},
            'metric': {'amount': 244.0, 'unitShort': 'ml', 'unitLong': 'milliliters'}
          }
        },
        {
          'id': 19335,
          'aisle': 'Baking',
          'image': 'sugar-in-bowl.png',
          'consistency': 'SOLID',
          'name': "confectioner's sugar",
          'nameClean': "confectioner's sugar",
          'original': "confectioner's sugar",
          'originalName': "confectioner's sugar",
          'amount': 4.0,
          'unit': 'servings',
          'meta': [],
          'measures': {
            'us': {'amount': 4.0, 'unitShort': 'servings', 'unitLong': 'servings'},
            'metric': {'amount': 4.0, 'unitShort': 'servings', 'unitLong': 'servings'}
          }
        },
        {
          'id': 1145,
          'aisle': 'Milk, Eggs, Other Dairy',
          'image': 'butter-sliced.jpg',
          'consistency': 'SOLID',
          'name': 'butter',
          'nameClean': 'butter',
          'original': '2 tablespoons Unsalted Organic Butter',
          'originalName': 'Unsalted Organic Butter',
          'amount': 2.0,
          'unit': 'tablespoons',
          'meta': ['unsalted', 'organic'],
          'measures': {
            'us': {'amount': 2.0, 'unitShort': 'Tbsps', 'unitLong': 'Tbsps'},
            'metric': {'amount': 2.0, 'unitShort': 'Tbsps', 'unitLong': 'Tbsps'}
          }
        }
      ],
      'summary': "Dutch Baby could be just the <b>lacto ovo vegetarian</b> recipe you've been looking for. For <b>63 cents per serving</b>, this recipe <b>covers 12%</b> of your daily requirements of vitamins and minerals. This side dish has <b>310 calories</b>, <b>10g of protein</b>, and <b>11g of fat</b> per serving. This recipe serves 4. From preparation to the plate, this recipe takes approximately <b>45 minutes</b>. 22 people have tried and liked this recipe. This recipe from Foodista requires eggs, flour, butter, and milk. Taking all factors into account, this recipe <b>earns a spoonacular score of 46%</b>, which is solid. If you like this recipe, take a look at these similar recipes: <a href=\"https://spoonacular.com/recipes/going-dutch-apple-spice-buttermilk-dutch-baby-864590\">Going Dutch: Apple-Spice Buttermilk Dutch Baby</a>, <a href=\"https://spoonacular.com/recipes/dutch-baby-141619\">Dutch Baby</a>, and <a href=\"https://spoonacular.com/recipes/dutch-baby-1220881\">Dutch Baby</a>.",
      'cuisines': [],
      'dishTypes': ['side dish'],
      'diets': ['lacto ovo vegetarian'],
      'occasions': [],
      'winePairing': {
        'pairedWines': [],
        'pairingText': '',
        'productMatches': []
      },
      'instructions': '<ol><li>Preheat oven to 475 degrees F. Cut lemons in half, crosswise.</li><li>Place butter in a heavy 10" oven-proof skillet. Melt butter in oven; when melted, carefully remove skillet from oven.</li><li>In a bowl, combine milk, flour and eggsmix just enough to blend. Add mixture to hot butter in skillet (swish butter around sides of skillet). Return to oven and bake for 12 minutes or until puffed up.</li><li>Remove puffed Dutch baby from oven to platter. Sprinkle with juice from lemon halves and dust with confectioner\'s sugar. Cut into serving size pieces and serve immediately.</li></ol>',
      'analyzedInstructions': [
        {
          'name': '',
          'steps': [
            {
              'number': 1,
              'step': 'Preheat oven to 475 degrees F.',
              'ingredients': [],
              'equipment': [
                {
                  'id': 404784,
                  'name': 'oven',
                  'localizedName': 'oven',
                  'image': 'https://spoonacular.com/cdn/equipment_100x100/oven.jpg',
                  'temperature': {'number': 475.0, 'unit': 'Fahrenheit'}
                }
              ],
              'length': {}
            },
            {
              'number': 2,
              'step': 'Cut lemons in half, crosswise.',
              'ingredients': [
                {
                  'id': 9150,
                  'name': 'lemon',
                  'localizedName': 'lemon',
                  'image': 'https://spoonacular.com/cdn/ingredients_100x100/lemon.png'
                }
              ],
              'equipment': [],
              'length': {}
            },
            {
              'number': 3,
              'step': 'Place butter in a heavy 10" oven-proof skillet. Melt butter in oven; when melted, carefully remove skillet from oven.In a bowl, combine milk, flour and eggsmix just enough to blend.',
              'ingredients': [
                {'id': 1001, 'name': 'butter', 'localizedName': 'butter', 'image': 'butter-sliced.jpg'},
                {'id': 20081, 'name': 'all purpose flour', 'localizedName': 'all purpose flour', 'image': 'flour.png'},
                {'id': 1077, 'name': 'milk', 'localizedName': 'milk', 'image': 'milk.png'}
              ],
              'equipment': [
                {'id': 404645, 'name': 'frying pan', 'localizedName': 'frying pan', 'image': 'https://spoonacular.com/cdn/equipment_100x100/pan.png', 'temperature': null},
                {'id': 404783, 'name': 'bowl', 'localizedName': 'bowl', 'image': 'https://spoonacular.com/cdn/equipment_100x100/bowl.jpg', 'temperature': null},
                {'id': 404784, 'name': 'oven', 'localizedName': 'oven', 'image': 'https://spoonacular.com/cdn/equipment_100x100/oven.jpg', 'temperature': null}
              ],
              'length': {}
            },
            {
              'number': 4,
              'step': 'Add mixture to hot butter in skillet (swish butter around sides of skillet). Return to oven and bake for 12 minutes or until puffed up.',
              'ingredients': [
                {'id': 1001, 'name': 'butter', 'localizedName': 'butter', 'image': 'butter-sliced.jpg'}
              ],
              'equipment': [
                {'id': 404784, 'name': 'oven', 'localizedName': 'oven', 'image': 'https://spoonacular.com/cdn/equipment_100x100/oven.jpg', 'temperature': null},
                {'id': 404645, 'name': 'frying pan', 'localizedName': 'frying pan', 'image': 'https://spoonacular.com/cdn/equipment_100x100/pan.png', 'temperature': null}
              ],
              'length': {'number': 12, 'unit': 'minutes'}
            },
            {
              'number': 5,
              'step': 'Remove puffed Dutch baby from oven to platter.',
              'ingredients': [],
              'equipment': [
                {'id': 404784, 'name': 'oven', 'localizedName': 'oven', 'image': 'https://spoonacular.com/cdn/equipment_100x100/oven.jpg', 'temperature': null}
              ],
              'length': {}
            },
            {
              'number': 6,
              'step': "Sprinkle with juice from lemon halves and dust with confectioner's sugar.",
              'ingredients': [
                {'id': 1019016, 'name': 'juice', 'localizedName': 'juice', 'image': 'apple-juice.jpg'},
                {'id': 9150, 'name': 'lemon', 'localizedName': 'lemon', 'image': 'https://spoonacular.com/cdn/ingredients_100x100/lemon.png'},
                {'id': 19335, 'name': 'sugar', 'localizedName': 'sugar', 'image': 'sugar-in-bowl.png'}
              ],
              'equipment': [],
              'length': {}
            },
            {
              'number': 7,
              'step': 'Cut into serving size pieces and serve immediately.',
              'ingredients': [],
              'equipment': [],
              'length': {}
            }
          ]
        }
      ],
      'originalId': null,
      'spoonacularScore': 51.050907135009766,
      'spoonacularSourceUrl': 'https://spoonacular.com/dutch-baby-641759'
  };
  ///////////////////// for testing //////////////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => startFlow()); // Uncomment to start flow immediately

    // For UI dev only: Populate with dummy recipes delete later
    // setState(() {
    //   recipeResults = getDummyRecipes();
    //   recipeDetails = List.generate(5, (i) {
    //     final m = deepConvertToStringKeyedMap(sampleRecipeDetailMap);
    //     m['id'] = 157473 + i;
    //     m['title'] = 'Dutch Baby #${i + 1}';
    //     return RecipeDetail.fromJson(m);
    //   });
    // });
  }

  String formatTime(int totalMinutes) {
    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    } else {
      int hours = totalMinutes ~/ 60;
      int minutes = totalMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }

  Future<void> startFlow() async {
    setState(() {
      loading = true;
      errorMsg = null;
      recipeResults.clear();
      visibleRecipes = 3;
      selectedRecipes.clear();
    });

    int? time = await pickCookingTime(context);
    if (time == null) {
      setState(() => loading = false);
      return;
    }
    selectedTime = time;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        loading = false;
        errorMsg = 'User not signed in';
      });
      return;
    }
    ingredientList = await service.fetchUserIngredients(userId);

    Set<String>? unwanted = await selectIngredients(context, ingredientList);
    if (unwanted == null) {
      setState(() => loading = false);
      return;
    }
    unwantedIngredients = unwanted;
    final selectedIngredients = ingredientList.where((ing) => !unwanted.contains(ing)).toList();

    print('\x1B[34m[DEBUG] Selected Time: $selectedTime\x1B[0m');
    print('\x1B[34m[DEBUG] Selected Ingredients: $selectedIngredients\x1B[0m');
    print('\x1B[34m[DEBUG] Unselected Ingredients: ${unwantedIngredients.toList()}\x1B[0m');
    print('\x1B[34m------------------------------------\x1B[0m');


    setState(() {
      loading = false;
      processing = true;
    });
    final lottieController = LottieAnimationController();

    lottieController.show(
      context: context,
      assetPath: 'assets/animations/Animation_Food_Choice.json',
      backgroundColor: bgColor(context),
      repeat: true,
      barrierDismissible: false,
    );

    print('\x1B[34m[DEBUG] Ingredients sent to backend: $selectedIngredients\x1B[0m');

    try {
      final result = await service.searchRecipesWithUserPrefs(
        userId: userId,
        maxTime: selectedTime!,
        overrideIngredients: selectedIngredients,
      );

      // ============ ROTATION LOGIC START ============

      // 1. Fetch recipe history from Firestore
      final recipeHistory = await fetchUserRecipeHistory(userId);

      // 2. Rotate recipes (if you wish to disable, comment this line)
      final rotatedResults = rotateRecipes<Recipe>(
        result.summaries,
        recipeHistory,
        snoozeDays: 2,
        maxFresh: 8,
        getId: (r) => r.id.toString(),
      );

      // 3. Update Firestore with shown recipe IDs
      await updateUserRecipeHistory(
        userId,
        rotatedResults.map((r) => r.id.toString()).toList(),
        maxDaysOld: 5,      // <-- Clear any recipes last shown more than 5 days ago
        trimTo: 200,        // <-- Still keep max 300 entries
      );

      setState(() {
        recipeResults = rotatedResults;
        recipeDetails = result.details;
        processing = false;
      });

      // ============ ROTATION LOGIC END ============

      lottieController.hide();
    } catch (e) {
      lottieController.hide();
      setState(() {
        processing = false;
        errorMsg = e.toString();
      });
    }
  }

  void toggleRecipeSelection(String recipeId) {
    setState(() {
      if (selectedRecipes.contains(recipeId)) {
        selectedRecipes.clear();
      } else {
        selectedRecipes
          ..clear()
          ..add(recipeId);
      }
    });
  }

  void showMoreRecipes() {
    setState(() {
      visibleRecipes = (visibleRecipes + 3).clamp(0, recipeResults.length);
    });
  }

  void showRecipeDetails(Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecipeDetailModal(
        recipe: recipe,
        formatTime: formatTime,
        openWebView: (url) => showRecipeWebView(url),
      ),
    );
  }

  void showRecipeWebView(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.12),
      builder: (context) => RecipeWebViewDialog(url: url),
    );
  }

  // dummy data for test , delete apres
  List<Recipe> getDummyRecipes() {
    Map<String, dynamic> sample = {
      'id': 641759,
      'title': 'Dutch Baby',
      'image': 'https://img.spoonacular.com/recipes/641759-556x370.jpg',
      'imageType': 'jpg',
      'readyInMinutes': 45,
      'servings': 4,
      'sourceUrl': 'http://www.foodista.com/recipe/WVMGFLGF/dutch-baby',
      'vegetarian': true,
      'vegan': false,
      'nutrition': {
        'nutrients': [
          {'name': 'Calories', 'amount': 309.59, 'unit': 'kcal', 'percentOfDailyNeeds': 15.48},
          {'name': 'Fat', 'amount': 11.27, 'unit': 'g', 'percentOfDailyNeeds': 17.35},
          {'name': 'Saturated Fat', 'amount': 5.83, 'unit': 'g', 'percentOfDailyNeeds': 36.45},
          {'name': 'Carbohydrates', 'amount': 43.92, 'unit': 'g', 'percentOfDailyNeeds': 14.64},
          {'name': 'Net Carbohydrates', 'amount': 41.57, 'unit': 'g', 'percentOfDailyNeeds': 15.12},
          {'name': 'Sugar', 'amount': 16.47, 'unit': 'g', 'percentOfDailyNeeds': 18.3},
          {'name': 'Cholesterol', 'amount': 145.13, 'unit': 'mg', 'percentOfDailyNeeds': 48.38},
          {'name': 'Sodium', 'amount': 72.64, 'unit': 'mg', 'percentOfDailyNeeds': 3.16},
          {'name': 'Alcohol', 'amount': 0.0, 'unit': 'g', 'percentOfDailyNeeds': 100.0},
          {'name': 'Alcohol %', 'amount': 0.0, 'unit': '%', 'percentOfDailyNeeds': 100.0},
          {'name': 'Protein', 'amount': 10.04, 'unit': 'g', 'percentOfDailyNeeds': 20.08},
          {'name': 'Vitamin C', 'amount': 28.62, 'unit': 'mg', 'percentOfDailyNeeds': 34.69},
          {'name': 'Selenium', 'amount': 22.24, 'unit': 'µg', 'percentOfDailyNeeds': 31.77},
          {'name': 'Vitamin B2', 'amount': 0.4, 'unit': 'mg', 'percentOfDailyNeeds': 23.81},
          {'name': 'Vitamin B1', 'amount': 0.31, 'unit': 'mg', 'percentOfDailyNeeds': 20.97},
          {'name': 'Folate', 'amount': 78.85, 'unit': 'µg', 'percentOfDailyNeeds': 19.71},
          {'name': 'Phosphorus', 'amount': 171.02, 'unit': 'mg', 'percentOfDailyNeeds': 17.1},
          {'name': 'Iron', 'amount': 2.36, 'unit': 'mg', 'percentOfDailyNeeds': 13.11},
          {'name': 'Manganese', 'amount': 0.24, 'unit': 'mg', 'percentOfDailyNeeds': 12.09},
          {'name': 'Calcium', 'amount': 114.04, 'unit': 'mg', 'percentOfDailyNeeds': 11.4},
          {'name': 'Vitamin B12', 'amount': 0.63, 'unit': 'µg', 'percentOfDailyNeeds': 10.58},
          {'name': 'Vitamin B3', 'amount': 1.99, 'unit': 'mg', 'percentOfDailyNeeds': 9.95},
          {'name': 'Vitamin B5', 'amount': 0.98, 'unit': 'mg', 'percentOfDailyNeeds': 9.81},
          {'name': 'Vitamin D', 'amount': 1.44, 'unit': 'µg', 'percentOfDailyNeeds': 9.57},
          {'name': 'Fiber', 'amount': 2.36, 'unit': 'g', 'percentOfDailyNeeds': 9.42},
          {'name': 'Vitamin A', 'amount': 463.83, 'unit': 'IU', 'percentOfDailyNeeds': 9.28},
          {'name': 'Vitamin B6', 'amount': 0.15, 'unit': 'mg', 'percentOfDailyNeeds': 7.52},
          {'name': 'Potassium', 'amount': 246.92, 'unit': 'mg', 'percentOfDailyNeeds': 7.05},
          {'name': 'Zinc', 'amount': 0.93, 'unit': 'mg', 'percentOfDailyNeeds': 6.23},
          {'name': 'Magnesium', 'amount': 22.61, 'unit': 'mg', 'percentOfDailyNeeds': 5.65},
          {'name': 'Copper', 'amount': 0.09, 'unit': 'mg', 'percentOfDailyNeeds': 4.57},
          {'name': 'Vitamin E', 'amount': 0.64, 'unit': 'mg', 'percentOfDailyNeeds': 4.26}
        ],
        'caloricBreakdown': {
          'percentProtein': 12.66,
          'percentFat': 31.98,
          'percentCarbs': 55.36
        },
        'weightPerServing': {'amount': 198.0, 'unit': 'g'}
      },
      'glutenFree': false,
      'dairyFree': false,
      'veryHealthy': false,
      'cheap': false,
      'veryPopular': false,
      'sustainable': false,
      'lowFodmap': false,
      'weightWatcherSmartPoints': 11,
      'gaps': 'no',
      'preparationMinutes': null,
      'cookingMinutes': null,
      'aggregateLikes': 22,
      'healthScore': 5.0,
      'creditsText': 'Foodista.com – The Cooking Encyclopedia Everyone Can Edit',
      'license': 'CC BY 3.0',
      'sourceName': 'Foodista',
      'pricePerServing': 63.09,
      'extendedIngredients': [
        {
          'id': 1123,
          'aisle': 'Milk, Eggs, Other Dairy',
          'image': 'egg.png',
          'consistency': 'SOLID',
          'name': 'eggs',
          'nameClean': 'eggs',
          'original': '3 Eggs',
          'originalName': 'Eggs',
          'amount': 3.0,
          'unit': '',
          'meta': [],
          'measures': {
            'us': {'amount': 3.0, 'unitShort': '', 'unitLong': ''},
            'metric': {'amount': 3.0, 'unitShort': '', 'unitLong': ''}
          }
        },
        {
          'id': 20081,
          'aisle': 'Baking',
          'image': 'flour.png',
          'consistency': 'SOLID',
          'name': 'flour',
          'nameClean': 'flour',
          'original': '1 cup all-purpose flour',
          'originalName': 'all-purpose flour',
          'amount': 1.0,
          'unit': 'cup',
          'meta': ['all-purpose'],
          'measures': {
            'us': {'amount': 1.0, 'unitShort': 'cup', 'unitLong': 'cup'},
            'metric': {'amount': 125.0, 'unitShort': 'g', 'unitLong': 'grams'}
          }
        },
        {
          'id': 9150,
          'aisle': 'Produce',
          'image': 'lemon.png',
          'consistency': 'SOLID',
          'name': 'lemons',
          'nameClean': 'lemons',
          'original': '2 lemons',
          'originalName': 'lemons',
          'amount': 2.0,
          'unit': '',
          'meta': [],
          'measures': {
            'us': {'amount': 2.0, 'unitShort': '', 'unitLong': ''},
            'metric': {'amount': 2.0, 'unitShort': '', 'unitLong': ''}
          }
        },
        {
          'id': 1077,
          'aisle': 'Milk, Eggs, Other Dairy',
          'image': 'milk.png',
          'consistency': 'LIQUID',
          'name': 'milk',
          'nameClean': 'milk',
          'original': '1 cup milk',
          'originalName': 'milk',
          'amount': 1.0,
          'unit': 'cup',
          'meta': [],
          'measures': {
            'us': {'amount': 1.0, 'unitShort': 'cup', 'unitLong': 'cup'},
            'metric': {'amount': 244.0, 'unitShort': 'ml', 'unitLong': 'milliliters'}
          }
        },
        {
          'id': 19335,
          'aisle': 'Baking',
          'image': 'sugar-in-bowl.png',
          'consistency': 'SOLID',
          'name': "confectioner's sugar",
          'nameClean': "confectioner's sugar",
          'original': "confectioner's sugar",
          'originalName': "confectioner's sugar",
          'amount': 4.0,
          'unit': 'servings',
          'meta': [],
          'measures': {
            'us': {'amount': 4.0, 'unitShort': 'servings', 'unitLong': 'servings'},
            'metric': {'amount': 4.0, 'unitShort': 'servings', 'unitLong': 'servings'}
          }
        },
        {
          'id': 1145,
          'aisle': 'Milk, Eggs, Other Dairy',
          'image': 'butter-sliced.jpg',
          'consistency': 'SOLID',
          'name': 'butter',
          'nameClean': 'butter',
          'original': '2 tablespoons Unsalted Organic Butter',
          'originalName': 'Unsalted Organic Butter',
          'amount': 2.0,
          'unit': 'tablespoons',
          'meta': ['unsalted', 'organic'],
          'measures': {
            'us': {'amount': 2.0, 'unitShort': 'Tbsps', 'unitLong': 'Tbsps'},
            'metric': {'amount': 2.0, 'unitShort': 'Tbsps', 'unitLong': 'Tbsps'}
          }
        }
      ],
      'summary': "Dutch Baby could be just the <b>lacto ovo vegetarian</b> recipe you've been looking for. For <b>63 cents per serving</b>, this recipe <b>covers 12%</b> of your daily requirements of vitamins and minerals. This side dish has <b>310 calories</b>, <b>10g of protein</b>, and <b>11g of fat</b> per serving. This recipe serves 4. From preparation to the plate, this recipe takes approximately <b>45 minutes</b>. 22 people have tried and liked this recipe. This recipe from Foodista requires eggs, flour, butter, and milk. Taking all factors into account, this recipe <b>earns a spoonacular score of 46%</b>, which is solid. If you like this recipe, take a look at these similar recipes: <a href=\"https://spoonacular.com/recipes/going-dutch-apple-spice-buttermilk-dutch-baby-864590\">Going Dutch: Apple-Spice Buttermilk Dutch Baby</a>, <a href=\"https://spoonacular.com/recipes/dutch-baby-141619\">Dutch Baby</a>, and <a href=\"https://spoonacular.com/recipes/dutch-baby-1220881\">Dutch Baby</a>.",
      'cuisines': [],
      'dishTypes': ['side dish'],
      'diets': ['lacto ovo vegetarian'],
      'occasions': [],
      'winePairing': {
        'pairedWines': [],
        'pairingText': '',
        'productMatches': []
      },
      'instructions': '<ol><li>Preheat oven to 475 degrees F. Cut lemons in half, crosswise.</li><li>Place butter in a heavy 10" oven-proof skillet. Melt butter in oven; when melted, carefully remove skillet from oven.</li><li>In a bowl, combine milk, flour and eggsmix just enough to blend. Add mixture to hot butter in skillet (swish butter around sides of skillet). Return to oven and bake for 12 minutes or until puffed up.</li><li>Remove puffed Dutch baby from oven to platter. Sprinkle with juice from lemon halves and dust with confectioner\'s sugar. Cut into serving size pieces and serve immediately.</li></ol>',
      'analyzedInstructions': [
        {
          'name': '',
          'steps': [
            {
              'number': 1,
              'step': 'Preheat oven to 475 degrees F.',
              'ingredients': [],
              'equipment': [
                {
                  'id': 404784,
                  'name': 'oven',
                  'localizedName': 'oven',
                  'image': 'https://spoonacular.com/cdn/equipment_100x100/oven.jpg',
                  'temperature': {'number': 475.0, 'unit': 'Fahrenheit'}
                }
              ],
              'length': {}
            },
            {
              'number': 2,
              'step': 'Cut lemons in half, crosswise.',
              'ingredients': [
                {
                  'id': 9150,
                  'name': 'lemon',
                  'localizedName': 'lemon',
                  'image': 'https://spoonacular.com/cdn/ingredients_100x100/lemon.png'
                }
              ],
              'equipment': [],
              'length': {}
            },
            {
              'number': 3,
              'step': 'Place butter in a heavy 10" oven-proof skillet. Melt butter in oven; when melted, carefully remove skillet from oven.In a bowl, combine milk, flour and eggsmix just enough to blend.',
              'ingredients': [
                {'id': 1001, 'name': 'butter', 'localizedName': 'butter', 'image': 'butter-sliced.jpg'},
                {'id': 20081, 'name': 'all purpose flour', 'localizedName': 'all purpose flour', 'image': 'flour.png'},
                {'id': 1077, 'name': 'milk', 'localizedName': 'milk', 'image': 'milk.png'}
              ],
              'equipment': [
                {'id': 404645, 'name': 'frying pan', 'localizedName': 'frying pan', 'image': 'https://spoonacular.com/cdn/equipment_100x100/pan.png', 'temperature': null},
                {'id': 404783, 'name': 'bowl', 'localizedName': 'bowl', 'image': 'https://spoonacular.com/cdn/equipment_100x100/bowl.jpg', 'temperature': null},
                {'id': 404784, 'name': 'oven', 'localizedName': 'oven', 'image': 'https://spoonacular.com/cdn/equipment_100x100/oven.jpg', 'temperature': null}
              ],
              'length': {}
            },
            {
              'number': 4,
              'step': 'Add mixture to hot butter in skillet (swish butter around sides of skillet). Return to oven and bake for 12 minutes or until puffed up.',
              'ingredients': [
                {'id': 1001, 'name': 'butter', 'localizedName': 'butter', 'image': 'butter-sliced.jpg'}
              ],
              'equipment': [
                {'id': 404784, 'name': 'oven', 'localizedName': 'oven', 'image': 'https://spoonacular.com/cdn/equipment_100x100/oven.jpg', 'temperature': null},
                {'id': 404645, 'name': 'frying pan', 'localizedName': 'frying pan', 'image': 'https://spoonacular.com/cdn/equipment_100x100/pan.png', 'temperature': null}
              ],
              'length': {'number': 12, 'unit': 'minutes'}
            },
            {
              'number': 5,
              'step': 'Remove puffed Dutch baby from oven to platter.',
              'ingredients': [],
              'equipment': [
                {'id': 404784, 'name': 'oven', 'localizedName': 'oven', 'image': 'https://spoonacular.com/cdn/equipment_100x100/oven.jpg', 'temperature': null}
              ],
              'length': {}
            },
            {
              'number': 6,
              'step': "Sprinkle with juice from lemon halves and dust with confectioner's sugar.",
              'ingredients': [
                {'id': 1019016, 'name': 'juice', 'localizedName': 'juice', 'image': 'apple-juice.jpg'},
                {'id': 9150, 'name': 'lemon', 'localizedName': 'lemon', 'image': 'https://spoonacular.com/cdn/ingredients_100x100/lemon.png'},
                {'id': 19335, 'name': 'sugar', 'localizedName': 'sugar', 'image': 'sugar-in-bowl.png'}
              ],
              'equipment': [],
              'length': {}
            },
            {
              'number': 7,
              'step': 'Cut into serving size pieces and serve immediately.',
              'ingredients': [],
              'equipment': [],
              'length': {}
            }
          ]
        }
      ],
      'originalId': null,
      'spoonacularScore': 51.050907135009766,
      'spoonacularSourceUrl': 'https://spoonacular.com/dutch-baby-641759'
    };

    // Generate 5 copies with unique ids
    return List.generate(5, (i) {
      var copy = Map<String, dynamic>.from(sample);
      copy['id'] = 157473 + i;
      copy['title'] = sample['title'] + ' #${i + 1}';
      return Recipe.fromJson(copy);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: bgColor(context),
        body: Center(
          child: loader(
            Theme.of(context).colorScheme.primary,
            70.w,
            4.w,
            10,
            1300,
          ),
        ),
      );
    }
    if (processing) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: true,
      extendBody: true,
      drawer: CustomDrawer(),
      appBar: CustomAppBar(
        title: "Find Recipes",
        showMenu: false,
        themeToggleWidget: ThemeToggleButton(),
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
      ),
      body: errorMsg != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(
                    errorMsg!,
                    style: TextStyle(color: Colors.red, fontSize: 18.sp),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : recipeResults.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80.sp, color: Colors.grey[500]),
                  SizedBox(height: 12.h),
                  EmojiAnimation(
                    name: "mouthNone",
                    size: 60,
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    "No Recipes Matched",
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.w),
                    child: Text(
                      "We couldn't find any recipes for your search.\n\n"
                      "Tips:\n"
                      "• Select fewer ingredients\n"
                      "• Adjust the maximum cooking time\n"
                      "• Try again",
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 22.h),
                ],
              ),
            )
          : Column(
              children: [
                // Results header
                Container(
                  padding: EdgeInsets.fromLTRB(20.w, 120.h, 20.w, 16.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        child: Text(
                          'Found ${recipeResults.length} recipes',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: textColor(context),
                          ),
                        ),
                      ),
                      if (selectedRecipes.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRecipes.clear();
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 16.sp),
                                SizedBox(width: 6.w),
                                Text(
                                  '${selectedRecipes.length} selected',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Recipes list
                Expanded(
                  child: ListView.builder(
                    cacheExtent: MediaQuery.of(context).size.height,
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                    // itemCount logic:
                    // - If there are more recipes to show, show a "Show More" button as the last item.
                    // - Otherwise, just show as many as we have.
                    itemCount: (recipeResults.length > visibleRecipes)
                        ? visibleRecipes + 1 // +1 for the button
                        : recipeResults.length,
                    itemBuilder: (context, index) {
                      // Display recipe cards
                      if (index < visibleRecipes && index < recipeResults.length) {
                        final isSelected = selectedRecipes.contains(recipeResults[index].id);
                        if (selectedRecipes.isNotEmpty && !isSelected) {
                          // Only blur non-selected cards when something is selected
                          return Stack(
                            children: [
                              RecipeCard(
                                recipe: recipeResults[index],
                                isSelected: false,
                                formatTime: formatTime,
                                onLongPress: () => toggleRecipeSelection(recipeResults[index].id),
                                onSelect: () => toggleRecipeSelection(recipeResults[index].id),
                                onViewRecipe: () => showRecipeDetails(recipeResults[index]),
                              ),
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24.r),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                                    child: Container(
                                      color: Colors.black.withOpacity(0.05), // Optional: subtle overlay
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Show the selected card (or all cards when nothing is selected) without any blur
                          return RecipeCard(
                            recipe: recipeResults[index],
                            isSelected: isSelected,
                            formatTime: formatTime,
                            onLongPress: () => toggleRecipeSelection(recipeResults[index].id),
                            onSelect: () => toggleRecipeSelection(recipeResults[index].id),
                            onViewRecipe: () => showRecipeDetails(recipeResults[index]),
                          );
                        }
                      }
                      // "Show more" button logic
                      else if (index == visibleRecipes &&
                              recipeResults.length > visibleRecipes) {
                        return Container(
                          margin: EdgeInsets.only(top: 8.h),
                          child: GestureDetector(
                            onTap: showMoreRecipes,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.expand_more_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Show ${(recipeResults.length - visibleRecipes).clamp(0, 3)} more recipes',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ).asGlass(
                              blurX: 7,
                              blurY: 7,
                              tintColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              clipBorderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                        );
                      }
                      else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: Builder(
        builder: (context) {
          final isRecipeSelected = selectedRecipes.length == 1;     
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: FloatingActionButton.extended(
              onPressed: isRecipeSelected
                ? () async { 
                    final selectedSummary = recipeResults.firstWhere(
                      (r) => selectedRecipes.contains(r.id),
                    );

                    RecipeDetail? selectedRecipeDetail;
                    try {
                      selectedRecipeDetail = recipeDetails.firstWhere(
                        (d) => d.id.toString() == selectedSummary.id.toString(), // Use .toString() for safety
                      );
                    } catch (e) {
                      setState(() {
                        errorMsg = "Recipe details not found. Please try again.";
                      });
                      return;
                    }

                    context.push('/recipePage', extra: {'recipe': selectedRecipeDetail, 'fromHistory': false});
                  }
                : startFlow,
              icon: Icon(
                isRecipeSelected ? Icons.restaurant_menu_rounded : Icons.refresh,
                size: 22.sp,
              ),
              label: Text(
                isRecipeSelected ? "Cook >>>" : "Search Again",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.sp),
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: textColor(context),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ).asGlass(
              blurX: 20,
              blurY: 20,
              tintColor: isRecipeSelected? Colors.green : Colors.red,
              clipBorderRadius: BorderRadius.circular(24.r),
            ),
          );
        },
      ),
    );
  }
}

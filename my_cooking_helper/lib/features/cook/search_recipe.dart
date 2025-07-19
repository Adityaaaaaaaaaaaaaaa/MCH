import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
// import 'package:webview_flutter/webview_flutter.dart';
import '/models/recipe.dart';
import '/widgets/cook_picker.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/utils/colors.dart';
import '/utils/loader.dart';
import '/services/recipe_search_service.dart';
import '/utils/lottie_animation.dart';
import '/widgets/recipe_card.dart';
import '/widgets/recipe_detail_modal.dart';
import '/utils/recipe_webview_dialog.dart';

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
  String? errorMsg;

  int visibleRecipes = 3;
  Set<String> selectedRecipes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => startFlow());
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
      assetPath: 'assets/animations/Animation_scanReceipt.json',
      backgroundColor: bgColor(context),
      repeat: true,
      barrierDismissible: false,
    );

    print('\x1B[34m[DEBUG] Ingredients sent to backend: $selectedIngredients\x1B[0m');

    try {
      recipeResults = await service.searchRecipesWithUserPrefs(
        userId: userId,
        maxTime: selectedTime!,
        overrideIngredients: selectedIngredients,
      );

      lottieController.hide();
      setState(() => processing = false);
    } catch (e) {
      lottieController.hide();
      setState(() {
        processing = false;
        errorMsg = e.toString();
      });
    }
  }

  void toggleRecipeSelection(String recipeTitle) {
    setState(() {
      if (selectedRecipes.contains(recipeTitle)) {
        selectedRecipes.remove(recipeTitle);
      } else {
        selectedRecipes.add(recipeTitle);
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
                      Icon(Icons.search_off, size: 80.sp, color: Colors.grey[400]),
                      SizedBox(height: 16.h),
                      Text(
                        'No recipes found',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Try adjusting your preferences and search again',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
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
                          Text(
                            'Found ${recipeResults.length} recipes',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (selectedRecipes.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Text(
                                '${selectedRecipes.length} selected',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Recipes list
                    Expanded(
                      child: ListView.builder(
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
                            //return _buildRecipeCard(recipeResults[index], index);
                            // inside ListView.builder:
                            return RecipeCard(
                              recipe: recipeResults[index],
                              isSelected: selectedRecipes.contains(recipeResults[index].title),
                              formatTime: formatTime,
                              onTap: () => showRecipeDetails(recipeResults[index]),
                              onSelect: () => toggleRecipeSelection(recipeResults[index].title),
                              onViewRecipe: () => showRecipeDetails(recipeResults[index]),
                            );
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
                                        Icons.expand_more,
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
                          // Defensive: If index is out of range (shouldn't happen), return empty
                          else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: startFlow,
        icon: const Icon(Icons.refresh),
        label: const Text('Search Again'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

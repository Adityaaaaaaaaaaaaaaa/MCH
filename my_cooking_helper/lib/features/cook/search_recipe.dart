import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/widgets/cook_picker.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/utils/colors.dart';
import '/utils/loader.dart';
import '/services/recipe_search_service.dart';
import '/utils/lottie_animation.dart';

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
  Set<String> unwantedIngredients = {}; // Excluded ones (red)
  List<Recipe> recipeResults = [];
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => startFlow());
  }

  Future<void> startFlow() async {
    setState(() {
      loading = true;
      errorMsg = null;
      recipeResults.clear();
    });

    // Step 1: Pick cooking time
    int? time = await pickCookingTime(context);
    if (time == null) {
      setState(() => loading = false);
      return;
    }
    selectedTime = time;

    // Step 2: Fetch ingredients
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        loading = false;
        errorMsg = 'User not signed in';
      });
      return;
    }
    ingredientList = await service.fetchUserIngredients(userId);

    // Step 3: Select ingredients (returns unwanted/excluded ones)
    Set<String>? unwanted = await selectIngredients(context, ingredientList);
    if (unwanted == null) {
      setState(() => loading = false);
      return;
    }
    unwantedIngredients = unwanted;
    final selectedIngredients = ingredientList.where((ing) => !unwanted.contains(ing)).toList();

    // Step 4: Animation and backend call
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

    try {
      recipeResults = await service.searchRecipes(
        ingredients: selectedIngredients,
        maxTime: selectedTime!,
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
    if (processing) return const SizedBox.shrink(); // Lottie overlay shown

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
      body: Padding(
        padding: EdgeInsets.all(20.0.w),
        child: errorMsg != null
            ? Center(
                child: Text(
                  errorMsg!,
                  style: TextStyle(color: Colors.red, fontSize: 18.sp),
                ),
              )
            : recipeResults.isEmpty
                ? Center(
                    child: Text(
                      'No recipes found. Try again!',
                      style: TextStyle(fontSize: 18.sp),
                    ),
                  )
                : ListView.builder(
                    itemCount: recipeResults.length,
                    itemBuilder: (context, idx) {
                      final recipe = recipeResults[idx];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                          leading: recipe.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Image.network(
                                    recipe.imageUrl,
                                    width: 56.w,
                                    height: 56.w,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.restaurant_menu, size: 36),
                          title: Text(
                            recipe.title,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                          ),
                          subtitle: Text('${recipe.totalTime} min'),
                          onTap: () {
                            // TODO: handle recipe selection (details/confirm/etc.)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Selected: ${recipe.title}')),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: startFlow,
        tooltip: 'Start Again',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

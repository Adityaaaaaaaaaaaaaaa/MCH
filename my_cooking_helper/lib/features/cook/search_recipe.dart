import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';

import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/utils/colors.dart';
import '/utils/loader.dart'; // Your custom loader widget
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
        padding: EdgeInsets.all(16.0.w),
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
        child: const Icon(Icons.refresh),
        tooltip: 'Start Again',
      ),
    );
  }
}

// --------- Modular Dialogs (Glassy, Responsive, with Toggle) ---------

Future<int?> pickCookingTime(BuildContext context, {int initial = 30}) {
  int tmpTime = initial;
  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26.r)),
        backgroundColor: Colors.white.withOpacity(0.13),
        title: Center(
          child: Text(
            'Select Cooking Time',
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
          ),
        ),
        content: Container(
          width: 290.w,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$tmpTime min',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.teal.shade700,
                ),
              ),
              SizedBox(height: 10.h),
              Slider(
                min: 10,
                max: 120,
                divisions: 22,
                value: tmpTime.toDouble(),
                activeColor: Colors.teal,
                inactiveColor: Colors.teal.shade100,
                label: '$tmpTime min',
                onChanged: (val) => setState(() => tmpTime = val.round()),
              ),
              SizedBox(height: 2.h),
              Text(
                'How much time do you have?',
                style: TextStyle(fontSize: 15.sp, color: Colors.black54),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: Text('Cancel', style: TextStyle(fontSize: 16.sp)),
                ),
                SizedBox(width: 12.w),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r)),
                  ),
                  onPressed: () => Navigator.pop(ctx, tmpTime),
                  child: Text('OK', style: TextStyle(fontSize: 16.sp)),
                ),
              ],
            ),
          ),
        ],
      ).asGlass(
          blurX: 13,
          blurY: 13,
          tintColor: Colors.white,
          clipBorderRadius: BorderRadius.circular(26.r),
          frosted: true),
    ),
  );
}

Future<Set<String>?> selectIngredients(
  BuildContext context,
  List<String> initialIngredients,
) {
  final Set<String> unwanted = {};
  return showDialog<Set<String>>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26.r)),
        backgroundColor: Colors.white.withOpacity(0.12),
        title: Text(
          "Select Ingredients",
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 10.w,
            runSpacing: 12.h,
            children: [
              for (final ing in initialIngredients)
                GestureDetector(
                  onTap: () => setState(() {
                    if (unwanted.contains(ing)) {
                      unwanted.remove(ing);
                    } else {
                      unwanted.add(ing);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    margin: EdgeInsets.symmetric(vertical: 2.h),
                    decoration: BoxDecoration(
                      color: unwanted.contains(ing)
                          ? Colors.red.withOpacity(0.9)
                          : Colors.green.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(22.r),
                      border: Border.all(
                        color: unwanted.contains(ing)
                            ? Colors.red.shade900
                            : Colors.green.shade900,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: unwanted.contains(ing)
                              ? Colors.red.withOpacity(0.15)
                              : Colors.green.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Text(
                      ing,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ).asGlass(
                    tintColor: unwanted.contains(ing)
                        ? Colors.red
                        : Colors.green,
                    blurX: 12,
                    blurY: 12,
                    clipBorderRadius: BorderRadius.circular(22.r),
                    frosted: true,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: Text("Cancel", style: TextStyle(fontSize: 16.sp)),
                ),
                SizedBox(width: 14.w),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 10.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r)),
                  ),
                  onPressed: () => Navigator.pop(ctx, unwanted),
                  child: Text("Proceed", style: TextStyle(fontSize: 16.sp)),
                ),
              ],
            ),
          ),
        ],
      ).asGlass(
        blurX: 15, blurY: 15, tintColor: Colors.white, clipBorderRadius: BorderRadius.circular(26.r), frosted: true),
    ),
  );
}

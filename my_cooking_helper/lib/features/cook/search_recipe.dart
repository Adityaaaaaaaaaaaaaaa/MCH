import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
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

// ---------------------- Modern Glassy Time Picker ----------------------

Future<int?> pickCookingTime(BuildContext context, {int initial = 30}) {
  int tmpTime = initial;
  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: bgColor(context),
        child: Container(
          width: 320.w,
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 15.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.r),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.blueGrey.withOpacity(0.20),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 34,
                offset: Offset(0, 10.h),
              )
            ],
            border: Border.all(
              color: Colors.tealAccent.withOpacity(0.5),
              width: 1.2.w,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How much time do you have?', 
                style: TextStyle(
                  fontSize: 18.sp, 
                  color: textColor(context), 
                  fontWeight: FontWeight.w700
                )
              ),
              SizedBox(height: 20.h),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150.w,
                    height: 70.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(15.r),
                      gradient: LinearGradient(
                        colors: [
                          Colors.redAccent.withOpacity(0.3),
                          Colors.blueAccent.withOpacity(0.3)
                        ],
                      ),
                    ),
                  ),
                  Text(
                    tmpTime >= 60
                      ? '${tmpTime ~/ 60}h ${tmpTime % 60 > 0 ? '${tmpTime % 60}m' : ''}'
                      : '$tmpTime min',
                    style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor(context),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
                SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.h,
                  activeTrackColor: Colors.blue.shade200,
                  inactiveTrackColor: Colors.tealAccent.shade100,
                  thumbColor: Colors.teal.shade400,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.sp),
                  overlayColor: Colors.blueGrey.shade100,
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 15.sp),
                  valueIndicatorColor: Colors.grey,
                  valueIndicatorTextStyle: TextStyle(fontSize: 15.sp, color: Colors.white),
                ),
                child: Column(
                  children: [
                    Slider(
                      min: 15,
                      max: 180,
                      divisions: 11, // 15 min steps: 15, 30, ..., 180
                      value: tmpTime.toDouble().clamp(15, 180),
                      label: '${tmpTime ~/ 60}h ${tmpTime % 60}m',
                      onChanged: (val) => setState(() => tmpTime = ((val ~/ 15) * 15).clamp(15, 180)),
                    ),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent.shade100,
                      textStyle: TextStyle(fontSize: 15.sp),
                    ),
                    onPressed: () => Navigator.pop(ctx, null),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: 15.w),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                      backgroundColor: Colors.tealAccent.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx, tmpTime),
                    child: Text('OK', style: TextStyle(fontSize: 15.sp)),
                  ),
                ],
              ),
            ],
          ),
        ).asGlass(
          blurX: 18,
          blurY: 18,
          tintColor: Colors.white,
          clipBorderRadius: BorderRadius.circular(28.r),
          frosted: true,
        ),
      ),
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
      builder: (context, setState) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400.w,
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 15.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.r),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.blueGrey.withOpacity(0.20),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.tealAccent.withOpacity(0.5),
              width: 1.2.w,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 0.70 * MediaQuery.of(context).size.height,
              minHeight: 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Select Ingredients",
                  style: TextStyle(
                    fontSize: 21.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor(context),
                  ),
                ),
                SizedBox(height: 18.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      alignment: WrapAlignment.center, // <-- Center the chips
                      spacing: 5.w, // chip gap
                      runSpacing: 5.h,
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
                              duration: const Duration(milliseconds: 170),
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w, //chip size
                                vertical: 5.h,
                              ),
                              margin: EdgeInsets.symmetric(vertical: 2.h),
                              decoration: BoxDecoration(
                                color: unwanted.contains(ing)
                                    ? Colors.redAccent.shade100
                                    : Colors.greenAccent.shade100,
                                borderRadius: BorderRadius.circular(12.r), //chip border
                                border: Border.all(
                                  color: unwanted.contains(ing)
                                      ? Colors.red.shade900
                                      : Colors.green.shade900,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    unwanted.contains(ing)
                                        ? Icons.close_rounded
                                        : Icons.check_circle_rounded,
                                    color: unwanted.contains(ing)
                                        ? Colors.red[50]
                                        : Colors.white,
                                    size: 12.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    ing,
                                    style: TextStyle(
                                      color: unwanted.contains(ing)
                                          ? Colors.red[50]
                                          : Colors.black,
                                      fontSize: 11.sp, //chip font size
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ).asGlass(
                              tintColor: unwanted.contains(ing)
                                  ? Colors.red.shade100
                                  : Colors.green.shade100,
                              blurX: 10,
                              blurY: 10,
                              clipBorderRadius: BorderRadius.circular(12.r),
                              frosted: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent.shade100,
                        textStyle: TextStyle(fontSize: 15.sp),
                      ),
                      onPressed: () => Navigator.pop(ctx, null),
                      child: const Text("Cancel"),
                    ),
                    SizedBox(width: 16.w),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        backgroundColor: Colors.tealAccent.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx, unwanted),
                      child: Text("Proceed", style: TextStyle(fontSize: 15.sp)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).asGlass(
          blurX: 17,
          blurY: 17,
          tintColor: Colors.white.withOpacity(0.09),
          clipBorderRadius: BorderRadius.circular(20.r),
          frosted: true,
        ),
      ),
    ),
  );
}
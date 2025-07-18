import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '/models/recipe.dart';
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

  Widget _buildRecipeCard(Recipe recipe, int index) {
    bool isSelected = selectedRecipes.contains(recipe.title);
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: () => showRecipeDetails(recipe),
        child: Container(
          margin: EdgeInsets.only(bottom: 16.h),
          child: Stack(
            children: [
              // Glass effect
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: isSelected ? Border.all(color: Colors.green, width: 2.5) : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28.r),
                  child: Container(
                    padding: EdgeInsets.only(bottom: 0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recipe Image with Glass Badge
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                              child: Image.network(
                                recipe.imageUrl,
                                width: double.infinity,
                                height: 180.h,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: double.infinity,
                                  height: 180.h,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.restaurant_menu, size: 60.sp, color: Colors.grey[400]),
                                ),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: double.infinity,
                                    height: 180.h,
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Time badge (glass effect)
                            Positioned(
                              bottom: 14.h,
                              left: 16.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time, size: 14.sp, color: Colors.white),
                                    SizedBox(width: 6.w),
                                    Text(
                                      formatTime(recipe.totalTime),
                                      style: TextStyle(
                                        color: textColor(context),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ).asGlass(
                                blurX: 7,
                                blurY: 7,
                                tintColor: Colors.black.withOpacity(0.38),
                                clipBorderRadius: BorderRadius.circular(18.r),
                              ),
                            ),
                            // Select badge
                            Positioned(
                              top: 14.h,
                              right: 16.w,
                              child: GestureDetector(
                                onTap: () {
                                  toggleRecipeSelection(recipe.title);
                                },
                                child: Container(
                                  padding: EdgeInsets.all(10.w),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.green : Colors.white.withOpacity(0.92),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.11),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isSelected ? Icons.check : Icons.add,
                                    size: 18.sp,
                                    color: isSelected ? Colors.white : Colors.green,
                                  ),
                                ).asGlass(
                                  blurX: 10,
                                  blurY: 10,
                                  tintColor: isSelected ? Colors.green : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Recipe Info Section
                        Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 19.sp,
                                  color: textColor(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 14.sp, color: Colors.grey[700]),
                                  SizedBox(width: 6.w),
                                  Text(
                                    '${recipe.ingredients.length} ingredients',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              // View Recipe Button
                              InkWell(
                                borderRadius: BorderRadius.circular(14.r),
                                onTap: () => showRecipeDetails(recipe),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 11.h),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'View Recipe',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ).asGlass(
                                  blurX: 4,
                                  blurY: 6,
                                  tintColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  clipBorderRadius: BorderRadius.circular(14.r),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).asGlass(
                  blurX: 8,
                  blurY: 8,
                  tintColor: Colors.white.withOpacity(0.07),
                  clipBorderRadius: BorderRadius.circular(28.r),
                ),
              ),
            ],
          ),
        ),
      ),
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
                            return _buildRecipeCard(recipeResults[index], index);
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

/// Recipe Detail Modal with glass and in-app webview open callback
class RecipeDetailModal extends StatelessWidget {
  final Recipe recipe;
  final String Function(int) formatTime;
  final void Function(String url) openWebView;
  const RecipeDetailModal({
    Key? key,
    required this.recipe,
    required this.formatTime,
    required this.openWebView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      maxChildSize: 0.98,
      minChildSize: 0.60,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(26, 18, 26, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // IMAGE
                  if (recipe.imageUrl.isNotEmpty)
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            recipe.imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.grey[200],
                              child: Icon(Icons.restaurant_menu, size: 60, color: Colors.grey[400]),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    recipe.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: textColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Time Info
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.deepPurple.withOpacity(0.25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.deepPurple),
                            const SizedBox(width: 7),
                            Text(
                              formatTime(recipe.totalTime),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Ingredients
                  if (recipe.ingredients.isNotEmpty) ...[
                    Text(
                      'Ingredients',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: textColor(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...recipe.ingredients.map((ingredient) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${ingredient.name}${ingredient.quantity.isNotEmpty ? " (${ingredient.quantity})" : ""}',
                              style: TextStyle(fontSize: 16, color: textColor(context)),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 18),
                  ],
                  // Instructions
                  if (recipe.instructions.isNotEmpty) ...[
                    Text(
                      'Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: textColor(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...recipe.instructions.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 13),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(fontSize: 15, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                  // Equipment
                  if (recipe.equipment.isNotEmpty) ...[
                    Text(
                      'Equipment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: textColor(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recipe.equipment.map((equipment) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          equipment,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.deepPurple,
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Website Link
                  if (recipe.website.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => openWebView(recipe.website),
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.blue.withOpacity(0.18)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.language, color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Visit Recipe Website',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (recipe.website.startsWith('http://')) // Show warning for HTTP
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 0),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This website is not secure (HTTP). Your connection may not be private.',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  // Videos
                  if (recipe.videos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Videos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...recipe.videos.map((video) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: GestureDetector(
                        onTap: () => openWebView(video),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.red.withOpacity(0.18)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.play_circle_fill, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  video,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fullscreen dialog for displaying a WebView.
/// This is the recommended solution for platform views, as per the official Flutter guidance.
class RecipeWebViewDialog extends StatefulWidget {
  final String url;
  const RecipeWebViewDialog({Key? key, required this.url}) : super(key: key);

  @override
  State<RecipeWebViewDialog> createState() => _RecipeWebViewDialogState();
}

class _RecipeWebViewDialogState extends State<RecipeWebViewDialog> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    _controller.clearCache();
    // Optionally: clear cookies, local storage, etc. if needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white.withOpacity(0.99),
            child: WebViewWidget(controller: _controller),
          ),
          Positioned(
            top: 32,
            right: 20,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(32),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 28, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

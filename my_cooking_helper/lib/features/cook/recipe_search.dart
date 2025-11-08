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

    try {
      final result = await service.searchRecipesWithUserPrefs(
        userId: userId,
        maxTime: selectedTime!,
        overrideIngredients: selectedIngredients,
      );

      // ROTATION LOGIC

      // 1. Fetch recipe history from Firestore
      final recipeHistory = await fetchUserRecipeHistory(userId);

      // 2. Rotate recipes
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

      // ROTATION LOGIC END 

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
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 22.w),
                child: Builder(
                  builder: (context) {
                    final String raw = errorMsg ?? '';

                    String sanitize(String s) {
                      String out = s;
                      out = out.replaceAll(RegExp(r'uri=\S+', caseSensitive: false), 'uri=<hidden>');
                      out = out.replaceAll(RegExp(r'host:\s*\S+', caseSensitive: false), 'host:<hidden>');
                      out = out.replaceAll(RegExp(r'port:\s*\d+', caseSensitive: false), 'port:<hidden>');
                      out = out.replaceAll(RegExp(r'https?:\/\/[^\s)]+', caseSensitive: false), '<url>');
                      out = out.replaceAll(RegExp(r'\b\d{1,3}(\.\d{1,3}){3}\b(:\d+)?'), '<ip>');
                      return out;
                    }

                    String lower = raw.toLowerCase();
                    String title = 'Something went wrong';
                    String friendly = 'Please try again. If the issue persists, check your connection or try later.';
                    Color accent = Colors.redAccent;

                    if (lower.contains('timed out') || lower.contains('timeout')) {
                      title = 'Connection timed out';
                      friendly = "The server didn't respond in time. Check your internet or try again.";
                      accent = Colors.orangeAccent;
                    } else if (lower.contains('socketexception') || lower.contains('failed host lookup')) {
                      title = 'Network issue';
                      friendly = 'We couldn\'t reach the service. Please verify your connection and VPN/proxy settings.';
                      accent = Colors.deepOrangeAccent;
                    } else if (RegExp(r'\b(5\d{2})\b').hasMatch(lower) || lower.contains('internal server error')) {
                      title = 'Server problem';
                      friendly = 'The service had a hiccup. Please try again shortly.';
                      accent = Colors.pinkAccent;
                    } else if (RegExp(r'\b(4\d{2})\b').hasMatch(lower)) {
                      title = 'Request error';
                      friendly = 'The request could not be completed. Please review your inputs and try again.';
                      accent = Colors.amber;
                    }

                    final String details = sanitize(raw);

                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          EmojiAnimation(name: 'warning', size: 48),
                          SizedBox(height: 12.h),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              color: textColor(context),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            friendly,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              height: 1.4,
                              color: textColor(context).withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: startFlow,
                                icon: Icon(Icons.refresh, size: 18.sp),
                                label: Text('Retry', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.sp)),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: accent.withOpacity(0.9),
                                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              collapsedIconColor: textColor(context).withOpacity(0.6),
                              iconColor: textColor(context).withOpacity(0.6),
                              leading: Icon(Icons.info_outline_rounded, size: 18.sp, color: textColor(context).withOpacity(0.7)),
                              title: Text(
                                'Details (sanitized)',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                  color: textColor(context).withOpacity(0.7),
                                ),
                              ),
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 10.h),
                                  child: SelectableText(
                                    details,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11.sp,
                                      height: 1.3,
                                      color: textColor(context).withOpacity(0.65),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).asGlass(
                      blurX: 18,
                      blurY: 18,
                      tintColor: accent.withOpacity(0.12),
                      clipBorderRadius: BorderRadius.circular(18.r),
                    );
                  },
                ),
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
                                      color: Colors.black.withOpacity(0.05),
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
              tintColor: isRecipeSelected? Colors.green : Colors.blue,
              clipBorderRadius: BorderRadius.circular(24.r),
            ),
          );
        },
      ),
    );
  }
}

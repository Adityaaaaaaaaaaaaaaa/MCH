import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/widgets/recipe_common_widgets.dart';
import '/theme/app_theme.dart';
import '/models/recipe.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
// import '/utils/recipe_webview_dialog.dart';

class RecipePage extends ConsumerWidget {
  const RecipePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final Recipe? recipe = args?['recipe'] as Recipe?;

    if (recipe == null) {
      return Scaffold(
        backgroundColor: bgColor(context),
        body: Center(
          child: Text(
            "No recipe data found.",
            style: TextStyle(fontSize: 20.sp, color: Colors.red),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    void openWebView(String url) {
      showRecipeWebView(context, url);
    }

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBody: true,
      extendBodyBehindAppBar: true,
      drawer: const CustomDrawer(), 
      appBar: CustomAppBar(
        title: "~ Recipe ~",
        showMenu: false,
        themeToggleWidget: ThemeToggleButton(),
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 18.h, right: 12.w),
        child: FloatingActionButton.extended(
          heroTag: "markAsCooked",
          backgroundColor: isDark ? Colors.green[700] : Colors.green[400],
          foregroundColor: Colors.white,
          elevation: 4,
          icon: Icon(Icons.check_circle_rounded, size: 24.sp),
          label: Text(
            "Mark as Cooked",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.sp),
          ),
          onPressed: () {
            // Implement Mark as Cooked logic later
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Marked as cooked! (Dummy action)"),
                backgroundColor: Colors.green[600],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // Blurred background image
          if (recipe.imageUrl.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: Image.network(
                  recipe.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const SizedBox.shrink(),
                ),
              ),
            ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 50.h),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  if (recipe.imageUrl.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.all(10.w),
                      child: RecipeImageCard(imageUrl: recipe.imageUrl, isDark: isDark,),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        RecipeTitle(title: recipe.title),
                        SizedBox(height: 6.h),

                        // Dish Type & Servings as Chips (separate rows)
                        if (recipe.dishTypes.isNotEmpty)
                          InfoChip(
                            icon: Icons.restaurant_rounded, 
                            text: recipe.dishTypes.join(', ').replaceFirstMapped(
                                RegExp(r'^\w'),
                                (m) => m.group(0)!.toUpperCase(),
                              ), 
                            isDark: isDark
                          ),
                        SizedBox(height: 7.h),

                        if (recipe.servings > 0)
                          InfoChip(
                            icon: Icons.people_rounded, 
                            text: 'Serves ${recipe.servings}', 
                            isDark: isDark
                          ),
                        SizedBox(height: 10.h),

                        // Times Row (Prep, Cook, Total)
                        TimeRow(
                          recipe: recipe, 
                          isDark: isDark, 
                          formatTime: formatTime
                        ),
                        SizedBox(height: 25.h),

                        // Ingredients Section
                        if (recipe.ingredients.isNotEmpty) ...[
                          SectionHeader(
                            title: 'Ingredients', 
                            icon: Icons.list_alt_rounded, 
                            isDark: isDark
                          ),
                          SizedBox(height: 10.h),
                          IngredientsList(ingredients: recipe.ingredients, isDark: isDark),
                          SizedBox(height: 25.h),
                        ],

                        // Instructions Section
                        if (recipe.instructions.isNotEmpty) ...[
                          SectionHeader(
                            title: 'Instructions', 
                            icon: Icons.format_list_numbered_rounded, 
                            isDark: isDark
                          ),
                          SizedBox(height: 10.h),
                          InstructionsList(instructions: recipe.instructions, isDark: isDark),
                          SizedBox(height: 22.h),
                        ],

                        // Equipment Section
                        if (recipe.equipment.isNotEmpty) ...[
                          SectionHeader(
                            title: 'Equipment', 
                            icon: Icons.kitchen_rounded, 
                            isDark: isDark
                          ),
                          SizedBox(height: 16.h),
                          EquipmentChips(equipment: recipe.equipment, isDark: isDark),
                          SizedBox(height: 25.h),
                        ],

                        // Nutrition Section
                        if (recipe.nutrition != null && recipe.nutrition!.isNotEmpty)
                          NutritionSection(nutrition: recipe.nutrition!),
                        SizedBox(height: 21.h),

                        // Website Link
                        if (recipe.website.isNotEmpty) ...[
                          WebsiteLinkCard(
                            url: recipe.website,
                            isDark: isDark,
                            onTap: (url) => showRecipeWebView(context, url),
                          ),
                          if (recipe.website.startsWith('http://'))
                            HttpWarningCard(isDark: isDark),
                        ],

                        // Videos Section
                        if (recipe.videos.isNotEmpty) ...[
                          SectionHeader(title: 'Videos', icon: Icons.play_circle_filled_rounded, isDark: isDark),
                          SizedBox(height: 10.h),
                          ...recipe.videos.map(
                            (video) => Container(
                              margin: EdgeInsets.only(bottom: 9.h),
                              child: GestureDetector(
                                onTap: () => openWebView(video),
                                child: Container(
                                  padding: EdgeInsets.all(13.w),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [Colors.red[800]!.withOpacity(0.17), Colors.red[700]!.withOpacity(0.07)]
                                          : [Colors.red.withOpacity(0.08), Colors.red.withOpacity(0.04)],
                                    ),
                                    borderRadius: BorderRadius.circular(14.r),
                                    border: Border.all(
                                      color: isDark ? Colors.red[400]!.withOpacity(0.23) : Colors.red.withOpacity(0.17),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.play_circle_fill_rounded, color: isDark ? Colors.red[300] : Colors.red[700], size: 23.sp),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: Text(
                                          video,
                                          style: TextStyle(
                                            color: isDark ? Colors.red[200] : Colors.red[700],
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            height: 1.4,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Helper ---
String formatTime(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final mins = totalMinutes % 60;
  if (hours > 0) {
    return mins > 0 ? '$hours hr $mins min' : '$hours hr';
  } else {
    return '$mins min';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/widgets/recipe_common_widgets.dart';
import '/theme/app_theme.dart';
import '/models/recipe_detail.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';

class RecipePage extends ConsumerWidget {
  final RecipeDetail recipe;
  const RecipePage({Key? key, required this.recipe}) : super(key: key);

@override
Widget build(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  //void openWebView(String url) => showRecipeWebView(context, url);

  // Fallbacks
  final imageUrl = recipe.image ?? '';
  final title = recipe.title ?? 'No Title';
  final summary = recipe.summary ?? '';
  final website = recipe.sourceUrl ?? '';
  final dishTypes = recipe.dishTypes;
  final servings = recipe.servings ?? 0;
  final healthScore = recipe.healthScore ?? 0.0;
  final pricePerServing = recipe.pricePerServing ?? 0.0;
  final spoonacularScore = recipe.spoonacularScore ?? 0.0;

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
        label: Text("Mark as Cooked", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.sp)),
        onPressed: () {
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
        if (imageUrl.isNotEmpty)
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
          ),
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 70.h),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.all(10.w),
                    child: RecipeImageCard(imageUrl: imageUrl, isDark: isDark),
                  ),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RecipeTitle(title: title),
                      SizedBox(height: 6.h),

                      if (summary.isNotEmpty)
                        HtmlSummaryText(html: summary),
                      SizedBox(height: 10.h),

                      if (recipe.healthScore != null && recipe.pricePerServing != null && recipe.spoonacularScore != null)
                        RecipeStatsRow(
                          healthScore: healthScore,
                          pricePerServing: pricePerServing,
                          spoonacularScore: spoonacularScore,
                        ),
                      SizedBox(height: 10.h),

                      if (recipe.nutrition?.caloricBreakdown != null)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: CaloricBreakdownWidget(
                            breakdown: recipe.nutrition?.caloricBreakdown,
                            glutenFree: recipe.glutenFree,
                            dairyFree: recipe.dairyFree,
                            weightPerServing: recipe.nutrition?.toJson()['weightPerServing'],
                            isDark: isDark,
                          ),
                        ),
                      SizedBox(height: 10.h),
                      
                      if (dishTypes.isNotEmpty)
                        Center(
                          child: InfoChip(
                            icon: Icons.restaurant_rounded,
                            text: dishTypes.join(', ').replaceFirstMapped(RegExp(r'^\w'), (m) => m.group(0)!.toUpperCase()),
                            isDark: isDark,
                          ),
                        ),
                      SizedBox(height: 7.h),

                      if (servings > 0)
                        Center(
                          child: InfoChip(
                            icon: Icons.people_rounded,
                            text: 'Serves $servings',
                            isDark: isDark,
                          ),
                        ),
                      SizedBox(height: 10.h),

                      // INGREDIENTS
                      if (recipe.extendedIngredients.isNotEmpty) ...[
                        SectionHeader(title: 'Ingredients', icon: Icons.list_alt_rounded, isDark: isDark),
                        SizedBox(height: 10.h),
                        Column(
                          children: recipe.extendedIngredients
                              .map((ingredient) => ExtendedIngredientCard(ingredient: ingredient, isDark: isDark))
                              .toList(),
                        ),
                        SizedBox(height: 25.h),
                      ],

                      // INSTRUCTIONS
                      if (recipe.analyzedInstructions.isNotEmpty) ...[
                        SectionHeader(title: 'Instructions', icon: Icons.format_list_numbered_rounded, isDark: isDark),
                        SizedBox(height: 10.h),
                        InstructionsList(
                          instructions: recipe.analyzedInstructions.expand((instr) => instr.steps).toList(),
                          isDark: isDark,
                        ),
                        SizedBox(height: 22.h),
                      ],

                      // EQUIPMENT
                      if (recipe.analyzedInstructions.isNotEmpty) ...[
                        SectionHeader(title: 'Equipment', icon: Icons.kitchen_rounded, isDark: isDark),
                        SizedBox(height: 10.h),
                        EquipmentChips(
                          equipment: recipe.analyzedInstructions
                              .expand((instr) => instr.steps)
                              .expand((step) => step.equipment
                                  .map((e) => e['name'])
                                  .whereType<String>())
                              .toSet()
                              .toList(),
                          isDark: isDark,
                        ),
                        SizedBox(height: 25.h),
                      ],

                      // NUTRITION
                      if (recipe.nutrition != null)
                        NutritionSection(
                          nutrition: recipe.nutrition!.toJson(),
                          showAllNutrients: true,
                        ),

                      // WEBSITE LINK
                      if (website.isNotEmpty) ...[
                        WebsiteLinkCard(
                          url: website,
                          isDark: isDark,
                          onTap: (url) => showRecipeWebView(context, url),
                        ),
                        if (website.startsWith('http://'))
                          HttpWarningCard(isDark: isDark),
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

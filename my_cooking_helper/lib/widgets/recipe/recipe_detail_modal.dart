// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/models/recipe.dart';
import 'recipe_common_widgets.dart';
import 'recipe_page_widgets.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark 
        ? const Color(0xFF1A1A1A).withOpacity(0.98)
        : Colors.white.withOpacity(0.98);

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      maxChildSize: 0.98,
      minChildSize: 0.60,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          child: Container(
            color: backgroundColor,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 50.w,
                      height: 5.h,
                      margin: EdgeInsets.only(bottom: 24.h),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  // IMAGE
                  if (recipe.imageUrl.isNotEmpty)
                    RecipeImageCard(imageUrl: recipe.imageUrl, isDark: isDark,),
                    
                  // TITLE
                  Center(child: RecipeTitle(title: recipe.title)),
                  SizedBox(height: 15.h),

                  // DISH TYPE (one line)
                  if (recipe.dishTypes.isNotEmpty)
                    Center(
                      child: InfoChip(
                        icon: Icons.restaurant_rounded, 
                        text: recipe.dishTypes.join(', ').replaceFirstMapped(
                            RegExp(r'^\w'),
                            (m) => m.group(0)!.toUpperCase(),
                          ), 
                        isDark: isDark
                      ),
                    ),
                  SizedBox(height: 7.h),

                  // SERVINGS (separate line)
                  if (recipe.servings > 0)
                    Center(
                      child: InfoChip(
                        icon: Icons.people_rounded, 
                        text: 'Serves ${recipe.servings}', 
                        isDark: isDark
                      ),
                    ),
                  SizedBox(height: 10.h),

                  // TIMES: prep/cook/total (horizontal row, centered, with separators)
                  TimeRow(
                    recipe: recipe, 
                    isDark: isDark, 
                    formatTime: formatTime
                  ),
                  SizedBox(height: 25.h),

                  // INGREDIENTS SECTION
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

                  // INSTRUCTIONS SECTION (as in your style)
                  if (recipe.instructions.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Instructions', 
                      icon: Icons.format_list_numbered_rounded, 
                      isDark: isDark
                    ),
                    SizedBox(height: 20.h),
                    InstructionsList(instructions: recipe.instructions, isDark: isDark),
                    SizedBox(height: 25.h),
                  ],

                  // EQUIPMENT SECTION
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
                  if (recipe.nutrition != null && recipe.nutrition!.isNotEmpty) ...[
                    NutritionSection(nutrition: recipe.nutrition!),
                    SizedBox(height: 35.h),
                  ],
                  
                  // Website Link
                  if (recipe.website.isNotEmpty) ...[
                    WebsiteLinkCard(
                      url: recipe.website,
                      isDark: isDark,
                      onTap: (url) => showRecipeWebView(context, url),
                    ),
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
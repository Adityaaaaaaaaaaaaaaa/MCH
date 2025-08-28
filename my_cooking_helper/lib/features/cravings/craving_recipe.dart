// lib/features/cravings/craving_recipe_page.dart
// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/models/cravings.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/theme/app_theme.dart';
import '/widgets/cravings/craving_recipe_widgets.dart';

class CravingRecipePage extends StatelessWidget {
  const CravingRecipePage({
    super.key,
    required this.recipe,
    this.previewImageBytes,
  });

  /// Full recipe from Firestore (already hydrated in your flow)
  final CravingRecipeModel recipe;

  /// Optional preview image bytes (from the list card, memory-only)
  final Uint8List? previewImageBytes;

  // Convert a data URL -> bytes (when you only have imageDataUrl on the model)
  Uint8List? _bytesFromDataUrl(String? dataUrl) {
    if (dataUrl == null || dataUrl.isEmpty) return null;
    try {
      final uri = Uri.parse(dataUrl);
      final data = uri.data; // UriData?
      if (data == null) return null;
      return Uint8List.fromList(data.contentAsBytes());
    } catch (_) {
      return null;
    }
  }

  /// minutes → “xh ym”
  String formatHm(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0 && m > 0) return '$h hr $m min';
    if (h > 0) return '$h hr';
    return '$m min';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = bgColor(context);

    // choose image in priority order:
    // 1) passed preview bytes  2) hydrated model imageDataUrl  3) none
    final bytes = previewImageBytes ?? _bytesFromDataUrl(recipe.imageDataUrl);

    return Scaffold(
      backgroundColor: bg,
      extendBody: true,
      extendBodyBehindAppBar: true,
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(
        title: "~ Your Craving ~",
        showMenu: false,
        themeToggleWidget: ThemeToggleButton(),
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
      ),
      body: Stack(
        children: [
          // Soft gradient backdrop
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [bg.withOpacity(1.0), bg.withOpacity(0.92)]
                      : [bg.withOpacity(1.0), bg.withOpacity(0.96)],
                ),
              ),
            ),
          ),
          // Subtle image texture
          if (bytes != null)
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.065 : 0.085,
                child: Image.memory(bytes, fit: BoxFit.cover),
              ),
            ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 26.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HERO
                  if (bytes != null)
                    Hero(
                      tag: 'craving-hero-${recipe.id}',
                      child: Stack(
                        children: [
                          ModernHeroImage(bytes: bytes),
                          Positioned(
                            left: 12.w,
                            bottom: 12.h,
                            child: ModernTimeBadge(minutes: recipe.readyInMinutes),
                          ),
                        ],
                      )

                    ),
                  if (bytes != null) SizedBox(height: 12.h),

                  // TITLE + META CHIPS
                  ModernSection(
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            recipe.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: textColor(context),
                                  letterSpacing: -0.5,
                                ),
                          ),
                          SizedBox(height: 8.h),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              // if (recipe.readyInMinutes != null)
                              //   PremiumChip(
                              //     icon: Icons.timer_rounded,
                              //     label: formatHm(recipe.readyInMinutes!),
                              //     isPrimary: true,
                              //   ),
                              if (recipe.vegetarian == true)
                                PremiumChip(icon: Icons.restaurant_rounded, label: "Vegetarian"),
                              if (recipe.vegan == true)
                                PremiumChip(icon: Icons.spa_rounded, label: "Vegan"),
                              if (recipe.glutenFree == true)
                                PremiumChip(icon: Icons.no_food_rounded, label: "Gluten-free"),
                              if (recipe.dairyFree == true)
                                PremiumChip(icon: Icons.free_breakfast_rounded, label: "Dairy-free"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // CUISINES / DIETS
                  if (recipe.cuisines.isNotEmpty || recipe.diets.isNotEmpty)
                    Row(
                      children: [
                        if (recipe.cuisines.isNotEmpty)
                          Expanded(
                            child: ModernSection(
                              title: "Cuisines",
                              icon: Icons.flag_rounded,
                              child: Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 6.w,
                                  runSpacing: 6.h,
                                  children: recipe.cuisines
                                      .map((c) => ModernFlagTag(text: c, emoji: cuisineFlagEmoji(c)))
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                        if (recipe.cuisines.isNotEmpty && recipe.diets.isNotEmpty) SizedBox(width: 8.w),
                        if (recipe.diets.isNotEmpty)
                          Expanded(
                            child: ModernSection(
                              title: "Diets",
                              icon: Icons.emoji_food_beverage_rounded,
                              child: Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 6.w,
                                  runSpacing: 6.h,
                                  children: recipe.diets.map((d) => ModernPillTag(text: d)).toList(),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (recipe.cuisines.isNotEmpty || recipe.diets.isNotEmpty)
                    SizedBox(height: 10.h),

                  // SUMMARY
                  if ((recipe.summary ?? '').isNotEmpty)
                    ModernSection(
                      title: "Summary",
                      icon: Icons.description_rounded,
                      child: Text(
                        recipe.summary!,
                        textAlign: TextAlign.justify,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: textColor(context).withOpacity(0.92),
                            ),
                      ),
                    ),
                  if ((recipe.summary ?? '').isNotEmpty) SizedBox(height: 10.h),

                  // Why this fits
                  if (recipe.reasons.isNotEmpty)
                    ModernSection(
                      title: "Why this fits",
                      icon: Icons.thumb_up_alt_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: recipe.reasons.map((r) => ModernBulletPoint(text: r)).toList(),
                      ),
                    ),
                  if (recipe.reasons.isNotEmpty) SizedBox(height: 10.h),

                  // INGREDIENTS (Unified, shopping button only for tag == 'buy')
                  if (recipe.requiredIngredients.isNotEmpty || recipe.optionalIngredients.isNotEmpty)
                    ModernSection(
                      title: "Ingredients",
                      icon: Icons.list_alt_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...recipe.requiredIngredients.map(
                            (e) => ModernIngredientTile(
                              data: e,
                              initiallyInShopping: false,
                              onToggleShopping: () {
                                // TODO: persist add/remove selection
                              },
                            ),
                          ),
                          if (recipe.optionalIngredients.isNotEmpty) SizedBox(height: 12.h),
                          ...recipe.optionalIngredients.map(
                            (e) => ModernIngredientTile(
                              data: e, // if you want, you may ensure e['tag'] is not 'buy'
                              onToggleShopping: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (recipe.requiredIngredients.isNotEmpty || recipe.optionalIngredients.isNotEmpty)
                    SizedBox(height: 10.h),

                  // Instructions
                  if (recipe.instructions.isNotEmpty)
                    ModernSection(
                      title: "Instructions",
                      icon: Icons.menu_book_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          recipe.instructions.length,
                          (i) => ModernInstructionTile(index: i + 1, text: recipe.instructions[i].toString()),
                        ),
                      ),
                    ),
                  if (recipe.instructions.isNotEmpty) SizedBox(height: 10.h),

                  // Nutrition
                  if (recipe.nutrition != null && recipe.nutrition!.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    ModernSection(
                      title: "Nutrition (approx. per serving)",
                      icon: Icons.health_and_safety_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ModernNutritionChips(nutrition: recipe.nutrition!),

                          SizedBox(height: 15.h),

                          ModernCaloricBreakdownFromNutrition(
                            nutrition: recipe.nutrition ?? {},
                            energyDv: 2000,
                            proteinDv: 50,
                            fatDv: 70,
                            carbsDv: 260,
                            showNote: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 15.h),
                  
                  const AiCautionBarFancy(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

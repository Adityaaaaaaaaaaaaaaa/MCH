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
                  // Glassy hero with parallax-ish feel
                  if (bytes != null)
                    Hero(
                      tag: 'craving-hero-${recipe.id}',
                      child: GlassHeroImage(bytes: bytes),
                    ),
                  if (bytes != null) SizedBox(height: 12.h),

                  // Title + chips
                  GlassSectionFancy(
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              if (recipe.readyInMinutes != null)
                                TinyChipFancy(
                                  icon: Icons.timer_rounded,
                                  label: formatHm(recipe.readyInMinutes!),
                                  tone: ChipTone.primary,
                                ),
                              if (recipe.vegetarian == true)
                                TinyChipFancy(icon: Icons.eco_rounded, label: "Vegetarian"),
                              if (recipe.vegan == true)
                                TinyChipFancy(icon: Icons.spa_rounded, label: "Vegan"),
                              if (recipe.glutenFree == true)
                                TinyChipFancy(icon: Icons.no_food_rounded, label: "Gluten-free"),
                              if (recipe.dairyFree == true)
                                TinyChipFancy(icon: Icons.free_breakfast_rounded, label: "Dairy-free"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Cuisines / Diets
                  if (recipe.cuisines.isNotEmpty || recipe.diets.isNotEmpty)
                    Row(
                      children: [
                        if (recipe.cuisines.isNotEmpty)
                          Expanded(
                            child: GlassSectionFancy(
                              title: "Cuisines",
                              child: Wrap(
                                spacing: 6.w,
                                runSpacing: 6.h,
                                children: recipe.cuisines
                                    .map((c) => FlagTagFancy(text: c, emoji: cuisineFlagEmoji(c)))
                                    .toList(),
                              ),
                            ),
                          ),
                        if (recipe.cuisines.isNotEmpty && recipe.diets.isNotEmpty)
                          SizedBox(width: 8.w),
                        if (recipe.diets.isNotEmpty)
                          Expanded(
                            child: GlassSectionFancy(
                              title: "Diets",
                              child: Wrap(
                                spacing: 6.w,
                                runSpacing: 6.h,
                                children: recipe.diets.map((d) => PillTagFancy(text: d)).toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (recipe.cuisines.isNotEmpty || recipe.diets.isNotEmpty)
                    SizedBox(height: 10.h),

                  // Summary
                  if ((recipe.summary ?? '').isNotEmpty)
                    GlassSectionFancy(
                      title: "Summary",
                      child: Text(
                        recipe.summary!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: textColor(context).withOpacity(0.92),
                            ),
                      ),
                    ),
                  if ((recipe.summary ?? '').isNotEmpty) SizedBox(height: 10.h),

                  // Why this fits
                  if (recipe.reasons.isNotEmpty)
                    GlassSectionFancy(
                      title: "Why this fits",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: recipe.reasons.map((r) => BulletLineFancy(text: r)).toList(),
                      ),
                    ),
                  if (recipe.reasons.isNotEmpty) SizedBox(height: 10.h),

                  // Ingredients
                  if (recipe.requiredIngredients.isNotEmpty || recipe.optionalIngredients.isNotEmpty)
                    GlassSectionFancy(
                      title: "Ingredients",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (recipe.requiredIngredients.isNotEmpty) ...[
                            SubHeaderFancy("Required"),
                            SizedBox(height: 6.h),
                            ...recipe.requiredIngredients.map((e) => IngredientTileFancy(data: e)),
                          ],
                          if (recipe.optionalIngredients.isNotEmpty) ...[
                            SizedBox(height: 12.h),
                            SubHeaderFancy("Optional"),
                            SizedBox(height: 6.h),
                            ...recipe.optionalIngredients.map((e) => IngredientTileFancy(data: e)),
                          ],
                        ],
                      ),
                    ),
                  if (recipe.requiredIngredients.isNotEmpty || recipe.optionalIngredients.isNotEmpty)
                    SizedBox(height: 10.h),

                  // Instructions
                  if (recipe.instructions.isNotEmpty)
                    GlassSectionFancy(
                      title: "Instructions",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          recipe.instructions.length,
                          (i) => InstructionTileFancy(index: i + 1, text: recipe.instructions[i].toString()),
                        ),
                      ),
                    ),
                  if (recipe.instructions.isNotEmpty) SizedBox(height: 10.h),

                  // Shopping list
                  if (recipe.shopping.isNotEmpty)
                    GlassSectionFancy(
                      title: "Shopping",
                      child: Column(
                        children: recipe.shopping.map((s) => ShoppingTileFancy(item: s)).toList(),
                      ),
                    ),
                  if (recipe.shopping.isNotEmpty) SizedBox(height: 10.h),

                  // Nutrition
                  if (recipe.nutrition != null && recipe.nutrition!.isNotEmpty)
                    GlassSectionFancy(
                      title: "Nutrition (approx. per serving)",
                      child: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          if (recipe.nutrition!['calories'] != null)
                            TinyChipFancy(icon: Icons.local_fire_department_rounded, label: "${recipe.nutrition!['calories']} kcal"),
                          if (recipe.nutrition!['protein_g'] != null)
                            TinyChipFancy(icon: Icons.egg_alt_rounded, label: "${recipe.nutrition!['protein_g']} g protein"),
                          if (recipe.nutrition!['fat_g'] != null)
                            TinyChipFancy(icon: Icons.water_drop_rounded, label: "${recipe.nutrition!['fat_g']} g fat"),
                          if (recipe.nutrition!['carbs_g'] != null)
                            TinyChipFancy(icon: Icons.bakery_dining_rounded, label: "${recipe.nutrition!['carbs_g']} g carbs"),
                        ],
                      ),
                    ),

                  SizedBox(height: 14.h),
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

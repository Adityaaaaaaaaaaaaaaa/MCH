// lib/features/cravings/craving_recipe_page.dart
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
          // faint background image/gradient for atmosphere
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [bg.withOpacity(0.95), bg.withOpacity(0.75)]
                      : [bg.withOpacity(0.98), bg.withOpacity(0.85)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          if (bytes != null)
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.07 : 0.10,
                child: Image.memory(bytes, fit: BoxFit.cover),
              ),
            ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 22.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero image card (glassy)
                  if (bytes != null)
                    Hero(
                      tag: 'craving-hero-${recipe.id}',
                      child: GlassHeroImage(bytes: bytes),
                    ),
                  SizedBox(height: 12.h),

                  // Title + meta chips (time + diet flags)
                  GlassSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: textColor(context),
                              ),
                        ),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            if (recipe.readyInMinutes != null)
                              TinyChip(
                                icon: Icons.timer_rounded,
                                text: formatHm(recipe.readyInMinutes!),
                              ),
                            if (recipe.vegetarian == true)
                              TinyChip(icon: Icons.eco_rounded, text: "Vegetarian"),
                            if (recipe.vegan == true)
                              TinyChip(icon: Icons.spa_rounded, text: "Vegan"),
                            if (recipe.glutenFree == true)
                              TinyChip(icon: Icons.no_food_rounded, text: "Gluten-free"),
                            if (recipe.dairyFree == true)
                              TinyChip(icon: Icons.free_breakfast_rounded, text: "Dairy-free"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Cuisines + Diets
                  if (recipe.cuisines.isNotEmpty || recipe.diets.isNotEmpty)
                    Row(
                      children: [
                        if (recipe.cuisines.isNotEmpty)
                          Expanded(
                            child: GlassSection(
                              title: "Cuisines",
                              child: Wrap(
                                spacing: 6.w,
                                runSpacing: 6.h,
                                children: recipe.cuisines
                                    .map((c) => FlagTag(text: c, emoji: cuisineFlagEmoji(c)))
                                    .toList(),
                              ),
                            ),
                          ),
                        if (recipe.cuisines.isNotEmpty && recipe.diets.isNotEmpty)
                          SizedBox(width: 8.w),
                        if (recipe.diets.isNotEmpty)
                          Expanded(
                            child: GlassSection(
                              title: "Diets",
                              child: Wrap(
                                spacing: 6.w,
                                runSpacing: 6.h,
                                children: recipe.diets.map((d) => PillTag(text: d)).toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (recipe.cuisines.isNotEmpty || recipe.diets.isNotEmpty)
                    SizedBox(height: 10.h),

                  // Summary
                  if ((recipe.summary ?? '').isNotEmpty)
                    GlassSection(
                      title: "Summary",
                      child: Text(
                        recipe.summary!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.35,
                              color: textColor(context).withOpacity(0.92),
                            ),
                      ),
                    ),
                  if ((recipe.summary ?? '').isNotEmpty) SizedBox(height: 10.h),

                  // Why this fits
                  if (recipe.reasons.isNotEmpty)
                    GlassSection(
                      title: "Why this fits",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: recipe.reasons
                            .map((r) => BulletLine(text: r))
                            .toList(),
                      ),
                    ),
                  if (recipe.reasons.isNotEmpty) SizedBox(height: 10.h),

                  // Ingredients
                  if (recipe.requiredIngredients.isNotEmpty || recipe.optionalIngredients.isNotEmpty)
                    GlassSection(
                      title: "Ingredients",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (recipe.requiredIngredients.isNotEmpty) ...[
                            SubHeader("Required"),
                            SizedBox(height: 6.h),
                            ...recipe.requiredIngredients.map((e) => IngredientTile(data: e)),
                          ],
                          if (recipe.optionalIngredients.isNotEmpty) ...[
                            SizedBox(height: 10.h),
                            SubHeader("Optional"),
                            SizedBox(height: 6.h),
                            ...recipe.optionalIngredients.map((e) => IngredientTile(data: e)),
                          ],
                        ],
                      ),
                    ),
                  if (recipe.requiredIngredients.isNotEmpty || recipe.optionalIngredients.isNotEmpty)
                    SizedBox(height: 10.h),

                  // Instructions
                  if (recipe.instructions.isNotEmpty)
                    GlassSection(
                      title: "Instructions",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          recipe.instructions.length,
                          (i) => InstructionTile(index: i + 1, text: recipe.instructions[i].toString()),
                        ),
                      ),
                    ),
                  if (recipe.instructions.isNotEmpty) SizedBox(height: 10.h),

                  // Shopping list
                  if (recipe.shopping.isNotEmpty)
                    GlassSection(
                      title: "Shopping",
                      child: Column(
                        children: recipe.shopping.map((s) => ShoppingTile(item: s)).toList(),
                      ),
                    ),
                  if (recipe.shopping.isNotEmpty) SizedBox(height: 10.h),

                  // Nutrition
                  if (recipe.nutrition != null && recipe.nutrition!.isNotEmpty)
                    GlassSection(
                      title: "Nutrition (approx. per serving)",
                      child: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          if (recipe.nutrition!['calories'] != null)
                            TinyChip(icon: Icons.local_fire_department_rounded, text: "${recipe.nutrition!['calories']} kcal"),
                          if (recipe.nutrition!['protein_g'] != null)
                            TinyChip(icon: Icons.egg_alt_rounded, text: "${recipe.nutrition!['protein_g']} g protein"),
                          if (recipe.nutrition!['fat_g'] != null)
                            TinyChip(icon: Icons.water_drop_rounded, text: "${recipe.nutrition!['fat_g']} g fat"),
                          if (recipe.nutrition!['carbs_g'] != null)
                            TinyChip(icon: Icons.bakery_dining_rounded, text: "${recipe.nutrition!['carbs_g']} g carbs"),
                        ],
                      ),
                    ),

                  SizedBox(height: 14.h),
                  const AiCautionBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// lib/features/cravings/craving_recipe_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/models/cravings.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/theme/app_theme.dart';

class CravingRecipePage extends StatelessWidget {
  final CravingRecipeModel recipe;
  const CravingRecipePage({super.key, required this.recipe});

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imgBytes = _bytesFromDataUrl(recipe.imageDataUrl);

    return Scaffold(
      backgroundColor: bgColor(context),
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE
              if (imgBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(18.r),
                  child: Image.memory(
                    imgBytes,
                    height: 220.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 14.h),
              ],

              // TITLE + META
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
                    _chip(context, Icons.timer_rounded, "${recipe.readyInMinutes} min", isDark),
                  if (recipe.vegetarian == true) _chip(context, Icons.eco_rounded, "Vegetarian", isDark),
                  if (recipe.vegan == true) _chip(context, Icons.spa_rounded, "Vegan", isDark),
                  if (recipe.glutenFree == true) _chip(context, Icons.no_food_rounded, "Gluten-free", isDark),
                  if (recipe.dairyFree == true) _chip(context, Icons.free_breakfast_rounded, "Dairy-free", isDark),
                ],
              ),
              SizedBox(height: 12.h),

              // CUISINES / DIETS
              if (recipe.cuisines.isNotEmpty || recipe.diets.isNotEmpty) ...[
                Row(
                  children: [
                    if (recipe.cuisines.isNotEmpty)
                      Expanded(
                        child: _sectionBox(
                          context,
                          title: "Cuisines",
                          child: Wrap(
                            spacing: 6.w,
                            runSpacing: 6.h,
                            children: recipe.cuisines
                                .map((c) => _smallTag(context, c, isDark))
                                .toList(),
                          ),
                        ),
                      ),
                    if (recipe.diets.isNotEmpty) SizedBox(width: 10.w),
                    if (recipe.diets.isNotEmpty)
                      Expanded(
                        child: _sectionBox(
                          context,
                          title: "Diets",
                          child: Wrap(
                            spacing: 6.w,
                            runSpacing: 6.h,
                            children: recipe.diets
                                .map((d) => _smallTag(context, d, isDark))
                                .toList(),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
              ],

              // SUMMARY
              if ((recipe.summary ?? '').isNotEmpty)
                _sectionBox(
                  context,
                  title: "Summary",
                  child: Text(
                    recipe.summary!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                          color: textColor(context).withOpacity(0.90),
                        ),
                  ),
                ),
              if ((recipe.summary ?? '').isNotEmpty) SizedBox(height: 12.h),

              // WHY THIS FITS
              if (recipe.reasons.isNotEmpty)
                _sectionBox(
                  context,
                  title: "Why this fits",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: recipe.reasons
                        .map((r) => Padding(
                              padding: EdgeInsets.only(bottom: 6.h),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("• "),
                                  Expanded(
                                    child: Text(
                                      r,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: textColor(context).withOpacity(0.95),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              if (recipe.reasons.isNotEmpty) SizedBox(height: 12.h),

              // INGREDIENTS
              if (recipe.requiredIngredients.isNotEmpty || recipe.optionalIngredients.isNotEmpty)
                _sectionBox(
                  context,
                  title: "Ingredients",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (recipe.requiredIngredients.isNotEmpty) ...[
                        Text("Required", style: Theme.of(context).textTheme.titleSmall),
                        SizedBox(height: 6.h),
                        ...recipe.requiredIngredients.map((e) => _bulletLine(context, _formatIng(e))),
                      ],
                      if (recipe.optionalIngredients.isNotEmpty) ...[
                        SizedBox(height: 10.h),
                        Text("Optional", style: Theme.of(context).textTheme.titleSmall),
                        SizedBox(height: 6.h),
                        ...recipe.optionalIngredients.map((e) => _bulletLine(context, _formatIng(e))),
                      ],
                    ],
                  ),
                ),
              if (recipe.requiredIngredients.isNotEmpty || recipe.optionalIngredients.isNotEmpty) SizedBox(height: 12.h),

              // INSTRUCTIONS
              if (recipe.instructions.isNotEmpty)
                _sectionBox(
                  context,
                  title: "Instructions",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      recipe.instructions.length,
                      (i) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${i + 1}. "),
                            Expanded(child: Text(recipe.instructions[i].toString())),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (recipe.instructions.isNotEmpty) SizedBox(height: 12.h),

              // SHOPPING LIST
              if (recipe.shopping.isNotEmpty)
                _sectionBox(
                  context,
                  title: "Shopping",
                  child: Column(
                    children: recipe.shopping.map((s) {
                      final need = s.need.toStringAsFixed(s.need % 1 == 0 ? 0 : 1);
                      final have = s.have.toStringAsFixed(s.have % 1 == 0 ? 0 : 1);
                      final tagColor = s.tag == 'missing'
                          ? Colors.amber[700]
                          : Theme.of(context).colorScheme.tertiary;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text("${s.name} • $need ${s.unit}"),
                        subtitle: Text("have: $have ${s.unit}"),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            color: tagColor?.withOpacity(0.15),
                            border: Border.all(color: tagColor ?? Colors.grey),
                          ),
                          child: Text(
                            s.tag,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: tagColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              if (recipe.shopping.isNotEmpty) SizedBox(height: 12.h),

              // NUTRITION (simple)
              if (recipe.nutrition != null && recipe.nutrition!.isNotEmpty)
                _sectionBox(
                  context,
                  title: "Nutrition (per serving, approx.)",
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      if (recipe.nutrition!['calories'] != null)
                        _chip(context, Icons.local_fire_department_rounded,
                            "${recipe.nutrition!['calories']} kcal", isDark),
                      if (recipe.nutrition!['protein_g'] != null)
                        _chip(context, Icons.egg_alt_rounded,
                            "${recipe.nutrition!['protein_g']} g protein", isDark),
                      if (recipe.nutrition!['fat_g'] != null)
                        _chip(context, Icons.water_drop_rounded,
                            "${recipe.nutrition!['fat_g']} g fat", isDark),
                      if (recipe.nutrition!['carbs_g'] != null)
                        _chip(context, Icons.bakery_dining_rounded,
                            "${recipe.nutrition!['carbs_g']} g carbs", isDark),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- tiny UI helpers ---
  Widget _chip(BuildContext ctx, IconData icon, String text, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: textColor(ctx).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: textColor(ctx)),
          SizedBox(width: 6.w),
          Text(text, style: TextStyle(color: textColor(ctx))),
        ],
      ),
    );
  }

  Widget _smallTag(BuildContext ctx, String text, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: textColor(ctx).withOpacity(0.08),
      ),
      child: Text(text, style: TextStyle(fontSize: 12.sp)),
    );
  }

  Widget _sectionBox(BuildContext ctx, {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: textColor(ctx).withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }

  Widget _bulletLine(BuildContext ctx, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• "),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _formatIng(dynamic e) {
    // data shape from your Firestore:
    // {name, quantity, unit, canonical, pantryLikely} OR sometimes string
    if (e is String) return e;
    if (e is Map) {
      final name = (e['name'] ?? '').toString();
      final q = (e['quantity'] as num?)?.toDouble();
      final unit = (e['unit'] ?? '').toString();
      if (q == null || q == 0) return name;
      final qStr = q % 1 == 0 ? q.toStringAsFixed(0) : q.toString();
      return unit.isEmpty ? "$name — $qStr" : "$name — $qStr $unit";
    }
    return e.toString();
  }
}

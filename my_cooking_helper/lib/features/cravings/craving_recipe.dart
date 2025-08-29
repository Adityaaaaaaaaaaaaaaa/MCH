// lib/features/cravings/craving_recipe_page.dart
// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/services/cravings_recipe_service.dart';
import '/models/cravings.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/theme/app_theme.dart';
import '/widgets/cravings/craving_recipe_widgets.dart';

enum _ShopVariant { bag, plus }

class CravingRecipePage extends StatefulWidget {
  const CravingRecipePage({
    super.key,
    required this.recipe,
    this.previewImageBytes,
    this.openedFromHistory = false, // NEW
    this.recipeKey,                 
  });

  /// Full recipe from Firestore (already hydrated in your flow)
  final CravingRecipeModel recipe;

  /// Optional preview image bytes (from the list card, memory-only)
  final Uint8List? previewImageBytes;

  final bool openedFromHistory;
  final String? recipeKey;


  @override
  State<CravingRecipePage> createState() => _CravingRecipePageState();
}

class _CravingRecipePageState extends State<CravingRecipePage> {
  final ValueNotifier<int> selectAllSignal = ValueNotifier<int>(0);
  final ValueNotifier<int> selectionDirtySignal = ValueNotifier<int>(0);
  final ValueNotifier<int> selectedCount = ValueNotifier<int>(0);

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

  // ignore: unused_element
  String _nameOf(dynamic e) {
    if (e == null) return '';
    if (e is String) return e;
    if (e is Map) {
      if (e['name'] != null) return e['name'].toString();
      if (e['original'] != null) return e['original'].toString();
      if (e['title'] != null) return e['title'].toString();
      return e.toString();
    }
    if (e is ShoppingItemModel) return e.name;
    return e.toString();
  }

  @override
  void dispose() {
    selectAllSignal.dispose();
    selectionDirtySignal.dispose();
    selectedCount.dispose();
    super.dispose();
  }

  // ignore: unused_element
  _ShopVariant _variantFor(dynamic e) {
    // mirror tile logic: bag if in shopping('buy'), else plus
    String name = "";

    if (e is String) {
      name = e;
    } else if (e is ShoppingItemModel) {
      name = e.name;
    } else if (e is Map) {
      name = (e['name'] ?? '').toString();
    }

    final s = widget.recipe.shopping.firstWhere(
      (x) => x.name.trim().toLowerCase() == name.trim().toLowerCase(),
      orElse: () => ShoppingItemModel(name: '', need: 0, unit: 'count', have: 0, tag: ''),
    );

    if (s.name.isNotEmpty && s.tag.toLowerCase() == 'buy') {
      return _ShopVariant.bag;
    }
    return _ShopVariant.plus;
  }

  int _eligibleCount() {
    return widget.recipe.requiredIngredients.length + widget.recipe.optionalIngredients.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = bgColor(context);
    final eligible = _eligibleCount();

    // choose image in priority order:
    // 1) passed preview bytes  2) hydrated model imageDataUrl  3) none
    final bytes = widget.previewImageBytes ?? _bytesFromDataUrl(widget.recipe.imageDataUrl);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final recipeKey = widget.recipeKey ?? CravingsRecipeService.computeRecipeKey(widget.recipe);

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
                  colors: isDark ? [bg.withOpacity(1.0), bg.withOpacity(0.92)] : [bg.withOpacity(1.0), bg.withOpacity(0.96)],
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
                      tag: 'craving-hero-${widget.recipe.id}',
                      child: Stack(
                        children: [
                          ModernHeroImage(bytes: bytes),
                          Positioned(
                            left: 12.w,
                            bottom: 12.h,
                            child: ModernTimeBadge(minutes: widget.recipe.readyInMinutes),
                          ),
                        ],
                      ),
                    ),
                  if (bytes != null) SizedBox(height: 12.h),

                  // TITLE + META CHIPS
                  ModernSection(
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.recipe.title,
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
                              if (bytes == null ) ModernTimeBadge(minutes: widget.recipe.readyInMinutes),
                              if (widget.recipe.vegetarian == true) PremiumChip(icon: Icons.restaurant_rounded, label: "Vegetarian"),
                              if (widget.recipe.vegan == true) PremiumChip(icon: Icons.spa_rounded, label: "Vegan"),
                              if (widget.recipe.glutenFree == true) PremiumChip(icon: Icons.no_food_rounded, label: "Gluten-free"),
                              if (widget.recipe.dairyFree == true) PremiumChip(icon: Icons.free_breakfast_rounded, label: "Dairy-free"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // CUISINES / DIETS
                  if (widget.recipe.cuisines.isNotEmpty || widget.recipe.diets.isNotEmpty)
                    Row(
                      children: [
                        if (widget.recipe.cuisines.isNotEmpty)
                          Expanded(
                            child: ModernSection(
                              title: "Cuisines",
                              icon: Icons.flag_rounded,
                              child: Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 6.w,
                                  runSpacing: 6.h,
                                  children: widget.recipe.cuisines.map((c) => ModernFlagTag(text: c, emoji: cuisineFlagEmoji(c))).toList(),
                                ),
                              ),
                            ),
                          ),
                        if (widget.recipe.cuisines.isNotEmpty && widget.recipe.diets.isNotEmpty) SizedBox(width: 8.w),
                        if (widget.recipe.diets.isNotEmpty)
                          Expanded(
                            child: ModernSection(
                              title: "Diets",
                              icon: Icons.emoji_food_beverage_rounded,
                              child: Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 6.w,
                                  runSpacing: 6.h,
                                  children: widget.recipe.diets.map((d) => ModernPillTag(text: d)).toList(),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (widget.recipe.cuisines.isNotEmpty || widget.recipe.diets.isNotEmpty) SizedBox(height: 10.h),

                  // SUMMARY
                  if ((widget.recipe.summary ?? '').isNotEmpty)
                    ModernSection(
                      title: "Summary",
                      icon: Icons.description_rounded,
                      child: Text(
                        widget.recipe.summary!,
                        textAlign: TextAlign.justify,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: textColor(context).withOpacity(0.92),
                            ),
                      ),
                    ),
                  if ((widget.recipe.summary ?? '').isNotEmpty) SizedBox(height: 10.h),

                  // Why this fits
                  if (widget.recipe.reasons.isNotEmpty)
                    ModernSection(
                      title: "Why this fits",
                      icon: Icons.thumb_up_alt_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.recipe.reasons.map((r) => ModernBulletPoint(text: r)).toList(),
                      ),
                    ),
                  if (widget.recipe.reasons.isNotEmpty) SizedBox(height: 10.h),

                  // INGREDIENTS (Unified, shopping button only for tag == 'buy')
                  if (widget.recipe.requiredIngredients.isNotEmpty || widget.recipe.optionalIngredients.isNotEmpty)
                    ModernSection(
                      title: "Ingredients",
                      icon: Icons.list_alt_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Required ingredients
                          ...widget.recipe.requiredIngredients.map(
                            (e) => ModernIngredientTile(
                              data: e,
                              shopping: widget.recipe.shopping,
                              optionalIngredients: widget.recipe.optionalIngredients,
                              selectAllSignal: selectAllSignal,
                              selectionDirtySignal: selectionDirtySignal,
                              selectionCount: selectedCount, // NEW
                              initiallyInShopping: false, // never auto-activate
                              onToggleShopping: () {}, // hook later
                            ),
                          ),

                          if (widget.recipe.optionalIngredients.isNotEmpty) SizedBox(height: 12.h),

                          // Optional ingredients
                          ...widget.recipe.optionalIngredients.map(
                            (e) => ModernIngredientTile(
                              data: e,
                              shopping: widget.recipe.shopping,
                              optionalIngredients: widget.recipe.optionalIngredients,
                              selectAllSignal: selectAllSignal,
                              selectionDirtySignal: selectionDirtySignal,
                              selectionCount: selectedCount, // NEW
                              initiallyInShopping: false,
                              onToggleShopping: () {},
                            ),
                          ),

                          SizedBox(height: 15.h),
                          ModernCreateShoppingListButton(
                            selectAllSignal: selectAllSignal,
                            selectionDirtySignal: selectionDirtySignal,
                            selectedCount: selectedCount, // NEW
                            eligibleCount: eligible, // NEW
                            onCreate: () {
                              // Persist current selection snapshot (bagSelected/plusSelected) as you prefer.
                              // (No duplicates; tiles are idempotent and you can de-dupe server-side too.)
                            },
                          ),
                        ],
                      ),
                    ),
                  if (widget.recipe.requiredIngredients.isNotEmpty || widget.recipe.optionalIngredients.isNotEmpty)
                    SizedBox(height: 10.h),

                  // Instructions
                  if (widget.recipe.instructions.isNotEmpty)
                    ModernSection(
                      title: "Instructions",
                      icon: Icons.menu_book_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          widget.recipe.instructions.length,
                          (i) => ModernInstructionTile(index: i + 1, text: widget.recipe.instructions[i].toString()),
                        ),
                      ),
                    ),
                  if (widget.recipe.instructions.isNotEmpty) SizedBox(height: 10.h),

                  // Nutrition
                  if (widget.recipe.nutrition != null && widget.recipe.nutrition!.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    ModernSection(
                      title: "Nutrition (approx. per serving)",
                      icon: Icons.health_and_safety_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ModernNutritionChips(nutrition: widget.recipe.nutrition!),
                          SizedBox(height: 15.h),
                          ModernCaloricBreakdownFromNutrition(
                            nutrition: widget.recipe.nutrition ?? {},
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

          // === Real-time action bar (favourite + cooked), driven by providers ===
          Consumer(
            builder: (context, ref, _) {
              final favAsync = ref.watch(cravingFavouriteStatusProvider(recipeKey));
              final cookedSuccess = ref.watch(cravingCookedSuccessProvider(recipeKey));

              return favAsync.when(
                data: (isFavourite) => CravingActionBar(
                  isFavourited: isFavourite,
                  cookedSuccess: cookedSuccess,
                  onFavourite: () async {
                    if (uid == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Please log in to use Favourites."),
                          backgroundColor: Colors.red[600],
                        ),
                      );
                      return;
                    }
                    await CravingsRecipeService.updateFavouriteStatus(
                      uid: uid,
                      recipe: widget.recipe,
                      isFavourite: !isFavourite,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(!isFavourite ? "Added to Favourites!" : "Removed from Favourites."),
                        backgroundColor: !isFavourite ? Colors.pink[400] : Colors.grey[600],
                      ),
                    );
                  },
                  onMarkCooked: () async {
                    if (uid == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Please log in to mark as cooked."),
                          backgroundColor: Colors.red[600],
                        ),
                      );
                      return;
                    }
                    await CravingsRecipeService.markAsCooked(
                      uid: uid,
                      recipe: widget.recipe,
                      keepFavourite: isFavourite,
                    );
                    ref.read(cravingCookedSuccessProvider(recipeKey).notifier).state = true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Marked as cooked!"),
                        backgroundColor: Colors.green[600],
                      ),
                    );
                  },
                ),
                loading: () => CravingActionBar(
                  isFavourited: false,
                  cookedSuccess: false,
                  onFavourite: () {},
                  onMarkCooked: () {},
                ),
                error: (e, st) => const Icon(Icons.error, color: Colors.red),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import 'package:my_cooking_helper/utils/colors.dart';
import '/services/recipe_save_service.dart';
import '/services/cravings_recipe_service.dart';
import '/models/recipe_history.dart';

// --- Grouping logic, unchanged ---
class CookedRecipeGroup {
  final String label;
  final List<RecipeHistoryEntry> recipes;
  CookedRecipeGroup({required this.label, required this.recipes});
}

List<CookedRecipeGroup> groupRecipesByRecency(List<RecipeHistoryEntry> recipes) {
  final now = DateTime.now();
  final today = <RecipeHistoryEntry>[];
  final yesterday = <RecipeHistoryEntry>[];
  final week = <RecipeHistoryEntry>[];
  final older = <RecipeHistoryEntry>[];

  for (final r in recipes) {
    if (r.lastCookedAt == null) continue;
    final daysAgo = now.difference(r.lastCookedAt!).inDays;
    if (daysAgo == 0) {
      today.add(r);
    } else if (daysAgo == 1) {
      yesterday.add(r);
    } else if (daysAgo < 7) {
      week.add(r);
    } else {
      older.add(r);
    }
  }

  final groups = <CookedRecipeGroup>[];
  if (today.isNotEmpty) groups.add(CookedRecipeGroup(label: "Today", recipes: today));
  if (yesterday.isNotEmpty) groups.add(CookedRecipeGroup(label: "Yesterday", recipes: yesterday));
  if (week.isNotEmpty) groups.add(CookedRecipeGroup(label: "Earlier this week", recipes: week));
  if (older.isNotEmpty) groups.add(CookedRecipeGroup(label: "Earlier", recipes: older));
  return groups;
}

class CookedRecipeCard extends StatefulWidget {
  final RecipeHistoryEntry recipe;
  final String? imageUrl;
  final void Function()? onTap;
  final bool isAi; // NEW

  const CookedRecipeCard({
    required this.recipe,
    this.imageUrl,
    this.onTap,
    this.isAi = false, // default for backward-compat
    super.key,
  });

  @override
  State<CookedRecipeCard> createState() => _CookedRecipeCardState();
}

class _CookedRecipeCardState extends State<CookedRecipeCard>
    with TickerProviderStateMixin {
  late bool isFavourite;
  late AnimationController _pressController;
  late AnimationController _favoriteController;
  late AnimationController _aiGlowController; // NEW
  late Animation<double> _scaleAnimation;
  late Animation<double> _favoriteScaleAnimation;

  @override
  void initState() {
    super.initState();
    isFavourite = widget.recipe.isFavourite == true;

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _favoriteScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _favoriteController, curve: Curves.elasticOut),
    );

    _aiGlowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pressController.dispose();
    _favoriteController.dispose();
    _aiGlowController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavourite() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Trigger favorite animation
    _favoriteController.forward().then((_) => _favoriteController.reverse());

    final newFav = !isFavourite;
    setState(() => isFavourite = newFav);

    if (!widget.isAi) {
      // Normal recipes (Spoonacular-backed)
      await RecipeSaveService.updateFavouriteStatus(
        recipeId: widget.recipe.recipeId,
        userId: userId,
        isFavourite: newFav,
      );
    } else {
      // AI cravings: toggle by recipeKey (widget.recipe.recipeId == 'ai:<hash>')
      await CravingsRecipeService.updateFavouriteStatusByKey(
        uid: userId,
        recipeKey: widget.recipe.recipeId,
        isFavourite: newFav,
        recipeTitle: widget.recipe.recipeTitle,
        hasImage: widget.imageUrl != null && widget.imageUrl!.isNotEmpty,
        // Optionally, also persist lastSeenSession/tracker if you have them here.
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newFav ? 'Added to Favourites' : 'Removed from Favourites'),
        backgroundColor: newFav ? const Color(0xFFE91E63) : const Color(0xFF6B7280),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  void _onTapDown(TapDownDetails details) => _pressController.forward();
  void _onTapUp(TapUpDetails details) => _pressController.reverse();
  void _onTapCancel() => _pressController.reverse();

  String _formatDate() {
    if (widget.recipe.lastCookedAt == null) return 'Unknown';
    final date = widget.recipe.lastCookedAt!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cardDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(cardDate).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final aiGlow = Tween<double>(begin: 0.15, end: 0.55).animate(
      CurvedAnimation(parent: _aiGlowController, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _aiGlowController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.onTap,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
              child: Stack(
                children: [
                  // Main card container
                  Container(
                    height: 130.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28.r),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF1F2937).withOpacity(0.8),
                                const Color(0xFF111827).withOpacity(0.9),
                              ]
                            : [
                                const Color(0xFFFFFFFF).withOpacity(0.9),
                                const Color(0xFFF8FAFC).withOpacity(0.7),
                              ],
                      ),
                      border: Border.all(
                        color: widget.isAi
                            ? Color.lerp(
                                const Color(0xFF60A5FA), // blue-400
                                const Color(0xFFA78BFA), // violet-400
                                aiGlow.value,
                              )!
                            : (isDark
                                ? const Color(0xFF374151).withOpacity(0.3)
                                : const Color(0xFFE5E7EB).withOpacity(0.5)),
                        width: widget.isAi ? 1.8 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isAi
                              ? Color.lerp(
                                  const Color(0xFF60A5FA).withOpacity(0.35),
                                  const Color(0xFFA78BFA).withOpacity(0.35),
                                  aiGlow.value,
                                )!
                              : (isDark
                                  ? const Color(0xFF000000).withOpacity(0.4)
                                  : const Color(0xFF64748B).withOpacity(0.15)),
                          blurRadius: widget.isAi ? 24 : 20,
                          offset: const Offset(0, 8),
                          spreadRadius: widget.isAi ? 1 : 0,
                        ),
                        BoxShadow(
                          color: isDark
                              ? const Color(0xFF1F2937).withOpacity(0.8)
                              : const Color(0xFFFFFFFF).withOpacity(0.9),
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ).asGlass(
                    tintColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFFFF),
                    clipBorderRadius: BorderRadius.circular(28.r),
                  ),

                  // Content
                  Container(
                    height: 130.h,
                    padding: EdgeInsets.all(18.w),
                    child: Row(
                      children: [
                        // Recipe Image
                        Hero(
                          tag: 'recipe_image_${widget.recipe.recipeId}',
                          child: Container(
                            width: 94.w,
                            height: 94.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? const Color(0xFF000000).withOpacity(0.3)
                                      : const Color(0xFF64748B).withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24.r),
                              child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      widget.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => _fallbackIcon(context),
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: isDark
                                                  ? [const Color(0xFF374151), const Color(0xFF1F2937)]
                                                  : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                                            ),
                                            borderRadius: BorderRadius.circular(24.r),
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : _fallbackIcon(context),
                            ),
                          ),
                        ),

                        SizedBox(width: 18.w),

                        // Content area
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Recipe Title
                              Text(
                                widget.recipe.recipeTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.sp,
                                  color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              SizedBox(height: 12.h),

                              // Date info chip
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDark
                                        ? [const Color(0xFF3B82F6).withOpacity(0.2), const Color(0xFF1D4ED8).withOpacity(0.1)]
                                        : [const Color(0xFF3B82F6).withOpacity(0.1), const Color(0xFF1E40AF).withOpacity(0.05)],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 15, color: Color(0xFF3B82F6)),
                                    SizedBox(width: 5.w),
                                    Flexible( // <-- allow compression
                                      child: Text(
                                        _formatDate(),
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis, // <-- no overflow anymore
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: textColor(context),
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ),
                            ],
                          ),
                        ),

                        // Favorite button
                        Container(
                          margin: EdgeInsets.only(left: 12.w),
                          child: AnimatedBuilder(
                            animation: _favoriteScaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _favoriteScaleAnimation.value,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(22.r),
                                    onTap: _toggleFavourite,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      padding: EdgeInsets.all(14.w),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(22.r),
                                        gradient: isFavourite
                                            ? LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  const Color(0xFFEC4899).withOpacity(0.2),
                                                  const Color(0xFFBE185D).withOpacity(0.1),
                                                ],
                                              )
                                            : null,
                                        border: Border.all(
                                          color: isFavourite
                                              ? const Color(0xFFEC4899).withOpacity(0.3)
                                              : Colors.transparent,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Icon(
                                        isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: isFavourite
                                            ? const Color(0xFFEC4899)
                                            : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                                        size: 24.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // AI chip
                  if (widget.isAi)
                    Positioned(
                      left: 12.w,
                      top: 12.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.r),
                          gradient: LinearGradient(
                            colors: [const Color(0xFF60A5FA).withOpacity(0.2), const Color(0xFFA78BFA).withOpacity(0.2)],
                          ),
                          border: Border.all(
                            color: Color.lerp(const Color(0xFF60A5FA), const Color(0xFFA78BFA), aiGlow.value)!.withOpacity(0.8),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 15.sp, color: Color(0xFF6366F1)),
                            SizedBox(width: 6.w),
                            Text(
                              'AI',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.sp,
                                color: const Color(0xFF3730A3),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Subtle arrow indicator
                  Positioned(
                    right: 12.w,
                    top: 12.h,
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16.sp,
                      color: isDark
                          ? const Color(0xFF6B7280).withOpacity(0.6)
                          : const Color(0xFF9CA3AF).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Fallback icon for when no image is available
  Widget _fallbackIcon(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 94.w,
      height: 94.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? [const Color(0xFF374151), const Color(0xFF1F2937)] : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563).withOpacity(0.3) : const Color(0xFFD1D5DB).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.auto_awesome,
        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        size: 36.sp,
      ),
    );
  }
}

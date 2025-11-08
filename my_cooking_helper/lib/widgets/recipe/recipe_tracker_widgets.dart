// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import '/utils/colors.dart';
import '/services/recipe_save_service.dart';
import '/services/cravings_recipe_service.dart';
import '/models/recipe_history.dart';

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
  final bool isAi; 

  const CookedRecipeCard({
    required this.recipe,
    this.imageUrl,
    this.onTap,
    this.isAi = false,
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
  AnimationController? _aiGlowController; // only create if isAi==true
  late Animation<double> _scaleAnimation;
  late Animation<double> _favoriteScaleAnimation;

  @override
  void initState() {
    super.initState();
    isFavourite = widget.recipe.isFavourite == true;

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _favoriteScaleAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _favoriteController, curve: Curves.elasticOut),
    );

    if (widget.isAi) {
      _aiGlowController = AnimationController(
        duration: const Duration(seconds: 6), 
        vsync: this,
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CookedRecipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAi != widget.isAi) {
      if (widget.isAi && _aiGlowController == null) {
        _aiGlowController = AnimationController(
          duration: const Duration(seconds: 6),
          vsync: this,
        )..repeat();
      } else if (!widget.isAi && _aiGlowController != null) {
        _aiGlowController!.dispose();
        _aiGlowController = null;
      }
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _favoriteController.dispose();
    _aiGlowController?.dispose();
    super.dispose();
  }

  Future<void> _toggleFavourite() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Bounce animation
    _favoriteController.forward().then((_) => _favoriteController.reverse());

    final newFav = !isFavourite;
    setState(() => isFavourite = newFav);

    if (!widget.isAi) {
      await RecipeSaveService.updateFavouriteStatus(
        recipeId: widget.recipe.recipeId,
        userId: userId,
        isFavourite: newFav,
      );
    } else {
      await CravingsRecipeService.updateFavouriteStatusByKey(
        uid: userId,
        recipeKey: widget.recipe.recipeId,
        isFavourite: newFav,
        recipeTitle: widget.recipe.recipeTitle,
        hasImage: widget.imageUrl != null && widget.imageUrl!.isNotEmpty,
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

  void _onTapDown(TapDownDetails _) => _pressController.forward();
  void _onTapUp(TapUpDetails _) => _pressController.reverse();
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

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          if (_aiGlowController != null) _aiGlowController!,
        ]),
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
                height: 120.h, // tuned for mobile
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF161A21), const Color(0xFF0F1217)]
                        : [const Color(0xFFFFFFFF), const Color(0xFFF7F8FA)],
                  ),
                  border: Border.all(
                    color: widget.isAi
                        ? const Color(0xFFA78BFA).withOpacity(0.55) // static (no jank)
                        : (isDark ? const Color(0xFF2A2F38) : const Color(0xFFE7EBF0)),
                    width: widget.isAi ? 1.6 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.30)
                          : const Color(0xFF1F2937).withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: buildContent(context),
              ).asGlass(
                // light tint only; heavier blur can cause jank on low-end devices
                tintColor: isDark ? const Color(0xFF0E1218) : Colors.white,
                clipBorderRadius: BorderRadius.circular(22.r),
                blurX: 8,
                blurY: 8,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // Blue debug to track builds (your convention)
    // ignore: avoid_print
    print('\x1B[34m[CARD] build id=${widget.recipe.recipeId} fav=$isFavourite ai=${widget.isAi}\x1B[0m');
  }

  // ---- Inner content (separate build to reduce rebuild cost) ----
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 120.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          // === Thumbnail / Fallback (with AI border + chip when isAi) ===
          Hero(
            tag: 'recipe_image_${widget.recipe.recipeId}',
            child: SizedBox(
              width: 88.w,
              height: 88.w,
              child: widget.isAi
                  ? _buildAnimatedAiImage(context, isDark)
                  : _buildStandardThumb(context, isDark),
            ),
          ),

          SizedBox(width: 14.w),

          // Texts & Meta
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final titleMaxLines = constraints.maxHeight < 115 ? 2 : 3;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Title (max 3 lines)
                    Flexible(
                      child: Text(
                        widget.recipe.recipeTitle,
                        maxLines: titleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5.sp,
                          color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                          height: 1.22,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),

                    SizedBox(height: 8.h),

                    // Chips row -> Wrap to avoid overflow
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Date chip
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14.r),
                            color: isDark ? const Color(0xFF172036) : const Color(0xFFEFF6FF),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF3758F9).withOpacity(0.35)
                                  : const Color(0xFF3B82F6).withOpacity(0.30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule_rounded, size: 14.sp, color: const Color(0xFF3B82F6)),
                              SizedBox(width: 6.w),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  // leave space for favourite button on narrow layouts
                                  maxWidth: MediaQuery.of(context).size.width * 0.42,
                                ),
                                child: Text(
                                  _formatDate(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: textColor(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // AI chip is on the image
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // Favourite button
          Padding(
            padding: EdgeInsets.only(left: 8.w, right: 8.w),
            child: AnimatedBuilder(
              animation: _favoriteScaleAnimation,
              builder: (_, __) {
                return Transform.scale(
                  scale: _favoriteScaleAnimation.value,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20.r),
                      onTap: _toggleFavourite,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          color: isFavourite
                              ? (isDark ? const Color(0xFF3B0A2A) : const Color(0xFFFFEEF5))
                              : Colors.transparent,
                          border: Border.all(
                            color: isFavourite
                                ? const Color(0xFFEC4899).withOpacity(0.35)
                                : (isDark ? Colors.white10 : Colors.black12),
                          ),
                        ),
                        child: Icon(
                          isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavourite
                              ? const Color(0xFFEC4899)
                              : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                          size: 22.sp,
                          semanticLabel: isFavourite ? 'Remove from favourites' : 'Add to favourites',
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
    );
  }

  // AI image: smooth
  Widget _buildAnimatedAiImage(BuildContext context, bool isDark) {
    // Inner image / AI fallback (static — no rotation)
    final Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
          ? Image.network(
              widget.imageUrl!,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (c, e, s) => _aiFallbackThumb(isDark),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _aiFallbackThumb(isDark);
              },
            )
          : _aiFallbackThumb(isDark),
    );

    // Animate only the border shader, not the image.
    final animation = _aiGlowController ?? const AlwaysStoppedAnimation(0.0);

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Static image sits underneath
          image,

          // Animated glow border on top
          IgnorePointer(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _GlowBorderPainter(
                    progress: animation.value,        // 0..1, loops
                    strokeWidth: 2.0,     
                    radius: 18.r,           
                    colors: const [
                      Color(0xFF60A5FA),   
                      Color(0xFFA78BFA),    
                      Color(0xFF60A5FA),
                    ],
                  ),
                );
              },
            ),
          ),

          // Static AI chip at top-left (no animation)
          Positioned(
            left: 4.w,
            top: 4.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: textColor(context)),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.4) : Colors.black12,
                    blurRadius: 6, offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 12.sp, color: isDark ? Colors.tealAccent : Colors.purpleAccent),
                  SizedBox(width: 4.w),
                  Text(
                    'AI',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5.sp,
                      color: textColor(context),
                      letterSpacing: 0.2,
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

  // Standard (non-AI)
  Widget _buildStandardThumb(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.28) : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
            ? Image.network(
                widget.imageUrl!,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (c, e, s) => _fallbackIcon(context),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _fallbackIcon(context);
                },
              )
            : _fallbackIcon(context),
      ),
    );
  }

  // Fallback icon when no image is available (also used on load/error)
  Widget _fallbackIcon(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isAi) {
      return _aiFallbackThumb(isDark);
    }

    // default non-AI placeholder
    return Container(
      width: 88.w,
      height: 88.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF232833), const Color(0xFF151922)]
              : [const Color(0xFFF3F6FA), const Color(0xFFE8ECF2)],
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF414955).withOpacity(0.35) : const Color(0xFFD8DFE7),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.restaurant_menu_rounded,
        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        size: 28.sp,
      ),
    );
  }

  // Compact helper used by AI image & fallback
  Widget _aiFallbackThumb(bool isDark) {
    return Container(
      width: 88.w, height: 88.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1B1F2A), const Color(0xFF121620)]
              : [const Color(0xFFF3F6FF), const Color(0xFFEFF1FA)],
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF434769) : const Color(0xFFD9DDF4),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: 28.sp,
        color: isDark ? const Color(0xFF9DB0FF) : const Color(0xFF5B21B6),
      ),
    );
  }
}

class _GlowBorderPainter extends CustomPainter {
  final double progress;      // 0..1
  final double strokeWidth;
  final double radius;
  final List<Color> colors;

  _GlowBorderPainter({
    required this.progress,
    required this.strokeWidth,
    required this.radius,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final sweep = SweepGradient(
      colors: colors.map((c) => c.withOpacity(0.95)).toList(),
      transform: GradientRotation(progress * 6.28318530718), // 2π
    ).createShader(rect);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = sweep
      ..isAntiAlias = true;

    // Draw rounded rectangle border; deflate so the stroke stays fully inside.
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowBorderPainter oldDelegate) {
    // Repaint when animation advances or parameters change
    return oldDelegate.progress != progress ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.radius != radius ||
           oldDelegate.colors != colors;
  }
}

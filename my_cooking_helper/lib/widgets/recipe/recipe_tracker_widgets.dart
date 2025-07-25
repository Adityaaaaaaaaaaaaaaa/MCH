import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/services/recipe_save_service.dart';
import '/models/recipe_history.dart';
import '/utils/colors.dart';

class CookedRecipeCard extends StatefulWidget {
  final RecipeHistoryEntry recipe;
  final String? imageUrl; // Pass image from RecipeDetail (can be null)
  final void Function()? onTap;

  const CookedRecipeCard({
    required this.recipe,
    this.imageUrl,
    this.onTap,
    super.key,
  });

  @override
  State<CookedRecipeCard> createState() => _CookedRecipeCardState();
}

class _CookedRecipeCardState extends State<CookedRecipeCard> {
  late bool isFavourite;

  @override
  void initState() {
    super.initState();
    isFavourite = widget.recipe.isFavourite == true;
  }

  Future<void> _toggleFavourite() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final newFav = !isFavourite;
    setState(() => isFavourite = newFav);

    await RecipeSaveService.updateFavouriteStatus(
      recipeId: widget.recipe.recipeId,
      userId: userId,
      isFavourite: newFav,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newFav ? 'Added to Favourites' : 'Removed from Favourites'),
        backgroundColor: newFav ? Colors.pink[400] : Colors.grey[600],
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.09)
        : Colors.grey[50]!.withOpacity(0.18);

    return InkWell(
      borderRadius: BorderRadius.circular(22.r),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(vertical: 7.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          gradient: LinearGradient(
            colors: [
              cardBg,
              theme.cardColor.withOpacity(0.21),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.13 : 0.09),
              blurRadius: 13,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(10.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18.r),
                    child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                        ? Image.network(
                            widget.imageUrl!,
                            height: 68.w,
                            width: 68.w,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => _fallbackIcon(context),
                          )
                        : _fallbackIcon(context),
                  ),
                ),
                SizedBox(width: 12.w),
                // --- Main Info Section ---
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recipe.recipeTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: textColor(context),
                            fontSize: 17.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 7.h),
                        // You can even wrap this row in a SingleChildScrollView if you expect chip overflow
                        Row(
                          children: [
                            Flexible(
                              child: Chip(
                                label: Text(
                                  "${widget.recipe.timesCooked}x",
                                  style: TextStyle(
                                    color: Colors.teal[800],
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: Colors.teal.withOpacity(0.12),
                                avatar: Icon(Icons.restaurant_menu, color: Colors.teal, size: 18),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Chip(
                                label: Text(
                                  widget.recipe.lastCookedAt != null
                                      ? "${widget.recipe.lastCookedAt!.day}/${widget.recipe.lastCookedAt!.month}/${widget.recipe.lastCookedAt!.year}"
                                      : "-",
                                  style: TextStyle(
                                    color: Colors.indigo[900],
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: Colors.indigo.withOpacity(0.12),
                                avatar: Icon(Icons.calendar_today_rounded, color: Colors.indigo, size: 16),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // --- Favourite Button (floating effect) ---
                Padding(
                  padding: EdgeInsets.only(right: 8.w, left: 4.w),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _toggleFavourite,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 170),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFavourite ? Colors.pink.withOpacity(0.18) : Colors.white.withOpacity(0.13),
                          boxShadow: isFavourite
                              ? [BoxShadow(color: Colors.pink.withOpacity(0.21), blurRadius: 16)]
                              : [],
                        ),
                        padding: EdgeInsets.all(9.w),
                        child: Icon(
                          isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavourite ? Colors.pink : textColor(context).withOpacity(0.55),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 17, color: textColor(context).withOpacity(0.6)),
                SizedBox(width: 7.w),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fallback icon for when no image is available
  Widget _fallbackIcon(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 68.w,
      height: 68.w,
      color: theme.brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[200],
      child: Icon(Icons.fastfood_rounded, color: Colors.grey[500], size: 34),
    );
  }
}

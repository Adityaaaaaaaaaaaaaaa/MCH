import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/services/recipe_save_service.dart';
import '/models/recipe_history.dart';
import '/utils/colors.dart';

class CookedRecipeCard extends StatefulWidget {
  final RecipeHistoryEntry recipe;
  final void Function()? onTap;

  const CookedRecipeCard({
    required this.recipe,
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

    // Update Firestore instantly
    await RecipeSaveService.updateFavouriteStatus(
      recipeId: widget.recipe.recipeId,
      userId: userId,
      isFavourite: newFav,
    );
    // Optional: show a snackbar for feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newFav ? 'Added to Favourites' : 'Removed from Favourites'),
        backgroundColor: newFav ? Colors.pink[400] : Colors.grey[600],
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22.r),
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          color: Colors.white.withOpacity(0.15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ... (your thumbnail code)
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipe.recipeTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textColor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: Colors.teal),
                      SizedBox(width: 6.w),
                      Text(
                        "${widget.recipe.timesCooked}x cooked",
                        style: TextStyle(
                          color: Colors.teal[700],
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 18.w),
                      Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4.w),
                      Text(
                        widget.recipe.lastCookedAt != null
                            ? "${widget.recipe.lastCookedAt!.day}/${widget.recipe.lastCookedAt!.month}/${widget.recipe.lastCookedAt!.year}"
                            : "-",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // --- Favourite Button ---
            IconButton(
              icon: Icon(
                isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavourite ? Colors.pink : textColor(context).withOpacity(0.5),
              ),
              onPressed: _toggleFavourite,
              tooltip: isFavourite ? "Remove from Favourites" : "Add to Favourites",
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textColor(context).withOpacity(0.7)),
            SizedBox(width: 12.w),
          ],
        ),
      ),
    );
  }
}

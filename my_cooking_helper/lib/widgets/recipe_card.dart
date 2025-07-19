import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import '/models/recipe.dart';
import '/utils/colors.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isSelected;
  final String Function(int) formatTime;
  final VoidCallback onTap;
  final VoidCallback onSelect;
  final VoidCallback onViewRecipe;

  const RecipeCard({
    Key? key,
    required this.recipe,
    required this.isSelected,
    required this.formatTime,
    required this.onTap,
    required this.onSelect,
    required this.onViewRecipe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: 16.h),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: isSelected ? Border.all(color: Colors.green, width: 2.5) : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28.r),
                  child: Container(
                    padding: EdgeInsets.only(bottom: 0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recipe Image with Glass Badge
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                              child: Image.network(
                                recipe.imageUrl,
                                width: double.infinity,
                                height: 180.h,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: double.infinity,
                                  height: 180.h,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.restaurant_menu, size: 60.sp, color: Colors.grey[400]),
                                ),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: double.infinity,
                                    height: 180.h,
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Time badge (glass effect)
                            Positioned(
                              bottom: 14.h,
                              left: 16.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time, size: 14.sp, color: Colors.white),
                                    SizedBox(width: 6.w),
                                    Text(
                                      formatTime(recipe.totalTime),
                                      style: TextStyle(
                                        color: textColor(context),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ).asGlass(
                                blurX: 7,
                                blurY: 7,
                                tintColor: Colors.black.withOpacity(0.38),
                                clipBorderRadius: BorderRadius.circular(18.r),
                              ),
                            ),
                            // Select badge
                            Positioned(
                              top: 14.h,
                              right: 16.w,
                              child: GestureDetector(
                                onTap: onSelect,
                                child: Container(
                                  padding: EdgeInsets.all(10.w),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.green : Colors.white.withOpacity(0.92),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.11),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isSelected ? Icons.check : Icons.add,
                                    size: 18.sp,
                                    color: isSelected ? Colors.white : Colors.green,
                                  ),
                                ).asGlass(
                                  blurX: 10,
                                  blurY: 10,
                                  tintColor: isSelected ? Colors.green : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Recipe Info Section
                        Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 19.sp,
                                  color: textColor(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 14.sp, color: Colors.grey[700]),
                                  SizedBox(width: 6.w),
                                  Text(
                                    '${recipe.ingredients.length} ingredients',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              // View Recipe Button
                              InkWell(
                                borderRadius: BorderRadius.circular(14.r),
                                onTap: onViewRecipe,
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 11.h),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'View Recipe',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ).asGlass(
                                  blurX: 4,
                                  blurY: 6,
                                  tintColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  clipBorderRadius: BorderRadius.circular(14.r),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).asGlass(
                  blurX: 8,
                  blurY: 8,
                  tintColor: Colors.white.withOpacity(0.07),
                  clipBorderRadius: BorderRadius.circular(28.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

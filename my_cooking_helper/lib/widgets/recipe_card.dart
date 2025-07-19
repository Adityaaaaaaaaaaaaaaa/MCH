// ignore_for_file: deprecated_member_use

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
    // Enhanced theme detection for better dark/light mode support
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark 
        ? Colors.grey[900]!.withOpacity(0.7)
        : Colors.white.withOpacity(0.95);
        
    final shadowColor = isDark 
        ? Colors.black.withOpacity(0.4)
        : Colors.black.withOpacity(0.08);

    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: 20.h), // Increased margin for better spacing
          child: Stack(
            children: [
              // Enhanced card container with better shadows and modern design
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.r), // Slightly reduced for modern look
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 20, // Enhanced shadow
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    // Additional subtle shadow for depth
                    BoxShadow(
                      color: shadowColor.withOpacity(0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                  // Enhanced border with theme-aware colors
                  border: isSelected 
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary, 
                          width: 2.5
                        ) 
                      : Border.all(
                          color: isDark 
                              ? Colors.grey[700]!.withOpacity(0.3)
                              : Colors.grey[200]!.withOpacity(0.5),
                          width: 1,
                        ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: Container(
                    // Enhanced background with theme awareness
                    decoration: BoxDecoration(
                      color: cardColor,
                      // Added subtle gradient for modern look
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cardColor,
                          cardColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Enhanced Recipe Image Section
                        Stack(
                          children: [
                            // Improved image container with better aspect ratio
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                              child: SizedBox(
                                height: 200.h, // Increased height for better proportions
                                width: double.infinity,
                                child: Image.network(
                                  recipe.imageUrl,
                                  width: double.infinity,
                                  height: 200.h,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: double.infinity,
                                    height: 200.h,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          isDark ? Colors.grey[800]! : Colors.grey[100]!,
                                          isDark ? Colors.grey[700]! : Colors.grey[200]!,
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.restaurant_menu_rounded, // More modern icon
                                      size: 48.sp, 
                                      color: isDark ? Colors.grey[500] : Colors.grey[400]
                                    ),
                                  ),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: double.infinity,
                                      height: 200.h,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Theme.of(context).colorScheme.primary,
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
                            ),
                            
                            // Enhanced overlay gradient for better text readability
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.0, 0.6, 1.0],
                                    colors: [
                                      Colors.transparent,
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Redesigned time badge with modern glassmorphism
                            Positioned(
                              bottom: 16.h,
                              left: 16.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.r),
                                  // Enhanced glass effect
                                  color: Colors.black.withOpacity(0.2),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded, // More modern icon
                                      size: 16.sp, 
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      formatTime(recipe.totalTime),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.sp,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ).asGlass(
                                blurX: 10,
                                blurY: 10,
                                tintColor: Colors.white.withOpacity(0.1),
                                clipBorderRadius: BorderRadius.circular(20.r),
                              ),
                            ),
                            
                            // Modern select badge with enhanced design
                            Positioned(
                              top: 16.h,
                              right: 16.w,
                              child: GestureDetector(
                                onTap: onSelect,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: EdgeInsets.all(10.w),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.white.withOpacity(0.95),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected 
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.white.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isSelected ? Icons.check_rounded : Icons.add_rounded,
                                    size: 18.sp,
                                    color: isSelected 
                                        ? Colors.white 
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Enhanced Recipe Info Section with modern layout
                        Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h), // Better padding
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Recipe title with improved typography
                              Text(
                                recipe.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700, // Slightly bolder
                                  fontSize: 20.sp, // Increased size
                                  color: textColor(context),
                                  letterSpacing: -0.5, // Modern tight spacing
                                  height: 1.2, // Better line height
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              SizedBox(height: 12.h), // Increased spacing
                              
                              // Enhanced ingredients info with modern design
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? Colors.grey[800]!.withOpacity(0.5)
                                      : Colors.grey[100]!.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: isDark 
                                        ? Colors.grey[600]!.withOpacity(0.3)
                                        : Colors.grey[300]!.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_rounded, // More modern icon
                                      size: 16.sp, 
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      '${recipe.ingredients.length} ingredients',
                                      style: TextStyle(
                                        fontSize: 14.sp, // Slightly larger
                                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: 16.h), // Better spacing
                              
                              // Enhanced View Recipe Button with modern design
                              InkWell(
                                borderRadius: BorderRadius.circular(16.r),
                                onTap: onViewRecipe,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 14.h), // Better padding
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16.r), // More modern radius
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.restaurant_menu_rounded,
                                          color: Colors.white,
                                          size: 16.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'View Recipe',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15.sp, // Slightly larger
                                            letterSpacing: 0.5, // Modern spacing
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).asGlass(
                  blurX: 12, // Enhanced blur
                  blurY: 12,
                  tintColor: isDark 
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.1),
                  clipBorderRadius: BorderRadius.circular(24.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

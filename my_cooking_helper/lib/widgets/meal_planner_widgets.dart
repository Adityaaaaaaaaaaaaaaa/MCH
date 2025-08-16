// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';

class DayRowCarousel extends StatelessWidget {
  final String dayLabel;            // e.g. "Monday — Aug 18"
  final bool isToday;               // highlight row if true
  final List<MealCellLite> meals;   // 3 items: breakfast, lunch, dinner
  final VoidCallback? onLongPressDay;

  const DayRowCarousel({
    super.key,
    required this.dayLabel,
    required this.meals,
    this.isToday = false,
    this.onLongPressDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Enhanced colors with more personality
    final borderColor = isToday
        ? theme.colorScheme.primary.withOpacity(0.6)
        : isDark 
          ? Colors.purple.withOpacity(0.15)
          : Colors.blue.withOpacity(0.2);

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: borderColor, 
          width: isToday ? 2.0 : 1.0
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isToday
              ? [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.primary.withOpacity(0.05),
                  Colors.transparent,
                ]
              : isDark
                ? [
                    Colors.purple.withOpacity(0.08),
                    Colors.indigo.withOpacity(0.05),
                    Colors.transparent,
                  ]
                : [
                    Colors.blue.withOpacity(0.06),
                    Colors.cyan.withOpacity(0.04),
                    Colors.transparent,
                  ],
        ),
        boxShadow: [
          if (isToday) BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced day label with better typography
          Row(
            children: [
              if (isToday) ...[
                Container(
                  width: 6.w, 
                  height: 6.w,
                  margin: EdgeInsets.only(right: 10.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  dayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isToday 
                      ? theme.colorScheme.primary
                      : null,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Enhanced horizontal carousel with better spacing
          SizedBox(
            height: math.max(160.h, 150.0), // Updated to match card height
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: meals.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (context, i) => MealCardLarge(meal: meals[i]),
            ),
          ),
        ],
      ),
    ).asGlass(
      blurX: 20,
      blurY: 20,
      tintColor: isDark 
        ? Colors.purple.withOpacity(0.02)
        : Colors.blue.withOpacity(0.02),
      clipBorderRadius: BorderRadius.circular(24.r),
      frosted: true,
    );

    return GestureDetector(
      onLongPress: onLongPressDay, 
      child: container,
    );
  }
}

class MealCellLite {
  final String label;         // Breakfast | Lunch | Dinner
  final String? id;
  final String? title;
  final String? image;
  final VoidCallback? onTap;

  MealCellLite({
    required this.label,
    this.id,
    this.title,
    this.image,
    this.onTap,
  });
}

class MealCardLarge extends StatelessWidget {
  final MealCellLite meal;
  const MealCardLarge({super.key, required this.meal});

  // Get color based on meal type
  Color _getMealColor(String label, bool isDark) {
    switch (label.toLowerCase()) {
      case 'breakfast':
        return isDark ? Colors.orange.withOpacity(0.6) : Colors.orange;
      case 'lunch':
        return isDark ? Colors.green.withOpacity(0.6) : Colors.green;
      case 'dinner':
        return isDark ? Colors.deepPurple.withOpacity(0.6) : Colors.deepPurple;
      default:
        return isDark ? Colors.blue.withOpacity(0.6) : Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasMeal = (meal.id != null);
    final mealColor = _getMealColor(meal.label, isDark);

    return LayoutBuilder(
      builder: (_, constraints) {
        // More responsive card sizing
        final screenW = MediaQuery.of(context).size.width;
        final cardW = math.min(screenW * 0.75, 260.0).w; // Increased width

        final card = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasMeal ? meal.onTap : null,
            borderRadius: BorderRadius.circular(20.r),
            splashColor: mealColor.withOpacity(0.1),
            highlightColor: mealColor.withOpacity(0.05),
            child: Container(
              width: cardW,
              height: math.max(160.h, 150.0), // Increased height
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: mealColor.withOpacity(0.2),
                  width: 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    mealColor.withOpacity(0.08),
                    mealColor.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: mealColor.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Prevent overflow
                children: [
                  // Image with enhanced styling - increased size
                  Expanded(
                    flex: 4, // Increased from 3 to 4 for larger image
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: mealColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: (hasMeal && (meal.image ?? '').isNotEmpty)
                            ? Image.network(
                                meal.image!, 
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: mealColor,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 24, 
                                      color: mealColor.withOpacity(0.6),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.restaurant_menu_outlined,
                                  size: 32, // Increased icon size for larger image area 
                                  color: mealColor.withOpacity(0.5),
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  
                  // Meal type label with better styling
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: mealColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      meal.label.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: mealColor,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                        fontSize: 9.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  
                  // Title with improved typography - flexible to prevent overflow
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            hasMeal ? (meal.title ?? 'Untitled Recipe') : 'No meal planned',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              letterSpacing: -0.1,
                              fontSize: 13.sp,
                              color: hasMeal 
                                ? null 
                                : theme.hintColor.withOpacity(0.7),
                            ),
                          ),
                        ),
                        
                        // Action indicator
                        if (hasMeal) ...[
                          SizedBox(height: 4.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: mealColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 14,
                                color: mealColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).asGlass(
          blurX: 16,
          blurY: 16,
          tintColor: mealColor.withOpacity(0.02),
          clipBorderRadius: BorderRadius.circular(20.r),
          frosted: true,
        );

        return card;
      },
    );
  }
}

class WeekHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool leadingHighlight;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  const WeekHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingHighlight = false,
    this.primaryAction,
    this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Gather actions (skip nulls)
    final actions = <Widget>[
      if (secondaryAction != null) secondaryAction!,
      if (primaryAction != null) primaryAction!,
    ];

    final card = Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: isDark 
            ? Colors.purple.withOpacity(0.2)
            : Colors.blue.withOpacity(0.25),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: leadingHighlight
              ? [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.primary.withOpacity(0.05),
                  Colors.transparent,
                ]
              : isDark
                ? [
                    Colors.purple.withOpacity(0.08),
                    Colors.indigo.withOpacity(0.05),
                    Colors.transparent,
                  ]
                : [
                    Colors.blue.withOpacity(0.06),
                    Colors.cyan.withOpacity(0.04),
                    Colors.transparent,
                  ],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.purple.withOpacity(0.1)
              : Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          if (leadingHighlight) BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Enhanced header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: leadingHighlight
                        ? [
                            theme.colorScheme.primary.withOpacity(0.2),
                            theme.colorScheme.primary.withOpacity(0.1),
                          ]
                        : isDark
                          ? [
                              Colors.purple.withOpacity(0.15),
                              Colors.indigo.withOpacity(0.1),
                            ]
                          : [
                              Colors.blue.withOpacity(0.15),
                              Colors.cyan.withOpacity(0.1),
                            ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: leadingHighlight
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : isDark
                          ? Colors.purple.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: leadingHighlight 
                    ? theme.colorScheme.primary
                    : isDark
                      ? Colors.purple.shade300
                      : Colors.blue.shade600,
                  size: 28,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor.withOpacity(0.8),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Enhanced actions with better spacing
          if (actions.isNotEmpty) ...[
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: actions.map((action) {
                      // Enhance button styling if it's an ElevatedButton or OutlinedButton
                      if (action is ElevatedButton) {
                        return _enhanceElevatedButton(action, theme);
                      } else if (action is OutlinedButton) {
                        return _enhanceOutlinedButton(action, theme, isDark);
                      }
                      return action;
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).asGlass(
      blurX: 22,
      blurY: 22,
      tintColor: isDark 
        ? Colors.purple.withOpacity(0.02)
        : Colors.blue.withOpacity(0.02),
      clipBorderRadius: BorderRadius.circular(28.r),
      frosted: true,
    );

    return card;
  }

  Widget _enhanceElevatedButton(ElevatedButton button, ThemeData theme) {
    // Extract the original properties properly
    final onPressed = button.onPressed;
    
    // Handle the button content
    Widget buttonContent;
    Icon? buttonIcon;
    
    if (button.child is Row) {
      // It's an ElevatedButton.icon, extract icon and label
      final row = button.child as Row;
      final children = row.children;
      
      if (children.length >= 2) {
        buttonIcon = children.first is Icon ? children.first as Icon : null;
        buttonContent = children.last;
      } else {
        buttonContent = button.child!;
      }
    } else {
      buttonContent = button.child!;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        elevation: 2,
        shadowColor: theme.colorScheme.primary.withOpacity(0.3),
      ),
      child: buttonIcon != null 
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              buttonIcon,
              SizedBox(width: 6.w),
              buttonContent,
            ],
          )
        : buttonContent,
    );
  }

  Widget _enhanceOutlinedButton(OutlinedButton button, ThemeData theme, bool isDark) {
    // Extract the original properties properly
    final onPressed = button.onPressed;
    
    // Handle the button content
    Widget buttonContent;
    Icon? buttonIcon;
    
    if (button.child is Row) {
      // It's an OutlinedButton.icon, extract icon and label
      final row = button.child as Row;
      final children = row.children;
      
      if (children.length >= 2) {
        buttonIcon = children.first is Icon ? children.first as Icon : null;
        buttonContent = children.last;
      } else {
        buttonContent = button.child!;
      }
    } else {
      buttonContent = button.child!;
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: buttonIcon != null 
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              buttonIcon,
              SizedBox(width: 6.w),
              buttonContent,
            ],
          )
        : buttonContent,
    );
  }
}
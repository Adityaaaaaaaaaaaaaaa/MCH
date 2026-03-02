// ignore_for_file: deprecated_member_use, file_names

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import '/utils/colors.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';

Future<int?> pickCookingTime(BuildContext context, {int initial = 30}) {
  int tmpTime = initial;
  bool isPressed = false;

  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = isDark ? const Color(0xFF4398FF) : const Color(0xFF266AFB);

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 340.w,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              color: isDark 
                ? const Color(0xFF1A1A1A) 
                : const Color(0xFFFEFEFE),
              border: Border.all(
                color: textColor(context),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.08),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        color: primaryColor,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cooking Time',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: textColor(context),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'How much time do you have?',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w400,
                              color: textColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 28.h),

                // Clock with Glow
                GestureDetector(
                  onTapDown: (_) {
                    setState(() => isPressed = true);
                    HapticFeedback.lightImpact();
                  },
                  onTapUp: (_) => setState(() => isPressed = false),
                  onTapCancel: () => setState(() => isPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.identity()..scale(isPressed ? 0.97 : 1.0),
                    child: Container(
                      width: 180.w,
                      height: 180.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark 
                          ? const Color(0xFF262626)
                          : const Color(0xFFFAFAFA),
                        border: Border.all(
                          color: isDark 
                            ? Colors.teal
                            : Colors.orange,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark 
                              ? Colors.tealAccent.withOpacity(0.5)
                              : Colors.orange.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.9),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                        ],
                      ),
                      child: CustomPaint(
                        size: Size(180.w, 180.w),
                        painter: EnhancedClockPainter(
                          totalMinutes: tmpTime,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Time Display
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    color: primaryColor.withOpacity(0.2),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tmpTime == 0
                        ? 'No time selected'
                        : (tmpTime >= 60)
                            ? '${tmpTime ~/ 60}h ${tmpTime % 60 > 0 ? '${tmpTime % 60}m' : ''}'
                            : '$tmpTime min',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                SizedBox(height: 28.h),

                // Slider
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0 min',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: textColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '3h',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: textColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 6.h,
                          thumbColor: primaryColor,
                          activeTrackColor: primaryColor,
                          inactiveTrackColor: isDark 
                            ? const Color(0xFF404040)
                            : const Color(0xFFE5E7EB),
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.r),
                          overlayColor: primaryColor.withOpacity(0.16),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 20.r),
                          trackShape: const RoundedRectSliderTrackShape(),
                        ),
                        child: Slider(
                          min: 0,
                          max: 180,
                          divisions: 36,
                          value: tmpTime.toDouble().clamp(0, 180),
                          onChanged: (val) {
                            HapticFeedback.selectionClick();
                            setState(() => tmpTime = ((val ~/ 5) * 5).clamp(0, 180));
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 28.h),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF404040) : const Color(0xFFD1D5DB),
                            width: 1.5,
                          ),
                          foregroundColor: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, tmpTime),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).asGlass(
            tintColor: isDark ? Colors.black : Colors.white,
            clipBorderRadius: BorderRadius.circular(20.r),
            blurX: 12,
            blurY: 12,
            frosted: true,
          ),
        );
      },
    ),
  );
}

// Clock Painter Glow
class EnhancedClockPainter extends CustomPainter {
  final int totalMinutes;
  final bool isDark;
  final Color primaryColor;

  EnhancedClockPainter({
    required this.totalMinutes,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 24;

    // Draw subtle clock face marks
    final tickPaint = Paint()
      ..color = isDark 
        ? const Color(0xFFE6E6E6).withOpacity(0.6)
        : const Color(0xFF9CA3AF).withOpacity(0.9)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final length = (i % 3 == 0) ? 10.0 : 5.0;
      final start = Offset(
        center.dx + (radius - length) * math.cos(angle),
        center.dy + (radius - length) * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    // Draw background track
    final bgTrackPaint = Paint()
      ..color = isDark 
        ? const Color(0xFF7B7B7B).withOpacity(0.3)
        : const Color(0xFFE5E7EB).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 12, bgTrackPaint);

    // Draw glowing progress arc
    if (totalMinutes > 0) {
      final sweepAngle = (totalMinutes / 180) * 2 * math.pi;
      
      // Glow effect layers
      for (int i = 0; i < 3; i++) {
        final glowPaint = Paint()
          ..color = primaryColor.withOpacity(0.1 - (i * 0.02))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8 + (i * 6.0)
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0 + (i * 2.0));

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - 12),
          -math.pi / 2,
          sweepAngle,
          false,
          glowPaint,
        );
      }

      // Main progress arc
      final progressPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 12),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // Draw subtle hour hand
    if (totalMinutes > 0) {
      final hours = totalMinutes / 60;
      final hourAngle = (hours / 3) * 2 * math.pi - math.pi / 2;
      final hourPaint = Paint()
        ..color = primaryColor.withOpacity(0.8)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        center,
        Offset(
          center.dx + (radius - 45) * math.cos(hourAngle),
          center.dy + (radius - 45) * math.sin(hourAngle),
        ),
        hourPaint,
      );
    }

    // Draw center dot with subtle glow
    final centerGlowPaint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, 8, centerGlowPaint);

    final centerPaint = Paint()
      ..color = primaryColor;
    canvas.drawCircle(center, 5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Ingredient Selector 
Future<Set<String>?> selectIngredients(
  BuildContext context,
  List<String> initialIngredients,
) {
  final Set<String> unwanted = {};
  final ScrollController scrollController = ScrollController();

  return showDialog<Set<String>>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: 0.8 * MediaQuery.of(context).size.height,
              maxWidth: 400.w,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFEFEFE),
              border: Border.all(
                color: textColor(context),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: Column(
              children: [
                // Header
                _buildMinimalistHeader(context, initialIngredients.length, unwanted.length),

                // Quick actions
                _buildMinimalistQuickActions(context, initialIngredients, unwanted, setState),

                // Ingredient grid
                Expanded(
                  child: _buildMinimalistIngredientGrid(
                    context,
                    initialIngredients,
                    unwanted,
                    setState,
                    scrollController,
                  ),
                ),

                // Action buttons
                _buildMinimalistActionBar(context, unwanted, ctx),
              ],
            ),
          ).asGlass(
            blurX: 12,
            blurY: 12,
            tintColor: isDark ? Colors.black : Colors.white,
            clipBorderRadius: BorderRadius.circular(20.r),
            frosted: true,
          ),
        );
      },
    ),
  );
}

Widget _buildMinimalistHeader(BuildContext context, int totalCount, int excludedCount) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(24.w),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.r),
        topRight: Radius.circular(20.r),
      ),
      color: isDark 
        ? const Color(0xFF262626)
        : const Color(0xFFFAFAFA),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark 
                  ? const Color(0xFF60A5FA).withOpacity(0.08)
                  : const Color(0xFF2563EB).withOpacity(0.06),
                border: Border.all(
                  color: isDark 
                    ? const Color(0xFF60A5FA).withOpacity(0.12)
                    : const Color(0xFF2563EB).withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Ingredients",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "Tap to exclude ingredients you don't want",
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 18.h),
        Row(
          children: [
            _buildMinimalistStatChip(
              "Included", 
              (totalCount - excludedCount).toString(), 
              isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
              isDark,
            ),
            SizedBox(width: 10.w),
            _buildMinimalistStatChip(
              "Excluded", 
              excludedCount.toString(), 
              isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
              isDark,
            ),
            SizedBox(width: 10.w),
            _buildMinimalistStatChip(
              "Total", 
              totalCount.toString(), 
              isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              isDark,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildMinimalistStatChip(String label, String value, Color color, bool isDark) {
  return Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: color.withOpacity(0.06),
        border: Border.all(
          color: color.withOpacity(0.12),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMinimalistQuickActions(BuildContext context, List<String> ingredients, Set<String> unwanted, StateSetter setState) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
    child: Row(
      children: [
        Expanded(
          child: _buildMinimalistQuickActionButton(
            "All",
            Icons.check_circle_outline_rounded,
            isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
            isDark,
            () {
              HapticFeedback.lightImpact();
              setState(() {
                unwanted.clear();
              });
            },
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildMinimalistQuickActionButton(
            "None",
            Icons.remove_circle_outline_rounded,
            isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
            isDark,
            () {
              HapticFeedback.lightImpact();
              setState(() {
                unwanted.addAll(ingredients);
              });
            },
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildMinimalistQuickActionButton(
            "Invert",
            Icons.swap_horiz_rounded,
            isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED),
            isDark,
            () {
              HapticFeedback.lightImpact();
              setState(() {
                final newUnwanted = <String>{};
                for (final ing in ingredients) {
                  if (!unwanted.contains(ing)) {
                    newUnwanted.add(ing);
                  }
                }
                unwanted.clear();
                unwanted.addAll(newUnwanted);
              });
            },
          ),
        ),
      ],
    ),
  );
}

Widget _buildMinimalistQuickActionButton(String text, IconData icon, Color color, bool isDark, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: color.withOpacity(0.06),
        border: Border.all(
          color: color.withOpacity(0.12),
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMinimalistIngredientGrid(
  BuildContext context,
  List<String> ingredients,
  Set<String> unwanted,
  StateSetter setState,
  ScrollController scrollController,
) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 24.w),
    child: GridView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 16.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: ingredients.length,
      itemBuilder: (context, index) => _buildMinimalistIngredientChip(
        ingredients[index],
        unwanted.contains(ingredients[index]),
        context,
        () {
          HapticFeedback.selectionClick();
          setState(() {
            final ing = ingredients[index];
            if (unwanted.contains(ing)) {
              unwanted.remove(ing);
            } else {
              unwanted.add(ing);
            }
          });
        },
      ),
    ),
  );
}

Widget _buildMinimalistIngredientChip(
  String ingredient,
  bool isUnwanted,
  BuildContext context,
  VoidCallback onTap,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: isUnwanted
            ? (isDark 
                ? const Color(0xFFF59E0B).withOpacity(0.4)
                : const Color(0xFFD97706).withOpacity(0.3))
            : (isDark 
                ? const Color(0xFF10B981).withOpacity(0.4)
                : const Color(0xFF059669).withOpacity(0.3)),
        border: Border.all(
          color: isUnwanted
              ? (isDark ? const Color(0xFFF59E0B).withOpacity(0.5) : const Color(0xFFD97706).withOpacity(0.3))
              : (isDark ? const Color(0xFF10B981).withOpacity(0.5) : const Color(0xFF059669).withOpacity(0.3)),
          width: 1.w,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            Icon(
              isUnwanted ? Icons.remove_circle_rounded : Icons.check_circle_rounded,
              color: isUnwanted
                  ? (isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706))
                  : (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)),
              size: 16.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                ingredient,
                style: TextStyle(
                  color: isUnwanted
                      ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                      : (isDark ? const Color(0xFF34D399) : const Color(0xFF047857)),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildMinimalistActionBar(BuildContext context, Set<String> unwanted, BuildContext ctx) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primaryColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
  
  return Container(
    padding: EdgeInsets.all(24.w),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(ctx, null),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              side: BorderSide(
                color: isDark ? const Color(0xFF404040) : const Color(0xFFD1D5DB),
                width: 1.5,
              ),
              foregroundColor: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx, unwanted),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class FancyGlowyMultiHourClockPainter extends CustomPainter {
  final int totalMinutes;
  final bool isDark;
  FancyGlowyMultiHourClockPainter({required this.totalMinutes, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class FancyGlassySliderThumb extends SliderComponentShape {
  final double thumbRadius;
  final bool isDark;
  final Color primaryColor;

  FancyGlassySliderThumb({
    required this.thumbRadius,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
  }
}

class _ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSecondary;
  final bool isDark;
  final Color primaryColor;

  const _ModernButton({
    required this.text,
    required this.onPressed,
    required this.isSecondary,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  _ModernButtonState createState() => _ModernButtonState();
}

class _ModernButtonState extends State<_ModernButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(isPressed ? 0.96 : 1.0),
        height: 48.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: widget.isSecondary
              ? (widget.isDark ? Colors.grey.shade800 : Colors.grey.shade100)
              : widget.primaryColor,
          border: widget.isSecondary
              ? Border.all(
                  color: widget.isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  width: 1.w,
                )
              : null,
        ),
        child: Center(
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: widget.isSecondary
                  ? (widget.isDark ? Colors.grey.shade300 : Colors.grey.shade700)
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
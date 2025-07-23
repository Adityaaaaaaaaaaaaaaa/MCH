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
        final primaryColor = isDark ? Colors.tealAccent.shade400 : Colors.teal.shade600;
        final surfaceColor = isDark ? Colors.grey.shade800 : Colors.white;
        final cardColor = isDark ? Colors.grey.shade900 : Colors.grey.shade50;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 340.w,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              color: surfaceColor.withOpacity(isDark ? 0.95 : 0.98),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                    ? Colors.black.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.15),
                  blurRadius: 30,
                  offset: Offset(0, 15.h),
                  spreadRadius: isDark ? -5 : 0,
                ),
                if (!isDark) ...[
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 20,
                    offset: Offset(-5, -5),
                    spreadRadius: -10,
                  ),
                ],
              ],
              border: isDark 
                ? Border.all(color: Colors.grey.shade700, width: 0.5.w)
                : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text(
                  'How much time do you have?',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor(context),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 32.h),
                
                // Interactive Clock
                GestureDetector(
                  onTapDown: (_) {
                    setState(() => isPressed = true);
                    HapticFeedback.lightImpact();
                  },
                  onTapUp: (_) => setState(() => isPressed = false),
                  onTapCancel: () => setState(() => isPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    transform: Matrix4.identity()
                      ..scale(isPressed ? 0.96 : 1.0),
                    child: Container(
                      width: 200.w,
                      height: 200.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardColor,
                        boxShadow: [
                          // Outer shadow
                          BoxShadow(
                            color: isDark 
                              ? Colors.black.withOpacity(0.6)
                              : Colors.grey.withOpacity(0.2),
                            blurRadius: isDark ? 25 : 20,
                            offset: Offset(8, 8),
                            spreadRadius: isDark ? -3 : -2,
                          ),
                          // Inner light shadow (neumorphism)
                          if (!isDark)
                            BoxShadow(
                              color: Colors.white.withOpacity(0.9),
                              blurRadius: 15,
                              offset: Offset(-6, -6),
                              spreadRadius: -2,
                            ),
                          // Subtle inner dark shadow
                          BoxShadow(
                            color: isDark 
                              ? Colors.grey.shade900.withOpacity(0.8)
                              : Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(-3, -3),
                            spreadRadius: -8,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Clock face with markers
                          CustomPaint(
                            size: Size(180.w, 180.w),
                            painter: ModernClockFacePainter(
                              isDark: isDark,
                              primaryColor: primaryColor,
                            ),
                          ),
                          
                          // Animated clock hand
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 300),
                            tween: Tween(end: (tmpTime / 180) * 2 * math.pi - math.pi / 2),
                            curve: Curves.easeOutCubic,
                            builder: (context, angle, child) {
                              return Transform.rotate(
                                angle: angle,
                                child: Container(
                                  width: 70.w,
                                  height: 3.h,
                                  margin: EdgeInsets.only(right: 35.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2.r),
                                    color: primaryColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // Center dot
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 24.h),
                
                // Time Display (Outside clock)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Text(
                    tmpTime >= 60
                        ? '${tmpTime ~/ 60}h ${tmpTime % 60 > 0 ? '${tmpTime % 60}m' : ''}'
                        : '$tmpTime min',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                
                SizedBox(height: 32.h),
                
                // Modern Slider
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      // Time range labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '15m',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: textColor(context).withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '3h',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: textColor(context).withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      
                      // Custom Slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.h, // Thinner track
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          thumbColor: primaryColor,
                          thumbShape: ModernSliderThumb(
                            thumbRadius: 10.sp, // Slightly smaller thumb
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          overlayColor: primaryColor.withOpacity(0.15),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 18.sp),
                          trackShape: _CustomTrackShape(), // Add this custom shape below
                        ),
                        child: Stack(
                          children: [
                            // Track background
                            Positioned.fill(
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 24.w),
                                height: 4.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2.r),
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                  boxShadow: [
                                    if (!isDark)
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.6),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Active track
                            Positioned.fill(
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 24.w),
                                height: 4.h,
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: (tmpTime - 15) / (180 - 15),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2.r),
                                      color: primaryColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.5),
                                          blurRadius: 5,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // The actual slider widget
                            Slider(
                              min: 15,
                              max: 180,
                              divisions: 33, // 5 min steps: (180-15)/5 = 33
                              value: tmpTime.toDouble().clamp(15, 180),
                              onChanged: (val) {
                                HapticFeedback.selectionClick();
                                setState(() => tmpTime = ((val ~/ 5) * 5).clamp(15, 180));
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32.h),
                
                // Action Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: _ModernButton(
                        text: 'Cancel',
                        onPressed: () => Navigator.pop(ctx, null),
                        isSecondary: true,
                        isDark: isDark,
                        primaryColor: primaryColor,
                      ),
                    ),
                    
                    SizedBox(width: 12.w),
                    
                    // OK Button
                    Expanded(
                      child: _ModernButton(
                        text: 'OK',
                        onPressed: () => Navigator.pop(ctx, tmpTime),
                        isSecondary: false,
                        isDark: isDark,
                        primaryColor: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).asGlass(
            blurX: 10,
            blurY: 10,
            tintColor: surfaceColor.withOpacity(0.1),
            clipBorderRadius: BorderRadius.circular(24.r),
            frosted: false,
          ),
        );
      },
    ),
  );
}

class _CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    double additionalActiveTrackHeight = 2,
  }) {
    // Do nothing: visual is handled by Stack in your widget tree.
  }
}

// Modern Button Widget
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
        transform: Matrix4.identity()..scale(isPressed ? 0.95 : 1.0),
        height: 48.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: widget.isSecondary 
            ? (widget.isDark ? Colors.grey.shade800 : Colors.grey.shade100)
            : widget.primaryColor,
          border: widget.isSecondary 
            ? Border.all(
                color: widget.isDark 
                  ? Colors.grey.shade600 
                  : Colors.grey.shade300,
                width: 1.w,
              )
            : null,
          boxShadow: [
            if (!widget.isSecondary) ...[
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6.h),
              ),
            ],
            BoxShadow(
              color: widget.isDark 
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2.h),
            ),
          ],
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
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// Modern Clock Face Painter (Improved for timer/clock logic)
class ModernClockFacePainter extends CustomPainter {
  final bool isDark;
  final Color primaryColor;

  ModernClockFacePainter({required this.isDark, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw minute tick marks (every 15 minutes, 12 total)
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final isQuarter = i % 3 == 0;

      final paint = Paint()
        ..color = isQuarter ? primaryColor : (isDark ? Colors.grey.shade600 : Colors.grey.shade400)
        ..strokeWidth = isQuarter ? 2.8 : 1.2
        ..strokeCap = StrokeCap.round;

      final startRadius = isQuarter ? radius - 20 : radius - 10;
      final endRadius = radius;

      final startX = center.dx + startRadius * math.cos(angle);
      final startY = center.dy + startRadius * math.sin(angle);
      final endX = center.dx + endRadius * math.cos(angle);
      final endY = center.dy + endRadius * math.sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }

    // Draw main time labels at correct positions (outside tick marks)
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final labels = [
      {'text': '15m',     'angle': 225.0},
      {'text': '45m',     'angle': 315.0},
      {'text': '1h30m',   'angle': 0.0},
      {'text': '2h',      'angle': 50.0},
      {'text': '2h30m',   'angle': 110.0},
      {'text': '3h',      'angle': 180.0},
    ];
    final labelRadius = radius + 22;
    for (var label in labels) {
      final angle = ((label['angle'] as double) - 90) * math.pi / 180; // <-- this line
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      textPainter.text = TextSpan(
        text: label['text'] as String,
        style: TextStyle(
          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Modern Slider Thumb
class ModernSliderThumb extends SliderComponentShape {
  final double thumbRadius;
  final bool isDark;
  final Color primaryColor;
  
  ModernSliderThumb({
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
    final canvas = context.canvas;
    
    // Shadow
    final shadowPaint = Paint()
      ..color = isDark 
        ? Colors.black.withOpacity(0.4)
        : Colors.grey.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center.translate(0, 2), thumbRadius, shadowPaint);
    
    // Main thumb
    final thumbPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius, thumbPaint);
    
    // White inner circle
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius * 0.4, innerPaint);
  }
}

Future<Set<String>?> selectIngredients(
  BuildContext context,
  List<String> initialIngredients,
) {
  final Set<String> unwanted = {};
  return showDialog<Set<String>>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400.w,
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 15.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.r),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.blueGrey.withOpacity(0.20),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.tealAccent.withOpacity(0.5),
              width: 1.2.w,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 0.70 * MediaQuery.of(context).size.height,
              minHeight: 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Select Ingredients",
                  style: TextStyle(
                    fontSize: 21.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor(context),
                  ),
                ),
                SizedBox(height: 18.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      alignment: WrapAlignment.center, // <-- Center the chips
                      spacing: 5.w, // chip gap
                      runSpacing: 5.h,
                      children: [
                        for (final ing in initialIngredients)
                          GestureDetector(
                            onTap: () => setState(() {
                              if (unwanted.contains(ing)) {
                                unwanted.remove(ing);
                              } else {
                                unwanted.add(ing);
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 170),
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w, //chip size
                                vertical: 5.h,
                              ),
                              margin: EdgeInsets.symmetric(vertical: 2.h),
                              decoration: BoxDecoration(
                                color: unwanted.contains(ing)
                                    ? Colors.redAccent.shade100
                                    : Colors.greenAccent.shade100,
                                borderRadius: BorderRadius.circular(12.r), //chip border
                                border: Border.all(
                                  color: unwanted.contains(ing)
                                      ? Colors.red.shade900
                                      : Colors.green.shade900,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    unwanted.contains(ing)
                                        ? Icons.close_rounded
                                        : Icons.check_circle_rounded,
                                    color: unwanted.contains(ing)
                                        ? Colors.red[50]
                                        : Colors.white,
                                    size: 12.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    ing,
                                    style: TextStyle(
                                      color: unwanted.contains(ing)
                                          ? Colors.red[50]
                                          : Colors.black,
                                      fontSize: 11.sp, //chip font size
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ).asGlass(
                              tintColor: unwanted.contains(ing)
                                  ? Colors.red.shade100
                                  : Colors.green.shade100,
                              blurX: 10,
                              blurY: 10,
                              clipBorderRadius: BorderRadius.circular(12.r),
                              frosted: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent.shade100,
                        textStyle: TextStyle(fontSize: 15.sp),
                      ),
                      onPressed: () => Navigator.pop(ctx, null),
                      child: const Text("Cancel"),
                    ),
                    SizedBox(width: 16.w),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        backgroundColor: Colors.tealAccent.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx, unwanted),
                      child: Text("Proceed", style: TextStyle(fontSize: 15.sp)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).asGlass(
          blurX: 17,
          blurY: 17,
          tintColor: Colors.white.withOpacity(0.09),
          clipBorderRadius: BorderRadius.circular(20.r),
          frosted: true,
        ),
      ),
    ),
  );
}
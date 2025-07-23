// ignore_for_file: deprecated_member_use

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
        final cardColor = isDark ? Colors.grey.shade900 : Colors.grey.shade50;
        final surfaceColor = isDark ? Colors.grey.shade800 : Colors.white;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 340.w,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              color: surfaceColor.withOpacity(isDark ? 0.93 : 0.98),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.13),
                  blurRadius: 32,
                  offset: Offset(0, 18.h),
                ),
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
                    color: isDark ? Colors.grey.shade100 : Colors.grey.shade900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 32.h),

                // Multi-Hour Clock
                GestureDetector(
                  onTapDown: (_) {
                    setState(() => isPressed = true);
                    HapticFeedback.lightImpact();
                  },
                  onTapUp: (_) => setState(() => isPressed = false),
                  onTapCancel: () => setState(() => isPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    transform: Matrix4.identity()..scale(isPressed ? 0.96 : 1.0),
                    child: Container(
                      width: 200.w,
                      height: 200.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardColor.withOpacity(isDark ? 0.98 : 0.99),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.13),
                            blurRadius: isDark ? 24 : 18,
                            offset: Offset(0, 10.h),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        size: Size(180.w, 180.w),
                        painter: MultiHourClockPainter(
                          totalMinutes: tmpTime,
                          isDark: isDark,
                          color1: Colors.tealAccent.shade400,
                          color2: Colors.orange.shade400,
                          color3: Colors.red.shade400,
                        ),
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
                      color: primaryColor.withOpacity(0.28),
                      width: 1.w,
                    ),
                  ),
                  child: Text(
                    (tmpTime >= 60)
                        ? '${tmpTime ~/ 60}h ${tmpTime % 60 > 0 ? '${tmpTime % 60}m' : ''}'
                        : '${tmpTime} min',
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
                            '0 min',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '3h',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 5.h,
                          thumbColor: primaryColor,
                          thumbShape: ModernSliderThumb(
                            thumbRadius: 13.sp,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          overlayColor: primaryColor.withOpacity(0.14),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 22.sp),
                          trackShape: _CustomTrackShape(),
                        ),
                        child: Slider(
                          min: 0,
                          max: 180,
                          divisions: 36, // 5 min steps
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

                SizedBox(height: 32.h),

                // Action Buttons
                Row(
                  children: [
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
          ),
        );
      },
    ),
  );
}

// ============================
// Multi-Hour Clock Painter
// ============================
class MultiHourClockPainter extends CustomPainter {
  final int totalMinutes; // 0 to 180
  final bool isDark;
  final Color color1;
  final Color color2;
  final Color color3;

  MultiHourClockPainter({
    required this.totalMinutes,
    required this.isDark,
    required this.color1,
    required this.color2,
    required this.color3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final radius = size.width/2 - 10;
    final hourSegments = [
      {'start': 0, 'end': 60, 'color': color1},
      {'start': 60, 'end': 120, 'color': color2},
      {'start': 120, 'end': 180, 'color': color3},
    ];

    // Glassy circular background and subtle glow
    final glassPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
          ? [Colors.black.withOpacity(0.92), Colors.grey[900]!.withOpacity(0.82)]
          : [Colors.white.withOpacity(0.97), Colors.grey[100]!.withOpacity(0.90)],
        radius: 1.18,
      ).createShader(Rect.fromCircle(center: center, radius: radius+13));
    canvas.drawCircle(center, radius + 13, glassPaint);

    final glowPaint = Paint()
      ..color = color1.withOpacity(0.11)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(center, radius + 6, glowPaint);

    // Draw colored progress for each hour
    int remaining = totalMinutes;
    for (final seg in hourSegments) {
      int value = (remaining > 60) ? 60 : remaining.clamp(0, 60);
      if (value > 0) {
        final paint = Paint()
          ..color = (seg['color'] as Color).withOpacity(0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 13;
        final startAngle = -math.pi/2 + (seg['start'] as int) / 60 * 2*math.pi;
        final sweep = value / 60 * 2*math.pi;
        canvas.drawArc(
          Rect.fromCircle(
            center: center, 
            radius: radius + 3 - 6 * ((seg['start'] as int) ~/ 60),
          ),
          startAngle, sweep, false, paint
        );
      }
      remaining -= 60;
    }

    // Draw ticks for each hour
    final tickPaint = Paint()
      ..color = isDark ? Colors.grey[500]! : Colors.grey[400]!
      ..strokeWidth = 2.0;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi/2;
      final len = (i % 3 == 0) ? 15.0 : 8.0;
      final start = Offset(
        center.dx + (radius-len) * math.cos(angle),
        center.dy + (radius-len) * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    // Draw hand (minute)
    final min = totalMinutes % 60;
    final hour = totalMinutes ~/ 60;
    final handAngle = (min / 60.0) * 2 * math.pi - math.pi/2;
    final handPaint = Paint()
      ..color = hour == 0 ? color1 : (hour == 1 ? color2 : color3)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(center.dx + (radius-22) * math.cos(handAngle),
             center.dy + (radius-22) * math.sin(handAngle)),
      handPaint
    );

    // Center dot
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, dotPaint);

    // Draw hours in center (if any)
    if (hour > 0) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: "${hour}h",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: hour == 1 ? color2 : color3,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 2,
                offset: Offset(0, 2),
              )
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas, 
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================
// Slider Thumb (Glowy Round)
// ==========================
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

    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(0.23)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, thumbRadius * 1.65, glowPaint);

    final thumbPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius, thumbPaint);

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius * 0.45, innerPaint);
  }
}

// ==========================
// Flat Track (Slider Visual)
// ==========================
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
    // Do nothing: visual is handled by Stack in your widget tree or the default.
  }
}

// ==========================
// Modern Button
// ==========================
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
                color: widget.primaryColor.withOpacity(0.25),
                blurRadius: 12,
                offset: Offset(0, 6.h),
              ),
            ],
            BoxShadow(
              color: widget.isDark
                  ? Colors.black.withOpacity(0.14)
                  : Colors.grey.withOpacity(0.08),
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
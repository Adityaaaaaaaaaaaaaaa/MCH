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
        final glassColor = isDark ? Colors.black.withOpacity(0.55) : Colors.white.withOpacity(0.5);
        final cardColor = isDark ? Colors.grey.shade900 : Colors.white.withOpacity(0.92);

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 350.w,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26.r),
              color: glassColor,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.tealAccent.withOpacity(0.08)
                      : Colors.teal.withOpacity(0.04),
                  blurRadius: 36,
                  offset: Offset(0, 20.h),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? Colors.tealAccent.shade400.withOpacity(0.13)
                    : Colors.teal.shade200.withOpacity(0.13),
                width: 0.8,
              ),
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
                    color: isDark ? Colors.white.withOpacity(0.95) : Colors.grey.shade900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 30.h),

                // Glassy/Glowy Clock
                GestureDetector(
                  onTapDown: (_) {
                    setState(() => isPressed = true);
                    HapticFeedback.lightImpact();
                  },
                  onTapUp: (_) => setState(() => isPressed = false),
                  onTapCancel: () => setState(() => isPressed = false),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    transform: Matrix4.identity()..scale(isPressed ? 0.96 : 1.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(120.r),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.tealAccent.withOpacity(0.06)
                              : Colors.teal.shade300.withOpacity(0.09),
                          blurRadius: 40,
                          spreadRadius: 6,
                          offset: Offset(0, 16.h),
                        ),
                      ],
                    ),
                    child: Container(
                      width: 205.w,
                      height: 205.w,
                      child: Stack(
                        children: [
                          // Glass and Frosted Layer
                          Container(
                            width: 205.w,
                            height: 205.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cardColor.withOpacity(isDark ? 0.82 : 0.7),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.tealAccent.withOpacity(0.11)
                                      : Colors.teal.shade200.withOpacity(0.09),
                                  blurRadius: 56,
                                  spreadRadius: 16,
                                  offset: Offset(0, 10.h),
                                ),
                              ],
                            ),
                          ).asGlass(
                            blurX: 14,
                            blurY: 14,
                            tintColor: Colors.transparent,
                            frosted: true,
                            clipBorderRadius: BorderRadius.circular(140.r),
                          ),
                          // Glowy Circular Progress Clock
                          CustomPaint(
                            size: Size(205.w, 205.w),
                            painter: FancyGlowyMultiHourClockPainter(
                              totalMinutes: tmpTime,
                              isDark: isDark,
                            ),
                          ),
                          // Center info (just a glowy dot for modern look)
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 18.w,
                              height: 18.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.92),
                                    (isDark ? Colors.tealAccent : Colors.teal)
                                        .withOpacity(0.33),
                                    Colors.transparent
                                  ],
                                  stops: [0.1, 0.45, 1],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? Colors.tealAccent : Colors.teal)
                                        .withOpacity(0.21),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 22.h),

                // Time Display (glassy, glowy)
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17.r),
                    color: isDark
                        ? Colors.tealAccent.shade400.withOpacity(0.08)
                        : Colors.teal.shade50.withOpacity(0.38),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.33),
                      width: 1.1.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.tealAccent.shade400.withOpacity(0.16)
                            : Colors.teal.shade100.withOpacity(0.13),
                        blurRadius: 22,
                        offset: Offset(0, 6.h),
                      ),
                    ],
                  ),
                  child: Text(
                    tmpTime == 0
                        ? '—'
                        : (tmpTime >= 60)
                            ? '${tmpTime ~/ 60}h ${tmpTime % 60 > 0 ? '${tmpTime % 60}m' : ''}'
                            : '$tmpTime min',
                    style: TextStyle(
                      fontSize: 27.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 0.2,
                      shadows: [
                        Shadow(
                          color: primaryColor.withOpacity(0.16),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 28.h),

                // Modern glassy/gradient Slider
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      // Labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0 min',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: isDark ? Colors.tealAccent.shade100 : Colors.teal.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '3h',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: isDark ? Colors.tealAccent.shade100 : Colors.teal.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 7.h),
                      Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 7.h,
                            margin: EdgeInsets.symmetric(horizontal: 24.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5.r),
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        Colors.tealAccent.shade400.withOpacity(0.22),
                                        Colors.tealAccent.shade400.withOpacity(0.04),
                                      ]
                                    : [
                                        Colors.teal.shade200.withOpacity(0.22),
                                        Colors.teal.shade50.withOpacity(0.04),
                                      ],
                              ),
                            ),
                          ),
                          // Filled progress
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (tmpTime) / 180,
                            child: Container(
                              height: 7.h,
                              margin: EdgeInsets.symmetric(horizontal: 24.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.r),
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          Colors.tealAccent.shade400.withOpacity(0.62),
                                          Colors.orangeAccent.withOpacity(0.32),
                                        ]
                                      : [
                                          Colors.teal.shade400.withOpacity(0.65),
                                          Colors.orangeAccent.withOpacity(0.24),
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.22),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 7.h,
                              thumbColor: primaryColor,
                              thumbShape: FancyGlassySliderThumb(
                                thumbRadius: 14.sp,
                                isDark: isDark,
                                primaryColor: primaryColor,
                              ),
                              overlayColor: primaryColor.withOpacity(0.22),
                              overlayShape: RoundSliderOverlayShape(overlayRadius: 22.sp),
                              trackShape: _CustomTrackShape(),
                              valueIndicatorShape: PaddleSliderValueIndicatorShape(),
                              valueIndicatorColor: Colors.transparent,
                              showValueIndicator: ShowValueIndicator.always,
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
                              label: tmpTime == 0
                                  ? '—'
                                  : tmpTime < 60
                                      ? '$tmpTime min'
                                      : '${tmpTime ~/ 60}h${tmpTime % 60 > 0 ? ' ${tmpTime % 60}m' : ''}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 28.h),

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

// ===============================
// Fancy Multi-Hour Glowy Clock
// ===============================
class FancyGlowyMultiHourClockPainter extends CustomPainter {
  final int totalMinutes; // 0–180 (3h max)
  final bool isDark;
  FancyGlowyMultiHourClockPainter({
    required this.totalMinutes,
    required this.isDark,
  });

  static final List<Color> hourColorsDark = [
    Colors.tealAccent,
    Colors.orangeAccent,
    Colors.redAccent,
  ];
  static final List<Color> hourColorsLight = [
    Colors.teal.shade400,
    Colors.orange.shade400,
    Colors.red.shade400,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 18;
    final List<Color> segmentColors = isDark ? hourColorsDark : hourColorsLight;

    // Glassy background
    final glassPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [Colors.grey[900]!.withOpacity(0.99), Colors.tealAccent.shade700.withOpacity(0.02)]
            : [Colors.white.withOpacity(0.96), Colors.teal.shade50.withOpacity(0.03)],
        radius: 1.2,
      ).createShader(Rect.fromCircle(center: center, radius: radius + 26));
    canvas.drawCircle(center, radius + 25, glassPaint);

    // Draw up to 3 progress arcs (each a full circle = 60 min)
    int mins = totalMinutes.clamp(0, 180);
    for (int lap = 0; lap < 3; lap++) {
      int thisLapMin = (mins >= 60) ? 60 : mins;
      if (lap > 0 && mins > 0) {
        // Glow ring for completed lap
        final glowPaint = Paint()
          ..color = segmentColors[lap - 1].withOpacity(0.13)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 15
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16);
        canvas.drawCircle(center, radius - 4, glowPaint);
      }
      if (thisLapMin > 0) {
        final arcPaint = Paint()
          ..color = segmentColors[lap].withOpacity(0.82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 13
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + lap * 4);
        final startAngle = -math.pi / 2;
        final sweep = (thisLapMin / 60) * 2 * math.pi;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweep,
          false,
          arcPaint,
        );
      }
      mins -= 60;
      if (mins <= 0) break;
    }

    // Ticks (same as before)
    final tickPaint = Paint()
      ..color = isDark ? Colors.tealAccent.shade100 : Colors.teal.shade400
      ..strokeWidth = 2.2;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final len = (i % 3 == 0) ? 16.0 : 7.0;
      final start = Offset(center.dx + (radius - len) * math.cos(angle), center.dy + (radius - len) * math.sin(angle));
      final end = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      canvas.drawLine(start, end, tickPaint);
    }

    // Time labels: "0", "15", "30", "45", "60"
    final labelStyle = TextStyle(
      fontSize: 12.sp,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black,
      letterSpacing: 0.5,
      shadows: [Shadow(color: Colors.black.withOpacity(0.15), blurRadius: 5)],
    );

    int lap = (totalMinutes ~/ 60);
    List<Map<int, String>> dynamicLabels = [
      {0: '0m', 15: '15m', 30: '30m', 45: '45m', 60: '60m'},
      {0: '1h', 15: '1h15m', 30: '1h30m', 45: '1h45m', 60: '2h'},
      {0: '2h', 15: '2h15m', 30: '2h30m', 45: '2h45m', 60: '3h'},
    ];
    // Clamp for safety
    final labelMap = dynamicLabels[lap.clamp(0, 2)];

    for (final entry in labelMap.entries) {
      final min = entry.key;
      final label = entry.value;
      final angle = (min / 60) * 2 * math.pi - math.pi / 2;
      final r = radius + 22;
      Offset offset = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      // Avoid overlap at top
      if (min == 0) offset = offset.translate(0, 13);
      if (min == 60) offset = offset.translate(0, -15);

      final painter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, offset - Offset(painter.width / 2, painter.height / 2));
    }

    // Draw hand (minute)
    final handMinute = totalMinutes % 60;
    final handAngle = (handMinute / 60) * 2 * math.pi - math.pi / 2;
    final hour = totalMinutes ~/ 60;
    final handPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.96), segmentColors[hour.clamp(0, 2)]],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(center.dx - 10, center.dy - 60, 20, 80))
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawLine(
      center,
      Offset(center.dx + (radius - 24) * math.cos(handAngle), center.dy + (radius - 24) * math.sin(handAngle)),
      handPaint,
    );

    // Optional: subtle hand glow
    final handGlow = Paint()
      ..color = segmentColors[hour.clamp(0, 2)].withOpacity(0.21)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(
      Offset(center.dx + (radius - 24) * math.cos(handAngle), center.dy + (radius - 24) * math.sin(handAngle)),
      10,
      handGlow,
    );

    // Center dot (glassy)
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================
// Glowy Glassy Slider Thumb
// ============================
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
    final canvas = context.canvas;

    final outerGlow = Paint()
      ..color = primaryColor.withOpacity(0.23)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, thumbRadius * 1.8, outerGlow);

    final thumbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(isDark ? 0.98 : 0.93),
          primaryColor.withOpacity(0.68),
        ],
        radius: 1.2,
      ).createShader(Rect.fromCircle(center: center, radius: thumbRadius));
    canvas.drawCircle(center, thumbRadius, thumbPaint);

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius * 0.4, innerPaint);
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
    // Do nothing: visual is handled by Stack in your widget tree.
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
        duration: Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(isPressed ? 0.96 : 1.0),
        height: 48.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17.r),
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
            if (!widget.isSecondary)
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.23),
                blurRadius: 16,
                offset: Offset(0, 7.h),
              ),
            BoxShadow(
              color: widget.isDark
                  ? Colors.black.withOpacity(0.13)
                  : Colors.grey.withOpacity(0.07),
              blurRadius: 8,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 17.sp,
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
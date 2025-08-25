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
  final ScrollController scrollController = ScrollController();

  return showDialog<Set<String>>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: 0.8 * MediaQuery.of(context).size.height,
              maxWidth: 400.w,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.r),
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        Color(0xFF1F2937).withOpacity(0.95),
                        Color(0xFF111827).withOpacity(0.90),
                      ]
                    : [
                        Colors.white.withOpacity(0.95),
                        Color(0xFFF9FAFB).withOpacity(0.90),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.grey[300]!.withOpacity(0.5),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                _buildCleanHeader(context, initialIngredients.length, unwanted.length),

                // Quick actions
                _buildQuickActions(context, initialIngredients, unwanted, setState),

                // Ingredient grid (use full list)
                Expanded(
                  child: _buildIngredientGrid(
                    context,
                    initialIngredients, // Always show all ingredients
                    unwanted,
                    setState,
                    scrollController,
                  ),
                ),

                // Action buttons
                _buildActionBar(context, unwanted, ctx),
              ],
            ),
          ).asGlass(
            blurX: 40,
            blurY: 40,
            tintColor: Theme.of(context).brightness == Brightness.dark
                ? Color(0xFF1F2937).withOpacity(0.2)
                : Colors.white.withOpacity(0.3),
            clipBorderRadius: BorderRadius.circular(28.r),
            frosted: true,
          ),
        );
      },
    ),
  );
}

Widget _buildCleanHeader(BuildContext context, int totalCount, int excludedCount) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 10.h),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(28.r),
        topRight: Radius.circular(28.r),
      ),
      gradient: LinearGradient(
        colors: isDark
            ? [
                Color(0xFF3B82F6).withOpacity(0.3),
                Color(0xFF1E40AF).withOpacity(0.1),
              ]
            : [
                Color(0xFF3B82F6).withOpacity(0.15),
                Color(0xFF60A5FA).withOpacity(0.05),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
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
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.1),
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                color: isDark ? Colors.blue[300] : Colors.blue[600],
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Ingredients",
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: textColor(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Tap to exclude ingredients you don't want",
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: textColor(context).withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            _buildStatChip("Selected", (totalCount - excludedCount).toString(), Colors.green),
            SizedBox(width: 12.w),
            _buildStatChip("Excluded", excludedCount.toString(), Colors.red),
            SizedBox(width: 12.w),
            _buildStatChip("Total", totalCount.toString(), Colors.blue),
          ],
        ),
      ],
    ),
  );
}

Widget _buildStatChip(String label, String value, Color color) {
  return Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildQuickActions(BuildContext context, List<String> ingredients, Set<String> unwanted, StateSetter setState) {
  return Container(
    height: 40.h,
    margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
    child: Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            "Select All",
            Icons.check_circle_outline_rounded,
            Colors.green,
            () {
              setState(() {
                unwanted.clear();
              });
            },
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildQuickActionButton(
            "Clear All",
            Icons.remove_circle_outline_rounded,
            Colors.red,
            () {
              setState(() {
                unwanted.addAll(ingredients);
              });
            },
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildQuickActionButton(
            "Invert",
            Icons.swap_horiz_rounded,
            Colors.orange,
            () {
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

Widget _buildQuickActionButton(String text, IconData icon, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 14.sp),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildIngredientGrid(
  BuildContext context,
  List<String> ingredients,
  Set<String> unwanted,
  StateSetter setState,
  ScrollController scrollController,
) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 20.w),
    child: GridView.builder(
      controller: scrollController,
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 12.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 10.h,
      ),
      itemCount: ingredients.length,
      itemBuilder: (context, index) => _buildIngredientChip(
        ingredients[index],
        unwanted.contains(ingredients[index]),
        context,
        () => setState(() {
          final ing = ingredients[index];
          if (unwanted.contains(ing)) {
            unwanted.remove(ing);
          } else {
            unwanted.add(ing);
          }
        }),
        index,
      ),
    ),
  );
}

Widget _buildIngredientChip(
  String ingredient,
  bool isUnwanted,
  BuildContext context,
  VoidCallback onTap,
  int index,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return TweenAnimationBuilder<double>(
    duration: Duration(milliseconds: 200 + (index * 20)),
    tween: Tween(begin: 0.0, end: 1.0),
    builder: (context, value, child) {
      return Transform.scale(
        scale: 0.7 + (0.175 * value),
        child: Opacity(
          opacity: value,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  colors: isUnwanted
                      ? isDark
                          ? [
                              Colors.red[800]!.withOpacity(0.3),
                              Colors.red[900]!.withOpacity(0.2),
                            ]
                          : [
                              Colors.red[50]!.withOpacity(0.9),
                              Colors.red[100]!.withOpacity(0.6),
                            ]
                      : isDark
                          ? [
                              Colors.green[700]!.withOpacity(0.3),
                              Colors.green[800]!.withOpacity(0.2),
                            ]
                          : [
                              Colors.green[50]!.withOpacity(0.9),
                              Colors.green[100]!.withOpacity(0.6),
                            ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isUnwanted
                      ? isDark
                          ? Colors.red[400]!.withOpacity(0.5)
                          : Colors.red[300]!.withOpacity(0.7)
                      : isDark
                          ? Colors.green[400]!.withOpacity(0.5)
                          : Colors.green[300]!.withOpacity(0.7),
                  width: 1.5.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUnwanted ? Colors.red : Colors.green)
                        .withOpacity(0.15),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      child: Icon(
                        isUnwanted
                            ? Icons.remove_circle_rounded
                            : Icons.check_circle_rounded,
                        key: ValueKey(isUnwanted),
                        color: isUnwanted
                            ? isDark ? Colors.red[300] : Colors.red[600]
                            : isDark ? Colors.green[300] : Colors.green[600],
                        size: 16.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        ingredient,
                        style: TextStyle(
                          color: isUnwanted
                              ? isDark ? Colors.red[200] : Colors.red[700]
                              : isDark ? Colors.green[200] : Colors.green[700],
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ).asGlass(
              tintColor: isUnwanted
                  ? Colors.red.withOpacity(0.05)
                  : Colors.green.withOpacity(0.05),
              blurX: 15,
              blurY: 15,
              clipBorderRadius: BorderRadius.circular(16.r),
              frosted: true,
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildActionBar(BuildContext context, Set<String> unwanted, BuildContext ctx) {  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildActionButton(
            text: "Cancel",
            isPrimary: false,
            context: context,
            onPressed: () => Navigator.pop(ctx, null),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 3,
          child: _buildActionButton(
            text: "Continue",
            isPrimary: true,
            context: context,
            onPressed: () => Navigator.pop(ctx, unwanted),
          ),
        ),
      ],
    ),
  );
}

Widget _buildActionButton({
  required String text,
  required bool isPrimary,
  required BuildContext context,
  required VoidCallback onPressed,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return SizedBox(
    height: 40.h,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: EdgeInsets.zero,
      ),
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: isPrimary
              ? LinearGradient(
                  colors: isDark
                      ? [Colors.blue[600]!, Colors.blue[700]!]
                      : [Colors.blue[500]!, Colors.blue[600]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  colors: isDark
                      ? [
                          Colors.grey[700]!.withOpacity(0.6),
                          Colors.grey[800]!.withOpacity(0.4),
                        ]
                      : [
                          Colors.grey[100]!.withOpacity(0.8),
                          Colors.grey[200]!.withOpacity(0.6),
                        ],
                ),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : isDark
                    ? Colors.grey[600]!.withOpacity(0.3)
                    : Colors.grey[300]!.withOpacity(0.5),
            width: 1.w,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: isPrimary
                  ? Colors.white
                  : isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
      ).asGlass(
        tintColor: isPrimary
            ? Colors.transparent
            : isDark
                ? Colors.grey[700]!.withOpacity(0.1)
                : Colors.white.withOpacity(0.4),
        blurX: isPrimary ? 0 : 15,
        blurY: isPrimary ? 0 : 15,
        clipBorderRadius: BorderRadius.circular(16.r),
        frosted: !isPrimary,
      ),
    ),
  );
}
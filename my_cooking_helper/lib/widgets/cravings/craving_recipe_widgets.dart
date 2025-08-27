// lib/widgets/cravings/craving_recipe_widgets.dart
// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import '/models/cravings.dart';
import '/utils/colors.dart';

/// ------------------------------------------------------------
/// GLASSY BASE - Enhanced with vibrant colors and effects
/// ------------------------------------------------------------
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 22,
    this.tint,
    this.blur = 10,
    this.padding,
    this.gradient,
    this.strokeColor,
    this.strokeWidth,
    this.glowColor,
    this.animated = false,
    this.interactive = false,
    this.vibrantBorder = false,
  });

  final Widget child;
  final double radius;
  final Color? tint;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final Color? strokeColor;
  final double? strokeWidth;
  final Color? glowColor;
  final bool animated;
  final bool interactive;
  final bool vibrantBorder;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _borderController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _borderAnimation;
  // ignore: unused_field
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _borderController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
    _borderAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.linear),
    );

    if (widget.vibrantBorder) {
      _borderController.repeat();
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tintColor = widget.tint ??
        (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.35));
    final border = widget.strokeColor ?? 
        (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08));

    Widget container = GestureDetector(
      onTapDown: widget.interactive ? (_) => _hoverController.forward() : null,
      onTapUp: widget.interactive ? (_) => _hoverController.reverse() : null,
      onTapCancel: widget.interactive ? () => _hoverController.reverse() : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _glowAnimation, _borderAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.interactive ? _scaleAnimation.value : 1.0,
            child: Stack(
              children: [
                // ✅ Animated border sized to the Stack
                if (widget.vibrantBorder)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: VibrantBorderPainter(
                        _borderAnimation.value,
                        widget.radius.r,
                      ),
                    ),
                  ),

                // Main container (unchanged)
                Container(
                  margin:
                      widget.vibrantBorder ? EdgeInsets.all(2.w) : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius.r),
                    gradient: widget.gradient,
                    border: widget.vibrantBorder
                        ? null
                        : Border.all(
                            color: border,
                            width: widget.strokeWidth ?? 1.2,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.4)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                      if (widget.interactive)
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 32,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      if (widget.glowColor != null)
                        BoxShadow(
                          color: widget.glowColor!.withOpacity(isDark ? 0.25 : 0.15),
                          blurRadius: 32,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: (widget.padding != null
                          ? Padding(padding: widget.padding!, child: widget.child)
                          : widget.child)
                      .asGlass(
                    tintColor: tintColor,
                    frosted: true,
                    blurX: widget.blur,
                    blurY: widget.blur,
                    clipBorderRadius: BorderRadius.circular(widget.radius.r),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (widget.animated) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: container,
            ),
          );
        },
      );
    }

    return container;
  }
}

class VibrantBorderPainter extends CustomPainter {
  final double animationValue;
  final double radius;

  VibrantBorderPainter(this.animationValue, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    
    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: animationValue,
      colors: const [
        Color(0xFF6366F1), // Indigo
        Color(0xFF8B5CF6), // Purple
        Color(0xFFEC4899), // Pink
        Color(0xFFF59E0B), // Amber
        Color(0xFF10B981), // Emerald
        Color(0xFF3B82F6), // Blue
        Color(0xFF6366F1), // Back to Indigo
      ],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Enhanced hero image with particle effects
class GlassHeroImage extends StatefulWidget {
  const GlassHeroImage({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  State<GlassHeroImage> createState() => _GlassHeroImageState();
}

class _GlassHeroImageState extends State<GlassHeroImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      radius: 28,
      blur: 20,
      animated: true,
      interactive: true,
      vibrantBorder: true,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.purple.withOpacity(0.1),
                Colors.blue.withOpacity(0.05),
                Colors.pink.withOpacity(0.08),
              ]
            : [
                Colors.purple.withOpacity(0.15),
                Colors.blue.withOpacity(0.1),
                Colors.pink.withOpacity(0.12),
              ],
      ),
      padding: EdgeInsets.all(6.w),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.memory(widget.bytes, fit: BoxFit.cover),
            ),
          ),
          // Shimmer effect
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(_shimmerAnimation.value, -1),
                        end: Alignment(_shimmerAnimation.value + 0.5, 0),
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// SECTIONS with vibrant accents
/// ------------------------------------------------------------
class GlassSectionFancy extends StatelessWidget {
  const GlassSectionFancy({
    super.key,
    this.title,
    required this.child,
  });

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tc = textColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    
    return GlassCard(
      radius: 24,
      padding: EdgeInsets.all(20.w),
      animated: true,
      interactive: true,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                primary.withOpacity(0.08),
                Colors.purple.withOpacity(0.04),
                Colors.blue.withOpacity(0.06),
              ]
            : [
                primary.withOpacity(0.12),
                Colors.purple.withOpacity(0.08),
                Colors.blue.withOpacity(0.1),
              ],
      ),
      strokeColor: primary.withOpacity(isDark ? 0.2 : 0.15),
      glowColor: primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Container(
                  width: 4.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.r),
                    gradient: LinearGradient(
                      colors: [
                        primary,
                        primary.withOpacity(0.6),
                        Colors.purple.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tc,
                          letterSpacing: -0.3,
                          fontSize: 18.sp,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
          ],
          child,
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// TYPOGRAPHY with animated effects
/// ------------------------------------------------------------
class SubHeaderFancy extends StatefulWidget {
  const SubHeaderFancy(this.text, {super.key});
  final String text;

  @override
  State<SubHeaderFancy> createState() => _SubHeaderFancyState();
}

class _SubHeaderFancyState extends State<SubHeaderFancy>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    primary,
                    Colors.purple,
                    primary,
                  ],
                ).createShader(bounds);
              },
              child: Text(
                widget.text,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BulletLineFancy extends StatelessWidget {
  const BulletLineFancy({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final tc = textColor(context);
    final primary = Theme.of(context).colorScheme.primary;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 8.h, right: 16.w),
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primary,
                  Colors.purple,
                  primary.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tc.withOpacity(0.92),
                    height: 1.5,
                    fontSize: 15.sp,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// CHIPS with enhanced interactions
/// ------------------------------------------------------------
enum ChipTone { neutral, primary }

class TinyChipFancy extends StatefulWidget {
  const TinyChipFancy({
    super.key,
    required this.icon,
    required this.label,
    this.tone = ChipTone.neutral,
  });

  final IconData icon;
  final String label;
  final ChipTone tone;

  @override
  State<TinyChipFancy> createState() => _TinyChipFancyState();
}

class _TinyChipFancyState extends State<TinyChipFancy>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _colorController;
  late Animation<double> _pulseAnimation;
  Animation<Color?>? _colorAnimation; // <-- nullable now
  // ignore: unused_field
  bool _isPressed = false;

  bool _colorTweenInitialized = false; // guard to avoid re-creating tween

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _colorController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to access Theme here
    if (widget.tone == ChipTone.primary && !_colorTweenInitialized) {
      final primary = Theme.of(context).colorScheme.primary;
      _colorAnimation = ColorTween(
        begin: primary,
        end: Colors.purple,
      ).animate(_colorController);
      _colorController.repeat(reverse: true);
      _colorTweenInitialized = true;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.tone == ChipTone.primary
        ? Theme.of(context).colorScheme.primary
        : (isDark ? Colors.white : Colors.grey.shade700);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _pulseController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _pulseController.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _pulseController.reverse();
      },
      child: AnimatedBuilder(
        animation: widget.tone == ChipTone.primary
            ? Listenable.merge([
                _pulseAnimation,
                if (_colorAnimation != null) _colorAnimation!,
              ])
            : _pulseAnimation,
        builder: (context, child) {
          final currentColor = widget.tone == ChipTone.primary
              ? (_colorAnimation?.value ?? baseColor)
              : baseColor;

          return Transform.scale(
            scale: _pulseAnimation.value,
            child: GlassCard(
              radius: 18,
              blur: 12,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              tint: currentColor.withOpacity(isDark ? 0.15 : 0.12),
              strokeColor: currentColor.withOpacity(isDark ? 0.4 : 0.25),
              glowColor: widget.tone == ChipTone.primary ? currentColor : null,
              vibrantBorder: widget.tone == ChipTone.primary,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 16.sp,
                    color: widget.tone == ChipTone.primary
                        ? Colors.white
                        : textColor(context),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.tone == ChipTone.primary
                          ? Colors.white
                          : textColor(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PillTagFancy extends StatelessWidget {
  const PillTagFancy({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final tc = textColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GlassCard(
      radius: 20,
      blur: 10,
      interactive: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      tint: tc.withOpacity(isDark ? 0.1 : 0.08),
      strokeColor: tc.withOpacity(isDark ? 0.25 : 0.18),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.sp,
          color: tc.withOpacity(0.9),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class FlagTagFancy extends StatelessWidget {
  const FlagTagFancy({super.key, required this.text, required this.emoji});
  final String text;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final tc = textColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    
    return GlassCard(
      radius: 22,
      blur: 12,
      interactive: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      gradient: LinearGradient(
        colors: [
          primary.withOpacity(isDark ? 0.1 : 0.08),
          Colors.blue.withOpacity(isDark ? 0.05 : 0.04),
        ],
      ),
      strokeColor: primary.withOpacity(isDark ? 0.25 : 0.18),
      glowColor: primary.withOpacity(0.1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: Colors.white.withOpacity(isDark ? 0.15 : 0.25),
              border: Border.all(
                color: primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(emoji, style: TextStyle(fontSize: 16.sp)),
          ),
          SizedBox(width: 12.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: tc.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// DETAIL TILES with enhanced interactions
/// ------------------------------------------------------------
class IngredientTileFancy extends StatelessWidget {
  const IngredientTileFancy({super.key, required this.data});
  final dynamic data;

  @override
  Widget build(BuildContext context) {
    String label;
    if (data is String) {
      label = data;
    } else if (data is Map) {
      final name = (data['name'] ?? '').toString();
      final q = (data['quantity'] as num?)?.toDouble();
      final unit = (data['unit'] ?? '').toString();
      if (q == null || q == 0) {
        label = name;
      } else {
        final qStr = q % 1 == 0 ? q.toStringAsFixed(0) : q.toString();
        label = unit.isEmpty ? "$name — $qStr" : "$name — $qStr $unit";
      }
    } else {
      label = data.toString();
    }

    final tc = textColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GlassCard(
        radius: 18,
        blur: 10,
        interactive: true,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        gradient: LinearGradient(
          colors: [
            primary.withOpacity(isDark ? 0.08 : 0.06),
            Colors.green.withOpacity(isDark ? 0.04 : 0.03),
          ],
        ),
        strokeColor: primary.withOpacity(isDark ? 0.2 : 0.15),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                gradient: LinearGradient(
                  colors: [
                    primary,
                    Colors.green,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.eco_rounded,
                size: 16.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: tc.withOpacity(0.92),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InstructionTileFancy extends StatelessWidget {
  const InstructionTileFancy({super.key, required this.index, required this.text});
  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tc = textColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: GlassCard(
        radius: 20,
        blur: 10,
        interactive: true,
        padding: EdgeInsets.all(18.w),
        gradient: LinearGradient(
          colors: [
            primary.withOpacity(isDark ? 0.06 : 0.04),
            Colors.purple.withOpacity(isDark ? 0.04 : 0.02),
          ],
        ),
        strokeColor: primary.withOpacity(isDark ? 0.15 : 0.12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  colors: [primary, Colors.purple],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "$index",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 18.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Text(
                  text,
                  style: TextStyle(
                    color: tc.withOpacity(0.92),
                    fontSize: 15.sp,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShoppingTileFancy extends StatelessWidget {
  const ShoppingTileFancy({super.key, required this.item});
  final ShoppingItemModel item;

  @override
  Widget build(BuildContext context) {
    final need = item.need.toStringAsFixed(item.need % 1 == 0 ? 0 : 1);
    final have = item.have.toStringAsFixed(item.have % 1 == 0 ? 0 : 1);
    final isMissing = item.tag == 'missing';
    final tc = textColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final chipColor = isMissing
        ? (isDark ? Colors.amber.shade300 : Colors.amber.shade700)
        : Theme.of(context).colorScheme.tertiary;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GlassCard(
        radius: 20,
        interactive: true,
        vibrantBorder: isMissing,
        padding: EdgeInsets.all(18.w),
        gradient: LinearGradient(
          colors: [
            chipColor.withOpacity(isDark ? 0.1 : 0.06),
            chipColor.withOpacity(isDark ? 0.05 : 0.03),
          ],
        ),
        strokeColor: chipColor.withOpacity(isDark ? 0.2 : 0.15),
        glowColor: isMissing ? Colors.amber.withOpacity(0.2) : null,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  colors: [
                    chipColor,
                    chipColor.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: chipColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 18.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: tc.withOpacity(0.95),
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: tc.withOpacity(0.7),
                        fontSize: 13.sp,
                      ),
                      children: [
                        const TextSpan(text: "Need: "),
                        TextSpan(
                          text: "$need ${item.unit}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: " • Have: "),
                        TextSpan(
                          text: "$have ${item.unit}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                gradient: LinearGradient(
                  colors: [
                    chipColor.withOpacity(0.2),
                    chipColor.withOpacity(0.15),
                  ],
                ),
                border: Border.all(color: chipColor.withOpacity(0.5)),
              ),
              child: Text(
                item.tag.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: chipColor,
                  fontSize: 11.sp,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// ENHANCED CAUTION FOOTER with popup and animations
/// ------------------------------------------------------------
// --- Revamped, tappable, serious caution bar ---
class AiCautionBarFancy extends StatefulWidget {
  const AiCautionBarFancy({super.key});

  @override
  State<AiCautionBarFancy> createState() => _AiCautionBarFancyState();
}

class _AiCautionBarFancyState extends State<AiCautionBarFancy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _borderController;
  late final Animation<double> _borderAnim;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _borderAnim = Tween<double>(begin: 0, end: 2 * 3.1415926535).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  void _toggle() => setState(() => _open = !_open);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = textColor(context);

    // Neutral, serious palette
    final baseTint = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.22);
    final borderCol = (isDark ? Colors.red[300] : Colors.red[700])!.withOpacity(0.25);
    final iconAccent = isDark ? Colors.amber[300] : Colors.amber[700];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main bar (always visible)
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(18.r),
          child: GlassCard(
            radius: 18,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            tint: baseTint,
            strokeColor: borderCol,
            blur: 10,
            child: Row(
              children: [
                // Animated border badge
                AnimatedBuilder(
                  animation: _borderAnim,
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // rotating sweep ring
                        Transform.rotate(
                          angle: _borderAnim.value,
                          child: Container(
                            width: 34.w,
                            height: 34.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  (isDark ? Colors.red[400] : Colors.red[600])!.withOpacity(0.00),
                                  (isDark ? Colors.red[400] : Colors.red[600])!.withOpacity(0.45),
                                  (isDark ? Colors.orange[400] : Colors.orange[700])!.withOpacity(0.65),
                                  (isDark ? Colors.amber[300] : Colors.amber[700])!.withOpacity(0.45),
                                  (isDark ? Colors.red[400] : Colors.red[600])!.withOpacity(0.00),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // inner cutout + icon
                        Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.black.withOpacity(0.75) : Colors.white,
                            border: Border.all(
                              color: (isDark ? Colors.red[200] : Colors.red[600])!.withOpacity(0.25),
                              width: 1.4,
                            ),
                          ),
                          child: Icon(
                            Icons.psychology_rounded,
                            size: 16.sp,
                            color: iconAccent,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(width: 12.w),
                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI-generated recipe",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.sp,
                          letterSpacing: 0.2,
                          color: tc,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "Review safety notes before cooking",
                        style: TextStyle(
                          color: tc.withOpacity(0.72),
                          fontSize: 12.5.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 20.sp,
                  color: tc.withOpacity(0.9),
                ),
              ],
            ),
          ),
        ),

        // Collapsible content (expands below; never blocks taps)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: !_open
              ? const SizedBox.shrink()
              : Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: GlassCard(
                    radius: 16,
                    padding: EdgeInsets.all(14.w),
                    tint: isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.white.withOpacity(0.18),
                    strokeColor: (isDark ? Colors.grey[400] : Colors.grey[700])!.withOpacity(0.25),
                    blur: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _point(context, "Verify ingredient quantities and taste as you go."),
                        _point(context, "Double-check allergens and dietary restrictions."),
                        _point(context, "Validate cooking times/temperatures for doneness."),
                        _point(context, "Follow standard food-safety practices."),
                        _point(context, "Consult a professional for medical or dietary advice."),
                        _point(context, "Check for raw or undercooked ingredients."),
                        _point(context, "Be cautious with unfamiliar ingredients or techniques."),
                        _point(context, "Adjust recipes for children, elderly, or immunocompromised."),
                        _point(context, "Do not rely on AI for emergency or critical health situations."),
                        SizedBox(height: 10.h),
                        Text(
                          "Use this as inspiration, not medical or professional advice.",
                          style: TextStyle(
                            color: tc.withOpacity(0.8),
                            fontSize: 12.5.sp,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _toggle,
                            icon: const Icon(Icons.check_circle_outline_rounded),
                            label: const Text("Got it"),
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? Colors.amber[300] : Colors.amber[800],
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _point(BuildContext context, String text) {
    final tc = textColor(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 7.h),
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.red[300]
                      : Colors.red[700])!
                  .withOpacity(0.85),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: tc.withOpacity(0.95),
                fontSize: 13.5.sp,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// CUISINE → FLAG EMOJI (Updated with actual country flags)
/// ------------------------------------------------------------
String cuisineFlagEmoji(String name) {
  final key = name.trim().toLowerCase();
  const map = {
    'italian': '🇮🇹',
    'asian': '🌏', // General Asia
    'caribbean': '🏝️', // Caribbean islands
    'eastern european': '🇷🇺',
    'european': '🇪🇺',
    'irish': '🇮🇪',
    'latin american': '🌎', // Latin America
    'chinese': '🇨🇳',
    'mexican': '🇲🇽',
    'indian': '🇮🇳',
    'japanese': '🇯🇵',
    'thai': '🇹🇭',
    'korean': '🇰🇷',
    'vietnamese': '🇻🇳',
    'spanish': '🇪🇸',
    'french': '🇫🇷',
    'middle eastern': '🇱🇧', // Lebanon as representative
    'mediterranean': '🇬🇷',
    'american': '🇺🇸',
    'british': '🇬🇧',
    'greek': '🇬🇷',
    'german': '🇩🇪',
    'mauritian': '🇲🇺',
    'other': '🌍',
  };
  return map[key] ?? '🌍';
}
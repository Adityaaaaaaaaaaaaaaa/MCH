// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import '/models/cravings.dart';
import '/utils/colors.dart';

/// ------------------------------------------------------------
/// MODERN CARD WITH ANIMATED GRADIENT BORDERS (+ glass blur)
/// - subtle gradient border in both light/dark
/// - optional sweep animated border
/// - lightweight tap pulse + scale (no shader masks, smooth perf)
/// ------------------------------------------------------------
class ModernCard extends StatefulWidget {
  const ModernCard({
    super.key,
    required this.child,
    this.radius = 16,
    this.padding,
    this.margin,
    this.gradient,
    this.animatedBorder = false,
    this.borderWidth = 2.0,
    this.shadowIntensity = 1.0,
    this.onTap,
    this.enableTapPulse = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final bool animatedBorder;
  final double borderWidth;
  final double shadowIntensity;
  final VoidCallback? onTap;
  final bool enableTapPulse;

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard> with TickerProviderStateMixin {
  late final AnimationController _borderController;
  late final AnimationController _pressController;
  late final AnimationController _pulseController;
  late final Animation<double> _borderAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseOpacity;
  late final Animation<double> _pulseRadius;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 110),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );

    _borderAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.linear),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );

    _pulseOpacity = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
    );
    _pulseRadius = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
    );

    if (widget.animatedBorder) _borderController.repeat();
  }

  @override
  void dispose() {
    _borderController.dispose();
    _pressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.enableTapPulse) {
      _pulseController
        ..value = 0
        ..forward();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCol = isDark ? const Color(0xFF151515) : const Color(0xFFFDFDFE);
    final subtleBorder = LinearGradient(
      colors: isDark
          ? [Colors.white.withOpacity(.09), Colors.white.withOpacity(.04)]
          : [Colors.black.withOpacity(.06), Colors.black.withOpacity(.03)],
    );

    final content = RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_borderAnimation, _scaleAnimation, _pulseController]),
        builder: (context, _) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.margin,
              child: Stack(
                children: [
                  if (widget.animatedBorder)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _AnimatedBorderPainter(
                          animation: _borderAnimation.value,
                          radius: widget.radius,
                          borderWidth: widget.borderWidth,
                          isDark: isDark,
                        ),
                      ),
                    ),

                  // Static pretty border if not animated
                  if (!widget.animatedBorder)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.radius.r),
                          border: Border.all(width: 1.3, color: Colors.transparent),
                          gradient: null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(widget.radius.r),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(widget.radius.r),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(.12)
                                    : Colors.black.withOpacity(.10),
                                width: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Main glass container
                  Container(
                    margin: widget.animatedBorder
                        ? EdgeInsets.all(widget.borderWidth)
                        : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.radius.r),
                      color: bgCol,
                      gradient: widget.gradient ?? subtleBorder,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.35 * widget.shadowIntensity)
                              : Colors.black.withOpacity(0.06 * widget.shadowIntensity),
                          blurRadius: 18 * widget.shadowIntensity,
                          offset: Offset(0, 8 * widget.shadowIntensity),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.radius.r),
                      child: widget.padding != null
                          ? Padding(padding: widget.padding!, child: widget.child)
                          : widget.child,
                    ),
                  ).asGlass(
                    blurX: 8,
                    blurY: 8,
                    tintColor: isDark
                        ? Colors.white.withOpacity(0.03)
                        : Colors.white.withOpacity(0.22),
                    frosted: true,
                    clipBorderRadius: BorderRadius.circular(widget.radius.r),
                  ),

                  // Tap pulse (one-shot)
                  if (widget.enableTapPulse)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: _pulseOpacity.value,
                          child: CustomPaint(
                            painter: _PulsePainter(
                              progress: _pulseRadius.value,
                              color: (isDark
                                      ? Colors.white.withOpacity(0.35)
                                      : Colors.black.withOpacity(0.25))
                                  .withOpacity(0.16),
                              radius: widget.radius,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          _handleTap();
        },
        onTapCancel: () => _pressController.reverse(),
        child: content,
      );
    }
    return content;
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.progress, required this.color, required this.radius});
  final double progress;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide * 0.66;
    // ignore: unused_local_variable
    final r = maxR * progress;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * (1 - progress)
      ..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size.width, height: size.height),
        Radius.circular(radius),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PulsePainter old) => old.progress != progress || old.color != color;
}

class _AnimatedBorderPainter extends CustomPainter {
  final double animation;
  final double radius;
  final double borderWidth;
  final bool isDark;

  _AnimatedBorderPainter({
    required this.animation,
    required this.radius,
    required this.borderWidth,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: animation,
      endAngle: animation + 2 * math.pi,
      colors: isDark
          ? const [
              Color(0xFF00D4FF),
              Color(0xFF7B2FF7),
              Color(0xFFFF107F),
              Color(0xFFFFB800),
              Color(0xFF00FF94),
              Color(0xFF00D4FF),
            ]
          : const [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
              Color(0xFFF093FB),
              Color(0xFF7EE8FA),
              Color(0xFF80FF72),
              Color(0xFF667EEA),
            ],
      stops: const [0, .2, .4, .6, .8, 1],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedBorderPainter old) =>
      old.animation != animation || old.isDark != isDark || old.borderWidth != borderWidth;
}

/// ------------------------------------------------------------
/// HERO IMAGE WITH SHIMMER
/// ------------------------------------------------------------
class ModernHeroImage extends StatefulWidget {
  const ModernHeroImage({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  State<ModernHeroImage> createState() => _ModernHeroImageState();
}

class _ModernHeroImageState extends State<ModernHeroImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ModernCard(
        radius: 20,
        animatedBorder: true,
        borderWidth: 2.0,
        shadowIntensity: 1.0,
        padding: EdgeInsets.all(3.w),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.memory(widget.bytes, fit: BoxFit.cover),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (_, __) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(_shimmerAnimation.value - 0.5, -0.5),
                          end: Alignment(_shimmerAnimation.value + 0.5, 0.5),
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// ANIMATED TIME BADGE (same animated border language)
/// Usage: ModernTimeBadge(minutes: model.readyInMinutes)
/// ------------------------------------------------------------
class ModernTimeBadge extends StatelessWidget {
  const ModernTimeBadge({super.key, required this.minutes});
  final int? minutes;

  String _format(int m) {
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}m';
    // e.g. 75 -> 1h 15m; 60 -> 1h
  }

  @override
  Widget build(BuildContext context) {
    if (minutes == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return RepaintBoundary(
      child: ModernCard(
        radius: 20,
        animatedBorder: true,
        borderWidth: 1.5,
        shadowIntensity: .8,
        enableTapPulse: true,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_rounded, size: 15.sp, color: primary),
            SizedBox(width: 6.w),
            Text(
              _format(minutes!),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14.sp,
                color: isDark ? Colors.white : Colors.white,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// SECTION CONTAINER
/// ------------------------------------------------------------
class ModernSection extends StatelessWidget {
  const ModernSection({
    super.key,
    this.title,
    required this.child,
    this.icon,
  });

  final String? title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return ModernCard(
      radius: 16,
      padding: EdgeInsets.all(16.w),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF1E1E1E), Color(0xFF181818)]
            : const [Color(0xFFFDFDFE), Color(0xFFF8F8FA)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    gradient: LinearGradient(
                      colors: [primary.withOpacity(0.95), primary.withOpacity(0.75)],
                    ),
                    border: Border.all(
                      color: textColor(context),
                      width: 1.1,
                    ),
                  ),
                  child: Icon(icon ?? Icons.auto_awesome_rounded,
                      color: Colors.white, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title!,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, primary.withOpacity(0.22), Colors.transparent],
                ),
              ),
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
/// SUBHEADER / BULLET
/// ------------------------------------------------------------
class ModernSubHeader extends StatelessWidget {
  const ModernSubHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 4.w,
          height: 22.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.r),
            gradient: LinearGradient(colors: [primary, primary.withOpacity(0.6)]),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class ModernBulletPoint extends StatelessWidget {
  const ModernBulletPoint({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 7.h),
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [textColor(context), textColor(context).withOpacity(0.6)]),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: textColor(context),
                fontSize: 12.sp,
                height: 1.5,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// PREMIUM CHIPS / TAGS
/// ------------------------------------------------------------
class PremiumChip extends StatelessWidget {
  const PremiumChip({
    super.key,
    required this.icon,
    required this.label,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final bg = isPrimary
        ? primary.withOpacity(0.15)
        : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06));
    final border = isPrimary
        ? primary.withOpacity(0.40)
        : (isDark ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.12));
    final content = isPrimary ? primary : (isDark ? Colors.white : Colors.black87);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: bg,
        border: Border.all(color: border, width: 1.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: content),
          SizedBox(width: 6.w),
          Text(label,
                style: TextStyle(
                  color: content, 
                  fontWeight: FontWeight.w600, 
                  fontSize: 12.5.sp
                )
              ),
        ],
      ),
    );
  }
}

class ModernPillTag extends StatelessWidget {
  const ModernPillTag({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.04)]
              : [Colors.black.withOpacity(0.06), Colors.black.withOpacity(0.03)],
        ),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.12),
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5.sp,
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class ModernFlagTag extends StatelessWidget {
  const ModernFlagTag({super.key, required this.text, required this.emoji});
  final String text;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
              : [const Color(0xFFF5F5F5), const Color(0xFFEEEEEE)],
        ),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.12),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: 15.sp)),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// ENHANCED INGREDIENT TILE
/// - supports: String | Map | ShoppingItemModel
/// - only shows shopping toggle when tag == 'buy'
/// - tag == 'optional' -> shows Optional badge
/// - shows need/unit/have and delta
/// - no "count" word (empty unit for count)
/// ------------------------------------------------------------
// -------------------- ModernIngredientTile (revamped layout) --------------------
// TOP-LEVEL (keep this where you already had it)
enum _ShopVariant { bag, plus }

// -------------------- ModernIngredientTile --------------------
class ModernIngredientTile extends StatefulWidget {
  const ModernIngredientTile({
    super.key,
    required this.data,
    this.initiallyInShopping = false,     // kept but NOT used to auto-activate
    this.onToggleShopping,
    this.shopping,                        // List<ShoppingItemModel>
    this.optionalIngredients,             // List<dynamic>
    this.selectAllSignal,                 // broadcast: CTA → tiles
    this.selectionDirtySignal,            // broadcast: tiles → CTA when a control is turned OFF
  });

  final dynamic data; // Map<String,dynamic> | String | ShoppingItemModel
  final bool initiallyInShopping;
  final VoidCallback? onToggleShopping;
  final List<ShoppingItemModel>? shopping;
  final List<dynamic>? optionalIngredients;
  final ValueNotifier<int>? selectAllSignal;
  final ValueNotifier<int>? selectionDirtySignal;

  @override
  State<ModernIngredientTile> createState() => _ModernIngredientTileState();
}

class _ModernIngredientTileState extends State<ModernIngredientTile>
    with SingleTickerProviderStateMixin {
  // independent internal states (both start INACTIVE)
  bool bagSelected = false;
  bool plusSelected = false;

  late final AnimationController _bounceController;
  late final Animation<double> _bounce;
  VoidCallback? _selectAllListener;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _bounce = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    // Listen to CTA broadcast: set the visible control ACTIVE (never toggle)
    if (widget.selectAllSignal != null) {
      _selectAllListener = () {
        final variant = _computeVariant();
        if (variant == _ShopVariant.bag && !bagSelected) {
          setState(() => bagSelected = true);
        } else if (variant == _ShopVariant.plus && !plusSelected) {
          setState(() => plusSelected = true);
        }
      };
      widget.selectAllSignal!.addListener(_selectAllListener!);
    }
  }

  @override
  void dispose() {
    if (_selectAllListener != null && widget.selectAllSignal != null) {
      widget.selectAllSignal!.removeListener(_selectAllListener!);
    }
    _bounceController.dispose();
    super.dispose();
  }

  void _pulse() => _bounceController..value = 0..forward();

  void _notifyDirtyIfDeselected(bool newValue) {
    if (!newValue && widget.selectionDirtySignal != null) {
      widget.selectionDirtySignal!.value = widget.selectionDirtySignal!.value + 1;
    }
  }

  // ------ parsing helpers ---------------------------------------------------
  String _norm(String s) => s.trim().toLowerCase();

  String _extractName(dynamic e) {
    if (e == null) return '';
    if (e is String) return e;
    if (e is ShoppingItemModel) return e.name;
    if (e is Map) {
      final v = e['name'] ?? e['original'] ?? e['title'];
      return v?.toString() ?? e.toString();
    }
    return e.toString();
  }

  ShoppingItemModel? _findShoppingItemByName(String name) {
    final list = widget.shopping;
    if (list == null || name.isEmpty) return null;
    final n = _norm(name);
    for (final s in list) {
      if (_norm(s.name) == n) return s;
    }
    return null;
  }

  bool _isOptionalByName(String name) {
    final opts = widget.optionalIngredients;
    if (opts == null || name.isEmpty) return false;
    final n = _norm(name);
    for (final e in opts) {
      if (_norm(_extractName(e)) == n) return true;
    }
    return false;
  }

  bool _pantryLikely(dynamic data) {
    if (data is Map) {
      final v = data['pantryLikely'] ?? data['pantry_likely'];
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
    }
    return true;
  }

  /// Decide which control this tile shows: bag if in shopping('buy'), else plus if pantryLikely==false, else none.
  _ShopVariant? _computeVariant() {
    // parse name & meta
    String name = "";
    String? dataTag;
    if (widget.data is String) {
      name = widget.data as String;
    } else if (widget.data is ShoppingItemModel) {
      final s = widget.data as ShoppingItemModel;
      name = s.name; dataTag = s.tag.toLowerCase();
    } else if (widget.data is Map) {
      final m = widget.data as Map;
      name = (m['name'] ?? '').toString();
      dataTag = (m['tag'] as String?)?.toLowerCase();
    }

    final shoppingItem = _findShoppingItemByName(name);
    final tag = (shoppingItem?.tag.toLowerCase()) ?? dataTag ?? '';
    if (shoppingItem != null && tag == 'buy') return _ShopVariant.bag;

    final pantry = _pantryLikely(widget.data);
    if (shoppingItem == null && pantry == false) return _ShopVariant.plus;

    return null; // show no control
  }

  // ------ UI helpers --------------------------------------------------------
  Widget _miniChip({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.32), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12.5.sp, color: color),
        SizedBox(width: 5.w),
        Text(text, style: TextStyle(color: color, fontSize: 12.0.sp, fontWeight: FontWeight.w700, letterSpacing: .2)),
      ]),
    );
  }

  Widget _statusChip({required IconData icon, required String label, required Color color, VoidCallback? onTap, bool elevated = false}) {
    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.38), width: 1.0),
        boxShadow: elevated ? [BoxShadow(color: color.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4))] : [],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13.sp, color: color),
        SizedBox(width: 4.w),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.5.sp, letterSpacing: .2)),
      ]),
    );
    return onTap == null ? chip : GestureDetector(onTap: onTap, child: chip);
  }

  Widget _controlButton({
    required bool active,
    required _ShopVariant variant,
    required Color primary,
    required Color okCol,
    required VoidCallback onTap,
  }) {
    final bgGrad = LinearGradient(
      colors: active ? [okCol.withOpacity(0.22), okCol.withOpacity(0.10)]
                     : [primary.withOpacity(0.16), primary.withOpacity(0.08)],
    );
    final borderCol = active ? okCol.withOpacity(0.48) : primary.withOpacity(0.28);
    final IconData icon = active
        ? (variant == _ShopVariant.plus ? Icons.check_circle_rounded : Icons.shopping_bag_rounded)
        : (variant == _ShopVariant.plus ? Icons.add_circle_rounded : Icons.shopping_bag_outlined);
    final iconColor = active ? okCol : primary;

    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, __) => Transform.scale(
        scale: _bounce.value,
        child: GestureDetector(
          onTap: () { _pulse(); onTap(); widget.onToggleShopping?.call(); },
          child: Container(
            width: 44.w, height: 44.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              gradient: bgGrad,
              border: Border.all(color: borderCol, width: 1.2),
              boxShadow: active ? [BoxShadow(color: okCol.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))] : [],
            ),
            child: Center(child: Icon(icon, size: 22.sp, color: iconColor)),
          ),
        ),
      ),
    );
  }

  // ------ build -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    // parse minimal quantities for chips (no auto-activation)
    String name = "", unit = "";
    double? need, have;
    if (widget.data is String) {
      name = widget.data as String;
    } else if (widget.data is ShoppingItemModel) {
      final s = widget.data as ShoppingItemModel;
      name = s.name; need = s.need; have = s.have; unit = s.unit.trim().toLowerCase();
    } else if (widget.data is Map) {
      final m = widget.data as Map;
      name = (m['name'] ?? '').toString();
      need = (m['need'] as num?)?.toDouble() ?? (m['quantity'] as num?)?.toDouble();
      have = (m['have'] as num?)?.toDouble();
      unit = ((m['unit'] ?? '').toString()).trim().toLowerCase();
    }

    final isOptional = _isOptionalByName(name);
    final shoppingItem = _findShoppingItemByName(name);
    final isMissing = (() {
      final tag = (shoppingItem?.tag.toLowerCase()) ?? '';
      return shoppingItem != null && tag == 'missing';
    })();

    String? qtyStr;
    if (need != null && need > 0) {
      final raw = (need % 1 == 0) ? need.toStringAsFixed(0) : need.toString();
      qtyStr = (unit.isEmpty || unit == 'count') ? raw : "$raw $unit";
    }
    String? haveStr;
    if (have != null && have > 0) {
      final raw = (have % 1 == 0) ? have.toStringAsFixed(0) : have.toString();
      haveStr = (unit.isEmpty || unit == 'count') ? raw : "$raw $unit";
    }

    final qtyColor = isDark ? Colors.cyan[300]! : Colors.cyan[700]!;
    final okCol    = isDark ? Colors.green[300]! : Colors.green[600]!;
    final warnCol  = isDark ? Colors.orange[300]! : Colors.orange[700]!;
    final missCol  = isDark ? Colors.red[300]! : Colors.red[600]!;

    final double iconSize = 44.w, gap = 12.w;
    final _ShopVariant? variant = _computeVariant();
    final bool active = (variant == _ShopVariant.bag) ? bagSelected : (variant == _ShopVariant.plus) ? plusSelected : false;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: ModernCard(
        radius: 14,
        padding: EdgeInsets.all(14.w),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isDark ? const [Color(0xFF242424), Color(0xFF1E1E1E)]
                         : const [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
        ),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // centered title
            Row(children: [
              SizedBox(width: iconSize + gap),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15.5.sp,
                    fontWeight: FontWeight.w800, letterSpacing: -0.2, height: 1.2),
                ),
              ),
              SizedBox(width: 44.w), // right button space (one control)
            ]),
            SizedBox(height: 10.h),

            // icon | chips | control (one of bag/plus or none)
            Row(children: [
              Container(
                width: iconSize, height: iconSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: LinearGradient(colors: [primary.withOpacity(0.18), primary.withOpacity(0.08)]),
                  border: Border.all(color: primary.withOpacity(0.25), width: 1.1),
                ),
                child: Icon(Icons.restaurant_menu_rounded, size: 20.sp, color: primary),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.start, spacing: 8.w, runSpacing: 6.h,
                  children: [
                    if (qtyStr != null) _miniChip(icon: Icons.inventory_2_rounded, text: qtyStr, color: qtyColor),
                    if (haveStr != null) _miniChip(icon: Icons.check_circle_rounded, text: "Have $haveStr", color: okCol),
                  ],
                ),
              ),
              if (variant != null)
                _controlButton(
                  active: active,
                  variant: variant,
                  primary: primary,
                  okCol: okCol,
                  onTap: () {
                    setState(() {
                      if (variant == _ShopVariant.bag) {
                        bagSelected = !bagSelected;
                        _notifyDirtyIfDeselected(bagSelected);
                      } else {
                        plusSelected = !plusSelected;
                        _notifyDirtyIfDeselected(plusSelected);
                      }
                    });
                  },
                )
              else
                SizedBox(width: 44.w, height: 44.w),
            ]),

            // badges line (only for the visible control + optional/missing)
            SizedBox(height: 10.h),
            Row(children: [
              SizedBox(width: iconSize + gap),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.center, spacing: 8.w, runSpacing: 6.h,
                  children: [
                    if (variant == _ShopVariant.bag)
                      _statusChip(
                        icon: active ? Icons.check_circle_rounded : Icons.shopping_bag_outlined,
                        label: active ? 'Buy — added' : 'Buy',
                        color: active ? okCol : primary,
                        onTap: () {
                          setState(() {
                            bagSelected = !bagSelected;
                            _notifyDirtyIfDeselected(bagSelected);
                          });
                        },
                        elevated: active,
                      ),
                    if (variant == _ShopVariant.plus)
                      _statusChip(
                        icon: active ? Icons.check_circle_rounded : Icons.add_circle_rounded,
                        label: active ? 'Add — added' : 'Add',
                        color: active ? okCol : primary,
                        onTap: () {
                          setState(() {
                            plusSelected = !plusSelected;
                            _notifyDirtyIfDeselected(plusSelected);
                          });
                        },
                        elevated: active,
                      ),
                    if (isOptional)
                      _statusChip(icon: Icons.info_outline_rounded, label: 'Optional', color: warnCol),
                    if (isMissing)
                      _statusChip(icon: Icons.report_gmailerrorred_rounded, label: 'Missing', color: missCol),
                  ],
                ),
              ),
              SizedBox(width: 44.w),
            ]),
          ],
        ),
      ),
    );
  }
}

class ModernCreateShoppingListButton extends StatefulWidget {
  const ModernCreateShoppingListButton({
    super.key,
    required this.selectAllSignal,
    required this.selectionDirtySignal,   // listen for any tile turning OFF
    this.onCreate,
  });

  final ValueNotifier<int> selectAllSignal;
  final ValueNotifier<int> selectionDirtySignal;
  final VoidCallback? onCreate;

  @override
  State<ModernCreateShoppingListButton> createState() => _ModernCreateShoppingListButtonState();
}

class _ModernCreateShoppingListButtonState extends State<ModernCreateShoppingListButton> {
  bool created = false;
  int _lastDirtyTick = 0;

  @override
  void initState() {
    super.initState();
    widget.selectionDirtySignal.addListener(_onDirty);
  }

  void _onDirty() {
    final v = widget.selectionDirtySignal.value;
    if (v != _lastDirtyTick) {
      _lastDirtyTick = v;
      if (created) setState(() => created = false); // revert to idle only when a tile deselects
    }
  }

  @override
  void dispose() {
    widget.selectionDirtySignal.removeListener(_onDirty);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final okCol   = isDark ? Colors.green[300]! : Colors.green[600]!;

    final bg = created ? LinearGradient(colors: [okCol.withOpacity(.22), okCol.withOpacity(.10)]) : null;
    final borderCol = created ? okCol.withOpacity(.55) : primary.withOpacity(.35);
    final textCol = created ? okCol : (isDark ? Colors.white : Colors.black87);
    final icon = created ? Icons.check_rounded : Icons.playlist_add_check_rounded;

    return GestureDetector(
      onTap: () {
        // idempotent: only sets ACTIVE, never toggles OFF
        widget.selectAllSignal.value = widget.selectAllSignal.value + 1;
        if (!created) setState(() => created = true);
        widget.onCreate?.call();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          gradient: bg,
          border: Border.all(color: borderCol, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: created ? okCol : primary, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              created ? "Shopping list created" : "Create shopping list",
              style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: textCol, letterSpacing: .1),
            ),
          ],
        ),
      ),
    );
  }
}


/// ------------------------------------------------------------
/// INSTRUCTION STEP TILE (justified text)
/// ------------------------------------------------------------
class ModernInstructionTile extends StatelessWidget {
  const ModernInstructionTile({
    super.key,
    required this.index,
    required this.text,
  });

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ModernCard(
        radius: 14,
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, primary.withOpacity(0.85)],
                ),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  "$index",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.justify,
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.92) : Colors.black87,
                  fontSize: 14.sp,
                  height: 1.5,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Nutrition chips (unchanged API, adds subtle bounce on tap) ----
class ModernNutritionChips extends StatelessWidget {
  const ModernNutritionChips({super.key, required this.nutrition});
  final Map<String, dynamic> nutrition;

  @override
  Widget build(BuildContext context) {
    final cal = nutrition['calories'];
    final p = nutrition['protein_g'];
    final f = nutrition['fat_g'];
    final c = nutrition['carbs_g'];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        if (cal != null)
          _TapBounce(
            child: PremiumChip(
              icon: Icons.local_fire_department_rounded,
              label: "$cal kcal",
              isPrimary: true,
            ),
          ),
        if (p != null)
          _TapBounce(
            child: PremiumChip(icon: Icons.egg_alt_rounded, label: "$p g protein"),
          ),
        if (f != null)
          _TapBounce(
            child: PremiumChip(icon: Icons.water_drop_rounded, label: "$f g fat"),
          ),
        if (c != null)
          _TapBounce(
            child: PremiumChip(icon: Icons.bakery_dining_rounded, label: "$c g carbs"),
          ),
      ],
    );
  }
}

// ---- Caloric breakdown (unchanged API). Percentages come from props. ----
class ModernCaloricBreakdown extends StatelessWidget {
  const ModernCaloricBreakdown({
    super.key,
    required this.percentProtein,
    required this.percentFat,
    required this.percentCarbs,
    required this.percentEnergy, // not used, but could be
  });

  final double? percentProtein;
  final double? percentFat;
  final double? percentCarbs;
  final double? percentEnergy; // not used, but could be

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final energyCol  = isDark ? Colors.orange[300]! : Colors.orange[600]!;
    final proteinCol = isDark ? Colors.green[300]! : Colors.green[600]!;
    final fatCol     = isDark ? Colors.red[300]!   : Colors.red[600]!;
    final carbsCol   = isDark ? Colors.blue[300]!  : Colors.blue[600]!;

    return ModernCard(
      radius: 14,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      gradient: LinearGradient(
        colors: isDark
            ? [const Color(0xFF232323), const Color(0xFF1C1C1C)]
            : [const Color(0xFFFFFFFF), const Color(0xFFF8F9FA)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        spacing: 5.w,
        children: [
          _Ring(label: "Energy",  value: (percentEnergy ?? 0).clamp(0, 100),  color: energyCol),
          _Ring(label: "Protein", value: (percentProtein ?? 0).clamp(0, 100), color: proteinCol),
          _Ring(label: "Fat",     value: (percentFat ?? 0).clamp(0, 100),     color: fatCol),
          _Ring(label: "Carbs",   value: (percentCarbs ?? 0).clamp(0, 100),   color: carbsCol),
        ],
      ),
    );
  }
}

// ---- NEW: Convenience wrapper that derives percentages from nutrition map ----
// Note: Daily Values (DV) assumed for reference intake (RI): 
// Energy 2000 kcal, Protein 50 g, Fat 70 g, Carbs 260 g.
// These are generic guideline values; we clamp to [0,100] and show a small note.
class ModernCaloricBreakdownFromNutrition extends StatelessWidget {
  const ModernCaloricBreakdownFromNutrition({
    super.key,
    required this.nutrition,
    this.energyDv = 2000, // kcal
    this.proteinDv = 50,  // g
    this.fatDv = 70,      // g
    this.carbsDv = 260,   // g
    this.showNote = true,
  });

  final Map<String, dynamic> nutrition;
  final double energyDv;
  final double proteinDv;
  final double fatDv;
  final double carbsDv;
  final bool showNote;

  double _pct(num? v, double dv) {
    if (v == null) return 0;
    final val = v.toDouble();
    return (100 * (val / dv)).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final e = nutrition['calories'] as num?;
    final p = nutrition['protein_g'] as num?;
    final f = nutrition['fat_g'] as num?;
    final c = nutrition['carbs_g'] as num?;

    final percentEnergy  = _pct(e, energyDv);
    final percentProtein = _pct(p, proteinDv);
    final percentFat     = _pct(f, fatDv);
    final percentCarbs   = _pct(c, carbsDv);

    final column = Column(
      children: [
        ModernCaloricBreakdown(
          percentProtein: percentProtein,
          percentFat: percentFat,
          percentCarbs: percentCarbs,
          percentEnergy: percentEnergy,
        ),
        if (showNote) ...[
          SizedBox(height: 15.h),
          Text(
            "Based on generic Daily Values: ${energyDv.toStringAsFixed(0)} kcal, "
            "${proteinDv.toStringAsFixed(0)} g protein, ${fatDv.toStringAsFixed(0)} g fat, "
            "${carbsDv.toStringAsFixed(0)} g carbs.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
        ]
      ],
    );

    return column;
  }
}

// ---- Ring with glow + tap-to-play fill animation (same API as before) ----
class _Ring extends StatefulWidget {
  const _Ring({required this.label, required this.value, required this.color});
  final String label;
  final double value; // 0..100
  final Color color;

  @override
  State<_Ring> createState() => _RingState();
}

class _RingState extends State<_Ring> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late double _target; // 0..1
  static const _stroke = 8.0;

  @override
  void initState() {
    super.initState();
    _target = (widget.value.clamp(0, 100)) / 100.0;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0,
      upperBound: 1,
    )..value = _target; // start filled to current value
  }

  @override
  void didUpdateWidget(covariant _Ring oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newTarget = (widget.value.clamp(0, 100)) / 100.0;
    if (newTarget != _target) {
      _target = newTarget;
      _ctrl.animateTo(_target, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _play() {
    // replay fill animation from 0 -> target
    _ctrl
      ..value = 0
      ..animateTo(_target, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        GestureDetector(
          onTap: _play,
          child: SizedBox(
            width: 64.w,
            height: 64.w,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return CustomPaint(
                  painter: _GlowRingPainter(
                    progress: _ctrl.value,          // 0..1
                    color: widget.color,
                    trackColor: isDark ? Colors.white12 : Colors.black12,
                    strokeWidth: _stroke,
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _GlowRingPainter extends CustomPainter {
  _GlowRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress; // 0..1
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2.0;

    // Track
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    // Glow (blurred arc)
    final glow = Paint()
      ..color = color.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final sweepAngle = 2 * math.pi * progress;
    final rectArc = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rectArc, -math.pi / 2, sweepAngle, false, glow);

    // Foreground solid arc
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rectArc, -math.pi / 2, sweepAngle, false, fg);

    // Center text
    final tp = TextPainter(
      text: TextSpan(
        text: "${(progress * 100).round()}%",
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13.sp,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _GlowRingPainter old) =>
      old.progress != progress || old.color != color || old.trackColor != trackColor;
}

// ---- tiny helper: tactile bounce for chips (visual only) ----
class _TapBounce extends StatefulWidget {
  const _TapBounce({required this.child});
  final Widget child;
  @override
  State<_TapBounce> createState() => _TapBounceState();
}

class _TapBounceState extends State<_TapBounce> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _s = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(_) => _c.forward();
  void _up([_]) => _c.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _up,
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, __) => Transform.scale(scale: _s.value, child: widget.child),
      ),
    );
  }
}


/// ------------------------------------------------------------
/// ENHANCED CAUTION BAR - Clean, informative design (ModernCard)
/// ------------------------------------------------------------
class AiCautionBarFancy extends StatefulWidget {
  const AiCautionBarFancy({super.key});

  @override
  State<AiCautionBarFancy> createState() => _AiCautionBarFancyState();
}

class _AiCautionBarFancyState extends State<AiCautionBarFancy>
    with TickerProviderStateMixin {
  late final AnimationController _borderController;
  late final AnimationController _pressController;
  late final Animation<double> _borderAnimation;
  late final Animation<double> _pressAnimation;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();

    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _borderAnimation = Tween<double>(begin: 0, end: 2 * 3.1415926535).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.linear),
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _borderController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = textColor(context);
    final warningColor = isDark ? Colors.amber[300]! : Colors.amber[700]!;
    // ignore: unused_local_variable
    final borderBase = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.08);

    return Column(
      children: [
        // Tap row
        GestureDetector(
          onTapDown: (_) => _pressController.forward(),
          onTapUp: (_) {
            _pressController.reverse();
            _toggle();
          },
          onTapCancel: () => _pressController.reverse(),
          child: AnimatedBuilder(
            animation: _pressAnimation,
            builder: (_, __) {
              return Transform.scale(
                scale: _pressAnimation.value,
                child: ModernCard(
                  radius: 16,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF232323), const Color(0xFF1B1B1B)]
                        : [Colors.white, const Color(0xFFFAFAFA)],
                  ),
                  // subtle static border (serious look)
                  borderWidth: 1.5,
                  child: Row(
                    children: [
                      // Animated ring + icon
                      AnimatedBuilder(
                        animation: _borderAnimation,
                        builder: (context, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.rotate(
                                angle: _borderAnimation.value,
                                child: Container(
                                  width: 30.w,
                                  height: 30.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        warningColor.withOpacity(0.0),
                                        warningColor.withOpacity(0.55),
                                        Colors.orange.withOpacity(0.7),
                                        warningColor.withOpacity(0.55),
                                        warningColor.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 24.w,
                                height: 24.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? const Color(0xFF0E0E0E) : Colors.white,
                                  border: Border.all(
                                    color: warningColor.withOpacity(0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.shield_outlined,
                                  size: 13.sp,
                                  color: warningColor,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(width: 10.w),

                      // Texts
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AI-generated recipe",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                                color: tc,
                                letterSpacing: 0.1,
                              ),
                            ),
                            Text(
                              "Tap for safety guidelines",
                              style: TextStyle(
                                color: tc.withOpacity(0.6),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Chevron
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18.sp,
                          color: tc.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Expanded content
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: _expanded
              ? Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: ModernCard(
                    radius: 14,
                    padding: EdgeInsets.all(12.w),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1F1F1F), const Color(0xFF181818)]
                          : [Colors.white, const Color(0xFFF7F7F7)],
                    ),
                    borderWidth: 1.2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SafetyPoint(text: "Verify ingredient quantities and taste as you go."),
                        _SafetyPoint(text: "Double-check allergens and dietary restrictions."),
                        _SafetyPoint(text: "Validate cooking times/temperatures for doneness."),
                        _SafetyPoint(text: "Follow standard food-safety practices."),
                        _SafetyPoint(text: "Consult a professional for medical/dietary advice."),
                        _SafetyPoint(text: "Watch for raw/undercooked ingredients."),
                        _SafetyPoint(text: "Be cautious with unfamiliar ingredients/techniques."),
                        _SafetyPoint(text: "Adjust for kids, elderly, or immunocompromised."),
                        _SafetyPoint(
                          text:
                              "Do not rely on AI for emergencies or critical health decisions.",
                          isLast: true,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Use this for inspiration — not medical or professional advice.",
                          style: TextStyle(
                            color: tc.withOpacity(0.7),
                            fontSize: 11.sp,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _toggle,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                color: warningColor.withOpacity(0.12),
                                border: Border.all(
                                  color: warningColor.withOpacity(0.35),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded, size: 14.sp, color: warningColor),
                                  SizedBox(width: 4.w),
                                  Text(
                                    "Got it",
                                    style: TextStyle(
                                      color: warningColor,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
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
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SafetyPoint extends StatelessWidget {
  const _SafetyPoint({required this.text, this.isLast = false});
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tc = textColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warningColor = isDark ? Colors.amber[300]! : Colors.amber[700]!;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 7.h),
            width: 5.w,
            height: 5.w,
            decoration: BoxDecoration(
              color: warningColor.withOpacity(0.85),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: tc.withOpacity(0.85),
                fontSize: 12.sp,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// ------------------------------------------------------------
/// CUISINE FLAG EMOJI MAPPER (UNCHANGED, do not edit list)
/// ------------------------------------------------------------
String cuisineFlagEmoji(String name) {
  final key = name.trim().toLowerCase();
  const map = {
    'italian': '🇮🇹',
    'asian': '🌏',
    'caribbean': '🏝️',
    'eastern european': '🇷🇺',
    'european': '🇪🇺',
    'irish': '🇮🇪',
    'latin american': '🌎',
    'chinese': '🇨🇳',
    'mexican': '🇲🇽',
    'indian': '🇮🇳',
    'japanese': '🇯🇵',
    'thai': '🇹🇭',
    'korean': '🇰🇷',
    'vietnamese': '🇻🇳',
    'spanish': '🇪🇸',
    'french': '🇫🇷',
    'middle eastern': '🇱🇧',
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

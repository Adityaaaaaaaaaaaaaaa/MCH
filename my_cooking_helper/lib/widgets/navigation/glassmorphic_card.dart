import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double opacity;
  final double elevation;

  const GlassmorphicCard({
    Key? key,
    required this.child,
    this.borderRadius = 28,
    this.padding,
    this.blur = 18,
    this.opacity = 0.17,
    this.elevation = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final baseColor = isLight
        ? Colors.white.withOpacity(opacity)
        : Colors.grey.shade900.withOpacity(opacity + 0.1);

    return Stack(
      children: [
        // 3D shadow layer
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular((borderRadius + 4).r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isLight ? 0.10 : 0.18),
                  blurRadius: elevation.r,
                  offset: Offset(0, 18.h),
                ),
              ],
            ),
          ),
        ),
        // Glass main content
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur.r, sigmaY: blur.r),
            child: Container(
              padding: padding ?? EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    baseColor,
                    isLight
                        ? Colors.white.withOpacity(opacity - 0.05)
                        : Colors.grey.shade800.withOpacity(opacity),
                  ],
                ),
                borderRadius: BorderRadius.circular(borderRadius.r),
                border: Border.all(
                  color: Colors.white.withOpacity(isLight ? 0.33 : 0.18),
                  width: 1.6.w,
                ),
              ),
              child: child,
            ),
          ),
        ),
        // Inner subtle border for layered look
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular((borderRadius - 3).r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.09),
                  width: 1.2.w,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: IgnorePointer(
            child: Container(
              height: 32.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(borderRadius.r),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(isLight ? 0.18 : 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

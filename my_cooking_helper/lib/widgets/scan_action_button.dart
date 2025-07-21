import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import '/utils/colors.dart';

class ScanActionButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool enabled;

  const ScanActionButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Theme.of(context).primaryColor;
    final activeColor = enabled ? baseColor.withOpacity(0.6) : baseColor.withOpacity(0.15);

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 15.h),
        elevation: 0,
        backgroundColor: activeColor,
        shadowColor: Colors.transparent,
      ),
      onPressed: onPressed,
      icon: icon,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
          color: textColor(context),
        ),
      ),
    ).asGlass(
      blurX: 10,
      blurY: 10,
      tintColor: (color ?? Theme.of(context).primaryColor), 
      clipBorderRadius: BorderRadius.circular(30.r),
      frosted: true,
    );
  }
}

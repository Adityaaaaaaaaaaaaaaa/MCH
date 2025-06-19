import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import '/utils/colors.dart';

class ScanActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const ScanActionButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 15.h),
        elevation: 0,
        backgroundColor: (color ?? Theme.of(context).primaryColor).withOpacity(0.45), // Add tint with opacity
        shadowColor: Colors.transparent,
        /*shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.r),
        ),*/
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 25.sp,
        color: Theme.of(context).primaryColor,
      ),
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
      tintColor: (color ?? Theme.of(context).primaryColor).withOpacity(0.30), // Stronger tint
      clipBorderRadius: BorderRadius.circular(30.r),
      frosted: true,
    );
  }
}

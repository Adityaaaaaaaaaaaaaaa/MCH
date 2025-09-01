// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_cooking_helper/utils/colors.dart';

// ---------- helpers ----------
IconData _categoryIcon(String c) {
  final s = (c).toLowerCase();
  if (s.contains('fruit')) return Icons.apple_rounded;
  if (s.contains('vegetable')) return Icons.eco_rounded;
  if (s.contains('grain')) return Icons.rice_bowl_rounded;
  if (s.contains('dairy')) return Icons.icecream_rounded;
  if (s.contains('protein')) return Icons.set_meal_rounded;
  return Icons.category_rounded;
}

String _prettyQtyUnitFromStrings(String qtyStr, String unitRaw) {
  final unit = (unitRaw).toLowerCase().trim();
  final q = double.tryParse(qtyStr) ?? 0;

  if (unit.isEmpty || unit == 'count') {
    final n = q.isFinite ? q.round() : 1;
    return 'x$n';
  }
  if (unit == 'g' || unit == 'kg') {
    if (unit == 'kg') {
      final s = (q % 1 == 0) ? q.toInt().toString() : q.toStringAsFixed(1);
      return '$s kg';
    }
    if (q >= 1000) {
      final kg = q / 1000.0;
      final kgStr = (kg % 1 == 0) ? kg.toInt().toString() : kg.toStringAsFixed(1);
      return '$kgStr kg';
    }
    final gStr = (q % 1 == 0) ? q.toInt().toString() : q.toStringAsFixed(1);
    return '$gStr g';
  }
  if (unit == 'ml' || unit == 'l') {
    if (unit == 'l') {
      final s = (q % 1 == 0) ? q.toInt().toString() : q.toStringAsFixed(1);
      return '$s L';
    }
    if (q >= 1000) {
      final l = q / 1000.0;
      final lStr = (l % 1 == 0) ? l.toInt().toString() : l.toStringAsFixed(1);
      return '$lStr L';
    }
    final mlStr = (q % 1 == 0) ? q.toInt().toString() : q.toStringAsFixed(1);
    return '$mlStr ml';
  }
  final s = (q % 1 == 0) ? q.toInt().toString() : q.toStringAsFixed(1);
  return '$s ${unitRaw.trim()}';
}

Widget _categoryChip(BuildContext context, String category) {
  final c = textColor(context).withOpacity(.7);
  final border = textColor(context).withOpacity(.18);
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999.r),
      border: Border.all(color: border, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_categoryIcon(category), size: 13.sp, color: c),
        SizedBox(width: 6.w),
        Text(
          category.isEmpty ? 'Uncategorized' : category,
          style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 11.5.sp),
        ),
      ],
    ),
  );
}

// ---------- tile ----------
class InventoryTile extends StatelessWidget {
  final String imageUrl;
  final String itemName;
  final String quantity;
  final String unit;
  final String category;
  final bool isSelected;
  final bool isOnline;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const InventoryTile({
    super.key,
    required this.imageUrl,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.category,
    this.isSelected = false,
    this.isOnline = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final fg = textColor(context);
    final soft = fg.withOpacity(.75);
    final border = fg.withOpacity(.16);
    final accent = const Color(0xFF5AB2FF);

    final amount = _prettyQtyUnitFromStrings(quantity, unit);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: RepaintBoundary(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                color: Colors.black.withOpacity(0.08),
                border: Border.all(
                  color: isSelected ? Colors.redAccent : border,
                  width: 1.4.w,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Make image flexible so text area never overflows
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                      child: Container(
                        width: double.infinity,
                        color: Colors.black.withOpacity(0.10),
                        child: imageUrl.isNotEmpty
                            ? FadeInImage.assetNetwork(
                                placeholder: '', // keep empty = no extra assets
                                image: imageUrl,
                                fit: BoxFit.cover,
                                imageErrorBuilder: (_, __, ___) => Center(
                                  child: Icon(Icons.image_not_supported, color: soft, size: 22.sp),
                                ),
                              )
                            : Center(child: Icon(Icons.image, size: 22.sp, color: soft)),
                      ),
                    ),
                  ),

                  // Compact content block
                  Padding(
                    padding: EdgeInsets.fromLTRB(8.w, 7.h, 8.w, 8.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + amount on one line
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                itemName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.2.sp,
                                  color: fg,
                                  letterSpacing: .1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            // Let amount shrink to fit instead of overflowing
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  amount,
                                  style: TextStyle(
                                    fontSize: 12.3.sp,
                                    color: accent,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),

                        // Category chip – scale down if it’s too wide
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _categoryChip(context, category),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).asGlass(
              tintColor: Colors.transparent,
              blurX: 7,
              blurY: 7,
              frosted: true,
              clipBorderRadius: BorderRadius.circular(18.r),
            ),

            if (!isOnline)
              Positioned(
                top: 6.h,
                right: 8.w,
                child: Tooltip(
                  message: "Not synced",
                  child: Icon(Icons.cloud_off_outlined, color: Colors.redAccent, size: 16.sp),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 8.h,
                left: 8.w,
                child: Icon(Icons.check_circle, color: Colors.redAccent, size: 18.sp),
              ),
          ],
        ),
      ),
    );
  }
}

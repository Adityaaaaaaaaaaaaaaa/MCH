// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import '/utils/colors.dart';
import '/models/item.dart';

String prettyQtyUnit(double? q, String? unitRaw) {
  final unit = (unitRaw ?? '').toLowerCase().trim();
  final qty = (q ?? 0).toDouble();

  if (unit == 'count' || unit.isEmpty) {
    final n = qty.isFinite ? qty.round() : 1;
    return 'x$n';
  }
  if (unit == 'g') {
    if (qty >= 1000) {
      final kg = qty / 1000.0;
      final kgStr = (kg % 1 == 0) ? kg.toInt().toString() : kg.toStringAsFixed(1);
      return '$kgStr kg';
    }
    final gStr = (qty % 1 == 0) ? qty.toInt().toString() : qty.toStringAsFixed(1);
    return '$gStr g';
  }
  if (unit == 'ml') {
    if (qty >= 1000) {
      final l = qty / 1000.0;
      final lStr = (l % 1 == 0) ? l.toInt().toString() : l.toStringAsFixed(1);
      return '$lStr L';
    }
    final mlStr = (qty % 1 == 0) ? qty.toInt().toString() : qty.toStringAsFixed(1);
    return '$mlStr ml';
  }
  final s = (qty % 1 == 0) ? qty.toInt().toString() : qty.toStringAsFixed(1);
  return '$s ${unitRaw ?? ''}'.trim();
}

IconData _categoryIcon(String c) {
  final s = c.toLowerCase();
  if (s.contains('fruit')) return Icons.apple_rounded;
  if (s.contains('vegetable')) return Icons.eco_rounded;
  if (s.contains('grain')) return Icons.rice_bowl_rounded;
  if (s.contains('dairy')) return Icons.icecream_rounded;
  if (s.contains('protein')) return Icons.set_meal_rounded;
  return Icons.category_rounded;
}

Widget categoryChip(BuildContext context, String category) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final border = isDark ? Colors.white.withOpacity(0.14) : Colors.black.withOpacity(0.12);
  final text = isDark ? const Color(0xFFEAEFF6) : const Color(0xFF2A2F36);

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999.r),
      border: Border.all(color: border, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_categoryIcon(category), size: 14.sp, color: text.withOpacity(.75)),
        SizedBox(width: 6.w),
        Text(
          category,
          style: TextStyle(color: text.withOpacity(.85), fontWeight: FontWeight.w700, fontSize: 11.5.sp),
        ),
      ],
    ),
  );
}

class ReviewHeaderCard extends StatelessWidget {
  const ReviewHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.10);
    final fill = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: fill,
        border: Border.all(color: border, width: 1.2.w),
      ),
      child: Text(
        "Review and verify your detected items below before confirming.",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor(context),
          fontWeight: FontWeight.w900,
          fontSize: 17.sp,
        ),
      ),
    ).asGlass(
      blurX: 10, 
      blurY: 10, 
      frosted: true,
      tintColor: Colors.indigo,
      clipBorderRadius: BorderRadius.circular(20.r),
    );
  }
}

class SwipeHintChip extends StatelessWidget {
  const SwipeHintChip({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.10);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swipe_left_rounded, 
            color: textColor(context), 
            size: 20.sp
          ),
          SizedBox(width: 7.w),
          Text(
            "Swipe left to delete an item",
            style: TextStyle(
              color: textColor(context), 
              fontWeight: FontWeight.w800, 
              fontSize: 12.sp
            )
          ),
        ],
      ),
    ).asGlass(
      blurX: 10, 
      blurY: 10, 
      frosted: true,
      tintColor: Colors.blueAccent,
      clipBorderRadius: BorderRadius.circular(12.r),
    );
  }
}

// Item tile 
class ReviewItemTile extends StatelessWidget {
  final ScannedItem item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ReviewItemTile({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = isDark ? const Color(0xFF5AB2FF) : const Color(0xFF0E7AE6);
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08);
    final fill = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.035);

    final amount = prettyQtyUnit(item.quantity, item.unit);

    final tile = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: fill,
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${item.itemName} -',
                          style: TextStyle(
                            color: textColor(context),
                            fontWeight: FontWeight.w900,
                            fontSize: 20.sp,
                            letterSpacing: .1,
                          ),
                        ),
                        TextSpan(text: '    '),
                        TextSpan(
                          text: amount, // x3 / 300 ml / 3.5 L / 400 g / 4.5 kg
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 20.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 120.w),
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: Colors.blue, size: 18.sp),
                  tooltip: "Edit",
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // Category chip 
            categoryChip(context, item.category ?? 'Uncategorized'),
          ],
        ),
      ),
    ).asGlass(
      blurX: 10, 
      blurY: 10, 
      frosted: true,
      tintColor: Colors.blueGrey,
      clipBorderRadius: BorderRadius.circular(16.r),
    );

    return RepaintBoundary(child: tile);
  }
}

//  Buttons                                                                                                                                                                                                                                                                        
class ConfirmAllButton extends StatelessWidget {
  final VoidCallback onPressed;
  const ConfirmAllButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2EAD76) : const Color(0xFF2DB36B);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(
          Icons.done_rounded, 
          size: 22.sp, 
          color: textColor(context)
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
          elevation: 6,
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        label: Text(
          'Confirm All', 
          style: TextStyle(
            color: textColor(context)
          )
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class AddItemFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const AddItemFAB({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF5AB2FF) : const Color(0xFF0E7AE6);

    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: accent,
      elevation: 10,
      icon: const Icon(
        Icons.add_circle_rounded, 
        color: Colors.white
      ),
      label: Text(
        'Add Item',
        style: TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.bold, 
          fontSize: 15.sp
        ),
      ),
    );
  }
}

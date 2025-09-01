// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_cooking_helper/utils/colors.dart';

class InventorySortBar extends StatelessWidget {
  final String sortBy;
  final ValueChanged<String> onSort;
  const InventorySortBar({super.key, required this.sortBy, required this.onSort});

  @override
  Widget build(BuildContext context) {
    final fg = textColor(context);
    final soft = fg.withOpacity(.75);
    final border = fg.withOpacity(.16);

    final Map<String, IconData> _icons = {
      "default": Icons.auto_awesome_rounded,
      "name": Icons.sort_by_alpha_rounded,
      "quantity": Icons.format_list_numbered_rounded,
      "category": Icons.category_rounded,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          //Icon(_icons[sortBy] ?? Icons.auto_awesome_rounded, color: soft, size: 16.sp),
          SizedBox(width: 8.w),
          Text("Sort", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.sp, color: fg)),
          SizedBox(width: 6.w),
          // Hide underline; keep Dropdown logic identical
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: sortBy,
              onChanged: (value) {
                if (value != null) onSort(value);
              },
              dropdownColor: Colors.black.withOpacity(.90),
              icon: Icon(Icons.arrow_drop_down_rounded, color: soft, size: 22.sp),
              borderRadius: BorderRadius.circular(12.r),
              items: const [
                {"value": "default", "text": "Default"},
                {"value": "name", "text": "Name"},
                {"value": "quantity", "text": "Quantity"},
                {"value": "category", "text": "Category"},
              ].map((item) {
                final v = item["value"]!;
                final t = item["text"]!;
                return DropdownMenuItem<String>(
                  value: v,
                  child: Row(
                    children: [
                      Icon(_icons[v]!, size: 16.sp, color: soft),
                      SizedBox(width: 8.w),
                      Text(
                        t,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                          color: textColor(context),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

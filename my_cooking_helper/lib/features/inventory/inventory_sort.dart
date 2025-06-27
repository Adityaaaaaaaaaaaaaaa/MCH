import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_cooking_helper/utils/colors.dart';

class InventorySortBar extends StatelessWidget {
  final String sortBy;
  final ValueChanged<String> onSort;
  const InventorySortBar({super.key, required this.sortBy, required this.onSort});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h)),
        Text(
          "Sort by:", 
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11.sp,
          )
        ),
        SizedBox(width: 10.w),
        DropdownButton<String>(
          value: sortBy,
          onChanged: (value) {
            if (value != null) {
              onSort(value);
            }
          },
          dropdownColor: Colors.blueGrey,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey,),
          iconSize: 25.0.sp,
          menuWidth: 100.w,
          borderRadius: BorderRadius.circular(15.r),
          items: [
            {"value": "default", "text": "Default"},
            {"value": "name", "text": "Name"},
            {"value": "quantity", "text": "Quantity"},
            {"value": "category", "text": "Category"},
          ].map((item) => DropdownMenuItem(
            value: item["value"]!,
            child: Text(
              item["text"]!,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11.sp,
                color: textColor(context),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

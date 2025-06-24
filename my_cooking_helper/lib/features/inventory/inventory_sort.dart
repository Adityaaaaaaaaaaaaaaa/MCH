import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
          dropdownColor: Colors.black.withOpacity(0.60),
          icon: Icon(Icons.arrow_drop_down, color: Colors.white70,),
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          iconSize: 25.0.sp,
          menuWidth: 100.w,
          borderRadius: BorderRadius.circular(15.r),
          items: [
            DropdownMenuItem(value: "default", child: Text("Default", style: TextStyle(fontWeight: FontWeight.w600,fontSize: 11.sp,))),
            DropdownMenuItem(value: "name", child: Text("Name", style: TextStyle(fontWeight: FontWeight.w600,fontSize: 11.sp,))),
            DropdownMenuItem(value: "quantity", child: Text("Quantity", style: TextStyle(fontWeight: FontWeight.w600,fontSize: 11.sp,))),
            DropdownMenuItem(value: "category", child: Text("Category", style: TextStyle(fontWeight: FontWeight.w600,fontSize: 11.sp,))),
          ],
        ),
      ],
    );
  }
}

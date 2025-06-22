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
          items: [
            DropdownMenuItem(value: "default", child: Text("Default",style: TextStyle(fontWeight: FontWeight.w600,fontSize: 11.sp,))),
            DropdownMenuItem(value: "name", child: Text("Name", style: TextStyle(fontWeight: FontWeight.w600,fontSize: 11.sp,))),
            DropdownMenuItem(value: "quantity", child: Text("Quantity", style: TextStyle(fontWeight: FontWeight.w600,fontSize: 11.sp,))),
            DropdownMenuItem(value: "category", child: Text("Category", style: TextStyle(fontWeight: FontWeight.w600,fontSize: 11.sp,))),
          ],
        ),
      ],
    );
  }
}

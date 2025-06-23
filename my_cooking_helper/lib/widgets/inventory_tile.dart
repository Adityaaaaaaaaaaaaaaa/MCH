import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_cooking_helper/utils/colors.dart';

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
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: isSelected ? Colors.redAccent : Colors.grey,
                width: 2.w,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // IMAGE CONTAINER
                Container(
                  height: 70.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                  ),
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported),
                          ),
                        )
                      : Icon(Icons.image, size: 35.sp, color: Colors.grey[500]),
                ),
                // TEXT CONTAINER
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        itemName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17.sp,
                          color: textColor(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '$quantity $unit',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: textColor(context),
                        ),
                      ),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: textColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).asGlass(
            tintColor: Colors.blueGrey,
            blurX: 7,
            blurY: 7,
            frosted: true,
            clipBorderRadius: BorderRadius.circular(18.r),
          ),
          if (!isOnline)
            Positioned(
              top: 5.h,
              right: 10.w,
              child: Tooltip(
                message: "Not synced",
                child: Icon(Icons.cloud_off_outlined, color: Colors.redAccent, size: 15.sp),
              ),
            ),
          if (isSelected)
            Positioned(
              top: 7.h,
              left: 10.w,
              child: Icon(Icons.check_circle, color: Colors.redAccent, size: 20.sp),
            ),
        ],
      ),
    );
  }
}

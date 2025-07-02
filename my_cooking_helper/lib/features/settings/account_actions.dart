import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animated_emoji/animated_emoji.dart';

class AccountActionsSection extends StatelessWidget {
  final VoidCallback onSignOut;
  final Function(BuildContext) onDelete;

  const AccountActionsSection({
    super.key,
    required this.onSignOut,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        //SIGN OUT
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Sign Out", 
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17.sp
                  )),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: Text(
                    "Sign Out", 
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16.sp,
                    )),
                  onPressed: onSignOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.93),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 1,
                  ),
                ),
                // ffffffffffffffffff

              ],
            ),
          )
          .asGlass(
            blurX: 15,
            blurY: 15,
            tintColor: Colors.black,
            frosted: true,
            clipBorderRadius: BorderRadius.circular(20.r),
          ),
        ),
        SizedBox(height: 12.h),
        // DELETE CARD 
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Delete your Account",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w900,
                          fontSize: 17.sp,
                        ),
                      ),
                      Text(
                        "Irreversible action!",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.sp,
                        )),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: AnimatedEmoji(
                  AnimatedEmojis.policeCarLight, 
                  size: 24,
                  repeat: true,
                  ),
                  label: Text(
                    "Delete",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15.sp,
                    ),
                  ),
                  onPressed: () => onDelete(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ],
            ),
          )
          .asGlass(
            blurX: 15,
            blurY: 15,
            tintColor: Colors.red,
            frosted: true,
            clipBorderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ],
    );
  }
}

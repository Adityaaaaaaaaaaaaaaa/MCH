import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileAccountSection extends StatelessWidget {
  final dynamic user;
  final dynamic avatar;
  final VoidCallback onSwitchAccount;

  const ProfileAccountSection({
    super.key,
    required this.user,
    required this.avatar,
    required this.onSwitchAccount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 0),
      child: Hero(
        tag: "profile-icon",
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Row with avatar and button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircleAvatar(
                    radius: 35.r,
                    backgroundImage: avatar as ImageProvider,
                    backgroundColor: Colors.transparent,
                  ),
                  SizedBox(width: 20.w),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.switch_account),
                    label: const Text("Switch"),
                    onPressed: onSwitchAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Text(
                user?.displayName ?? "User",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 16.sp,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 5.h),
              Text(
                user?.email ?? "",
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ).asGlass(
          blurX: 25,
          blurY: 25,
          tintColor: Colors.black,
          frosted: true,
          clipBorderRadius: BorderRadius.circular(30.r),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_cooking_helper/utils/colors.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0),
      child: Hero(
        tag: "profile-icon",
        child: Container(
          padding: EdgeInsets.all(24.w),
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.08),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with subtle border
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [
                          const Color(0xFF6366F1),
                          const Color(0xFF8B5CF6),
                          const Color(0xFFEC4899),
                        ]
                      : [
                          const Color(0xFF3B82F6),
                          const Color(0xFF6366F1),
                          const Color(0xFF8B5CF6),
                        ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  ),
                  child: CircleAvatar(
                    radius: 40.r,
                    backgroundImage: avatar as ImageProvider,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              
              SizedBox(height: 20.h),
              
              // User name with gradient text effect
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isDark 
                    ? [
                        const Color(0xFF60A5FA),
                        const Color(0xFF8B5CF6),
                      ]
                    : [
                        const Color(0xFF1E40AF),
                        const Color(0xFF7C3AED),
                      ],
                ).createShader(bounds),
                child: Text(
                  user?.displayName ?? "User",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20.sp,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(height: 8.h),
              
              // Email with subtle styling
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isDark 
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark 
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: Text(
                  user?.email ?? "",
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13.sp,
                    color: textColor(context).withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Enhanced switch account button
              Container(
                width: double.infinity,
                height: 48.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [
                          const Color(0xFF374151),
                          const Color(0xFF1F2937),
                        ]
                      : [
                          const Color(0xFFF8FAFC),
                          const Color(0xFFE2E8F0),
                        ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark 
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSwitchAccount,
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            color: isDark 
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "Switch Account",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15.sp,
                              color: isDark 
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).asGlass(
          blurX: 25,
          blurY: 25,
          tintColor: isDark 
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.3),
          frosted: true,
          clipBorderRadius: BorderRadius.circular(24.r),
        ),
      ),
    );
  }
}
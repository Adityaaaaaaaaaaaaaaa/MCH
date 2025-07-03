import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'glassmorphic_card.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? themeToggleWidget;
  final Widget? trailingWidget;
  final VoidCallback? onTrailingIconTap;
  final bool showMenu;
  final VoidCallback? onMenuTap;
  final double height;
  final double borderRadius;
  final double topPadding;
  final double fontSize;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.themeToggleWidget,
    this.trailingWidget,
    this.onTrailingIconTap,
    this.showMenu = true,
    this.onMenuTap,
    this.height = 85,
    this.borderRadius = 26,
    this.topPadding = 35,
    this.fontSize = 16,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(height.h);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PreferredSize(
      preferredSize: Size.fromHeight(height.h),
      child: Padding(
        padding: EdgeInsets.only(top: topPadding.h, left: 10.w, right: 10.w),
        child: GlassmorphicCard(
          borderRadius: borderRadius,
          blur: 22,
          opacity: 0.14,
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) => showMenu
                  ? IconButton(
                      icon: Icon(Icons.menu_rounded, size: 25.sp),
                      color: theme.colorScheme.primary,
                      tooltip: "Open menu",
                      onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: theme.colorScheme.primary,
                      tooltip: "Back",
                      onPressed: onMenuTap ?? () {
                        // Fallback: Try pop, then maybePop, then go home
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
                    ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2, 
                      fontSize: fontSize.sp, 
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  if (themeToggleWidget != null) themeToggleWidget!,
                  if (trailingWidget != null)
                    IconButton(
                      icon: trailingWidget!,
                      tooltip: "Action",
                      color: theme.colorScheme.primary,
                      onPressed: onTrailingIconTap ?? () {},
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

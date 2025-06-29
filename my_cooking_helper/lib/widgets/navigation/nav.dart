import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_cooking_helper/utils/colors.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'glassmorphic_card.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  const CustomNavBar({super.key, required this.currentIndex});

  static final _navItems = [
    _NavItem(Icons.kitchen_rounded, "Inventory", "/inventory"),
    _NavItem(Icons.camera_alt_rounded, "Cook", "/scan"),
    _NavItem(Icons.home_rounded, "Home", "/home"),
    _NavItem(Icons.fastfood_rounded, "Cravings", "/cravings"),
    _NavItem(Icons.calendar_month_rounded, "Planner", "/planner"),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 25.h),
      child: GlassmorphicCard(
        borderRadius: 22.r,
        blur: 16,
        opacity: 0.12,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
        child: SalomonBottomBar(
          currentIndex: currentIndex,
          onTap: (index) {
            final targetPath = _navItems[index].route;
            if (GoRouterState.of(context).uri.toString() != targetPath) {
              context.push(targetPath);
            }
          },
          items: _navItems
              .map(
                (item) => SalomonBottomBarItem(
                  icon: Icon(item.icon, size: 20.sp),
                  title: Text(
                    item.title,
                    style: TextStyle(color: textColor(context))
                  ),
                  selectedColor: textColor(context), 
                  unselectedColor: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              )
              .toList(),
          backgroundColor: Colors.transparent,
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          duration: const Duration(milliseconds: 400),
          itemShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String title;
  final String route;
  const _NavItem(this.icon, this.title, this.route);
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import '../../theme/glassmorphic_card.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  const CustomNavBar({Key? key, required this.currentIndex}) : super(key: key);

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
      padding: const EdgeInsets.only(left: 18, right: 18, bottom: 14),
      child: GlassmorphicCard(
        borderRadius: 22,
        blur: 16,
        opacity: 0.12,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: SalomonBottomBar(
          currentIndex: currentIndex,
          onTap: (index) {
            final targetPath = _navItems[index].route;
            if (GoRouterState.of(context).uri.toString() != targetPath) {
              context.go(targetPath);
            }
          },
          items: _navItems
              .map(
                (item) => SalomonBottomBarItem(
                  icon: Icon(item.icon, size: 26),
                  title: Text(item.title),
                  selectedColor: theme.colorScheme.primary,
                  unselectedColor: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              )
              .toList(),
          backgroundColor: Colors.transparent,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          duration: const Duration(milliseconds: 400),
          itemShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

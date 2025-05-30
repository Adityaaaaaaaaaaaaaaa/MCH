import 'package:flutter/material.dart';
import '/theme/glassmorphic_card.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? themeToggleWidget;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingIconTap;
  final bool showMenu;
  final VoidCallback? onMenuTap;
  final double height;
  final double borderRadius;
  final double topPadding;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.themeToggleWidget,
    this.trailingIcon,
    this.onTrailingIconTap,
    this.showMenu = true,
    this.onMenuTap,
    this.height = 85,
    this.borderRadius = 26,
    this.topPadding = 35,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: Padding(
        padding: EdgeInsets.only(top: topPadding, left: 10, right: 10),
        child: GlassmorphicCard(
          borderRadius: borderRadius,
          blur: 22,
          opacity: 0.14,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) => showMenu
                  ? IconButton(
                      icon: const Icon(Icons.menu_rounded, size: 30),
                      color: theme.colorScheme.primary,
                      tooltip: "Open menu",
                      onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: theme.colorScheme.primary,
                      tooltip: "Back",
                      onPressed: () => Navigator.of(context).canPop() ? Navigator.of(context).pop() : Navigator.of(context).maybePop(),
                    ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  if (themeToggleWidget != null) themeToggleWidget!,
                  if (trailingIcon != null)
                    IconButton(
                      icon: Icon(trailingIcon, size: 28),
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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final List<String> headerImages = [
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=facearea&w=400&q=80',
    // Add more image URLs or asset paths
    'assets/app_icon.png', // Local asset as fallback
  ];

  late String selectedImage;

  @override
  void initState() {
    super.initState();
    _pickRandomImage();
  }

  void _pickRandomImage() {
    setState(() {
      selectedImage = headerImages[Random().nextInt(headerImages.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final GoRouter router = GoRouter.of(context);

    // List of routes for navigation (modular, could come from a config)
    final List<_DrawerRoute> routes = [
      _DrawerRoute(
          icon: Icons.camera_alt,
          label: 'Scan and Cook',
          path: '/scan'
      ),
      _DrawerRoute(
          icon: Icons.calendar_month,
          label: 'Meal Planner',
          path: '/planner'
      ),
      _DrawerRoute(
          icon: Icons.kitchen,
          label: 'My Inventory',
          path: '/inventory'
      ),
      _DrawerRoute(
          icon: Icons.fastfood,
          label: 'My Cravings',
          path: '/cravings'
      ),
      _DrawerRoute(
          icon: Icons.history,
          label: 'Past Meals',
          path: '/history'
      ),
      _DrawerRoute(
          icon: Icons.shopping_cart,
          label: 'My Shopping List',
          path: '/shopping'
      ),
    ];

    return Drawer(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickRandomImage,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundImage: selectedImage.startsWith('http')
                      ? NetworkImage(selectedImage)
                      : AssetImage(selectedImage) as ImageProvider,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
          ...routes.map((route) => _DrawerItem(
                icon: route.icon,
                label: route.label,
                routePath: route.path,
                isSelected: GoRouterState.of(context).uri.toString() == route.path,
                onTap: () {
                  // Only navigate if not already there
                  if (GoRouterState.of(context).uri.toString() != route.path) {
                    context.pop(); // Close drawer first
                    context.go(route.path);
                  } else {
                    context.pop(); // Just close drawer
                  }
                },
              )),
          const Spacer(),
          const Divider(),
          _DrawerItem(
            icon: Icons.settings,
            label: 'Settings and Preferences',
            routePath: '/settings',
            isSelected: GoRouterState.of(context).uri.toString() == '/settings',
            onTap: () {
              if (GoRouterState.of(context).uri.toString() != '/settings') {
                context.pop();
                context.go('/settings');
              } else {
                context.pop();
              }
            },
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _DrawerRoute {
  final IconData icon;
  final String label;
  final String path;
  const _DrawerRoute({
    required this.icon,
    required this.label,
    required this.path,
  });
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String routePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.routePath,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : null),
      title: Text(
        label,
        style: isSelected
            ? TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              )
            : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.2) : null,
      onTap: onTap,
    );
  }
}

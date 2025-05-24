import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/glassmorphic_card.dart';
import '../../core/theme_toggle_button.dart';
import 'drawer.dart';
import 'nav.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<_FeatureCardData> features = [
    _FeatureCardData(
        'Scan and Cook',
        Icons.camera_alt_rounded,
        Colors.deepOrange,
        '/scan'
    ),
    _FeatureCardData(
        'Meal Planner',
        Icons.calendar_month_rounded,
        Colors.indigo,
        '/planner'
    ),
    _FeatureCardData(
        'My Inventory',
        Icons.kitchen_rounded,
        Colors.teal,
        '/inventory'
    ),
    _FeatureCardData(
        'My Cravings',
        Icons.fastfood_rounded,
        Colors.amber,
        '/cravings'
    ),
    _FeatureCardData(
        'Past Meals',
        Icons.history_rounded,
        Colors.purple,
        '/history'
    ),
    _FeatureCardData(
        'My Shopping List',
        Icons.shopping_cart_rounded,
        Colors.cyan,
        '/shopping'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 950),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openSettings(BuildContext context) {
    context.go('/settings');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: CustomDrawer(),
      bottomNavigationBar: CustomNavBar(currentIndex: 2),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Padding(
          padding: const EdgeInsets.only(top: 60, left: 10, right: 10),
          child: GlassmorphicCard(
            borderRadius: 26,
            blur: 22,
            opacity: 0.14,
            padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "My Cooking Helper",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                Row(
                  children: [
                    // Animated theme toggle button (from your implementation)
                    const ThemeToggleButton(),
                    const SizedBox(width: 10),
                    // Profile icon button
                    GestureDetector(
                      onTap: () => _openSettings(context),
                      child: Hero(
                        tag: "profile-icon",
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: AssetImage("assets/images/chef_avatar.png"),
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(top: 25, left: 12, right: 12),
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 18, mainAxisSpacing: 18,
            ),
            itemBuilder: (context, index) {
              final feature = features[index];
              return ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Interval(index * 0.09, 1, curve: Curves.elasticOut),
                ),
                child: InkWell(
                  onTap: () => context.go(feature.route),
                  borderRadius: BorderRadius.circular(30),
                  child: GlassmorphicCard(
                    borderRadius: 30,
                    blur: 14,
                    opacity: 0.14,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutBack,
                          decoration: BoxDecoration(
                            color: feature.color.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(feature.icon, size: 38, color: feature.color),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          feature.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      // You can plug in your improved nav bar here
      // bottomNavigationBar: CustomNavBar(currentIndex: 2),
    );
  }
}

class _FeatureCardData {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  const _FeatureCardData(this.title, this.icon, this.color, this.route);
}

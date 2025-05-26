import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/glassmorphic_card.dart';
import '../../theme/app_theme.dart';
import '../../theme/loader.dart';
import 'drawer.dart';
import 'nav.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<_FeatureCardData> features = [
    _FeatureCardData('Scan and Cook', Icons.camera_alt_rounded, Colors.deepOrange, '/scan'),
    _FeatureCardData('Meal Planner', Icons.calendar_month_rounded, Colors.indigo, '/planner'),
    _FeatureCardData('My Inventory', Icons.kitchen_rounded, Colors.teal, '/inventory'),
    _FeatureCardData('My Cravings', Icons.fastfood_rounded, Colors.amber, '/cravings'),
    _FeatureCardData('Past Meals', Icons.history_rounded, Colors.purple, '/history'),
    _FeatureCardData('My Shopping List', Icons.shopping_cart_rounded, Colors.cyan, '/shopping'),
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

  /*void _openSettings(BuildContext context) {
    context.go('/settings');
  }*/

  void _openSettings(BuildContext context) async {
    // Show your custom loader modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: loader(
          Colors.deepOrangeAccent, // color
          70,                // size
          5,                 // lineWidth
          8,                 // itemCount
          500               // duration (ms)
        ),
      ),
    );

    // Wait for 1.2 seconds for the loader animation
    await Future.delayed(const Duration(milliseconds: 700));

    // Dismiss the loader
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    // Now navigate to settings
    if (context.mounted) context.go('/settings');
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // CARD SIZE CONTROL: Adjust these values for width/height of all feature cards!
    const double cardWidth = 170;  // Change this for card width
    const double cardHeight = 155; // Change this for card height

    return Scaffold(
      backgroundColor: isLight
          ? const Color(0xfff8fafc)
          : const Color(0xff232526),
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
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded, size: 30),
                    color: theme.colorScheme.primary,
                    tooltip: "Open menu",
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "My Cooking Helper",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const ThemeToggleButton(),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _openSettings(context),
                      child: Hero(
                        tag: "profile-icon",
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: AssetImage("assets/app_icon.png"),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
                ? [
                    const Color(0xfff8fafc),
                    const Color(0xffa1c4fd).withOpacity(0.11),
                  ]
                : [
                    const Color(0xff232526),
                    const Color(0xff393e46).withOpacity(0.13),
                  ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            // Center the grid
            child: SizedBox(
              // This width ensures the grid stays centered, even on big screens
              width: (cardWidth + 24) * 2,
              // 2 columns: card + spacing
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 150, bottom: 10),
                itemCount: features.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,         // Always 2 per row
                  mainAxisSpacing: 26,       // Vertical spacing
                  crossAxisSpacing: 24,      // Horizontal spacing
                  childAspectRatio: cardWidth / cardHeight, // Controls exact shape!
                ),
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _controller,
                      curve: Interval(index * 0.09, 1, curve: Curves.elasticOut),
                    ),
                    child: Center(
                      child: FeatureCard(
                        icon: feature.icon,
                        title: feature.title,
                        color: feature.color,
                        width: cardWidth,
                        height: cardHeight,
                        onTap: () => context.go(feature.route),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final double width;  // << adjustable width
  final double height; // << adjustable height
  final VoidCallback onTap;
  const FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.color,
    required this.width,
    required this.height,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Material(
      color: isLight ? Colors.white : Colors.grey[900],
      elevation: 8,
      borderRadius: BorderRadius.circular(25),
      shadowColor: color.withOpacity(0.5), //glow edge
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        splashColor: color.withOpacity(0.18),
        onTap: onTap,
        child: SizedBox(
          width: width,         // << controls card width
          height: height,       // << controls card height
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(15), // Icon padding inside circle
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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

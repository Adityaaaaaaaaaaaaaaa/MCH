import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import '/utils/colors.dart';
import '/utils/appbar.dart';
import '/theme/app_theme.dart';
import '/utils/loader.dart';
import '/utils/drawer.dart';
import '/utils/nav.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openSettings(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: loader(
          Colors.deepOrangeAccent,
          70,
          5,
          8,
          500,
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 700));
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (context.mounted) context.go('/settings');
  }

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);
    //final isLight = theme.brightness == Brightness.light;

    //width/height of all feature cards!
    const double cardWidth = 160;  //  width
    const double cardHeight = 135; //  height

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: true,
      extendBody: true,
      drawer: CustomDrawer(),
      bottomNavigationBar: CustomNavBar(currentIndex: 2),
      appBar: CustomAppBar(
        title: "My Cooking Helper",
        themeToggleWidget: const ThemeToggleButton(),
        trailingIcon: Icons.settings_rounded,
        onTrailingIconTap: () => _openSettings(context),
        height: 100,
        borderRadius: 26,
        topPadding: 60,
      ),
      body: Stack(
        children: [
          // -------- BACKGROUND IMAGES --------
          Positioned(
            top: 40,
            left: 90,
            child: Transform.rotate(
              angle: -0.6, //radians
              child: Image.asset(
                'assets/images/home/salad.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 250,
            left: 40,
            child: Transform.rotate(
              angle: 0.9, 
              child: Image.asset(
                'assets/images/home/curry.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: 55,
            child: Transform.rotate(
              angle: 0.1, 
              child: Image.asset(
                'assets/images/home/burger.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 15,
            child: Transform.rotate(
              angle: -0.4, 
              child: Image.asset(
                'assets/images/home/tenders.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // -------- FEATURE CARDS IN GLASS EFFECT --------
          Center(
            child: SizedBox(
              width: (cardWidth + 24) * 2,
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 150, bottom: 10),
                itemCount: features.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 26,
                  crossAxisSpacing: 24,
                  childAspectRatio: cardWidth / cardHeight,
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
                        onTap: () => context.push(feature.route),
                      ).asGlass(
                        blurX: 5,
                        blurY: 5,
                        //tintColor: const Color.fromARGB(255, 255, 255, 255),
                        clipBorderRadius: BorderRadius.circular(25),
                        frosted: true, 
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------ Feature Card ------
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
    //final isLight = theme.brightness == Brightness.light;
    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(25),
      shadowColor: color.withOpacity(0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        splashColor: color.withOpacity(0.18),
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(15),
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

// Helper class for feature card metadata
class _FeatureCardData {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  const _FeatureCardData(this.title, this.icon, this.color, this.route);
}

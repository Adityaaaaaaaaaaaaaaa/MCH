// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/emoji_animation.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/theme/app_theme.dart';
import '/utils/loader.dart';
import '/widgets/navigation/drawer.dart';
import '/widgets/navigation/nav.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<_FeatureCardData> features = [
    _FeatureCardData('Smart Scan', Icons.camera_alt_rounded, Colors.red, '/scan'),
    _FeatureCardData('Meal Planner', Icons.calendar_month_rounded, Colors.indigo, '/planner'),
    _FeatureCardData('My Inventory', Icons.kitchen_rounded, Colors.teal, '/inventory'),
    _FeatureCardData('AI Recipe Generator', Icons.auto_awesome, Colors.purple, '/cravings'),
    _FeatureCardData('Cook Something', Icons.history_rounded, Colors.brown, '/cook'),
    _FeatureCardData('My Shopping List', Icons.shopping_cart_outlined, Colors.blueGrey, '/shopping'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: loader(
          isDark ? Colors.deepOrangeAccent : Colors.orange,
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

    //width/height of all feature cards!
    double cardWidth = 150.w;
    double cardHeight = 140.h;

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: true,
      extendBody: true,
      drawer: CustomDrawer(),
      bottomNavigationBar: CustomNavBar(currentIndex: 2),
      appBar: CustomAppBar(
        title: "Cookgenix",
        themeToggleWidget: ThemeToggleButton(),
        trailingWidget: EmojiAnimation(name: 'gear'),
        onTrailingIconTap: () => _openSettings(context),
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 20.0.h),
            child: Center(
              child: SizedBox(
                width: (cardWidth + 24) * 2,
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(top: 110.h, bottom: 10.h),
                  itemCount: features.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 25.h,
                    crossAxisSpacing: 50.w,
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
                          blurX: 15,
                          blurY: 15,
                          tintColor: Colors.black,
                          clipBorderRadius: BorderRadius.circular(20.r),
                          frosted: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------ Feature Card ------
class FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final double width;
  final double height;
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
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  // ignore: unused_field
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _hoverController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _hoverController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (0.04 * _hoverController.value),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.r),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(25.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24.r),
                  splashColor: widget.color.withOpacity(0.14),
                  highlightColor: widget.color.withOpacity(0.1),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6), 
                              width: 1
                            ),
                            gradient: LinearGradient(
                              colors: [
                                widget.color.withOpacity(0.8),
                                Colors.white.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withOpacity(0.9),
                                blurRadius: 7,
                                offset: Offset(1, 4),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(13.w),
                          child: Icon(widget.icon, size: 30.sp, color: Colors.white),
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.10,
                            fontSize: 14.sp,
                            color: textColor(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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

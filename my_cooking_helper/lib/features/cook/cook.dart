import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
// ignore: unused_import
import '/widgets/navigation/nav.dart';

class CookScreen extends ConsumerWidget {
  const CookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<_CookFeatureCardData> features = [
      _CookFeatureCardData(
        'Past Cooked Meals',
        Icons.history_rounded,
        Colors.teal,
        '/history',
      ),
      _CookFeatureCardData(
        'Cook Something New',
        Icons.restaurant_menu_rounded,
        Colors.deepOrangeAccent,
        '/cook-now',
      ),
      _CookFeatureCardData(
        'My Favourite Recipes',
        Icons.favorite_rounded,
        Colors.pink,
        '/favourites',
      ),
    ];

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: true,
      extendBody: true,
      drawer: CustomDrawer(),
      //bottomNavigationBar: CustomNavBar(currentIndex: 4),
      appBar: CustomAppBar(
        title: "Cook",
        showMenu: false,
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
      ),
      body: Stack(
        children: [
          // --- BACKGROUND IMAGES (for aesthetics) ---
          Positioned(
            top: 35,
            right: 80,
            child: Transform.rotate(
              angle: -0.5,
              child: Image.asset(
                'assets/images/home/salad.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 170,
            left: 30,
            child: Transform.rotate(
              angle: 0.7,
              child: Image.asset(
                'assets/images/home/curry.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 24.0.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 110.h),
                Text(
                  'Welcome to Cooking!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor(context),
                      ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Choose what you want to do:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor(context).withOpacity(0.7),
                      ),
                ),
                SizedBox(height: 40.h),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: features.length,
                    padding: EdgeInsets.only(bottom: 20.h),
                    itemBuilder: (context, index) {
                      final feature = features[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 20.h),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          curve: Curves.easeOutBack,
                          child: CookFeatureCard(
                            icon: feature.icon,
                            title: feature.title,
                            color: feature.color,
                            onTap: () => context.push(feature.route),
                            index: index,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CookFeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final int index;

  const CookFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    required this.index,
  });

  @override
  State<CookFeatureCard> createState() => _CookFeatureCardState();
}

class _CookFeatureCardState extends State<CookFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  // ignore: unused_field
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              height: 90.h,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.10),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 20.w),
                          // Icon container with enhanced glassmorphism
                          Container(
                            width: 56.w,
                            height: 56.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  widget.color.withOpacity(0.3),
                                  widget.color.withOpacity(0.1),
                                ],
                              ),
                              border: Border.all(
                                color: widget.color.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.color.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              size: 28.sp,
                              color: widget.color,
                            ),
                          ),
                          SizedBox(width: 20.w),
                          // Title and arrow
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.sp,
                                      color: textColor(context),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 32.w,
                                  height: 32.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.15),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14.sp,
                                    color: textColor(context).withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 20.w),
                        ],
                      ),
                    ),
                  ).asGlass(
                    blurX: 20,
                    blurY: 20,
                    tintColor: Colors.white,
                    clipBorderRadius: BorderRadius.circular(24.r),
                    frosted: true,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Helper class for feature card metadata
class _CookFeatureCardData {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  const _CookFeatureCardData(this.title, this.icon, this.color, this.route);
}
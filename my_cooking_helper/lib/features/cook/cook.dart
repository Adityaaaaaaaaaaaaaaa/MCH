// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/theme/app_theme.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/utils/connectivity_provider.dart';
import '/utils/snackbar.dart';

class CookScreen extends ConsumerWidget {
  const CookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final isOnline = ref.watch(isOnlineProvider).maybeWhen(
      data: (v) => v, orElse: () => true,
    );

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
        '/searchRecipe',
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
      appBar: CustomAppBar(
        title: "Cook",
        showMenu: false,
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
        themeToggleWidget: ThemeToggleButton(),
      ),
      body: Stack(
        children: [
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
            padding: EdgeInsets.symmetric(horizontal: 25.0.w, vertical: 25.0.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 100.h),
                Text(
                  'Let\'s cook something!',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor(context),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'What do you want to do ?',
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

                      // ✅ Only gate the "Cook Something New" action when offline
                      final bool enabled = feature.route == '/searchRecipe'
                          ? isOnline
                          : true;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 20.h),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          curve: Curves.easeOutBack,
                          child: CookFeatureCard(
                            icon: feature.icon,
                            title: feature.title,
                            color: feature.color,
                            enabled: enabled,
                            onTap: () {
                              if (!enabled) {
                                SnackbarUtils.alert(
                                  context,
                                  "You are offline — this feature requires internet",
                                  icon: Icons.wifi_off,
                                  iconColor: Colors.redAccent,
                                  typeInfo: TypeInfo.error,
                                  position: MessagePosition.top,
                                  duration: 3,
                                );
                                return;
                              }
                              context.push(feature.route);
                            },
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

  // ✅ NEW: enable/disable flag with default true
  final bool enabled;

  const CookFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    required this.index,
    this.enabled = true,
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
    if (!widget.enabled) return; // no press effect when disabled
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.enabled) {
      // press effect not applied, but we still reverse in case
      _controller.reverse();
      // Parent onTap already handles snackbar; nothing to do here
      return;
    }
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

    // ✅ Combine animation opacity with disabled dim (0.6)
    final disabledDim = widget.enabled ? 1.0 : 0.7;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value * disabledDim,
            child: AbsorbPointer( // ✅ blocks gestures when disabled
              absorbing: !widget.enabled,
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
                            color: textColor(context).withOpacity(0.2),
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
                                  color: widget.color.withOpacity(1.0),
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
                                size: 30.sp,
                                color: widget.enabled
                                    ? widget.color
                                    : widget.color.withOpacity(0.5),
                              ),
                            ),
                            SizedBox(width: 20.w),
                            // Title and arrow (arrow dims when disabled)
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.title,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17.sp,
                                        color: textColor(context).withOpacity(
                                          widget.enabled ? 1.0 : 0.7,
                                        ),
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
                                      widget.enabled
                                          ? Icons.arrow_forward_ios_rounded
                                          : Icons.wifi_off_rounded,
                                      size: 15.sp,
                                      color: widget.enabled
                                        ? textColor(context).withOpacity(0.7)
                                        : Colors.red
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

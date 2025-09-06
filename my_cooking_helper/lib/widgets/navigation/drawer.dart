// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import 'dart:async';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _itemsController;
  late AnimationController _emojiController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _glowController;
  late AnimationController _emojiTransitionController;

  late Animation<double> _headerAnimation;
  // kept but no longer used to drive entrance
  // ignore: unused_field
  late Animation<double> _itemsAnimation;
  late Animation<double> _emojiRotation;
  late Animation<double> _emojiScale;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _glowAnimation;

  bool _isDrawerOpen = false;
  int _currentEmojiIndex = 0;
  Timer? _autoEmojiTimer;

  final List<String> foodEmojis = [
    '🍳','🥘','🍲','🥞','🧇','🍱',
    '🍔','🍟','🌭','🥪','🌮','🍕','🥙','🌯',
    '🍣','🍤','🍚','🍛','🍜','🍥','🥠',
    '🍿','🥨','🥜','🥯','🍞',
    '🍧','🍨','🍦','🥧','🍰','🧁','🍩','🍪','🍫','🍬','🍭','🍮','🍯','🥮',
    '🍎','🍉','🍓','🍒','🍑','🍍','🥭','🍋','🍊','🍌','🍏','🥝','🥥',
    '🥒','🥕','🌽','🥔','🍠','🥬','🥦','🧄','🧅','🍆',
    '🍗','🍖','🥩','🥓','🧀','🥚',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialAnimations();
    _startAutoEmojiTimer();
  }

  void _setupAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _itemsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _emojiController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3800),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat(reverse: true);

    _emojiTransitionController = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    );

    // kept for compatibility; not used to animate list anymore
    _itemsAnimation = CurvedAnimation(
      parent: _itemsController,
      curve: Curves.easeOut,
    );

    _emojiRotation = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _emojiController, curve: Curves.easeOutBack),
    );

    _emojiScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _emojiController, curve: Curves.easeOutExpo),
    );

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );

    _glowAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _startInitialAnimations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _isDrawerOpen = true);
      _currentEmojiIndex = Random().nextInt(foodEmojis.length);
      _headerController.forward();
      _emojiController.forward();
      // NOTE: we intentionally don't animate list entrance anymore
      // _itemsController.forward();
    });
  }

  void _startAutoEmojiTimer() {
    _autoEmojiTimer?.cancel();
    _autoEmojiTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted && _isDrawerOpen) _changeEmoji(false);
    });
  }

  void _changeEmoji([bool userTriggered = true]) {
    if (!mounted) return;
    if (userTriggered) {
      HapticFeedback.lightImpact();
      _startAutoEmojiTimer();
    }
    int next = Random().nextInt(foodEmojis.length);
    if (next == _currentEmojiIndex && foodEmojis.length > 1) {
      next = (next + 1) % foodEmojis.length;
    }
    setState(() => _currentEmojiIndex = next);
    _emojiController
      ..reset()
      ..forward();
  }

  void _stopAnimations() {
    if (!mounted) return;
    setState(() => _isDrawerOpen = false);
    _headerController.stop();
    _itemsController.stop();
    _emojiController.stop();
    _autoEmojiTimer?.cancel();
  }

  @override
  void dispose() {
    _autoEmojiTimer?.cancel();
    _headerController.dispose();
    _itemsController.dispose();
    _emojiController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    _emojiTransitionController.dispose();
    super.dispose();
  }

  Color _getCustomColor(bool isDark, String type) {
    switch (type) {
      case 'primary':
        return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
      case 'accent':
        return isDark ? const Color(0xFFFFAB40) : const Color(0xFFFF9800);
      case 'background':
        return isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);
      case 'surface':
        return isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
      case 'border':
        return isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);
      case 'text':
        return isDark ? const Color(0xFFE0E0E0) : const Color(0xFF212121);
      default:
        return isDark ? Colors.white : Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<_DrawerRoute> mainRoutes = [
      _DrawerRoute(icon: Icons.home_rounded, label: 'Home', path: '/home', color: const Color(0xFF4CAF50)),
      _DrawerRoute(icon: Icons.camera_alt_rounded, label: 'Smart Scan', path: '/scan', color: const Color(0xFF2196F3)),
      _DrawerRoute(icon: Icons.edit_rounded, label: 'Manual Input', path: '/manualInput', color: const Color(0xFFFF9800)),
      _DrawerRoute(icon: Icons.kitchen_rounded, label: 'My Inventory', path: '/inventory', color: const Color(0xFF9C27B0)),
      _DrawerRoute(icon: Icons.search_rounded, label: 'Search Recipe', path: '/searchRecipe', color: const Color(0xFFE91E63)),
      _DrawerRoute(icon: Icons.history_rounded, label: 'History', path: '/history', color: const Color(0xFF795548)),
      _DrawerRoute(icon: Icons.favorite_rounded, label: 'Favourites', path: '/favourites', color: const Color(0xFFF44336)),
      _DrawerRoute(icon: Icons.calendar_month_rounded, label: 'Meal Planner', path: '/planner', color: const Color(0xFF009688)),
      _DrawerRoute(icon: Icons.fastfood_rounded, label: 'My Cravings', path: '/cravings', color: const Color(0xFFFF5722)),
      _DrawerRoute(icon: Icons.shopping_cart_rounded, label: 'Shopping List', path: '/shopping', color: const Color(0xFF3F51B5)),
    ];

    final settingsRoute = _DrawerRoute(
      icon: Icons.settings_rounded,
      label: 'Settings & Preferences',
      path: '/settings',
      color: const Color(0xFF607D8B),
    );

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F), const Color(0xFF050505)]
                : [const Color(0xFFFDFDFD), const Color(0xFFF8F9FA), const Color(0xFFF1F3F4)],
          ),
        ),
        child: Column(
          children: [
            // Header animates in lightly
            AnimatedBuilder(
              animation: Listenable.merge([
                _headerAnimation, _emojiRotation, _emojiScale,
                _pulseAnimation, _waveAnimation, _glowAnimation
              ]),
              builder: (context, _) {
                return Transform.scale(
                  scale: 0.9 + (_headerAnimation.value * 0.1),
                  child: Transform.translate(
                    offset: Offset(0, -12 + (_headerAnimation.value * 12)),
                    child: _buildHeader(context, isDark),
                  ),
                );
              },
            ),

            // Routes list (no entrance animation)
            Expanded(
              child: ListView.separated(
                cacheExtent: MediaQuery.of(context).size.height,
                padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 8.h),
                physics: const BouncingScrollPhysics(),
                itemCount: mainRoutes.length,
                separatorBuilder: (_, __) => SizedBox(height: 4.h),
                itemBuilder: (context, index) =>
                    _buildDrawerItem(context, mainRoutes[index], index, isDark),
              ),
            ),

            // Bottom pinned settings
            SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_waveAnimation, _glowAnimation]),
                    builder: (context, _) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        height: 2.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1.r),
                          gradient: LinearGradient(
                            stops: [
                              0.0,
                              (_waveAnimation.value - 0.3).clamp(0.0, 1.0),
                              _waveAnimation.value,
                              (_waveAnimation.value + 0.3).clamp(0.0, 1.0),
                              1.0,
                            ],
                            colors: [
                              Colors.transparent,
                              _getCustomColor(isDark, 'primary').withOpacity(0.3 * _glowAnimation.value),
                              _getCustomColor(isDark, 'primary').withOpacity(0.8 * _glowAnimation.value),
                              _getCustomColor(isDark, 'primary').withOpacity(0.3 * _glowAnimation.value),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getCustomColor(isDark, 'primary').withOpacity(0.35 * _glowAnimation.value),
                              blurRadius: 10.r,
                              spreadRadius: 1.5.r,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
                    child: _buildDrawerItem(context, settingsRoute, -1, isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      height: 130.h,
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8.h,
        left: 12.w, right: 12.w, bottom: 8.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A2A2A).withOpacity(0.95), const Color(0xFF1A1A1A).withOpacity(0.9)]
              : [const Color(0xFFFFFFFF).withOpacity(0.95), const Color(0xFFF8F9FA).withOpacity(0.9)],
        ),
        border: Border.all(
          width: 2,
          color: _getCustomColor(isDark, 'primary').withOpacity(0.18 * _glowAnimation.value),
        ),
        boxShadow: [
          BoxShadow(
            color: _getCustomColor(isDark, 'primary').withOpacity(0.18 * _glowAnimation.value),
            blurRadius: 16.r, spreadRadius: 3.r, offset: Offset(0, 3.h),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.08),
            blurRadius: 12.r, spreadRadius: 1.r, offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Row(
          children: [
            // Emoji avatar (gentle pulse & wave ring)
            AnimatedBuilder(
              animation: Listenable.merge([_waveAnimation, _pulseAnimation, _emojiRotation, _emojiScale]),
              builder: (context, _) {
                return Container(
                  width: 70.w, height: 70.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      startAngle: _waveAnimation.value * 2 * pi,
                      colors: [
                        _getCustomColor(isDark, 'primary').withOpacity(0.35),
                        _getCustomColor(isDark, 'accent').withOpacity(0.35),
                        const Color(0xFFE91E63).withOpacity(0.35),
                        _getCustomColor(isDark, 'primary').withOpacity(0.35),
                      ],
                    ),
                  ),
                  child: Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _changeEmoji(true),
                        child: Transform.rotate(
                          angle: _emojiRotation.value,
                          child: Transform.scale(
                            scale: _emojiScale.value,
                            child: AnimatedSwitcher(
                              duration: _emojiTransitionController.duration!,
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, anim) {
                                return FadeTransition(
                                  opacity: anim,
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 0.96, end: 1.0).animate(anim),
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                key: ValueKey(_currentEmojiIndex),
                                width: 62.w, height: 62.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getCustomColor(isDark, 'surface'),
                                  border: Border.all(
                                    color: _getCustomColor(isDark, 'primary').withOpacity(0.45),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    foodEmojis[_currentEmojiIndex],
                                    style: TextStyle(fontSize: 28.sp),
                                  ),
                                ),
                              ).asGlass(
                                tintColor: _getCustomColor(isDark, 'primary').withOpacity(0.08),
                                clipBorderRadius: BorderRadius.circular(31.r),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(width: 16.w),

            // Title (no ellipsis): FittedBox scales down to fit width
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'My Cooking Helper',
                    softWrap: false,
                    overflow: TextOverflow.visible, // no ellipsis
                    style: TextStyle(
                      fontSize: 20.sp, // will scale down if needed
                      fontWeight: FontWeight.w800,
                      color: _getCustomColor(isDark, 'text'),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    _DrawerRoute route,
    int index,
    bool isDark,
  ) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final isSelected = currentPath == route.path;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 3.h, horizontal: 8.w),
      height: 58.h,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                      colors: [route.color.withOpacity(0.14), route.color.withOpacity(0.05)],
                    )
                  : null,
              border: Border.all(
                color: isSelected
                    ? route.color.withOpacity(0.55 * _glowAnimation.value)
                    : _getCustomColor(isDark, 'border').withOpacity(0.12),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: route.color.withOpacity(0.26 * _glowAnimation.value),
                        blurRadius: 12.r, spreadRadius: 1.2.r,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.grey).withOpacity(0.05),
                        blurRadius: 8.r, spreadRadius: 1.r, offset: Offset(0, 2.h),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18.r),
                splashColor: route.color.withOpacity(0.18),
                highlightColor: route.color.withOpacity(0.1),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  if (currentPath != route.path) {
                    context.pop();
                    context.push(route.path);
                  } else {
                    context.pop();
                  }
                  _stopAnimations();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                  child: Row(
                    children: [
                      // Icon box
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: 42.w, height: 42.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [route.color.withOpacity(0.2), route.color.withOpacity(0.06)],
                                )
                              : LinearGradient(
                                  colors: [_getCustomColor(isDark, 'surface'), _getCustomColor(isDark, 'surface').withOpacity(0.5)],
                                ),
                          border: Border.all(
                            color: isSelected
                                ? route.color.withOpacity(0.4)
                                : _getCustomColor(isDark, 'border').withOpacity(0.18),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Icon(
                          route.icon,
                          size: 22.w,
                          color: isSelected
                              ? route.color
                              : _getCustomColor(isDark, 'text').withOpacity(0.85),
                        ),
                      ),

                      SizedBox(width: 16.w),

                      // Text + underline when selected
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              route.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis, // safe for long labels
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 15.sp,
                                color: isSelected ? route.color : _getCustomColor(isDark, 'text'),
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (isSelected) ...[
                              SizedBox(height: 2.h),
                              AnimatedBuilder(
                                animation: _glowAnimation,
                                builder: (_, __) {
                                  return Container(
                                    width: 36.w, height: 2.h,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(1.r),
                                      gradient: LinearGradient(
                                        colors: [
                                          route.color.withOpacity(0.85 * _glowAnimation.value),
                                          route.color.withOpacity(0.35 * _glowAnimation.value),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: route.color.withOpacity(0.4 * _glowAnimation.value),
                                          blurRadius: 6.r, spreadRadius: 1.r,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (isSelected)
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, _) {
                            return Transform.scale(
                              scale: _pulseAnimation.value * 0.2 + 0.8,
                              child: Container(
                                width: 8.w, height: 8.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: route.color,
                                  boxShadow: [
                                    BoxShadow(
                                      color: route.color.withOpacity(0.55 * _glowAnimation.value),
                                      blurRadius: 10.r, spreadRadius: 2.r,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
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

class _DrawerRoute {
  final IconData icon;
  final String label;
  final String path;
  final Color color;

  const _DrawerRoute({
    required this.icon,
    required this.label,
    required this.path,
    required this.color,
  });
}

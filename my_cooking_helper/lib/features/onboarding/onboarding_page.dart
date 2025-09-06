// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentIndex = 0;
  
  late AnimationController _slideController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _shimmerAnimation;

  final List<List<Color>> _gradients = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
  ];

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/images/onboarding/onb1.png",
      "title": "Welcome to My Cooking Helper",
      "desc": "Plan meals, manage your pantry, and discover recipes - all in one smart kitchen app.",
    },
    {
      "image": "assets/images/onboarding/onb2.png",
      "title": "Track Your Pantry with Ease",
      "desc": "Scan groceries, keep your pantry organized, and cut down on food waste effortlessly.",
    },
    {
      "image": "assets/images/onboarding/onb3.png",
      "title": "Get Personalised Recipe Ideas",
      "desc": "Find tasty recipes tailored to your preferences and what you already have at home.",
    },
  ];

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _floatAnimation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.forward();
    _floatController.repeat(reverse: true);
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _slideController.reset();
      _slideController.forward();
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go('/signin');
    }
  }

  Widget _buildAnimatedButton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: LinearGradient(
              colors: _gradients[_currentIndex],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _gradients[_currentIndex][0].withOpacity(0.4),
                blurRadius: 12.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + _shimmerAnimation.value, 0.0),
                      end: Alignment(1.0 + _shimmerAnimation.value, 0.0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18.r),
                  onTap: _nextPage,
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      _currentIndex == _pages.length - 1 ? "Get Started" : "Next",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: _currentIndex == i ? 28.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            gradient: _currentIndex == i
                ? LinearGradient(
                    colors: _gradients[_currentIndex],
                  )
                : null,
            color: _currentIndex != i ? Colors.grey.withOpacity(0.3) : null,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingCard({required Widget child}) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value * 20.h),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: Container(
                padding: EdgeInsets.all(24.w),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background gradients
          ...List.generate(_gradients.length, (i) {
            return AnimatedOpacity(
              opacity: i == _currentIndex ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _gradients[i][0],
                      _gradients[i][1],
                      _gradients[i][0].withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 20.h),
                
                // Main content
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                      _slideController.reset();
                      _slideController.forward();
                    },
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Image container with floating animation
                              _buildFloatingCard(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 260.w,
                                      height: 260.w,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 15.r,
                                            offset: Offset(0, 5.h),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20.r),
                                        child: Image.asset(
                                          page["image"]!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    
                                    SizedBox(height: 32.h),
                                    
                                    Text(
                                      page["title"]!,
                                      style: TextStyle(
                                        fontSize: 30.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    
                                    SizedBox(height: 16.h),
                                    
                                    Text(
                                      page["desc"]!,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.white,
                                        height: 1.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Page indicator
                _buildPageIndicator(),
                
                SizedBox(height: 24.h),
                
                // Next/Get Started button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: _buildAnimatedButton(),
                ),
                
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
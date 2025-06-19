import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<List<Color>> _gradients = [
    [Color(0xFFB8E1FC), Color(0xFFE5F1FA)],   
    [Color(0xFFD0F2C7), Color(0xFFE5F1FA)],   
    [Color(0xFFF9D4C1), Color(0xFFE5F1FA)],  
  ];

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/images/onboarding/onb1.png",
      "title": "Welcome to My Cooking Helper",
      "desc": "Your smart kitchen companion. Plan meals, manage your pantry, and discover recipes tailored to you.",
    },
    {
      "image": "assets/images/onboarding/onb2.png",
      "title": "Track Your Pantry with Ease",
      "desc": "Scan your groceries, manage what you have, and reduce food waste effortlessly.",
    },
    {
      "image": "assets/images/onboarding/onb3.png",
      "title": "Get Personalised Recipe Ideas",
      "desc": "Discover delicious recipes based on your preferences and what's in your kitchen.",
    },
  ];

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double imgWidth = screenWidth * 0.75;
    final double imgHeight = imgWidth * 1.5;

    return Scaffold(
      body: Stack(
        children: [
          ...List.generate(_gradients.length, (i) {
            return AnimatedOpacity(
              opacity: i == _currentIndex ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _gradients[i],
                  ),
                ),
              ),
            );
          }),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 25.h), // Top space
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _pages.length,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0.h, horizontal: 0.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              key: ValueKey(page["image"]),
                              width: imgWidth.w,
                              height: imgHeight > 300.h ? 300.h : imgHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32.r),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32.r),
                                child: Image.asset(
                                  page["image"]!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            SizedBox(height: 48.h),
                            Text(
                              page["title"]!,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32.0.w),
                              child: Text(
                                page["desc"]!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.blueGrey.shade700,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.symmetric(horizontal: 6.w),
                      width: _currentIndex == i ? 24.w : 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: _currentIndex == i
                            ? Colors.blueAccent
                            : Colors.blueGrey.shade200,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        minimumSize: Size(double.infinity, 54.h),
                      ),
                      child: Text(
                        _currentIndex == _pages.length - 1
                            ? "Get Started"
                            : "Next",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
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

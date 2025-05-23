import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  // Gradients for each onboarding page
  final List<List<Color>> _gradients = [
    [Color(0xFFB8E1FC), Color(0xFFE5F1FA)],   // Blue
    [Color(0xFFD0F2C7), Color(0xFFE5F1FA)],   // Light green
    [Color(0xFFF9D4C1), Color(0xFFE5F1FA)],   // Light orange/pink
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
      // Animated gradient background
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradients[_currentIndex],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80), // Top space
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // AnimatedSwitcher for the image!
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(opacity: animation, child: child),
                            child: Container(
                              key: ValueKey(page["image"]),
                              width: imgWidth,
                              height: imgHeight > 340 ? 340 : imgHeight,
                              decoration: BoxDecoration(
                                //color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Image.asset(
                                  page["image"]!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          // AnimatedSwitcher for text for extra smoothness
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(opacity: animation, child: child),
                            child: Column(
                              key: ValueKey(_currentIndex),
                              children: [
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
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: _currentIndex == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == i
                          ? Colors.blueAccent
                          : Colors.blueGrey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    child: Text(
                      _currentIndex == _pages.length - 1
                          ? "Get Started"
                          : "Next",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

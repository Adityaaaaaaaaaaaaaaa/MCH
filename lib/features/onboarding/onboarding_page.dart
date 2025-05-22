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

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/images/onboarding/onboarding1.png",
      "title": "Welcome to My Cooking Helper",
      "desc": "Your smart kitchen companion. Plan meals, manage your pantry, and discover recipes tailored to you."
    },
    {
      "image": "assets/images/onboarding/onboarding2.png",
      "title": "Track Your Pantry with Ease",
      "desc": "Scan your groceries, manage what you have, and reduce food waste effortlessly."
    },
    {
      "image": "assets/images/onboarding/onboarding3.png",
      "title": "Get Personalised Recipe Ideas",
      "desc": "Discover delicious recipes based on your preferences and what's in your kitchen."
    },
  ];

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // Go to sign in page with go_router
      context.go('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive: constrain max width for web/tablet
    return Scaffold(
      backgroundColor: const Color(0xFFE5F1FA),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420), // 420 is typical mobile width
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 30),
                            // Responsive image height (20-25% of screen)
                            Container(
                              height: MediaQuery.of(context).size.height * 0.23,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                color: Colors.white.withOpacity(0.5),
                              ),
                              child: Center(
                                child: Image.asset(
                                  page["image"]!,
                                  height: MediaQuery.of(context).size.height * 0.25,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 48),
                            Text(
                              page["title"]!,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page["desc"]!,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.blueGrey.shade700,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Progress dots
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
                        color: _currentIndex == i ? Colors.blueAccent : Colors.blueGrey.shade200,
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size(double.infinity, 54),
                      ),
                      child: Text(
                        _currentIndex == _pages.length - 1 ? "Get Started" : "Next",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

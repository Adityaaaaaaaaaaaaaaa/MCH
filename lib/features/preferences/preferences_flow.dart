import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/theme/app_theme.dart';
import 'preference_utils.dart';
import 'preference_question_widgets.dart';

class PreferencesFlow extends StatefulWidget {
  const PreferencesFlow({super.key});

  @override
  State<PreferencesFlow> createState() => _PreferencesFlowState();
}

class _PreferencesFlowState extends State<PreferencesFlow> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  final UserPreferences preferences = UserPreferences();

  final int totalPages = 9;

  void _nextPage() {
    if (_currentPage < totalPages - 1) {
      setState(() => _currentPage++);
      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      // Go to home with preferences (for now, just show as arguments)
      context.go('/home', extra: preferences);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _controller.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 0),
      child: LinearProgressIndicator(
        value: (_currentPage + 1) / totalPages,
        backgroundColor: Colors.blue[50],
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        minHeight: 7,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Animated background color gradient per page
    final List<List<Color>> lightGradients = [
      [Color(0xFFB8E1FC), Color(0xFFE5F1FA)],
      [Color(0xFFD0F2C7), Color(0xFFE5F1FA)],
      [Color(0xFFF9D4C1), Color(0xFFE5F1FA)],
      [Color(0xFFFFF9C4), Color(0xFFE5F1FA)],
      [Color(0xFFFFDDE1), Color(0xFFE5F1FA)],
      [Color(0xFFC9F7F5), Color(0xFFE5F1FA)],
      [Color(0xFFFED6E3), Color(0xFFE5F1FA)],
      [Color(0xFFF3F8FF), Color(0xFFE5F1FA)],
      [Color(0xFFB8E1FC), Color(0xFFE5F1FA)],
    ];

    final List<List<Color>> darkGradients = [
      [Color(0xFF233347), Color(0xFF15202B)],
      [Color(0xFF264733), Color(0xFF1C2D24)],
      [Color(0xFF482E3B), Color(0xFF1B181C)],
      [Color(0xFF332C1C), Color(0xFF181818)],
      [Color(0xFF282828), Color(0xFF131313)],
      [Color(0xFF19282C), Color(0xFF0B1820)],
      [Color(0xFF41283D), Color(0xFF261826)],
      [Color(0xFF23263A), Color(0xFF131A29)],
      [Color(0xFF233347), Color(0xFF15202B)],
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColors = isDark ? darkGradients[_currentPage] : lightGradients[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 60), // Lower progress bar a bit
                  _buildProgressBar(),
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // 1. Intro
                        _QuestionPage(
                          title: "First, let's get to know you better!",
                          subtitle: "Let's tailor your experience for a food-tastic journey!",
                          onNext: _nextPage,
                        ),
                        // 2. Gender
                        AnimatedSingleSelectBig(
                          title: "Choose Your Gender",
                          options: PreferenceUtils.genders,
                          value: preferences.gender,
                          onChanged: (val) => setState(() => preferences.gender = val),
                          onNext: _nextPage,
                          onBack: _prevPage,
                        ),
                        // 3. Cooking Time
                        AnimatedSingleSelectBig(
                          title: "How much time do you have for cooking?",
                          options: PreferenceUtils.cookingTimes,
                          value: preferences.cookingTime,
                          onChanged: (val) => setState(() => preferences.cookingTime = val),
                          onNext: _nextPage,
                          onBack: _prevPage,
                        ),
                        // 4. Allergies
                        AnimatedMultiSelectSmall(
                          title: "Do you have any allergies or intolerances?",
                          options: PreferenceUtils.allergies,
                          values: preferences.allergies,
                          onChanged: (vals) => setState(() => preferences.allergies = vals),
                          onNext: _nextPage,
                          onBack: _prevPage,
                        ),
                        // 5. Diet Type
                        AnimatedMultiSelectSmall(
                          title: "What type of diet do you follow/prefer?",
                          options: PreferenceUtils.diets,
                          values: preferences.diets,
                          onChanged: (vals) => setState(() => preferences.diets = vals),
                          onNext: _nextPage,
                          onBack: _prevPage,
                        ),
                        // 6. Cuisines Loved
                        AnimatedMultiSelectSmall(
                          title: "Which cuisines do you love?",
                          options: PreferenceUtils.cuisines,
                          values: preferences.cuisines,
                          onChanged: (vals) => setState(() => preferences.cuisines = vals),
                          onNext: _nextPage,
                          onBack: _prevPage,
                        ),
                        // 7. Spice Level
                        AnimatedSingleSelectBig(
                          title: "What’s the max spice level you can handle?",
                          options: PreferenceUtils.spiceLevels,
                          value: preferences.spiceLevel,
                          onChanged: (val) => setState(() => preferences.spiceLevel = val),
                          onNext: _nextPage,
                          onBack: _prevPage,
                        ),
                        // 8. Barriers
                        AnimatedMultiSelectSmall(
                          title: "What typically stops you from cooking at home?",
                          options: PreferenceUtils.barriers,
                          values: preferences.barriers,
                          onChanged: (vals) => setState(() => preferences.barriers = vals),
                          onNext: _nextPage,
                          onBack: _prevPage,
                        ),
                        // 9. Thank you / Confirmation
                        _ThankYouPage(
                          onNext: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                              'displayName': user.displayName,
                              'email': user.email,
                              'onboardingCompleted': true,
                              'preferences': preferences.toMap(), // Ensure your UserPreferences has toMap()
                            }, SetOptions(merge: true));
                            context.go('/home');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // THEME TOGGLE BUTTON
              Positioned(
                top: 10,
                right: 18,
                child: ThemeToggleButton(), // Add your own ThemeToggleButton widget!
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple intro/thank you page
class _QuestionPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onNext;
  const _QuestionPage({required this.title, this.subtitle, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 18.0, left: 24, right: 24),
            child: Text(subtitle!, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          ),
        const Spacer(),
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            minimumSize: const Size(110, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 14),
            child: Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

// Thank You / Confirmation
class _ThankYouPage extends StatelessWidget {
  final VoidCallback onNext;
  const _ThankYouPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text("Thank you for trusting us!",
              style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(50.0),
          child: Text(
            "We're committed to protecting your information with the highest standards of privacy and security.\n\n"
            "Ready to discover your new cooking partner? Complete this step and click Ready below!",
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            minimumSize: const Size(110, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 14),
            child: Text("Ready!", style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

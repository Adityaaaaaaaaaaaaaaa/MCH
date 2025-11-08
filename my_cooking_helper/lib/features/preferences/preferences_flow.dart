import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import '/utils/emoji_animation.dart';
import '/theme/app_theme.dart';
import '/utils/preference_utils.dart';
import '/widgets/preference_question_widgets.dart';

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
      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 0.h),
      child: StepProgressIndicator(
        totalSteps: totalPages,
        currentStep: _currentPage + 1, // +1 because steps are 1-indexed
        size: 6.h, // Thickness of bar
        direction: Axis.horizontal,
        progressDirection: TextDirection.ltr,
        padding: 3.w,
        roundedEdges: Radius.circular(15.r),
        selectedGradientColor: LinearGradient(
          colors: [Colors.green, Colors.lightGreenAccent],
        ),
        unselectedGradientColor: LinearGradient(
          colors: [Colors.lightBlue, Colors.blue],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  SizedBox(height: 60.h), // Lower progress bar a bit
                  _buildProgressBar(),
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        //Intro
                        Stack(
                          children: [
                            _QuestionPage(
                              title: "First, let's get to know you better!",
                              subtitle: "Let's tailor your experience for a food-tastic journey!",
                              onNext: _nextPage,
                            ),
                            Positioned(
                              bottom: 65.h,
                              left: 250.w,
                              child: EmojiAnimation(name: 'sparkles'),
                            ),
                            Positioned(
                              top: 140.h,
                              right: 40.w,
                              child: EmojiAnimation(name: 'sparkles'),
                            ),
                            Positioned(
                              top: 280.h,
                              left: 50.w,
                              child: EmojiAnimation(name: 'sparkles'),
                            ),
                            Positioned(
                              top: 70.h,
                              left: 50.w,
                              child: EmojiAnimation(name: 'sparkles'),
                            ),
                            Positioned(
                              top: 100.h,
                              left: 150.w,
                              child: EmojiAnimation(name: 'confettiBall', size: 50,),
                            ),
                            Positioned(
                              bottom: 170.h,
                              left: 150.w,
                              child: EmojiAnimation(name: 'clinkingBeerMugs', size: 50,),
                            ),
                          ],
                        ),
                        //Gender
                        AnimatedSingleSelectBig(
                          title: "Choose Your Gender",
                          options: PreferenceUtils.genders,
                          value: preferences.gender,
                          onChanged: (val) => setState(() => preferences.gender = val),
                          onNext: _nextPage,
                          onBack: _prevPage,
                        ),
                        //Cooking Time
                        AnimatedSingleSelectBig(
                          title: "How much time do you have for cooking?",
                          options: PreferenceUtils.cookingTimes,
                          value: preferences.cookingTime,
                          onChanged: (val) => setState(() => preferences.cookingTime = val),
                          onNext: _nextPage,
                          onBack: _prevPage,
                        ),
                        //Allergies
                        AnimatedMultiSelectSmall(
                          title: "Do you have any allergies or intolerances?",
                          options: PreferenceUtils.allergies,
                          values: preferences.allergies,
                          onChanged: (vals) => setState(() => preferences.allergies = vals),
                          onNext: _nextPage,
                          onBack: _prevPage,
                        ),
                        //Diet Type
                        AnimatedMultiSelectSmall(
                          title: "What type of diet do you follow/prefer?",
                          options: PreferenceUtils.diets,
                          values: preferences.diets,
                          onChanged: (vals) => setState(() => preferences.diets = vals),
                          onNext: _nextPage,
                          onBack: _prevPage,
                        ),
                        //Cuisines Loved
                        AnimatedMultiSelectSmall(
                          title: "Which cuisines do you love?",
                          options: PreferenceUtils.cuisines,
                          values: preferences.cuisines,
                          onChanged: (vals) => setState(() => preferences.cuisines = vals),
                          onNext: _nextPage,
                          onBack: _prevPage,
                        ),
                        //Spice Level
                        AnimatedSingleSelectBig(
                          title: "What's the max spice level you can handle?",
                          options: PreferenceUtils.spiceLevels,
                          value: preferences.spiceLevel,
                          onChanged: (val) => setState(() => preferences.spiceLevel = val),
                          onNext: _nextPage,
                          onBack: _prevPage,
                        ),
                        //Barriers
                        AnimatedMultiSelectSmall(
                          title: "What typically stops you from cooking at home?",
                          options: PreferenceUtils.barriers,
                          values: preferences.barriers,
                          onChanged: (vals) => setState(() => preferences.barriers = vals),
                          onNext: _nextPage,
                          onBack: _prevPage,
                        ),
                        //Thank you
                        _ThankYouPage(
                          onNext: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                              'displayName': user.displayName,
                              'email': user.email,
                              'onboardingCompleted': true,
                              'preferences': preferences.toMap(), 
                            }, SetOptions(merge: true));
                            context.go('/home');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // theme button
              Positioned(
                top: 10.h,
                right: 18.w,
                child: ThemeToggleButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// intro page
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
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Text(
            title, 
            style: Theme.of(context).textTheme.headlineSmall, 
            textAlign: TextAlign.center
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: EdgeInsets.only(top: 25.0.h, left: 25.w, right: 25.w),
            child: Text(
              subtitle!, 
              style: Theme.of(context).textTheme.bodyLarge, 
              textAlign: TextAlign.center
            ),
          ),
        const Spacer(),
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            minimumSize: Size(130.w, 50.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.0.w, vertical: 10.h),
            child: Text("Next", style: TextStyle(fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ),
        SizedBox(height: 100.h),
      ],
    );
  }
}

// Thank You page
class _ThankYouPage extends StatelessWidget {
  final VoidCallback onNext;
  const _ThankYouPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Text("Thank you for trusting us!",
                  style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.all(50.0.w),
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
                minimumSize: Size(110.w, 48.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0.w, vertical: 15.h),
                child: Text("Ready!", style: TextStyle(fontSize: 18.sp, color: Colors.white)),
              ),
            ),
            SizedBox(height: 50.h),
          ],
        ),
        Positioned(
          top: 150.h,
          left: 150.w,
          child: EmojiAnimation(name: 'clinkingGlasses', size: 60,),
        ),
        Positioned(
          top: 30.h,
          left: 150.w,
          child: EmojiAnimation(name: 'glowingStar', size: 40,),
        ),
        Positioned(
          bottom: 140.h,
          left: 150.w,
          child: EmojiAnimation(name: 'rocket', size: 60,),
        ),
        Positioned(
          bottom: 190.h,
          left: 100.w,
          child: EmojiAnimation(name: 'sparkles', size: 20,),
        ),
        Positioned(
          bottom: 100.h,
          right: 70.w,
          child: EmojiAnimation(name: 'sparkles', size: 20,),
        ),
        Positioned(
          top: 30.h,
          left: 20.w,
          child: EmojiAnimation(name: 'partyPopper', size: 40,),
        ),
      ],
    );
  }
}

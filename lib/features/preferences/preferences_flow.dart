import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'user_preferences.dart';
import 'preferences_options.dart';


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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
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
                    _SingleSelectPage(
                      title: "Choose Your Gender",
                      subtitle: "We ask your gender to provide personalized recommendations.",
                      options: PreferencesOptions.genders,
                      value: preferences.gender,
                      onChanged: (val) => setState(() => preferences.gender = val),
                      onNext: _nextPage,
                      onBack: _prevPage,
                    ),
                    // 3. Cooking Time
                    _SingleSelectPage(
                      title: "How much time do you have for cooking?",
                      options: PreferencesOptions.cookingTimes,
                      value: preferences.cookingTime,
                      onChanged: (val) => setState(() => preferences.cookingTime = val),
                      onNext: _nextPage,
                      onBack: _prevPage,
                    ),
                    // 4. Allergies
                    _MultiSelectPage(
                      title: "Do you have any allergies or intolerances?",
                      options: PreferencesOptions.allergies,
                      values: preferences.allergies,
                      onChanged: (vals) => setState(() => preferences.allergies = vals),
                      onNext: _nextPage,
                      onBack: _prevPage,
                    ),
                    // 5. Diet Type
                    _MultiSelectPage(
                      title: "What type of diet do you follow/prefer?",
                      options: PreferencesOptions.diets,
                      values: preferences.diets,
                      onChanged: (vals) => setState(() => preferences.diets = vals),
                      onNext: _nextPage,
                      onBack: _prevPage,
                    ),
                    // 6. Cuisines Loved
                    _MultiSelectPage(
                      title: "Which cuisines do you love?",
                      options: PreferencesOptions.cuisines,
                      values: preferences.cuisines,
                      onChanged: (vals) => setState(() => preferences.cuisines = vals),
                      onNext: _nextPage,
                      onBack: _prevPage,
                    ),
                    // 7. Spice Level
                    _SingleSelectPage(
                      title: "What’s the max spice level you can handle?",
                      options: PreferencesOptions.spiceLevels,
                      value: preferences.spiceLevel,
                      onChanged: (val) => setState(() => preferences.spiceLevel = val),
                      onNext: _nextPage,
                      onBack: _prevPage,
                    ),
                    // 8. Barriers
                    _MultiSelectPage(
                      title: "What typically stops you from cooking at home?",
                      options: PreferencesOptions.barriers,
                      values: preferences.barriers,
                      onChanged: (vals) => setState(() => preferences.barriers = vals),
                      onNext: _nextPage,
                      onBack: _prevPage,
                    ),
                    // 9. Thank you / Confirmation
                    _ThankYouPage(
                      onNext: () {
                        // Navigate to home and pass preferences as extra
                        context.go('/home', extra: preferences);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Question Page (intro, thank you)
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
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 14),
            child: Text("Next", style: TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// Single-Select Question Page
class _SingleSelectPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const _SingleSelectPage({
    required this.title,
    this.subtitle,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.onNext,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0, left: 24, right: 24),
            child: Text(subtitle!, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          ),
        const SizedBox(height: 24),
        ...options.map((option) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 24),
              child: GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: value == option ? Colors.blueAccent : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: value == option ? Colors.blueAccent : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: Text(
                    option,
                    style: TextStyle(
                      color: value == option ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (onBack != null)
              TextButton(
                onPressed: onBack,
                child: const Text("Back"),
              ),
            ElevatedButton(
              onPressed: value != null ? onNext : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 14),
                child: Text("Next", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// Multi-Select Question Page
class _MultiSelectPage extends StatelessWidget {
  final String title;
  final List<String> options;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const _MultiSelectPage({
    required this.title,
    required this.options,
    required this.values,
    required this.onChanged,
    required this.onNext,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: options.map((option) {
            final selected = values.contains(option);
            return FilterChip(
              label: Text(option, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              selected: selected,
              selectedColor: Colors.blueAccent.withOpacity(0.7),
              backgroundColor: Colors.grey.shade100,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
              onSelected: (checked) {
                final newVals = List<String>.from(values);
                if (checked) {
                  newVals.add(option);
                } else {
                  newVals.remove(option);
                }
                onChanged(newVals);
              },
            );
          }).toList(),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (onBack != null)
              TextButton(
                onPressed: onBack,
                child: const Text("Back"),
              ),
            ElevatedButton(
              onPressed: values.isNotEmpty ? onNext : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 14),
                child: Text("Next", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
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
          padding: const EdgeInsets.all(24.0),
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
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 14),
            child: Text("Ready!", style: TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

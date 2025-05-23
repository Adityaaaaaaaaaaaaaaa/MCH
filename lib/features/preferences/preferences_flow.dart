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
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8), // Top spacing here
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
    final List<List<Color>> gradients = [
      [Colors.blue.shade50, Colors.blue.shade100, Colors.white],
      [Colors.purple.shade50, Colors.purple.shade100, Colors.white],
      [Colors.green.shade50, Colors.green.shade100, Colors.white],
      [Colors.red.shade50, Colors.orange.shade100, Colors.white],
      [Colors.teal.shade50, Colors.teal.shade100, Colors.white],
      [Colors.yellow.shade50, Colors.orange.shade100, Colors.white],
      [Colors.deepOrange.shade50, Colors.red.shade100, Colors.white],
      [Colors.blueGrey.shade50, Colors.blueGrey.shade100, Colors.white],
      [Colors.blue.shade50, Colors.blue.shade100, Colors.white],
    ];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradients[_currentPage],
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
                    _QuestionPage(
                      title: "First, let's get to know you better! 👋",
                      subtitle: "Let's tailor your experience for a food-tastic journey!",
                      onNext: _nextPage,
                    ),
                    _SingleSelectPageWithEmojis(
                      title: "Choose Your Gender",
                      subtitle: "We ask your gender to provide personalized recommendations.",
                      options: PreferencesOptions.genders,
                      value: preferences.gender,
                      onChanged: (val) => setState(() => preferences.gender = val),
                      onNext: _nextPage,
                      onBack: _prevPage,
                      highlightColor: Colors.blueAccent,
                    ),
                    _SingleSelectPageWithEmojis(
                      title: "How much time do you have for cooking?",
                      options: PreferencesOptions.cookingTimes,
                      value: preferences.cookingTime,
                      onChanged: (val) => setState(() => preferences.cookingTime = val),
                      onNext: _nextPage,
                      onBack: _prevPage,
                      highlightColor: Colors.purpleAccent,
                    ),
                    _MultiSelectPageWithEmojis(
                      title: "Do you have any allergies or intolerances?",
                      options: PreferencesOptions.allergies,
                      values: preferences.allergies,
                      onChanged: (vals) => setState(() => preferences.allergies = vals),
                      onNext: _nextPage,
                      onBack: _prevPage,
                      highlightColor: Colors.green,
                    ),
                    _MultiSelectPageWithEmojis(
                      title: "What type of diet do you follow/prefer?",
                      options: PreferencesOptions.diets,
                      values: preferences.diets,
                      onChanged: (vals) => setState(() => preferences.diets = vals),
                      onNext: _nextPage,
                      onBack: _prevPage,
                      highlightColor: Colors.teal,
                    ),
                    _MultiSelectPageWithEmojis(
                      title: "Which cuisines do you love?",
                      options: PreferencesOptions.cuisines,
                      values: preferences.cuisines,
                      onChanged: (vals) => setState(() => preferences.cuisines = vals),
                      onNext: _nextPage,
                      onBack: _prevPage,
                      highlightColor: Colors.orange,
                    ),
                    _SingleSelectPageWithEmojis(
                      title: "What’s the max spice level you can handle?",
                      options: PreferencesOptions.spiceLevels,
                      value: preferences.spiceLevel,
                      onChanged: (val) => setState(() => preferences.spiceLevel = val),
                      onNext: _nextPage,
                      onBack: _prevPage,
                      highlightColor: Colors.deepOrangeAccent,
                    ),
                    _MultiSelectPageWithEmojis(
                      title: "What typically stops you from cooking at home?",
                      options: PreferencesOptions.barriers,
                      values: preferences.barriers,
                      onChanged: (vals) => setState(() => preferences.barriers = vals),
                      onNext: _nextPage,
                      onBack: _prevPage,
                      highlightColor: Colors.blueGrey,
                    ),
                    _ThankYouPage(
                      onNext: () => context.go('/home', extra: preferences),
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

// INTRO/THANK YOU PAGE
class _QuestionPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onNext;
  const _QuestionPage({required this.title, this.subtitle, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 18.0),
                child: Text(subtitle!, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
              ),
            const SizedBox(height: 50),
            Row(
              children: [
                Expanded(child: SizedBox()),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
                    ),
                    child: const Text("Next", style: TextStyle(fontSize: 18)),
                  ),
                ),
                Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// SINGLE SELECT WITH EMOJIS (uses _LargeChoice)
class _SingleSelectPageWithEmojis extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Map<String, String>> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final Color highlightColor;
  const _SingleSelectPageWithEmojis({
    required this.title,
    this.subtitle,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.onNext,
    this.onBack,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0), // <-- Adjust padding here
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(subtitle!, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
            ),
          const SizedBox(height: 18), // Spacing before choices
          ...options.map((option) => _LargeChoice(
            label: option['label']!,
            emoji: option['emoji']!,
            selected: value == option['label'],
            onTap: () => onChanged(option['label']!),
            selectedColor: highlightColor,
          )),
          const Spacer(),
          Row(
            children: [
              if (onBack != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: highlightColor, width: 2),
                    ),
                    child: const Text("Back", style: TextStyle(fontSize: 16)),
                  ),
                ),
              if (onBack != null) const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: value != null ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: highlightColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

// MULTI SELECT WITH EMOJIS (compact, with no scroll conflicts)
// MULTI SELECT WITH EMOJIS (all chips always visible)
class _MultiSelectPageWithEmojis extends StatelessWidget {
  final String title;
  final List<Map<String, String>> options;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final Color highlightColor;

  const _MultiSelectPageWithEmojis({
    required this.title,
    required this.options,
    required this.values,
    required this.onChanged,
    required this.onNext,
    this.onBack,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // <-- Adjust padding here
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 26),
          Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), // Add vertical padding if you wish
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: options.map((option) {
                final selected = values.contains(option['label']!);
                return _CompactChoice(
                  label: option['label']!,
                  emoji: option['emoji']!,
                  selected: selected,
                  onTap: () {
                    final newVals = List<String>.from(values);
                    if (!selected) {
                      newVals.add(option['label']!);
                    } else {
                      newVals.remove(option['label']!);
                    }
                    onChanged(newVals);
                  },
                  selectedColor: highlightColor,
                );
              }).toList(),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              if (onBack != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: highlightColor, width: 2),
                    ),
                    child: const Text("Back", style: TextStyle(fontSize: 16)),
                  ),
                ),
              if (onBack != null) const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: values.isNotEmpty ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: highlightColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

// Compact Choice Widget (multi-select, fits more)
class _CompactChoice extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _CompactChoice({
    super.key,
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), // <-- adjust for chip size
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? selectedColor : Colors.grey.shade300,
            width: 1.7,
          ),
          boxShadow: selected
              ? [BoxShadow(color: selectedColor.withOpacity(0.13), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : Colors.black87,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Large Choice Widget (single-select, prominent)
class _LargeChoice extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _LargeChoice({
    super.key,
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16), // <-- adjust for bigger single choices
        margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? selectedColor : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: selectedColor.withOpacity(0.16), blurRadius: 12, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 18),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black87,
                  fontSize: 19,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// THANK YOU PAGE
class _ThankYouPage extends StatelessWidget {
  final VoidCallback onNext;
  const _ThankYouPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Text("Thank you for trusting us! 🎉",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "We're committed to protecting your information with the highest standards of privacy and security.\n\n"
                "Ready to discover your new cooking partner? Complete this step and click Ready below!",
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: SizedBox()),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
                    ),
                    child: const Text("Ready!", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

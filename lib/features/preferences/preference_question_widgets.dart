import 'package:flutter/material.dart';
import 'preference_utils.dart';

// Large single select (centered, no tick, fixed height)
class AnimatedSingleSelectBig extends StatelessWidget {
  final String title;
  final List<PreferenceOption> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const AnimatedSingleSelectBig({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
    this.onNext,
    this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 28),
            Column(
              children: options.map((opt) {
                final selected = value == opt.label;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 54,
                    decoration: BoxDecoration(
                      color: selected ? Colors.blueAccent : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected ? Colors.blueAccent : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.12), blurRadius: 8, offset: Offset(0, 2))]
                          : [],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => onChanged(opt.label),
                      child: Center(
                        child: Text(
                          "${opt.emoji} ${opt.label}",
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
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
                  onPressed: value != null ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(110, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// Small multi-select, centered, no tick, no size jump
class AnimatedMultiSelectSmall extends StatelessWidget {
  final String title;
  final List<PreferenceOption> options;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const AnimatedMultiSelectSmall({
    required this.title,
    required this.options,
    required this.values,
    required this.onChanged,
    this.onNext,
    this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: options.map((opt) {
                  final selected = values.contains(opt.label);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blueAccent : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? Colors.blueAccent : Colors.grey.shade300,
                        width: 1.7,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        final newVals = List<String>.from(values);
                        if (selected) {
                          newVals.remove(opt.label);
                        } else {
                          newVals.add(opt.label);
                        }
                        onChanged(newVals);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        child: Text(
                          "${opt.emoji} ${opt.label}",
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(110, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

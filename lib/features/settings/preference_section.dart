import 'package:flutter/material.dart';
import '/theme/glassmorphic_card.dart';
import '../preferences/preference_utils.dart';

class PreferenceSection extends StatelessWidget {
  final String? gender, cookingTime, spiceLevel;
  final List<String> allergies, diets, cuisines, barriers;
  final Function(String, dynamic, {bool isMulti}) onUpdatePref;

  const PreferenceSection({
    super.key,
    required this.gender,
    required this.cookingTime,
    required this.spiceLevel,
    required this.allergies,
    required this.diets,
    required this.cuisines,
    required this.barriers,
    required this.onUpdatePref,
  });

  // Map a List<String> to List<PreferenceOption>
  List<PreferenceOption> mapLabelsToOptions(List<PreferenceOption> options, List<dynamic> labels) {
    return labels
        .where((label) => options.any((o) => o.label == label))
        .map((label) => options.firstWhere((o) => o.label == label))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: GlassmorphicCard(
        borderRadius: 30,
        blur: 15,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Preferences", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            AnimatedPreferenceTile<PreferenceOption>(
              title: "Gender",
              value: PreferenceUtils.genders.firstWhere(
                (opt) => opt.label == (gender ?? ""),
                orElse: () => PreferenceUtils.genders.first,
              ),
              options: PreferenceUtils.genders,
              multiSelect: false,
              onChanged: (newVal) => onUpdatePref(PreferenceKeys.gender, newVal.label),
            ),
            AnimatedPreferenceTile<PreferenceOption>(
              title: "Cooking Time",
              value: PreferenceUtils.cookingTimes.firstWhere(
                (opt) => opt.label == (cookingTime ?? ""),
                orElse: () => PreferenceUtils.cookingTimes.first,
              ),
              options: PreferenceUtils.cookingTimes,
              multiSelect: false,
              onChanged: (newVal) => onUpdatePref(PreferenceKeys.cookingTime, newVal.label),
            ),
            AnimatedPreferenceTile<PreferenceOption>(
              title: "Allergies / Intolerances",
              value: mapLabelsToOptions(PreferenceUtils.allergies, allergies),
              options: PreferenceUtils.allergies,
              multiSelect: true,
              onChanged: (newVals) => onUpdatePref(PreferenceKeys.allergies, newVals, isMulti: true),
            ),
            AnimatedPreferenceTile<PreferenceOption>(
              title: "Diet Preferences",
              value: mapLabelsToOptions(PreferenceUtils.diets, diets),
              options: PreferenceUtils.diets,
              multiSelect: true,
              onChanged: (newVals) => onUpdatePref(PreferenceKeys.diets, newVals, isMulti: true),
            ),
            AnimatedPreferenceTile<PreferenceOption>(
              title: "Cuisines Loved",
              value: mapLabelsToOptions(PreferenceUtils.cuisines, cuisines),
              options: PreferenceUtils.cuisines,
              multiSelect: true,
              onChanged: (newVals) => onUpdatePref(PreferenceKeys.cuisines, newVals, isMulti: true),
            ),
            AnimatedPreferenceTile<PreferenceOption>(
              title: "Spice Level",
              value: PreferenceUtils.spiceLevels.firstWhere(
                (opt) => opt.label == (spiceLevel ?? ""),
                orElse: () => PreferenceUtils.spiceLevels.first,
              ),
              options: PreferenceUtils.spiceLevels,
              multiSelect: false,
              onChanged: (newVal) => onUpdatePref(PreferenceKeys.spiceLevel, newVal.label),
            ),
            AnimatedPreferenceTile<PreferenceOption>(
              title: "Barriers",
              value: mapLabelsToOptions(PreferenceUtils.barriers, barriers),
              options: PreferenceUtils.barriers,
              multiSelect: true,
              onChanged: (newVals) => onUpdatePref(PreferenceKeys.barriers, newVals, isMulti: true),
            ),
          ],
        ),
      ),
    );
  }
}


// ---------- Below: Improved AnimatedPreferenceTile & Modal ---------

class AnimatedPreferenceTile<T extends PreferenceOption> extends StatelessWidget {
  final String title;
  final dynamic value; // T or List<T>
  final List<T> options;
  final bool multiSelect;
  final Future<void> Function(dynamic newValue) onChanged;

  const AnimatedPreferenceTile({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.multiSelect,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Display for multi: up to 3 chips, then "+n more"
    Widget multiDisplay() {
      final vals = value as List<T>;
      if (vals.isEmpty) {
        return Center(child: Chip(label: Text("None")));
      }
      final maxShow = 3;
      List<Widget> chips = vals
          .take(maxShow)
          .map((v) => Chip(
              label: Text(
                "${v.emoji} ${v.label}",
                style: TextStyle(color: theme.colorScheme.primary),
              )))
          .toList();
      if (vals.length > maxShow) {
        chips.add(Chip(
            label: Text("+${vals.length - maxShow} more",
                style: TextStyle(color: theme.colorScheme.primary))));
      }
      return Center(
        child: Wrap(
          spacing: 5,
          alignment: WrapAlignment.center,
          children: chips,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: theme.colorScheme.primary.withOpacity(0.045),
        title: Text(title, style: theme.textTheme.bodyLarge),
        subtitle: multiSelect
            ? multiDisplay()
            : value != null
                ? Center(
                    child: Text(
                      "${value.emoji} ${value.label}",
                      style: theme.textTheme.titleMedium,
                    ),
                  )
                : const Center(child: Text("None")),
        trailing: Icon(Icons.edit, color: theme.colorScheme.primary),
        onTap: () async {
          final result = await showModalBottomSheet(
            context: context,
            backgroundColor: theme.scaffoldBackgroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            isScrollControlled: true,
            builder: (ctx) => PreferenceEditModal<T>(
              title: title,
              options: options,
              currentValue: value,
              multiSelect: multiSelect,
            ),
          );
          if (result != null) {
            await onChanged(result);
          }
        },
      ),
    );
  }
}

class PreferenceEditModal<T extends PreferenceOption> extends StatefulWidget {
  final String title;
  final List<T> options;
  final dynamic currentValue; // T or List<T>
  final bool multiSelect;

  const PreferenceEditModal({
    super.key,
    required this.title,
    required this.options,
    required this.currentValue,
    required this.multiSelect,
  });

  @override
  State<PreferenceEditModal<T>> createState() => _PreferenceEditModalState<T>();
}

class _PreferenceEditModalState<T extends PreferenceOption>
    extends State<PreferenceEditModal<T>>
    with SingleTickerProviderStateMixin {
  late List<T> selectedValues;
  late List<T> initialValues;

  @override
  void initState() {
    super.initState();
    if (widget.multiSelect) {
      selectedValues = List<T>.from(widget.currentValue ?? []);
      initialValues = List<T>.from(widget.currentValue ?? []);
    } else {
      selectedValues = [widget.currentValue as T? ?? widget.options.first];
      initialValues = [widget.currentValue as T? ?? widget.options.first];
    }
  }

  bool get hasChanged {
    if (widget.multiSelect) {
      return !(selectedValues.length == initialValues.length &&
          selectedValues.every((element) => initialValues.contains(element)));
    } else {
      return selectedValues.first != initialValues.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 22),
          if (widget.multiSelect)
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: widget.options.map((option) {
                  final selected = selectedValues.contains(option);
                  return FilterChip(
                    label: Text("${option.emoji} ${option.label}"),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (selected) {
                          selectedValues.remove(option);
                        } else {
                          selectedValues.add(option);
                        }
                      });
                    },
                    showCheckmark: true,
                    checkmarkColor: theme.colorScheme.primary,
                    selectedColor: theme.colorScheme.primary.withOpacity(0.20),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                    labelStyle: TextStyle(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  );
                }).toList(),
              ),
            )
          else
            Center(
              child: Column(
                children: widget.options.map((option) {
                  return RadioListTile<T>(
                    value: option,
                    groupValue: selectedValues.first,
                    onChanged: (val) {
                      setState(() => selectedValues = [val!]);
                    },
                    activeColor: theme.colorScheme.primary,
                    title: Text("${option.emoji} ${option.label}"),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text(
                      "Save",
                      style: TextStyle(color: Colors.black),
                    ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasChanged
                        ? Colors.green
                        : theme.disabledColor,
                  ),
                  onPressed: hasChanged
                      ? () => Navigator.of(context).pop(widget.multiSelect
                          ? selectedValues
                          : selectedValues.first)
                      : null,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

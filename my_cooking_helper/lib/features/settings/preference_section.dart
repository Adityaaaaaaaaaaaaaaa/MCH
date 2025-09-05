import 'package:flutter/material.dart';
import 'package:glass/glass.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/preference_utils.dart';

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
      padding: EdgeInsets.symmetric(horizontal: 22.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text(
              "Your Preferences", 
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 20.sp,
              )
            )),
            SizedBox(height: 20.h),
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
              title: "Allergies",
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
      )
      .asGlass(
        blurX: 20,
        blurY: 20,
        tintColor: Colors.blueGrey,
        clipBorderRadius: BorderRadius.circular(20.r),
        frosted: true,
      ),
    );
  }
}

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

    Widget multiDisplay() {
      final vals = value as List<T>;
      if (vals.isEmpty) {
        return Center(child: Chip(label: Text("None")));
      }
      final maxShow = 3;
      List<Widget> chips = vals
          .take(maxShow)
          .map((v) => Chip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SmartPreferenceEmojiRow(option: v, size: 18),
                SizedBox(width: 6),
                Text(v.label),
              ],
            )
          )).toList();
      if (vals.length > maxShow) {
        chips.add(Chip(
            label: Text("+${vals.length - maxShow} more",
                style: TextStyle(color: theme.colorScheme.primary))));
      }
      return Center(
        child: Wrap(
          spacing: 5.w,
          alignment: WrapAlignment.center,
          children: chips,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
            color: Colors.grey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: ListTile(
          tileColor: theme.colorScheme.primary.withOpacity(0.045),
          title: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 20.sp,
                ),
              ),
            ),
          ),
          subtitle: multiSelect
            ? multiDisplay()
            : value != null
                ? Center(
                    child: Row(
                      children: [
                        SmartPreferenceEmojiRow(option: value, size: 20),
                        SizedBox(width: 8),
                          Flexible(
                          child: Center(
                            child: Text(
                              value.label,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 14.sp, // apperance on screen before modal
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(child: Text("None")),
          trailing: Icon(Icons.edit, color: theme.colorScheme.primary),
          onTap: () async {
            final result = await showModalBottomSheet(
              context: context,
              backgroundColor: theme.scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
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
        ).asGlass(
          blurX: 15,
          blurY: 15,
          tintColor: Colors.blueAccent,
          clipBorderRadius: BorderRadius.circular(20.r),
          frosted: true,
        ),
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
        left: 20.w, right: 20.w, top: 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 22.h),
          if (widget.multiSelect)
            Center(
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                alignment: WrapAlignment.center,
                children: widget.options.map((option) {
                  final selected = selectedValues.contains(option);
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SmartPreferenceEmojiRow(option: option, size: 16),
                        SizedBox(width: 6),
                        Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14.sp), // multi selects
                        ),
                      ],
                    ),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        final bool hasExclusiveNone = widget.options.any((o) => o.label == 'None');
                        final bool isNone = option.label == 'None';

                        if (hasExclusiveNone) {
                          if (isNone) {
                            // "None" is exclusive: clear others and keep only "None"
                            selectedValues
                              ..clear()
                              ..add(option);
                          } else {
                            // Selecting a non-"None": remove "None" if present, then toggle normally
                            selectedValues.removeWhere((o) => o.label == 'None');
                            if (selected) {
                              selectedValues.remove(option);
                            } else {
                              if (!selectedValues.contains(option)) selectedValues.add(option);
                            }
                          }
                        } else {
                          // Generic multi-select (no "None" in this group)
                          if (selected) {
                            selectedValues.remove(option);
                          } else {
                            if (!selectedValues.contains(option)) selectedValues.add(option);
                          }
                        }
                      });
                    },
                    showCheckmark: true,
                    checkmarkColor: Colors.green,
                    selectedColor: Colors.green.shade100,
                    backgroundColor: Colors.grey.shade200,
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
                    activeColor: Colors.green,
                    groupValue: selectedValues.first,
                    onChanged: (val) {
                      setState(() => selectedValues = [val!]);
                    },
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        //single selects
                        SmartPreferenceEmojiRow(option: option, size: 16),
                        SizedBox(width: 8),
                        Text(
                          option.label, 
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(width: 12.w),
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

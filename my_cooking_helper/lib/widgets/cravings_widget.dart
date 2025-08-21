// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';

/// Clean glass search bar (no buttons)
class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const GlassSearchBar({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28.r)),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.white70),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "e.g., spicy cheesy pasta under 20 min",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    ).asGlass(
      tintColor: Colors.white,
      clipBorderRadius: BorderRadius.circular(28.r),
      blurX: 24,
      blurY: 24,
      frosted: true,
    );
  }
}

/// Separate action buttons row
class CravingsActions extends StatelessWidget {
  final VoidCallback onOpenFilters;
  final VoidCallback onGenerate;

  const CravingsActions({
    super.key,
    required this.onOpenFilters,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: onOpenFilters,
          icon: const Icon(Icons.tune_rounded),
          label: const Text("Filters"),
        ),
        SizedBox(width: 14.w),
        ElevatedButton.icon(
          onPressed: onGenerate,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text("Generate"),
        ),
      ],
    );
  }
}

/// Glass caution banner (below buttons)
class CautionBannerGlass extends StatelessWidget {
  const CautionBannerGlass({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16.r)),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.amber),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              "AI-generated results. Please review for accuracy and food safety.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    ).asGlass(
      tintColor: Colors.white,
      clipBorderRadius: BorderRadius.circular(16.r),
      blurX: 20,
      blurY: 20,
      frosted: true,
    );
  }
}

/// Filters sheet with chilli meter + time slider
class CravingsFiltersSheet extends StatelessWidget {
  final int spiceLevel; // default (from Firestore)
  final int maxTime;    // default (from Firestore)
  final ValueChanged<int> onSpiceChanged;
  final ValueChanged<int> onTimeChanged;
  final VoidCallback onApply;

  const CravingsFiltersSheet({
    super.key,
    required this.spiceLevel,
    required this.maxTime,
    required this.onSpiceChanged,
    required this.onTimeChanged,
    required this.onApply,
  });

  static const List<String> _spiceLabels = [
    'No Spice (Plain Jane)',   // 0
    'Gentle Warmth (Mild)',    // 1
    'Balanced Kick (Medium)',  // 2
    'Bring the Heat (Spicy)',  // 3
    'RIP (Super Spicy!)',      // 4
    'Mystery Heat (Surprise me!)', // 5
    "Spice? I'm Open!",        // 5
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h + MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          gradient: LinearGradient(
            colors: [Colors.deepOrangeAccent.withOpacity(0.9), Colors.redAccent.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✨ Craving Filters', style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 16.h),

            Align(
              alignment: Alignment.centerLeft,
              child: Text('Spice Level', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white)),
            ),
            SizedBox(height: 8.h),
            ChilliMeter(value: spiceLevel, onChanged: onSpiceChanged),
            SizedBox(height: 6.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _spiceLabels[spiceLevel],
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ),

            SizedBox(height: 20.h),

            Align(
              alignment: Alignment.centerLeft,
              child: Text('Max Cook Time', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white)),
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: maxTime.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '$maxTime min',
                    activeColor: Colors.white,
                    inactiveColor: Colors.white54,
                    onChanged: (v) => onTimeChanged(v.round()),
                  ),
                ),
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.white.withOpacity(0.25),
                  ),
                  child: Text('$maxTime min',
                      style: theme.textTheme.labelMedium?.copyWith(color: Colors.white)),
                ),
              ],
            ),

            SizedBox(height: 18.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Close'),
                ),
                SizedBox(width: 10.w),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.redAccent),
                  onPressed: onApply,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 0..5 tappable chilli emojis 🌶️
class ChilliMeter extends StatelessWidget {
  final int value; // 0..5
  final ValueChanged<int> onChanged;
  const ChilliMeter({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      children: List.generate(6, (i) {
        final isActive = i <= value;
        return GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: isActive ? 1.0 : 0.35,
            child: Text("🌶️", style: TextStyle(fontSize: 28.sp)),
          ),
        );
      }),
    );
  }
}

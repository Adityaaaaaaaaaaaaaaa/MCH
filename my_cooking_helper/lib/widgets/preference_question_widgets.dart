import 'package:flutter/material.dart';
import '/utils/preference_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title at top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 35.h),

          // Expanded scrollable options area
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: options.map((opt) {
                  final selected = value == opt.label;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.0.h),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 40.h,
                      width: 300.w,
                      decoration: BoxDecoration(
                        color: selected ? Colors.blueAccent : Colors.white,
                        borderRadius: BorderRadius.circular(17.r),
                        border: Border.all(
                          color: selected ? Colors.blueAccent : Colors.grey,
                          width: 2.0.w,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.12), blurRadius: 8, offset: Offset(0, 2))]
                            : [],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22.r),
                        onTap: () => onChanged(opt.label),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SmartPreferenceEmojiRow(option: opt, size: 24, repeat: true,), 
                              SizedBox(width: 8.w),
                              Text(
                                opt.label,
                                style: TextStyle(
                                  color: selected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Footer: action buttons pinned at the bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (onBack != null)
                ElevatedButton(
                  onPressed: onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    minimumSize: Size(80.w, 40.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text("Back", style: TextStyle(fontSize: 18.sp, color: Colors.black87)),
                ),
              ElevatedButton(
                onPressed: value != null ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: Size(80.w, 40.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text("Next", style: TextStyle(fontSize: 18.sp, color: Colors.white)),
              ),
            ],
          ),
          SizedBox(height: 18.h),
        ],
      ),
    );
  }
}

class AnimatedMultiSelectSmall extends StatelessWidget {
  final String title;
  final List<PreferenceOption> options;
  final List<String> values; // keep as-is to avoid breaking callers
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 25.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20.h),

          // Expanded scrollable options area (wrap for chips)
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10.w,
                  runSpacing: 10.h,
                  children: options.map((opt) {
                    final selected = values.contains(opt.label);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        color: selected ? Colors.blueAccent : Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: selected ? Colors.blueAccent : Colors.grey,
                          width: 2.0.w,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14.r),
                        onTap: () {
                          // --- SINGLE-SELECT LOGIC ---
                          if (selected) {
                            // tapping the selected chip -> deselect all
                            onChanged(<String>[]);
                          } else {
                            // tapping a new chip -> replace any existing selection
                            onChanged(<String>[opt.label]);
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SmartPreferenceEmojiRow(option: opt, size: 24, repeat: true),
                              SizedBox(width: 8.w),
                              Text(
                                opt.label,
                                style: TextStyle(
                                  color: selected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Footer: action buttons pinned at the bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (onBack != null)
                ElevatedButton(
                  onPressed: onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    minimumSize: Size(80.w, 40.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text("Back", style: TextStyle(fontSize: 18.sp, color: Colors.black87)),
                ),
              ElevatedButton(
                onPressed: values.isNotEmpty ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: Size(80.w, 40.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text("Next", style: TextStyle(fontSize: 18.sp, color: Colors.white)),
              ),
            ],
          ),
          SizedBox(height: 18.h),
        ],
      ),
    );
  }
}

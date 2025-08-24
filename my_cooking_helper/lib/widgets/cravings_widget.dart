// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import '/utils/colors.dart';
import 'dart:typed_data';
import '/models/cravings.dart';
import '/utils/image_data_url.dart';

/// Clean glass search bar (no buttons)
class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String? hintText;
  final bool isLoading;

  const GlassSearchBar({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.hintText,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Stack(
        children: [
          // Subtle glow effect
          Container(
            width: double.infinity,
            height: 52.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.08),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          // Main glass container
          Container(
            width: double.infinity,
            height: 52.h,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Search icon
                Icon(
                  Icons.search_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 22.sp,
                ),
                SizedBox(width: 14.w),
                // Text field
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSubmit(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    cursorColor: Colors.white.withOpacity(0.8),
                    decoration: InputDecoration(
                      hintText: hintText ?? "Search your cravings or guilty pleasures ...",
                      hintStyle: TextStyle(
                        color: textColor(context),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w300,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                // Loading indicator or search action
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.7),
                            ),
                          ),
                        )
                      : controller.text.isNotEmpty
                          ? GestureDetector(
                              onTap: onSubmit,
                              child: Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.r),
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 16.sp,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ).asGlass(
            tintColor: Colors.white.withOpacity(0.04),
            clipBorderRadius: BorderRadius.circular(26.r),
            blurX: 28,
            blurY: 28,
            frosted: true,
          ),
        ],
      ),
    );
  }
}

/// Separate action buttons row
class CravingsActions extends StatefulWidget {
  final VoidCallback onOpenFilters;
  final VoidCallback onGenerate;
  final bool isGenerating;

  const CravingsActions({
    super.key,
    required this.onOpenFilters,
    required this.onGenerate,
    this.isGenerating = false,
  });

  @override
  State<CravingsActions> createState() => _CravingsActionsState();
}

class _CravingsActionsState extends State<CravingsActions>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main gradient animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    // Pulse animation for AI effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // Filter Button - Clean Glass Style
          Expanded(
            flex: 2,
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onOpenFilters,
                  borderRadius: BorderRadius.circular(24.r),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: textColor(context),
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "Filters",
                          style: TextStyle(
                            color: textColor(context),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).asGlass(
              tintColor: Colors.white.withOpacity(0.05),
              clipBorderRadius: BorderRadius.circular(24.r),
              blurX: 20,
              blurY: 20,
              frosted: true,
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Generate Button - Animated AI Style
          Expanded(
            flex: 3,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isGenerating ? _pulseAnimation.value : 1.0,
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4285F4).withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.r),
                            gradient: SweepGradient(
                              center: Alignment.center,
                              startAngle: _rotationAnimation.value * 2 * 3.14159,
                              colors: const [
                                Color(0xFF4285F4), // Google Blue
                                Color(0xFFDB4437), // Google Red
                                Color(0xFFF4B400), // Google Yellow
                                Color(0xFF0F9D58), // Google Green
                                Color(0xFF4285F4), // Back to Blue
                              ],
                              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                            ),
                          ),
                          child: Container(
                            margin: EdgeInsets.all(1.5.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22.5.r),
                              color: Colors.black.withOpacity(0.8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.isGenerating ? null : widget.onGenerate,
                                borderRadius: BorderRadius.circular(22.5.r),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22.5.r),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        child: widget.isGenerating
                                            ? SizedBox(
                                                width: 18.w,
                                                height: 18.h,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Colors.white.withOpacity(0.9),
                                                  ),
                                                ),
                                              )
                                            : Icon(
                                                Icons.auto_awesome_rounded,
                                                color: Colors.white.withOpacity(0.95),
                                                size: 18.sp,
                                              ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        widget.isGenerating ? "Generating..." : "Generate AI",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.95),
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Stack(
        children: [
          // Subtle glow effect behind the glass
          Container(
            width: double.infinity,
            height: 60.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          // Main glass container
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated warning icon with gradient
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withOpacity(0.3),
                        Colors.orange.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Colors.amber.shade300,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "AI Generated",
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.orange.shade500,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "Please review for accuracy and food safety",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor(context).withOpacity(0.6),
                          fontSize: 13.sp,
                          height: 1.2,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Optional dismiss button or accent
                Container(
                  width: 4.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.r),
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withOpacity(0.6),
                        Colors.amber.withOpacity(0.2),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ).asGlass(
            tintColor: Colors.white.withOpacity(0.05),
            clipBorderRadius: BorderRadius.circular(20.r),
            blurX: 25,
            blurY: 25,
            frosted: true,
          ),
        ],
      ),
    );
  }
}

class CravingsFiltersSheet extends StatelessWidget {
  final int spiceLevel;         // 0..4 (ignored if randomEnabled)
  final bool randomEnabled;
  final int timeMinutes;        // total minutes

  final ValueChanged<int> onSpiceChanged;
  final ValueChanged<bool> onRandomChanged;
  final ValueChanged<int> onTimeChanged;
  final VoidCallback onApply;

  const CravingsFiltersSheet({
    super.key,
    required this.spiceLevel,
    required this.randomEnabled,
    required this.timeMinutes,
    required this.onSpiceChanged,
    required this.onRandomChanged,
    required this.onTimeChanged,
    required this.onApply,
  });

  static const int _kMaxMinutes = 240; // 4h cap
  static const List<String> _spiceLabels = [
    'No Spice (Plain Jane)',   // 0
    'Gentle Warmth (Mild)',    // 1
    'Balanced Kick (Medium)',  // 2
    'Bring the Heat (Spicy)',  // 3
    'RIP (Super Spicy!)',      // 4
    'Mystery Heat (Surprise me!) / Open', // 5 (random)
  ];

  String _fmtDuration(int minutes) {
    final m = minutes.clamp(0, _kMaxMinutes);
    final h = m ~/ 60, mm = m % 60;
    if (h == 0) return '${mm}m';
    if (mm == 0) return '${h}h';
    return '${h}h ${mm}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use a StatefulBuilder to sync chips -> picker and vice‑versa.
    return StatefulBuilder(
      builder: (ctx, setModalState) {
        final clamped = timeMinutes.clamp(0, _kMaxMinutes);
        final quick = <int>[15, 30, 45, 60, 90, 120];

        // When chips/picker change, update both UI + parent via callback.
        void _setTime(int mins) {
          final v = mins.clamp(0, _kMaxMinutes);
          setModalState(() {});     // rebuild this sheet
          onTimeChanged(v);         // inform parent (you’re already logging blue debug)
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h + MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              gradient: LinearGradient(
                colors: [Colors.deepOrangeAccent.withOpacity(0.95), Colors.redAccent.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                  child: Row(
                    children: [
                      Text('✨ Craving Filters',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Body (glass)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24.r),
                      bottomRight: Radius.circular(24.r),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------- Spice ------------
                      Text('Spice level', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white)),
                      SizedBox(height: 10.h),

                      // Chilli row (disabled when random is on)
                      Opacity(
                        opacity: randomEnabled ? 0.35 : 1.0,
                        child: IgnorePointer(
                          ignoring: randomEnabled,
                          child: Center(
                            child: ChilliMeter5(
                              value: spiceLevel,
                              onChanged: (v) {
                                onSpiceChanged(v);
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Selected label badge (glass)
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🌶️', style: TextStyle(fontSize: 16.sp)),
                              SizedBox(width: 6.w),
                              Text(
                                randomEnabled ? _spiceLabels[5] : _spiceLabels[spiceLevel],
                                style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ).asGlass(
                          tintColor: Colors.white,
                          clipBorderRadius: BorderRadius.circular(999),
                          blurX: 18,
                          blurY: 18,
                          frosted: true,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // Random pill (moved here, less eye‑catching) — glass style
                      Align(
                        alignment: Alignment.center,
                        child: _RandomPill(
                          enabled: randomEnabled,
                          onChanged: (on) => onRandomChanged(on),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // -------- Time ------------
                      Text('Max cook time', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white)),
                      SizedBox(height: 8.h),

                      // Centered quick select pills
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            for (final m in quick)
                              ChoiceChip(
                                label: Text(_fmtDuration(m)),
                                selected: clamped == m,
                                onSelected: (_) => _setTime(m), // sync chips -> picker
                                selectedColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: clamped == m ? Colors.redAccent : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor: Colors.white.withOpacity(0.20),
                                shape: StadiumBorder(
                                  side: BorderSide(color: Colors.white.withOpacity(0.35)),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // Timer picker (hours + minutes), clamped to 0..4h
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          color: Colors.white.withOpacity(0.15),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 150.h,
                              // Key forces recreation so the picker jumps to chip selection immediately
                              child: CupertinoTimerPicker(
                                key: ValueKey(clamped),
                                mode: CupertinoTimerPickerMode.hm,
                                minuteInterval: 5,
                                initialTimerDuration: Duration(minutes: clamped),
                                onTimerDurationChanged: (dur) {
                                  final mins = dur.inMinutes.clamp(0, _kMaxMinutes);
                                  _setTime(mins); // sync picker -> chips
                                },
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              'Selected: ${_fmtDuration(clamped)}  •  limit: up to 4h',
                              style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
                            ),
                            SizedBox(height: 6.h),
                          ],
                        ),
                      ).asGlass(
                        tintColor: Colors.blue,
                        clipBorderRadius: BorderRadius.circular(16.r),
                        blurX: 18,
                        blurY: 18,
                        frosted: true,
                      ),

                      SizedBox(height: 18.h),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Close'),
                          ),
                          SizedBox(width: 10.w),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.redAccent,
                            ),
                            onPressed: onApply,
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Apply'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ).asGlass(
              tintColor: Colors.blueGrey,
              clipBorderRadius: BorderRadius.all(Radius.circular(24.r)),
              blurX: 10,
              blurY: 10,
              frosted: true,
            ),
          ),
        );
      },
    );
  }
}

/// 5 tappable chilli emojis 🌶️ for fixed levels 0..4
class ChilliMeter5 extends StatelessWidget {
  final int value; // 0..4
  final ValueChanged<int> onChanged;
  const ChilliMeter5({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.w,
      children: List.generate(5, (i) {
        // grey(0) -> deep red(4)
        final color = Color.lerp(Colors.grey, Colors.redAccent, i / 4)!;
        final isActive = i <= value;
        return GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            transform: Matrix4.identity()..scale(isActive ? 1.08 : 1.0),
            child: Opacity(
              opacity: isActive ? 1.0 : 0.45,
              child: Text(
                "🌶️",
                style: TextStyle(
                  fontSize: 30.sp,
                  color: color,
                  shadows: isActive
                      ? [Shadow(color: color.withOpacity(0.6), blurRadius: 8)]
                      : const [],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Glassy random spice pill toggle (less eye‑catching, centered under chilli)
class _RandomPill extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _RandomPill({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(!enabled),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
            color: enabled ? Colors.white : Colors.white.withOpacity(0.18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎲', style: TextStyle(fontSize: 14.sp)),
              SizedBox(width: 6.w),
              Text(
                enabled ? 'Random spice: ON' : 'Random spice: OFF',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: enabled ? Colors.redAccent : Colors.white,
                ),
              ),
            ],
          ),
        ).asGlass(
          tintColor: Colors.white,
          clipBorderRadius: BorderRadius.circular(999),
          blurX: 16,
          blurY: 16,
          frosted: true,
        ),
      ),
    );
  }
}

// /widgets/cravings_results.dart
class CravingsResultsGrid extends StatelessWidget {
  const CravingsResultsGrid({
    super.key,
    required this.items,
    this.onTap,
  });

  final List<CravingRecipeModel> items;
  final void Function(CravingRecipeModel item)? onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final wide = ScreenUtil().screenWidth > 600;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 3 : 1,
        mainAxisSpacing: 14.h,
        crossAxisSpacing: 14.w,
        // tuned so 16:9 image + text fits neatly on both phone/tablet
        childAspectRatio: wide ? 0.72 : 1.30,
      ),
      itemBuilder: (_, i) => _CravingsCard(
        item: items[i],
        onTap: onTap,
      ),
    );
  }
}

class _CravingsCard extends StatelessWidget {
  const _CravingsCard({required this.item, this.onTap});

  final CravingRecipeModel item;
  final void Function(CravingRecipeModel item)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // IMAGE: decode data URL safely; show placeholder if null/bad
    final Uint8List? bytes = decodeDataUrl(item.imageDataUrl);
    final Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: (bytes != null)
          ? Image.memory(bytes, fit: BoxFit.cover)
          : Container(
              color: theme.colorScheme.surface.withOpacity(0.10),
              alignment: Alignment.center,
              child: Icon(Icons.image_outlined,
                  size: 48, color: Colors.white.withOpacity(0.35)),
            ),
    );

    return InkWell(
      onTap: onTap == null ? null : () => onTap!(item),
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        padding: EdgeInsets.all(10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // fixed aspect so cards are consistent, avoids overflow surprises
            AspectRatio(
              aspectRatio: 16 / 9,
              child: image,
            ),
            SizedBox(height: 10.h),

            // TITLE
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),

            // META ROW
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16),
                SizedBox(width: 6.w),
                Text('${item.readyInMinutes ?? 0} min',
                    style: theme.textTheme.bodySmall),
                const Spacer(),
                const Icon(Icons.shopping_cart_outlined, size: 16),
                SizedBox(width: 6.w),
                Text('${item.shopping.length}',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

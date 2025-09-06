// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import '/utils/image_data_url.dart';
import '/utils/colors.dart';
import '/models/cravings.dart';

/// Clean glass search bar (no buttons)
class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String? hintText;
  final bool isLoading;

  /// NEW: called when the clear (×) button is tapped.
  /// Use it to reset your screen to State B (loading).
  final VoidCallback? onClear;

  const GlassSearchBar({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.hintText,
    this.isLoading = false,
    this.onClear, // 👈 new
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Stack(
            children: [
              // Subtle glow
              Container(
                width: double.infinity,
                height: 52.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),

              // Main glass container
              Container(
                width: double.infinity,
                height: 52.h,
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26.r),
                  border: Border.all(
                    color: isDark? Colors.deepOrange.withOpacity(0.7) : Colors.orange.withOpacity(0.9),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Search icon
                    Icon(Icons.search_rounded, color: textColor(context), size: 22.sp),
                    SizedBox(width: 10.w),

                    // Text field
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) {
                          if (!hasText) return; // prevent empty submit
                          onSubmit();
                        },
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: textColor(context),
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

                    // Forward button (disabled when empty)
                    IgnorePointer(
                      ignoring: !hasText,
                      child: GestureDetector(
                        onTap: () {
                          if (!hasText) return;
                          onSubmit();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.r),
                            color: hasText
                                ? textColor(context).withOpacity(0.18)
                                : textColor(context).withOpacity(0.08),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: hasText ? Colors.blue : textColor(context).withOpacity(0.3),
                            size: 16.sp,
                          ),
                        ),
                      ),
                    ),

                    // Small gap then the CLEAR (×) button — only when there's text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: hasText
                          ? Padding(
                              padding: EdgeInsets.only(left: 8.w),
                              child: GestureDetector(
                                onTap: () {
                                  controller.clear();
                                  FocusScope.of(context).unfocus();
                                  onClear?.call(); // tell parent to go to State B
                                },
                                child: Container(
                                  key: const ValueKey('clear'),
                                  padding: EdgeInsets.all(6.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.r),
                                    color: textColor(context).withOpacity(0.18),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: isDark? Colors.deepOrangeAccent :Colors.red,
                                    size: 16.sp,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox(key: ValueKey('no-clear'), width: 0, height: 0),
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
      },
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

  void _showInfoModal(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w),
          child: Stack(
            children: [
              // Main modal content
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                  border: Border.all(
                    color: isDark 
                      ? const Color(0xFF4A5568).withOpacity(0.5) 
                      : const Color(0xFFE2E8F0).withOpacity(0.8),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(top: 12.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2.r),
                        color: const Color(0xFF94A3B8).withOpacity(0.6),
                      ),
                    ),
                    
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(14.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18.r),
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFFBBF24).withOpacity(0.15),
                                        const Color(0xFFF59E0B).withOpacity(0.1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFFBBF24).withOpacity(0.3),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    color: const Color(0xFFF59E0B),
                                    size: 26.sp,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Gemini Recipe Assistant",
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          color: const Color(0xFFF59E0B),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 22.sp,
                                          height: 1.2,
                                        ),
                                      ),
                                      Text(
                                        "AI-Powered Cooking Guide",
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: textColor(context),
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16.r),
                                      color: const Color(0xFF64748B).withOpacity(0.1),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 20.sp,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 28.h),
                            
                            // Safety Warning
                            _buildInfoCard(
                              context,
                              "🛡️",
                              "Safety First",
                              "Always verify AI-generated recipes for accuracy. Double-check cooking temperatures, times, and ingredient compatibility. Be especially careful with food allergies and dietary restrictions.",
                              const Color(0xFFEF4444),
                              isDark,
                            ),
                            
                            SizedBox(height: 16.h),
                            
                            // Pro Tips
                            _buildInfoCard(
                              context,
                              "💡",
                              "Pro Tips for Better Results",
                              "• Be specific: \"Gluten-free pasta for 4 people, 30 minutes\"\n"
                              "• Mention your skill level: \"Beginner-friendly\" or \"Advanced\"\n"
                              "• Include equipment: \"No oven\" or \"One-pot meal\"\n"
                              "• State preferences: \"Low sodium\" or \"Kid-friendly\"\n"
                              "• Ask for substitutions: \"Replace dairy with alternatives\"",
                              const Color(0xFF3B82F6),
                              isDark,
                            ),
                            
                            SizedBox(height: 16.h),
                            
                            // Smart Prompts
                            _buildInfoCard(
                              context,
                              "✨",
                              "Smart Prompt Examples",
                              "• \"Quick 20-minute dinner with chicken breast and vegetables\"\n"
                              "• \"Vegan dessert using coconut milk, serves 6 people\"\n"
                              "• \"High-protein breakfast for muscle building, no eggs\"\n"
                              "• \"Keto-friendly lunch under 500 calories with salmon\"\n"
                              "• \"Comfort food for cold weather, easy to make ahead\"",
                              const Color(0xFF10B981),
                              isDark,
                            ),
                            
                            SizedBox(height: 16.h),
                            
                            // Cooking Wisdom
                            _buildInfoCard(
                              context,
                              "👨‍🍳",
                              "Cooking Wisdom",
                              "• Always taste and adjust seasonings gradually\n"
                              "• Check doneness with thermometer for meat dishes\n"
                              "• Prep all ingredients before you start cooking\n"
                              "• Start with less spice - you can always add more\n"
                              "• When in doubt, cook low and slow",
                              const Color(0xFF8B5CF6),
                              isDark,
                            ),
                            
                            SizedBox(height: 24.h),
                            
                            // Action button
                            Container(
                              width: double.infinity,
                              height: 52.h,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF59E0B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 20.sp),
                                    SizedBox(width: 8.w),
                                    Text(
                                      "Got it, let's cook!",
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).asGlass(
                tintColor: isDark 
                  ? const Color(0xFF1E293B).withOpacity(0.95) 
                  : const Color(0xFFFAFAFA).withOpacity(0.95),
                clipBorderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                blurX: 20,
                blurY: 20,
                frosted: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String emoji, String title, 
      String content, Color accentColor, bool isDark) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: accentColor.withOpacity(0.05),
        border: Border.all(
          color: isDark ? accentColor.withOpacity(0.5) : accentColor.withOpacity(0.7),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: TextStyle(fontSize: 20.sp),
              ),
              SizedBox(width: 10.w),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark ? accentColor : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor(context),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Stack(
        children: [
          // Optimized glow effect
          Container(
            width: double.infinity,
            height: 56.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withOpacity(0.12),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          // Main banner container
          Container(
            width: double.infinity,
            height: 56.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Enhanced AI icon
                Container(
                  width: 32.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFBBF24).withOpacity(0.2),
                        const Color(0xFFF59E0B).withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFFFBBF24).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 18.sp,
                  ),
                ),
                
                SizedBox(width: 12.w),
                
                // Improved text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Gemini AI Recipe",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        "Verify for safety & accuracy",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor(context),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Interactive info button with better feedback
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showInfoModal(context),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: 32.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF3B82F6).withOpacity(0.15),
                            const Color(0xFF1D4ED8).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: const Color(0xFF3B82F6),
                        size: 16.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).asGlass(
            tintColor: isDark
              ? const Color(0xFFF59E0B).withOpacity(0.1) 
              : const Color(0xFFFEF3C7).withOpacity(0.7),
            clipBorderRadius: BorderRadius.circular(20.r),
            blurX: 15,
            blurY: 15,
            frosted: false,
          ),
        ],
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////
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
    final isDark = theme.brightness == Brightness.dark;

    return StatefulBuilder(
      builder: (ctx, setModalState) {
        final clamped = timeMinutes.clamp(0, _kMaxMinutes);
        final quick = <int>[15, 30, 45, 60, 90, 120];

        void _setTime(int mins) {
          final v = mins.clamp(0, _kMaxMinutes);
          setModalState(() {});
          onTimeChanged(v);
        }

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h + MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 16.w, 12.h),
                    child: Row(
                      children: [
                        Text(
                          '🎯 Craving Filters',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    height: 1,
                  ),

                  // Body
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Spice Level Section
                        Text(
                          'Spice level',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isDark ? Colors.white : Colors.grey[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Spice Level Selector - keeping original logic
                        Opacity(
                          opacity: randomEnabled ? 0.35 : 1.0,
                          child: IgnorePointer(
                            ignoring: randomEnabled,
                            child: Center(
                              child: _ModernChilliMeter(
                                value: spiceLevel,
                                onChanged: (v) {
                                  onSpiceChanged(v);
                                },
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 12.h),

                        // Selected spice label
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.r),
                              color: isDark 
                                ? Colors.grey[800]
                                : Colors.grey[100],
                              border: Border.all(
                                color: isDark 
                                  ? Colors.grey[600]!
                                  : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🌶️', style: TextStyle(fontSize: 14.sp)),
                                SizedBox(width: 6.w),
                                Text(
                                  randomEnabled ? _spiceLabels[5] : _spiceLabels[spiceLevel],
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: isDark ? Colors.white : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Random Toggle - keeping original logic
                        Align(
                          alignment: Alignment.center,
                          child: _SimpleRandomPill(
                            enabled: randomEnabled,
                            onChanged: (on) => onRandomChanged(on),
                            isDark: isDark,
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Time Section
                        Text(
                          'Max cook time',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isDark ? Colors.white : Colors.grey[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Quick select chips
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6.w,
                            runSpacing: 6.h,
                            children: [
                              for (final m in quick)
                                _SimpleTimeChip(
                                  label: _fmtDuration(m),
                                  selected: clamped == m,
                                  onSelected: (_) => _setTime(m),
                                  isDark: isDark,
                                ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Timer picker
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            color: isDark 
                              ? Colors.grey[850]
                              : Colors.grey[50],
                            border: Border.all(
                              color: isDark 
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 120.h,
                                child: CupertinoTimerPicker(
                                  key: ValueKey(clamped),
                                  mode: CupertinoTimerPickerMode.hm,
                                  minuteInterval: 5,
                                  initialTimerDuration: Duration(minutes: clamped),
                                  onTimerDurationChanged: (dur) {
                                    final mins = dur.inMinutes.clamp(0, _kMaxMinutes);
                                    _setTime(mins);
                                  },
                                ),
                              ),
                              Text(
                                'Selected: ${_fmtDuration(clamped)}  •  limit: up to 4h',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? Colors.grey[400] : Colors.grey[700],
                                  side: BorderSide(
                                    color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Close'),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.blue[700] : Colors.blue[600],
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: onApply,
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('Apply'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).asGlass(
              tintColor: isDark ? Colors.black : Colors.white,
              clipBorderRadius: BorderRadius.circular(20.r),
              blurX: 8,
              blurY: 8,
              frosted: true,
            ),
          ),
        );
      },
    );
  }
}

/// Modern chilli meter keeping exact same logic as ChilliMeter5
class _ModernChilliMeter extends StatelessWidget {
  final int value; // 0..4
  final ValueChanged<int> onChanged;
  final bool isDark;
  
  const _ModernChilliMeter({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (i) {
        final isActive = i <= value;
        final intensity = i / 4.0; // 0 to 1
        
        return GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive 
                ? Color.lerp(Colors.yellow[600], Colors.red[600], intensity)
                : isDark ? Colors.grey[700] : Colors.grey[300],
              border: Border.all(
                color: isActive 
                  ? Color.lerp(Colors.yellow[400], Colors.red[400], intensity)!
                  : Colors.transparent,
                width: 2,
              ),
              boxShadow: isActive ? [
                BoxShadow(
                  color: Color.lerp(Colors.yellow, Colors.red, intensity)!.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isActive 
                    ? Colors.white
                    : isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Simple random pill keeping exact same logic as _RandomPill
class _SimpleRandomPill extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _SimpleRandomPill({
    required this.enabled,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: () => onChanged(!enabled),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: enabled 
              ? (isDark ? Colors.blue[800] : Colors.blue[100])
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
            border: Border.all(
              color: enabled
                ? (isDark ? Colors.blue[600]! : Colors.blue[300]!)
                : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎲', style: TextStyle(fontSize: 14.sp)),
              SizedBox(width: 6.w),
              Text(
                enabled ? 'Random spice: ON' : 'Random spice: OFF',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: enabled 
                    ? (isDark ? Colors.blue[200] : Colors.blue[700])
                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple time chip keeping same selection logic
class _SimpleTimeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final bool isDark;

  const _SimpleTimeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: isDark ? Colors.blue[700] : Colors.blue[100],
      labelStyle: TextStyle(
        color: selected 
          ? (isDark ? Colors.white : Colors.blue[700])
          : (isDark ? Colors.grey[400] : Colors.grey[700]),
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
            ? (isDark ? Colors.blue[500]! : Colors.blue[300]!)
            : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
        ),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// /widgets/cravings/cravings_widget.dart
class CravingsResultsGrid extends StatelessWidget {
  const CravingsResultsGrid({
    super.key,
    required this.items,
    this.onTap,

    // ---- tunables ----
    this.outerHorizontalPadding = 24.0,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.phoneColumns = 1,
    this.tabletColumns = 2,
    this.phoneAspect = 1.7,
    this.tabletAspect = 0.72,
  });

  final List<CravingRecipeModel> items;
  final void Function(CravingRecipeModel item)? onTap;

  final double outerHorizontalPadding;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final int phoneColumns;
  final int tabletColumns;
  final double phoneAspect;
  final double tabletAspect;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final screenW = ScreenUtil().screenWidth;
    final isWide = screenW >= 700;
    final crossAxisCount = isWide ? tabletColumns : phoneColumns;

    final mainGap = (mainAxisSpacing ?? 14.h);
    final crossGap = (crossAxisSpacing ?? 14.w);

    // phone: 1 column -> use ListView to avoid any grid tile height math (no gaps)
    if (crossAxisCount == 1) {
      return ListView.separated(
        cacheExtent: MediaQuery.of(context).size.height,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: mainGap),
        itemBuilder: (_, i) => _CravingsCard(
          item: items[i],
          onTap: onTap,
          columns: 1,
          crossSpacing: crossGap,
          outerHorizontalPadding: outerHorizontalPadding,
        ),
      );
    }

    // tablet: 2+ columns -> compute exact tile height (mainAxisExtent)
    final availableW = (screenW - (outerHorizontalPadding * 2));
    final totalCrossSpacing = (crossAxisCount > 1) ? crossGap * (crossAxisCount - 1) : 0.0;
    final tileW = (availableW - totalCrossSpacing) / crossAxisCount;

    // your card padding is EdgeInsets.all(12.w)
    final cardHPad = 12.w;
    final innerW = (tileW - cardHPad * 2).clamp(0.0, double.infinity);

    // 16:9 image inside the card
    final imageH = innerW * 9.0 / 16.0;

    // title (max 2 lines) using current theme (rough but close)
    final titleStyle = theme.textTheme.titleMedium;
    final titleFont = (titleStyle?.fontSize ?? 16.0);
    final titleLineH = titleFont * (titleStyle?.height ?? 1.15);
    final titleH = titleLineH * 2;

    // time pill height
    final pillTextSize = (theme.textTheme.labelSmall?.fontSize ?? 12.0);
    final pillH = (6.h * 2) + pillTextSize + 2;

    // vertical structure: padding/image/spacers/title/spacer/pill/padding
    final topPad = 12.h;      // use .h for verticals
    final betweenImageTitle = 10.h;
    final betweenTitlePill = 6.h;
    final bottomPad = 12.h;

    final cardH = topPad +
        imageH +
        betweenImageTitle +
        titleH +
        betweenTitlePill +
        pillH +
        bottomPad;

    // Debug
    // print('[Grid] tileW=$tileW innerW=$innerW imageH=$imageH cardH=$cardH');

    // grid (tablet)
    return GridView.builder(
      cacheExtent: MediaQuery.of(context).size.height,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossGap,
        mainAxisSpacing: mainGap,
        mainAxisExtent: cardH, // <- matches card height: no blank under each tile
      ),
      itemBuilder: (_, i) => _CravingsCard(
        item: items[i],
        onTap: onTap,
        columns: crossAxisCount,
        crossSpacing: crossGap,
        outerHorizontalPadding: outerHorizontalPadding,
      ),
    );
  }
}

class _CravingsCard extends StatelessWidget {
  const _CravingsCard({
    required this.item,
    this.onTap,
    required this.columns,
    required this.crossSpacing,
    required this.outerHorizontalPadding,
  });

  final CravingRecipeModel item;
  final void Function(CravingRecipeModel item)? onTap;

  final int columns;
  final double crossSpacing;
  final double outerHorizontalPadding;

  String _fmtMins(int? mins) {
    final m = (mins ?? 0).clamp(0, 10000);
    final h = m ~/ 60;
    final rem = m % 60;
    if (h > 0) return '${h}h ${rem}m';
    return '${rem}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Uint8List? bytes = decodeDataUrl(item.imageDataUrl);
    print('\x1B[34m[CravingsCard] "${item.title}" decoded=${bytes?.length ?? 0} bytes\x1B[0m');

    // GPU cache downscale
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final screenW = ScreenUtil().screenWidth;
    final available = (screenW - (outerHorizontalPadding * 2)).clamp(0, double.infinity);
    final totalCrossSpacing = columns > 1 ? crossSpacing : 0.0;
    final gridWidthPerCol = (available - totalCrossSpacing) / columns;
    final cacheWidthPx = (gridWidthPerCol * dpr).round().clamp(64, 4096);

    final Widget imageArea = ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bytes != null && bytes.isNotEmpty)
            Hero(
              tag: 'craving:${item.id}',
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.low,
                cacheWidth: cacheWidthPx,
                errorBuilder: (_, __, ___) => _ImageErrorTile(title: item.title),
              ),
            )
          else
            _ImageErrorTile(title: item.title),

          // subtle gradient
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(isDark ? 0.05 : 0.08),
                      Colors.transparent,
                      Colors.black.withOpacity(isDark ? 0.22 : 0.18),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.teal : Colors.black,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.30 : 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
      ),
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // intrinsic height on phone/ListView
        children: [
          AspectRatio(
            aspectRatio: 16 / 9, 
            child: imageArea
          ),
          SizedBox(height: 10.h),
          Text(
            item.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: textColor(context),
              height: 1.15,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 6.h),
          _TimePill(label: _fmtMins(item.readyInMinutes)),
        ],
      ),
    ).asGlass(
      clipBorderRadius: BorderRadius.circular(20.r),
      frosted: true,
      blurX: 15,
      blurY: 15,
      tintColor: isDark ? Colors.deepPurpleAccent : Colors.deepOrange,
    );

    // No Align wrapper — phone ListView handles intrinsic height;
    // tablet Grid uses exact mainAxisExtent (so no blank below).
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(item),
      borderRadius: BorderRadius.circular(20.r),
      child: card,
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pill = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withOpacity(0.26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined, 
            size: 15.sp,
            color: textColor(context),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: textColor(context),
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );

    return pill.asGlass(
      frosted: true,
      blurX: 5,
      blurY: 5,
      tintColor: isDark ? Colors.lightGreen : Colors.deepPurple,
      clipBorderRadius: BorderRadius.circular(999),
    );
  }
}

class _ImageErrorTile extends StatelessWidget {
  const _ImageErrorTile({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface.withOpacity(0.12),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, size: 40, color: Colors.white.withOpacity(0.45)),
          const SizedBox(height: 6),
          Text('image', style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withOpacity(0.55),
            letterSpacing: 0.3,
          )),
        ],
      ),
    );
  }
}

// /lib/features/cravings/cravings.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:glass/glass.dart';
import 'package:lottie/lottie.dart';

import '/theme/app_theme.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/widgets/navigation/nav.dart';

class CravingsScreen extends StatefulWidget {
  const CravingsScreen({super.key});
  @override
  State<CravingsScreen> createState() => _CravingsScreenState();
}

class _CravingsScreenState extends State<CravingsScreen> {
  // ---- Config: set your background Lottie asset path here ----
  static const String _bgLottie = 'assets/animations/Animation_loading_glassmorphism.json';

  // UI-only controllers
  final TextEditingController _queryCtrl = TextEditingController();
  final TextEditingController _includeCtrl = TextEditingController();
  final TextEditingController _excludeCtrl = TextEditingController();

  int _maxTime = 30;
  String? _spiceLabel; // e.g. "Balanced Kick (Medium)"

  @override
  void dispose() {
    _queryCtrl.dispose();
    _includeCtrl.dispose();
    _excludeCtrl.dispose();
    super.dispose();
  }

  void _notWiredToast() {
    // ignore: avoid_print
    print('\x1B[34m[DEBUG] Generate tapped (service not wired yet)\x1B[0m');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cravings service not wired yet.')),
    );
  }

  // ---- Glassy filters bottom sheet (UI only) ----
  void _openFilters() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16.w,
            0,
            16.w,
            24.h + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Craving Filters', style: theme.textTheme.titleMedium),
                SizedBox(height: 12.h),

                // Must include
                TextFormField(
                  controller: _includeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Must include (comma-separated)',
                    hintText: 'garlic, tomato, egg',
                  ),
                ),
                SizedBox(height: 10.h),

                // Exclude / allergies
                TextFormField(
                  controller: _excludeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Exclude (allergies/intolerances)',
                    hintText: 'peanut, shellfish',
                  ),
                ),
                SizedBox(height: 12.h),

                // Spice + time
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _spiceLabel,
                        items: const [
                          'No Spice (Plain Jane)',
                          'Gentle Warmth (Mild)',
                          'Balanced Kick (Medium)',
                          'Bring the Heat (Spicy)',
                          'RIP (Super Spicy!)',
                          'Spice? I\'m Open!',
                        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _spiceLabel = v),
                        decoration: const InputDecoration(labelText: 'Spice level'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Max time: $_maxTime min', style: theme.textTheme.bodyMedium),
                          Slider(
                            value: _maxTime.toDouble(),
                            min: 5,
                            max: 120,
                            divisions: 23,
                            label: '$_maxTime',
                            onChanged: (v) => setState(() => _maxTime = v.round()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Close'),
                    ),
                    SizedBox(width: 10.w),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _notWiredToast();
                      },
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ).asGlass(
            tintColor: Colors.white,
            clipBorderRadius: BorderRadius.circular(24.r),
            blurX: 24,
            blurY: 24,
            frosted: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: true,
      extendBody: true,
      drawer: const CustomDrawer(),
      bottomNavigationBar: CustomNavBar(currentIndex: 3), // adjust as needed
      appBar: CustomAppBar(
        title: "My Cravings",
        showMenu: true,
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
        themeToggleWidget: ThemeToggleButton(),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ---- Fullscreen Lottie background ----
          IgnorePointer(
            child: Center(
              child: SizedBox(
                width: 400,   // <-- set your custom width
                height: 400,  // <-- set your custom height
                child: Lottie.asset(
                  _bgLottie,
                  frameRate: FrameRate.max,
                  repeat: true,
                  fit: BoxFit.contain, // don’t stretch, just contain inside box
                ),
              ),
            ),
          ),

          // Soft gradient overlay (for readability)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.45),
                  Colors.black.withOpacity(0.15),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ---- Foreground content ----
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 120.h, 24.w, 0.h),
            child: uid == null
                ? Center(
                    child: Text(
                      'Sign in to generate recipes based on your cravings.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 720.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "What are you craving today?",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 18.h),

                          // ---- Central glass search bar (Google-like) ----
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28.r),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, color: Colors.white70),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: TextField(
                                    controller: _queryCtrl,
                                    textInputAction: TextInputAction.search,
                                    onSubmitted: (_) => _notWiredToast(),
                                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: "e.g., spicy cheesy pasta under 20 min",
                                      hintStyle: TextStyle(color: Colors.white70),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                IconButton(
                                  tooltip: 'Filters',
                                  onPressed: _openFilters,
                                  icon: const Icon(Icons.tune_rounded, color: Colors.white70),
                                ),
                                SizedBox(width: 6.w),
                                ElevatedButton(
                                  onPressed: _notWiredToast,
                                  style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                                  child: const Text('Generate'),
                                ),
                              ],
                            ),
                          ).asGlass(
                            tintColor: Colors.white,
                            clipBorderRadius: BorderRadius.circular(28.r),
                            blurX: 24,
                            blurY: 24,
                            frosted: true,
                          ),

                          SizedBox(height: 14.h),

                          // ---- Caution banner (glass) ----
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Colors.amber),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    "AI‑generated results. Please review for accuracy and food safety.",
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
                          ),

                          SizedBox(height: 40.h),

                          // Placeholder (results area to be implemented later)
                          Text(
                            "Type a craving and tap Generate.",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

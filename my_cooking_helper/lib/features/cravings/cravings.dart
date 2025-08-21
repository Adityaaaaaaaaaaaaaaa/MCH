// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

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
  // ---- UI controllers/state (UI-only; no service wiring here) ----
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

  void _showServiceNotWiredToast() {
    // ignore: avoid_print
    print('\x1B[34m[DEBUG] Generate tapped (service not wired yet)\x1B[0m');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cravings service not wired yet.')),
    );
  }

  void _openFiltersSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16.w,
          8.h,
          16.w,
          24.h + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Craving Filters', style: theme.textTheme.titleMedium),
            SizedBox(height: 12.h),

            // Must-include ingredients
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
            SizedBox(height: 10.h),

            // Spice + Time
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
                    _showServiceNotWiredToast();
                  },
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
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
      bottomNavigationBar: CustomNavBar(currentIndex: 3), // adjust index as needed
      appBar: CustomAppBar(
        title: "My Cravings",
        showMenu: true,
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
        themeToggleWidget: ThemeToggleButton(),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 120.h, 24.w, 0.h),
        child: uid == null
            ? Center(
                child: Text(
                  'Sign in to generate recipes based on your cravings.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor(context).withOpacity(0.7),
                  ),
                ),
              )
            : Column(
                children: [
                  // Search row (UI only)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _queryCtrl,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _showServiceNotWiredToast(),
                          decoration: InputDecoration(
                            hintText: "Type a craving... e.g., spicy cheesy pasta under 20 min",
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: IconButton(
                              tooltip: 'Filters',
                              icon: const Icon(Icons.tune_rounded),
                              onPressed: _openFiltersSheet,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      ElevatedButton.icon(
                        onPressed: _showServiceNotWiredToast,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Generate'),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Caution banner
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Colors.amber),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            "AI‑generated results. Please review for accuracy and food safety.",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: textColor(context).withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Placeholder area (no results until service is wired)
                  Expanded(
                    child: Center(
                      child: Text(
                        "Start by typing a craving and hit Generate.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor(context).withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
      ),
    );
  }
}

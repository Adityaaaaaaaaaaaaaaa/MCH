// /lib/features/cravings/cravings.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '/services/cravings_service.dart';
import '/theme/app_theme.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/widgets/navigation/nav.dart';
import '/widgets/cravings_widget.dart';

class CravingsScreen extends StatefulWidget {
  const CravingsScreen({super.key});
  @override
  State<CravingsScreen> createState() => _CravingsScreenState();
}

class _CravingsScreenState extends State<CravingsScreen> {
  static const String _bgLottie = 'assets/animations/Animation_wave.json';

  final TextEditingController _queryCtrl = TextEditingController();
  final CravingsService _svc = CravingsService();

  // -------- Defaults from Firestore (spice/time) --------
  // 1) Defaults: set time = 90 min, spice from Firestore (as before)
  int _defaultSpice = 2; // 0..5 (fallback if Firestore missing)
  int _defaultTime  = 90; // <-- 1 hour 30 minutes

  // 2) Effective values (no change): if user didn't Apply, defaults are used
  int? _overrideSpice; // null => use default
  int? _overrideTime;  // null => use default
  int get _effectiveSpice => _overrideSpice ?? _defaultSpice;
  int get _effectiveTime  => _overrideTime  ?? _defaultTime;


  @override
  void initState() {
    super.initState();
    _primeDefaultsFromPrefs();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  // Fetch prefs + inventory; set default spice (0..5). Time default stays 30 unless you store it.
  // 3) Keep this: load spice from Firestore; leave time default at 90 unless you add it in prefs
  Future<void> _primeDefaultsFromPrefs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      print('\x1B[34m[DEBUG][Cravings] Loading defaults from Firestore...\x1B[0m');
      final ctx = await _svc.loadUserCravingsContext(uid);

      final mapped = ctx.spiceLevel.clamp(0, 5);
      setState(() {
        _defaultSpice = mapped;
        // _defaultTime stays at 90 unless you later read it from Firestore
      });

      print('\x1B[34m[DEBUG][Cravings] Defaults -> spice=$_defaultSpice, time=$_defaultTime\x1B[0m');
    } catch (e) {
      print('\x1B[34m[DEBUG][Cravings] Failed to load defaults: $e\x1B[0m');
    }
  }


  // For now, Generate just re-fetches (so you see blue logs). Later we’ll pass query + effective filters to backend.
  // 4) Generate: ALWAYS use the effective (user override if any, otherwise defaults)
  Future<void> _generate() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please sign in to use cravings.')));
      return;
    }

    final query = _queryCtrl.text.trim();
    final spice = _effectiveSpice;   // <-- user-chosen if applied, else Firestore default
    final time  = _effectiveTime;    // <-- user-chosen if applied, else 90

    print('\x1B[34m[DEBUG][Cravings] Generate → query="$query", spice=$spice, time=$time min\x1B[0m');

    try {
      // For now just fetch context to show blue logs; next step: call your backend with {query, spice, time}
      await _svc.loadUserCravingsContext(uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Using spice=$spice • time=$time min (see blue logs).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user context: $e')),
      );
    }
  }

  // 5) Filters sheet commit (no change): only set overrides on Apply
  void _openFilters() {
    int tempSpice = _effectiveSpice;
    int tempTime  = _effectiveTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return CravingsFiltersSheet(
              spiceLevel: tempSpice,
              maxTime: tempTime,
              onSpiceChanged: (v) => setModalState(() => tempSpice = v),
              onTimeChanged:  (v) => setModalState(() => tempTime  = v),
              onApply: () {
                setState(() {
                  _overrideSpice = (tempSpice == _defaultSpice) ? null : tempSpice;
                  _overrideTime  = (tempTime  == _defaultTime)  ? null : tempTime;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Filters set • spice=$tempSpice, time=$tempTime min')),
                );
              },
            );
          },
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
      bottomNavigationBar: CustomNavBar(currentIndex: 3),
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
          // Background animation
          IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 400.w,
                height: 400.h,
                child: Lottie.asset(
                  _bgLottie,
                  frameRate: FrameRate.max,
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Readability gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.45), Colors.black.withOpacity(0.15)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Foreground
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

                          // Clean glass search bar (no buttons)
                          GlassSearchBar(
                            controller: _queryCtrl,
                            onSubmit: _generate,
                          ),

                          SizedBox(height: 12.h),

                          // Separate actions row (Filters + Generate)
                          CravingsActions(
                            onOpenFilters: _openFilters,
                            onGenerate: _generate,
                          ),

                          SizedBox(height: 14.h),

                          // Caution banner
                          const CautionBannerGlass(),

                          SizedBox(height: 40.h),

                          // Helper text showing current effective filters
                          Text(
                            "Effective filters → spice: $_effectiveSpice • time: $_effectiveTime min",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.85),
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

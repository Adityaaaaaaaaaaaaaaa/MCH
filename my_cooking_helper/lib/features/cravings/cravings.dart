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

  // Defaults loaded from Firestore
  Map<String, dynamic>? _defaults; // allergies, cuisines, diets, inventory, spiceLevel(0..5), spiceLabel
  int _defaultTime = 90;            // 1h30 global default

  // User overrides (null => use default)
  bool? _overrideRandomSpice; // if null, use default randomness (default is spiceLevel==5)
  int?  _overrideSpiceFixed;  // 0..4 (ignored if random)
  int?  _overrideTime;        // minutes

  // Effective getters
  bool get _defaultRandom => (_defaults?['spiceLevel'] == 5);
  bool get _effectiveRandom => _overrideRandomSpice ?? _defaultRandom;
  int  get _effectiveFixedSpice =>
      (_overrideSpiceFixed ??
          (_defaults != null ? (_defaults!['spiceLevel'] as int).clamp(0, 4) : 2));
  int  get _effectiveTime => _overrideTime ?? _defaultTime;

  @override
  void initState() {
    super.initState();
    _primeDefaultsFromFirestore();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _primeDefaultsFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // ignore: avoid_print
      print('\x1B[34m[DEBUG][Cravings] Loading Firestore defaults...\x1B[0m');
      final map = await _svc.fetchDefaults(uid);
      setState(() => _defaults = map);
      // ignore: avoid_print
      print('\x1B[34m[DEBUG][Cravings] Defaults ready: spice=${map['spiceLevel']}, time=$_defaultTime\x1B[0m');
    } catch (e) {
      // ignore: avoid_print
      print('\x1B[34m[DEBUG][Cravings] Failed to load defaults: $e\x1B[0m');
    }
  }

  void _openFilters() {
    // start with effective values
    int   tempFixed   = _effectiveFixedSpice; // 0..4
    bool  tempRandom  = _effectiveRandom;     // true => ignore fixed
    int   tempMinutes = _effectiveTime;       // minutes

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return CravingsFiltersSheet(
              spiceLevel: tempFixed,
              randomEnabled: tempRandom,
              timeMinutes: tempMinutes,
              onSpiceChanged: (v) {
                setModalState(() => tempFixed = v);
                _svc.debugUserSelection(spiceFixedLevel: v);
              },
              onRandomChanged: (on) {
                setModalState(() => tempRandom = on);
                _svc.debugUserSelection(randomEnabled: on);
              },
              onTimeChanged: (mins) {
                setModalState(() => tempMinutes = mins);
                _svc.debugUserSelection(timeMinutes: mins);
              },
              onApply: () {
                setState(() {
                  // Commit to overrides.
                  // If user set the same as defaults, keep null (means "use defaults")
                  final defFixed = (_defaults?['spiceLevel'] as int? ?? 2).clamp(0, 4);
                  final defRand  = _defaultRandom;

                  _overrideRandomSpice = (tempRandom == defRand) ? null : tempRandom;
                  _overrideSpiceFixed  = tempRandom ? null : (tempFixed == defFixed ? null : tempFixed);
                  _overrideTime        = (tempMinutes == _defaultTime) ? null : tempMinutes;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Filters set • '
                      'spice=${tempRandom ? "RANDOM" : tempFixed}, time=${tempMinutes}m')),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _generate() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please sign in to use cravings.')));
      return;
    }

    // Ensure defaults are present
    final defaults = _defaults ?? await _svc.fetchDefaults(uid);

    final query = _queryCtrl.text.trim();
    final useRandom = _effectiveRandom;
    final useFixed  = _effectiveFixedSpice; // only used if !random
    final timeMins  = _effectiveTime;

    // Build + log the final payload; this also resolves random 0..4 when needed.
    _svc.buildFinalBundle(
      userId: uid,
      query: query,
      defaults: defaults,
      randomSpice: useRandom,
      fixedSpiceLevel: useRandom ? null : useFixed,
      timeMinutes: timeMins,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating with '
          '${useRandom ? "random spice" : "spice=$useFixed"} • time=$timeMins min')),
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
      resizeToAvoidBottomInset: true,
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
          // Background Lottie + gradient...
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
            padding: EdgeInsets.fromLTRB(24.w, 120.h, 24.w, 0),
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
                : Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bottomInset = MediaQuery.of(context).viewInsets.bottom; // keyboard height

                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.only(
                                bottom: 16.h + (bottomInset > 0 ? bottomInset : 0), // room when keyboard shows
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 720.w),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(height: 30.h),
                                        Text(
                                          "What are you craving today?",
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            color: Colors.white.withOpacity(0.95),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 50.h),

                                        GlassSearchBar(
                                          controller: _queryCtrl,
                                          onSubmit: _generate,
                                        ),
                                        SizedBox(height: 10.h),

                                        CravingsActions(
                                          onOpenFilters: _openFilters,
                                          onGenerate: _generate,
                                        ),
                                        SizedBox(height: 14.h),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // 👇 Banner now locked just above the nav bar
                      const CautionBannerGlass(),
                      SizedBox(height: 90.h),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

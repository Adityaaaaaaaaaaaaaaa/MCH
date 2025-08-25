// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';

import '/models/cravings.dart';
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

  List<CravingRecipeModel>? _results;
  bool _loading = false;


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

    final defaults = _defaults ?? await _svc.fetchDefaults(uid);

    final query     = _queryCtrl.text.trim();
    final useRandom = _effectiveRandom;
    final useFixed  = _effectiveFixedSpice; // used only when !random
    final timeMins  = _effectiveTime;

    setState(() { 
      _loading = true; 
      _results = null; // clear previous results so layout “snaps” up cleanly
    });

    CravingsSessionResult? session;
    try {
      // ✅ new: get models (with imageDataUrl) directly from the POST response
      session = await _svc.generateCravingsAndParse(
        userId: uid,
        query: query,
        defaults: defaults,
        randomSpice: useRandom,
        fixedSpiceLevel: useRandom ? null : useFixed,
        timeMinutes: timeMins,
        timeout: const Duration(seconds: 75), // image+LLM is slow sometimes
      );
    } catch (e) {
      // soft-fail — server likely still saved to Firestore; try to hydrate from there
      // ignore: avoid_print
      print('\x1B[34m[DEBUG][Cravings] POST parse failed, trying Firestore: $e\x1B[0m');
    }

    List<CravingRecipeModel> models;
    if (session != null && session.items.isNotEmpty) {
      models = session.items;
    } else {
      // 🔁 fallback: read latest saved session and fetch images by title
      models = await _svc.fetchLatestCravingsWithImages(uid);
    }

    if (!mounted) return;
    setState(() {
      _results = models;
      _loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating with '
          '${useRandom ? "random spice" : "spice=$useFixed"} • time=$timeMins min')),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final hasResults = (_results != null && _results!.isNotEmpty); // ⭐ NEW
    final topPad = hasResults ? 40.h : 120.h;                       // ⭐ NEW


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
          // Background stays, but we can dim the lottie when results are visible:
          IgnorePointer(
            child: Opacity(
              opacity: hasResults ? 0.0 : 1.0, // ⭐ NEW
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 400.w,
                  height: 400.h,
                  child: Lottie.asset(_bgLottie, frameRate: FrameRate.max, repeat: true, fit: BoxFit.contain),
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
            padding: EdgeInsets.fromLTRB(24.w, topPad, 24.w, 0), // ⭐ NEW
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
                            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.only(
                                bottom: 16.h + (bottomInset > 0 ? bottomInset : 0),
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 720.w),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(height: hasResults ? 10.h : 30.h),
                                        Text(
                                          hasResults ? "Your picks" : "What are you craving today?",
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            color: Colors.white.withOpacity(0.95),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: hasResults ? 16.h : 50.h),

                                        // Search bar always visible
                                        GlassSearchBar(
                                          controller: _queryCtrl,
                                          onSubmit: _generate,
                                        ),
                                        SizedBox(height: 10.h),

                                        // Hide actions if we have results (like Google style) ⭐ NEW
                                        if (!hasResults) ...[
                                          CravingsActions(
                                            onOpenFilters: _openFilters,
                                            onGenerate: _generate,
                                          ),
                                          SizedBox(height: 14.h),
                                        ],

                                        // Results grid ⭐ NEW
                                        if (hasResults) ...[
                                          SizedBox(height: 16.h),
                                          if (_loading)
                                            const LinearProgressIndicator(minHeight: 2)
                                          else
                                            CravingsResultsGrid(
                                              items: _results!,
                                              onTap: (m) {
                                                // TODO: push detail page with `m`
                                              },
                                            ),
                                          SizedBox(height: 16.h),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

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

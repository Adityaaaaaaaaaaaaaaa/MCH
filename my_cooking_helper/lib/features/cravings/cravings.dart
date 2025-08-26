// lib/features/cravings/cravings.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';

import '/theme/app_theme.dart';
import '/models/cravings.dart';
import '/services/cravings_service.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/widgets/navigation/nav.dart';
import '/widgets/cravings/cravings_widget.dart';

class CravingsScreen extends StatefulWidget {
  const CravingsScreen({super.key});
  @override
  State<CravingsScreen> createState() => _CravingsScreenState();
}

class _CravingsScreenState extends State<CravingsScreen> {
  static const String _bgLottie = 'assets/animations/Animation_wave.json';
  static const String _loadingLottie = 'assets/animations/Animation_wave.json'; // replace later

  // Height of your CustomNavBar so content can scroll behind it elegantly.
  static const double _bottomNavSpacer = 90;

  final TextEditingController _queryCtrl = TextEditingController();
  final CravingsService _svc = CravingsService();

  List<CravingRecipeModel>? _results;
  bool _loading = false;

  Map<String, dynamic>? _defaults;
  int _defaultTime = 90;

  bool? _overrideRandomSpice;
  int?  _overrideSpiceFixed;
  int?  _overrideTime;

  bool get _defaultRandom => (_defaults?['spiceLevel'] == 5);
  bool get _effectiveRandom => _overrideRandomSpice ?? _defaultRandom;
  int  get _effectiveFixedSpice =>
      (_overrideSpiceFixed ?? (_defaults != null ? (_defaults!['spiceLevel'] as int).clamp(0, 4) : 2));
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
      print('\x1B[34m[DEBUG][Cravings] Loading Firestore defaults...\x1B[0m');
      final map = await _svc.fetchDefaults(uid);
      setState(() => _defaults = map);
      print('\x1B[34m[DEBUG][Cravings] Defaults ready: spice=${map['spiceLevel']}, time=$_defaultTime\x1B[0m');
    } catch (e) {
      print('\x1B[34m[DEBUG][Cravings] Failed to load defaults: $e\x1B[0m');
    }
  }

  void _openFilters() {
    int   tempFixed   = _effectiveFixedSpice;
    bool  tempRandom  = _effectiveRandom;
    int   tempMinutes = _effectiveTime;

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
    final useFixed  = _effectiveFixedSpice;
    final timeMins  = _effectiveTime;

    setState(() {
      _loading = true;
      _results = null; // clean loading state
    });

    CravingsSessionResult? session;
    try {
      session = await _svc.generateCravingsAndParse(
        userId: uid,
        query: query,
        defaults: defaults,
        randomSpice: useRandom,
        fixedSpiceLevel: useRandom ? null : useFixed,
        timeMinutes: timeMins,
        timeout: const Duration(seconds: 75),
      );
    } catch (e) {
      print('\x1B[34m[DEBUG][Cravings] POST parse failed, trying Firestore: $e\x1B[0m');
    }

    List<CravingRecipeModel> models;
    if (session != null && session.items.isNotEmpty) {
      models = session.items;
    } else {
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final hasResults = (_results != null && _results!.isNotEmpty);

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: true,
      extendBody: true, // scroll under bottom nav
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
          // Background lottie (visible only when no results)
          Positioned(
            top: 100.h,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: hasResults ? 0.0 : 1.0,
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
            ),
          ),

          // MAIN: three states
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // A) NO RESULTS (centered search & actions, caution glued at bottom)
              if (uid == null)
                _centeredWithCaution(
                  content: _centerChunk(
                    "Sign in to generate recipes based on your cravings.",
                    showActions: false,
                  ),
                )
              else if (!_loading && !hasResults)
                _centeredWithCaution(
                  content: _centerChunk(
                    "What are you craving today?",
                    showActions: true,
                  ),
                )

              // B) LOADING (center Lottie, caution glued at bottom)
              else if (_loading && !hasResults)
                _centeredWithCaution(
                  content: Center(
                    child: SizedBox(
                      width: 200.w,
                      height: 200.h,
                      child: Lottie.asset(
                        _loadingLottie,
                        repeat: true,
                        frameRate: FrameRate.max,
                      ),
                    ),
                  ),
                )

              // C) RESULTS (pinned search + compact top gap + grid)
              else ...[
                SliverPadding(
                  padding: EdgeInsets.only(top: 120.h), // tighter than before
                  sliver: SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedSearchHeader(
                      minH: 66.h,
                      maxH: 80.h,
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: GlassSearchBar(
                        controller: _queryCtrl,
                        onSubmit: _generate,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 20.h),
                    child: CravingsResultsGrid(
                      items: _results!,
                      onTap: (m) {
                        // TODO: push details later
                      },

                      // spacing/size control
                      outerHorizontalPadding: 24.w,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      phoneColumns: 1,
                      tabletColumns: 2,
                      phoneAspect: 0.90, // slightly taller cards on phones
                      tabletAspect: 0.70,
                    ),
                  ),
                ),
              ],

              // Caution glued above bottom nav (all states handled)
              // SliverToBoxAdapter(child: SizedBox(height: 14.h)),
              // SliverPadding(
              //   padding: EdgeInsets.symmetric(horizontal: 24.w),
              //   sliver: const SliverToBoxAdapter(child: CautionBannerGlass()),
              // ),
              // SliverToBoxAdapter(child: SizedBox(height: _bottomNavSpacer)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- helper slivers ----------

  /// A centered piece of content with the caution bar pushed to the bottom (above nav).
  SliverFillRemaining _centeredWithCaution({required Widget content}) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        children: [
          // take available space to keep content centered
          Expanded(child: Center(child: Padding(
            //padding: EdgeInsets.symmetric(horizontal: 24.w),
            padding: EdgeInsets.only(top: 120.h),
            child: content,
          ))),

          // caution + spacer for bottom nav
          Padding(
            //padding: EdgeInsets.symmetric(horizontal: 24.w),
            padding: EdgeInsets.only(bottom: 20.h, left: 10.w, right: 10.w),
            child: const CautionBannerGlass(),
          ),
          SizedBox(height: _bottomNavSpacer),
        ],
      ),
    );
  }

  Widget _centerChunk(String title, {required bool showActions}) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 720.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16.h),
          GlassSearchBar(
            controller: _queryCtrl,
            onSubmit: _generate,
          ),
          if (showActions) ...[
            SizedBox(height: 12.h),
            CravingsActions(
              onOpenFilters: _openFilters,
              onGenerate: _generate,
            ),
          ],
        ],
      ),
    );
  }
}

/// Pinned header that holds the search bar when results exist.
class _PinnedSearchHeader extends SliverPersistentHeaderDelegate {
  _PinnedSearchHeader({
    required this.minH,
    required this.maxH,
    required this.padding,
    required this.child,
  });

  final double minH;
  final double maxH;
  final EdgeInsets padding;
  final Widget child;

  @override
  double get minExtent => minH;
  @override
  double get maxExtent => maxH;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.transparent,
      padding: padding,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedSearchHeader oldDelegate) {
    return oldDelegate.minH != minH ||
        oldDelegate.maxH != maxH ||
        oldDelegate.padding != padding ||
        oldDelegate.child != child;
  }
}

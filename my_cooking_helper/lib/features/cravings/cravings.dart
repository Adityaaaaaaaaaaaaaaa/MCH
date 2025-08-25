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
  static const String _loadingLottie = 'assets/animations/Animation_wave.json'; // swap later

  // If you know the height of your CustomNavBar, set it here.
  // This spacer lets content scroll BEHIND the bottom nav (extendBody: true).
  static const double _bottomNavSpacer = 90;

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
      print('\x1B[34m[DEBUG][Cravings] Loading Firestore defaults...\x1B[0m');
      final map = await _svc.fetchDefaults(uid);
      setState(() => _defaults = map);
      print('\x1B[34m[DEBUG][Cravings] Defaults ready: spice=${map['spiceLevel']}, time=$_defaultTime\x1B[0m');
    } catch (e) {
      print('\x1B[34m[DEBUG][Cravings] Failed to load defaults: $e\x1B[0m');
    }
  }

  void _openFilters() {
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
      _results = null; // clear previous results to show clean loading state
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
      extendBody: true, // content can scroll under bottom nav
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
          // Background lottie (dim more when results are present)
          IgnorePointer(
            child: Opacity(
              opacity: hasResults ? 0.10 : 1.0,
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 420.w,
                  height: 420.h,
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

          // MAIN SCROLLER: switches between 3 states
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ========== STATE A: NO RESULTS (centered bar + actions) ==========
              if (uid == null)
                _buildCenteredMessage('Sign in to generate recipes based on your cravings.')
              else if (!_loading && !hasResults)
                _buildCenteredSearch(
                  title: "What are you craving today?",
                  childBelow: Padding(
                    padding: EdgeInsets.only(top: 14.h),
                    child: CravingsActions(
                      onOpenFilters: _openFilters,
                      onGenerate: _generate,
                    ),
                  ),
                )

              // ========== STATE B: LOADING (center Lottie) ==========
              else if (_loading && !hasResults)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: SizedBox(
                      width: 220.w,
                      height: 220.h,
                      child: Lottie.asset(
                        _loadingLottie,
                        repeat: true,
                        frameRate: FrameRate.max,
                      ),
                    ),
                  ),
                )

              // ========== STATE C: RESULTS (pinned bar + big grid) ==========
              else ...[
                // Pinned search bar
                SliverPadding(
                  padding: EdgeInsets.only(top: 120.h),
                  sliver: SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedSearchHeader(
                      minH: 72.h,
                      maxH: 86.h,
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: GlassSearchBar(
                        controller: _queryCtrl,
                        onSubmit: _generate,
                      ),
                    ),
                  ),
                ),
                // Results grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 0),
                    child: CravingsResultsGrid(
                      items: _results!,
                      onTap: (m) {
                        // TODO: open details later
                      },
                    ),
                  ),
                ),
              ],

              // Footer caution + spacer to keep it just above bottom nav
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                sliver: const SliverToBoxAdapter(child: CautionBannerGlass()),
              ),
              // Spacer so content can scroll behind bottom nav
              SliverToBoxAdapter(child: SizedBox(height: _bottomNavSpacer)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- helper slivers ----------

  SliverFillRemaining _buildCenteredMessage(String text) {
    final theme = Theme.of(context);
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ),
      ),
    );
  }

  SliverFillRemaining _buildCenteredSearch({
    required String title,
    Widget? childBelow,
  }) {
    final theme = Theme.of(context);
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: ConstrainedBox(
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
                SizedBox(height: 18.h),
                GlassSearchBar(
                  controller: _queryCtrl,
                  onSubmit: _generate,
                ),
                if (childBelow != null) childBelow,
              ],
            ),
          ),
        ),
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

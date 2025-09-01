// lib/features/cravings/cravings.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '/theme/app_theme.dart';
import '/models/cravings.dart';
import '/services/cravings_service.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/widgets/navigation/nav.dart';
import '/widgets/cravings/cravings_widget.dart';

// Rebuilds on sign-in, sign-out, and user switches
final authUserProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

class CravingsScreen extends ConsumerStatefulWidget {
  const CravingsScreen({super.key});
  @override
  ConsumerState<CravingsScreen> createState() => _CravingsScreenState();
}

class _CravingsScreenState extends ConsumerState<CravingsScreen> {
  static const String _bgLottie = 'assets/animations/Animation_wave.json';
  static const String _loadingLottie = 'assets/animations/Animation_AI_Food_Search.json';

  late final ProviderSubscription<AsyncValue<User?>> _authSub;

  // Height of your CustomNavBar so content can scroll behind it elegantly.
  static const double _bottomNavSpacer = 100;

  final TextEditingController _queryCtrl = TextEditingController();
  final CravingsService _svc = CravingsService();

  List<CravingRecipeModel>? _results;
  bool _loading = false;

  Map<String, dynamic>? _defaults;
  // ignore: prefer_final_fields
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

    // ✅ Allowed in initState
    _authSub = ref.listenManual<AsyncValue<User?>>(authUserProvider, (prev, next) {
      final prevUid = prev?.asData?.value?.uid;
      final nextUid = next.asData?.value?.uid;
      if (nextUid != null && nextUid != prevUid) {
        print('\x1B[34m[DEBUG][Cravings] Auth resolved for uid=$nextUid\x1B[0m');
        _primeDefaultsFromFirestore(nextUid);
      }
    }, fireImmediately: true); // immediately fires once with current value (if any)
  }

  @override
  void dispose() {
    _authSub.close();
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _primeDefaultsFromFirestore(String uid) async {
    try {
      print('\x1B[34m[DEBUG][Cravings] Loading Firestore defaults...\x1B[0m');
      final map = await _svc.fetchDefaults(uid);
      if (!mounted) return;
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
    //final uid = ref.read(authUserProvider).value?.uid;
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

  void _resetToLoadingFromClear() {
    // go to State A (LOADING) with no results
    setState(() {
      _loading = false;
      _results = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    //final uid = FirebaseAuth.instance.currentUser?.uid;
    final auth = ref.watch(authUserProvider);

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final uid = auth.asData?.value?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    final hasResults = (_results != null && _results!.isNotEmpty);

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: false,
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
          // Background lottie (rendered ONLY when no results)
          if (!hasResults)
            Positioned(
              top: 40.h,
              left: 0,
              right: 0,
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

          // MAIN: three states
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ========= A) NO RESULTS (centered) =========
              if (uid == null)
                _buildCenteredWithCaution(
                  content: _buildCenterContent(
                    "Sign in to generate recipes based on your cravings.",
                    showActions: false,
                  ),
                )
              else if (!_loading && !hasResults)
                _buildCenteredWithCaution(
                  content: _buildCenterContent(
                    "What are you craving today?",
                    showActions: true,
                  ),
                )

              // ========= B) LOADING (centered Lottie) =========
              else if (_loading && !hasResults)
                _buildCenteredWithCaution(
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

              // ========= C) RESULTS =========
              else ...[
                // Search bar pinned directly under the app bar (no extra top spacer needed)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedSearchHeader(
                    minH: 56.h,
                    maxH: 56.h,
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    child: GlassSearchBar(
                      controller: _queryCtrl,
                      onSubmit: _generate,
                      onClear: _resetToLoadingFromClear,
                    ),
                  ),
                ),

                // tiny gap under search
                SliverToBoxAdapter(child: SizedBox(height: 10.h)),

                // Cards (tight) — no inner scroll, so no weird extra space
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20.w, 5.h, 20.w, 5.h),
                  sliver: SliverToBoxAdapter(
                    child: CravingsResultsGrid(
                      items: _results!,
                      onTap: (m) async {
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid == null) return;

                        // m is CravingRecipeModel from the grid (already has imageDataUrl for this session)
                        final detail = await _svc.fetchCravingRecipeDetail(
                          userId: uid,
                          recipeId: m.id,
                          previewImageDataUrl: m.imageDataUrl, // pass the preview image!
                        );

                        if (detail != null && context.mounted) {
                          context.push('/cravingRecipe', extra: detail);
                        }
                      },
                      outerHorizontalPadding: 24.w,
                      mainAxisSpacing: 10.h,
                      crossAxisSpacing: 12.w,
                      phoneColumns: 1,
                      tabletColumns: 2,
                      phoneAspect: 0.90,
                      tabletAspect: 0.70,
                    ),
                  ),
                ),

                // Caution immediately after cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 0),
                    child: const CautionBannerGlass(),
                  ),
                ),

                // Bottom spacer so content can scroll behind the bottom nav (but never behind the app bar)
                SliverToBoxAdapter(child: SizedBox(height: _bottomNavSpacer)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ---------- helper slivers (renamed for clarity) ----------

  /// Centered content panel (title + search [+ optional actions]).
  Widget _buildCenterContent(String title, {required bool showActions}) {
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
              color: textColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16.h),
          GlassSearchBar(
            controller: _queryCtrl,
            onSubmit: _generate,
            onClear: _resetToLoadingFromClear,
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

  /// A centered layout with the caution bar glued above the bottom nav.
  SliverFillRemaining _buildCenteredWithCaution({required Widget content}) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: 120.h),
                child: content,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 20.h, left: 10.w, right: 10.w),
            child: const CautionBannerGlass(),
          ),
          SizedBox(height: _bottomNavSpacer),
        ],
      ),
    );
  }
}

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

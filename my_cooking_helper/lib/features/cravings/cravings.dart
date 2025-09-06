// lib/features/cravings/cravings.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:glass/glass.dart';
import '../../utils/emoji_animation.dart';
import '/utils/loader.dart';
import '/theme/app_theme.dart';
import '/models/cravings.dart';
import '/services/cravings_service.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/widgets/navigation/nav.dart';
import '/widgets/cravings/cravings_widget.dart';
import '/utils/connectivity_provider.dart';

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

  String? _errorMsg;

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
      _results = null;   // clean loading state
      _errorMsg = null;  // clear any previous error
    });

    CravingsSessionResult? session;
    Object? genError;
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
      genError = e;
      print('\x1B[34m[DEBUG][Cravings] generateCravingsAndParse failed: $e\x1B[0m');
    }

    if (!mounted) return;

    if (session != null && session.items.isNotEmpty) {
      setState(() {
        _results = session!.items;
        _loading = false;
        _errorMsg = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generating with '
            '${useRandom ? "random spice" : "spice=$useFixed"} • time=$timeMins min')),
      );
    } else {
      // Backend didn’t respond or returned no items → show friendly error (no fallback)
      setState(() {
        _loading = false;
        _results = null;
        _errorMsg = genError?.toString() ?? 'No response from the server.';
      });
    }
  }

  void _resetToLoadingFromClear() {
    // go to State A (LOADING) with no results
    setState(() {
      _loading = false;
      _results = null;
    });
  }

  // Mask URLs/IPs from raw errors
  String _sanitizeError(String s) {
    var out = s;
    out = out.replaceAll(RegExp(r'uri=\S+', caseSensitive: false), 'uri=<hidden>');
    out = out.replaceAll(RegExp(r'host:\s*\S+', caseSensitive: false), 'host:<hidden>');
    out = out.replaceAll(RegExp(r'port:\s*\d+', caseSensitive: false), 'port:<hidden>');
    out = out.replaceAll(RegExp(r'https?:\/\/[^\s)]+', caseSensitive: false), '<url>');
    out = out.replaceAll(RegExp(r'\b\d{1,3}(\.\d{1,3}){3}\b(:\d+)?'), '<ip>');
    return out;
  }

  // Glass error card (friendly headline + sanitized details)
  Widget _cravingsErrorGlass(String raw) {
    final theme = Theme.of(context);
    final String lower = raw.toLowerCase();

    String title = 'Something went wrong';
    String friendly = 'Please try again. If it persists, check your connection.';
    Color accent = Colors.redAccent;

    if (lower.contains('timed out') || lower.contains('timeout')) {
      title = 'Connection timed out';
      friendly = "The server didn’t respond in time. Please try again.";
      accent = Colors.orangeAccent;
    } else if (lower.contains('socketexception') || lower.contains('failed host lookup')) {
      title = 'Network issue';
      friendly = 'We couldn’t reach the service. Please verify your connection.';
      accent = Colors.deepOrangeAccent;
    } else if (RegExp(r'\b(5\d{2})\b').hasMatch(lower) || lower.contains('internal server error')) {
      title = 'Server problem';
      friendly = 'The service had a hiccup. Try again shortly.';
      accent = Colors.pinkAccent;
    } else if (RegExp(r'\b(4\d{2})\b').hasMatch(lower)) {
      title = 'Request error';
      friendly = 'The request could not be completed. Please try again.';
      accent = Colors.amber;
    }

    final details = _sanitizeError(raw);

    return Padding(
      // keeps it away from screen edges on all devices
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Align(
        alignment: Alignment.center,
        child: FractionallySizedBox(
          // % of available width (prevents edge-to-edge)
          widthFactor: 0.88,
          child: ConstrainedBox(
            // hard cap so it never looks too wide on tablets
            constraints: BoxConstraints(maxWidth: 480.w, minWidth: 260.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EmojiAnimation(name: 'warning', size: 38.r),
                  SizedBox(height: 8.h),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: textColor(context),
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),

                  // Friendly summary
                  Text(
                    friendly,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor(context).withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5.sp,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Collapsible details with a modest height cap
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      collapsedIconColor: textColor(context).withOpacity(0.6),
                      iconColor: textColor(context).withOpacity(0.6),
                      leading: Icon(
                        Icons.info_outline_rounded,
                        size: 16.sp,
                        color: textColor(context).withOpacity(0.7),
                      ),
                      title: Text(
                        'Details (sanitized)',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: textColor(context).withOpacity(0.7),
                        ),
                      ),
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 130.h),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 8.h),
                            child: SelectableText(
                              details,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.sp,
                                height: 1.2,
                                color: textColor(context).withOpacity(0.65),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Compact retry button
                  SizedBox(
                    width: 180.w,
                    child: ElevatedButton.icon(
                      onPressed: _generate,
                      icon: Icon(Icons.refresh, size: 18.sp),
                      label: Text(
                        'Retry',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: accent.withOpacity(0.9),
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ).asGlass(
              blurX: 16,
              blurY: 16,
              tintColor: accent.withOpacity(0.12),
              clipBorderRadius: BorderRadius.circular(16.r),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //final uid = FirebaseAuth.instance.currentUser?.uid;
    final auth = ref.watch(authUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ online state
    final isOnline = ref.watch(isOnlineProvider).maybeWhen(
      data: (v) => v, orElse: () => true,
    );

    if (auth.isLoading) {
      return Scaffold(
        body: Center(child: loader(
            isDark ? Colors.deepOrangeAccent : Colors.orange,
            70,
            5,
            8,
            500,
          ),
        ),
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
              // ========= A) NO RESULTS (centered) =========
              else if (!_loading && !hasResults)
                _buildCenteredWithCaution(
                  content: Builder(
                    builder: (context) {
                      // 1) Offline → keep original UI (no error box)
                      if (!isOnline) {
                        return AbsorbPointer(
                          absorbing: true,
                          child: _buildCenterContent(
                            "You are offline",
                            showActions: false,
                          ),
                        );
                      }

                      // 2) Online but backend error → error box + disabled search titled "Server error"
                      if (_errorMsg != null && _errorMsg!.isNotEmpty) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _cravingsErrorGlass(_errorMsg!), // friendly/sanitized glass error
                            SizedBox(height: 14.h),
                            AbsorbPointer(
                              absorbing: false, // keep search disabled in error state
                              child: _buildCenterContent(
                                "Server error",
                                showActions: false,
                              ),
                            ),
                          ],
                        );
                      }


                      // 3) Online, no error → original prompt and actions
                      return _buildCenterContent(
                        "What are you craving today?",
                        showActions: true,
                      );
                    },
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
                    child: AbsorbPointer( // ✅ disable search when offline
                      absorbing: !isOnline,
                      child: GlassSearchBar(
                        controller: _queryCtrl,
                        onSubmit: _generate,
                        onClear: _resetToLoadingFromClear,
                      ),
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/utils/loader.dart';
import '/widgets/shimmer/meal_planner_skeleton.dart';
import '/widgets/navigation/nav.dart';
import '/theme/app_theme.dart';
import '/models/meal_plan.dart';             
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/services/meal_planner_service.dart';
import '/widgets/meal_planner_widgets.dart';

// Rebuilds on sign-in, sign-out, and user switches
final authUserProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.userChanges(),
);

// DI
final mealPlannerServiceProvider =
    Provider<MealPlannerService>((ref) => MealPlannerService());

// Emits (weekLite, progress[0..1])
final weekProvider =
    StreamProvider.family<(MealPlanWeekLite, double), String>((ref, userId) {
  final week = ref.watch(mealPlannerServiceProvider);
  return week.streamWeek2(userId: userId);
});

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});
  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  bool generating = false;

  @override
  void initState() {
    super.initState();
    _pingBackendOnce();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Optional: also try on dependencies to catch route returns
    _pingBackendOnce();
  }

  Future<void> _pingBackendOnce() async {
    final uid = ref.watch(authUserProvider).value?.uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'meal_ping_last_$uid';
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    if (prefs.getString(key) == todayKey) return; // already pinged today

    // fire and forget; no UI
    unawaited(ref.read(mealPlannerServiceProvider).pingBackend(userId: uid));
    await prefs.setString(key, todayKey);
  }

  Future<void> _generateNow() async {
    final uid = ref.watch(authUserProvider).value?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please sign in.')));
      return;
    }
    setState(() => generating = true);
    try {
      await ref.read(mealPlannerServiceProvider).generateWeeklyPlan(userId: uid);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => generating = false);
    }
  }

  Future<void> _scrapPlan(String uid, String planId) async {
    await ref.read(mealPlannerServiceProvider).deletePlan(userId: uid, planId: planId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan deleted.')),
      );
    }
  }

  Future<void> _regeneratePlan(String uid, String planId) async {
    setState(() => generating = true);
    try {
      await ref.read(mealPlannerServiceProvider).regenerateWeek(userId: uid, planId: planId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() => generating = false);
    }
  }

  Future<void> _openRecipe({
    required String recipeId,
    required String? title,
    required int dayIndex,
    required String mealKey,
  }) async {
    final uid = ref.watch(authUserProvider).value?.uid;
    if (uid == null || !mounted) return;

    // Get the current week planId from the stream you already have
    final tuple = ref.read(weekProvider(uid)).valueOrNull;
    if (tuple == null) return;
    final planId = tuple.$1.planId;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Optional: quick loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: loader(
          isDark ? Colors.deepOrangeAccent : Colors.orange,
          70,
          5,
          8,
          500,
        ),
      ),
    );

    try {
      final svc = ref.read(mealPlannerServiceProvider);
      final detail = await svc.fetchRecipeForDayMeal(
        userId: uid,
        planId: planId,
        dayIndex: dayIndex,
        mealKey: mealKey,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading

      if (detail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe not found')),
        );
        return;
      }

      context.push('/recipePage', extra: detail);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open recipe: $e')),
      );
    }
  }

  void _showChangeDay(int dayIndex) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change ${_dayName(dayIndex)}\'s meal plan ?',
                  style: theme.textTheme.titleMedium,
                ),
                SizedBox(height: 12.h),
                ListTile(
                  leading: const Icon(Icons.shuffle_rounded),
                  title: const Text('Swap this day'),
                  subtitle: const Text('Generate new breakfast, lunch and dinner for this day'),
                  onTap: () async {
                    Navigator.pop(context);
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) return;

                    // grab current planId from stream
                    final tuple = ref.read(weekProvider(uid)).valueOrNull;
                    final planId = tuple?.$1.planId;

                    try {
                      await ref.read(mealPlannerServiceProvider).changeDay(
                        userId: uid,
                        dayIndex: dayIndex,
                        planId: planId,  // optional; backend will default if null
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Updated ${_dayName(dayIndex)}')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to change day: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
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
      bottomNavigationBar: CustomNavBar(currentIndex: 4),
      appBar: CustomAppBar(
        title: "Meal Planner",
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
                  'Sign in to generate and view your weekly plan.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor(context).withOpacity(0.7),
                  ),
                ),
              )
            : Consumer(
                builder: (context, ref, _) {
                  final asyncWP = ref.watch(weekProvider(uid));
                  return asyncWP.when(
                    loading: () => const PlannerSliverSkeleton(rows: 7),
                    error: (err, __) => Center(child: Text('Error: $err')),
                    data: (wp) {
                      final week = wp.$1;
                      final hasAny = week.days.isNotEmpty;
                      final range = ref
                          .read(mealPlannerServiceProvider)
                          .weekRangeLabel(week.planId);

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: WeekHeaderCard(
                              title: 'Weekly Meal Plan',
                              subtitle: range,
                              leadingHighlight: true,
                              primaryAction: hasAny
                                  ? ElevatedButton.icon(
                                      onPressed: generating ? null : () => _regeneratePlan(uid, week.planId),
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Regenerate'),
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: generating ? null : _generateNow,
                                      icon: const Icon(Icons.auto_awesome_rounded),
                                      label: const Text('Generate'),
                                    ),
                              secondaryAction: hasAny
                                  ? OutlinedButton.icon(
                                      onPressed: () => _scrapPlan(uid, week.planId),
                                      icon: const Icon(Icons.delete_outline_rounded),
                                      label: const Text('Scrap plan'),
                                    )
                                  : null,
                            ),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                          if (hasAny)
                            SliverList.separated(
                              itemCount: week.days.length,
                              separatorBuilder: (_, __) => SizedBox(height: 10.h),
                              itemBuilder: (context, i) {
                                final d = week.days[i];
                                final date = _dateFor(week.planId, d.dayIndex);
                                final dateLabel = _dateLabel(date);
                                final isToday = _isToday(week.planId, d.dayIndex);

                                final cells = <MealCellLite>[
                                  MealCellLite(
                                    label: 'Breakfast',
                                    id: d.breakfast?.id,
                                    title: d.breakfast?.title,
                                    image: d.breakfast?.image,
                                    onTap: d.breakfast == null
                                        ? null
                                        : () => _openRecipe(
                                              recipeId: d.breakfast!.id,
                                              title: d.breakfast!.title,
                                              dayIndex: d.dayIndex,
                                              mealKey: 'breakfast',
                                            ),
                                  ),
                                  MealCellLite(
                                    label: 'Lunch',
                                    id: d.lunch?.id,
                                    title: d.lunch?.title,
                                    image: d.lunch?.image,
                                    onTap: d.lunch == null
                                        ? null
                                        : () => _openRecipe(
                                              recipeId: d.lunch!.id,
                                              title: d.lunch!.title,
                                              dayIndex: d.dayIndex,
                                              mealKey: 'lunch',
                                            ),
                                  ),
                                  MealCellLite(
                                    label: 'Dinner',
                                    id: d.dinner?.id,
                                    title: d.dinner?.title,
                                    image: d.dinner?.image,
                                    onTap: d.dinner == null
                                        ? null
                                        : () => _openRecipe(
                                              recipeId: d.dinner!.id,
                                              title: d.dinner!.title,
                                              dayIndex: d.dayIndex,
                                              mealKey: 'dinner',
                                            ),
                                  ),
                                ];

                                return DayRowCarousel(
                                  dayLabel: dateLabel,
                                  isToday: isToday,
                                  meals: cells,
                                  onLongPressDay: () => _showChangeDay(d.dayIndex),
                                );
                              },
                            ),
                          SliverToBoxAdapter(child: SizedBox(height: 90.h)),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

// ---------- helpers ----------

bool _isToday(String planIdMonday, int dayIndex) {
  final d = _dateFor(planIdMonday, dayIndex);
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

DateTime _dateFor(String planIdMonday, int dayIndex) {
  final p = planIdMonday.split('-').map(int.parse).toList(); // [year, month, day]
  final mon = DateTime.utc(p[0], p[1], p[2]);
  return mon.add(Duration(days: dayIndex - 1)).toLocal();
}

/// Pretty string like "Monday, 13 August 2025"
String _dateLabel(DateTime d) {
  return DateFormat('EEEE, d MMMM y').format(d);
}

/// Still here if you need weekday-only text elsewhere
String _dayName(int dayIndex) =>
    const ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][dayIndex - 1];

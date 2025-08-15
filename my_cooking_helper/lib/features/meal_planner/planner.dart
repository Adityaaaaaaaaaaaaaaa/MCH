import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import '/models/meal_plan.dart';                  // MealPlanWeekLite, MealLite
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/services/meal_planner_service.dart';
import '/widgets/meal_planner_widgets.dart';

// DI
final mealPlannerServiceProvider =
    Provider<MealPlannerService>((ref) => MealPlannerService());

// Emits (weekLite, progress[0..1])
final weekWithProgressProvider =
    StreamProvider.family<(MealPlanWeekLite, double), String>((ref, userId) {
  final svc = ref.watch(mealPlannerServiceProvider);
  return svc.streamWeekWithProgress(userId: userId);
});

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});
  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  bool generating = false;

  Future<void> _generateNow() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan deleted.')));
    }
  }

  Future<void> _regeneratePlan(String uid, String planId) async {
    setState(() => generating = true);
    try {
      await ref.read(mealPlannerServiceProvider).regenerateWeek(userId: uid, planId: planId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => generating = false);
    }
  }

  // Open full detail: pull from Firestore day doc and navigate
  Future<void> _openRecipe({
    required String recipeId,
    required String? title,
    required int dayIndex,
    required String mealKey, // 'breakfast' | 'lunch' | 'dinner'
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !mounted) return;

    // Get the current week planId from the stream you already have
    final tuple = ref.read(weekWithProgressProvider(uid)).valueOrNull;
    if (tuple == null) return;
    final planId = tuple.$1.planId;

    // Optional: quick loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
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

      // Your GoRouter route accepts RecipeDetail directly (first branch in your screenshot).
      context.push('/recipePage', extra: detail);

      // If you prefer the map form your route also supports:
      // context.push('/recipePage', extra: {'recipe': detail, 'fromHistory': false});
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open recipe: $e')),
      );
    }
  }

  void _showChangeDaySheet(int dayIndex) {
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
                Text('Change ${_dayName(dayIndex)}', style: theme.textTheme.titleMedium),
                SizedBox(height: 12.h),
                ListTile(
                  leading: const Icon(Icons.shuffle_rounded),
                  title: const Text('Swap this day'),
                  subtitle: const Text('Generate new breakfast, lunch and dinner for this day'),
                  onTap: () async {
                    Navigator.pop(context);
                    // (Optional) call your swapDay endpoint when ready
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Swap day ${_dayName(dayIndex)}: coming soon')),
                    );
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
      appBar: CustomAppBar(
        title: "Meal Planner",
        showMenu: false,
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 110.h, 24.w, 24.h),
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
                  final asyncWP = ref.watch(weekWithProgressProvider(uid));
                  return asyncWP.when(
                      loading: () => _WeekHeaderCard(
                        title: 'Weekly Meal Plan',
                        subtitle: 'Breakfast • Lunch • Dinner for 7 days',
                        primaryAction: ElevatedButton.icon(
                          onPressed: generating ? null : _generateNow,
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: const Text('Generate'),
                        ),
                        // no progress bar while loading
                      ),
                    error: (err, __) => Center(child: Text('Error: $err')),
                    data: (wp) {
                      final week = wp.$1;
                      final progress = wp.$2;
                      final hasAny = week.days.isNotEmpty;
                      final range = ref.read(mealPlannerServiceProvider).weekRangeLabel(week.planId);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _WeekHeaderCard(
                            title: 'Weekly Meal Plan',
                            subtitle: range,
                            progress: hasAny ? progress : null,
                            leadingHighlight: true,
                            primaryAction: hasAny
                                ? ElevatedButton.icon(
                                    onPressed: generating
                                        ? null
                                        : () => _regeneratePlan(uid, week.planId),
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
                          SizedBox(height: 12.h),
                          if (hasAny)
                            Expanded(
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: week.days.length,
                                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                                itemBuilder: (context, i) {
                                  final d = week.days[i];
                                  final dateLabel = _dateFor(week.planId, d.dayIndex);
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
                                    dayLabel: '${d.dayName} — $dateLabel',
                                    isToday: isToday,
                                    meals: cells,
                                    onLongPressDay: () => _showChangeDaySheet(d.dayIndex),
                                  );
                                },
                              ),
                            ),
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

// ---------- Header Card (with range, actions, optional progress) ----------

class _WeekHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool leadingHighlight;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final double? progress;

  const _WeekHeaderCard({
    required this.title,
    required this.subtitle,
    this.leadingHighlight = false,
    this.primaryAction,
    this.secondaryAction,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Gather actions (skip nulls)
    final actions = <Widget>[
      if (secondaryAction != null) secondaryAction!,
      if (primaryAction != null) primaryAction!,
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.12),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: avatar + text
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26.r,
                backgroundColor: leadingHighlight
                    ? theme.colorScheme.primary.withOpacity(0.12)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.35),
                child: Icon(Icons.calendar_month_rounded,
                    color: theme.colorScheme.primary),
              ),
              SizedBox(width: 14.w),
              // Make the text take remaining space
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progress (if any)
          if (progress != null) ...[
            SizedBox(height: 12.h),
            LinearProgressIndicator(value: progress == 0 ? null : progress),
          ],

          // Actions under the header, right-aligned, wrapping when needed
          if (actions.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600), // keeps buttons tidy on tablets
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: actions,
                ),
              ),
            ),
          ],
        ],
      ),
    ).asGlass(
      blurX: 20,
      blurY: 20,
      tintColor: Colors.white,
      clipBorderRadius: BorderRadius.circular(24.r),
      frosted: true,
    );
  }
}

// ---------- tiny helpers ----------

bool _isToday(String planIdMonday, int dayIndex) {
  // Compare today (local) to the computed date
  final dStr = _dateFor(planIdMonday, dayIndex);
  final now = DateTime.now();
  final todayStr = '${now.day}/${now.month}';
  return dStr == todayStr;
}

String _dateFor(String planIdMonday, int dayIndex) {
  final p = planIdMonday.split('-').map(int.parse).toList();
  final mon = DateTime.utc(p[0], p[1], p[2]);
  final d = mon.add(Duration(days: dayIndex - 1)).toLocal();
  return '${d.day}/${d.month}';
}

String _dayName(int dayIndex) =>
    const ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][dayIndex - 1];

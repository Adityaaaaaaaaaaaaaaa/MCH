import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
// ignore: unused_import
import '/widgets/navigation/nav.dart';
import '/services/meal_planner_service.dart';

final mealPlannerServiceProvider = Provider<MealPlannerService>((ref) {
  return MealPlannerService();
});


class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  bool loading = false;

  Future<void> _generateMealPlan(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be signed in to generate a meal plan.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final svc = ref.read(mealPlannerServiceProvider);

      print('\x1B[34m[DEBUG] PlannerScreen -> generating plan for uid=$uid\x1B[0m');
      await svc.generateWeeklyPlan(userId: uid);

      // We’ll design the results view later.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal plan request sent.')),
      );
      // Example: navigate to a placeholder route later
      // context.push('/mealPlanResults');
    } catch (e) {
      print('\x1B[34m[DEBUG] PlannerScreen error: $e\x1B[0m');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate meal plan: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: true,
      extendBody: true,
      drawer: CustomDrawer(),
      appBar: CustomAppBar(
        title: "Meal Planner",
        showMenu: false,
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
      ),
      body: Stack(
        children: [
          // --- Background aesthetics (kept consistent) ---
          Positioned(
            top: 40,
            right: 60,
            child: Transform.rotate(
              angle: -0.6,
              child: Image.asset(
                'assets/images/home/salad.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 180,
            left: 40,
            child: Transform.rotate(
              angle: 0.8,
              child: Image.asset(
                'assets/images/home/curry.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 110.h),

                // Headline
                Text(
                  "Plan your week's meals!",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor(context),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'We will use your preferences (diet & allergies) to generate a 7‑day plan.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor(context).withOpacity(0.7),
                  ),
                ),

                SizedBox(height: 36.h),

                // CTA card (glass)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: textColor(context).withOpacity(0.18),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.event_note_rounded,
                          size: 34.sp, color: theme.colorScheme.primary),
                      SizedBox(height: 14.h),
                      Text(
                        'Generate Weekly Meal Plan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textColor(context),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'One tap to create 21 meals (breakfast, lunch, dinner) for the next 7 days.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor(context).withOpacity(0.65),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      loading
                          ? Padding(
                              padding: EdgeInsets.symmetric(vertical: 6.h),
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : ElevatedButton.icon(
                              icon: const Icon(Icons.auto_awesome_rounded),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 28.w, vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.r),
                                ),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 8,
                              ),
                              onPressed: () => _generateMealPlan(context),
                              label: Text(
                                'Generate Now',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                    ],
                  ),
                ).asGlass(
                  blurX: 20,
                  blurY: 20,
                  tintColor: Colors.white,
                  clipBorderRadius: BorderRadius.circular(24.r),
                  frosted: true,
                ),

                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16.sp, color: textColor(context).withOpacity(0.6)),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        'Tip: adjust your diet/allergies in Settings → Preferences.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor(context).withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),

                // Reserved space for results (we’ll add later)
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

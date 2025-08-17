import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Header skeleton for the planner (matches your WeekHeaderCard proportions)
class WeekHeaderSkeleton extends StatelessWidget {
  const WeekHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? Colors.deepPurple[800]! : Colors.deepPurple[100]!;
    final highlightColor = isDark ? Colors.deepPurple[400]! : Colors.deepPurple[50]!;
    final blockColor = isDark ? Colors.deepPurple[700]! : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          color: blockColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar circle
                Container(
                  width: 52.r,
                  height: 52.r,
                  decoration: BoxDecoration(
                    color: blockColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 14.w),
                // Title + subtitle bars
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(width: 160.w, height: 18.h, blockColor: blockColor, radius: 8.r),
                      SizedBox(height: 8.h),
                      _bar(width: 120.w, height: 14.h, blockColor: blockColor, radius: 8.r),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Actions row (two buttons)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _roundedButton(width: 130.w, height: 40.h, blockColor: blockColor),
                  _outlinedButton(width: 120.w, height: 40.h, blockColor: blockColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({
    required double width,
    required double height,
    required Color blockColor,
    double radius = 10,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: blockColor, borderRadius: BorderRadius.circular(radius)),
    );
  }

  Widget _roundedButton({required double width, required double height, required Color blockColor}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }

  Widget _outlinedButton({required double width, required double height, required Color blockColor}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: blockColor.withOpacity(0.6), width: 1),
      ),
    );
  }
}

/// One day-row skeleton with three large horizontal meal cards (carousel look)
class DayRowCarouselSkeleton extends StatelessWidget {
  final String titleHint; // e.g. "Monday — 12/8" (only used to size the bar nicely)

  const DayRowCarouselSkeleton({super.key, required this.titleHint});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? Colors.deepPurple[800]! : Colors.deepPurple[100]!;
    final highlightColor = isDark ? Colors.deepPurple[400]! : Colors.deepPurple[50]!;
    final blockColor = isDark ? Colors.deepPurple[700]! : Colors.white;

    // approximate title width from hint length (just for visual variety)
    final titleWidth = (titleHint.length * 8).toDouble().clamp(140, 240);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          color: blockColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day title bar
            Container(
              width: titleWidth.toDouble(),
              height: 18.h,
              decoration: BoxDecoration(
                color: blockColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(height: 12.h),
            // Horizontal list of 3 meal cards
            SizedBox(
              height: 132.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (_, __) => _mealCardSkeleton(blockColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealCardSkeleton(Color blockColor) {
    return Container(
      width: 240.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: blockColor,
      ),
      child: Row(
        children: [
          // Image thumb
          Container(
            width: 92.w,
            height: 92.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: blockColor,
            ),
          ),
          SizedBox(width: 12.w),
          // Two lines of text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(width: 60.w, height: 10.h, blockColor: blockColor, radius: 6.r),
                SizedBox(height: 8.h),
                _bar(width: 150.w, height: 14.h, blockColor: blockColor, radius: 8.r),
                SizedBox(height: 6.h),
                _bar(width: 120.w, height: 14.h, blockColor: blockColor, radius: 8.r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar({
    required double width,
    required double height,
    required Color blockColor,
    double radius = 10,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: blockColor, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

/// Full-page skeleton (header + N day rows)
class PlannerPageSkeleton extends StatelessWidget {
  final int rows;
  const PlannerPageSkeleton({super.key, this.rows = 5});

  @override
  Widget build(BuildContext context) {
    final labels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const WeekHeaderSkeleton(),
        SizedBox(height: 12.h),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            itemCount: rows,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (context, i) =>
                DayRowCarouselSkeleton(titleHint: '${labels[i % labels.length]} — 00/00'),
          ),
        ),
      ],
    );
  }
}

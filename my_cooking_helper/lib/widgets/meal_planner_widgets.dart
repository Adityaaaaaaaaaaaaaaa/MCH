import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DayRowCarousel extends StatelessWidget {
  final String dayLabel;            // e.g. "Monday — Aug 18"
  final bool isToday;               // highlight row if true
  final List<MealCellLite> meals;   // 3 items: breakfast, lunch, dinner
  final VoidCallback? onLongPressDay;

  const DayRowCarousel({
    super.key,
    required this.dayLabel,
    required this.meals,
    this.isToday = false,
    this.onLongPressDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isToday
        ? theme.colorScheme.primary.withOpacity(0.35)
        : theme.colorScheme.outline.withOpacity(0.15);
    final bg = isToday
        ? theme.colorScheme.primary.withOpacity(0.06)
        : theme.colorScheme.surface.withOpacity(0.6);

    return GestureDetector(
      onLongPress: onLongPressDay,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          color: bg,
          border: Border.all(color: borderColor, width: isToday ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dayLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              height: 132.h, // bigger tiles
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: meals.length,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (context, i) => MealCardLarge(meal: meals[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MealCellLite {
  final String label;         // Breakfast | Lunch | Dinner
  final String? id;
  final String? title;
  final String? image;
  final VoidCallback? onTap;

  MealCellLite({
    required this.label,
    this.id,
    this.title,
    this.image,
    this.onTap,
  });
}

class MealCardLarge extends StatelessWidget {
  final MealCellLite meal;
  const MealCardLarge({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMeal = (meal.id != null);

    return InkWell(
      onTap: hasMeal ? meal.onTap : null,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: 240.w, // large card
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: SizedBox(
                width: 92.w,
                height: 92.w,
                child: (hasMeal && (meal.image ?? '').isNotEmpty)
                    ? Image.network(meal.image!, fit: BoxFit.cover)
                    : Container(
                        color: theme.colorScheme.surface.withOpacity(0.6),
                        child: Icon(Icons.image_not_supported_outlined,
                            size: 28, color: theme.hintColor),
                      ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breakfast/Lunch/Dinner label
                  Text(
                    meal.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    hasMeal ? (meal.title ?? '') : '—',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (hasMeal) const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

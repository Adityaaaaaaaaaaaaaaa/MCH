import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecipePageSkeleton extends StatelessWidget {
  const RecipePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use neutral greys and adaptive purples for shimmer
    final baseColor = isDark ? Colors.deepPurple[800]! : Colors.deepPurple[100]!;
    final highlightColor = isDark ? Colors.deepPurple[400]! : Colors.deepPurple[50]!;

    Color blockColor = isDark ? Colors.deepPurple[700]! : Colors.white;

    return Padding(
      padding: EdgeInsets.only(top: 120.h),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                margin: EdgeInsets.all(10.w),
                height: 180.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Container(
                      width: 180.w,
                      height: 28.h,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    // Summary
                    Container(
                      width: double.infinity,
                      height: 54.h,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    // Chips (Dish type, Servings)
                    Row(
                      children: [
                        Container(
                          width: 72.w,
                          height: 28.h,
                          decoration: BoxDecoration(
                            color: blockColor,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Container(
                          width: 54.w,
                          height: 28.h,
                          decoration: BoxDecoration(
                            color: blockColor,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 22.h),
                    // Ingredients section header
                    Container(
                      width: 110.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    // Ingredient items
                    ...List.generate(4, (i) => Container(
                      width: double.infinity,
                      height: 16.h,
                      margin: EdgeInsets.only(bottom: 7.h),
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    )),
                    SizedBox(height: 18.h),
                    // Instructions section header
                    Container(
                      width: 120.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    // Instruction items
                    ...List.generate(3, (i) => Container(
                      width: double.infinity,
                      height: 16.h,
                      margin: EdgeInsets.only(bottom: 7.h),
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    )),
                    SizedBox(height: 18.h),
                    // Youtube Videos section header
                    Container(
                      width: 120.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    // Video thumbnails
                    ...List.generate(2, (i) => Container(
                      width: double.infinity,
                      height: 80.h,
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                    )),
                    SizedBox(height: 15.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

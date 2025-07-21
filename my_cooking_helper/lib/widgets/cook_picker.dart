import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import '/utils/colors.dart';

Future<int?> pickCookingTime(BuildContext context, {int initial = 30}) {
  int tmpTime = initial;
  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: bgColor(context),
        child: Container(
          width: 320.w,
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 15.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.r),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.blueGrey.withOpacity(0.20),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 34,
                offset: Offset(0, 10.h),
              )
            ],
            border: Border.all(
              color: Colors.tealAccent.withOpacity(0.5),
              width: 1.2.w,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How much time do you have?', 
                style: TextStyle(
                  fontSize: 18.sp, 
                  color: textColor(context), 
                  fontWeight: FontWeight.w700
                )
              ),
              SizedBox(height: 20.h),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150.w,
                    height: 70.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(15.r),
                      gradient: LinearGradient(
                        colors: [
                          Colors.redAccent.withOpacity(0.3),
                          Colors.blueAccent.withOpacity(0.3)
                        ],
                      ),
                    ),
                  ),
                  Text(
                    tmpTime >= 60
                      ? '${tmpTime ~/ 60}h ${tmpTime % 60 > 0 ? '${tmpTime % 60}m' : ''}'
                      : '$tmpTime min',
                    style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor(context),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
                SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.h,
                  activeTrackColor: Colors.blue.shade200,
                  inactiveTrackColor: Colors.tealAccent.shade100,
                  thumbColor: Colors.teal.shade400,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.sp),
                  overlayColor: Colors.blueGrey.shade100,
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 15.sp),
                  valueIndicatorColor: Colors.grey,
                  valueIndicatorTextStyle: TextStyle(fontSize: 15.sp, color: Colors.white),
                ),
                child: Column(
                  children: [
                    Slider(
                      min: 15,
                      max: 180,
                      divisions: 11, // 15 min steps: 15, 30, ..., 180
                      value: tmpTime.toDouble().clamp(15, 180),
                      label: '${tmpTime ~/ 60}h ${tmpTime % 60}m',
                      onChanged: (val) => setState(() => tmpTime = ((val ~/ 15) * 15).clamp(15, 180)),
                    ),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent.shade100,
                      textStyle: TextStyle(fontSize: 15.sp),
                    ),
                    onPressed: () => Navigator.pop(ctx, null),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: 15.w),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                      backgroundColor: Colors.tealAccent.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx, tmpTime),
                    child: Text('OK', style: TextStyle(fontSize: 15.sp)),
                  ),
                ],
              ),
            ],
          ),
        ).asGlass(
          blurX: 18,
          blurY: 18,
          tintColor: Colors.white,
          clipBorderRadius: BorderRadius.circular(28.r),
          frosted: true,
        ),
      ),
    ),
  );
}

Future<Set<String>?> selectIngredients(
  BuildContext context,
  List<String> initialIngredients,
) {
  final Set<String> unwanted = {};
  return showDialog<Set<String>>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400.w,
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 15.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.r),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.blueGrey.withOpacity(0.20),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.tealAccent.withOpacity(0.5),
              width: 1.2.w,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 0.70 * MediaQuery.of(context).size.height,
              minHeight: 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Select Ingredients",
                  style: TextStyle(
                    fontSize: 21.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor(context),
                  ),
                ),
                SizedBox(height: 18.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      alignment: WrapAlignment.center, // <-- Center the chips
                      spacing: 5.w, // chip gap
                      runSpacing: 5.h,
                      children: [
                        for (final ing in initialIngredients)
                          GestureDetector(
                            onTap: () => setState(() {
                              if (unwanted.contains(ing)) {
                                unwanted.remove(ing);
                              } else {
                                unwanted.add(ing);
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 170),
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w, //chip size
                                vertical: 5.h,
                              ),
                              margin: EdgeInsets.symmetric(vertical: 2.h),
                              decoration: BoxDecoration(
                                color: unwanted.contains(ing)
                                    ? Colors.redAccent.shade100
                                    : Colors.greenAccent.shade100,
                                borderRadius: BorderRadius.circular(12.r), //chip border
                                border: Border.all(
                                  color: unwanted.contains(ing)
                                      ? Colors.red.shade900
                                      : Colors.green.shade900,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    unwanted.contains(ing)
                                        ? Icons.close_rounded
                                        : Icons.check_circle_rounded,
                                    color: unwanted.contains(ing)
                                        ? Colors.red[50]
                                        : Colors.white,
                                    size: 12.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    ing,
                                    style: TextStyle(
                                      color: unwanted.contains(ing)
                                          ? Colors.red[50]
                                          : Colors.black,
                                      fontSize: 11.sp, //chip font size
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ).asGlass(
                              tintColor: unwanted.contains(ing)
                                  ? Colors.red.shade100
                                  : Colors.green.shade100,
                              blurX: 10,
                              blurY: 10,
                              clipBorderRadius: BorderRadius.circular(12.r),
                              frosted: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent.shade100,
                        textStyle: TextStyle(fontSize: 15.sp),
                      ),
                      onPressed: () => Navigator.pop(ctx, null),
                      child: const Text("Cancel"),
                    ),
                    SizedBox(width: 16.w),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        backgroundColor: Colors.tealAccent.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx, unwanted),
                      child: Text("Proceed", style: TextStyle(fontSize: 15.sp)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).asGlass(
          blurX: 17,
          blurY: 17,
          tintColor: Colors.white.withOpacity(0.09),
          clipBorderRadius: BorderRadius.circular(20.r),
          frosted: true,
        ),
      ),
    ),
  );
}
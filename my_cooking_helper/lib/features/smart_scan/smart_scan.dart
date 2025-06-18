import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/scan_action_button.dart';
import '/widgets/navigation/drawer.dart';
import '/widgets/navigation/nav.dart';

class SmartScan extends StatelessWidget {
  const SmartScan({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      drawer: CustomDrawer(),
      bottomNavigationBar: CustomNavBar(currentIndex: 1),
      appBar: CustomAppBar(
        title: "Smart Scan",
        height: 100.h,
        borderRadius: 26.r,
        topPadding: 60.h,
      ),
      backgroundColor: bgColor(context),
      body: Stack(
        children: [
          // BACKGROUND IMAGES 
          Positioned(
            top: 110.h,
            left: 30.w,
            child: Transform.rotate(
              angle: -0.15, //radians
              child: Image.asset(
                'assets/images/smartScan/scanFood.png',
                width: 210.w,
                height: 210.h,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 80.h,
            left: 150.w,
            child: Transform.rotate(
              angle: 0.3, 
              child: Image.asset(
                'assets/images/smartScan/manualScan.png',
                width: 300.w,
                height: 300.h,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 65.h,
            right: 200.w,
            child: Transform.rotate(
              angle: -0.15, 
              child: Image.asset(
                'assets/images/smartScan/scanReceipt.png',
                width: 200.w,
                height: 200.h,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // GLASS CARD CONTENT
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 50.h),
                child: Container(
                  width: 250.w, 
                  padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_rounded,
                        size: 50.sp,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "How would you like to add items?",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: textColor(context),
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32.h),
                      ScanActionButton(
                        label: "Scan Food",
                        icon: Icons.fastfood,
                        color: Colors.green,
                        onPressed: () => context.push('/scanFood'),
                      ),
                      SizedBox(height: 20.h),
                      ScanActionButton(
                        label: "Scan Receipt",
                        icon: Icons.receipt_long,
                        color: Colors.deepOrange,
                        onPressed: () => context.push('/scanReceipt'),
                      ),
                      SizedBox(height: 20.h),
                      ScanActionButton(
                        label: "Manual Input",
                        icon: Icons.edit_note_rounded,
                        color: Colors.amber[700],
                        onPressed: () => context.push('/manualInput'),
                      ),
                    ],
                  ),
                )
                .asGlass(
                  blurX: 5,
                  blurY: 5,
                  //tintColor: theme.colorScheme.background.withOpacity(0.26),
                  clipBorderRadius: BorderRadius.circular(30.r),
                  frosted: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

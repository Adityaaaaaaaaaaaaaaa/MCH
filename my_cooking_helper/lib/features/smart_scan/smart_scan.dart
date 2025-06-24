import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/snackbar.dart';
import '/utils/connectivity_provider.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/scan_action_button.dart';
import '/widgets/navigation/drawer.dart';
import '/widgets/navigation/nav.dart';

class SmartScan extends ConsumerStatefulWidget {
  const SmartScan({super.key});

  @override
  ConsumerState<SmartScan> createState() => _SmartScanState();
}

class _SmartScanState extends ConsumerState<SmartScan> {
  bool isOnline = true;
  StreamSubscription<bool>? _statusSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = ref.read(connectivityServiceProvider);

      _statusSubscription = service.onStatusChange.listen((status) {
        SnackbarUtils.alert(
          context,
          status ? "You're online" : "You're offline",
          icon: status ? Icons.wifi : Icons.wifi_off,
          iconColor: status ? Colors.greenAccent : Colors.redAccent,
          typeInfo: status ? TypeInfo.success : TypeInfo.error,
          position: MessagePosition.top,
          duration: 3,
        );

        setState(() => isOnline = status);
      });
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = ref.watch(isOnlineProvider).maybeWhen(
      data: (val) => val,
      orElse: () => true,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      drawer: CustomDrawer(),
      bottomNavigationBar: CustomNavBar(currentIndex: 1),
      appBar: CustomAppBar(
        title: "Smart Scan",
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
      ),
      backgroundColor: bgColor(context),
      body: Stack(
        children: [
          // BACKGROUND IMAGES 
          Positioned(
            top: 110,
            left: 30,
            child: Transform.rotate(
              angle: -0.15, //radians
              child: Image.asset(
                'assets/images/smartScan/scanFood.png',
                width: 210,
                height: 210,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 150,
            child: Transform.rotate(
              angle: 0.3, 
              child: Image.asset(
                'assets/images/smartScan/manualScan.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 65,
            right: 200,
            child: Transform.rotate(
              angle: -0.15, 
              child: Image.asset(
                'assets/images/smartScan/scanReceipt.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // GLASS CARD CONTENT
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(right: 50.0.w, left: 50.w),
                child: Container(
                  width: 300.w, 
                  padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_rounded,
                        size: 50.sp,
                        color: Colors.white,
                      ),
                      SizedBox(height: 15.h),
                      Text(
                        "How would you like to add items?",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: textColor(context),
                          letterSpacing: 0.5,
                          fontSize: 20.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40.h),
                      ScanActionButton(
                        label: "Scan Food",
                        icon: Icons.fastfood_rounded,
                        color: Colors.green,
                        enabled: isOnline,
                        onPressed: () {
                          if (isOnline) {
                            context.push('/scanFood');
                          } else {
                            SnackbarUtils.show(
                              context, 
                              textStyle: TextStyle(
                                fontWeight: FontWeight.w900
                              ),
                              "You are offline, try Manual input !",
                              duration: 1000, 
                              behavior: SnackBarBehavior.floating,
                              icon: Icons.wifi_off,
                              iconColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                              backgroundColor: Colors.grey,
                              width: 250.w,
                            );
                          }
                        },
                      ),
                      SizedBox(height: 20.h),
                      ScanActionButton(
                        label: "Scan Receipt",
                        icon: Icons.receipt_long_rounded,
                        color: Colors.orange,
                        enabled: isOnline,
                        onPressed: () {
                          if (isOnline) {
                            context.push('/scanFood');
                          } else {
                            SnackbarUtils.show(
                              context, 
                              textStyle: TextStyle(
                                fontWeight: FontWeight.w900
                              ),
                              "You are offline, try Manual input !",
                              duration: 1000, 
                              behavior: SnackBarBehavior.floating,
                              icon: Icons.wifi_off,
                              iconColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                              backgroundColor: Colors.grey,
                              width: 250.w,
                            );
                          }
                        },
                      ),
                      SizedBox(height: 20.h),
                      ScanActionButton(
                        label: "Manual Input",
                        icon: Icons.edit_note,
                        color: Colors.amber,
                        onPressed: () => context.push('/manualInput'),
                      ),
                    ],
                  ),
                ).asGlass(
                  blurX: 10,
                  blurY: 10,
                  tintColor: Colors.blueGrey,
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

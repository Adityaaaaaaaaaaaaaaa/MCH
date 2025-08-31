import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/lottie_animation.dart';
import '/services/inventory_service.dart';
import '/utils/snackbar.dart';
import '/widgets/edit_add_item_dialog.dart';
import '/models/item.dart';
import '/utils/colors.dart';
import 'item_controller.dart';
import '/widgets/navigation/appbar.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scannedItems = ref.watch(smartScanControllerProvider);
    final scanController = ref.read(smartScanControllerProvider.notifier);
    final InventoryService _inventoryService = InventoryService();

    final lottieController = LottieAnimationController();

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: CustomAppBar(
        title: "Review Items",
        showMenu: false,
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
      ),
      backgroundColor: bgColor(context),
      body: Stack(
        children: [
          //image la dan downloads.
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
          Column(
            children: [
              SizedBox(height: 120.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 2.h),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    color: theme.cardColor.withOpacity(0.60),
                  ),
                  child: Text(
                    "Review and verify your detected items below before confirming.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(1),
                    ),
                  ),
                ).asGlass(
                  //tintColor: theme.primaryColor.withOpacity(0.11),
                  blurX: 3,
                  blurY: 3,
                  frosted: true,
                  clipBorderRadius: BorderRadius.circular(20.r),
                ),
              ),
              // Swipe hint
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe_left_rounded, color: Colors.white),
                      SizedBox(width: 7.w),
                      Text(
                        "Swipe left to delete an item",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ).asGlass(
                  blurX: 20,
                  blurY: 20,
                  frosted: true,
                  tintColor: Colors.white,
                  clipBorderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: scannedItems.isEmpty
                    ? Center(
                        child: Text(
                          'No items detected yet.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        cacheExtent: MediaQuery.of(context).size.height,
                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                        itemCount: scannedItems.length,
                        itemBuilder: (context, index) {
                          final item = scannedItems[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 2.w),
                            child: Slidable(
                              key: ValueKey(item.itemName + index.toString()),
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                extentRatio: 0.25,
                                children: [
                                  SlidableAction(
                                    onPressed: (context) => scanController.removeItem(index),
                                    backgroundColor: Colors.red[400]!,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_forever_rounded,
                                    label: 'Delete',
                                    borderRadius: BorderRadius.circular(18.r),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: theme.primaryColor.withOpacity(0.11),
                                    width: 1.2.w,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.primaryColor.withOpacity(0.10),
                                      theme.primaryColor.withOpacity(0.07),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.fastfood_rounded,
                                    color: theme.primaryColor,
                                    size: 32.sp,
                                  ),
                                  title: Text(
                                    item.itemName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Quantity: ${item.quantity} ${item.unit ?? ""}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.hintColor,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Text(
                                        'Category: ${item.category}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.hintColor,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                                    tooltip: "Edit",
                                    onPressed: () async {
                                      final edited = await showDialog<ScannedItem>(
                                        context: context,
                                        builder: (_) => EditOrAddItemDialog(item: item),
                                      );
                                      if (edited != null) {
                                        scanController.editItem(index, edited);
                                      }
                                    },
                                  ),
                                ).asGlass(
                                  blurX: 15,
                                  blurY: 15,
                                  tintColor: Colors.blueGrey,
                                  frosted: true,
                                  clipBorderRadius: BorderRadius.circular(15.r),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (scannedItems.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 15.h, top: 0, left: 15.w, right: 15.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.done_rounded, size: 25.sp, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26.r),
                        ),
                        elevation: 9,
                        textStyle: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      label: const Text(
                        'Confirm All',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        try {
                          lottieController.show(
                            context: context,
                            assetPath: 'assets/animations/Animation_upload_cloud.json',
                            backgroundColor: bgColor(context),
                            repeat: true,
                            barrierDismissible: false,
                          );

                          // Convert model list to a list of map
                          final itemsToSave = scannedItems.map((item) => item.toJson()).toList();

                          // Save to Firestore using your service
                          await _inventoryService.addItemsToInventory(itemsToSave);

                          scanController.clearItems();

                          lottieController.hide();

                          SnackbarUtils.show(
                            context, 
                            "Items Added!",
                            duration: 500, 
                            behavior: SnackBarBehavior.floating,
                            icon: Icons.check,
                            iconColor: Colors.lightGreenAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                            textStyle: TextStyle(
                              fontWeight: FontWeight.w900
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                            backgroundColor: Colors.grey,
                            width: 250.w,
                          );
                          context.go('/home');
                        } catch (e) {
                          SnackbarUtils.show(
                            context, 
                            "Error adding items !",
                            duration: 500, 
                            behavior: SnackBarBehavior.floating,
                            icon: Icons.warning_amber_rounded,
                            iconColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                            textStyle: TextStyle(
                              fontWeight: FontWeight.w900
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                            backgroundColor: Colors.grey,
                            width: 250.w,
                          );
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
          Positioned(
            bottom: 90.h,
            right: 25.w,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
                elevation: 13,
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
              ),
              icon: Icon(Icons.add_circle_rounded, color: Colors.white, size: 25.sp),
              label: Text(
                'Add Item',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17.sp,
                ),
              ),
              onPressed: () async {
                final added = await showDialog<ScannedItem>(
                  context: context,
                  builder: (_) => EditOrAddItemDialog(),
                );
                if (added != null) {
                  scanController.addItem(added);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
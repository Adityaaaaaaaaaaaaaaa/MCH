// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/theme/app_theme.dart';
import '/utils/lottie_animation.dart';
import '/services/inventory_service.dart';
import '/utils/snackbar.dart';
import '/widgets/edit_add_item_dialog.dart';
import '/models/item.dart';
import '/utils/colors.dart';
import 'item_controller.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/scan/review_widgets.dart';

class ManualInputScreen extends ConsumerWidget {
  const ManualInputScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allItems = ref.watch(smartScanControllerProvider);
    final manualItems = allItems.where((i) => i.source == "manual_input").toList();
    final controller = ref.read(smartScanControllerProvider.notifier);
    final inventoryService = InventoryService();

    final lottieController = LottieAnimationController();

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: CustomAppBar(
        title: "Manual Input",
        showMenu: false,
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
        themeToggleWidget: ThemeToggleButton(),
      ),
      backgroundColor: bgColor(context),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 110.h),

              // Header (local copy styled like your review header, but with manual text)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 18.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    color: (Theme.of(context).brightness == Brightness.dark)
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    border: Border.all(
                      color: (Theme.of(context).brightness == Brightness.dark)
                          ? Colors.white.withOpacity(0.10)
                          : Colors.black.withOpacity(0.08),
                      width: 1.2.w,
                    ),
                  ),
                  child: Text(
                    "Manually add and review your items below.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor(context),
                      fontWeight: FontWeight.w900,
                      fontSize: 16.sp,
                    ),
                  ),
                ).asGlass(
                  blurX: 8,
                  blurY: 8,
                  frosted: true,
                  tintColor: Colors.indigo,
                  clipBorderRadius: BorderRadius.circular(20.r),
                ),
              ),

              Expanded(
                child: manualItems.isEmpty
                    ? Center(
                        child: Text(
                          'No items added yet.',
                          style: TextStyle(
                            color: textColor(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                          ),
                        ),
                      )
                    : ListView.separated(
                        cacheExtent: MediaQuery.of(context).size.height,
                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                        itemCount: manualItems.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.h),
                        itemBuilder: (context, index) {
                          final item = manualItems[index];

                          return Slidable(
                            key: ValueKey('manual-${item.itemName}-$index'),
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              extentRatio: 0.25,
                              children: [
                                SlidableAction(
                                  onPressed: (context) {
                                    final globalIndex = ref
                                        .read(smartScanControllerProvider)
                                        .indexOf(item);
                                    if (globalIndex >= 0) {
                                      controller.removeItem(globalIndex);
                                    }
                                  },
                                  backgroundColor: Colors.red[400]!,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete_forever_rounded,
                                  label: 'Delete',
                                  borderRadius: BorderRadius.circular(18.r),
                                ),
                              ],
                            ),
                            child: ReviewItemTile(
                              item: item,
                              onDelete: () {
                                final globalIndex = ref
                                    .read(smartScanControllerProvider)
                                    .indexOf(item);
                                if (globalIndex >= 0) {
                                  controller.removeItem(globalIndex);
                                }
                              },
                              onEdit: () async {
                                final edited = await showDialog<ScannedItem>(
                                  context: context,
                                  builder: (_) => EditOrAddItemDialog(item: item, title: "Edit Item"),
                                );
                                if (edited != null) {
                                  final globalIndex = ref
                                      .read(smartScanControllerProvider)
                                      .indexOf(item);
                                  if (globalIndex >= 0) {
                                    controller.editItem(globalIndex, edited);
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),

              if (manualItems.isNotEmpty)
                Padding(
                  // Give right-side space so FAB never overlaps
                  padding: EdgeInsets.only(bottom: 10.h, top: 10.h, left: 15.w, right: 150.w),
                  child: ConfirmAllButton(
                    onPressed: () async {
                      try {
                        lottieController.show(
                          context: context,
                          assetPath: 'assets/animations/Animation_upload_cloud.json',
                          backgroundColor: bgColor(context),
                          repeat: true,
                          barrierDismissible: false,
                        );

                        // Only save manual items
                        final itemsToSave =
                            manualItems.map((item) => item.toJson()).toList();

                        await inventoryService.addItemsToInventory(itemsToSave);

                        // Current logic clears all items; kept as-is per your pattern.
                        // If you want to clear only manual items, we can do a filtered clear.
                        controller.clearItems();

                        lottieController.hide();

                        SnackbarUtils.show(
                          context,
                          "Items Added!",
                          duration: 500,
                          behavior: SnackBarBehavior.floating,
                          icon: Icons.check,
                          iconColor: Colors.lightGreenAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900),
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                          backgroundColor: Colors.grey,
                          width: 200.w,
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900),
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                          backgroundColor: Colors.grey,
                          width: 250.w,
                        );
                      }
                    },
                  ),
                ),
            ],
          ),

          // Add Item button as FAB (consistent with Review screen)
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(right: 10.w, bottom: 10.h),
                child: AddItemFAB(
                  onPressed: () async {
                    final added = await showDialog<ScannedItem>(
                      context: context,
                      builder: (_) => const EditOrAddItemDialog(title: "Add Item"),
                    );
                    if (added != null) {
                      controller.addItem(added);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

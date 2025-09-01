import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        themeToggleWidget: ThemeToggleButton(),
      ),
      backgroundColor: bgColor(context),
      body: Stack(
        children: [
          // Decorative image (kept)
          Positioned(
            top: 110.h,
            left: 30.w,
            child: Transform.rotate(
              angle: -0.15,
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
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
                child: const ReviewHeaderCard(),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
                child: const SwipeHintChip(),
              ),

              SizedBox(height: 10.h),

              Expanded(
                child: scannedItems.isEmpty
                    ? Center(
                        child: Text(
                          'No items detected yet.',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                          ),
                        ),
                      )
                    : ListView.separated(
                        cacheExtent: MediaQuery.of(context).size.height,
                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                        itemCount: scannedItems.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.h),
                        itemBuilder: (context, index) {
                          final item = scannedItems[index];
                          return Slidable(
                            key: ValueKey('${item.itemName}-$index'),
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              extentRatio: 0.25,
                              children: [
                                SlidableAction(
                                  onPressed: (context) => scanController.removeItem(index),
                                  backgroundColor: const Color(0xFFE35B66),
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete_forever_rounded,
                                  label: 'Delete',
                                  borderRadius: BorderRadius.circular(18.r),
                                ),
                              ],
                            ),
                            child: ReviewItemTile(
                              item: item,
                              onDelete: () => scanController.removeItem(index),
                              onEdit: () async {
                                final edited = await showDialog<ScannedItem>(
                                  context: context,
                                  builder: (_) => EditOrAddItemDialog(item: item),
                                );
                                if (edited != null) {
                                  scanController.editItem(index, edited);
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),

              if (scannedItems.isNotEmpty)
                Padding(
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

                        final itemsToSave = scannedItems.map((item) => item.toJson()).toList();
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
                          textStyle: const TextStyle(fontWeight: FontWeight.w900),
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                          backgroundColor: Colors.grey,
                          width: 250.w,
                        );
                        context.go('/home'); // keeping your original nav behavior
                      } catch (e) {
                        SnackbarUtils.show(
                          context,
                          "Error adding items !",
                          duration: 500,
                          behavior: SnackBarBehavior.floating,
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
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
        ],
      ),

      // Add button as FAB so it doesn't disturb the page layout
      floatingActionButton: AddItemFAB(
        onPressed: () async {
          final added = await showDialog<ScannedItem>(
            context: context,
            builder: (_) => const EditOrAddItemDialog(),
          );
          if (added != null) {
            ref.read(smartScanControllerProvider.notifier).addItem(added);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
    );
  }
}

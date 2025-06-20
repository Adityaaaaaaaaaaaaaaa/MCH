import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/services/inventory_service.dart';
import '/utils/snackbar.dart';
import '/widgets/edit_add_item_dialog.dart';
import '/models/item.dart';
import '/utils/colors.dart';
import 'item_controller.dart';
import '/widgets/navigation/appbar.dart';

class ManualInputScreen extends ConsumerWidget {
  const ManualInputScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final manualItems = ref.watch(smartScanControllerProvider)
      .where((item) => item.source == "manual_input")
      .toList();
    final controller = ref.read(smartScanControllerProvider.notifier);
    final InventoryService inventoryService = InventoryService();

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: CustomAppBar(
        title: "Manual Input",
        showMenu: false,
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
      ),
      backgroundColor: bgColor(context),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 110.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                child: Container(
                  width: 300.w,
                  padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    color: theme.cardColor.withOpacity(0.60),
                  ),
                  child: Text(
                    "Manually add and review your items below.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 10.sp,
                      color: textColor(context),
                    ),
                  ),
                ).asGlass(
                  blurX: 10,
                  blurY: 10,
                  frosted: true,
                  clipBorderRadius: BorderRadius.circular(20.r),
                ),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: manualItems.isEmpty
                    ? Center(
                        child: Text(
                          'No items added yet.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                        itemCount: manualItems.length,
                        itemBuilder: (context, index) {
                          final item = manualItems[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 2.w),
                            child: Slidable(
                              key: ValueKey(item.itemName + index.toString()),
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                extentRatio: 0.25,
                                children: [
                                  SlidableAction(
                                    onPressed: (context) => controller.removeItem(
                                        ref.read(smartScanControllerProvider)
                                           .indexOf(item)), // Remove using global index
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
                                    Icons.edit_note_rounded,
                                    color: Colors.white,
                                    size: 30.sp,
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
                                        // Find the global index in the provider
                                        final idx = ref.read(smartScanControllerProvider).indexOf(item);
                                        controller.editItem(idx, edited);
                                      }
                                    },
                                  ),
                                ).asGlass(
                                  blurX: 15,
                                  blurY: 15,
                                  tintColor: Colors.white,
                                  frosted: true,
                                  clipBorderRadius: BorderRadius.circular(15.r),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (manualItems.isNotEmpty)
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
                          // Convert to list of maps
                          final itemsToSave = manualItems.map((item) => item.toJson()).toList();

                          // Save to Firestore
                          await inventoryService.addItemsToInventory(itemsToSave);

                          // Clear only manual input items
                          controller.clearItems();

                          SnackbarUtils.show(
                            context, 
                            "Items Added!",
                            duration: 500, 
                            behavior: SnackBarBehavior.floating,
                            icon: Icons.check,
                            iconColor: Colors.lightGreenAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
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
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.r),
                          );
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
          //Add Item button
          Positioned(
            bottom: 110.h,
            right: 25.w,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shadowColor: Colors.transparent,
                elevation: 100,
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
              ),
              icon: Icon(
                Icons.add_circle_rounded, 
                color: Colors.white, 
                size: 20.sp
              ),
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
                  controller.addItem(added);
                }
              },
            ).asGlass(
              blurX: 30,
              blurY: 30,
              frosted: true,
              tintColor: Colors.blueGrey,
              clipBorderRadius: BorderRadius.circular(15.r),
            ),
          ),
        ],
      ),
    );
  }
}

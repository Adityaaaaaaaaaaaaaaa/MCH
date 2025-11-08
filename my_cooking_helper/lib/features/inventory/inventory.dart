import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass/glass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import '/theme/app_theme.dart';
import '/utils/snackbar.dart';
import '/utils/connectivity_provider.dart';
import '/models/item.dart';
import '/widgets/edit_add_item_dialog.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/widgets/navigation/nav.dart';
import '/widgets/inventory_widgets.dart';
import 'inventory_controller.dart';
import 'inventory_sort.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});
  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  List<String> selectedIds = [];
  bool deleteMode = false;
  String sortBy = "default";

  List<Map<String, dynamic>> sortInventory(List<Map<String, dynamic>> items) {
    switch (sortBy) {
      case "name":
        items.sort((a, b) => (a["itemName"] ?? '').toString().compareTo((b["itemName"] ?? '').toString()));
        break;
      case "quantity":
        items.sort((a, b) => ((a["quantity"] ?? 0) as num).compareTo((b["quantity"] ?? 0) as num));
        break;
      case "category":
        items.sort((a, b) => (a["category"] ?? '').toString().compareTo((b["category"] ?? '').toString()));
        break;
      default:
        break;
    }
    return items;
  }

  Future<void> _refreshInventory() async {
    final online = ref.read(isOnlineProvider).maybeWhen(
      data: (v) => v, orElse: () => true,
    );
    if (!online) {
      SnackbarUtils.alert(context, "Offline — showing cached items");
      return;
    }
    await ref.read(inventoryControllerProvider.notifier).refreshFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inventoryControllerProvider);
    final sortedItems = sortInventory(List<Map<String, dynamic>>.from(items));

    ref.listen<AsyncValue<bool>>(isOnlineProvider, (prev, next) {
      next.whenOrNull(data: (online) {
        final prevVal = prev?.value;
        if (prevVal == online) return;
        if (!mounted) return;
        SnackbarUtils.alert(
          context,
          online ? "You're online" : "You're offline",
          icon: online ? Icons.wifi : Icons.wifi_off,
          iconColor: online ? Colors.greenAccent : Colors.redAccent,
          typeInfo: online ? TypeInfo.success : TypeInfo.error,
          position: MessagePosition.top,
          duration: 3,
        );
      });
    });

    final isOnline = ref.watch(isOnlineProvider).maybeWhen(
      data: (v) => v, orElse: () => true,
    );

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: true,
      extendBody: true,
      drawer: CustomDrawer(),
      bottomNavigationBar: CustomNavBar(currentIndex: 0),
      appBar: CustomAppBar(
        title: "Inventory",
        showMenu: true,
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
        themeToggleWidget: ThemeToggleButton(),
      ),
      body: LiquidPullToRefresh(
        showChildOpacityTransition: false,
        onRefresh: _refreshInventory,
        springAnimationDurationInMilliseconds: isOnline ? 1000 : 500,
        animSpeedFactor: 1,
        borderWidth: 2.5.w,
        color: isOnline ? const Color(0xFF2DB36B) : Colors.redAccent,
        backgroundColor: bgColor(context),
        height: 260.h,
        child: Column(
          children: [
            // Sort Bar
            Padding(
              padding: EdgeInsets.only(top: 120.h, right: 15.w, left: 15.w, bottom: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    child: InventorySortBar(
                      sortBy: sortBy,
                      onSort: (s) => setState(() => sortBy = s),
                    ),
                  ).asGlass(
                    blurX: 10,
                    blurY: 10,
                    frosted: true,
                    tintColor: Colors.transparent,
                    clipBorderRadius: BorderRadius.circular(12.r),
                  ),
                ],
              ),
            ),
            // Grid
            Expanded(
              child: GridView.builder(
                cacheExtent: MediaQuery.of(context).size.height,
                padding: EdgeInsets.only(right: 12.w, left: 12.w, top: 6.h, bottom: 100.h),
                itemCount: sortedItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.64,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                ),
                itemBuilder: (context, idx) {
                  final item = sortedItems[idx];
                  return InventoryTile(
                    imageUrl: item["imageUrl"] ?? "",
                    itemName: item["itemName"] ?? "",
                    quantity: (item["quantity"] ?? "1").toString(),
                    unit: (item["unit"] ?? "").toString(),
                    category: (item["category"] ?? "").toString(),
                    isSelected: deleteMode && selectedIds.contains(item["id"]),
                    isOnline: isOnline,
                    onTap: () async {
                      if (deleteMode) {
                        setState(() {
                          if (selectedIds.contains(item["id"])) {
                            selectedIds.remove(item["id"]);
                          } else {
                            selectedIds.add(item["id"]);
                          }
                        });
                      } else {
                        final itemObj = ScannedItem.fromJson(item);
                        final edited = await showDialog<ScannedItem>(
                          context: context,
                          builder: (_) => EditOrAddItemDialog(item: itemObj, title: "Edit Ingredient"),
                        );
                        if (edited != null) {
                          final map = edited.toJson();
                          map['dateAdded'] = item['dateAdded'];
                          await ref.read(inventoryControllerProvider.notifier)
                            .addOrUpdateItem(map, previousId: item['id']);
                        }
                      }
                    },
                    onLongPress: () {
                      setState(() {
                        deleteMode = true;
                        if (!selectedIds.contains(item["id"])) {
                          selectedIds.add(item["id"]);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: deleteMode
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  onPressed: () async {
                    await ref.read(inventoryControllerProvider.notifier).deleteItems(selectedIds);
                    setState(() {
                      deleteMode = false;
                      selectedIds.clear();
                    });
                  },
                  backgroundColor: Colors.redAccent,
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete"),
                ),
                SizedBox(width: 12.w),
                FloatingActionButton.extended(
                  onPressed: () => setState(() {
                    deleteMode = false;
                    selectedIds.clear();
                  }),
                  backgroundColor: Colors.grey[700],
                  icon: const Icon(Icons.close),
                  label: const Text("Cancel"),
                ),
              ],
            )
          : FloatingActionButton.extended(
              onPressed: () async {
                final added = await showDialog<ScannedItem>(
                  context: context,
                  builder: (_) => const EditOrAddItemDialog(title: "Add Ingredient"),
                );
                if (added != null) {
                  final map = added.toJson();
                  map['source'] = 'manual_ingreident_input';
                  await ref.read(inventoryControllerProvider.notifier).addOrUpdateItem(map);
                }
              },
              backgroundColor: const Color(0xFF5B5BD6),
              icon: const Icon(Icons.add),
              label: const Text("Add"),
            ),
    );
  }
}

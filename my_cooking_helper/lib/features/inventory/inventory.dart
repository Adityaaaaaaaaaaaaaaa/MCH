import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass/glass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import '../../utils/snackbar.dart';
import '/utils/connectivity_provider.dart';
import '/models/item.dart';
import '/widgets/edit_add_item_dialog.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/widgets/navigation/nav.dart';
import '/widgets/inventory_tile.dart';
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
  bool isOnline = true; 
  StreamSubscription<bool>? _statusSubscription;

  List<Map<String, dynamic>> sortInventory(List<Map<String, dynamic>> items) {
    switch (sortBy) {
      case "name": items.sort((a, b) => a["itemName"].compareTo(b["itemName"])); break;
      case "quantity": items.sort((a, b) => (a["quantity"] as num).compareTo(b["quantity"] as num)); break;
      case "category": items.sort((a, b) => a["category"].compareTo(b["category"])); break;
      default: break;
    }
    return items;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = ref.read(connectivityServiceProvider);

      _statusSubscription = service.onStatusChange.listen((isOnline) {
        SnackbarUtils.alert(
          context,
          isOnline ? "You're online" : "You're offline",
          icon: isOnline ? Icons.wifi : Icons.wifi_off,
          iconColor: isOnline ? Colors.greenAccent : Colors.redAccent,
          typeInfo: isOnline ? TypeInfo.success : TypeInfo.error,
          position: MessagePosition.top,
          duration: 3,
        );
        setState(() => this.isOnline = isOnline);
      });
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshInventory() async {
    // This should trigger a Firestore sync on pull-down
    await ref.read(inventoryControllerProvider.notifier).refreshFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inventoryControllerProvider);
    final sortedItems = sortInventory(List<Map<String, dynamic>>.from(items));

    final isOnline = ref.watch(isOnlineProvider).maybeWhen(
      data: (val) => val,
      orElse: () => true,
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
      ),
      body: LiquidPullToRefresh(
        showChildOpacityTransition: false,
        onRefresh: _refreshInventory,
        springAnimationDurationInMilliseconds: isOnline ? 1000 : 500,
        animSpeedFactor: 1,
        borderWidth: 3.w,
        color: isOnline ? Colors.lightGreen : Colors.redAccent,
        backgroundColor: bgColor(context),
        height: 300.h,
        child: Column(
          children: [
            // Sort Bar at the top
            Padding(
              padding: EdgeInsets.only(top: 120.h, right: 15.w, bottom: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    child: InventorySortBar(
                      sortBy: sortBy,
                      onSort: (s) => setState(() => sortBy = s),
                    ),
                  ).asGlass(
                    blurX: 15,
                    blurY: 15,
                    frosted: true,
                    tintColor: Colors.red,
                    clipBorderRadius: BorderRadius.circular(12.r),
                  ),
                ],
              ),
            ),
            // GridView fills remaining space
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.only(right: 10.w, left: 10.w, top: 10.h, bottom: 90.h),
                itemCount: sortedItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                ),
                itemBuilder: (context, idx) {
                  final item = sortedItems[idx];
                  return InventoryTile(
                    imageUrl: item["imageUrl"] ?? "",
                    itemName: item["itemName"] ?? "",
                    quantity: item["quantity"]?.toString() ?? "1",
                    unit: item["unit"] ?? "",
                    category: item["category"] ?? "",
                    isSelected: deleteMode && selectedIds.contains(item["id"]),
                    isOnline: isOnline,
                      //edit ingredient
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
                          builder: (_) => EditOrAddItemDialog(item: itemObj, title: "Ingredient"),
                        );
                        if (edited != null) {
                          final map = edited.toJson();
                          map['dateAdded'] = item['dateAdded']; // preserve date if you want
                          // Pass both the new data (map) and the old ID (item['id'])
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
                  backgroundColor: Colors.red,
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete"),
                ),
                SizedBox(width: 14.w),
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
            //add ingredient
          : FloatingActionButton.extended(
              onPressed: () async {
                final added = await showDialog<ScannedItem>(
                  context: context,
                  builder: (_) => EditOrAddItemDialog(title: "Ingredient"),
                );
                if (added != null) {
                  // Convert to Map and save using your controller
                  final map = added.toJson();
                  map['source'] = 'manual_ingreident_input';
                  await ref.read(inventoryControllerProvider.notifier)
                    .addOrUpdateItem(map); // No previousId for a new item
                }
              },
              backgroundColor: Colors.deepPurple,
              icon: const Icon(Icons.add),
              label: const Text("Add"),
            ),
    );
  }
}

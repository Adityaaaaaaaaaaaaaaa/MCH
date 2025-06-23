import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass/glass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

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
    _checkConnectivity();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      // results is List<ConnectivityResult>
      final online = results.any((r) => r != ConnectivityResult.none);
      print('\x1B[34m[DEBUG] Connectivity changed: $results (online=$online)\x1B[0m');
      setState(() {
        isOnline = online;
      });
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final online = result != ConnectivityResult.none;
    print('\x1B[34m[DEBUG] Initial Connectivity: $result (online=$online)\x1B[0m');
    setState(() {
      isOnline = online;
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 120.h, right: 15.w,),
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
              Container(
                margin: EdgeInsets.only(top: 5.w, bottom: 90.h),
                decoration: BoxDecoration( //remove whole decoration , keep margin in container
                    border: Border.all(
                    color: Colors.red, //remove apres, just for gap testing sa
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                  physics: const NeverScrollableScrollPhysics(), // Avoid nested scroll
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
                      isOffline: item["offline"] ?? false,
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

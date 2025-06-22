import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass/glass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      body: Column(
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
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20.0.w),
              child: GridView.builder(
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
                      final itemObj = ScannedItem.fromJson(item);
                      final edited = await showDialog<ScannedItem>(
                        context: context,
                        builder: (_) => EditOrAddItemDialog(item: itemObj, title: "Ingredient"),
                      );
                      if (edited != null) {
                        final map = edited.toJson();
                        map['id'] = item['id']; // keep firestore document id so it updates!
                        map['dateAdded'] = item['dateAdded']; // preserve date if you want
                        await ref.read(inventoryControllerProvider.notifier).addOrUpdateItem(map);
                      }
                    },
                    onLongPress: () {
                      setState(() {
                        deleteMode = true;
                        selectedIds = [item["id"]];
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ],
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
                  map['source'] = 'manual_ingreident_input'; // add a source if you want to track origin
                  await ref.read(inventoryControllerProvider.notifier).addOrUpdateItem(map);
                }
              },
              backgroundColor: Colors.deepPurple,
              icon: const Icon(Icons.add),
              label: const Text("Add"),
            ),
    );
  }
}

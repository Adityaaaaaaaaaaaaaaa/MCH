import 'package:flutter/material.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:glass/glass.dart';
//import '/utils/loader.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
//import '/theme/app_theme.dart';
//import '/utils/loader.dart';
import '/widgets/navigation/drawer.dart';
import '/widgets/navigation/nav.dart';
import '/widgets/inventory_tile.dart';
import 'inventory_controller.dart';
import '/widgets/inventory_edit_modal.dart';
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
        height: 100,
        borderRadius: 26,
        topPadding: 60,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 140),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InventorySortBar(sortBy: sortBy, onSort: (s) => setState(() => sortBy = s)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: GridView.builder(
                itemCount: sortedItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
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
                        await showDialog(
                          context: context,
                          builder: (_) => InventoryEditModal(
                            item: item,
                            onSave: (data) => ref.read(inventoryControllerProvider.notifier).addOrUpdateItem(data),
                          ),
                        );
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
                const SizedBox(width: 14),
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
                await showDialog(
                  context: context,
                  builder: (_) => InventoryEditModal(
                    onSave: (data) => ref.read(inventoryControllerProvider.notifier).addOrUpdateItem(data),
                  ),
                );
              },
              backgroundColor: Colors.deepPurple,
              icon: const Icon(Icons.add),
              label: const Text("Add"),
            ),
    );
  }
}

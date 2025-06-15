import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
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
        height: 90,
        borderRadius: 22,
        topPadding: 48,
      ),
      backgroundColor: bgColor(context),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 120),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: theme.cardColor.withOpacity(0.60),
                  ),
                  child: Text(
                    "Manually add and review your items below.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(1),
                    ),
                  ),
                ).asGlass(
                  blurX: 10,
                  blurY: 10,
                  frosted: true,
                  clipBorderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 10),
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
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        itemCount: manualItems.length,
                        itemBuilder: (context, index) {
                          final item = manualItems[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
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
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.primaryColor.withOpacity(0.11),
                                    width: 1.2,
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
                                    color: theme.primaryColor,
                                    size: 32,
                                  ),
                                  title: Text(
                                    item.itemName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Quantity: ${item.quantity} ${item.unit ?? ""}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.hintColor,
                                      fontWeight: FontWeight.w400,
                                    ),
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
                                  clipBorderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (manualItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 30, top: 18, left: 18, right: 18),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.done_rounded, size: 26, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 19, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 9,
                        textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
            bottom: 110,
            right: 25,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                elevation: 13,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              ),
              icon: const Icon(Icons.add_circle_rounded, color: Colors.white, size: 28),
              label: const Text(
                'Add Item',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
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
            ),
          ),
        ],
      ),
    );
  }
}

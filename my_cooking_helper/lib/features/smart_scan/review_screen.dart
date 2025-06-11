import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:glass/glass.dart';
import '/models/item.dart';
import '/utils/colors.dart';
import 'item_controller.dart';
import '/widgets/appbar.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scannedItems = ref.watch(smartScanControllerProvider);
    final scanController = ref.read(smartScanControllerProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: CustomAppBar(
        title: "Review Items",
        showMenu: false,
        height: 90,
        borderRadius: 22,
        topPadding: 48,
      ),
      backgroundColor: bgColor(context),
      body: Stack(
        children: [
          // You can add your background images here, below the content.
          Positioned(
            top: 110,
            left: 30,
            child: Transform.rotate(
              angle: -0.15, //radians
              child: Image.asset(
                'assets/images/smartScan/scanFood.png',
                width: 210,
                height: 210,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 120),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
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
                  clipBorderRadius: BorderRadius.circular(20),
                ),
              ),
              // Swipe hint
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe_left_rounded, color: Colors.white),
                      const SizedBox(width: 7),
                      Text(
                        "Swipe left to delete an item",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
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
                  clipBorderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 10),
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
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        itemCount: scannedItems.length,
                        itemBuilder: (context, index) {
                          final item = scannedItems[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
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
                                    Icons.fastfood_rounded,
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
                                        builder: (_) => EditItemDialog(item: item),
                                      );
                                      if (edited != null) {
                                        scanController.editItem(index, edited);
                                      }
                                    },
                                  ),
                                ).asGlass(
                                  blurX: 15,
                                  blurY: 15,
                                  tintColor: Colors.cyanAccent,
                                  frosted: true,
                                  clipBorderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (scannedItems.isNotEmpty)
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
                      onPressed: () {
                        // TODO: Firestore integration
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Confirm'),
                            content: const Text('Items confirmed! (Later this will save to Firebase.)'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class EditItemDialog extends StatefulWidget {
  final ScannedItem item;
  const EditItemDialog({super.key, required this.item});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late TextEditingController nameController;
  late TextEditingController unitController;
  late double quantity;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.itemName);
    quantity = widget.item.quantity;
    unitController = TextEditingController(text: widget.item.unit ?? "");
  }

  @override
  void dispose() {
    nameController.dispose();
    unitController.dispose();
    super.dispose();
  }

  void _incrementQty() {
    setState(() {
      quantity += 1;
    });
  }

  void _decrementQty() {
    setState(() {
      if (quantity > 1) {
        quantity -= 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: theme.cardColor.withOpacity(0.61),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Edit Item",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle, color: theme.colorScheme.error, size: 30),
                  onPressed: _decrementQty,
                ),
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    controller: TextEditingController(text: quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          quantity = parsed;
                        });
                      }
                    },
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: "Quantity",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.green, size: 30),
                  onPressed: _incrementQty,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: unitController,
              decoration: InputDecoration(
                labelText: "Unit",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final unit = unitController.text.trim().isEmpty
                        ? null
                        : unitController.text.trim();
                    final editedItem = widget.item.copyWith(
                      itemName: name,
                      quantity: quantity,
                      unit: unit,
                      isEdited: true,
                      isReviewed: true,
                    );
                    Navigator.pop(context, editedItem);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ).asGlass(
          blurX: 10,
          blurY: 10,
          frosted: true,
          //tintColor: theme.primaryColor.withOpacity(0.13),
          clipBorderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
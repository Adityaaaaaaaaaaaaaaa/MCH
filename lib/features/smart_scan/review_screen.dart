import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/scanned_item.dart';
import 'smart_scan_controller.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannedItems = ref.watch(smartScanControllerProvider);
    final scanController = ref.read(smartScanControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Detected Items'),
      ),
      body: scannedItems.isEmpty
          ? const Center(child: Text('No items detected yet.'))
          : ListView.builder(
              itemCount: scannedItems.length,
              itemBuilder: (context, index) {
                final item = scannedItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(item.itemName),
                    subtitle: Text(
                        'Quantity: ${item.quantity.toString()} ${item.unit ?? ""}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
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
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            scanController.removeItem(index);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: scannedItems.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  // For now, just show confirmation dialog/snackbar
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Confirm'),
                      content: const Text(
                          'Items confirmed! (Later this will save to Firebase.)'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Confirm All',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
    );
  }
}

// Simple dialog for editing an item (inline editing)
class EditItemDialog extends StatefulWidget {
  final ScannedItem item;
  const EditItemDialog({super.key, required this.item});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late TextEditingController nameController;
  late TextEditingController quantityController;
  late TextEditingController unitController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.itemName);
    quantityController = TextEditingController(text: widget.item.quantity.toString());
    unitController = TextEditingController(text: widget.item.unit ?? "");
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Item Name"),
          ),
          TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Quantity"),
          ),
          TextField(
            controller: unitController,
            decoration: const InputDecoration(labelText: "Unit"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = nameController.text.trim();
            final quantity = double.tryParse(quantityController.text.trim()) ?? 1.0;
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
    );
  }
}

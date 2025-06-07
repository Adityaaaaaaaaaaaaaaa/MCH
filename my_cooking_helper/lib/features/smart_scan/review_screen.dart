import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '/widgets/appbar.dart';
import '/widgets/glassmorphic_card.dart';
import '/models/item.dart';
import 'item_controller.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
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
      backgroundColor: isLight
          ? const Color(0xfff8fafc)
          : const Color(0xff232526),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
                ? [
                    const Color(0xfff8fafc),
                    const Color(0xffa1c4fd).withOpacity(0.13),
                  ]
                : [
                    const Color(0xff232526),
                    const Color(0xff393e46).withOpacity(0.16),
                  ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 130),
            FadeInDown(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassmorphicCard(
                  borderRadius: 22,
                  blur: 12,
                  opacity: 0.21,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  child: Text(
                    "Please review and verify each detected item before confirming.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.primaryColor.withOpacity(0.85),
                    ),
                  ),
                ),
              ),
            ),
            // Swipe hint
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe_left_rounded, color: theme.primaryColor.withOpacity(0.6)),
                  const SizedBox(width: 7),
                  Text(
                    "Swipe left on an item to delete",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: scannedItems.isEmpty
                  ? FadeIn(
                      child: Center(
                        child: Text(
                          'No items detected yet.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      itemCount: scannedItems.length,
                      itemBuilder: (context, index) {
                        final item = scannedItems[index];
                        return SlideInUp(
                          duration: Duration(milliseconds: 320 + index * 100),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            child: Slidable(
                              key: ValueKey(item.itemName + index.toString()),
                              endActionPane: ActionPane(
                                motion: const BehindMotion(),
                                extentRatio: 0.28,
                                children: [
                                  SlidableAction(
                                    onPressed: (context) => scanController.removeItem(index),
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_forever_rounded,
                                    label: 'Delete',
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ],
                              ),
                              child: GlassmorphicCard(
                                borderRadius: 22,
                                blur: 15,
                                opacity: 0.18,
                                padding: const EdgeInsets.all(18),
                                child: ListTile(
                                  leading: Icon(Icons.fastfood_rounded, color: theme.primaryColor, size: 30),
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
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Centered Confirm Button
            if (scannedItems.isNotEmpty)
              FadeInUp(
                duration: const Duration(milliseconds: 700),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30, top: 10, left: 20, right: 20),
                  child: Center(
                    child: GlassmorphicCard(
                      borderRadius: 30,
                      blur: 16,
                      opacity: 0.18,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.done_rounded, size: 26),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          elevation: 9,
                        ),
                        label: const Text(
                          'Confirm All',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
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
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Enhanced dialog for editing an item with glassmorphism
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
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: GlassmorphicCard(
        borderRadius: 26,
        blur: 18,
        opacity: 0.22,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 22),
        child: SingleChildScrollView(
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
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

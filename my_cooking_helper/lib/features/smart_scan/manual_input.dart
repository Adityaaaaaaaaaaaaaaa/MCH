import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '/widgets/appbar.dart';
import '/widgets/glassmorphic_card.dart';
import '/models/item.dart';
import 'item_controller.dart';

class ManualInputScreen extends ConsumerStatefulWidget {
  const ManualInputScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends ConsumerState<ManualInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  void _addItem() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final quantity = double.tryParse(_quantityController.text.trim()) ?? 1.0;
      final unit = _unitController.text.trim().isEmpty ? null : _unitController.text.trim();
      final scannedItem = ScannedItem(
        itemName: name,
        quantity: quantity,
        unit: unit,
        source: "manual_input",
        isReviewed: true,
      );
      ref.read(smartScanControllerProvider.notifier).addItem(scannedItem);
      _nameController.clear();
      _quantityController.clear();
      _unitController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _editItem(int index, ScannedItem item) async {
    final edited = await showDialog<ScannedItem>(
      context: context,
      builder: (_) => EditItemDialog(item: item),
    );
    if (edited != null) {
      ref.read(smartScanControllerProvider.notifier).editItem(index, edited);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final scannedItems = ref.watch(smartScanControllerProvider)
        .where((item) => item.source == "manual_input")
        .toList();

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
            const SizedBox(height: 120),
            FadeInDown(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                child: GlassmorphicCard(
                  borderRadius: 28,
                  blur: 16,
                  opacity: 0.21,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          "Add item manually",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: "Item Name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: "Quantity",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Enter quantity' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _unitController,
                                decoration: InputDecoration(
                                  labelText: "Unit",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        FadeInUp(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add_circle_rounded, size: 22),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                              ),
                              label: const Text(
                                'Add Item',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                              ),
                              onPressed: _addItem,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: scannedItems.isEmpty
                  ? FadeIn(
                      child: Center(
                        child: Text(
                          'No items added yet.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      itemCount: scannedItems.length,
                      itemBuilder: (context, index) {
                        final item = scannedItems[index];
                        return SlideInUp(
                          duration: Duration(milliseconds: 300 + index * 80),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
                            child: Slidable(
                              key: ValueKey(item.itemName + index.toString()),
                              endActionPane: ActionPane(
                                motion: const BehindMotion(),
                                extentRatio: 0.28,
                                children: [
                                  SlidableAction(
                                    onPressed: (context) => ref.read(smartScanControllerProvider.notifier).removeItem(index),
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
                                  leading: Icon(Icons.edit_note_rounded, color: theme.primaryColor, size: 30),
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
                                    onPressed: () => _editItem(index, item),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Confirm Button
            if (scannedItems.isNotEmpty)
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
                        icon: const Icon(Icons.done_rounded, size: 26, color: Colors.white,),
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
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
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

import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import '../utils/colors.dart';
import '/models/item.dart';

class EditOrAddItemDialog extends StatefulWidget {
  final ScannedItem? item; // null for add, not null for edit
  final bool isEdit;

  const EditOrAddItemDialog({Key? key, this.item})
      : isEdit = item != null,
        super(key: key);

  @override
  State<EditOrAddItemDialog> createState() => _EditOrAddItemDialogState();
}

class _EditOrAddItemDialogState extends State<EditOrAddItemDialog> {
  late TextEditingController nameController;
  late TextEditingController unitController;
  late double quantity;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item?.itemName ?? "");
    quantity = widget.item?.quantity ?? 1.0;
    unitController = TextEditingController(text: widget.item?.unit ?? "");
  }

  @override
  void dispose() {
    nameController.dispose();
    unitController.dispose();
    super.dispose();
  }

  void _incrementQty() => setState(() => quantity += 1);
  void _decrementQty() => setState(() { if (quantity > 1) quantity -= 1; });

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
          borderRadius: BorderRadius.circular(22),
          //color: theme.cardColor.withOpacity(0.74),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isEdit ? "Edit Item" : "Add Item",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor(context),
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
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red[300], size: 30),
                    onPressed: _decrementQty,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30),
                    child: TextField(
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      controller: TextEditingController(
                        text: quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null && parsed > 0) setState(() => quantity = parsed);
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
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.green, size: 30),
                    onPressed: _incrementQty,
                  ),
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
                    final unit = unitController.text.trim().isEmpty ? null : unitController.text.trim();
                    if (name.isEmpty) return; // You can show a snackbar for required fields
                    final newItem = ScannedItem(
                      itemName: name,
                      quantity: quantity,
                      unit: unit,
                      isEdited: widget.isEdit,
                      isReviewed: true,
                      source: widget.item?.source ?? "manual_input",
                    );
                    Navigator.pop(context, newItem);
                  },
                  child: Text(widget.isEdit ? 'Save' : 'Add'),
                ),
              ],
            ),
          ],
        ),
      ).asGlass(
          blurX: 15,
          blurY: 15,
          frosted: true,
          clipBorderRadius: BorderRadius.circular(15),
        ),
    );
  }
}

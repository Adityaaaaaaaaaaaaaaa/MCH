import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InventoryEditModal extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Function(Map<String, dynamic>) onSave;
  const InventoryEditModal({super.key, this.item, required this.onSave});

  @override
  State<InventoryEditModal> createState() => _InventoryEditModalState();
}

class _InventoryEditModalState extends State<InventoryEditModal> {
  late TextEditingController nameController;
  late TextEditingController quantityController;
  late TextEditingController unitController;
  String category = "Uncategorized";
  static const List<String> _categories = ['Fruits', 'Vegetables', 'Grains', 'Dairy', 'Protein', 'Uncategorized'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item?['itemName'] ?? "");
    quantityController = TextEditingController(text: widget.item?['quantity']?.toString() ?? "1");
    unitController = TextEditingController(text: widget.item?['unit'] ?? "");

    // Ensure the category matches the _categories list (case-insensitive)
    final incoming = widget.item?['category'] ?? "Uncategorized";
    category = _categories.firstWhere(
      (cat) => cat.toLowerCase() == incoming.toString().toLowerCase(),
      orElse: () => "Uncategorized"
    );
}


  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.item == null ? "Add Ingredient" : "Edit Ingredient",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 12.h),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Quantity"),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: unitController,
              decoration: InputDecoration(labelText: "Unit"),
            ),
            SizedBox(height: 10.h),
            DropdownButtonFormField<String>(
              value: category,
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => category = val!),
              decoration: InputDecoration(labelText: "Category"),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                SizedBox(width: 12.w),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final now = DateTime.now(); // For local, since Firestore uses serverTimestamp
                    final map = {
                      "itemName": nameController.text.trim(),
                      "quantity": double.tryParse(quantityController.text.trim()) ?? 1.0,
                      "unit": unitController.text.trim(),
                      "category": category,
                      "source": widget.item?['source'] ?? 'manual_ingredient_in',
                      "nutritionId": widget.item?['nutritionId'] ?? '',
                      "imageUrl": widget.item?['imageUrl'] ?? '',
                      "dateAdded": widget.item?['dateAdded'] ?? now,
                    };
                    if (widget.item?['id'] != null) map['id'] = widget.item!['id'];
                    Navigator.pop(context);
                    widget.onSave(map);
                  },
                  child: Text(widget.item == null ? "Add" : "Save"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

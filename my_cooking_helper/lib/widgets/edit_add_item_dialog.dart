import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/colors.dart';
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
    _selectedCategory = _normalizeCategory(widget.item?.category) ?? 'Uncategorized';
  }

  @override
  void dispose() {
    nameController.dispose();
    unitController.dispose();
    super.dispose();
  }

  void _incrementQty() => setState(() => quantity += 1);
  void _decrementQty() => setState(() { if (quantity > 1) quantity -= 1; });

  static const List<String> _categories = [
    'Fruits', 'Vegetables', 'Grains', 'Dairy', 'Protein', 'Uncategorized'
  ];
  String? _selectedCategory;

  String? _normalizeCategory(String? category) {
  if (category == null) return null;
  final match = _categories.firstWhere(
    (cat) => cat.toLowerCase() == category.toLowerCase(),
    orElse: () => 'Uncategorized',
  );
  return match;
}


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 24.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
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
            SizedBox(height: 18.h),
            TextField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 20.0.w),
                  child: IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red[300], size: 30.sp),
                    onPressed: _decrementQty,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 30.w, right: 30.w),
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
                  padding: EdgeInsets.only(right: 20.w),
                  child: IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.green, size: 30.sp),
                    onPressed: _incrementQty,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: unitController,
              decoration: InputDecoration(
                labelText: "Unit",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              onChanged: (val) => setState(() => _selectedCategory = val),
              items: _categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              decoration: InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
            SizedBox(height: 26.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                SizedBox(width: 10.w),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final unit = unitController.text.trim().isEmpty ? null : unitController.text.trim();
                    if (name.isEmpty) return; 
                    final newItem = ScannedItem(
                      itemName: name,
                      quantity: quantity,
                      unit: unit,
                      isEdited: widget.isEdit,
                      isReviewed: true,
                      source: widget.item?.source ?? "manual_input",
                      category: _selectedCategory ?? "Uncategorized", 
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
          clipBorderRadius: BorderRadius.circular(15.r),
        ),
    );
  }
}

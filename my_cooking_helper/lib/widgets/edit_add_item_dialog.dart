import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/models/item.dart';

class EditOrAddItemDialog extends StatefulWidget {
  final ScannedItem? item; // null for add, not null for edit
  final bool isEdit;
  final String title; // <-- ADD THIS

  const EditOrAddItemDialog({Key? key, this.item, this.title = "Item"})
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
      insetPadding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
      child: SingleChildScrollView(
        reverse: true,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 2.h),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 25.h, horizontal: 25.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Text(
                widget.isEdit ? "< Edit ${widget.title} >" : "< Add ${widget.title} >",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 27.sp,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: 20.h),
              StatefulBuilder(
                builder: (context, setState) {
                  bool isFilled = nameController.text.trim().isNotEmpty;
                  return TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: "Item Name",
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        borderSide: BorderSide(
                        color: isFilled ? Colors.green : Colors.white,
                        width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        borderSide: BorderSide(
                        color: isFilled ? Colors.green : Colors.blue,
                        width: 2,
                        ),
                      ),
                    ),
                    cursorColor: Colors.white,
                  );
                },
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
                      padding: EdgeInsets.only(left: 20.w, right: 20.w),
                      child: StatefulBuilder(
                        builder: (context, setState) {
                        bool isFilled = quantity > 0;
                        return TextField(
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          controller: TextEditingController(
                          text: quantity.toStringAsFixed(
                            quantity.truncateToDouble() == quantity ? 0 : 2,
                          ),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null && parsed > 0) setState(() => quantity = parsed);
                          },
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
                            labelText: "Quantity",
                            labelStyle: const TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.r),
                              borderSide: BorderSide(
                                color: isFilled ? Colors.green : Colors.white,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.r),
                              borderSide: BorderSide(
                                color: isFilled ? Colors.green : Colors.blue,
                                width: 2,
                              ),
                            ),
                          ),
                          cursorColor: Colors.white,
                        );
                        },
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
              SizedBox(height: 15.h),
              StatefulBuilder(
                builder: (context, setState) {
                  bool isFilled = unitController.text.trim().isNotEmpty;
                  return TextField(
                    controller: unitController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
                      labelText: "Unit",
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        borderSide: BorderSide(
                          color: isFilled ? Colors.green : Colors.white,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        borderSide: BorderSide(
                          color: isFilled ? Colors.green : Colors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                    cursorColor: Colors.white,
                  );
                },
              ),
              SizedBox(height: 20.h),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                onChanged: (val) => setState(() => _selectedCategory = val),
                items: _categories
                  .map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(
                          Icons.double_arrow_rounded,
                          color: Colors.white70,
                          size: 20.sp,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          cat,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                    ))
                  .toList(),
                dropdownColor: Colors.black.withOpacity(0.75),
                icon: Icon(Icons.arrow_drop_down, color: Colors.white70, size: 25.sp),
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
                decoration: InputDecoration(
                  labelText: "Category",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.r),
                    borderSide: BorderSide(
                      color: Colors.blueAccent,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
                ),
                borderRadius: BorderRadius.circular(30.r),
              ),
              SizedBox(height: 25.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
                      ),
                      backgroundColor: Colors.redAccent.withOpacity(0.08),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  StatefulBuilder(
                    builder: (context, setState) {
                      final isActive = nameController.text.trim().isNotEmpty;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? Colors.green : Colors.grey,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: theme.colorScheme.secondary.withOpacity(0.25),
                          padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                        ),
                        onPressed: isActive ? () {
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
                        } : null,
                        child: Text(
                          widget.isEdit ? 'Save' : 'Add',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            fontSize: 16.sp,
                          ),
                        ),
                      );
                    }
                  ),
                ],
              ),
            ],
            ),
          ).asGlass(
            blurX: 15,
            blurY: 15,
            frosted: true,
            tintColor: Colors.black,
            clipBorderRadius: BorderRadius.circular(30.r),
          ),
        ),
      ),
    );
  }
}

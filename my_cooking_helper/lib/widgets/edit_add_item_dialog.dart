// ignore_for_file: deprecated_member_use, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/colors.dart';
import '/models/item.dart';

class EditOrAddItemDialog extends StatefulWidget {
  final ScannedItem? item; // null for add, not null for edit
  final bool isEdit;
  final String title;

  const EditOrAddItemDialog({Key? key, this.item, this.title = "Item"})
      : isEdit = item != null,
        super(key: key);

  @override
  State<EditOrAddItemDialog> createState() => _EditOrAddItemDialogState();
}

class _EditOrAddItemDialogState extends State<EditOrAddItemDialog> {
  // Limits
  static const double _MAX_G = 100000;   // 100 kg
  static const double _MAX_ML = 100000;  // 100 L
  static const int _MAX_COUNT = 999;

  // Controllers/Focus
  late final TextEditingController nameController;
  late final TextEditingController qtyController;
  late final TextEditingController unitController; 
  late final FocusNode qtyFocusNode;

  // Model state
  late double quantity;
  final List<String> _unitChoices = const ['g', 'ml', 'count'];
  late String _unit; // 'g' | 'ml' | 'count'

  static const List<String> _categories = [
    'Fruits', 'Vegetables', 'Grains', 'Dairy', 'Protein', 'Uncategorized'
  ];
  String? _selectedCategory;

  bool _programmaticQtyUpdate = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item?.itemName ?? "");
    quantity = widget.item?.quantity ?? 1.0;

    final rawUnit = (widget.item?.unit ?? 'count').toLowerCase().trim();
    _unit = _unitChoices.contains(rawUnit) ? rawUnit : 'count';
    unitController = TextEditingController(text: _unit);

    _selectedCategory = _normalizeCategory(widget.item?.category) ?? 'Uncategorized';

    _clampQuantity();
    qtyController = TextEditingController(text: _qtyNumberString());
    qtyFocusNode = FocusNode();

    qtyController.addListener(() {
      if (_programmaticQtyUpdate) return;
      final txt = qtyController.text.trim();
      if (txt.isEmpty) return;

      double parsed;
      if (_unit == 'count') {
        parsed = (int.tryParse(txt) ?? 1).toDouble();
      } else {
        parsed = double.tryParse(txt) ?? 1.0;
      }
      setState(() {
        quantity = parsed;
        _clampQuantity();
      });
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    unitController.dispose();
    qtyFocusNode.dispose();
    super.dispose();
  }

  String? _normalizeCategory(String? category) {
    if (category == null) return null;
    final match = _categories.firstWhere(
      (cat) => cat.toLowerCase() == category.toLowerCase(),
      orElse: () => 'Uncategorized',
    );
    return match;
  }

  void _setUnit(String u) {
    setState(() {
      _unit = u;
      unitController.text = u; 
      _clampQuantity();
      _syncQtyTextFromQuantity(); 
    });
  }

  void _clampQuantity() {
    if (_unit == 'g') {
      if (quantity.isNaN || quantity <= 0) quantity = 1;
      if (quantity > _MAX_G) quantity = _MAX_G;
    } else if (_unit == 'ml') {
      if (quantity.isNaN || quantity <= 0) quantity = 1;
      if (quantity > _MAX_ML) quantity = _MAX_ML;
    } else {
      // count
      if (!quantity.isFinite || quantity < 1) quantity = 1;
      if (quantity > _MAX_COUNT) quantity = _MAX_COUNT.toDouble();
      quantity = quantity.roundToDouble();
    }
  }

  void _incrementQty() {
    setState(() {
      quantity += 1;
      _clampQuantity();
      _syncQtyTextFromQuantity();
    });
  }

  void _decrementQty() {
    setState(() {
      if (quantity > 1) quantity -= 1;
      _clampQuantity();
      _syncQtyTextFromQuantity();
    });
  }

  String _qtyNumberString() {
    if (_unit == 'count') return quantity.toInt().toString();
    final isInt = quantity.truncateToDouble() == quantity;
    return isInt ? quantity.toInt().toString() : quantity.toStringAsFixed(2);
  }

  void _syncQtyTextFromQuantity() {
    _programmaticQtyUpdate = true;
    final s = _qtyNumberString();
    qtyController
      ..text = s
      ..selection = TextSelection.fromPosition(TextPosition(offset: s.length));
    _programmaticQtyUpdate = false;
  }

  String _prettyPreview() {
    if (_unit == 'count') return 'x${quantity.toInt()}';
    if (_unit == 'g') {
      if (quantity >= 1000) {
        final kg = quantity / 1000.0;
        final s = (kg % 1 == 0) ? kg.toInt().toString() : kg.toStringAsFixed(1);
        return '$s kg';
      }
      final s = (quantity % 1 == 0) ? quantity.toInt().toString() : quantity.toStringAsFixed(1);
      return '$s g';
    }
    if (_unit == 'ml') {
      if (quantity >= 1000) {
        final l = quantity / 1000.0;
        final s = (l % 1 == 0) ? l.toInt().toString() : l.toStringAsFixed(1);
        return '$s L';
      }
      final s = (quantity % 1 == 0) ? quantity.toInt().toString() : quantity.toStringAsFixed(1);
      return '$s ml';
    }
    return '$quantity $_unit';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final border   = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.10);
    final fill     = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);
    final accent   = isDark ? const Color(0xFF5AB2FF) : const Color(0xFF0E7AE6);
    final okGreen  = isDark ? const Color(0xFF2EAD76) : const Color(0xFF2DB36B);

    final qtyLabel = (_unit == 'count')
        ? "Quantity (count)"
        : _unit == 'g' ? "Quantity (g)" : "Quantity (ml)";

    final List<TextInputFormatter> qtyFormatters =
        (_unit == 'count')
            ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)]
            : [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                LengthLimitingTextInputFormatter(7),
              ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 28.h),
      child: MediaQuery.removeViewInsets(
        removeBottom: true, 
        context: context,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 25.h, horizontal: 25.w),
              decoration: BoxDecoration(
                color: fill,
                border: Border.all(
                  color: isDark? Colors.teal : Colors.white, 
                  width: 1.5
                ),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    widget.isEdit ? "< ${widget.title} >" : "< ${widget.title} >",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22.sp,
                      color: Colors.white,
                      letterSpacing: .2,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Item name
                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Item Name",
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      filled: true,
                      fillColor: fill,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(color: Colors.grey, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(color: accent, width: 1.8),
                      ),
                    ),
                    cursorColor: accent,
                  ),

                  SizedBox(height: 14.h),

                  // Quantity row
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.redAccent, size: 28.sp),
                        onPressed: _decrementQty,
                        splashRadius: 22.r,
                      ),
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          focusNode: qtyFocusNode,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: qtyFormatters,
                          onEditingComplete: () {
                            setState(() {
                              _clampQuantity();
                              _syncQtyTextFromQuantity();
                            });
                            FocusScope.of(context).unfocus();
                          },
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w800, 
                            fontSize: 16.sp
                          ),
                          decoration: InputDecoration(
                            labelText: qtyLabel,
                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                            filled: true,
                            fillColor: fill,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.7), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide(color: accent, width: 1.8),
                            ),
                          ),
                          cursorColor: accent,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: Colors.green, size: 28.sp),
                        onPressed: _incrementQty,
                        splashRadius: 22.r,
                      ),
                    ],
                  ),

                  // Preview
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Preview: ${_prettyPreview()}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7), 
                        fontWeight: FontWeight.w700, 
                        fontSize: 12.5.sp
                      ),
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // Unit chips
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "----- Unit -----",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7), 
                        fontWeight: FontWeight.w900, 
                        fontSize: 13.sp
                      )
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8.w,
                    children: _unitChoices.map((u) {
                      final bool selected = _unit == u;
                      return ChoiceChip(
                        label: Text(u.toUpperCase()),
                        selected: selected,
                        onSelected: (_) => _setUnit(u),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : textColor(context),
                          fontWeight: FontWeight.w800,
                        ),
                        selectedColor: accent.withOpacity(0.90),
                        backgroundColor: fill,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(
                            color: selected ? accent : border,
                            width: 1.5,
                          ),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 25.h),

                  // Category dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    items: _categories.map((cat) {
                      IconData icon;
                      switch (cat) {
                        case 'Fruits': icon = Icons.apple_rounded; break;
                        case 'Vegetables': icon = Icons.eco_rounded; break;
                        case 'Grains': icon = Icons.rice_bowl_rounded; break;
                        case 'Dairy': icon = Icons.icecream_rounded; break;
                        case 'Protein': icon = Icons.set_meal_rounded; break;
                        default: icon = Icons.category_rounded;
                      }
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(icon, size: 18.sp, color: textColor(context)),
                            SizedBox(width: 10.w),
                            Text(cat, style: TextStyle(color: textColor(context), fontWeight: FontWeight.w600, fontSize: 15.sp)),
                          ],
                        ),
                      );
                    }).toList(),
                    dropdownColor: isDark ? const Color(0xFF0F1520) : Colors.white,
                    isDense: true,
                    menuMaxHeight: 300.h,
                    icon: Icon(Icons.arrow_drop_down_rounded, color: textColor(context), size: 26.sp),
                    style: TextStyle(color: textColor(context), fontSize: 15.sp),
                    decoration: InputDecoration(
                      labelText: "Category",
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      filled: true,
                      fillColor: fill,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.6), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(color: accent, width: 1.8),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),

                  SizedBox(height: 20.h),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
                          ),
                          backgroundColor: Colors.redAccent.withOpacity(0.2),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3, fontSize: 16),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: nameController,
                        builder: (_, value, __) {
                          final active = value.text.trim().isNotEmpty;
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: active ? okGreen : Colors.grey,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                            ),
                            onPressed: active
                                ? () {
                                    final name = value.text.trim();
                                    if (name.isEmpty) return;

                                    _clampQuantity();
                                    _syncQtyTextFromQuantity();

                                    final newItem = ScannedItem(
                                      itemName: name,
                                      quantity: quantity,
                                      unit: _unit, // strictly one of g/ml/count
                                      isEdited: widget.isEdit,
                                      isReviewed: true,
                                      source: widget.item?.source ?? "manual_input",
                                      category: _selectedCategory ?? "Uncategorized",
                                    );
                                    Navigator.pop(context, newItem);
                                  }
                                : null,
                            child: Text(
                              widget.isEdit ? 'Save' : 'Add',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                letterSpacing: 0.3, 
                                fontSize: 16.sp,
                                color: textColor(context),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ).asGlass(
              blurX: 10, 
              blurY: 10, 
              frosted: true,
              tintColor: isDark? Colors.transparent : Colors.black,
              clipBorderRadius: BorderRadius.circular(24.r),
            ),
          ),
        ),
      ),
    );
  }
}

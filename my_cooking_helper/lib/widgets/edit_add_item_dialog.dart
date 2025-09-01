import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  // limits (tweak as needed)
  static const double _MAX_G = 100000;   // 100 kg
  static const double _MAX_ML = 100000;  // 100 L
  static const int _MAX_COUNT = 999;

  late TextEditingController nameController;
  late TextEditingController unitController; // kept for compatibility
  late double quantity;

  // unit chips state
  final List<String> _unitChoices = const ['g', 'ml', 'count'];
  late String _unit; // 'g' | 'ml' | 'count'

  static const List<String> _categories = [
    'Fruits', 'Vegetables', 'Grains', 'Dairy', 'Protein', 'Uncategorized'
  ];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item?.itemName ?? "");
    quantity = widget.item?.quantity ?? 1.0;

    // normalise unit
    final rawUnit = (widget.item?.unit ?? 'count').toLowerCase();
    _unit = _unitChoices.contains(rawUnit) ? rawUnit : 'count';

    unitController = TextEditingController(text: _unit); // keep in sync
    _selectedCategory = _normalizeCategory(widget.item?.category) ?? 'Uncategorized';

    // clamp initial quantity
    _clampQuantity();
  }

  @override
  void dispose() {
    nameController.dispose();
    unitController.dispose();
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
      unitController.text = u; // keep controller consistent
      _clampQuantity();
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

  void _incrementQty() => setState(() {
    quantity += 1;
    _clampQuantity();
  });

  void _decrementQty() => setState(() {
    if (_unit == 'count') {
      if (quantity > 1) quantity -= 1;
    } else {
      if (quantity > 1) quantity -= 1;
    }
    _clampQuantity();
  });

  String _prettyPreview() {
    // live preview (kg/L when appropriate)
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
    final theme = Theme.of(context);
    final labelQty = (_unit == 'count')
        ? "Quantity (count)"
        : _unit == 'g' ? "Quantity (g)" : "Quantity (ml)";

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

                // --- Item name -------------------------------------------------
                StatefulBuilder(builder: (context, setStateSB) {
                  final isFilled = nameController.text.trim().isNotEmpty;
                  return TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => setStateSB(() {}),
                    decoration: InputDecoration(
                      labelText: "Item Name",
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        borderSide: BorderSide(color: isFilled ? Colors.green : Colors.white, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        borderSide: BorderSide(color: isFilled ? Colors.green : Colors.blue, width: 2),
                      ),
                    ),
                    cursorColor: Colors.white,
                  );
                }),

                SizedBox(height: 16.h),

                // --- Quantity row + steppers ----------------------------------
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
                        child: StatefulBuilder(builder: (context, setStateSB) {
                          final isFilled = quantity > 0;
                          // choose formatter based on unit
                          final List<TextInputFormatter> formatters =
                              (_unit == 'count')
                                  ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)]
                                  : [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                      LengthLimitingTextInputFormatter(7),
                                    ];
                          final controller = TextEditingController(
                            text: (_unit == 'count')
                                ? quantity.toInt().toString()
                                : quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2),
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: controller,
                                textAlign: TextAlign.center,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: formatters,
                                onChanged: (val) {
                                  double parsed = 0;
                                  if (_unit == 'count') {
                                    final n = int.tryParse(val) ?? 1;
                                    parsed = n.toDouble();
                                  } else {
                                    parsed = double.tryParse(val) ?? 1.0;
                                  }
                                  setStateSB(() {
                                    quantity = parsed;
                                    _clampQuantity();
                                  });
                                },
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold, color: Colors.white),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
                                  labelText: labelQty,
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15.r),
                                    borderSide: BorderSide(color: isFilled ? Colors.green : Colors.white, width: 2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15.r),
                                    borderSide: BorderSide(color: isFilled ? Colors.green : Colors.blue, width: 2),
                                  ),
                                ),
                                cursorColor: Colors.white,
                              ),
                              SizedBox(height: 8.h),
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  "Preview: ${_prettyPreview()}",
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 20.w, bottom: 10.h),
                      child: IconButton(
                        icon: Icon(Icons.add_circle, color: Colors.green, size: 30.sp),
                        onPressed: _incrementQty,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 15.h),

                // --- Unit chips (g / ml / count) -------------------------------
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Unit",
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13.sp),
                  ),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 8.w,
                  children: _unitChoices.map((u) {
                    final bool selected = _unit == u;
                    return ChoiceChip(
                      label: Text(u.toUpperCase()),
                      selected: selected,
                      onSelected: (_) => _setUnit(u),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedColor: Colors.blueAccent.withOpacity(0.8),
                      backgroundColor: Colors.white.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(
                          color: selected ? Colors.blueAccent : Colors.white24,
                          width: 1.5,
                        ),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),

                SizedBox(height: 20.h),

                // --- Category dropdown (unchanged) -----------------------------
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  onChanged: (val) => setState(() => _selectedCategory = val),
                  items: _categories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(Icons.double_arrow_rounded, color: Colors.white70, size: 20.sp),
                                SizedBox(width: 10.w),
                                Text(cat, style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16.sp)),
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
                      borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                ),

                SizedBox(height: 25.h),

                // --- Actions ----------------------------------------------------
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
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 16),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    StatefulBuilder(builder: (context, setStateSB) {
                      final isActive = nameController.text.trim().isNotEmpty;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? Colors.green : Colors.grey,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: theme.colorScheme.secondary.withOpacity(0.25),
                          padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                        ),
                        onPressed: isActive ? () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;

                          // ensure final clamp + integer for count
                          _clampQuantity();

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
                        } : null,
                        child: Text(
                          widget.isEdit ? 'Save' : 'Add',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 16.sp),
                        ),
                      );
                    }),
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

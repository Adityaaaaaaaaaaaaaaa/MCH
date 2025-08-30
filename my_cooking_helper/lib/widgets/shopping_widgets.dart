// lib/features/shopping/shopping_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/models/cravings.dart';

typedef OnItemChanged = void Function(ShoppingItemModel updated);
typedef OnItemRemove  = void Function();

class AddItemBar extends StatefulWidget {
  const AddItemBar({
    super.key,
    required this.onSubmit,
  });

  final void Function({required String name, required double need, required String unit}) onSubmit;

  @override
  State<AddItemBar> createState() => _AddItemBarState();
}

class _AddItemBarState extends State<AddItemBar> {
  final _nameCtrl = TextEditingController();
  double _qty = 1;
  String _unit = 'count';

  void _applyQty(double v) {
    setState(() => _qty = v < 0 ? 0 : v);
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    widget.onSubmit(name: name, need: _qty <= 0 ? 1 : _qty, unit: _unit);
    _nameCtrl.clear();
    setState(() => _qty = 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    Widget unitChip(String u) {
      final selected = _unit == u;
      return GestureDetector(
        onTap: () => setState(() => _unit = u),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: selected
                ? primary.withOpacity(isDark ? .22 : .12)
                : (isDark ? const Color(0xFF232323) : Colors.white),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: selected ? primary.withOpacity(.55) : primary.withOpacity(.18), width: 1.0),
          ),
          child: Text(
            u,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w800,
              color: selected ? primary : (isDark ? Colors.white : Colors.black87),
              letterSpacing: .2,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border.all(color: primary.withOpacity(.12), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Add ingredient',
                    hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp, color: isDark ? Colors.white : Colors.black87),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _applyQty(_qty - 1),
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Decrease',
                  ),
                  SizedBox(
                    width: 48.w,
                    child: Text(
                      (_qty % 1 == 0) ? _qty.toStringAsFixed(0) : _qty.toStringAsFixed(2),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _applyQty(_qty + 1),
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Increase',
                  ),
                ],
              ),
              SizedBox(width: 6.w),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              unitChip('g'),
              SizedBox(width: 6.w),
              unitChip('ml'),
              SizedBox(width: 6.w),
              unitChip('count'),
            ],
          ),
        ],
      ),
    );
  }
}

class ShoppingListTile extends StatefulWidget {
  const ShoppingListTile({
    super.key,
    required this.item,
    required this.onChange,
    required this.onDelete,
  });

  final ShoppingItemModel item;
  final OnItemChanged onChange;
  final OnItemRemove onDelete;

  @override
  State<ShoppingListTile> createState() => _ShoppingListTileState();
}

class _ShoppingListTileState extends State<ShoppingListTile> {
  late double qty;
  @override
  void initState() {
    super.initState();
    qty = widget.item.need > 0 ? widget.item.need : 1;
  }

  void _apply(double v) {
    setState(() => qty = v < 0 ? 0 : v);
    widget.onChange(widget.item.copyWith(need: qty));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        border: Border.all(color: primary.withOpacity(.15), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5.sp,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Text(
            widget.item.unit.isEmpty ? 'count' : widget.item.unit,
            style: TextStyle(fontSize: 12.sp, color: isDark ? Colors.grey[300] : Colors.grey[700]),
          ),
          SizedBox(width: 10.w),
          Row(
            children: [
              IconButton(
                onPressed: () => _apply(qty - 1),
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Decrease',
              ),
              SizedBox(
                width: 48.w,
                child: Text(
                  (qty % 1 == 0) ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
              ),
              IconButton(
                onPressed: () => _apply(qty + 1),
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Increase',
              ),
            ],
          ),
          IconButton(
            onPressed: widget.onDelete,
            icon: Icon(Icons.delete_outline, color: Colors.red[600]),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

// Convenience extension — keeps your model immutable style
extension ShoppingModelCopy on ShoppingItemModel {
  ShoppingItemModel copyWith({
    String? name,
    double? need,
    String? unit,
    double? have,
    String? tag,
  }) {
    return ShoppingItemModel(
      name: name ?? this.name,
      need: need ?? this.need,
      unit: unit ?? this.unit,
      have: have ?? this.have,
      tag: tag ?? this.tag,
    );
  }
}

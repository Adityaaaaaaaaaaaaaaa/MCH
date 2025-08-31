// lib/features/shopping/shopping_widgets.dart
// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import '/models/cravings.dart';

typedef OnItemChanged = void Function(ShoppingItemModel updated);
typedef OnItemRemove = void Function();

/// --------------------------
/// AddItemBar (Plus Button + Modal)
/// --------------------------
class AddItemBar extends StatefulWidget {
  const AddItemBar({super.key, required this.onSubmit});

  final void Function({
    required String name,
    required double need,
    required String unit,
  })
  onSubmit;

  @override
  State<AddItemBar> createState() => _AddItemBarState();
}

class _AddItemBarState extends State<AddItemBar> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotateController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _showAddModal() {
    _rotateController.forward().then((_) => _rotateController.reverse());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemModal(onSubmit: widget.onSubmit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    // ignore: unused_local_variable
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: RotationTransition(
          turns: _rotateAnimation,
          child: GestureDetector(
            onTap: _showAddModal,
            child: Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, primary.withOpacity(0.8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: primary.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: Colors.white, size: 28.sp),
            ).asGlass(
              tintColor: primary,
              clipBorderRadius: BorderRadius.circular(30.r),
            ),
          ),
        ),
      ),
    );
  }
}

/// --------------------------
/// AddItemModal (Beautiful Modal)
/// --------------------------
class AddItemModal extends StatefulWidget {
  const AddItemModal({super.key, required this.onSubmit});

  final void Function({
    required String name,
    required double need,
    required String unit,
  })
  onSubmit;

  @override
  State<AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends State<AddItemModal>
    with TickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  double _qty = 1;
  String _unit = 'count';
  final _qtyCtrl = TextEditingController(text: '1');

  late final AnimationController _slideController;
  late final AnimationController _borderController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<Color?> _borderAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _borderAnimation = ColorTween(
      begin: Colors.blue.withOpacity(0.2),
      end: Colors.purple.withOpacity(0.4),
    ).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _qtyCtrl.text = '1';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _slideController.dispose();
    _borderController.dispose();
    super.dispose();
  }

  void _applyQty(double v) {
    setState(() {
      _qty = clampByUnit(v < 0 ? 0 : v, _unit);
      _qtyCtrl.text = normalizedQtyTextForField(_unit, _qty);
    });
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    widget.onSubmit(name: name, need: _qty <= 0 ? 1 : _qty, unit: _unit);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    Widget unitChip(String u, IconData icon) {
      final selected = _unit == u;
      return GestureDetector(
        onTap: () {
          setState(() {
            _unit = u;
            _qty = clampByUnit(_qty, _unit);
            _qtyCtrl.text = normalizedQtyTextForField(_unit, _qty);
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.r),
            gradient:
                selected
                    ? LinearGradient(
                      colors: [primary, primary.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : LinearGradient(
                      colors: [
                        isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF5F5F5),
                        isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFEEEEEE),
                      ],
                    ),
            border: Border.all(
              color: selected ? primary.withOpacity(0.8) : Colors.transparent,
              width: 2,
            ),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18.sp,
                color:
                    selected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
              ),
              SizedBox(width: 8.w),
              Text(
                u,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color:
                      selected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16.w,
          right: 16.w,
          top: 20.h,
        ),
        child: AnimatedBuilder(
          animation: _borderAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [const Color(0xFF1E1E1E), const Color(0xFF2A2A2A)]
                          : [Colors.white, const Color(0xFFFAFAFA)],
                ),
                border: Border.all(
                  color: _borderAnimation.value ?? Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isDark
                            ? Colors.black.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modal Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Add Ingredient",
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[200],
                            ),
                            child: Icon(
                              Icons.close,
                              size: 20.sp,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // Item Name Input
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15.r),
                        color:
                            isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF8F8F8),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: 'Enter ingredient name...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                            fontSize: 16.sp,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Quantity Section
                    Row(
                      children: [
                        Text(
                          "Quantity:",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.r),
                            color:
                                isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFF8F8F8),
                            border: Border.all(
                              color: primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _applyQty(_qty - 1),
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(15.r),
                                      bottomLeft: Radius.circular(15.r),
                                    ),
                                    color: Colors.red.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    size: 20.sp,
                                    color: Colors.red[600],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 72.w,
                                child: TextField(
                                  controller: _qtyCtrl,
                                  textAlign: TextAlign.center,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: formattersForUnit(_unit),
                                  decoration: const InputDecoration(
                                    isCollapsed: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  onChanged: (t) {
                                    final v = double.tryParse(t) ?? 0;
                                    setState(() => _qty = v); // let user type freely; we clamp on commit/submit
                                  },
                                  onEditingComplete: () {
                                    _qty = clampByUnit(_qty, _unit);
                                    _qtyCtrl.text = normalizedQtyTextForField(_unit, _qty);
                                    FocusScope.of(context).unfocus();
                                  },
                                  onSubmitted: (_) => _submit(),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _applyQty(_qty + 1),
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(15.r),
                                      bottomRight: Radius.circular(15.r),
                                    ),
                                    color: Colors.green.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 20.sp,
                                    color: Colors.green[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // Unit Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Unit:",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            unitChip('g', Icons.scale),
                            SizedBox(width: 12.w),
                            unitChip('ml', Icons.opacity),
                            SizedBox(width: 12.w),
                            unitChip('count', Icons.tag),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 32.h),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          elevation: 8,
                          shadowColor: primary.withOpacity(0.4),
                        ),
                        child: Text(
                          "ADD TO LIST",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// --------------------------
/// ShoppingListTile (Receipt Item Style)
/// --------------------------
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

class _ShoppingListTileState extends State<ShoppingListTile>
    with TickerProviderStateMixin {
  late double qty;
  late final AnimationController _hoverController;
  late final AnimationController _borderController;
  late final Animation<double> _hoverAnimation;
  late Animation<Color?> _borderAnimation;
  late final TextEditingController _qtyCtrl;
  double _clampTile(double v) => clampByUnit(v, widget.item.unit);

  bool _showControls = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    qty = widget.item.need > 0 ? widget.item.need : 1;

    _qtyCtrl = TextEditingController(
      text: normalizedQtyTextForField(widget.item.unit, qty),
    );

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize color animation here where Theme.of(context) is safe to use
    final primary = Theme.of(context).colorScheme.primary;
    _borderAnimation = ColorTween(
      begin: Colors.transparent,
      end: primary.withOpacity(0.3),
    ).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _hoverController.dispose();
    _borderController.dispose();
    super.dispose();
  }

  void _apply(double v) {
    final nv = _clampTile(v < 0 ? 0 : v);
    setState(() {
      qty = nv;
      _qtyCtrl.text = normalizedQtyTextForField(widget.item.unit, qty);
    });
    widget.onChange(widget.item.copyWith(need: qty));
  }

  void _startBorderAnimation() {
    _borderController.repeat(reverse: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _borderController.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() => _showControls = !_showControls);
        _startBorderAnimation();
      },
      onTapDown: (_) {
        setState(() => _pressed = true);
        _hoverController.forward();   // scale up a touch
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _hoverController.reverse();   // return to normal scale
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _hoverController.reverse();
      },
      child: ScaleTransition(
        scale: _hoverAnimation,
        child: AnimatedBuilder(
          animation: _borderAnimation,
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                border: Border.all(
                  color: _borderAnimation.value ?? Colors.transparent,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: _pressed   // <-- use press state for shadow
                    ? [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.30)
                              : Colors.grey.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- your existing main Row (with full name, no ellipsis) ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 68.w,
                        child: Text(
                          formatQty(qty, widget.item.unit),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          widget.item.name,
                          softWrap: true,
                          maxLines: null,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                            height: 1.2,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 24.w,
                        child: Icon(
                          _showControls ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 20.sp,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // Dotted divider under the row (keeps receipt vibe)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final int count = (constraints.maxWidth / (3.w + 2.w))
                          .floor()
                          .clamp(0, 400);
                      return Row(
                        children: List.generate(
                          count,
                          (_) => Container(
                            width: 3.w,
                            height: 1.h,
                            margin: EdgeInsets.symmetric(horizontal: 1.w),
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),

                  // --- your existing expandable controls block (unchanged) ---
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: _showControls ? 60.h : 0,
                      child:
                          _showControls
                              ? Container(
                                margin: EdgeInsets.only(top: 12.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                  color:
                                      isDark
                                          ? const Color(0xFF2A2A2A)
                                          : const Color(0xFFF8F8F8),
                                ),
                                child: Row(
                                  children: [
                                    // Quantity Controls
                                    Expanded(
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _apply(qty - 1),
                                            child: Container(
                                              padding: EdgeInsets.all(8.w),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.red.withOpacity(
                                                  0.1,
                                                ),
                                                border: Border.all(
                                                  color: Colors.red.withOpacity(
                                                    0.3,
                                                  ),
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.remove,
                                                size: 16.sp,
                                                color: Colors.red[600],
                                              ),
                                            ),
                                          ),

                                          SizedBox(width: 10.w),

                                          // replace the center Text(...) with:
                                          SizedBox(
                                            width: 50.w,
                                            child: TextField(
                                              controller: _qtyCtrl,
                                              textAlign: TextAlign.center,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              inputFormatters: formattersForUnit(widget.item.unit),
                                              decoration: const InputDecoration(
                                                isCollapsed: true,
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16.sp,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                              onChanged: (t) {
                                                final v = double.tryParse(t);
                                                setState(() => qty = (v == null || v < 0) ? 0 : v); // live preview
                                              },
                                              onEditingComplete: () {
                                                final parsed = double.tryParse(_qtyCtrl.text) ?? qty;
                                                final clamped = _clampTile(parsed);
                                                _apply(clamped); // commits & re-normalizes the text
                                                FocusScope.of(context).unfocus();
                                              },
                                              onSubmitted: (_) {
                                                final parsed = double.tryParse(_qtyCtrl.text) ?? qty;
                                                _apply(_clampTile(parsed));
                                              },
                                            ),
                                          ),

                                          SizedBox(width: 10.w),

                                          GestureDetector(
                                            onTap: () => _apply(qty + 1),
                                            child: Container(
                                              padding: EdgeInsets.all(8.w),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.green.withOpacity(
                                                  0.1,
                                                ),
                                                border: Border.all(
                                                  color: Colors.green
                                                      .withOpacity(0.3),
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.add,
                                                size: 16.sp,
                                                color: Colors.green[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Delete Button
                                    GestureDetector(
                                      onTap: widget.onDelete,
                                      child: Container(
                                        padding: EdgeInsets.all(10.w),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          color: Colors.red.withOpacity(0.1),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              size: 16.sp,
                                              color: Colors.red[600],
                                            ),
                                            SizedBox(width: 6.w),
                                            Text(
                                              "Remove",
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.red[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Keep your model immutable style
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

/* -------------------------------------------------------------------------- */
/* Utility formatting                                                         */
/* -------------------------------------------------------------------------- */

String _trimZeros(String s) => s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;

/// Smart visual formatting only. Stored values/units remain unchanged.
String formatQty(double qty, String unitRaw) {
  final unit = unitRaw.trim().toLowerCase();

  // helper: choose decimals for small floats
  String asTight(double v) => _trimZeros(
        (v % 1 == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(2),
      );

  if (unit == 'g') {
    if (qty >= 1000) return '${_trimZeros((qty / 1000).toStringAsFixed(2))} kg';
    return '${asTight(qty)} g';
  }
  if (unit == 'ml') {
    if (qty >= 1000) return '${_trimZeros((qty / 1000).toStringAsFixed(2))} L';
    return '${asTight(qty)} ml';
  }
  if (unit.isEmpty || unit == 'count') {
    return '${asTight(qty)}x';
  }
  // fallback for any other unit
  return '${asTight(qty)} $unit';
}

/* -------------------------------------------------------------------------- */
/* Qty rules                                                                  */
/* -------------------------------------------------------------------------- */

// max: 999 count, 99 kg (→ 99,000 g), 99 L (→ 99,000 ml)
double clampByUnit(double v, String unitRaw) {
  final u = unitRaw.trim().toLowerCase();
  if (u.isEmpty || u == 'count') return v.clamp(0, 999).toDouble();
  if (u == 'g') return v.clamp(0, 99000).toDouble();   // 99 kg
  if (u == 'ml') return v.clamp(0, 99000).toDouble();  // 99 L
  return v.clamp(0, 9999).toDouble();                  // fallback
}

// how many decimals the *input field* should keep
int _decimalsForField(String unitRaw) {
  final u = unitRaw.trim().toLowerCase();
  if (u.isEmpty || u == 'count') return 1; // allow halves etc. for count
  if (u == 'g') return 2;                  // allow 0.5 g, 0.2 g etc.
  if (u == 'ml') return 2;                 // unchanged
  return 2;
}

// normalize controller text (9 → "9", 9.50 → "9.5")
String normalizedQtyTextForField(String unitRaw, double v) {
  final dec = _decimalsForField(unitRaw);
  return _trimZeros(v.toStringAsFixed(dec));
}

// dynamic input formatters (length guard + decimals allowed)
List<TextInputFormatter> formattersForUnit(String unitRaw) {
  final u = unitRaw.trim().toLowerCase();
  if (u.isEmpty || u == 'count') {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
      LengthLimitingTextInputFormatter(5), // e.g., "999.9"
    ];
  }
  if (u == 'g' || u == 'ml') {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      LengthLimitingTextInputFormatter(7), // e.g., "99000.0"
    ];
  }
  return [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
    LengthLimitingTextInputFormatter(6),
  ];
}


String generateReceiptId() {
  final now = DateTime.now();
  final rand = Random().nextInt(9000) + 1000; // 4-digit suffix
  // keep short, receipt-like, yet fairly unique per session
  return '${now.millisecondsSinceEpoch.toString().substring(6)}-$rand';
}

/* -------------------------------------------------------------------------- */
/* Receipt Shell: Header / Footer                                             */
/* -------------------------------------------------------------------------- */

class ReceiptHeader extends StatelessWidget {
  const ReceiptHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget perforation(int count) => Row(
      children: List.generate(
        count,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 1.w),
            height: 3.h,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              isDark
                  ? [const Color(0xFF1E1E1E), const Color(0xFF1A1A1A)]
                  : [const Color(0xFFFFFFFF), const Color(0xFFFDFDFD)],
        ),
      ),
      child: Column(
        children: [
          perforation(25),
          SizedBox(height: 16.h),

          // LOGO (asset)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/app_icon.png', // <-- add file, see step 3
                height: 36.h,
                fit: BoxFit.contain,
              ),
            ],
          ),
          SizedBox(height: 8.h),

          Text(
            "KITCHEN ESSENTIALS",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            "Your Shopping List",
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "Date: ${DateTime.now().toString().split(' ')[0]}",
            style: TextStyle(
              fontSize: 11.sp,
              fontFamily: 'monospace',
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
          SizedBox(height: 16.h),

          // Thin separator
          Container(
            height: 1.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDark ? Colors.grey[600]! : Colors.grey[400]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Column headers
          Row(
            children: [
              SizedBox(
                width: 60.w,
                child: Text(
                  "QTY",
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  "ITEM DESCRIPTION",
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),

          Container(
            height: 1.h,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
        ],
      ),
    );
  }
}

class ReceiptFooter extends StatelessWidget {
  const ReceiptFooter({
    super.key,
    required this.totalItems,
    required this.receiptId,
  });
  final int totalItems;
  final String receiptId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget dashedLine(int count) => Row(
      children: List.generate(
        count,
        (_) => Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 1.w),
            height: 2.h,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[400],
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12.r),
          bottomRight: Radius.circular(12.r),
        ),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              isDark
                  ? [const Color(0xFF1A1A1A), const Color(0xFF1E1E1E)]
                  : [const Color(0xFFFDFDFD), const Color(0xFFFFFFFF)],
        ),
      ),
      child: Column(
        children: [
          dashedLine(30),
          SizedBox(height: 12.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TOTAL ITEMS:",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  "$totalItems",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),
          Text(
            "*** THANK YOU ***",
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),

          SizedBox(height: 14.h),
          // Barcode look
          SizedBox(
            height: 40.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(30, (index) {
                final heights = [25.h, 30.h, 20.h, 35.h, 25.h];
                final widths = [2.w, 1.w, 3.w, 1.w, 2.w];
                return Container(
                  width: widths[index % widths.length],
                  height: heights[index % heights.length],
                  margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                    borderRadius: BorderRadius.circular(0.5.r),
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: 10.h),
          Text(
            "Receipt #$receiptId",
            style: TextStyle(
              fontSize: 10.sp,
              fontFamily: 'monospace',
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),

          SizedBox(height: 12.h),
          // Bottom perforation
          Row(
            children: List.generate(
              25,
              (_) => Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* Add Item chip to show under the list                                       */
/* -------------------------------------------------------------------------- */

class AddItemInline extends StatelessWidget {
  const AddItemInline({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: LinearGradient(
              colors: [primary, primary.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white),
              SizedBox(width: 8.w),
              Text(
                "Add item",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ).asGlass(
          tintColor:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.2),
          clipBorderRadius: BorderRadius.circular(24.r),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* The Receipt container (Header → Scrollable list → Footer)                  */
/* -------------------------------------------------------------------------- */

class ShoppingReceipt extends StatefulWidget {
  const ShoppingReceipt({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onChange,
    required this.onDelete,
    this.trailing,
  });

  final List<ShoppingItemModel> items;
  final void Function({
    required String name,
    required double need,
    required String unit,
  })
  onAdd;
  final OnItemChanged onChange;
  final Future<void> Function(String name) onDelete;
  final Widget? trailing;

  @override
  State<ShoppingReceipt> createState() => _ShoppingReceiptState();
}

class _ShoppingReceiptState extends State<ShoppingReceipt>
    with TickerProviderStateMixin {
  late final AnimationController _receiptController;
  late final Animation<double> _receiptAnimation;
  late final String _receiptId;

  @override
  void initState() {
    super.initState();
    _receiptId = generateReceiptId();

    _receiptController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _receiptAnimation = CurvedAnimation(
      parent: _receiptController,
      curve: Curves.easeOutCubic,
    );
    _receiptController.forward();
  }

  @override
  void dispose() {
    _receiptController.dispose();
    super.dispose();
  }

  void _openAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddItemModal(onSubmit: widget.onAdd),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, .2),
        end: Offset.zero,
      ).animate(_receiptAnimation),
      child: FadeTransition(
        opacity: _receiptAnimation,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color:
                    isDark
                        ? Colors.black.withOpacity(0.6)
                        : Colors.grey.withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(0, 12),
                spreadRadius: 2,
              ),
              BoxShadow(
                color:
                    isDark
                        ? Colors.grey[900]!.withOpacity(0.8)
                        : Colors.grey[100]!.withOpacity(0.8),
                blurRadius: 1,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    isDark
                        ? [
                          const Color(0xFF1A1A1A),
                          const Color(0xFF151515),
                          const Color(0xFF1C1C1C),
                        ]
                        : [
                          const Color(0xFFFDFDFD),
                          const Color(0xFFFAFAFA),
                          const Color(0xFFF8F8F8),
                        ],
              ),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(child: const ReceiptHeader()),

                // Add button under last item
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 16.h),
                    child: AddItemInline(onTap: _openAddModal),
                  ),
                ),

                // Items (or empty state)
                if (widget.items.isEmpty)
                  SliverToBoxAdapter(child: _EmptyReceipt(onAdd: _openAddModal))
                else
                  SliverList.separated(
                    itemCount: widget.items.length,
                    separatorBuilder: (_, __) => SizedBox(height: 2.h),
                    itemBuilder: (context, i) {
                      final e = widget.items[i];
                      return ShoppingListTile(
                        item: e,
                        onChange: widget.onChange,
                        onDelete: () async {
                          await widget.onDelete(e.name);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8.w),
                                  Text('Removed "${e.name}" from receipt'),
                                ],
                              ),
                              backgroundColor: Colors.red[600],
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              margin: EdgeInsets.all(16.w),
                            ),
                          );
                        },
                      );
                    },
                  ),

                // Footer
                SliverToBoxAdapter(
                  child: ReceiptFooter(
                    totalItems: widget.items.length,
                    receiptId: _receiptId,
                  ),
                ),

                if (widget.trailing != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 16.h),
                      child: widget.trailing!,
                    ),
                  ),
              ],
            ),
          ).asGlass(
            tintColor:
                isDark
                    ? Colors.black.withOpacity(0.1)
                    : Colors.white.withOpacity(0.1),
            clipBorderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* Empty state (kept compact)                                                 */
/* -------------------------------------------------------------------------- */
class _EmptyReceipt extends StatelessWidget {
  const _EmptyReceipt({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.grey[800] : Colors.grey[100],
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48.sp,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "No Items Added",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Tap the + to add your first ingredient",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
                height: 1.4,
              ),
            ),
            SizedBox(height: 18.h),
            //AddItemInline(onTap: onAdd),
          ],
        ),
      ),
    );
  }
}

// --------------------------
// ClearListButton (reusable)
// --------------------------
class ClearListButton extends StatelessWidget {
  const ClearListButton({
    super.key,
    required this.itemCount,
    required this.onClear,
    this.enabled = true,
  });

  final int itemCount;
  final Future<void> Function() onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPress = enabled && itemCount > 0;

    Future<void> _confirmAndClear() async {
      if (!canPress) return;

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Clear entire list?'),
          content: Text(
            'This will permanently remove ${itemCount} item(s) from your shopping list across all devices.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever_outlined),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              label: const Text('Clear'),
            ),
          ],
        ),
      ) ?? false;

      if (!ok) return;

      await onClear();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.delete_sweep, color: Colors.white),
                SizedBox(width: 8),
                Text('Shopping list cleared'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[600],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canPress ? _confirmAndClear : null,
        icon: const Icon(Icons.delete_sweep_outlined),
        label: Text(itemCount > 0 ? 'Clear list (${itemCount})' : 'Clear list'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          elevation: canPress ? 6 : 0,
          disabledBackgroundColor:
              isDark ? Colors.red[900]?.withOpacity(0.4) : Colors.red[200],
          disabledForegroundColor:
              isDark ? Colors.white70 : Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nice reminder sheet (date + time + pre-alert chips) with past-prevention.
// Call: final result = await showReminderSheet(context);
// ---------------------------------------------------------------------------

class ReminderPick {
  final DateTime when;
  final Duration preAlert;
  const ReminderPick(this.when, this.preAlert);
}

Future<ReminderPick?> showReminderSheet(BuildContext context) {
  final now = DateTime.now();
  DateTime pickedDate = DateTime(now.year, now.month, now.day);
  TimeOfDay pickedTime = _roundUpTo5(TimeOfDay.fromDateTime(now.add(const Duration(minutes: 10))));
  Duration preAlert = Duration.zero; // at time

  return showModalBottomSheet<ReminderPick>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (c) {
      final theme = Theme.of(c);
      final isDark = theme.brightness == Brightness.dark;

      return StatefulBuilder(
        builder: (ctx, setState) {
          // single, correct chip helper
          Widget chip(String label, Duration d) {
            final selected = preAlert == d;
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => setState(() => preAlert = d),
              labelStyle: TextStyle(
                color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: FontWeight.w600,
              ),
              selectedColor: theme.colorScheme.primary,
              backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F1F1),
              side: BorderSide(color: selected ? theme.colorScheme.primary : Colors.transparent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            );
          }

          Future<void> pickDate() async {
            final now = DateTime.now();
            final d = await showDatePicker(
              context: ctx,
              initialDate: pickedDate.isBefore(DateTime(now.year, now.month, now.day))
                  ? DateTime(now.year, now.month, now.day)
                  : pickedDate,
              firstDate: DateTime(now.year, now.month, now.day),
              lastDate: now.add(const Duration(days: 365 * 2)),
            );
            if (d != null) setState(() => pickedDate = d);
          }

          Future<void> pickTime() async {
            final now = DateTime.now();
            final initial = DateUtils.isSameDay(pickedDate, now)
                ? _roundUpTo5(TimeOfDay.fromDateTime(now.add(const Duration(minutes: 10))))
                : const TimeOfDay(hour: 9, minute: 0);

            final t = await showTimePicker(
              context: ctx,
              initialTime: initial,
              builder: (ctx2, child) => MediaQuery(
                data: MediaQuery.of(ctx2).copyWith(alwaysUse24HourFormat: true),
                child: child!,
              ),
            );
            if (t != null) setState(() => pickedTime = t);
          }

          final combined = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute,
          );
          final floor = now.add(const Duration(minutes: 1));
          final isPast = combined.isBefore(floor);

          return Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: isDark ? [const Color(0xFF1E1E1E), const Color(0xFF2A2A2A)]
                                 : [Colors.white, const Color(0xFFFAFAFA)],
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Set reminder', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event),
                            label: Text(
                              '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}',
                            ),
                            onPressed: pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(TimeOfDay(hour: pickedTime.hour, minute: pickedTime.minute).format(ctx)),
                            onPressed: pickTime,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Alert me', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        chip('At time', Duration.zero),
                        chip('1 min before', const Duration(minutes: 1)),
                        chip('5 min before', const Duration(minutes: 5)),
                        chip('15 min before', const Duration(minutes: 15)),
                        chip('1 hour before', const Duration(hours: 1)),
                      ],
                    ),

                    if (isPast) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Selected time is in the past. We’ll adjust to ~1 minute from now.',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
                      ),
                    ],

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          var when = DateTime(
                            pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute,
                          );
                          final floor = DateTime.now().add(const Duration(minutes: 1));
                          if (when.isBefore(floor)) when = floor;
                          Navigator.pop(ctx, ReminderPick(when, preAlert));
                        },
                        child: const Text('Schedule'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// helper: round minutes to next 5-min step
TimeOfDay _roundUpTo5(TimeOfDay t) {
  final m = ((t.minute + 4) ~/ 5) * 5;
  final extraHour = m >= 60 ? 1 : 0;
  final newMin = m % 60;
  final newHour = (t.hour + extraHour) % 24;
  return TimeOfDay(hour: newHour, minute: newMin);
}

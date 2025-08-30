// lib/features/shopping/shopping.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/theme/app_theme.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/services/shopping_service.dart';
import '/models/cravings.dart';

class ShoppingPage extends ConsumerWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shoppingServiceProvider);
    final svc = ref.read(shoppingServiceProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: avoid_print
      print('\x1B[34m[SHOP PAGE] items=${items.length}\x1B[0m');
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget section(String title, List<ShoppingItemModel> data) {
      if (data.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textColor(context),
                  letterSpacing: .2,
                ),
          ),
          SizedBox(height: 8.h),
          ...data.map((e) => _ShoppingRow(item: e, onChange: (updated) {
                // replace entry
                svc.setItem(
                  name: updated.name,
                  tag: updated.tag,
                  need: updated.need,
                  unit: updated.unit,
                  have: updated.have,
                );
              }, onDelete: () {
                svc.removeItem(e.name);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Removed "${e.name}" from list'), backgroundColor: Colors.red[600]),
                );
              })),
          SizedBox(height: 12.h),
        ],
      );
    }

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: false,
      extendBody: true, // scroll under bottom nav
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(
        title: "Shopping List",
        showMenu: false,
        themeToggleWidget: ThemeToggleButton(),
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
          child: items.isEmpty
              ? Center(
                  child: Text(
                    "Your shopping list is empty.\nGo pick ingredients from a recipe.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: textColor(context).withOpacity(.8),
                          height: 1.5,
                        ),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      section("Buy", svc.buyItems),
                      section("Add (pantry)", svc.addItems),
                      SizedBox(height: 4.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Total items: ${items.length}",
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _ShoppingRow extends StatefulWidget {
  const _ShoppingRow({
    required this.item,
    required this.onChange,
    required this.onDelete,
  });

  final ShoppingItemModel item;
  final ValueChanged<ShoppingItemModel> onChange;
  final VoidCallback onDelete;

  @override
  State<_ShoppingRow> createState() => _ShoppingRowState();
}

class _ShoppingRowState extends State<_ShoppingRow> {
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

// Convenience extension on your model
extension on ShoppingItemModel {
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

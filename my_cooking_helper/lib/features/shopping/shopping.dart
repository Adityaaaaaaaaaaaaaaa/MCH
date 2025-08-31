// lib/features/shopping/shopping.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/widgets/shopping_widgets.dart';
import '/theme/app_theme.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/services/shopping_service.dart';

class ShoppingPage extends ConsumerStatefulWidget {
  const ShoppingPage({super.key});
  @override
  ConsumerState<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends ConsumerState<ShoppingPage> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(shoppingServiceProvider);
    final svc = ref.read(shoppingServiceProvider.notifier);

    return Scaffold(
      backgroundColor: bgColor(context),
      drawer: const CustomDrawer(),
      extendBody: true,
      extendBodyBehindAppBar: false,
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
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
          child: ShoppingReceipt(
            items: items,
            onAdd: ({
              required String name,
              required double need,
              required String unit
            }) {
              svc.addOrUpdate(name: name, need: need, unit: unit);
            },
            onChange: (updated) => svc.addOrUpdate(
              name: updated.name,
              need: updated.need,
              unit: updated.unit,
              have: updated.have,
              tag: updated.tag,
            ),
            onDelete: (name) => svc.remove(name),

            // NEW: this now appears UNDER the list & scrolls with it
            trailing: ClearListButton(
              itemCount: items.length,
              onClear: () async {
                if (items.isEmpty) return;
                await svc.clearAll(); // Firestore stays in sync
              },
            ),
          ),
        ),
      ),
    );
  }
}

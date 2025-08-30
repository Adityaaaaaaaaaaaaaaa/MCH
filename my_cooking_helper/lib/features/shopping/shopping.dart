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

class ShoppingPage extends ConsumerWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shoppingServiceProvider);
    final svc = ref.read(shoppingServiceProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: false,
      extendBody: true,
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
          child: Column(
            children: [
              // Add-bar at top
              AddItemBar(
                onSubmit: ({required String name, required double need, required String unit}) {
                  svc.addOrUpdate(name: name, need: need, unit: unit);
                },
              ),
              SizedBox(height: 12.h),

              // Unified list
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          "Your shopping list is empty.\nAdd items or pick ingredients from a recipe.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: textColor(context).withOpacity(.8),
                                height: 1.5,
                              ),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        cacheExtent: MediaQuery.of(context).size.height, // per your perf note
                        itemCount: items.length,
                        separatorBuilder: (_, __) => SizedBox(height: 6.h),
                        itemBuilder: (context, i) {
                          final e = items[i];
                          return ShoppingListTile(
                            item: e,
                            onChange: (updated) {
                              svc.addOrUpdate(
                                name: updated.name,
                                need: updated.need,
                                unit: updated.unit,
                                have: updated.have,
                                tag: updated.tag,
                              );
                            },
                            onDelete: () async {
                              await svc.remove(e.name);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Removed "${e.name}" from list'), backgroundColor: Colors.red[600]),
                              );
                            },
                          );
                        },
                      ),
              ),

              // Footer meta
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
    );
  }
}

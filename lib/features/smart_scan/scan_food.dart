import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/appbar.dart';
import '/models/scanned_item.dart';
import 'smart_scan_controller.dart';
import '/widgets/scan_action_button.dart';
import '/utils/drawer.dart';
import '/utils/nav.dart';

class ScanFood extends ConsumerWidget {
  const ScanFood({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final scanController = ref.read(smartScanControllerProvider.notifier);

    return Scaffold(
      drawer: CustomDrawer(),
      bottomNavigationBar: CustomNavBar(currentIndex: 1),
      appBar: CustomAppBar(
        title: "Scan Food",
        trailingIcon: Icons.arrow_back_ios_new_rounded,
        onTrailingIconTap: () => context.pop(),
        height: 100,
        borderRadius: 26,
        topPadding: 60,
      ),
      backgroundColor: isLight
          ? const Color(0xfff8fafc)
          : const Color(0xff232526),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
                ? [
                    const Color(0xfff8fafc),
                    const Color(0xffa1c4fd).withOpacity(0.11),
                  ]
                : [
                    const Color(0xff232526),
                    const Color(0xff393e46).withOpacity(0.13),
                  ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Camera preview placeholder
                Container(
                  width: 320,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor.withOpacity(0.12),
                        Colors.greenAccent.withOpacity(0.14),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: theme.primaryColor, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.camera_alt_rounded,
                        size: 60, color: Colors.green),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "Point your camera at fresh produce or packaged food.\nTap below to add a dummy food item for testing.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 22),
                ScanActionButton(
                  label: "Add Dummy: Tomato (3 pcs)",
                  icon: Icons.local_pizza_rounded,
                  color: Colors.redAccent,
                  onPressed: () {
                    scanController.addItem(
                      ScannedItem(
                        itemName: "Tomato",
                        quantity: 3,
                        unit: "pcs",
                        source: "food_scan",
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dummy food item added!')),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ScanActionButton(
                  label: "Add Dummy: Chicken Breast (500 g)",
                  icon: Icons.set_meal_rounded,
                  color: Colors.orangeAccent,
                  onPressed: () {
                    scanController.addItem(
                      ScannedItem(
                        itemName: "Chicken Breast",
                        quantity: 500,
                        unit: "g",
                        source: "food_scan",
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dummy food item added!')),
                    );
                  },
                ),
                const SizedBox(height: 25),
                ScanActionButton(
                  label: "Review Detected Items",
                  icon: Icons.list,
                  color: theme.primaryColor,
                  onPressed: () => context.push('/reviewScreen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

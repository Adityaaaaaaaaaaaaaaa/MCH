import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/appbar.dart';
import '/models/scanned_item.dart';
import 'smart_scan_controller.dart';
import '/widgets/scan_action_button.dart';
import '/utils/drawer.dart';
import '/utils/nav.dart';

class ScanReceipt extends ConsumerWidget {
  const ScanReceipt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final scanController = ref.read(smartScanControllerProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: CustomDrawer(),
      bottomNavigationBar: CustomNavBar(currentIndex: 1),
      appBar: CustomAppBar(
        title: "Scan Receipt",
        showMenu: false,
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
                // Receipt image placeholder
                Container(
                  width: 320,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepOrangeAccent.withOpacity(0.09),
                        Colors.amber.withOpacity(0.11),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.deepOrange, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.receipt_long, size: 60, color: Colors.deepOrange),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "Snap a clear photo of your shopping receipt to auto-extract items.\nTap below to add dummy data for testing.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 22),
                ScanActionButton(
                  label: "Add Dummy: Milk (2 L)",
                  icon: Icons.local_drink_rounded,
                  color: Colors.blueAccent,
                  onPressed: () {
                    scanController.addItem(
                      ScannedItem(
                        itemName: "Milk",
                        quantity: 2,
                        unit: "L",
                        source: "receipt_scan",
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dummy receipt item added!')),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ScanActionButton(
                  label: "Add Dummy: Eggs (12 pcs)",
                  icon: Icons.egg_rounded,
                  color: Colors.purple,
                  onPressed: () {
                    scanController.addItem(
                      ScannedItem(
                        itemName: "Eggs",
                        quantity: 12,
                        unit: "pcs",
                        source: "receipt_scan",
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dummy receipt item added!')),
                    );
                  },
                ),
                const SizedBox(height: 25),
                ScanActionButton(
                  label: "Review Detected Items",
                  icon: Icons.list,
                  color: Colors.deepOrange,
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

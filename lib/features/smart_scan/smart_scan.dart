import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/appbar.dart';
import '/widgets/scan_action_button.dart';
import '/utils/drawer.dart';
import '/utils/nav.dart';

class SmartScan extends StatelessWidget {
  const SmartScan({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: CustomDrawer(),
      bottomNavigationBar: CustomNavBar(currentIndex: 1),
      appBar: CustomAppBar(
        title: "Smart Scan",
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScanActionButton(
                    label: "Scan Food",
                    icon: Icons.fastfood,
                    color: Colors.green,
                    onPressed: () => context.push('/scanFood'),
                  ),
                  const SizedBox(height: 20),
                  ScanActionButton(
                    label: "Scan Receipt",
                    icon: Icons.receipt_long,
                    color: Colors.deepOrange,
                    onPressed: () => context.push('/scanReceipt'),
                  ),
                  const SizedBox(height: 20),
                  ScanActionButton(
                    label: "Manual Input",
                    icon: Icons.edit_note_rounded,
                    color: Colors.amber[700],
                    onPressed: () => context.push('/manualInput'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

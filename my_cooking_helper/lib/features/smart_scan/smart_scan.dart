import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import '/utils/colors.dart';
import '../../widgets/navigation/appbar.dart';
import '/widgets/scan_action_button.dart';
import '../../widgets/navigation/drawer.dart';
import '../../widgets/navigation/nav.dart';

class SmartScan extends StatelessWidget {
  const SmartScan({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      drawer: CustomDrawer(),
      bottomNavigationBar: CustomNavBar(currentIndex: 1),
      appBar: CustomAppBar(
        title: "Smart Scan",
        height: 100,
        borderRadius: 26,
        topPadding: 60,
      ),
      backgroundColor: bgColor(context),
      body: Stack(
        children: [
          // -------- BACKGROUND IMAGES --------
          Positioned(
            top: 110,
            left: 30,
            child: Transform.rotate(
              angle: -0.15, //radians
              child: Image.asset(
                'assets/images/smartScan/scanFood.png',
                width: 210,
                height: 210,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 150,
            child: Transform.rotate(
              angle: 0.3, 
              child: Image.asset(
                'assets/images/smartScan/manualScan.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 65,
            right: 200,
            child: Transform.rotate(
              angle: -0.15, 
              child: Image.asset(
                'assets/images/smartScan/scanReceipt.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // --- GLASS CARD CONTENT ---
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 50),
                child: Container(
                  width: 250, // Set width as you like, or use constraints
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_rounded,
                        size: 50,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "How would you like to add items?",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: textColor(context),
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
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
                )
                // --- Apply the glass effect here ---
                .asGlass(
                  blurX: 5,
                  blurY: 5,
                  //tintColor: theme.colorScheme.background.withOpacity(0.26),
                  clipBorderRadius: BorderRadius.circular(30),
                  frosted: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

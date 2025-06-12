import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:glass/glass.dart';
//import 'package:go_router/go_router.dart';
import '../../utils/loader.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
//import '/theme/app_theme.dart';
//import '/utils/loader.dart';
import '/widgets/navigation/drawer.dart';
import '/widgets/navigation/nav.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 950),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
        final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text("Not logged in"));
    }
    final inventoryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('inventory');

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: true,
      extendBody: true,
      drawer: CustomDrawer(),
      bottomNavigationBar: CustomNavBar(currentIndex: 0),
      appBar: CustomAppBar(
        title: "Inventory",
        showMenu: true,
        height: 100,
        borderRadius: 26,
        topPadding: 60,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: inventoryRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: loader(
                                Colors.deepOrangeAccent,
                                  70,
                                  7,
                                  10,
                                  1500,
                                ),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text("No items in inventory."));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['itemName'] ?? '', 
                            style: TextStyle(color: textColor(context)),),
                subtitle: Text(
                  'Qty: ${data['quantity'] ?? ''}  |  Category: ${data['category'] ?? ''}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

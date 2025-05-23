import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              context.go('/'); // Back to onboarding
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome, ${user?.displayName ?? "User"}!',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

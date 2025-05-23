import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final prefs = data['preferences'] ?? {};

        return Scaffold(
          appBar: AppBar(
            title: const Text("Home"),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // TODO: Go to settings page if implemented
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  context.go('/signin');
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.blueAccent),
                  child: Text(data['displayName'] ?? user.displayName ?? "User",
                    style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () => context.go('/home'),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    // context.go('/settings');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    context.go('/signin');
                  },
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              children: [
                Text("Welcome, ${data['displayName'] ?? user.displayName}!", style: Theme.of(context).textTheme.headlineSmall),
                Text("Email: ${data['email'] ?? user.email}"),
                const SizedBox(height: 24),
                Text("Your Preferences:", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...prefs.entries.map((e) => Text("${e.key}: ${e.value}")).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}

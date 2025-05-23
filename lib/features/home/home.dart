import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../preferences/user_preferences.dart';
// ... other imports

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final UserPreferences? prefs = GoRouterState.of(context).extra as UserPreferences?;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              context.go('/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null) ...[
                Text('Name: ${user.displayName ?? "Unknown"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Email: ${user.email ?? "Unknown"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
              ],
              if (prefs != null) ...[
                Text('Gender: ${prefs.gender}'),
                Text('Cooking Time: ${prefs.cookingTime}'),
                Text('Allergies: ${prefs.allergies.join(', ')}'),
                Text('Diets: ${prefs.diets.join(', ')}'),
                Text('Cuisines: ${prefs.cuisines.join(', ')}'),
                Text('Spice Level: ${prefs.spiceLevel}'),
                Text('Barriers: ${prefs.barriers.join(', ')}'),
              ] else
                const Text('No preferences found.'),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

Future<void> _checkSession() async {
  final user = FirebaseAuth.instance.currentUser;
  print("Current UID: ${user?.uid}");
  if (user == null) {
    context.go('/signin');
    return;
  }
  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final data = doc.data();
  print("Firestore data: $data");
  if (data == null || !(data['onboardingCompleted'] ?? false)) {
    context.go('/preferences');
  } else {
    context.go('/home');
  }
}


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

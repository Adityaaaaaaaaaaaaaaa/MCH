import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '/utils/colors.dart';
import '/utils/lottie_animation.dart';
import '/utils/snackbar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Future.microtask(() => context.go('/'));
      return;
    }
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data();
    if (data == null || !(data['onboardingCompleted'] ?? false)) {
      Future.microtask(() => context.go('/preferences'));
    } else {
      SnackbarUtils.alert(
        context, 
        "Welcome ${data['displayName'] ?? 'user'} !",
        typeInfo: TypeInfo.success,
        position: MessagePosition.top,
        duration: 5,
        icon: Icons.star_rate_rounded,
        iconColor: Colors.greenAccent
      );
      Future.microtask(() => context.go('/home'));
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: bgColor(context),
      body: Center(
        child: 
          LottieOverlay(
            assetPath: 'assets/animations/Animation_fire.json',
            width: 300,
            height: 300,
            backgroundColor: Colors.transparent,
          ),
      ),
    );
  }
}

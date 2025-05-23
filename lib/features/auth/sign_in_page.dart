import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      // Always sign out first so the picker appears
      await GoogleSignIn().signOut();

      // Now trigger the picker (this always shows the account picker)
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User canceled sign-in
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // On success, go to home page
      context.go('/home');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign in failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 36),
              Text(
                'My Cooking Helper',
                style: TextStyle(
                  fontFamily: 'DancingScript', // Or use your font, else default
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Image.asset(
                "assets/images/loginSignup/signup.png",
                height: 210,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 28),
              const Text(
                'Login or Sign up to continue\nto My Cooking Helper',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Google Sign In Button
              ElevatedButton.icon(
                icon: Image.asset(
                  "assets/images/loginSignup/google_logo.png",
                  width: 24,
                  height: 24,
                ),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 1,
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                onPressed: () => _signInWithGoogle(context),
              ),
              const SizedBox(height: 16),
              // Apple Sign In (UI only)
              ElevatedButton.icon(
                icon: Image.asset(
                  "assets/images/loginSignup/apple_logo.png",
                  width: 24,
                  height: 24,
                ),
                label: const Text(
                  'Continue with Apple',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 1,
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                onPressed: () {
                  // TODO: Implement Apple sign in
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Apple Sign-In not yet implemented.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text.rich(
                TextSpan(
                  text: 'By clicking continue, you agree to our ',
                  children: [
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ],
                ),
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

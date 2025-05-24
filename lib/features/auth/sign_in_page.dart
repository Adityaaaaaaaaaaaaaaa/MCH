import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _gradientIndex = 0;

  final List<List<Color>> _gradients = [
    [Color(0xFFB8E1FC), Color(0xFFE5F1FA)],
    [Color(0xFFD0F2C7), Color(0xFFE5F1FA)],
    [Color(0xFFF9D4C1), Color(0xFFE5F1FA)],
    [Color(0xFFACE0F9), Color(0xFFD5E8FC)],
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        setState(() {
          _gradientIndex = (_gradientIndex + 1) % _gradients.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      context.go('/splash');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextGradient = _gradients[(_gradientIndex + 1) % _gradients.length];

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Interpolate between two gradients
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: List.generate(
                  _gradients[_gradientIndex].length,
                  (i) => Color.lerp(
                    _gradients[_gradientIndex][i],
                    nextGradient[i],
                    _animation.value,
                  )!,
                ),
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              children: [
                const SizedBox(height: 64), // More top space!
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
                const SizedBox(height: 42), // Moved image down
                Image.asset(
                  "assets/images/loginSignup/signup.png",
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 48), // Extra space before login text
                const Text(
                  'Login or Sign up to continue\nto My Cooking Helper',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 56), // Buttons moved further down
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Apple Sign-In not yet implemented.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 42),
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
      ),
    );
  }
}

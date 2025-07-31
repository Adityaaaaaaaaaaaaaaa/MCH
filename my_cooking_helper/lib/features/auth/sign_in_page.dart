// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
import '/utils/snackbar.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      // Always sign out any previous Google session.
      await GoogleSignIn.instance.signOut();

      // Authenticate the user.
      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();

      // Get the authentication tokens (now a getter, not a Future).
      final googleAuth = account.authentication;

      // Create a credential for Firebase Auth.
      final credential = GoogleAuthProvider.credential(
        //accessToken: googleAuth.accessToken, // accessToken is not available as in v6, but idToken suffices for Firebase Auth.
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential.
      await FirebaseAuth.instance.signInWithCredential(credential);

      context.go('/splash');
    } catch (e) {
      SnackbarUtils.alert(
        context,
        "Sign in failed!",
        typeInfo: TypeInfo.error,
        position: MessagePosition.top,
        duration: 3,
      );
    }
  }

  Widget _buildGlassButton({
    required String text,
    required String iconPath,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52.h,
        margin: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.10), Colors.blueGrey.withOpacity(0.25)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.black.withOpacity(0.15),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(iconPath, width: 22.w, height: 22.h),
                SizedBox(width: 10.w),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color(0xFF1F1B2E), // Deep base for contrast
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(height: 30.h),
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      //color: Colors.blueGrey.withOpacity(0.05),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      'My Cooking Helper',
                      style: TextStyle(
                        fontFamily: 'DancingScript',
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ).asGlass(
                    blurX: 10,
                    blurY: 10,
                    tintColor: Colors.blueGrey,
                    clipBorderRadius: BorderRadius.circular(24.r),
                  ),
                  SizedBox(height: 24.h),
                  Image.asset(
                    "assets/images/loginSignup/signup.png",
                    height: 160.h,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.r),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueGrey.withOpacity(0.4),
                      Colors.black.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: Column(
                    children: [
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 22.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Sign in to continue your culinary journey',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                      _buildGlassButton(
                        text: 'Continue with Google',
                        iconPath: "assets/images/loginSignup/google_logo.png",
                        onPressed: () => _signInWithGoogle(context),
                      ),
                      _buildGlassButton(
                        text: 'Continue with Apple',
                        iconPath: "assets/images/loginSignup/apple_logo.png",
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '<<< Apple Sign-In not yet implemented. >>>', 
                                textAlign: TextAlign.center, 
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text.rich(
                          TextSpan(
                            text: 'By continuing, you agree to our ',
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
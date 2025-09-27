// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/snackbar.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _borderController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _borderAnimation;

  bool _isGooglePressed = false;
  //bool _isApplePressed = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // ⬇️ Smoother, seamless loop (linear curve + longer period)
    _borderController = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // ⬇️ Linear progress avoids the abrupt “stop & restart” at the seam
    _borderAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _borderController,
      curve: Curves.linear,
    ));

    _fadeController.forward();
    _glowController.repeat(reverse: true);
    _borderController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    _borderController.dispose();
    super.dispose();
  }

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

  Color _getPrimaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED); // Premium purple
  }

  List<Color> _getBackgroundGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        const Color(0xFF1E1B4B),
        const Color(0xFF0F172A),
        const Color(0xFF020617),
      ];
    } else {
      return [
        const Color(0xFFF8FAFC),
        const Color(0xFFE2E8F0),
        const Color(0xFFCBD5E1),
      ];
    }
  }

  Color _getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : const Color(0xFF1E293B);
  }

  Color _getSubtextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF64748B);
  }

  // ⬇️ Renamed (no other behavior changes)
  Widget _buildAuthButton({
    required String text,
    required String iconPath,
    required VoidCallback onPressed,
    required bool isPressed,
    required ValueChanged<bool> onPressedChanged,
    required Color accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTapDown: (_) => onPressedChanged(true),
      onTapUp: (_) {
        onPressedChanged(false);
        onPressed();
      },
      onTapCancel: () => onPressedChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        height: 48.h,
        margin: EdgeInsets.symmetric(vertical: 6.h),
        transform: Matrix4.identity()
          ..scale(isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: isDark ? [
              accentColor.withOpacity(0.15),
              accentColor.withOpacity(0.05),
              Colors.white.withOpacity(0.08),
            ] : [
              accentColor.withOpacity(0.08),
              Colors.white,
              accentColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: accentColor.withOpacity(isPressed ? 0.4 : 0.25),
            width: 1.w,
          ),
          boxShadow: [
            if (!isPressed) ...[
              BoxShadow(
                color: accentColor.withOpacity(0.2),
                blurRadius: 8.r,
                spreadRadius: 0,
                offset: Offset(0, 2.h),
              ),
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                blurRadius: 4.r,
                offset: Offset(0, 1.h),
              ),
            ],
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isPressed ? 0.9 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    child: Image.asset(
                      iconPath,
                      width: 20.w,
                      height: 20.h,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBorder({required Widget child, required Color color}) {
    return AnimatedBuilder(
      animation: _borderAnimation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: SweepGradient(
              center: Alignment.center,
              // Linear, continuous rotation around the circle
              startAngle: _borderAnimation.value * 6.283185307179586, // 2π
              colors: [
                color.withOpacity(0.0),
                color.withOpacity(0.3),
                color.withOpacity(0.6),
                color.withOpacity(0.3),
                color.withOpacity(0.0),
              ],
              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
            ),
          ),
          padding: EdgeInsets.all(1.5.w),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = _getPrimaryColor(context);
    final backgroundGradient = _getBackgroundGradient(context);
    final textColor = _getTextColor(context);

    return Scaffold(
      body: Container(
        height: 1.sh,
        width: 1.sw,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: backgroundGradient,
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                
                // Header Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                                width: 1.w,
                              ),
                              gradient: LinearGradient(
                                colors: isDark ? [
                                  Colors.white.withOpacity(0.05),
                                  primaryColor.withOpacity(0.1),
                                ] : [
                                  Colors.white.withOpacity(0.9),
                                  primaryColor.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(_glowAnimation.value * 0.3),
                                  blurRadius: 15.r,
                                  spreadRadius: 2.r,
                                ),
                              ],
                            ),
                            child: Text(
                              'Cookgenix',
                              style: TextStyle(
                                fontFamily: 'Poppins', // Premium font
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Image.asset(
                            "assets/images/loginSignup/signup.png",
                            height: 200.h,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Sign In Card
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildAnimatedBorder(
                    color: primaryColor,
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.r),
                            gradient: LinearGradient(
                              colors: isDark ? [
                                Colors.white.withOpacity(0.08),
                                primaryColor.withOpacity(0.12),
                                Colors.black.withOpacity(0.05),
                              ] : [
                                Colors.white.withOpacity(0.95),
                                primaryColor.withOpacity(0.03),
                                Colors.grey.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.25),
                              width: 1.2.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(_glowAnimation.value * 0.2),
                                blurRadius: 20.r,
                                spreadRadius: 2.r,
                                offset: Offset(0, 8.h),
                              ),
                              BoxShadow(
                                color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
                                blurRadius: 15.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.r),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: EdgeInsets.all(20.w),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Welcome Back',
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        color: textColor,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    
                                    SizedBox(height: 6.h),
                                    
                                    Text(
                                      'Sign in to continue your culinary journey',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: _getSubtextColor(context),
                                        fontWeight: FontWeight.w400,
                                        height: 1.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    
                                    SizedBox(height: 20.h),
                                    
                                    _buildAuthButton(
                                      text: 'Continue with Google',
                                      iconPath: "assets/images/loginSignup/google_logo.png",
                                      onPressed: () => _signInWithGoogle(context),
                                      isPressed: _isGooglePressed,
                                      onPressedChanged: (pressed) {
                                        setState(() {
                                          _isGooglePressed = pressed;
                                        });
                                      },
                                      accentColor: const Color(0xFF4285F4),
                                    ),
                                    
                                    /*_buildAuthButton(
                                      text: 'Continue with Apple',
                                      iconPath: "assets/images/loginSignup/apple_logo.png",
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '<<< Apple Sign-In not yet implemented. >>>',
                                              textAlign: TextAlign.center,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: _getPrimaryColor(context).withOpacity(0.9),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                          ),
                                        );
                                      },
                                      isPressed: _isApplePressed,
                                      onPressedChanged: (pressed) {
                                        setState(() {
                                          _isApplePressed = pressed;
                                        });
                                      },
                                      accentColor: isDark ? Colors.white : const Color(0xFF1D1D1F),
                                    ),*/
                                    
                                    SizedBox(height: 16.h),
                                    
                                    Container(
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: isDark 
                                          ? Colors.black.withOpacity(0.15) 
                                          : Colors.white.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12.r),
                                        border: Border.all(
                                          color: isDark 
                                            ? Colors.white.withOpacity(0.1) 
                                            : Colors.grey.withOpacity(0.2),
                                          width: 0.5.w,
                                        ),
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
                                                color: Colors.white,
                                              ),
                                            ),
                                            const TextSpan(text: ' and '),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                decoration: TextDecoration.underline,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        style: TextStyle(
                                          color: _getSubtextColor(context),
                                          fontSize: 9.sp,
                                          height: 1.3,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

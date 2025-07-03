import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/emoji_animation.dart';
import '/utils/loader.dart';
import '/utils/snackbar.dart';
import '/utils/preference_utils.dart';
import '/widgets/navigation/glassmorphic_card.dart';
import '/widgets/navigation/appbar.dart';
import '/theme/app_theme.dart';
import 'profile_account.dart';
import 'preference_section.dart';
import 'account_actions.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});
  @override
  ConsumerState<Settings> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<Settings>
    with SingleTickerProviderStateMixin {
  User? user = FirebaseAuth.instance.currentUser;
  final usersRef = FirebaseFirestore.instance.collection('users');
  bool loading = true;

  String? gender, cookingTime, spiceLevel;
  List<String> allergies = [], diets = [], cuisines = [], barriers = [];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    if (user == null) return;
    final doc = await usersRef.doc(user!.uid).get();
    final data = doc.data();
    final prefs = data?['preferences'] as Map<String, dynamic>? ?? {};
    setState(() {
      gender = prefs['gender'] ?? "";
      cookingTime = prefs['cookingTime'] ?? "";
      spiceLevel = prefs['spiceLevel'] ?? "";
      allergies = _toStringList(prefs['allergies']);
      diets = _toStringList(prefs['diets']);
      cuisines = _toStringList(prefs['cuisines']);
      barriers = _toStringList(prefs['barriers']);
      loading = false;
    });
  }

  List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((v) => v.toString()).toList();
    } else if (value is String && value.isNotEmpty) {
      return value.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  Future<void> _updatePref(String key, dynamic value, {bool isMulti = false}) async {
    if (user == null || value == null) return;
    final updateValue = isMulti
        ? (value is List ? value.map((e) => e.label).toList() : [value.toString()])
        : (value is PreferenceOption ? value.label : value);
    await usersRef.doc(user!.uid).update({'preferences.$key': updateValue});
    setState(() {
      if (isMulti) {
        final listValue = updateValue as List;
        switch (key) {
          case PreferenceKeys.allergies:
            allergies = List<String>.from(listValue);
            break;
          case PreferenceKeys.diets:
            diets = List<String>.from(listValue);
            break;
          case PreferenceKeys.cuisines:
            cuisines = List<String>.from(listValue);
            break;
          case PreferenceKeys.barriers:
            barriers = List<String>.from(listValue);
            break;
        }
      } else {
        switch (key) {
          case PreferenceKeys.gender:
            gender = updateValue;
            break;
          case PreferenceKeys.cookingTime:
            cookingTime = updateValue;
            break;
          case PreferenceKeys.spiceLevel:
            spiceLevel = updateValue;
            break;
        }
      }
    });
    SnackbarUtils.show(
      context, 
      "Preference updated!",
      duration: 750, 
      behavior: SnackBarBehavior.floating,
      icon: Icons.check_circle_sharp,
      iconColor: Colors.lightGreenAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      textStyle: TextStyle(
        fontWeight: FontWeight.w900
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      backgroundColor: Colors.grey,
      width: 250.w,
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    SnackbarUtils.alert(
      context, 
      "Signed out!",
      typeInfo: TypeInfo.info,
      position: MessagePosition.top,
      duration: 3,
      iconColor: Colors.blue,
    );
    context.go('/signin');
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: loader(
          Colors.red, 
          70,                                   
          2,                                     
          10,                                      
          1500,                                 
        ),
      ),
    );

    try {
      final uid = user?.uid;
      await usersRef.doc(uid).delete();
      await user?.delete();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.of(context).pop(); 
      SnackbarUtils.show(
        context,
        "Signing out...!",
        duration: 1000,
        behavior: SnackBarBehavior.floating,
        icon: Icons.logout_outlined,
        iconColor: Colors.amber[200],
        textStyle: TextStyle(
          fontWeight: FontWeight.w900
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        backgroundColor: Colors.grey,
        width: 250.w,
      );
      await Future.delayed(const Duration(milliseconds: 1000));
      context.go('/');
      SnackbarUtils.alert(
        context,
        "Account deleted!",
        typeInfo: TypeInfo.success,
        position: MessagePosition.top,
        duration: 4,
      );
    } catch (e) {
      Navigator.of(context).pop(); 
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      SnackbarUtils.alert(
        context,
        "Error deleting account!",
        typeInfo: TypeInfo.error,
        position: MessagePosition.top,
        duration: 2,
      );
      context.go('/');
    }
  }
  
  Future<void> _switchAccount() async {
    try {
      await GoogleSignIn.instance.signOut();
      GoogleSignInAccount? account;

      // Authenticate in v7.x; signIn() removed
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        account = await GoogleSignIn.instance.authenticate();
      } else {
        // On platforms that do not support .authenticate(), 
        // you need to provide a platform-specific sign-in flow (e.g., use web button)
        throw Exception("Google Sign-In not supported on this platform.");
      }

      // ignore: unnecessary_null_comparison
      if (account != null) {
        final googleAuth = account.authentication;
        final credential = GoogleAuthProvider.credential(
          //accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final authResult = await FirebaseAuth.instance.signInWithCredential(credential);
        final switchedUser = authResult.user;
        setState(() {
          user = switchedUser;
        });

        // Check if user document exists in Firestore
        final userDoc = await usersRef.doc(switchedUser?.uid).get();
        if (userDoc.exists) {
          await _loadPrefs();
          SnackbarUtils.show(
            context, 
            "Account switched!",
            duration: 1000, 
            behavior: SnackBarBehavior.floating,
            icon: Icons.check_circle_sharp,
            iconColor: Colors.lightGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
            textStyle: TextStyle(
              fontWeight: FontWeight.w900
            ),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            backgroundColor: Colors.grey,
            width: 250.w,
          );
        } else {
          // Not registered, send to signin/onboarding
          SnackbarUtils.alert(
            context, 
            "Account not registered! Please sign in.",
            typeInfo: TypeInfo.warning,
            position: MessagePosition.top,
            duration: 5,
          );
          if (mounted) context.go('/signin');
        }
      }
    } catch (e) {
      SnackbarUtils.alert(
        context, 
        "Could not switch account!",
        typeInfo: TypeInfo.warning,
        position: MessagePosition.top,
        duration: 2,
        iconColor: Colors.yellow,
      );
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: EdgeInsets.fromLTRB(20.w, 26.h, 20.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmojiAnimation(name: 'warning', size: 40,),
              SizedBox(height: 10.h),
              Text(
                "Delete Account?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
              ),
              SizedBox(height: 12.h),
              const Text(
                "This action is irreversible. Are you sure you want to delete your account?",
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _deleteAccount();
                      },
                      child: const Text("Delete"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).asGlass(
          blurX: 15,
          blurY: 15,
          tintColor: Colors.redAccent,
          clipBorderRadius: BorderRadius.circular(18.r),
          frosted: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatar = user?.photoURL != null
        ? NetworkImage(user!.photoURL!)
        : const AssetImage("assets/app_icon.png");

    double imgOpacity = 0.80;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        showMenu: false,
        title: "Settings",
        themeToggleWidget: const ThemeToggleButton(),
        onMenuTap: () => context.push('/home'),
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
      ),
      body: Stack(
        children: [
          //BACKGROUND IMAGES
          Positioned(
            top: 60,
            left: 100,
            child: Transform.rotate(
              angle: -1.5708, //radians
              child: Opacity(
                opacity: imgOpacity,
                child: Image.asset(
                  'assets/images/settings/settings3.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 250,
            left: 40,
            child: Transform.rotate(
              angle: 0.3, 
              child: Opacity(
                opacity: imgOpacity,
                child: Image.asset(
                  'assets/images/settings/settings1.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 55,
            right: 35,
            child: Transform.rotate(
              angle: 0.1, 
              child: Opacity(
                opacity: imgOpacity,
                child: Image.asset(
                  'assets/images/settings/settings2.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 75,
            left: 20,
            child: Transform.rotate(
              angle: -0.4, 
              child: Opacity(
                opacity: imgOpacity,
                child: Image.asset(
                  'assets/images/settings/settings3.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          ListView(
            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            children: [
              SizedBox(height: 30.h),
              // Profile: Only profile and switch account
              ProfileAccountSection(
                user: user,
                avatar: avatar,
                onSwitchAccount: _switchAccount,
              ),
              SizedBox(height: 25.h),
              // Preferences
              PreferenceSection(
                gender: gender,
                cookingTime: cookingTime,
                spiceLevel: spiceLevel,
                allergies: allergies,
                diets: diets,
                cuisines: cuisines,
                barriers: barriers,
                onUpdatePref: _updatePref,
              ),
              SizedBox(height: 25.h),
              // Theme 
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 22.w),
                child: GlassmorphicCard(
                  borderRadius: 20.r,
                  blur: 14,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Text(
                          "Change Theme",
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      const ThemeToggleButton(),
                    ],
                  ),
                ),
              ),
              // Account actions
              SizedBox(height: 25.h),
              AccountActionsSection(
                onSignOut: _signOut,
                onDelete: _showDeleteDialog,
              ),
              SizedBox(height: 25.h),
            ],
          ),
        ],
      ),
    );
  }
}

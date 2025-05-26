import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../theme/glassmorphic_card.dart';
import '../../theme/app_theme.dart';
import '../preferences/preference_utils.dart';
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

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
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
    ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(
          content: Text("Preference updated!"),
          duration: const Duration(milliseconds: 500),
        )
      );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    context.go('/signin');
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final uid = user?.uid;
      await usersRef.doc(uid).delete();
      await user?.delete();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(
            content: Text("Signing out..."), 
            duration: Duration(milliseconds: 1000),
          )
        );
      await Future.delayed(const Duration(milliseconds: 1000));
      context.go('/');
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(
            content: Text("Account deleted."), 
            duration: Duration(milliseconds: 500),
          )
        );  
    } catch (e) {
      Navigator.of(context).pop();
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
            content: Text("Error deleting account: $e"),
            duration: Duration(milliseconds: 2000),
          )
        );
      context.go('/');
    }
  }

  Future<void> _switchAccount() async {
    try {
      await GoogleSignIn().signOut();
      final account = await GoogleSignIn().signIn();
      if (account != null) {
        final googleAuth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
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
          ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(
                content: Text("Account switched!"),
                duration: Duration(milliseconds: 500),
              )
            );
        } else {
          // Not registered, send to signin/onboarding
          ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(
                content: Text("Account not registered. Please sign in."),
                duration: Duration(milliseconds: 1000),
              )
            );
          if (mounted) context.go('/signin');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
          content: Text("Could not switch account: $e"),
          duration: const Duration(milliseconds: 1500),
        )
      );
    }
  }


  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Delete Account?"),
        content: const Text("This action is irreversible. Are you sure you want to delete your account?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteAccount();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    /* leave commented, will see later 
    if (loading) {
      return Scaffold(
        body: Center(
          child: loader(
            Colors.deepOrange, // color
            70,                // size
            5,                 // lineWidth
            8,                 // itemCount
            300               // duration (ms)
          ),
        ),
      );
    }*/
    final avatar = user?.photoURL != null
        ? NetworkImage(user!.photoURL!)
        : const AssetImage("assets/app_icon.png");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          children: [
            // Glassmorphic App Bar with Back Button
            Padding(
              padding: const EdgeInsets.only(top: 36, left: 16, right: 16, bottom: 10),
              child: GlassmorphicCard(
                borderRadius: 24,
                blur: 16,
                opacity: 0.15,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: theme.colorScheme.primary, size: 28),
                      onPressed: () => context.go('/home'),
                      tooltip: "Back to Home",
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Settings",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const ThemeToggleButton(),
                  ],
                ),
              ),
            ),
            // Profile: Only profile and switch account
            ProfileAccountSection(
              user: user,
              avatar: avatar,
              onSwitchAccount: _switchAccount,
            ),
            const SizedBox(height: 34),
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
            const SizedBox(height: 30),
            // Theme toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: GlassmorphicCard(
                borderRadius: 28,
                blur: 14,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Change Theme", style: theme.textTheme.bodyLarge),
                    const ThemeToggleButton(),
                  ],
                ),
              ),
            ),
            // Account actions
            const SizedBox(height: 18),
            AccountActionsSection(
              onSignOut: _signOut,
              onDelete: _showDeleteDialog,
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}

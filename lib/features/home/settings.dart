import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/glassmorphic_card.dart';
import '../../core/theme_toggle_button.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  ConsumerState<Settings> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<Settings>
    with SingleTickerProviderStateMixin {
  User? user = FirebaseAuth.instance.currentUser;
  final usersRef = FirebaseFirestore.instance.collection('users');
  bool loading = true;

  String? cuisine;
  String? diet;
  String? allergies;
  String? mealTime;

  final cuisineOptions = ["Italian", "Chinese", "Indian", "Other"];
  final dietOptions = ["None", "Vegetarian", "Vegan", "Halal", "Kosher"];
  final allergyOptions = ["None", "Gluten", "Lactose", "Peanut", "Other"];
  final mealTimeOptions = ["Morning", "Afternoon", "Evening"];

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
    setState(() {
      cuisine = data?['preferredCuisine'] ?? cuisineOptions.first;
      diet = data?['dietaryPreference'] ?? dietOptions.first;
      allergies = data?['allergies'] ?? allergyOptions.first;
      mealTime = data?['preferredMealTime'] ?? mealTimeOptions.first;
      loading = false;
    });
  }

  Future<void> _updatePref(String key, String? value) async {
    if (user == null || value == null) return;
    await usersRef.doc(user!.uid).update({key: value});
    setState(() {
      switch (key) {
        case 'preferredCuisine':
          cuisine = value;
          break;
        case 'dietaryPreference':
          diet = value;
          break;
        case 'allergies':
          allergies = value;
          break;
        case 'preferredMealTime':
          mealTime = value;
          break;
      }
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Preference updated!")));
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(child: CircularProgressIndicator()),
    );
    try {
      final uid = user?.uid;
      await usersRef.doc(uid).delete();
      await user?.delete();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loader
      context.go('/');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Account deleted.")));
    } catch (e) {
      Navigator.of(context).pop(); // Close loader
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error deleting account: $e")));
    }
  }

  Future<void> _switchAccount() async {
    try {
      await GoogleSignIn().signOut(); // Sign out from all accounts
      final account = await GoogleSignIn().signIn(); // Let user pick another account
      if (account != null) {
        final googleAuth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        setState(() {
          user = FirebaseAuth.instance.currentUser;
        });
        await _loadPrefs();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Account switched!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Could not switch account: $e")));
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Delete Account?"),
        content: const Text(
            "This action is irreversible. Are you sure you want to delete your account?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteAccount();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final avatar = user?.photoURL != null
        ? NetworkImage(user!.photoURL!)
        : const AssetImage("assets/images/chef_avatar.png");

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
                    // Optionally: Theme toggle button here
                    const ThemeToggleButton(),
                  ],
                ),
              ),
            ),
            // Profile Card with glass and Hero
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
              child: Hero(
                tag: "profile-icon",
                child: GlassmorphicCard(
                  borderRadius: 34,
                  blur: 18,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: avatar as ImageProvider,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.09),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.displayName ?? "User",
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text(user?.email ?? "",
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.switch_account),
                        label: const Text("Switch"),
                        onPressed: _switchAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.86),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 34),

            // Glass card with dropdowns
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: GlassmorphicCard(
                borderRadius: 30,
                blur: 15,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Your Preferences",
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _SettingsDropdown(
                      title: "Preferred cuisines",
                      value: cuisine!,
                      options: cuisineOptions,
                      onChanged: (val) => _updatePref('preferredCuisine', val),
                    ),
                    _SettingsDropdown(
                      title: "Dietary preferences",
                      value: diet!,
                      options: dietOptions,
                      onChanged: (val) => _updatePref('dietaryPreference', val),
                    ),
                    _SettingsDropdown(
                      title: "Allergies/intolerances",
                      value: allergies!,
                      options: allergyOptions,
                      onChanged: (val) => _updatePref('allergies', val),
                    ),
                    _SettingsDropdown(
                      title: "Preferred meal time",
                      value: mealTime!,
                      options: mealTimeOptions,
                      onChanged: (val) => _updatePref('preferredMealTime', val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Theme toggle, glass card
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
            const SizedBox(height: 26),

            // Sign out button, glass card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: GlassmorphicCard(
                borderRadius: 20,
                blur: 10,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Sign Out", style: theme.textTheme.bodyLarge),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text("Sign Out"),
                      onPressed: _signOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.93),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Delete account, glass card with warning
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
              child: GlassmorphicCard(
                borderRadius: 16,
                blur: 8,
                opacity: 0.22,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Delete your Account",
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            "Irreversible action!",
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: const Text("Delete"),
                      onPressed: () => _showDeleteDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDropdown extends StatelessWidget {
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _SettingsDropdown({
    Key? key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodyMedium),
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            child: DropdownButtonFormField<String>(
              value: value,
              items: options
                  .map((opt) =>
                      DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

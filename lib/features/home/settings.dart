import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/glassmorphic_card.dart';
import '../../core/theme_toggle_button.dart';
import '../preferences/preference_utils.dart';

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

  // User preference fields
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

  // Helper: convert Firestore field (array/string) to List<String>
  List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((v) => v.toString()).toList();
    } else if (value is String && value.isNotEmpty) {
      return value.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  /// --- UPDATE PREF (handles multi and single, always updates preferences map) ---
  Future<void> _updatePref(String key, dynamic value, {bool isMulti = false}) async {
    if (user == null || value == null) return;
    final updateValue = isMulti
        ? (value is List ? value.map((e) => e.label).toList() : [value.toString()])
        : (value is PreferenceOption ? value.label : value);
    await usersRef.doc(user!.uid).update({'preferences.$key': updateValue});
    // Update UI only (no full reload spinner)
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
        .showSnackBar(SnackBar(content: Text("Preference updated!")));
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    context.go('/splash');
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
      Navigator.of(context).pop(); // Close loader
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Signing out...")));
      context.go('/');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Account deleted.")));
    } catch (e) {
      Navigator.of(context).pop(); // Close loader
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error deleting account: $e")));
      context.go('/'); // Redirect to 3 page onboarding
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

  // --- Map a List<String> to List<PreferenceOption> (for chips) ---
  List<PreferenceOption> mapLabelsToOptions(List<PreferenceOption> options, List<dynamic> labels) {
    return labels
        .where((label) => options.any((o) => o.label == label))  // Keep only labels that match an option
        .map((label) => options.firstWhere((o) => o.label == label)) // Find the exact matching option
        .toList();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

            // Preferences Card
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
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Gender (single select)
                    AnimatedPreferenceTile<PreferenceOption>(
                      title: "Gender",
                      value: PreferenceUtils.genders.firstWhere(
                        (opt) => opt.label == (gender ?? ""),
                        orElse: () => PreferenceUtils.genders.first,
                      ),
                      options: PreferenceUtils.genders,
                      multiSelect: false,
                      onChanged: (newVal) => _updatePref(PreferenceKeys.gender, newVal.label),
                    ),

                    // Cooking Time (single select)
                    AnimatedPreferenceTile<PreferenceOption>(
                      title: "Cooking Time",
                      value: PreferenceUtils.cookingTimes.firstWhere(
                        (opt) => opt.label == (cookingTime ?? ""),
                        orElse: () => PreferenceUtils.cookingTimes.first,
                      ),
                      options: PreferenceUtils.cookingTimes,
                      multiSelect: false,
                      onChanged: (newVal) => _updatePref(PreferenceKeys.cookingTime, newVal.label),
                    ),

                    // Allergies (multi select)
                    AnimatedPreferenceTile<PreferenceOption>(
                      title: "Allergies / Intolerances",
                      value: mapLabelsToOptions(PreferenceUtils.allergies, allergies),
                      options: PreferenceUtils.allergies,
                      multiSelect: true,
                      onChanged: (newVals) => _updatePref(PreferenceKeys.allergies, newVals, isMulti: true),
                    ),

                    // Diets (multi select)
                    AnimatedPreferenceTile<PreferenceOption>(
                      title: "Diet Preferences",
                      value: mapLabelsToOptions(PreferenceUtils.diets, diets),
                      options: PreferenceUtils.diets,
                      multiSelect: true,
                      onChanged: (newVals) => _updatePref(PreferenceKeys.diets, newVals, isMulti: true),
                    ),

                    // Cuisines Loved (multi select)
                    AnimatedPreferenceTile<PreferenceOption>(
                      title: "Cuisines Loved",
                      value: mapLabelsToOptions(PreferenceUtils.cuisines, cuisines),
                      options: PreferenceUtils.cuisines,
                      multiSelect: true,
                      onChanged: (newVals) => _updatePref(PreferenceKeys.cuisines, newVals, isMulti: true),
                    ),

                    // Spice Level (single select)
                    AnimatedPreferenceTile<PreferenceOption>(
                      title: "Spice Level",
                      value: PreferenceUtils.spiceLevels.firstWhere(
                        (opt) => opt.label == (spiceLevel ?? ""),
                        orElse: () => PreferenceUtils.spiceLevels.first,
                      ),
                      options: PreferenceUtils.spiceLevels,
                      multiSelect: false,
                      onChanged: (newVal) => _updatePref(PreferenceKeys.spiceLevel, newVal.label),
                    ),

                    // Barriers (multi select)
                    AnimatedPreferenceTile<PreferenceOption>(
                      title: "Barriers",
                      value: mapLabelsToOptions(PreferenceUtils.barriers, barriers),
                      options: PreferenceUtils.barriers,
                      multiSelect: true,
                      onChanged: (newVals) => _updatePref(PreferenceKeys.barriers, newVals, isMulti: true),
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
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
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

// ---------- Below: Improved AnimatedPreferenceTile & Modal ---------

class AnimatedPreferenceTile<T extends PreferenceOption> extends StatelessWidget {
  final String title;
  final dynamic value; // T or List<T>
  final List<T> options;
  final bool multiSelect;
  final Future<void> Function(dynamic newValue) onChanged;

  const AnimatedPreferenceTile({
    Key? key,
    required this.title,
    required this.value,
    required this.options,
    required this.multiSelect,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Display for multi: up to 3 chips, then "+n more"
    Widget multiDisplay() {
      final vals = value as List<T>;
      if (vals.isEmpty) {
        return Center(child: Chip(label: Text("None")));
      }
      final maxShow = 3;
      List<Widget> chips = vals
          .take(maxShow)
          .map((v) => Chip(
              label: Text(
                "${v.emoji} ${v.label}",
                style: TextStyle(color: theme.colorScheme.primary),
              )))
          .toList();
      if (vals.length > maxShow) {
        chips.add(Chip(
            label: Text("+${vals.length - maxShow} more",
                style: TextStyle(color: theme.colorScheme.primary))));
      }
      return Center(
        child: Wrap(
          spacing: 5,
          alignment: WrapAlignment.center,
          children: chips,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: theme.colorScheme.primary.withOpacity(0.045),
        title: Text(title, style: theme.textTheme.bodyLarge),
        subtitle: multiSelect
            ? multiDisplay()
            : value != null
                ? Center(
                    child: Text(
                      "${value.emoji} ${value.label}",
                      style: theme.textTheme.titleMedium,
                    ),
                  )
                : const Center(child: Text("None")),
        trailing: Icon(Icons.edit, color: theme.colorScheme.primary),
        onTap: () async {
          final result = await showModalBottomSheet(
            context: context,
            backgroundColor: theme.scaffoldBackgroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            isScrollControlled: true,
            builder: (ctx) => PreferenceEditModal<T>(
              title: title,
              options: options,
              currentValue: value,
              multiSelect: multiSelect,
            ),
          );
          if (result != null) {
            await onChanged(result);
          }
        },
      ),
    );
  }
}

class PreferenceEditModal<T extends PreferenceOption> extends StatefulWidget {
  final String title;
  final List<T> options;
  final dynamic currentValue; // T or List<T>
  final bool multiSelect;

  const PreferenceEditModal({
    Key? key,
    required this.title,
    required this.options,
    required this.currentValue,
    required this.multiSelect,
  }) : super(key: key);

  @override
  State<PreferenceEditModal<T>> createState() => _PreferenceEditModalState<T>();
}

class _PreferenceEditModalState<T extends PreferenceOption>
    extends State<PreferenceEditModal<T>>
    with SingleTickerProviderStateMixin {
  late List<T> selectedValues;
  late List<T> initialValues;

  @override
  void initState() {
    super.initState();
    if (widget.multiSelect) {
      selectedValues = List<T>.from(widget.currentValue ?? []);
      initialValues = List<T>.from(widget.currentValue ?? []);
    } else {
      selectedValues = [widget.currentValue as T? ?? widget.options.first];
      initialValues = [widget.currentValue as T? ?? widget.options.first];
    }
  }

  bool get hasChanged {
    if (widget.multiSelect) {
      return !(selectedValues.length == initialValues.length &&
          selectedValues.every((element) => initialValues.contains(element)));
    } else {
      return selectedValues.first != initialValues.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 22),
          if (widget.multiSelect)
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: widget.options.map((option) {
                  final selected = selectedValues.contains(option);
                  return FilterChip(
                    label: Text("${option.emoji} ${option.label}"),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (selected) {
                          selectedValues.remove(option);
                        } else {
                          selectedValues.add(option);
                        }
                      });
                    },
                    showCheckmark: true,
                    checkmarkColor: theme.colorScheme.primary,
                    selectedColor: theme.colorScheme.primary.withOpacity(0.20),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                    labelStyle: TextStyle(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  );
                }).toList(),
              ),
            )
          else
            Center(
              child: Column(
                children: widget.options.map((option) {
                  return RadioListTile<T>(
                    value: option,
                    groupValue: selectedValues.first,
                    onChanged: (val) {
                      setState(() => selectedValues = [val!]);
                    },
                    activeColor: theme.colorScheme.primary,
                    title: Text("${option.emoji} ${option.label}"),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Save"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasChanged
                        ? Colors.green
                        : theme.disabledColor,
                  ),
                  onPressed: hasChanged
                      ? () => Navigator.of(context).pop(widget.multiSelect
                          ? selectedValues
                          : selectedValues.first)
                      : null,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

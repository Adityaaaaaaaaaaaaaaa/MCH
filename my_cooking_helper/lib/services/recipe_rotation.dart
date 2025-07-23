// /services/recipe_rotation.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 1. Rotates and shuffles recipes to prioritize freshness and variety.
List<T> rotateRecipes<T>(
  List<T> recipes,
  Map<String, DateTime> history, {
  int snoozeDays = 2,
  int maxFresh = 8,
  required String Function(T recipe) getId,
  DateTime? now,
}) {
  now ??= DateTime.now();
  final fresh = <T>[];
  final snoozed = <T>[];
  for (final r in recipes) {
    final id = getId(r);
    final lastShown = history[id];
    if (lastShown == null || now.difference(lastShown).inDays >= snoozeDays) {
      fresh.add(r);
    } else {
      snoozed.add(r);
    }
  }
  fresh.shuffle(Random());
  snoozed.shuffle(Random());
  return [...fresh.take(maxFresh), ...snoozed, ...fresh.skip(maxFresh)];
}

/// 2. Fetch user recipe history from Firestore and parse as Map<String, DateTime>
Future<Map<String, DateTime>> fetchUserRecipeHistory(String userId) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  final historyRaw = doc.data()?['recipeHistory'] as Map<String, dynamic>? ?? {};
  final history = <String, DateTime>{};
  historyRaw.forEach((k, v) {
    if (v is String) {
      history[k] = DateTime.parse(v);
    } else if (v is Timestamp) {
      history[k] = v.toDate();
    }
  });
  return history;
}     

/// 3. Update recipe history (can be optimized to trim history for Firestore size limits)
Future<void> updateUserRecipeHistory(
  String userId,
  List<String> shownIds, {
  int trimTo = 300,
  int? maxDaysOld, // e.g., 5 means remove anything last shown >5 days ago
}) async {
  // Fetch current history
  final currentHistory = await fetchUserRecipeHistory(userId);

  final now = DateTime.now().toUtc();

  // 1. Remove old entries if maxDaysOld is set
  if (maxDaysOld != null) {
    currentHistory.removeWhere((id, dt) => now.difference(dt).inDays > maxDaysOld);
  }

  // 2. Add new shownIds
  for (var id in shownIds) {
    currentHistory[id] = now;
  }

  // 3. Trim if too large (by count)
  if (currentHistory.length > trimTo) {
    final entries = currentHistory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Newest first
    final trimmed = Map<String, DateTime>.fromEntries(entries.take(trimTo));
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'recipeHistory': trimmed.map((k, v) => MapEntry(k, v.toIso8601String()))
    });
  } else {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'recipeHistory': currentHistory.map((k, v) => MapEntry(k, v.toIso8601String()))
    });
  }
}

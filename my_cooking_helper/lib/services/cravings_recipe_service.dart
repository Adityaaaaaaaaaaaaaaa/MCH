import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart' show sha256;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/models/cravings.dart';
import '/services/inventory_service.dart';

// ignore: constant_identifier_names
const String _BLUE = "\x1B[34m";
// ignore: constant_identifier_names
const String _RESET = "\x1B[0m";

class CravingsRecipeService {
  CravingsRecipeService._();

  // Stable key (ai:<hash>)
  static String computeRecipeKey(CravingRecipeModel r) {
    final title = _normStr(r.title);

    // Ingredient names only; normalize + sort for stability.
    final req = r.requiredIngredients.map(_ingredientName).toList();
    final opt = r.optionalIngredients.map(_ingredientName).toList();
    final ingredients = [...req, ...opt]..sort();

    // Normalized instructions.
    final steps = r.instructions.map((e) => _normStr(e.toString())).toList();

    final payload = jsonEncode(<String, dynamic>{
      't': title,
      'i': ingredients,
      's': steps,
    });

    final digest = sha256.convert(utf8.encode(payload)).toString();
    final short = digest.substring(0, 24); // 24 hex chars is plenty
    return 'ai:$short';
  }

  // Split "290825_1223_01" -> sessionId="290825_1223", trackerId="290825_1223_01"
  static ({String sessionId, String trackerId}) splitIds(String fullId) {
    final i = fullId.lastIndexOf('_');
    if (i <= 0) return (sessionId: fullId, trackerId: fullId);
    return (sessionId: fullId.substring(0, i), trackerId: fullId);
  }

  // Favourite toggle (real-time)
  // Mirrors to session tracker and user canonical tracker.
  static Future<void> updateFavouriteStatus({
    required String uid,
    required CravingRecipeModel recipe,
    required bool isFavourite,
  }) async {
    final db = FirebaseFirestore.instance;
    final ids = splitIds(recipe.id);
    final recipeKey = computeRecipeKey(recipe);

    final sessionTrackerRef = db
        .collection('users').doc(uid)
        .collection('aiCravings').doc(ids.sessionId)
        .collection('trackers').doc(ids.trackerId);

    final userTrackerRef = db
        .collection('users').doc(uid)
        .collection('userTrackers').doc(recipeKey);

    final batch = db.batch();

    // Session-level tracker
    batch.set(sessionTrackerRef, {
      'recipeKey': recipeKey,
      'isFavourite': isFavourite,
      'markFavOn': isFavourite ? FieldValue.serverTimestamp() : FieldValue.delete(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // User-level canonical (+ pointers for quick navigation)
    batch.set(userTrackerRef, {
      'isFavourite': isFavourite,
      'markFavOn': isFavourite ? FieldValue.serverTimestamp() : FieldValue.delete(),
      'recipeTitle': recipe.title,
      'hasImage': recipe.hasImage == true,
      'source': 'ai',
      'lastSeenSessionId': ids.sessionId,
      'lastSeenTrackerId': ids.trackerId,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // Mark as cooked (batched, writes both session + user timelines)
  static Future<void> markAsCooked({
    required String uid,
    required CravingRecipeModel recipe,
    required bool keepFavourite, // preserve current heart state
  }) async {
    final db = FirebaseFirestore.instance;
    final ids = splitIds(recipe.id);
    final recipeKey = computeRecipeKey(recipe);

    final userTrackerRef = db
        .collection('users').doc(uid)
        .collection('userTrackers').doc(recipeKey);
    final userCookEventRef = userTrackerRef.collection('cookEvents').doc();

    // If the "id" is not in expected shape, still record the canonical cook event
    final hasUnderscore = recipe.id.contains('_');
    if (!hasUnderscore) {
      final fb = db.batch();
      fb.set(userTrackerRef, {
        'timesCooked': FieldValue.increment(1),
        'lastCookedAt': FieldValue.serverTimestamp(),
        'isFavourite': keepFavourite,
        'recipeTitle': recipe.title,
        'hasImage': recipe.hasImage == true,
        'source': 'ai',
      }, SetOptions(merge: true));
      fb.set(userCookEventRef, {
        'cookedAt': FieldValue.serverTimestamp(),
      });
      await fb.commit();

      // --- Non-blocking inventory deduction (AI fallback path) --------------------
      try {
        final items = <CookedIngredientPayload>[];
        for (final ing in recipe.requiredIngredients) {
          final name = ((ing.name ?? '').toString()).trim();
          final amt  = ((ing.amount ?? 0) as num).toDouble();
          final unit = ((ing.unit ?? '').toString()).trim();
          if (name.isNotEmpty && amt > 0) {
            items.add(CookedIngredientPayload(name, amt, unit));
          }
        }
        if (items.isNotEmpty) {
          // ignore: unawaited_futures
          unawaited(InventoryService().deductViaBackend(
            uid: uid,
            ingredients: items,
            apply: true,
          ));
        }
      } catch (e) {
        // ignore: avoid_print
        print('$_BLUE[DEBUG] Cravings.markAsCooked: deduction call failed (fallback) -> $e$_RESET');
      }
      // ---------------------------------------------------------------------------

      return;
    }

    final sessionTrackerRef = db
        .collection('users').doc(uid)
        .collection('aiCravings').doc(ids.sessionId)
        .collection('trackers').doc(ids.trackerId);
    final sessionCookEventRef = sessionTrackerRef.collection('cookEvents').doc();

    // Use a batch with atomic increments—simple and reliable.
    final batch = db.batch();

    // Session tracker: increment and event
    batch.set(sessionTrackerRef, {
      'recipeKey': recipeKey,
      'cookedCount': FieldValue.increment(1),
      'lastCookedAt': FieldValue.serverTimestamp(),
      'isFavourite': keepFavourite,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(sessionCookEventRef, {
      'cookedAt': FieldValue.serverTimestamp(),
    });

    // User canonical: increment and event (centralised timeline across sessions)
    batch.set(userTrackerRef, {
      'timesCooked': FieldValue.increment(1),
      'lastCookedAt': FieldValue.serverTimestamp(),
      'isFavourite': keepFavourite,
      'recipeTitle': recipe.title,
      'hasImage': recipe.hasImage == true,
      'source': 'ai',
      'lastSeenSessionId': ids.sessionId,   // pointers for fast navigation
      'lastSeenTrackerId': ids.trackerId,
    }, SetOptions(merge: true));
    batch.set(userCookEventRef, {
      'cookedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // ignore: avoid_print
    print('$_BLUE[DEBUG] Cravings.markAsCooked: uid=$uid key=$recipeKey +1 cooked (session+user events)$_RESET');

    // Non-blocking inventory deduction (AI normal path)
    try {
      final items = <CookedIngredientPayload>[];
      final all = [...recipe.requiredIngredients, ...recipe.optionalIngredients];
      for (final ing in all) {
        final name = ((ing.name ?? '').toString()).trim();
        final amt  = ((ing.amount ?? 0) as num).toDouble();
        final unit = ((ing.unit ?? '').toString()).trim();
        if (name.isNotEmpty && amt > 0) {
          items.add(CookedIngredientPayload(name, amt, unit));
        }
      }
      if (items.isNotEmpty) {
        // ignore: unawaited_futures
        unawaited(InventoryService().deductViaBackend(
          uid: uid,
          ingredients: items,
          apply: true,
        ));
      }
    } catch (e) {
      // ignore: avoid_print
      print('$_BLUE[DEBUG] Cravings.markAsCooked: deduction call failed (normal) -> $e$_RESET');
    }
  }

  // Helpers
  static String _normStr(String? s) {
    if (s == null) return '';
    return s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _ingredientName(dynamic e) {
    if (e == null) return '';
    if (e is String) return _normStr(e);
    if (e is Map) {
      final name = (e['name'] ?? e['original'] ?? e['title'] ?? '').toString();
      return _normStr(name);
    }
    try {
      final name = (e as dynamic).name?.toString();
      if (name != null) return _normStr(name);
    } catch (_) {/* ignore */}
    return _normStr(e.toString());
  }


  /// Toggle favourite directly by recipeKey (used from History card).
  static Future<void> updateFavouriteStatusByKey({
    required String uid,
    required String recipeKey,
    required bool isFavourite,
    String? recipeTitle,
    bool? hasImage,
    String? lastSeenSessionId,
    String? lastSeenTrackerId,
  }) async {
    final db = FirebaseFirestore.instance;
    final userTrackerRef = db
        .collection('users').doc(uid)
        .collection('userTrackers').doc(recipeKey);

    final batch = db.batch();
    batch.set(userTrackerRef, {
      'isFavourite': isFavourite,
      'markFavOn': isFavourite ? FieldValue.serverTimestamp() : FieldValue.delete(),
      if (recipeTitle != null) 'recipeTitle': recipeTitle,
      if (hasImage != null) 'hasImage': hasImage,
      if (lastSeenSessionId != null) 'lastSeenSessionId': lastSeenSessionId,
      if (lastSeenTrackerId != null) 'lastSeenTrackerId': lastSeenTrackerId,
      'source': 'ai',
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Fetch the AI craving recipe document by session+tracker.
  static Future<CravingRecipeModel?> fetchCravingBySessionTracker({
    required String uid,
    required String sessionId,
    required String trackerId,
  }) async {
    final snap = await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('aiCravings').doc(sessionId)
        .collection('recipes').doc(trackerId)
        .get();

    if (!snap.exists || snap.data() == null) return null;
    return CravingRecipeModel.fromFirestore(snap.data()!);
  }

  static Future<({String sessionId, String trackerId})?> resolvePointersForKey({
    required String uid,
    required String recipeKey,
  }) async {
    final db = FirebaseFirestore.instance;

    // 1) Check cached pointers on userTrackers/{recipeKey}
    final utRef = db.collection('users').doc(uid)
        .collection('userTrackers').doc(recipeKey);
    final utSnap = await utRef.get();
    final um = utSnap.data() ?? {};
    final sId = (um['lastSeenSessionId'] as String?) ?? '';
    final tId = (um['lastSeenTrackerId'] as String?) ?? '';
    if (sId.isNotEmpty && tId.isNotEmpty) {
      return (sessionId: sId, trackerId: tId);
    }

    // 2) Fallback: scan ONLY this user's sessions, and query trackers inside each
    final sessions = await db.collection('users').doc(uid)
        .collection('aiCravings').get();

    for (final s in sessions.docs) {
      final q = await s.reference.collection('trackers')
          .where('recipeKey', isEqualTo: recipeKey)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        final trackerId = q.docs.first.id;
        final sessionId = s.id;

        // Cache for next time
        await utRef.set({
          'lastSeenSessionId': sessionId,
          'lastSeenTrackerId': trackerId,
        }, SetOptions(merge: true));

        return (sessionId: sessionId, trackerId: trackerId);
      }
    }

    return null;
  }

  // Fetch a Craving recipe by stable recipeKey ('ai:<hash>').
  // Uses saved pointers if present; otherwise does a collectionGroup fallback.
  // Also persists the pointers so the next open is instant.
  // Fetch full recipe by recipeKey, using the safe resolver above.
  static Future<({
    CravingRecipeModel recipe,
    String sessionId,
    String trackerId,
  })?> fetchCravingByRecipeKey({
    required String uid,
    required String recipeKey,
  }) async {
    final db = FirebaseFirestore.instance;

    final ptr = await resolvePointersForKey(uid: uid, recipeKey: recipeKey);
    if (ptr == null) return null;

    final snap = await db.collection('users').doc(uid)
        .collection('aiCravings').doc(ptr.sessionId)
        .collection('recipes').doc(ptr.trackerId)
        .get();

    if (!snap.exists || snap.data() == null) return null;

    return (
      recipe: CravingRecipeModel.fromFirestore(snap.data()!),
      sessionId: ptr.sessionId,
      trackerId: ptr.trackerId
    );
  }

  // Write-only helper to persist lastSeen pointers without touching favourite, etc.
  static Future<void> rememberPointers({
    required String uid,
    required String recipeKey,
    required String sessionId,
    required String trackerId,
  }) async {
    final db = FirebaseFirestore.instance;
    final ref = db.collection('users').doc(uid)
        .collection('userTrackers').doc(recipeKey);

    await ref.set({
      'lastSeenSessionId': sessionId,
      'lastSeenTrackerId': trackerId,
      'source': 'ai',
    }, SetOptions(merge: true));
  }
}

// Stream the favourite flag by stable recipeKey (ai:<hash>)
final cravingFavouriteStatusProvider =
    StreamProvider.family<bool, String>((ref, recipeKey) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream<bool>.empty();
  final doc = FirebaseFirestore.instance
      .collection('users').doc(uid)
      .collection('userTrackers').doc(recipeKey);
  return doc.snapshots().map((s) => s.exists && (s.data()?['isFavourite'] == true));
});

// UI-only success flag for the "Mark as Cooked" animation
final cravingCookedSuccessProvider =
    StateProvider.autoDispose.family<bool, String>((ref, recipeKey) => false);

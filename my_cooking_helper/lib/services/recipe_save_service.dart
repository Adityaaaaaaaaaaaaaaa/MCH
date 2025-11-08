import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/models/recipe_detail.dart';
import '/services/inventory_service.dart';

class RecipeSaveService {
  static Future<void> markRecipeAsCooked({
    required BuildContext context,
    required RecipeDetail recipe,
    required String userId,
    required bool isFavourite,
  }) async {
    final firestore = FirebaseFirestore.instance;

    // --- Normalize IDs (string, non-empty) ---
    final rid = (recipe.id ?? '').toString().trim();
    final uid = userId.trim();
    if (rid.isEmpty || uid.isEmpty) {
      return;
    }

    // 1) Save to global pool if not exists
    final recipeDoc = firestore.collection('recipes').doc(rid);
    final exists = (await recipeDoc.get()).exists;
    if (!exists) {
      await recipeDoc.set(recipe.toJson());
    } else {
      // ignore: avoid_print
      print('\x1B[34m[DEBUG] markRecipeAsCooked: global recipe already exists recipes/$rid\x1B[0m');
    }

    // 2) Add/Update user history doc
    final historyRef = firestore
        .collection('users')
        .doc(uid)
        .collection('recipeHistory')
        .doc(rid);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(historyRef);

      // Always add a new cook event
      final cookEventsRef = historyRef.collection('cookEvents').doc();
      transaction.set(cookEventsRef, {
        'cookedAt': FieldValue.serverTimestamp(),
      });

      if (snapshot.exists) {
        // Heal missing summary fields while updating counters/timestamps
        final data = snapshot.data() ?? {};
        final needsTitle = (data['recipeTitle'] as String?)?.trim().isEmpty ?? true;
        final needsId = (data['recipeId'] as String?)?.trim().isEmpty ?? true;
        final needsImage = (data['imageUrl'] as String?)?.trim().isEmpty ?? true;

        transaction.set(
          historyRef,
          {
            'isFavourite': isFavourite,
            'lastCookedAt': FieldValue.serverTimestamp(),
            'timesCooked': FieldValue.increment(1),
            'imageUrl': recipe.image, 
            if (needsId) 'recipeId': rid,
            if (needsTitle) 'recipeTitle': (recipe.title ?? 'Untitled'),
            if (needsImage && (recipe.image ?? '').toString().isNotEmpty) 'imageUrl': recipe.image,
          },
          SetOptions(merge: true),
        );
      } else {
        // First time - write full summary 
        transaction.set(historyRef, {
          'recipeId': rid,
          'recipeTitle': (recipe.title ?? 'Untitled'),
          'isFavourite': isFavourite,
          'lastCookedAt': FieldValue.serverTimestamp(),
          'timesCooked': 1,
          'imageUrl': recipe.image,
        });
      }
    });

    await _healHistoryDoc(userId: uid, recipeId: rid);

    // Non-blocking inventory deduction (Spoonacular)
    try {
      final items = <CookedIngredientPayload>[];
      if ((recipe.extendedIngredients).isNotEmpty) {
        for (final ing in recipe.extendedIngredients) {
          final name = ((ing.nameClean ?? ing.name ?? '').toString()).trim();
          final amt  = (ing.amount ?? ing.measures?.metric?.amount ?? 0).toDouble();
          final unit = ((ing.unit ?? ing.measures?.metric?.unitShort ?? '').toString()).trim();
          if (name.isNotEmpty && amt > 0) {
            items.add(CookedIngredientPayload(name, amt, unit));
          }
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
      print('\x1B[34m[DEBUG] markRecipeAsCooked: deduction call failed -> $e\x1B[0m');
    }
    // ---------------------------------------------------------------------------
  }

  static Future<void> updateFavouriteStatus({
    required String recipeId,
    required String userId,
    required bool isFavourite,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final rid = recipeId.toString().trim();
    final uid = userId.trim();
    if (rid.isEmpty || uid.isEmpty) {
      return;
    }

    // If marking as favourite, set timestamp; if unmarking, clear it (kept same behavior)
    final favUpdate = {
      'isFavourite': isFavourite,
      'markFavOn': isFavourite ? FieldValue.serverTimestamp() : null,
    };

    await firestore
        .collection('users')
        .doc(uid)
        .collection('recipeHistory')
        .doc(rid)
        .set(favUpdate, SetOptions(merge: true));

    await _healHistoryDoc(userId: uid, recipeId: rid);
  }

  /// Heals a SINGLE history doc by copying missing title/image from recipes/{recipeId}
  static Future<void> _healHistoryDoc({
    required String userId,
    required String recipeId,
  }) async {
    final db = FirebaseFirestore.instance;
    final uid = userId.trim();
    final rid = recipeId.toString().trim();
    if (uid.isEmpty || rid.isEmpty) {
      return;
    }

    final historyRef = db.collection('users').doc(uid).collection('recipeHistory').doc(rid);
    final snap = await historyRef.get();
    if (!snap.exists) {
      return;
    }

    final data = snap.data() ?? {};
    final hasTitle = (data['recipeTitle'] as String?)?.trim().isNotEmpty == true;
    final hasImage = (data['imageUrl'] as String?)?.trim().isNotEmpty == true;

    if (hasTitle && hasImage) {
      return;
    }

    final rSnap = await db.collection('recipes').doc(rid).get();
    if (!rSnap.exists) {
      return;
    }

    final r = rSnap.data()!;
    final title = ((r['title']) as String?)?.trim() ?? 'Untitled';
    final img = (r['image'] ?? r['imageUrl'] ?? '') as String? ?? '';

    await historyRef.set({
      if (!hasTitle) 'recipeTitle': title,
      if (!hasImage && img.isNotEmpty) 'imageUrl': img,
      if ((data['recipeId'] as String?)?.trim().isEmpty ?? true) 'recipeId': rid,
    }, SetOptions(merge: true));
  }

  /// Full backfill for a user (run once from a debug button)
  static Future<void> backfillHistorySummaries(String userId) async {
    final db = FirebaseFirestore.instance;
    final uid = userId.trim();
    if (uid.isEmpty) {
      return;
    }

    final qs = await db.collection('users').doc(uid).collection('recipeHistory').get();

    for (final d in qs.docs) {
      final m = d.data();
      final hasTitle = (m['recipeTitle'] as String?)?.trim().isNotEmpty == true;
      final rid = (m['recipeId'] ?? d.id).toString();

      if (!hasTitle) {
        final rSnap = await db.collection('recipes').doc(rid).get();
        if (!rSnap.exists) {
          continue;
        }
        final r = rSnap.data()!;
        final title = ((r['title']) as String?)?.trim() ?? 'Untitled';
        final img = (r['image'] ?? r['imageUrl'] ?? '') as String? ?? '';
        await d.reference.set({
          'recipeId': rid,
          'recipeTitle': title,
          if (img.isNotEmpty) 'imageUrl': img,
        }, SetOptions(merge: true));
      }
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/models/recipe_detail.dart';

class RecipeSaveService {
  static Future<void> markRecipeAsCooked({
    required BuildContext context,
    required RecipeDetail recipe,
    required String userId,
    required bool isFavourite,
  }) async {
    final firestore = FirebaseFirestore.instance;

    // 1. Save to global pool if not exists
    final recipeDoc = firestore.collection('recipes').doc(recipe.id);
    final exists = (await recipeDoc.get()).exists;
    if (!exists) {
      await recipeDoc.set(recipe.toJson());
    }

    // 2. Add a new cook event
    final historyRef = firestore
        .collection('users')
        .doc(userId)
        .collection('recipeHistory')
        .doc(recipe.id);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(historyRef);

      // Always add a new cookEvent
      final cookEventsRef = historyRef.collection('cookEvents').doc();
      transaction.set(cookEventsRef, {
        'cookedAt': FieldValue.serverTimestamp(),
      });

      // Update the main doc (for quick queries)
      if (snapshot.exists) {
        transaction.update(historyRef, {
          'isFavourite': isFavourite,
          'lastCookedAt': FieldValue.serverTimestamp(),
          'timesCooked': FieldValue.increment(1),
        });
      } else {
        transaction.set(historyRef, {
          'recipeId': recipe.id,
          'recipeTitle': recipe.title,
          'isFavourite': isFavourite,
          'lastCookedAt': FieldValue.serverTimestamp(),
          'timesCooked': 1,
        });
      }
    });
  }

  static Future<void> updateFavouriteStatus({
    required String recipeId,
    required String userId,
    required bool isFavourite,
  }) async {
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('users')
        .doc(userId)
        .collection('recipeHistory')
        .doc(recipeId)
        .set({'isFavourite': isFavourite}, SetOptions(merge: true));
  }
}
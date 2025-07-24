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

    // 2. Save/update user recipe tracker
    await firestore
        .collection('users')
        .doc(userId)
        .collection('recipeHistory')
        .doc(recipe.id)
        .set({
          'recipeId': recipe.id,           
          'recipeTitle': recipe.title,  
          'isFavourite': isFavourite,
          'lastCookedAt': FieldValue.serverTimestamp(),
          'timesCooked': FieldValue.increment(1),
        }, SetOptions(merge: true));
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
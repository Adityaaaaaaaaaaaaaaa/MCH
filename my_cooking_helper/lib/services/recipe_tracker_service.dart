import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/recipe_detail.dart';
import '/models/recipe_history.dart';

class RecipeTrackerService {
  static Future<List<RecipeHistoryEntry>> fetchCookedRecipes(String userId) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('recipeHistory')
        .orderBy('lastCookedAt', descending: true)
        .get();

    return snap.docs
        .map((doc) => RecipeHistoryEntry.fromFirestore(doc.data()))
        .toList();
  }

  static Stream<List<RecipeHistoryEntry>> cookedRecipesStream(String userId) {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('recipeHistory')
        .orderBy('lastCookedAt', descending: true);

    return ref.snapshots().map((snapshot) =>
      snapshot.docs
        .map((doc) => RecipeHistoryEntry.fromFirestore(doc.data()))
        .toList()
    );
  }

  static Future<RecipeDetail?> fetchFullRecipeDetail(String recipeId) async {
    final doc = await FirebaseFirestore.instance.collection('recipes').doc(recipeId).get();
    if (doc.exists && doc.data() != null) {
      return RecipeDetail.fromJson(doc.data()!);
    }
    return null;
  }

  static Stream<List<RecipeHistoryEntry>> favouriteRecipesStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('recipeHistory')
        .where('isFavourite', isEqualTo: true)
        .orderBy('markFavOn', descending: true) // Show most recently favourited first
        .snapshots()
        .map((snapshot) =>
          snapshot.docs.map((doc) => RecipeHistoryEntry.fromFirestore(doc.data())).toList()
        );
  }
}

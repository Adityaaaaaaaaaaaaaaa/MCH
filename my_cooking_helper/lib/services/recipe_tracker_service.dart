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

  static Future<RecipeDetail?> fetchFullRecipeDetail(String recipeId) async {
    final doc = await FirebaseFirestore.instance.collection('recipes').doc(recipeId).get();
    if (doc.exists && doc.data() != null) {
      return RecipeDetail.fromJson(doc.data()!);
    }
    return null;
  }
}

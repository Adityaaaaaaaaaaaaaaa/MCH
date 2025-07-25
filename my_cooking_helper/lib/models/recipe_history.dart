
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeHistoryEntry {
  final String recipeId;
  final String recipeTitle;
  final bool isFavourite;
  final DateTime? lastCookedAt;
  final int timesCooked;

  RecipeHistoryEntry({
    required this.recipeId,
    required this.recipeTitle,
    required this.isFavourite,
    this.lastCookedAt,
    required this.timesCooked,
  });

  factory RecipeHistoryEntry.fromFirestore(Map<String, dynamic> data) {
    return RecipeHistoryEntry(
      recipeId: data['recipeId'] ?? '',
      recipeTitle: data['recipeTitle'] ?? '',
      isFavourite: data['isFavourite'] ?? false,
      lastCookedAt: data['lastCookedAt'] != null
          ? (data['lastCookedAt'] as Timestamp).toDate()
          : null,
      timesCooked: data['timesCooked'] ?? 0,
    );
  }
}

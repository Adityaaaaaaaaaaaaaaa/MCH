
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeHistoryEntry {
  final String recipeId;
  final String recipeTitle;
  final bool isFavourite;
  final DateTime? lastCookedAt;
  final int timesCooked;
  final String? imageUrl;
  final DateTime? markFavOn;

  RecipeHistoryEntry({
    required this.recipeId,
    required this.recipeTitle,
    required this.isFavourite,
    this.lastCookedAt,
    required this.timesCooked,
    this.imageUrl,
    this.markFavOn,
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
      imageUrl: data['imageUrl'] as String?,
      markFavOn: data['markFavOn'] is Timestamp ? (data['markFavOn'] as Timestamp).toDate() : null,
    );
  }

  // Update fromJson and toJson:
  factory RecipeHistoryEntry.fromJson(Map<String, dynamic> json) => RecipeHistoryEntry(
    recipeId: json['recipeId'] as String,
    recipeTitle: json['recipeTitle'] as String,
    timesCooked: json['timesCooked'] as int,
    lastCookedAt: (json['lastCookedAt'] as Timestamp?)?.toDate(),
    isFavourite: json['isFavourite'] ?? false,
    imageUrl: json['imageUrl'] as String?,     
    markFavOn: (json['markFavOn'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toJson() => {
    'recipeId': recipeId,
    'recipeTitle': recipeTitle,
    'timesCooked': timesCooked,
    'lastCookedAt': lastCookedAt,
    'isFavourite': isFavourite,
    'imageUrl': imageUrl, 
    'markFavOn': markFavOn,
  };
}


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

enum RecipeSource { normal, ai }

class UnifiedHistoryItem {
  final String id;                 // Normal: rid ; AI: recipeKey 'ai:<hash>'
  final RecipeSource source;
  final String title;
  final bool isFavourite;
  final int timesCooked;
  final DateTime? lastCookedAt;
  final String? imageUrl;          // Normal may have; AI may be null (uses placeholder)
  // Optional pointers for AI navigation
  final String? lastSeenSessionId;
  final String? lastSeenTrackerId;

  const UnifiedHistoryItem({
    required this.id,
    required this.source,
    required this.title,
    required this.isFavourite,
    required this.timesCooked,
    required this.lastCookedAt,
    this.imageUrl,
    this.lastSeenSessionId,
    this.lastSeenTrackerId,
  });

  // Build from users/{uid}/recipeHistory/{rid}
  factory UnifiedHistoryItem.fromNormal(String rid, Map<String, dynamic> m) {
    return UnifiedHistoryItem(
      id: rid,
      source: RecipeSource.normal,
      title: (m['recipeTitle'] as String?) ?? '',
      isFavourite: (m['isFavourite'] as bool?) ?? false,
      timesCooked: (m['timesCooked'] as int?) ?? 0,
      lastCookedAt: (m['lastCookedAt'] as dynamic)?.toDate(),
      imageUrl: (m['imageUrl'] as String?),
    );
  }

  // Build from users/{uid}/userTrackers/{ai:<hash>}
  factory UnifiedHistoryItem.fromAi(String recipeKey, Map<String, dynamic> m) {
    return UnifiedHistoryItem(
      id: recipeKey,
      source: RecipeSource.ai,
      title: (m['recipeTitle'] as String?) ?? '',
      isFavourite: (m['isFavourite'] as bool?) ?? false,
      timesCooked: (m['timesCooked'] as int?) ?? 0,
      lastCookedAt: (m['lastCookedAt'] as dynamic)?.toDate(),
      imageUrl: (m['hasImage'] == true) ? (m['imageUrl'] as String?) : null,
      lastSeenSessionId: m['lastSeenSessionId'] as String?,
      lastSeenTrackerId: m['lastSeenTrackerId'] as String?,
    );
  }
}

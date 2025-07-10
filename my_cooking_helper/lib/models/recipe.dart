class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final int totalTime;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final List<String> equipment;
  final String website;
  final List<String> videos;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.totalTime,
    required this.ingredients,
    required this.instructions,
    required this.equipment,
    required this.website,
    required this.videos,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // ingredients may be returned as list of strings or list of objects
    final rawIngredients = json['ingredients'] as List? ?? [];
    List<RecipeIngredient> ingredientObjs;
    if (rawIngredients.isNotEmpty && rawIngredients[0] is Map) {
      ingredientObjs = rawIngredients
          .map((e) => RecipeIngredient.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      ingredientObjs = rawIngredients
          .map((e) => RecipeIngredient(name: e.toString(), quantity: ""))
          .toList();
    }

    return Recipe(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      totalTime: json['totalTime'] ?? 0,
      ingredients: ingredientObjs,
      instructions: (json['instructions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      equipment: (json['equipment'] as List?)?.map((e) => e.toString()).toList() ?? [],
      website: json['website'] ?? '',
      videos: (json['videos'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class RecipeIngredient {
  final String name;
  final String quantity;

  RecipeIngredient({
    required this.name,
    required this.quantity,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? '',
    );
  }
}
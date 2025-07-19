class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final int totalTime;
  final int prepTime;
  final int cookTime;
  final int servings;
  final List<String> dishTypes;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final List<String> equipment;
  final String website;
  final List<String> videos;
  final Map<String, dynamic>? nutrition;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.totalTime,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.dishTypes,
    required this.ingredients,
    required this.instructions,
    required this.equipment,
    required this.website,
    required this.videos,
    this.nutrition,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    int parseTime(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    // Always fallback to an empty list if null
    final List<String> parsedDishTypes =
        (json['dishTypes'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

    return Recipe(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['image']?.toString() ?? '',
      totalTime: parseTime(json['readyInMinutes']),
      prepTime: parseTime(json['preparationMinutes']),
      cookTime: parseTime(json['cookingMinutes']),
      servings: parseTime(json['servings']),
      dishTypes: parsedDishTypes,  // <--- Always a non-null list
      ingredients: (json['extendedIngredients'] as List<dynamic>? ?? [])
          .map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
          .toList(),
      instructions: _parseInstructions(json),
      equipment: _parseEquipment(json),
      website: json['sourceUrl']?.toString() ?? '',
      videos: [], // Implement if your backend supports it
      nutrition: json['nutrition'] as Map<String, dynamic>?,
    );
  }

  static List<String> _parseInstructions(Map<String, dynamic> json) {
    if (json['analyzedInstructions'] is List && (json['analyzedInstructions'] as List).isNotEmpty) {
      final steps = json['analyzedInstructions'][0]['steps'] as List<dynamic>? ?? [];
      return steps.map((s) => s['step']?.toString() ?? '').where((e) => e.isNotEmpty).toList();
    }
    if (json['instructions'] is String && (json['instructions'] as String).isNotEmpty) {
      return (json['instructions'] as String)
          .split(RegExp(r'\.\s+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  static List<String> _parseEquipment(Map<String, dynamic> json) {
    if (json['analyzedInstructions'] is List && (json['analyzedInstructions'] as List).isNotEmpty) {
      final steps = json['analyzedInstructions'][0]['steps'] as List<dynamic>? ?? [];
      final allEquipment = <String>{};
      for (var s in steps) {
        if (s is Map && s['equipment'] is List) {
          for (var e in s['equipment']) {
            if (e is Map && e['name'] != null) allEquipment.add(e['name'].toString());
          }
        }
      }
      return allEquipment.toList();
    }
    return [];
  }
}

class Ingredient {
  final String name;
  final String quantity;
  Ingredient({required this.name, required this.quantity});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name']?.toString() ?? '',
      quantity: json['original']?.toString() ?? '',
    );
  }
}

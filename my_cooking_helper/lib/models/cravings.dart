class ShoppingItemModel {
  final String name;
  final double need;
  final String unit;
  final double have;
  final String tag; //buy or missing

  ShoppingItemModel({
    required this.name,
    required this.need,
    required this.unit,
    required this.have,
    required this.tag,
  });

  factory ShoppingItemModel.fromMap(Map<String, dynamic> m) => ShoppingItemModel(
        name: (m['name'] ?? '').toString(),
        need: (m['need'] as num?)?.toDouble() ?? 0.0,
        unit: (m['unit'] ?? 'count').toString(),
        have: (m['have'] as num?)?.toDouble() ?? 0.0,
        tag: (m['tag'] ?? 'buy').toString(),
      );
}

class CravingRecipeModel {
  final String id;
  final String title;
  final int? readyInMinutes;

  final List<String> cuisines;
  final List<String> diets;
  final bool? vegetarian;
  final bool? vegan;
  final bool? glutenFree;
  final bool? dairyFree;
  final Map<String, dynamic>? nutrition; 
  final String? summary;

  final List<String> reasons;
  final List<dynamic> requiredIngredients;
  final List<dynamic> optionalIngredients;
  final List<dynamic> instructions;

  final List<ShoppingItemModel> shopping;
  final bool hasImage;

  String? imageDataUrl;

  CravingRecipeModel({
    required this.id,
    required this.title,
    required this.readyInMinutes,
    required this.reasons,
    required this.requiredIngredients,
    required this.optionalIngredients,
    required this.instructions,
    required this.shopping,
    required this.hasImage,
    this.imageDataUrl,

    this.cuisines = const [],
    this.diets = const [],
    this.vegetarian,
    this.vegan,
    this.glutenFree,
    this.dairyFree,
    this.nutrition,
    this.summary,
  });

  factory CravingRecipeModel.fromFirestore(Map<String, dynamic> m) {
    final rawShopping = (m['shopping'] as List?) ?? const [];
    return CravingRecipeModel(
      id: (m['id'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      readyInMinutes: (m['readyInMinutes'] is num)
          ? (m['readyInMinutes'] as num).toInt()
          : null,
      cuisines: ((m['cuisines'] as List?) ?? const []).map((e) => e.toString()).toList(),
      diets: ((m['diets'] as List?) ?? const []).map((e) => e.toString()).toList(),
      vegetarian: m['vegetarian'] as bool?,
      vegan: m['vegan'] as bool?,
      glutenFree: m['glutenFree'] as bool?,
      dairyFree: m['dairyFree'] as bool?,
      nutrition: (m['nutrition'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)),
      summary: (m['summary'] as String?),

      reasons: ((m['reasons'] as List?) ?? const []).map((e) => e.toString()).toList(),
      requiredIngredients: (m['required_ingredients'] as List?) ?? const [],
      optionalIngredients: (m['optional_ingredients'] as List?) ?? const [],
      instructions: (m['instructions'] as List?) ?? const [],
      shopping: rawShopping
          .map((e) => ShoppingItemModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      hasImage: (m['hasImage'] as bool?) ?? false,
    );
  }

  CravingRecipeModel copyWith({
    String? imageDataUrl,
  }) =>
      CravingRecipeModel(
        id: id,
        title: title,
        readyInMinutes: readyInMinutes,
        reasons: reasons,
        requiredIngredients: requiredIngredients,
        optionalIngredients: optionalIngredients,
        instructions: instructions,
        shopping: shopping,
        hasImage: hasImage,
        imageDataUrl: imageDataUrl ?? this.imageDataUrl,
        cuisines: cuisines,
        diets: diets,
        vegetarian: vegetarian,
        vegan: vegan,
        glutenFree: glutenFree,
        dairyFree: dairyFree,
        nutrition: nutrition,
        summary: summary,
      );
}

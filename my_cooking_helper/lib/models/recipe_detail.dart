class RecipeDetail {
  final String? id;
  final String? title;
  final String? image;
  final String? imageType;
  final int? readyInMinutes;
  final int? servings;
  final String? sourceUrl;
  final bool? vegetarian;
  final bool? vegan;
  final bool? glutenFree;
  final bool? dairyFree;
  final bool? veryHealthy;
  final bool? cheap;
  final bool? veryPopular;
  final bool? sustainable;
  final bool? lowFodmap;
  final int? weightWatcherSmartPoints;
  final String? gaps;
  final int? preparationMinutes;
  final int? cookingMinutes;
  final int? aggregateLikes;
  final double? healthScore;
  final String? creditsText;
  final String? license;
  final String? sourceName;
  final double? pricePerServing;
  final List<ExtendedIngredient> extendedIngredients;
  final String? summary;
  final List<String> cuisines;
  final List<String> dishTypes;
  final List<String> diets;
  final List<String> occasions;
  final WinePairing? winePairing;
  final String? instructions;
  final List<AnalyzedInstruction> analyzedInstructions;
  final int? originalId;
  final double? spoonacularScore;
  final String? spoonacularSourceUrl;
  final Nutrition? nutrition;
  final String? aiSummary; 
  final Map<String, dynamic>? geminiSummary;
  final List<RecipeVideo>? videos; 

  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'imageType': imageType,
      'readyInMinutes': readyInMinutes,
      'servings': servings,
      'sourceUrl': sourceUrl,
      'vegetarian': vegetarian,
      'vegan': vegan,
      'glutenFree': glutenFree,
      'dairyFree': dairyFree,
      'veryHealthy': veryHealthy,
      'cheap': cheap,
      'veryPopular': veryPopular,
      'sustainable': sustainable,
      'lowFodmap': lowFodmap,
      'weightWatcherSmartPoints': weightWatcherSmartPoints,
      'gaps': gaps,
      'preparationMinutes': preparationMinutes,
      'cookingMinutes': cookingMinutes,
      'aggregateLikes': aggregateLikes,
      'healthScore': healthScore,
      'creditsText': creditsText,
      'license': license,
      'sourceName': sourceName,
      'pricePerServing': pricePerServing,
      'extendedIngredients': extendedIngredients.map((e) => e.toJson()).toList(),
      'summary': summary,
      'cuisines': cuisines,
      'dishTypes': dishTypes,
      'diets': diets,
      'occasions': occasions,
      'winePairing': winePairing?.toJson(),
      'instructions': instructions,
      'analyzedInstructions': analyzedInstructions.map((e) => e.toJson()).toList(),
      'originalId': originalId,
      'spoonacularScore': spoonacularScore,
      'spoonacularSourceUrl': spoonacularSourceUrl,
      'nutrition': nutrition?.toJson(),
      'aiSummary': aiSummary, 
      'geminiSummary': geminiSummary,
      'videos': videos?.map((v) => v.toJson()).toList(), 
      ...extra,
    };
  }

  RecipeDetail copyWith({
    String? id,
    String? title,
    String? image,
    String? imageType,
    int? readyInMinutes,
    int? servings,
    String? sourceUrl,
    bool? vegetarian,
    bool? vegan,
    bool? glutenFree,
    bool? dairyFree,
    bool? veryHealthy,
    bool? cheap,
    bool? veryPopular,
    bool? sustainable,
    bool? lowFodmap,
    int? weightWatcherSmartPoints,
    String? gaps,
    int? preparationMinutes,
    int? cookingMinutes,
    int? aggregateLikes,
    double? healthScore,
    String? creditsText,
    String? license,
    String? sourceName,
    double? pricePerServing,
    List<ExtendedIngredient>? extendedIngredients,
    String? summary,
    List<String>? cuisines,
    List<String>? dishTypes,
    List<String>? diets,
    List<String>? occasions,
    WinePairing? winePairing,
    String? instructions,
    List<AnalyzedInstruction>? analyzedInstructions,
    int? originalId,
    double? spoonacularScore,
    String? spoonacularSourceUrl,
    Nutrition? nutrition,
    String? aiSummary, 
    Map<String, dynamic>? geminiSummary,
    List<RecipeVideo>? videos,  
    Map<String, dynamic>? extra,
  }) {
    return RecipeDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      imageType: imageType ?? this.imageType,
      readyInMinutes: readyInMinutes ?? this.readyInMinutes,
      servings: servings ?? this.servings,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      vegetarian: vegetarian ?? this.vegetarian,
      vegan: vegan ?? this.vegan,
      glutenFree: glutenFree ?? this.glutenFree,
      dairyFree: dairyFree ?? this.dairyFree,
      veryHealthy: veryHealthy ?? this.veryHealthy,
      cheap: cheap ?? this.cheap,
      veryPopular: veryPopular ?? this.veryPopular,
      sustainable: sustainable ?? this.sustainable,
      lowFodmap: lowFodmap ?? this.lowFodmap,
      weightWatcherSmartPoints: weightWatcherSmartPoints ?? this.weightWatcherSmartPoints,
      gaps: gaps ?? this.gaps,
      preparationMinutes: preparationMinutes ?? this.preparationMinutes,
      cookingMinutes: cookingMinutes ?? this.cookingMinutes,
      aggregateLikes: aggregateLikes ?? this.aggregateLikes,
      healthScore: healthScore ?? this.healthScore,
      creditsText: creditsText ?? this.creditsText,
      license: license ?? this.license,
      sourceName: sourceName ?? this.sourceName,
      pricePerServing: pricePerServing ?? this.pricePerServing,
      extendedIngredients: extendedIngredients ?? this.extendedIngredients,
      summary: summary ?? this.summary,
      cuisines: cuisines ?? this.cuisines,
      dishTypes: dishTypes ?? this.dishTypes,
      diets: diets ?? this.diets,
      occasions: occasions ?? this.occasions,
      winePairing: winePairing ?? this.winePairing,
      instructions: instructions ?? this.instructions,
      analyzedInstructions: analyzedInstructions ?? this.analyzedInstructions,
      originalId: originalId ?? this.originalId,
      spoonacularScore: spoonacularScore ?? this.spoonacularScore,
      spoonacularSourceUrl: spoonacularSourceUrl ?? this.spoonacularSourceUrl,
      nutrition: nutrition ?? this.nutrition,
      aiSummary: aiSummary ?? this.aiSummary, 
      geminiSummary: geminiSummary ?? this.geminiSummary, 
      videos: videos ?? this.videos, 
      extra: extra ?? this.extra,
    );
  }

  RecipeDetail({
    this.id,
    this.title,
    this.image,
    this.imageType,
    this.readyInMinutes,
    this.servings,
    this.sourceUrl,
    this.vegetarian,
    this.vegan,
    this.glutenFree,
    this.dairyFree,
    this.veryHealthy,
    this.cheap,
    this.veryPopular,
    this.sustainable,
    this.lowFodmap,
    this.weightWatcherSmartPoints,
    this.gaps,
    this.preparationMinutes,
    this.cookingMinutes,
    this.aggregateLikes,
    this.healthScore,
    this.creditsText,
    this.license,
    this.sourceName,
    this.pricePerServing,
    this.extendedIngredients = const [],
    this.summary,
    this.cuisines = const [],
    this.dishTypes = const [],
    this.diets = const [],
    this.occasions = const [],
    this.winePairing,
    this.instructions,
    this.analyzedInstructions = const [],
    this.originalId,
    this.spoonacularScore,
    this.spoonacularSourceUrl,
    this.nutrition,
    this.extra = const {},
    this.aiSummary,
    this.videos,
    this.geminiSummary,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    final knownKeys = {
      'id',
      'title',
      'image',
      'imageType',
      'readyInMinutes',
      'servings',
      'sourceUrl',
      'vegetarian',
      'vegan',
      'nutrition',
      'glutenFree',
      'dairyFree',
      'veryHealthy',
      'cheap',
      'veryPopular',
      'sustainable',
      'lowFodmap',
      'weightWatcherSmartPoints',
      'gaps',
      'preparationMinutes',
      'cookingMinutes',
      'aggregateLikes',
      'healthScore',
      'creditsText',
      'license',
      'sourceName',
      'pricePerServing',
      'extendedIngredients',
      'summary',
      'cuisines',
      'dishTypes',
      'diets',
      'occasions',
      'winePairing',
      'instructions',
      'analyzedInstructions',
      'originalId',
      'spoonacularScore',
      'spoonacularSourceUrl',
      'aiSummary',
      'geminiSummary',
      'videos',
    };
    
    final Map<String, dynamic> extra = {};
    for (var key in json.keys) {
      if (!knownKeys.contains(key)) {
        extra[key] = json[key];
      }
    }

    return RecipeDetail(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      image: json['image']?.toString(),
      imageType: json['imageType']?.toString(),
      readyInMinutes: _parseInt(json['readyInMinutes']),
      servings: _parseInt(json['servings']),
      sourceUrl: json['sourceUrl']?.toString(),
      vegetarian: json['vegetarian'] as bool?,
      vegan: json['vegan'] as bool?,
      glutenFree: json['glutenFree'] as bool?,
      dairyFree: json['dairyFree'] as bool?,
      veryHealthy: json['veryHealthy'] as bool?,
      cheap: json['cheap'] as bool?,
      veryPopular: json['veryPopular'] as bool?,
      sustainable: json['sustainable'] as bool?,
      lowFodmap: json['lowFodmap'] as bool?,
      weightWatcherSmartPoints: _parseInt(json['weightWatcherSmartPoints']),
      gaps: json['gaps']?.toString(),
      preparationMinutes: _parseInt(json['preparationMinutes']),
      cookingMinutes: _parseInt(json['cookingMinutes']),
      aggregateLikes: _parseInt(json['aggregateLikes']),
      healthScore: _parseDouble(json['healthScore']),
      creditsText: json['creditsText']?.toString(),
      license: json['license']?.toString(),
      sourceName: json['sourceName']?.toString(),
      pricePerServing: _parseDouble(json['pricePerServing']),
      extendedIngredients: (json['extendedIngredients'] as List<dynamic>? ?? [])
          .map((e) => ExtendedIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary']?.toString(),
      cuisines: (json['cuisines'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      dishTypes: (json['dishTypes'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      diets: (json['diets'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      occasions: (json['occasions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      winePairing: json['winePairing'] != null ? WinePairing.fromJson(json['winePairing']) : null,
      instructions: json['instructions']?.toString(),
      analyzedInstructions: (json['analyzedInstructions'] as List<dynamic>? ?? [])
          .map((e) => AnalyzedInstruction.fromJson(e as Map<String, dynamic>))
          .toList(),
      originalId: _parseInt(json['originalId']),
      spoonacularScore: _parseDouble(json['spoonacularScore']),
      spoonacularSourceUrl: json['spoonacularSourceUrl']?.toString(),
      nutrition: json['nutrition'] != null ? Nutrition.fromJson(json['nutrition']) : null,
      aiSummary: json['aiSummary']?.toString(),
      geminiSummary: json['geminiSummary'] == null
        ? null
        : Map<String, dynamic>.from(json['geminiSummary']),
      videos: json['videos'] == null
        ? null
        : (json['videos'] as List).map((e) => RecipeVideo.fromJson(e)).toList(),
      extra: extra,
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

// Nested Classes
class ExtendedIngredient {
  final int? id;
  final String? aisle;
  final String? image;
  final String? consistency;
  final String? name;
  final String? nameClean;
  final String? original;
  final String? originalName;
  final double? amount;
  final String? unit;
  final List<String> meta;
  final IngredientMeasures? measures;

  ExtendedIngredient({
    this.id,
    this.aisle,
    this.image,
    this.consistency,
    this.name,
    this.nameClean,
    this.original,
    this.originalName,
    this.amount,
    this.unit,
    this.meta = const [],
    this.measures,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'aisle': aisle,
    'image': image,
    'consistency': consistency,
    'name': name,
    'nameClean': nameClean,
    'original': original,
    'originalName': originalName,
    'amount': amount,
    'unit': unit,
    'meta': meta,
    'measures': measures?.toJson(),
  };

  factory ExtendedIngredient.fromJson(Map<String, dynamic> json) {
    return ExtendedIngredient(
      id: _parseInt(json['id']),
      aisle: json['aisle']?.toString(),
      image: json['image']?.toString(),
      consistency: json['consistency']?.toString(),
      name: json['name']?.toString(),
      nameClean: json['nameClean']?.toString(),
      original: json['original']?.toString(),
      originalName: json['originalName']?.toString(),
      amount: _parseDouble(json['amount']),
      unit: json['unit']?.toString(),
      meta: (json['meta'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      measures: json['measures'] != null ? IngredientMeasures.fromJson(json['measures']) : null,
    );
  }
}

class IngredientMeasures {
  final IngredientMeasure? us;
  final IngredientMeasure? metric;

  IngredientMeasures({this.us, this.metric});

  Map<String, dynamic> toJson() => {
    'us': us?.toJson(),
    'metric': metric?.toJson(),
  };

  factory IngredientMeasures.fromJson(Map<String, dynamic> json) {
    return IngredientMeasures(
      us: json['us'] != null ? IngredientMeasure.fromJson(json['us']) : null,
      metric: json['metric'] != null ? IngredientMeasure.fromJson(json['metric']) : null,
    );
  }
}

class IngredientMeasure {
  final double? amount;
  final String? unitShort;
  final String? unitLong;

  IngredientMeasure({this.amount, this.unitShort, this.unitLong});

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'unitShort': unitShort,
    'unitLong': unitLong,
  };

  factory IngredientMeasure.fromJson(Map<String, dynamic> json) {
    return IngredientMeasure(
      amount: _parseDouble(json['amount']),
      unitShort: json['unitShort']?.toString(),
      unitLong: json['unitLong']?.toString(),
    );
  }
}

class Nutrition {
  final List<Nutrient> nutrients;
  final CaloricBreakdown? caloricBreakdown;
  final WeightPerServing? weightPerServing;

  Nutrition({
    this.nutrients = const [],
    this.caloricBreakdown,
    this.weightPerServing,
  });

  Map<String, dynamic> toJson() {
    return {
      'nutrients': nutrients.map((n) => n.toJson()).toList(),
      'caloricBreakdown': caloricBreakdown?.toJson(),
      'weightPerServing': weightPerServing?.toJson(),
    };
  }

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      nutrients: (json['nutrients'] as List<dynamic>? ?? [])
          .map((e) => Nutrient.fromJson(e as Map<String, dynamic>))
          .toList(),
      caloricBreakdown: json['caloricBreakdown'] != null
          ? CaloricBreakdown.fromJson(json['caloricBreakdown'])
          : null,
      weightPerServing: json['weightPerServing'] != null
          ? WeightPerServing.fromJson(json['weightPerServing'])
          : null,
    );
  }
}

class Nutrient {
  final String? name;
  final double? amount;
  final String? unit;
  final double? percentOfDailyNeeds;

  Nutrient({this.name, this.amount, this.unit, this.percentOfDailyNeeds});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'percentOfDailyNeeds': percentOfDailyNeeds,
    };
  }

  factory Nutrient.fromJson(Map<String, dynamic> json) {
    return Nutrient(
      name: json['name']?.toString(),
      amount: _parseDouble(json['amount']),
      unit: json['unit']?.toString(),
      percentOfDailyNeeds: _parseDouble(json['percentOfDailyNeeds']),
    );
  }
}

class CaloricBreakdown {
  final double? percentProtein;
  final double? percentFat;
  final double? percentCarbs;

  CaloricBreakdown({this.percentProtein, this.percentFat, this.percentCarbs});

  Map<String, dynamic> toJson() {
    return {
      'percentProtein': percentProtein,
      'percentFat': percentFat,
      'percentCarbs': percentCarbs,
    };
  }

  factory CaloricBreakdown.fromJson(Map<String, dynamic> json) {
    return CaloricBreakdown(
      percentProtein: _parseDouble(json['percentProtein']),
      percentFat: _parseDouble(json['percentFat']),
      percentCarbs: _parseDouble(json['percentCarbs']),
    );
  }
}

class WeightPerServing {
  final double? amount;
  final String? unit;

  WeightPerServing({this.amount, this.unit});

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'unit': unit,
    };
  }

  factory WeightPerServing.fromJson(Map<String, dynamic> json) {
    return WeightPerServing(
      amount: _parseDouble(json['amount']),
      unit: json['unit']?.toString(),
    );
  }
}

class WinePairing {
  final List<String> pairedWines;
  final String? pairingText;
  final List<Map<String, dynamic>> productMatches;

  WinePairing({
    this.pairedWines = const [],
    this.pairingText,
    this.productMatches = const [],
  });

  Map<String, dynamic> toJson() => {
    'pairedWines': pairedWines,
    'pairingText': pairingText,
    'productMatches': productMatches,
  };

  factory WinePairing.fromJson(Map<String, dynamic> json) {
    return WinePairing(
      pairedWines: (json['pairedWines'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      pairingText: json['pairingText']?.toString(),
      productMatches: (json['productMatches'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}

class AnalyzedInstruction {
  final String? name;
  final List<InstructionStep> steps;

  AnalyzedInstruction({this.name, this.steps = const []});

  Map<String, dynamic> toJson() => {
    'name': name,
    'steps': steps.map((e) => e.toJson()).toList(),
  };

  factory AnalyzedInstruction.fromJson(Map<String, dynamic> json) {
    return AnalyzedInstruction(
      name: json['name']?.toString(),
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map((e) => InstructionStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class InstructionStep {
  final int? number;
  final String? step;
  final List<Map<String, dynamic>> ingredients;
  final List<Map<String, dynamic>> equipment;
  final Map<String, dynamic>? length;

  InstructionStep({
    this.number,
    this.step,
    this.ingredients = const [],
    this.equipment = const [],
    this.length,
  });

  Map<String, dynamic> toJson() => {
    'number': number,
    'step': step,
    'ingredients': ingredients,
    'equipment': equipment,
    'length': length,
  };

  factory InstructionStep.fromJson(Map<String, dynamic> json) {
    return InstructionStep(
      number: _parseInt(json['number']),
      step: json['step']?.toString(),
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      equipment: (json['equipment'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      length: json['length'] as Map<String, dynamic>?,
    );
  }
}

class RecipeVideo {
  final String videoId;
  final String title;
  final String thumbnail;
  final String channelTitle;
  final String publishedAt;
  final String description;

  RecipeVideo({
    required this.videoId,
    required this.title,
    required this.thumbnail,
    required this.channelTitle,
    required this.publishedAt,
    required this.description,
  });

  factory RecipeVideo.fromJson(Map<String, dynamic> json) {
    return RecipeVideo(
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      channelTitle: json['channelTitle'] ?? '',
      publishedAt: json['publishedAt'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'title': title,
    'thumbnail': thumbnail,
    'channelTitle': channelTitle,
    'publishedAt': publishedAt,
    'description': description,
  };
}

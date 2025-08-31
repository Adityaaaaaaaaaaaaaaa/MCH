import '/models/recipe_detail.dart'; // fix import path

class MealPlanDay {
  final int dayIndex;            // 1..7
  final String dayName;          // Monday..Sunday
  final RecipeDetail? breakfast;
  final RecipeDetail? lunch;
  final RecipeDetail? dinner;

  MealPlanDay({
    required this.dayIndex,
    required this.dayName,
    this.breakfast,
    this.lunch,
    this.dinner,
  });

  factory MealPlanDay.fromFirestore(Map<String, dynamic> json) {
    RecipeDetail? _parseRecipe(Map<String, dynamic>? r) =>
      (r == null) ? null : RecipeDetail.fromJson(r);

    return MealPlanDay(
      dayIndex: (json['dayIndex'] as num?)?.toInt() ?? 0,
      dayName: (json['dayName'] as String?) ?? '',
      breakfast: _parseRecipe(json['breakfast'] as Map<String, dynamic>?),
      lunch: _parseRecipe(json['lunch'] as Map<String, dynamic>?),
      dinner: _parseRecipe(json['dinner'] as Map<String, dynamic>?),
    );
  }
}

class MealPlanWeek {
  final String planId;           // ISO-Monday (YYYY-MM-DD)
  final List<MealPlanDay> days;  // length 7

  MealPlanWeek({required this.planId, required this.days});
}

  // ---- Light view model just for the planner row ----
class MealLite {
  final String id;
  final String title;
  final String? image;
  MealLite({required this.id, required this.title, this.image});

  static MealLite? fromDayField(Map<String, dynamic>? field) {
    if (field == null) return null;
    final id = field['id']?.toString();
    final title = field['title']?.toString() ?? '';
    final image = field['image']?.toString();
    if (id == null || title.isEmpty) return null;
    return MealLite(id: id, title: title, image: image);
  }
}

class MealPlanDayLite {
  final int dayIndex;         // 1..7
  final String dayName;       // Monday..Sunday
  final MealLite? breakfast;
  final MealLite? lunch;
  final MealLite? dinner;
  MealPlanDayLite({
    required this.dayIndex,
    required this.dayName,
    this.breakfast,
    this.lunch,
    this.dinner,
  });

  factory MealPlanDayLite.fromFirestore(Map<String, dynamic> data) {
    return MealPlanDayLite(
      dayIndex: (data['dayIndex'] ?? 0) as int,
      dayName: (data['dayName'] ?? '') as String,
      breakfast: MealLite.fromDayField(data['breakfast'] as Map<String, dynamic>?),
      lunch:     MealLite.fromDayField(data['lunch']     as Map<String, dynamic>?),
      dinner:    MealLite.fromDayField(data['dinner']    as Map<String, dynamic>?),
    );
  }
}

class MealPlanWeekLite {
  final String planId;           // YYYY-MM-DD (week Monday)
  final List<MealPlanDayLite> days; // up to 7
  MealPlanWeekLite({required this.planId, required this.days});
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/config/backend_config.dart';

class MealPlannerService {
  final FirebaseFirestore firestore;

  MealPlannerService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch main user preferences (diet & allergies)
  Future<Map<String, dynamic>> fetchUserMealPrefs(String userId) async {
    final doc = await firestore.collection('users').doc(userId).get();
    if (!doc.exists) {
      throw Exception('User document not found');
    }
    final prefs = doc.data()?['preferences'] ?? {};
    return {
      'allergies': (prefs['allergies'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      'diets': (prefs['diets'] as List<dynamic>?)?.cast<String>() ?? <String>[],
    };
  }

  // Blue debug printer
  void blueDebugPrint(Object msg) {
    dynamic makeEncodable(dynamic v) {
      if (v is Set) return v.map(makeEncodable).toList();
      if (v is List) return v.map(makeEncodable).toList();
      if (v is Map) return v.map((k, w) => MapEntry(k, makeEncodable(w)));
      return v;
    }
    final encodable = makeEncodable(msg);
    final str = (encodable is String)
        ? encodable
        : const JsonEncoder.withIndent('  ').convert(encodable);
    for (final line in str.split('\n')) {
      print('\x1B[34m[DEBUG] $line\x1B[0m');
    }
  }

  /// Generate weekly meal plan (no default calories; omit params if "None"/empty)
  Future<void> generateWeeklyPlan({
    required String userId,
  }) async {
    final prefs = await fetchUserMealPrefs(userId);

    // Normalize diet: first non-"None" non-empty
    final diets = (prefs['diets'] as List<String>?) ?? <String>[];
    final diet = diets.firstWhere(
      (d) => d.trim().isNotEmpty && d.trim().toLowerCase() != 'none',
      orElse: () => '',
    );

    // Normalize allergies: all non-"None" non-empty
    final allergies = (prefs['allergies'] as List<String>?) ?? <String>[];
    final filteredAllergies = allergies
        .where((a) => a.trim().isNotEmpty && a.trim().toLowerCase() != 'none')
        .toList();

    // Build payload, only include meaningful keys
    final Map<String, dynamic> payload = {
      "timeFrame": "week",
      if (diet.isNotEmpty) "diet": diet,
      if (filteredAllergies.isNotEmpty) "exclude": filteredAllergies.join(","),
      // targetCalories intentionally omitted (let Spoonacular default)
    };

    final url = Uri.parse(spoonacularMealplanner);
    blueDebugPrint('Generating Weekly Meal Plan (POST $url)');
    blueDebugPrint('Payload -> $payload');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    blueDebugPrint('Backend status: ${response.statusCode}');
    final preview = response.body.length > 400
        ? '${response.body.substring(0, 400)}...[trimmed]'
        : response.body;
    blueDebugPrint('Backend response preview: $preview');

    if (response.statusCode != 200) {
      throw Exception('Backend error: ${response.body}');
    }

    blueDebugPrint("Meal plan request sent successfully!");
    // We will parse/store the response later when we design the models/UI.
  }
}

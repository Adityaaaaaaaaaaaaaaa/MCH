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
    if (!doc.exists) throw Exception('User document not found');
    final prefs = doc.data()?['preferences'] ?? {};
    return {
      'allergies': (prefs['allergies'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      'diets': (prefs['diets'] as List<dynamic>?)?.cast<String>() ?? <String>[],
    };
  }

  // Blue debug printer
  void blueDebugPrint(Object msg) {
    dynamic enc(dynamic v) {
      if (v is Set) return v.map(enc).toList();
      if (v is List) return v.map(enc).toList();
      if (v is Map) return v.map((k, w) => MapEntry(k, enc(w)));
      return v;
    }
    final e = enc(msg);
    final s = (e is String) ? e : const JsonEncoder.withIndent('  ').convert(e);
    for (final line in s.split('\n')) {
      print('\x1B[34m[DEBUG] $line\x1B[0m');
    }
  }

  /// Calls backend /mealPlanner/weekPlanner
  /// Sends userId (required by backend) + diet/exclude derived from Firestore.
  Future<Map<String, dynamic>> generateWeeklyPlan({
    required String userId,
    String? planId, // optional override; usually omit and let backend compute ISO Monday
  }) async {
    final prefs = await fetchUserMealPrefs(userId);

    final diets = (prefs['diets'] as List<String>?) ?? <String>[];
    final diet = diets.firstWhere(
      (d) => d.trim().isNotEmpty && d.trim().toLowerCase() != 'none',
      orElse: () => '',
    );

    final allergies = (prefs['allergies'] as List<String>?) ?? <String>[];
    final filteredAllergies = allergies
        .where((a) => a.trim().isNotEmpty && a.trim().toLowerCase() != 'none')
        .toList();

    final payload = <String, dynamic>{
      "userId": userId,              // <<< REQUIRED
      "timeFrame": "week",
      if (diet.isNotEmpty) "diet": diet,
      if (filteredAllergies.isNotEmpty) "exclude": filteredAllergies.join(","),
      if (planId != null && planId.isNotEmpty) "planId": planId,
      // targetCalories intentionally omitted (use Spoonacular default)
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

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    blueDebugPrint('Parsed backend JSON keys: ${data.keys.toList()}');
    return data; // includes planId, path, saved flag, and the full structured week
  }
}

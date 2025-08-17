import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '/config/backend_config.dart';
import '/models/meal_plan.dart';
import '/models/recipe_detail.dart';

class MealPlannerService {
  final FirebaseFirestore firestore;

  MealPlannerService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  // ------------------------- Utilities -------------------------

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

  /// Compute the ISO-Monday planId the backend uses (YYYY-MM-DD).
  String currentWeekPlanId([DateTime? now]) {
    final dt = now?.toUtc() ?? DateTime.now().toUtc();
    final monday = dt.subtract(Duration(days: dt.weekday - 1));
    final dateOnly = DateTime.utc(monday.year, monday.month, monday.day);
    return DateFormat('yyyy-MM-dd').format(dateOnly);
  }

  /// Return "Mon d – Sun d" for a given planId (YYYY-MM-DD, Monday).
  String weekRangeLabel(String planId) {
    final p = planId.split('-').map(int.parse).toList();
    final mon = DateTime.utc(p[0], p[1], p[2]);
    final sun = mon.add(const Duration(days: 6));
    final fmt = DateFormat('MMM d');
    return '${fmt.format(mon)} – ${fmt.format(sun)}';
  }

  // -------------------- User prefs (diet/allergies) --------------------

  Future<Map<String, dynamic>> fetchUserMealPrefs(String userId) async {
    final doc = await firestore.collection('users').doc(userId).get();
    if (!doc.exists) throw Exception('User document not found');
    final prefs = doc.data()?['preferences'] ?? {};
    return {
      'allergies': (prefs['allergies'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      'diets': (prefs['diets'] as List<dynamic>?)?.cast<String>() ?? <String>[],
    };
  }

  // ----------------------- Backend calls -----------------------

  /// POST /mealPlanner/weekPlanner (creates & saves plan in Firestore)
  Future<Map<String, dynamic>> generateWeeklyPlan({
    required String userId,
    String? planId,
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
      "userId": userId,
      "timeFrame": "week",
      if (diet.isNotEmpty) "diet": diet,
      if (filteredAllergies.isNotEmpty) "exclude": filteredAllergies.join(","),
      if (planId != null && planId.isNotEmpty) "planId": planId,
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
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ----------------------- Firestore streams -----------------------

  /// Stream the 7 day docs for a given user + planId (defaults to current week).
  Stream<MealPlanWeek> streamWeek({
    required String userId,
    String? planId,
  }) {
    final pid = (planId?.trim().isNotEmpty ?? false) ? planId!.trim() : currentWeekPlanId();
    blueDebugPrint('[MealPlannerService] streamWeek -> uid=$userId, planId=$pid');

    final col = firestore
        .collection('users').doc(userId)
        .collection('mealPlans').doc(pid)
        .collection('days');

    return col.orderBy('dayIndex').snapshots().map((snap) {
      final days = snap.docs.map((d) {
        final data = d.data();
        return MealPlanDay.fromFirestore(data);
      }).toList();

      if (days.length != 7) {
        blueDebugPrint('[MealPlannerService] days fetched: ${days.length} (expected 7)');
      }
      return MealPlanWeek(planId: pid, days: days);
    });
  }

  /// Stream days + compute % complete based on number of day docs (0..7).
  Stream<(MealPlanWeekLite, double)> streamWeekWithProgress({
    required String userId,
    String? planId,
  }) {
    final pid = (planId != null && planId.trim().isNotEmpty)
        ? planId.trim()
        : currentWeekPlanId();

    final col = firestore
        .collection('users').doc(userId)
        .collection('mealPlans').doc(pid)
        .collection('days');

    return col.orderBy('dayIndex').snapshots().map((snap) {
      final days = snap.docs
          .map((d) => MealPlanDayLite.fromFirestore(d.data()))
          .toList();

      final progress = (days.length.clamp(0, 7) / 7.0);
      return (MealPlanWeekLite(planId: pid, days: days), progress);
    });
  }

  // -------------------------- Mutations --------------------------

  /// Delete the whole plan (plan doc + subcollection/7 day docs).
  Future<void> deletePlan({required String userId, required String planId}) async {
    final planRef = firestore
        .collection('users').doc(userId)
        .collection('mealPlans').doc(planId);

    final days = await planRef.collection('days').get();
    for (final d in days.docs) {
      await d.reference.delete();
    }
    await planRef.delete();
  }

  /// Regenerate this week (same planId). The backend overwrites day docs.
  Future<Map<String, dynamic>> regenerateWeek({
    required String userId,
    required String planId,
  }) {
    return generateWeeklyPlan(userId: userId, planId: planId);
  }

  /// Temporary stub for swapping a day – replace with backend call later.
  Future<void> swapDay({
    required String userId,
    required String planId, // you can still pass currentWeekPlanId() if needed
    required int dayIndex,  // 1..7
    String? diet,
    String? excludeCsv,
    int? targetCalories,
  }) async {
    final url = Uri.parse(spoonacularChangeDay); // <- adjust base
    final payload = <String, dynamic>{
      'userId': userId,
      'planId': planId,
      'dayIndex': dayIndex,
      if (diet != null && diet.isNotEmpty) 'diet': diet,
      if (excludeCsv != null && excludeCsv.isNotEmpty) 'exclude': excludeCsv,
      if (targetCalories != null) 'targetCalories': targetCalories,
    };
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('swapDay failed: ${res.body}');
    }
    // Firestore stream will refresh automatically.
  }

  // ---------------------- Fetch single recipe ----------------------

  /// Fetch a **single** meal’s full details from Firestore day doc.
  /// [mealKey] must be 'breakfast' | 'lunch' | 'dinner'
  Future<RecipeDetail?> fetchRecipeForDayMeal({
    required String userId,
    required String planId,
    required int dayIndex, // 1..7
    required String mealKey,
  }) async {
    assert(dayIndex >= 1 && dayIndex <= 7);
    if (!['breakfast', 'lunch', 'dinner'].contains(mealKey)) {
      throw ArgumentError('mealKey must be breakfast|lunch|dinner');
    }

    const dayNames = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
    final docId = dayNames[dayIndex - 1];

    final daySnap = await firestore
        .collection('users').doc(userId)
        .collection('mealPlans').doc(planId)
        .collection('days').doc(docId)
        .get();

    if (!daySnap.exists) return null;
    final data = daySnap.data()!;
    final mealJson = data[mealKey];
    if (mealJson == null) return null;

    try {
      final map = Map<String, dynamic>.from(mealJson as Map);
      return RecipeDetail.fromJson(map);
    } catch (e) {
      blueDebugPrint('Failed to parse RecipeDetail for $mealKey on $docId: $e');
      return null;
    }
  }

  /// Change (regenerate) a single day in the current (or given) plan.
  Future<void> changeDay({
    required String userId,
    required int dayIndex,       // 1..7
    String? planId,              // usually omit; backend computes current week
    String? diet,
    String? excludeCsv,
    int? targetCalories,
  }) async {
    final url = Uri.parse(spoonacularChangeDay);
    final payload = <String, dynamic>{
      'userId': userId,
      'dayIndex': dayIndex,
      if (planId != null && planId.isNotEmpty) 'planId': planId,
      if (diet != null && diet.isNotEmpty) 'diet': diet,
      if (excludeCsv != null && excludeCsv.isNotEmpty) 'exclude': excludeCsv,
      if (targetCalories != null) 'targetCalories': targetCalories,
    };

    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (resp.statusCode != 200) {
      throw Exception('changeDay failed: ${resp.statusCode} ${resp.body}');
    }
  }

  // in meal_planner_service.dart
  Future<void> pingBackend({required String userId}) async {
    final url = Uri.parse(spoonacularPing); // add this in backend_config.dart
    final body = jsonEncode(<String, dynamic>{
      "userId": userId,
      // You may also include diet/exclude/targetCalories if you want heartbeat to respect prefs:
      // "diet": "...", "exclude": "...", "targetCalories": 2000,
    });
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (resp.statusCode != 200) {
      blueDebugPrint('Heartbeat failed: ${resp.statusCode} ${resp.body}');
      // Not throwing: we want it to be silent.
    } else {
      blueDebugPrint('Heartbeat ok: ${resp.body}');
    }
  }
}

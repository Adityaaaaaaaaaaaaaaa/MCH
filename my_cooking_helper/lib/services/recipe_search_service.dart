import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/recipe_detail.dart';
import '/config/backend_config.dart';
import '/models/recipe.dart';

class RecipeSearchService {
  final FirebaseFirestore firestore;

  RecipeSearchService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch inventory ingredient names for the user
  Future<List<String>> fetchUserIngredients(String userId) async {
    final snap = await firestore
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .get();
    return snap.docs.map((doc) => doc.id).toList();
  }

  /// Fetch main user preferences
  Future<Map<String, dynamic>> fetchUserPreferences(String userId) async {
    final doc = await firestore.collection('users').doc(userId).get();
    if (!doc.exists) {
      throw Exception('User document not found');
    }
    final data = doc.data()!;
    final prefs = data['preferences'] ?? {};
    return {
      'allergies': (prefs['allergies'] as List<dynamic>?)?.cast<String>() ?? [],
      'diets': (prefs['diets'] as List<dynamic>?)?.cast<String>() ?? [],
      'cuisines': (prefs['cuisines'] as List<dynamic>?)?.cast<String>() ?? [],
      'spiceLevel': prefs['spiceLevel'] ?? '',
    };
  }

  //remove apres tresting //////////////////////////////////////////////////////////////
  void blueDebugPrint(Object msg) {
    dynamic makeEncodable(dynamic value) {
      if (value is Set) {
        return value.map(makeEncodable).toList();
      } else if (value is List) {
        return value.map(makeEncodable).toList();
      } else if (value is Map) {
        return value.map((k, v) => MapEntry(k, makeEncodable(v)));
      } else {
        return value;
      }
    }

    final encodable = makeEncodable(msg);
    final str = (encodable is String)
        ? encodable
        : const JsonEncoder.withIndent('  ').convert(encodable);

    for (final line in str.split('\n')) {
      print('\x1B[34m[DEBUG] $line\x1B[0m');
    }
  }
  /////////////////////////////////////////////////////////////////////////////////////////////

  /// Main search function: fetches all data, prints debug, sends to backend
  Future<RecipeSearchResults> searchRecipesWithUserPrefs({
    required String userId,
    required int maxTime,
    List<String>? overrideIngredients,
  }) async {
    // Fetch user data
    final prefs = await fetchUserPreferences(userId);
    final ingredients = overrideIngredients ?? await fetchUserIngredients(userId);

    blueDebugPrint('Sending Search Request:');
    blueDebugPrint('Allergies: ${prefs['allergies']}');
    blueDebugPrint('Diets: ${prefs['diets']}');
    blueDebugPrint('Cuisines: ${prefs['cuisines']}');
    blueDebugPrint('SpiceLevel: ${prefs['spiceLevel']}');
    blueDebugPrint('MaxTime: $maxTime');

    // Prepare payload
    final url = Uri.parse(spoonacularRecipeSearch); 
    final payload = {
      'ingredients': ingredients,
      'maxTime': maxTime,
      'allergies': prefs['allergies'],
      'diets': prefs['diets'],
      'cuisines': prefs['cuisines'],
      'spiceLevel': prefs['spiceLevel'],
    };

    // Send to backend
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Backend error: ${response.body}');
    }
    final data = jsonDecode(response.body);
    if (data['recipes'] == null || data['recipes'] is! List) {
       throw Exception('Invalid response from backend');
    }
    // return (data['recipes'] as List)
    //     .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
    //     .toList();

    // Full detail list
    final List<RecipeDetail> recipeDetails = (data['recipes'] as List)
        .map((e) => RecipeDetail.fromJson(e as Map<String, dynamic>))
        .toList();

    // Summary list
    final List<Recipe> recipeResults = (data['recipes'] as List)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();

    // Return both lists
    return RecipeSearchResults(summaries: recipeResults, details: recipeDetails);
  }

  Future<Map<String, dynamic>> fetchRecipeVideosAndSummary({
    required String title,
    required String summary,
  }) async {
    // Replace this with your actual backend endpoint for videos!
    final url = Uri.parse(spoonacularRecipeVideos);
    final payload = {
      "title": title,
      "summary": summary,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

class RecipeSearchResults {
  final List<Recipe> summaries;
  final List<RecipeDetail> details;

  RecipeSearchResults({required this.summaries, required this.details});
}

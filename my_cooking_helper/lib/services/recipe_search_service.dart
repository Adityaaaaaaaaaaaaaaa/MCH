import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipeSearchService {
  final FirebaseFirestore firestore;

  RecipeSearchService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch ingredient names (document IDs) from user's Firestore inventory
  Future<List<String>> fetchUserIngredients(String userId) async {
    final snap = await firestore
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .get();
    return snap.docs.map((doc) => doc.id).toList();
  }

  /// Search for recipes using your backend, which wraps Suggestic
  Future<List<Recipe>> searchRecipes({
    required List<String> ingredients,
    required int maxTime,
  }) async {
    // Example backend URL, replace with your actual Render/FastAPI endpoint
    final url = Uri.parse('https://your-backend-url/recipes/search');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ingredients': ingredients,
        'maxTime': maxTime,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Backend error: ${response.body}');
    }
    final data = jsonDecode(response.body);
    if (data['recipes'] == null || data['recipes'] is! List) {
      throw Exception('Invalid response from backend');
    }
    return (data['recipes'] as List)
        .map((e) => Recipe.fromJson(e))
        .toList();
  }
}

/// Example Recipe model. Adjust fields as per your backend’s output.
class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final int totalTime;
  final List<String> ingredients; // Or List<Ingredient> if you prefer
  final List<String> instructions;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.totalTime,
    required this.ingredients,
    required this.instructions,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        totalTime: json['totalTime'] ?? 0,
        ingredients: (json['ingredients'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        instructions: (json['instructions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

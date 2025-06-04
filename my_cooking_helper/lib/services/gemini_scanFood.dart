import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

const String GEMINI_API_KEY = ""; //  <--  IMPORTANT:  Set your API Key here!

final geminiProvider = Provider((ref) => GeminiService());

class GeminiService {
  // Accepts a File (image), returns a Gemini response (parsed)
  Future<String> analyzeFoodImage(File imageFile) async {
    if (GEMINI_API_KEY.isEmpty) {
      return "Error: Gemini API key is not set. Please set GEMINI_API_KEY in lib/services/gemini_service.dart";
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Gemini Vision API endpoint
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$GEMINI_API_KEY');

    // Prompt: You can tune for food recognition as needed
    final request = {
      "contents": [
        {
          "parts": [
            {
              "inlineData": {
                "mimeType": "image/jpeg",
                "data": base64Image,
              }
            },
            {
              "text":
                  "Identify and count the food items in this image. Respond with a comma-separated list of the items andd total count and Detect the all of the prominent food items in the image. The box_2d should be [ymin, xmin, ymax, xmax] normalized to 0-1000."
            }
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request),
      );

      print('\x1B[34m[DEBUG] Gemini API status: ${response.statusCode}\x1B[0m');
      print('\x1B[34m[DEBUG] Gemini API response: ${response.body}\x1B[0m');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Check if candidates is present and is a list
        if (data.containsKey('candidates') && data['candidates'] is List) {
          final candidates = data['candidates'] as List<dynamic>;

          // Check if the list is not empty
          if (candidates.isNotEmpty) {
            // Check if the first candidate has the expected structure
            if (candidates.first.containsKey('content') &&
                candidates.first['content'] is Map &&
                (candidates.first['content'] as Map).containsKey('parts') &&
                (candidates.first['content']['parts'] is List) &&
                (candidates.first['content']['parts'] as List).isNotEmpty &&
                (candidates.first['content']['parts'][0] is Map) &&
                (candidates.first['content']['parts'][0] as Map).containsKey('text')) {
              final content =
                  candidates.first['content']['parts'][0]['text'] as String;
              return content;
            } else {
              return "Error: Unexpected Gemini API response structure.";
            }
          } else {
            return "No items detected.";
          }
        } else {
          return "Error: Unexpected Gemini API response structure (candidates missing or not a list).";
        }
      } else {
        return "Error: Gemini returned status ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      print('\x1B[34m[DEBUG] Gemini API error: $e\x1B[0m');
      return "Error: Could not reach Gemini API: $e";
    }
  }
}
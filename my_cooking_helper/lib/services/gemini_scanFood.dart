import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ignore: constant_identifier_names
const String BACKEND_API_URL = "https://mch-rtlu.onrender.com/food/scanFood"; // <-- Render backend URL
// ignore: constant_identifier_names
//const String BACKEND_API_URL = "http://192.168.75.52:8000/food/scanFood"; // <-- PC IP, update 


final geminiProvider = Provider((ref) => GeminiService());


class GeminiService {
  // Returns a list of maps: [{"item": ..., "count": ...}, ...]
  Future<List<Map<String, dynamic>>> analyzeFoodImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(BACKEND_API_URL));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('\x1B[34m[DEBUG] Backend API status: ${response.statusCode}\x1B[0m');
      print('\x1B[34m[DEBUG] Backend API response: $responseBody\x1B[0m');

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(responseBody);
        // Defensive: Check if structure is as expected
        if (jsonResp is Map && jsonResp.containsKey('detected_items')) {
          return List<Map<String, dynamic>>.from(jsonResp['detected_items']);
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      print('\x1B[31m[DEBUG] Backend API error: $e\x1B[0m');
      return [];
    }
  }
}

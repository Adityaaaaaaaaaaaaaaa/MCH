// ignore_for_file: file_names

import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'backend_config.dart';

// ignore: constant_identifier_names
const String BACKEND_API_URL = "$backendApiUrl/food/scanFood";

final geminiProvider = Provider((ref) => GeminiService());

class GeminiService {
  /// Sends a food image to the backend and returns
  /// a list of maps: [{"itemName": String, "count": double?, "category": String}, ...]
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

        if (jsonResp is Map && jsonResp.containsKey('detected_items')) {
          final List<dynamic> rawItems = jsonResp['detected_items'];

          // Each item should now have itemName, count, and category
          return rawItems.map<Map<String, dynamic>>((item) {
            // Defensive: handle missing or old fields gracefully
            String name = item['itemName'] ?? item['item'] ?? '';
            double? count;
            if (item['count'] != null) {
              if (item['count'] is int) {
                count = (item['count'] as int).toDouble();
              } else if (item['count'] is double) {
                count = item['count'];
              } else if (item['count'] is String) {
                count = double.tryParse(item['count']);
              }
            }
            String category = (item['category'] ?? 'uncategorized').toString();
            return {'itemName': name, 'count': count, 'category': category};
          }).toList();
        } else {
          print('\x1B[33m[DEBUG] "detected_items" missing in backend response\x1B[0m');
          return [];
        }
      } else {
        print('\x1B[31m[DEBUG] Backend API error, non-200 response\x1B[0m');
        return [];
      }
    } catch (e) {
      print('\x1B[31m[DEBUG] Backend API exception: $e\x1B[0m');
      return [];
    }
  }
}

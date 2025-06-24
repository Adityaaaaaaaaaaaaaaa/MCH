// ignore_for_file: file_names

import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'backend_config.dart';

// ignore: constant_identifier_names
const String BACKEND_API_URL = "$backendApiUrl/food/scanFood";

final geminiProvider = Provider((ref) => GeminiService());

/// Wrapper class for food scan result and error info
class GeminiFoodScanResult {
  final List<Map<String, dynamic>> items;
  final String? error; // Contains error message if any
  final int? errorCode;

  GeminiFoodScanResult({required this.items, this.error, this.errorCode});
}

class GeminiService {
  /// Capitalize only the first letter (for itemName display)
  String capitalize(String input) {
    if (input.isEmpty) return input;
    return '${input[0].toUpperCase()}${input.substring(1).toLowerCase()}';
  }

  /// Sends a food image to the backend and returns
  /// GeminiFoodScanResult: items OR error and errorCode if any
  Future<GeminiFoodScanResult> analyzeFoodImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(BACKEND_API_URL));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('\x1B[34m[DEBUG] Backend API status: ${response.statusCode}\x1B[0m');
      print('\x1B[34m[DEBUG] Backend API response: $responseBody\x1B[0m');

      final jsonResp = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        // Success: extract detected_items if present
        if (jsonResp is Map && jsonResp.containsKey('detected_items')) {
          final List<dynamic> gemItems = jsonResp['detected_items'];

          // Defensive: always return a list, even if empty
          final items = gemItems.map<Map<String, dynamic>>((item) {
            String name = item['itemName'] ?? item['item'] ?? '';
            name = capitalize(name);

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

          return GeminiFoodScanResult(items: items);
        } else {
          // Malformed response: no detected_items key
          return GeminiFoodScanResult(
            items: [],
            error: '"detected_items" missing in backend response.',
            errorCode: 500,
          );
        }
      } else {
        // Non-200: backend error or Gemini error
        String? errMsg;
        int? errCode = response.statusCode;
        if (jsonResp is Map && jsonResp.containsKey('error')) {
          // If backend provided a custom error structure
          if (jsonResp['error'] is String) {
            errMsg = jsonResp['error'];
          } else if (jsonResp['error'] is Map && jsonResp['error']['message'] != null) {
            errMsg = jsonResp['error']['message'];
          } else {
            errMsg = jsonResp['error'].toString();
          }
        } else {
          errMsg = 'Unknown backend error (${response.statusCode}).';
        }
        return GeminiFoodScanResult(
          items: [],
          error: errMsg,
          errorCode: errCode,
        );
      }
    } catch (e) {
      // Network/decoding exceptions
      print('\x1B[31m[DEBUG] Backend API exception: $e\x1B[0m');
      return GeminiFoodScanResult(
        items: [],
        error: 'Failed to connect or parse backend response.',
        errorCode: null,
      );
    }
  }
}

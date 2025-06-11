// ignore_for_file: file_names

import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'backend_config.dart';

// ignore: constant_identifier_names
const String BACKEND_API_URL = "$backendApiUrl/receipt/scanReceipt";

final geminiReceiptProvider = Provider((ref) => GeminiReceiptService());

class GeminiReceiptService {
  /// Sends a receipt image to the backend and returns
  /// a list of maps: [{"item": String, "count": double?}, ...]
  Future<List<Map<String, dynamic>>> analyzeReceiptImage(File imageFile) async {
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
          final List<Map<String, dynamic>> rawItems =
              List<Map<String, dynamic>>.from(jsonResp['detected_items']);

          // Ensure all counts are double? for downstream UI
          return rawItems.map((item) {
            String name = item['item'] ?? '';
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
            return {'item': name, 'count': count};
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

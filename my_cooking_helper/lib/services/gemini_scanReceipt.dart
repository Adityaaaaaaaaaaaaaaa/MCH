// ignore_for_file: file_names

import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '/config/backend_config.dart';

// ignore: non_constant_identifier_names
final String BACKEND_API_URL = geminiScanReceipt;

final geminiReceiptProvider = Provider((ref) => GeminiReceiptService());

class GeminiReceiptScanResult {
  final List<Map<String, dynamic>> items;
  final String? error;
  final int? errorCode;

  GeminiReceiptScanResult({required this.items, this.error, this.errorCode});
}

class GeminiReceiptService {
  String capitalize(String input) {
    if (input.isEmpty) return input;
    return '${input[0].toUpperCase()}${input.substring(1).toLowerCase()}';
  }

  Future<GeminiReceiptScanResult> analyzeReceiptImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(BACKEND_API_URL));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('\x1B[34m[DEBUG] Backend API status: ${response.statusCode}\x1B[0m');
      print('\x1B[34m[DEBUG] Backend API response: $responseBody\x1B[0m');

      final jsonResp = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        if (jsonResp is Map && jsonResp.containsKey('detected_items')) {
          final List<dynamic> gemItems = jsonResp['detected_items'];

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

          return GeminiReceiptScanResult(items: items);
        } else {
          // Response is malformed
          return GeminiReceiptScanResult(
            items: [],
            error: '"detected_items" missing in backend response.',
            errorCode: 500,
          );
        }
      } else {
        // Non-200 (backend or Gemini error)
        String? errMsg;
        int? errCode = response.statusCode;
        if (jsonResp is Map && jsonResp.containsKey('error')) {
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
        return GeminiReceiptScanResult(
          items: [],
          error: errMsg,
          errorCode: errCode,
        );
      }
    } catch (e) {
      print('\x1B[31m[DEBUG] Backend API exception: $e\x1B[0m');
      return GeminiReceiptScanResult(
        items: [],
        error: 'Failed to connect or parse backend response.',
        errorCode: null,
      );
    }
  }
}

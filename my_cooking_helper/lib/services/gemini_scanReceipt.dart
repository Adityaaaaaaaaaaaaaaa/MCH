// ignore_for_file: file_names

import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '/config/backend_config.dart';

final geminiReceiptProvider = Provider((ref) => GeminiReceiptService());

class GeminiReceiptScanResult {
  final List<Map<String, dynamic>> items;
  final String? error;
  final int? errorCode;
  GeminiReceiptScanResult({required this.items, this.error, this.errorCode});
}

class GeminiReceiptService {
  String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  Future<GeminiReceiptScanResult> analyzeReceiptImage(File imageFile) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse(geminiScanReceipt));
      req.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final resp = await req.send();
      final body = await resp.stream.bytesToString();

      final jsonResp = jsonDecode(body);

      if (resp.statusCode == 200) {
        final List<dynamic> arr = (jsonResp is Map && jsonResp['detected_items'] is List)
            ? jsonResp['detected_items'] as List
            : const [];

        final items = arr.map<Map<String, dynamic>>((e) {
          final name = _cap((e['itemName'] ?? e['item'] ?? '').toString());

          // quantity parsing
          final dynamic q = e['quantity'];
          final double qty = (q is num) ? q.toDouble() : double.tryParse('${q}') ?? 1.0;

          final unit = (e['unit'] ?? 'count').toString().toLowerCase().trim();

          return {
            'itemName': name,
            'quantity': qty,
            'unit': unit, // 'g' | 'ml' | 'count'
            'category': (e['category'] ?? 'Uncategorized').toString(),
          };
        }).toList();

        return GeminiReceiptScanResult(items: items);
      } else {
        String errMsg = 'Unknown backend error (${resp.statusCode}).';
        int errCode = resp.statusCode;
        if (jsonResp is Map && jsonResp['error'] != null) {
          errMsg = jsonResp['error'].toString();
          errCode = (jsonResp['error_code'] ?? errCode) as int;
        }
        return GeminiReceiptScanResult(items: [], error: errMsg, errorCode: errCode);
      }
    } catch (e) {
      print('\x1B[31m[DEBUG] Backend API exception: $e\x1B[0m');
      return GeminiReceiptScanResult(
        items: [],
        error: 'Failed to connect or parse backend response.',
      );
    }
  }
}

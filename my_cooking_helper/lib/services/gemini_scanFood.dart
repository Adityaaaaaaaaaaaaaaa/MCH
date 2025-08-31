// lib/services/gemini_scanFood.dart
// ignore_for_file: file_names

import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '/config/backend_config.dart';


final geminiProvider = Provider((ref) => GeminiService());

class GeminiFoodScanResult {
  final List<Map<String, dynamic>> items;
  final String? error;
  final int? errorCode;
  GeminiFoodScanResult({required this.items, this.error, this.errorCode});
}

class GeminiService {
  String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  Future<GeminiFoodScanResult> analyzeFoodImage(File imageFile) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse(geminiScanFood));
      req.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final resp = await req.send();
      final body = await resp.stream.bytesToString();

      print('\x1B[34m[DEBUG] Backend API status: ${resp.statusCode}\x1B[0m');
      print('\x1B[34m[DEBUG] Backend API response: $body\x1B[0m');

      final jsonResp = jsonDecode(body);
      if (resp.statusCode == 200) {
        final List<dynamic> arr = (jsonResp is Map && jsonResp['detected_items'] is List)
            ? jsonResp['detected_items'] as List
            : const [];

        final items = arr.map<Map<String, dynamic>>((e) {
          final name = _cap((e['itemName'] ?? e['item'] ?? '').toString());
          final unit = (e['unit'] ?? 'count').toString().toLowerCase().trim();
          double qty;
          final q = e['quantity'];
          if (q is int) {
            qty = q.toDouble();
          } else if (q is double) {
            qty = q;
          } else {
            qty = double.tryParse(q?.toString() ?? '') ?? 1.0;
          }
          return {
            'itemName': name,
            'quantity': qty,
            'unit': unit, // 'g' | 'ml' | 'count'
            'category': (e['category'] ?? 'Uncategorized').toString(),
          };
        }).toList();

        return GeminiFoodScanResult(items: items);
      } else {
        String errMsg = 'Unknown backend error (${resp.statusCode}).';
        int errCode = resp.statusCode;
        if (jsonResp is Map && jsonResp['error'] != null) {
          errMsg = jsonResp['error'].toString();
          errCode = (jsonResp['error_code'] ?? errCode) as int;
        }
        return GeminiFoodScanResult(items: [], error: errMsg, errorCode: errCode);
      }
    } catch (e) {
      print('\x1B[31m[DEBUG] Backend API exception: $e\x1B[0m');
      return GeminiFoodScanResult(items: [], error: 'Failed to connect or parse backend response.');
    }
  }
}

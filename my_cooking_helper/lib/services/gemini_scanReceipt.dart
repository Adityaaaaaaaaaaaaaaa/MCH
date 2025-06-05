import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// ignore: constant_identifier_names
const String BACKEND_API_URL = "https://mch-rtlu.onrender.com/food/scanReceipt"; // <-- Render backend URL
// ignore: constant_identifier_names
//const String BACKEND_API_URL = "http://192.168.223.52:8000/food/scanReceipt"; // <-- PC IP, update 


final geminiReceiptProvider = Provider((ref) => GeminiReceiptService());

class GeminiReceiptService {
  // Accepts a File (image), sends it to FastAPI backend, returns parsed response
  Future<String> analyzeReceiptImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(BACKEND_API_URL));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('\x1B[34m[DEBUG] Backend API status: ${response.statusCode}\x1B[0m');
      print('\x1B[34m[DEBUG] Backend API response: $responseBody\x1B[0m');

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        return "Error: Backend returned status ${response.statusCode} - $responseBody";
      }
    } catch (e) {
      print('\x1B[31m[DEBUG] Backend API error: $e\x1B[0m');
      return "Error: Could not reach backend: $e";
    }
  }
}

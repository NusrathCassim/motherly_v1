import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:motherly_v1/models/scan_result_model.dart';

class ApiService {
  // DEFINE THIS - Your Render URL
  // static const String baseUrl = 'https://motherly-backend.onrender.com';
  
  // Alternative URLs (comment/uncomment as needed)
  // static const String baseUrl = 'http://10.0.2.2:5000';  // Android emulator
 //  static const String baseUrl = 'http://192.168.63.217:5000';  // Local network
   static const String baseUrl = 'http://192.168.1.109:5000';  // Local network
  // static const String baseUrl = 'http://localhost:5000';  // iOS simulator

  static Future<ScanResult> analyzeBabyImage(File imageFile, {bool isSinhala = false}) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/analyze-image'),  // Now baseUrl is defined!
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path)
      );
      
      // Add language preference
      request.fields['language'] = isSinhala ? 'si' : 'en';

      print('📤 Sending image to: $baseUrl/analyze-image');
      
      // Add timeout for cold starts
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return ScanResult.fromJson(jsonData);
      } else {
        var errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to analyze image');
      }
    } catch (e) {
      print('❌ API Error: $e');
      throw Exception('Failed to connect to server. Server may be waking up. Please try again.');
    }
  }

  static Future<bool> checkHealth() async {
    try {
      print('🔍 Checking health at: $baseUrl/health');
      var response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 15));  // Longer timeout for cold starts

      print('🔍 Health check: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getModelInfo() async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/model-info'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get model info');
      }
    } catch (e) {
      print('❌ Error getting model info: $e');
      throw Exception('Failed to connect to server');
    }
  }

  static Future<void> sendFeedback(Map<String, dynamic> feedback) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(feedback),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to send feedback');
      }
    } catch (e) {
      print('❌ Error sending feedback: $e');
    }
  }

  


}



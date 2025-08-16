import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PlantService {
  static const String baseUrl = "https://os.dsenergize.com";

  /// Extract MongoDB ID safely
  static String? extractPlantId(Map<String, dynamic> plant) {
    if (plant.containsKey('id') && plant['id'] is String) {
      return plant['id']!.toString().trim();
    }
    final rawId = plant['_id'];
    if (rawId is String) return rawId.trim();
    if (rawId is Map && rawId.containsKey(r"$oid")) {
      return rawId[r"$oid"]?.toString().trim();
    }
    return null;
  }

  /// Helper: Get authorization headers
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// ===== FETCH PLANTS =====
  static Future<List<Map<String, dynamic>>> fetchPlants() async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/api/plants');

    final response = await http.get(url, headers: headers);
    print("🌱 Fetch Plants: ${response.statusCode} ${response.body}");

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          final plantsRaw = data['data'] as List;
          final plants = plantsRaw
              .map((p) => Map<String, dynamic>.from(p))
              .toList();

          // Map plantId -> id for Flutter
          for (var plant in plants) {
            if (plant.containsKey('plantId') && !plant.containsKey('id')) {
              plant['id'] = plant['plantId']?.toString().trim();
            }
          }
          return plants;
        }
      } catch (e) {
        throw Exception('Invalid response format in fetchPlants: $e');
      }
    }
    throw Exception('Failed to load plants');
  }

  /// Fetch RMS Dashboard Data for a given plant
  static Future<Map<String, dynamic>> fetchRmsDashboard(String plantId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/api/rmsdashboard/$plantId');

    final response = await http.get(url, headers: headers);
    print("📊 RMS Dashboard: ${response.statusCode} ${response.body}");
    if (response.statusCode == 200) {
      try {
        final raw = jsonDecode(response.body);
        if (raw is Map<String, dynamic>) {
          if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
            return Map<String, dynamic>.from(raw['data']);
          }
          return raw;
        }
      } catch (e) {
        throw Exception('Invalid JSON in fetchRmsDashboard: $e');
      }
    }
    throw Exception('Failed to load RMS Dashboard');
  }

  /// Fetch alerts for the plant
  static Future<List<Map<String, dynamic>>> fetchAlerts(String plantId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/api/plants/$plantId/alerts');

    final response = await http.get(url, headers: headers);
    print("🚨 Alerts: ${response.statusCode} ${response.body}");

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      } catch (e) {
        throw Exception('Invalid JSON in fetchAlerts: $e');
      }
    }
    throw Exception('Failed to load alerts');
  }
}

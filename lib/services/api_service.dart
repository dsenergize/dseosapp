import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';

class ApiService {
  static const String baseUrl = "https://dsenergize-775014090096.europe-west1.run.app";

  /// Get headers including authorization if token available.
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token')?.trim();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ===== LOGIN =====
  static Future<UserModel?> login(String identifier, String password) async {
    final url = Uri.parse('$baseUrl/api/users/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'password': password}),
      );
      print("🔑 Login: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final user = UserModel.fromJson(data['user']);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', user.token.trim());
          await prefs.setString('user_data', jsonEncode(user.toJson()));
          return user;
        }
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
    return null;
  }

  // ===== FETCH & SEARCH PLANTS =====
  static Future<List<Map<String, dynamic>>> fetchPlants({String? searchQuery}) async {
    final headers = await _getHeaders();
    var urlString = '$baseUrl/api/plants';
    if (searchQuery != null && searchQuery.isNotEmpty) {
      urlString += '?search=${Uri.encodeComponent(searchQuery)}';
    }
    final url = Uri.parse(urlString);

    try {
      final response = await http.get(url, headers: headers);
      print("🌱 Fetch/Search Plants: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          final plants = List<Map<String, dynamic>>.from(data['data']);
          // Normalize plantId to id for consistency
          for (var plant in plants) {
            if (plant.containsKey('plantId') && !plant.containsKey('id')) {
              plant['id'] = plant['plantId']?.toString().trim();
            }
          }
          return plants;
        }
      }
    } catch (e) {
      throw Exception('fetchPlants failed: $e');
    }
    throw Exception('Failed to load plants');
  }


  // ===== FETCH RMS DASHBOARD (UPDATED to POST) =====
  static Future<Map<String, dynamic>> fetchRmsDashboard({
    String? plantId,
    String? plantName,
    DateTime? date,
  }) async {
    if ((plantId == null || plantId.isEmpty) && (plantName == null || plantName.isEmpty)) {
      throw Exception('Either plantId or plantName must be provided');
    }
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/api/RmsDashboard');
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'plantId': plantId,
          'plantName': plantName,
          if (date != null) 'date': DateFormat('yyyy-MM-dd').format(date),
        }),
      );
      print("📊 RMS Dashboard: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(data['data']);
        }
      }
    } catch (e) {
      throw Exception('fetchRmsDashboard failed: $e');
    }
    throw Exception('Failed to load RMS Dashboard');
  }

  // ===== FETCH ALERTS (ALREADY POST) =====
  static Future<List<Map<String, dynamic>>> fetchAlerts({
    String? plantId,
    String? plantName,
    DateTime? date,
  }) async {
    if ((plantId == null || plantId.isEmpty) && (plantName == null || plantName.isEmpty)) {
      throw Exception('Either plantId or plantName must be provided');
    }
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/api/RmsDashboard/alert');
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'plantId': plantId,
          'plantName': plantName,
          if (date != null) 'date': DateFormat('yyyy-MM-dd').format(date),
        }),
      );
      print("🚨 Alerts: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['deviceType'] != null && data['data']['deviceType']['inverter'] is List) {
          return List<Map<String, dynamic>>.from(data['data']['deviceType']['inverter']);
        }
      }
    } catch (e) {
      throw Exception('fetchAlerts failed: $e');
    }
    throw Exception('Failed to load alerts');
  }

  // ===== FETCH DAILY ENERGY (POST) =====
  static Future<List<Map<String, dynamic>>> fetchDailyEnergy(
      String plantId, DateTime date) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/api/RmsDashboard/lastsevendaygeneration/dailyEnergy');
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'plantId': plantId,
          'date': DateFormat('yyyy-MM-dd').format(date),
        }),
      );
      print("⚡ Daily Energy: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      throw Exception('fetchDailyEnergy failed: $e');
    }
    return [];
  }

  // ===== FETCH POA RADIATION (UPDATED to use plantName correctly in collection) =====
  static Future<List<Map<String, dynamic>>> fetchPoaRadiation(
      String plantId, String plantName, DateTime date) async {
    final headers = await _getHeaders();
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final url = Uri.parse('$baseUrl/api/RmsDashboard/charts/poaRadiation?collection=plant_$plantName&date=$formattedDate&intervalMinutes=5');
    try {
      final response = await http.get(url, headers: headers);
      print("☀️ POA Radiation: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      throw Exception('fetchPoaRadiation failed: $e');
    }
    return [];
  }

  // ===== FETCH AMBIENT TEMPERATURE (UPDATED to use plantName correctly in collection) =====
  static Future<List<Map<String, dynamic>>> fetchAmbientTemp(
      String plantId, String plantName, DateTime date) async {
    final headers = await _getHeaders();
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final url = Uri.parse('$baseUrl/api/RmsDashboard/charts/ambientTemp?collection=plant_$plantName&date=$formattedDate&intervalMinutes=5');
    try {
      final response = await http.get(url, headers: headers);
      print("🌡️ Ambient Temp: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      throw Exception('fetchAmbientTemp failed: $e');
    }
    return [];
  }

  // ===== FETCH AC POWER (NEW METHOD - GET) =====
  static Future<List<Map<String, dynamic>>> fetchAcPower(
      String plantId, String plantName, DateTime date) async {
    final headers = await _getHeaders();
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final url = Uri.parse('$baseUrl/api/RmsDashboard/charts/acPower?collection=plant_$plantName&date=$formattedDate&intervalMinutes=5');
    try {
      final response = await http.get(url, headers: headers);
      print("🔌 AC Power: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      throw Exception('fetchAcPower failed: $e');
    }
    return [];
  }

  // ===== FETCH SOLAR POWER (NEW METHOD - GET) =====
  static Future<List<Map<String, dynamic>>> fetchSolarPower(
      String plantId, String plantName, DateTime date) async {
    final headers = await _getHeaders();
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final url = Uri.parse('$baseUrl/api/RmsDashboard/charts/solarPower?collection=plant_$plantName&date=$formattedDate&intervalMinutes=5');
    try {
      final response = await http.get(url, headers: headers);
      print("🌞 Solar Power: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      throw Exception('fetchSolarPower failed: $e');
    }
    return [];
  }

  // ===== FETCH WIND SPEED (NEW METHOD - GET) =====
  static Future<List<Map<String, dynamic>>> fetchWindSpeed(
      String plantId, String plantName, DateTime date) async {
    final headers = await _getHeaders();
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final url = Uri.parse('$baseUrl/api/RmsDashboard/charts/windSpeed?collection=plant_$plantName&date=$formattedDate&intervalMinutes=5');
    try {
      final response = await http.get(url, headers: headers);
      print("🌬️ Wind Speed: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      throw Exception('fetchWindSpeed failed: $e');
    }
    return [];
  }

  // ===== FETCH LIFETIME EXPORT (NEW METHOD - GET) =====
  static Future<List<Map<String, dynamic>>> fetchLifetimeExport(
      String plantId, String plantName, DateTime date) async {
    final headers = await _getHeaders();
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final url = Uri.parse('$baseUrl/api/RmsDashboard/charts/lifeTimeExport?collection=plant_$plantName&date=$formattedDate&intervalMinutes=5');
    try {
      final response = await http.get(url, headers: headers);
      print("📈 Lifetime Export: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      throw Exception('fetchLifetimeExport failed: $e');
    }
    return [];
  }

  // ===== FETCH DAILY EXPORT (NEW METHOD - POST) =====
  static Future<List<Map<String, dynamic>>> fetchDailyExport(
      String plantId, DateTime date) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/api/RmsDashboard/lastsevendaygeneration/dailyExport');
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'plantId': plantId,
          'date': DateFormat('yyyy-MM-dd').format(date),
        }),
      );
      print("📉 Daily Export: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      throw Exception('fetchDailyExport failed: $e');
    }
    return [];
  }

  // ===== FETCH POA INSOLATION (NEW METHOD - GET) =====
  static Future<List<Map<String, dynamic>>> fetchPoaInsolation(
      String plantId, String plantName, DateTime date) async {
    final headers = await _getHeaders();
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final url = Uri.parse('$baseUrl/api/RmsDashboard/lastsevendaygeneration/poaInsolation?collection=plant_$plantName&date=$formattedDate&intervalMinutes=5');
    try {
      final response = await http.get(url, headers: headers);
      print("🌞 POA Insolation: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      throw Exception('fetchPoaInsolation failed: $e');
    }
    return [];
  }

  // ===== FETCH PR METERS (NEW METHOD - POST) =====
  static Future<List<Map<String, dynamic>>> fetchPrMeters(
      String plantId, DateTime date) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/api/RmsDashboard/lastsevendaygeneration/prMeters');
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'plantId': plantId,
          'date': DateFormat('yyyy-MM-dd').format(date),
        }),
      );
      print("📈 PR Meters: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      throw Exception('fetchPrMeters failed: $e');
    }
    return [];
  }

  // ===== CHANGE PASSWORD =====
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/api/users/change-password');
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        }),
      );
      print("🔒 Change Password: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      throw Exception('changePassword failed: $e');
    }
    return false;
  }

  // ===== UPDATE PROFILE =====
  static Future<UserModel?> updateProfile({
    required String name,
    required String email,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/api/users/update-profile');
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          "name": name,
          "email": email,
        }),
      );
      print("✏️ Update Profile: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final updatedUser = UserModel.fromJson(data['user']);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(updatedUser.toJson()));
          return updatedUser;
        }
      }
    } catch (e) {
      throw Exception('updateProfile failed: $e');
    }
    return null;
  }
}

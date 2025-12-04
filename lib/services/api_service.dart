import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';

// Custom exception for handling authentication errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class ApiService {
  static const String baseUrl = "https://os.dsenergize.com";

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token')?.trim();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static void _handleAuthError(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AuthException('Invalid or expired token. Please log in again.');
    }
  }

  // ===== LOGIN =====
  static Future<UserModel> login(String identifier, String password) async {
    final url = Uri.parse('$baseUrl/api/users/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'password': password}),
      );

      developer.log("🔑 Login Status: ${response.statusCode}", name: 'ApiService.login');
      developer.log("🔑 Login Response: ${response.body}", name: 'ApiService.login');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['token'] != null) {
          final token = data['token'] as String;

          final parts = token.split('.');
          if (parts.length != 3) {
            throw Exception('Invalid token received from server.');
          }
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final resp = utf8.decode(base64Url.decode(normalized));
          final payloadMap = json.decode(resp) as Map<String, dynamic>;

          payloadMap['token'] = token;

          final user = UserModel.fromJson(payloadMap);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token.trim());
          await prefs.setString('user_data', jsonEncode(user.toJson()));
          return user;
        } else {
          throw Exception('Login successful but token is missing from the response.');
        }
      } else {
        throw Exception(data['message'] ?? 'Invalid credentials or server error.');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error. Please check your connection.');
      }
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  // ===== FETCH & SEARCH PLANTS =====
  static Future<List<Map<String, dynamic>>> fetchPlants(
      {String? searchQuery}) async {
    final headers = await _getHeaders();
    var urlString = '$baseUrl/api/plants';
    if (searchQuery != null && searchQuery.isNotEmpty) {
      urlString += '?search=${Uri.encodeComponent(searchQuery)}';
    }
    final url = Uri.parse(urlString);

    try {
      final response = await http.get(url, headers: headers);
      developer.log("🌱 Fetch/Search Plants: ${response.statusCode}", name: 'ApiService.fetchPlants');
      _handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          final plants = List<Map<String, dynamic>>.from(data['data']);
          for (var plant in plants) {
            if (plant.containsKey('plantId') && !plant.containsKey('id')) {
              plant['id'] = plant['plantId']?.toString().trim();
            }
          }
          return plants;
        }
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw Exception('fetchPlants failed: $e');
    }
    throw Exception('Failed to load plants');
  }

  // ===== FETCH RMS DASHBOARD =====
  static Future<Map<String, dynamic>> fetchRmsDashboard({
    String? plantId,
    String? plantName,
    DateTime? date,
  }) async {
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
      developer.log("📊 RMS Dashboard: ${response.statusCode}", name: 'ApiService.fetchRmsDashboard');
      _handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(data['data']);
        }
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw Exception('fetchRmsDashboard failed: $e');
    }
    throw Exception('Failed to load RMS Dashboard');
  }

  // ===== FETCH ALERTS =====
  static Future<List<Map<String, dynamic>>> fetchAlerts({
    String? plantId,
    String? plantName,
    DateTime? date,
  }) async {
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
      developer.log("🚨 Alerts: ${response.statusCode}", name: 'ApiService.fetchAlerts');
      _handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null &&
            data['data']['deviceType'] != null &&
            data['data']['deviceType']['inverter'] is List) {
          return List<Map<String, dynamic>>.from(
              data['data']['deviceType']['inverter']);
        }
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw Exception('fetchAlerts failed: $e');
    }
    return [];
  }

  // ===== FETCH DEVICE STATUS =====
  static Future<Map<String, dynamic>> getDeviceStatus(String plantId, DateTime date) async {
    final headers = await _getHeaders();
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final url = Uri.parse('$baseUrl/api/RmsDashboard/alert/deviceStatus?plantId=$plantId&date=$formattedDate');

    developer.log("Requesting GET URL for Device Status: $url", name: "ApiService.getDeviceStatus");

    try {
      final response = await http.get(url, headers: headers);
      developer.log("Fetching Device Status: ${response.statusCode}", name: "ApiService.getDeviceStatus");
      _handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      rethrow;
    }
    throw Exception('Failed to load device status');
  }

  // ===== NEW CHART DATA METHODS =====
  static Future<Map<String, dynamic>> fetchSevenDayGenerationChartData(String plantId, DateTime date) async {
    final headers = await _getHeaders();
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final url = Uri.parse('$baseUrl/api/RmsDashboard/rmsCharts/sevenDayGen?plantId=$plantId&date=$formattedDate');

    developer.log("Requesting Chart Data: $url", name: "ApiService.fetchSevenDayGen");

    try {
      final response = await http.get(url, headers: headers);
      developer.log("Seven Day Gen Chart Status: ${response.statusCode}", name: "ApiService.fetchSevenDayGen");
      _handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    } catch(e) {
      if (e is AuthException) rethrow;
      developer.log("Error fetching Seven Day Gen chart: $e", name: "ApiService.fetchSevenDayGen");
    }
    return {};
  }

  static Future<Map<String, dynamic>> fetchPowerVsIrradianceChartData(String plantId, DateTime date) async {
    final headers = await _getHeaders();
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final url = Uri.parse('$baseUrl/api/RmsDashboard/rmsCharts/powerVsIrradiance?plantId=$plantId&date=$formattedDate');

    developer.log("Requesting Chart Data: $url", name: "ApiService.fetchPowerVsIrradiance");

    try {
      final response = await http.get(url, headers: headers);
      developer.log("Power vs Irradiance Chart Status: ${response.statusCode}", name: "ApiService.fetchPowerVsIrradiance");
      _handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    } catch(e) {
      if (e is AuthException) rethrow;
      developer.log("Error fetching Power vs Irradiance chart: $e", name: "ApiService.fetchPowerVsIrradiance");
    }
    return {};
  }

  // ===== MAIN DATA REPORTING HELPER =====
  static Future<Map<String, dynamic>> _fetchReportAsObject(
      String path, String plantId, DateTime date, {String? inverterName, String? meterName}) async {
    final headers = await _getHeaders();

    String formattedDate;
    if (path.endsWith('monthlyReport') || path.endsWith('yearlyReport')) {
      formattedDate = DateFormat('yyyy').format(date);
    } else if (path.endsWith('dailyReport')) {
      formattedDate = DateFormat('yyyy-MM').format(date);
    } else {
      formattedDate = DateFormat('yyyy-MM-dd').format(date);
    }

    var urlString = '$baseUrl/api/RmsDashboard/$path?plantId=$plantId&date=$formattedDate';
    if (inverterName != null && inverterName.isNotEmpty) {
      urlString += '&inverterName=${Uri.encodeComponent(inverterName)}';
    }
    if (meterName != null && meterName.isNotEmpty) {
      urlString += '&meterName=${Uri.encodeComponent(meterName)}';
    }
    final url = Uri.parse(urlString);

    developer.log("------------------------------------------------------", name: 'ApiService');
    developer.log("🚀 Making GET request for: $path", name: 'ApiService');
    developer.log("🔗 URL: $url", name: 'ApiService');

    try {
      final response = await http.get(url, headers: headers);
      developer.log("🚦 Status Code for $path: ${response.statusCode}", name: 'ApiService');
      _handleAuthError(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (path.startsWith('getPlant/')) {
          if (data != null && data['success'] == true && data['data'] is Map<String, dynamic>) {
            return data['data'];
          }
        } else {
          if (data is Map<String, dynamic>) {
            return data;
          }
        }

        developer.log('API for endpoint $path returned an unexpected format', name: 'ApiService');
        return {};

      } else {
        throw Exception('Failed to load $path with status code ${response.statusCode}');
      }
    } catch (e) {
      developer.log("🔥 Exception for $path: $e", name: 'ApiService');
      if (e is AuthException) rethrow;
      throw Exception('Failed to fetch $path: $e');
    }
  }

  // ===== NEW REPORTING Endpoints =====

  // --- Inverter ---
  static Future<Map<String, dynamic>> getInverterDayData(String plantId, DateTime date, {String? inverterName}) =>
      _fetchReportAsObject('getInverter/dayData', plantId, date, inverterName: inverterName);
  static Future<Map<String, dynamic>> getInverterDailyReport(String plantId, DateTime date) =>
      _fetchReportAsObject('getInverter/dailyReport', plantId, date);
  static Future<Map<String, dynamic>> getInverterMonthlyReport(String plantId, DateTime date) =>
      _fetchReportAsObject('getInverter/monthlyReport', plantId, date);
  static Future<Map<String, dynamic>> getInverterYearlyReport(String plantId, DateTime date) =>
      _fetchReportAsObject('getInverter/yearlyReport', plantId, date);

  // --- Meter ---
  static Future<Map<String, dynamic>> getMeterDayData(String plantId, DateTime date) =>
      _fetchReportAsObject('getMeter/dayData', plantId, date);
  static Future<Map<String, dynamic>> getMeterDailyReport(String plantId, DateTime date) =>
      _fetchReportAsObject('getMeter/dailyReport', plantId, date);
  static Future<Map<String, dynamic>> getMeterMonthlyReport(String plantId, DateTime date) =>
      _fetchReportAsObject('getMeter/monthlyReport', plantId, date);

  // --- Weather Station ---
  static Future<Map<String, dynamic>> getWeatherDayData(String plantId, DateTime date) =>
      _fetchReportAsObject('getWeather/dayData', plantId, date);
  static Future<Map<String, dynamic>> getWeatherDailyReport(String plantId, DateTime date) =>
      _fetchReportAsObject('getWeather/dailyReport', plantId, date);
  static Future<Map<String, dynamic>> getWeatherMonthlyReport(String plantId, DateTime date) =>
      _fetchReportAsObject('getWeather/monthlyReport', plantId, date);
  static Future<Map<String, dynamic>> getWeatherYearlyReport(String plantId, DateTime date) =>
      _fetchReportAsObject('getWeather/yearlyReport', plantId, date);


  // --- Plant ---
  static Future<Map<String, dynamic>> getPlantDayData(String plantId, DateTime date) =>
      _fetchReportAsObject('getPlant/dayData', plantId, date);
  static Future<Map<String, dynamic>> getPlantDailyReport(String plantId, DateTime date) =>
      _fetchReportAsObject('getPlant/dailyReport', plantId, date);
  static Future<Map<String, dynamic>> getPlantMonthlyReport(String plantId, DateTime date) =>
      _fetchReportAsObject('getPlant/monthlyReport', plantId, date);
  static Future<Map<String, dynamic>> getPlantYearlyReport(String plantId, DateTime date) =>
      _fetchReportAsObject('getPlant/yearlyReport', plantId, date);

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
      developer.log("🔒 Change Password: ${response.statusCode}", name: 'ApiService.changePassword');
      _handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      if (e is AuthException) rethrow;
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
      developer.log("✏️ Update Profile: ${response.statusCode}", name: 'ApiService.updateProfile');
      _handleAuthError(response);
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
      if (e is AuthException) rethrow;
      throw Exception('updateProfile failed: $e');
    }
    return null;
  }
}


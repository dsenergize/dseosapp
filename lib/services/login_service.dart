import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class LoginService {
  final String baseUrl = 'https://os.dsenergize.com';

  Future<UserModel?> login(String identifier, String password) async {
    final url = Uri.parse('$baseUrl/api/users/login'); // ✅ Correct backend path

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier, // matches backend
          'password': password,
        }),
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['user'] != null) {
          final user = UserModel.fromJson(data['user']);

          // Save token in SharedPreferences for future API calls
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', user.token);

          // Optionally save whole user as JSON string
          await prefs.setString('user_data', jsonEncode(user.toJson()));

          return user;
        } else {
          print('Unexpected response format: $data');
          return null;
        }
      } else {
        _logError(response.body);
        return null;
      }
    } catch (e) {
      print('Login API error: $e');
      return null;
    }
  }

  void _logError(String body) {
    try {
      final json = jsonDecode(body);
      print('Error: ${json['message'] ?? body}');
    } catch (_) {
      print('Error: $body');
    }
  }
}

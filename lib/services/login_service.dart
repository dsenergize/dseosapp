// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/user_model.dart';
//
// class LoginService {
//   final String baseUrl = 'https://os.dsenergize.com';
//
//   Future<UserModel?> login(String identifier, String password) async {
//     final url = Uri.parse('$baseUrl/api/users/login'); // ✅ Correct backend path
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'identifier': identifier, // matches backend
//           'password': password,
//         }),
//       );
//
//       print('Status code: ${response.statusCode}');
//       print('Response body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//
//         if (data['success'] == true && data['user'] != null) {
//           final user = UserModel.fromJson(data['user']);
//
//           // Save token in SharedPreferences for future API calls
//           final prefs = await SharedPreferences.getInstance();
//           await prefs.setString('auth_token', user.token);
//
//           // Optionally save whole user as JSON string
//           await prefs.setString('user_data', jsonEncode(user.toJson()));
//
//           return user;
//         } else {
//           print('Unexpected response format: $data');
//           return null;
//         }
//       } else {
//         _logError(response.body);
//         return null;
//       }
//     } catch (e) {
//       print('Login API error: $e');
//       return null;
//     }
//   }
//
//   void _logError(String body) {
//     try {
//       final json = jsonDecode(body);
//       print('Error: ${json['message'] ?? body}');
//     } catch (_) {
//       print('Error: $body');
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = false;
  bool _loading = false;
  String? _error;

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ApiService.login(_userController.text.trim(), _passController.text);
      if (user != null) {
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', user.token);
        }
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() {
          _error = "Invalid credentials. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Network/API error: ${e.toString()}";
      });
    } finally {
      if(mounted){
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/logo1.jpg', height: 100),
                const SizedBox(height: 24),
                Text(
                  "Welcome to DSE OS",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  "Sign in to continue",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: kTextSecondaryColor),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _userController,
                        decoration: const InputDecoration(
                          labelText: "Username or Email",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? "Please enter your username or email" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passController,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? "Please enter your password" : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                activeColor: kPrimaryColor,
                                onChanged: (val) => setState(() => _rememberMe = val ?? false),
                              ),
                              const Text("Remember Me"),
                            ],
                          ),
                          TextButton(
                            onPressed: (){},
                            child: const Text("Forgot Password?"),
                          )
                        ],
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loading ? null : _handleLogin,
                        child: _loading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                            : const Text("Login"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

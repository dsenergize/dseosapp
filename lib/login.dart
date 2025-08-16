import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> login() async {
    setState(() { isLoading = true; errorMessage = null; });

    final url = Uri.parse("https://your-api.com/login"); // Change this
    final response = await http.post(
      url,
      headers: { "Content-Type": "application/json" },
      body: json.encode({
        "email": emailController.text,
        "password": passwordController.text
      }),
    );

    setState(() { isLoading = false; });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["success"] == true) {
        Navigator.pushReplacementNamed(context, "/dashboard");
      } else {
        setState(() { errorMessage = data["message"] ?? "Login failed"; });
      }
    } else {
      setState(() { errorMessage = "Server error: ${response.statusCode}"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            if (errorMessage != null)
              Text(errorMessage!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : login,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}

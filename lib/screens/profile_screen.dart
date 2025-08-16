import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';

const kBlueColor = Color(0xFF0075B2);
const kYellowColor = Color(0xFFE3A72F);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = prefs.getString('user_data');
    if (userDataJson != null) {
      if(mounted){
        setState(() {
          _user = UserModel.fromJson(jsonDecode(userDataJson));
          _loading = false;
        });
      }
    } else {
      if(mounted){
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kBlueColor));
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: _user == null
          ? const Center(child: Text('No user found'))
          : ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: kBlueColor,
              child: Text(
                _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : "U",
                style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _user!.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          Center(
            child: Text(
              _user!.email,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 30),
          ListTile(
            leading: const Icon(Icons.edit, color: kBlueColor),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final updatedUser = await Navigator.push<UserModel>(
                context,
                MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user!)),
              );
              if (updatedUser != null) setState(() => _user = updatedUser);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock, color: kBlueColor),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}

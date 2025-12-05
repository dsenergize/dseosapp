import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import '../theme.dart';

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
    if (mounted) {
      setState(() {
        if (userDataJson != null) {
          _user = UserModel.fromJson(jsonDecode(userDataJson));
        }
        _loading = false;
      });
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

  String _getInitials(String name) {
    if (name.isEmpty) return "?";
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else {
      return parts[0][0].toUpperCase();
    }
  }

  Gradient _getGradientFromName(String name) {
    final List<Gradient> energyGradients = [
      const LinearGradient(
          colors: [Colors.blue, Colors.lightBlueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      const LinearGradient(
          colors: [Colors.orange, Colors.yellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      const LinearGradient(
          colors: [Colors.deepOrange, Colors.amber],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      const LinearGradient(
          colors: [Colors.blueAccent, Colors.yellowAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      const LinearGradient(
          colors: [Colors.lightBlue, Colors.orangeAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
    ];
    if (name.isEmpty) {
      return const LinearGradient(colors: [Colors.grey, Colors.grey]);
    }
    final int hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return energyGradients[hash % energyGradients.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: kPrimaryColor));
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: _user == null
            ? const Center(child: Text('No user found'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 30),
                  _buildActionButton(
                    label: 'Edit Profile',
                    onTap: () async {
                      final updatedUser = await Navigator.push<UserModel>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: _user!)),
                      );
                      if (updatedUser != null) {
                        setState(() => _user = updatedUser);
                      }
                    },
                    backgroundColor: kPrimaryColor.withValues(alpha: .1),
                    textColor: kPrimaryColor,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    label: 'Change Password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen()),
                      );
                    },
                    backgroundColor: kPrimaryColor.withValues(alpha: .1),
                    textColor: kPrimaryColor,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    label: 'Logout',
                    onTap: _logout,
                    backgroundColor: Colors.red.withValues(alpha: .1),
                    textColor: Colors.red,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProfileCard() {
    final bool isAdmin = _user?.role.toLowerCase() == 'admin';
    final initials = _getInitials(_user!.name);
    final avatarGradient = _getGradientFromName(_user!.name);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: avatarGradient,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.transparent,
                    child: Text(
                      initials,
                      style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (isAdmin)
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: Colors.orangeAccent,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _user!.name,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              _user!.email,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Chip(
                  label: const Text('Admin'),
                  backgroundColor: kPrimaryColor.withValues(alpha: .1),
                  labelStyle: const TextStyle(
                      color: kPrimaryColor, fontWeight: FontWeight.bold),
                  side: BorderSide.none,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'plant_list_screen.dart';
import 'rms_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';

// The reference blue color
const kBlueColor = Color(0xFF0075B2);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  // Screen widgets for each tab
  final List<Widget> _tabs = [
    const PlantListScreen(),
    const RMSScreen(),
    const AlertsScreen(),
    const ProfileScreen(),
  ];

  // Titles for the AppBar corresponding to each tab
  final List<String> _titles = [
    "All Plants",
    "RMS Dashboard",
    "Alerts",
    "Profile",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the background color to white for all screens
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_titles[_index], style: const TextStyle(color: Colors.white)),
        backgroundColor: kBlueColor,
        elevation: 0,
      ),
      body: _tabs[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: kBlueColor,
        unselectedItemColor: Colors.grey[500],
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        elevation: 5,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "RMS"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none_outlined), label: "Alerts"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class TeslaBottomNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTab;
  const TeslaBottomNavBar({super.key, required this.index, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: index,
      type: BottomNavigationBarType.fixed,
      onTap: onTab,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "RMS"),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alerts"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class TicketsScreen extends StatelessWidget {
  final Map<String, dynamic>? plant;
  const TicketsScreen({Key? key, this.plant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final plantName = plant?['plantName'] ?? 'Plant';

    // TODO: Replace with real API call for tickets when available.
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          "Tickets for $plantName will be shown here.",
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/alert_card.dart'; // Import the new AlertCard

const kBlueColor = Color(0xFF0075B2);

class AlertsScreen extends StatefulWidget {
  // Add the plant parameter that can be passed to this screen
  final Map<String, dynamic>? plant;

  const AlertsScreen({Key? key, this.plant}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  Future<List<Map<String, dynamic>>>? _alertsFuture;
  String _searchQuery = '';

  // Default plant data (used if no plant is passed to the screen)
  final String _defaultPlantId = "682b22b083afe84c2a8e9cb6";
  final String _defaultPlantName = "liluah";

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  void _fetchAlerts() {
    // Use the passed plant data if available, otherwise fall back to the default.
    final plantId = widget.plant?['id'] ?? widget.plant?['plantId'] ?? _defaultPlantId;
    final plantName = widget.plant?['plantName'] ?? _defaultPlantName;

    setState(() {
      _alertsFuture = ApiService.fetchAlerts(
        plantId: plantId,
        plantName: plantName,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search by device name or status...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _alertsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kBlueColor));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red)));
                }
                final allAlerts = snapshot.data ?? [];
                if (allAlerts.isEmpty) {
                  return const Center(child: Text("No alerts found."));
                }

                // Filter alerts based on search query
                final filteredAlerts = allAlerts.where((alert) {
                  final name = (alert['name'] as String?)?.toLowerCase() ?? '';
                  final status = (alert['status'] as String?)?.toLowerCase() ?? '';
                  final query = _searchQuery.toLowerCase();
                  return name.contains(query) || status.contains(query);
                }).toList();

                if (filteredAlerts.isEmpty) {
                  return const Center(child: Text("No matching alerts found."));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredAlerts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, idx) {
                    return AlertCard(alert: filteredAlerts[idx]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

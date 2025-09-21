import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/alert_card.dart';
import '../theme.dart';

class AlertsScreen extends StatefulWidget {
  final Map<String, dynamic>? plant;

  const AlertsScreen({Key? key, this.plant}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  Future<List<Map<String, dynamic>>>? _alertsFuture;
  String _searchQuery = '';

  final String _defaultPlantId = "682b22b083afe84c2a8e9cb6";
  final String _defaultPlantName = "liluah";

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  void _fetchAlerts() {
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
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: const Text("Alerts"),
              pinned: true,
              floating: true,
              forceElevated: innerBoxIsScrolled,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: const InputDecoration(
                      hintText: "Search by device or status...",
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            )
          ],
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _alertsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              }
              final allAlerts = snapshot.data ?? [];
              if (allAlerts.isEmpty) {
                return const Center(child: Text("No alerts found."));
              }

              final filteredAlerts = allAlerts.where((alert) {
                final name = (alert['name'] as String?)?.toLowerCase() ?? '';
                final status = (alert['status'] as String?)?.toLowerCase() ?? '';
                final query = _searchQuery.toLowerCase();
                return name.contains(query) || status.contains(query);
              }).toList();

              if (filteredAlerts.isEmpty) {
                return const Center(child: Text("No matching alerts found."));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredAlerts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  return AlertCard(alert: filteredAlerts[idx]);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

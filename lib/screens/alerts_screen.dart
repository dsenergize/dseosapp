import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/alert_card.dart';
import '../widgets/date_selector.dart';
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
  DateTime _selectedDate = DateTime.now();

  // Default plant data (used if no plant is passed to the screen)
  final String _defaultPlantId = "682b22b083afe84c2a8e9cb6";
  final String _defaultPlantName = "liluah";

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  void _fetchAlerts() {
    final plantId =
        widget.plant?['id'] ?? widget.plant?['plantId'] ?? _defaultPlantId;
    final plantName = widget.plant?['plantName'] ?? _defaultPlantName;

    setState(() {
      _alertsFuture = ApiService.fetchAlerts(
        plantId: plantId,
        plantName: plantName,
        date: _selectedDate,
      );
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _fetchAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.white,
        child: const Icon(Icons.menu, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                "Alerts",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 150,
                    child: DateSelector(
                      selectedDate: _selectedDate,
                      onDateSelected: _onDateSelected,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _alertsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child:
                          CircularProgressIndicator(color: kPrimaryColor));
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

                    final filteredAlerts = allAlerts.where((alert) {
                      final name =
                          (alert['name'] as String?)?.toLowerCase() ?? '';
                      final status =
                          (alert['status'] as String?)?.toLowerCase() ?? '';
                      final query = _searchQuery.toLowerCase();
                      return name.contains(query) || status.contains(query);
                    }).toList();

                    if (filteredAlerts.isEmpty) {
                      return const Center(
                          child: Text("No matching alerts found."));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: filteredAlerts.length,
                      separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        return AlertCard(alert: filteredAlerts[idx]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
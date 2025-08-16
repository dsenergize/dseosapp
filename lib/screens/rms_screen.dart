import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/rms_stat_card.dart';

const kBlueColor = Color(0xFF0075B2);

class RMSScreen extends StatefulWidget {
  const RMSScreen({super.key});
  @override
  State<RMSScreen> createState() => _RMSScreenState();
}

class _RMSScreenState extends State<RMSScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Map<String, dynamic>? _selectedPlant;

  Future<Map<String, dynamic>>? _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        setState(() {
          _isSearching = true;
        });
        ApiService.fetchPlants(searchQuery: _searchController.text).then((results) {
          if (mounted) {
            setState(() {
              _searchResults = results;
              _isSearching = false;
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _isSearching = false;
            });
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  void _selectPlant(Map<String, dynamic> plant) {
    setState(() {
      _selectedPlant = plant;
      _searchController.text = plant['plantName'] ?? '';
      _searchResults = [];
      _dashboardFuture = ApiService.fetchRmsDashboard(
        plantId: plant['id'],
        plantName: plant['plantName'],
        date: DateTime.now(),
      );
      FocusScope.of(context).unfocus(); // Hide keyboard
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack( // Use a Stack to overlay search results
        children: [
          // Main content (dashboard grid)
          Column(
            children: [
              const SizedBox(height: 88), // Space for the search bar
              Expanded(
                child: _buildDashboardContent(),
              ),
            ],
          ),
          // Search bar and results overlay
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: "Search Plants...",
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: kBlueColor, // Blue background for search bar
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              if (_isSearching) const LinearProgressIndicator(color: kBlueColor),
              // Conditionally display the search results dropdown
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: const BoxConstraints(maxHeight: 200), // Limit dropdown height
                  decoration: BoxDecoration(
                    color: kBlueColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final plant = _searchResults[index];
                      return ListTile(
                        title: Text(plant['plantName'] ?? 'N/A', style: const TextStyle(color: Colors.white)),
                        onTap: () => _selectPlant(plant),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_dashboardFuture == null) {
      return _buildDummyDashboard();
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kBlueColor));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No data found for this plant.", style: TextStyle(color: Colors.grey)));
        }

        final data = snapshot.data!;
        final stats = _mapApiDataToStats(data);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, idx) {
            final s = stats[idx];
            return RmsCard(
              title: s['title']!,
              value: s['value']!,
              unit: s['unit']!,
              iconData: s['icon']!,
              iconBgColor: s['color']!,
            );
          },
        );
      },
    );
  }

  Widget _buildDummyDashboard() {
    final dummyStats = _getDummyStats();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dummyStats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, idx) {
        final s = dummyStats[idx];
        return RmsCard(
          title: s['title']!,
          value: s['value']!,
          unit: s['unit']!,
          iconData: s['icon']!,
          iconBgColor: s['color']!,
        );
      },
    );
  }

  List<Map<String, dynamic>> _getDummyStats() {
    return [
      {"title": "Inverter Energy", "value": "N/A", "unit": "kWh", "icon": Icons.energy_savings_leaf, "color": Colors.green},
      {"title": "Plant PR", "value": "N/A", "unit": "%", "icon": Icons.show_chart, "color": Colors.blue},
      {"title": "Daily Export", "value": "N/A", "unit": "W/m²", "icon": Icons.wb_sunny, "color": Colors.purple},
      {"title": "Peak Power", "value": "N/A", "unit": "kW", "icon": Icons.bolt, "color": Colors.orange},
    ];
  }

  List<Map<String, dynamic>> _mapApiDataToStats(Map<String, dynamic> data) {
    String formatValue(dynamic value, {int precision = 2}) {
      if (value == null) return 'N/A';
      if (value is num) return value.toStringAsFixed(precision);
      return value.toString();
    }

    return [
      {"title": "Inverter Energy", "value": formatValue(data['totalDailyEnergy']), "unit": "kWh", "icon": Icons.energy_savings_leaf, "color": Colors.green},
      {"title": "Plant PR", "value": formatValue(data['dayPR']), "unit": "%", "icon": Icons.show_chart, "color": Colors.blue},
      {"title": "Daily Export", "value": formatValue(data['Peak_POA_Radiation']), "unit": "W/m²", "icon": Icons.wb_sunny, "color": Colors.purple},
      {"title": "Peak Power", "value": formatValue(data['dcCapacity']), "unit": "kW", "icon": Icons.bolt, "color": Colors.orange},
    ];
  }
}

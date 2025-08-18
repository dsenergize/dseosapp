import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/rms_stat_card.dart';
import 'rms_dashboard_screen.dart'; // Import the destination screen

const kBlueColor = Color(0xFF0075B2);

class RMSScreen extends StatefulWidget {
  const RMSScreen({super.key});
  @override
  State<RMSScreen> createState() => _RMSScreenState();
}

class _RMSScreenState extends State<RMSScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  List<Map<String, dynamic>> _allPlants = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoadingAllPlants = true;
  bool _isSearching = false;
  bool _showDropdown = false;

  Map<String, dynamic>? _selectedPlant;
  Future<Map<String, dynamic>>? _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _fetchAllPlants();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChange);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchAllPlants() async {
    try {
      final plants = await ApiService.fetchPlants();
      if (mounted) {
        setState(() {
          _allPlants = plants;
          _isLoadingAllPlants = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAllPlants = false;
        });
      }
    }
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      setState(() {
        _searchResults = _allPlants;
        _showDropdown = true;
      });
    } else if (!_searchFocusNode.hasFocus) {
      setState(() {
        _showDropdown = false;
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text;
      if (query.isNotEmpty) {
        setState(() {
          _isSearching = true;
          _showDropdown = true;
        });
        ApiService.fetchPlants(searchQuery: query).then((results) {
          if (mounted) {
            setState(() {
              _searchResults = results;
              _isSearching = false;
            });
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _searchResults = _allPlants;
            _isSearching = false;
            _showDropdown = _searchFocusNode.hasFocus;
          });
        }
      }
    });
  }

  void _selectPlant(Map<String, dynamic> plant) {
    // THE FIX: Temporarily remove the listener to prevent the search from re-triggering.
    _searchController.removeListener(_onSearchChanged);

    setState(() {
      _selectedPlant = plant;
      _searchController.text = plant['plantName'] ?? '';
      _showDropdown = false;
      _searchResults = [];
      _dashboardFuture = ApiService.fetchRmsDashboard(
        plantId: plant['id'],
        plantName: plant['plantName'],
        date: DateTime.now(),
      );
      FocusScope.of(context).unfocus();
    });

    // Add the listener back after the UI has updated.
    _searchController.addListener(_onSearchChanged);
  }

  void _navigateToDashboard() {
    if (_selectedPlant != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RMSDashboardScreen(
            plantId: _selectedPlant!['id'],
            plantName: _selectedPlant!['plantName'],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // The main background is now blue
    return Scaffold(
      backgroundColor: kBlueColor,
      body: Stack(
        children: [
          // The dashboard content is now pushed down
          Padding(
            padding: const EdgeInsets.only(top: 88.0),
            child: Container(
              // With a white background that has rounded top corners
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: _buildDashboardContent(),
            ),
          ),
          // Search bar and dropdown overlay
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: "Search Plants...",
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15), // Adjusted color
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              if (_isSearching) const LinearProgressIndicator(color: kBlueColor),
              if (_showDropdown && (_searchResults.isNotEmpty || _isLoadingAllPlants))
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isLoadingAllPlants
                      ? const Center(child: CircularProgressIndicator(color: kBlueColor))
                      : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final plant = _searchResults[index];
                      return ListTile(
                        title: Text(plant['plantName'] ?? 'N/A'),
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
            return GestureDetector(
              onTap: _navigateToDashboard,
              child: RmsCard(
                title: s['title']!,
                value: s['value']!,
                unit: s['unit']!,
                iconData: s['icon']!,
                iconBgColor: s['color']!,
              ),
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

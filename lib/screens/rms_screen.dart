import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/rms_stat_card.dart';
import '../theme.dart';

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
      if (!mounted) return;
      if (_searchController.text.isNotEmpty) {
        setState(() => _isSearching = true);
        ApiService.fetchPlants(searchQuery: _searchController.text)
            .then((results) {
          if (mounted) setState(() => _searchResults = results);
        }).catchError((_) {
          // Handle error if needed
        }).whenComplete(() {
          if (mounted) setState(() => _isSearching = false);
        });
      } else {
        setState(() {
          _searchResults = [];
          if (_selectedPlant != null) {
            _selectedPlant = null;
            _dashboardFuture = null;
          }
        });
      }
    });
  }

  void _selectPlant(Map<String, dynamic> plant) {
    setState(() {
      _selectedPlant = plant;
      _searchController.text = plant['plantName'] ?? '';
      _searchResults = [];
      _dashboardFuture = ApiService.fetchRmsDashboard(
        plantId: plant['id']?.toString() ?? plant['plantId']?.toString(),
        plantName: plant['plantName'],
        date: DateTime.now(),
      );
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("RMS Dashboard",
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              _buildSearchField(),
              if (_isSearching) const LinearProgressIndicator(color: kPrimaryColor),
              if (_searchResults.isNotEmpty)
                _buildSearchResults(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: _buildDashboardContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Search Plants...",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _isSearching
            ? const Padding(
            padding: EdgeInsets.all(12.0),
            child: CircularProgressIndicator(strokeWidth: 2))
            : null,
      ),
    );
  }

  Widget _buildSearchResults() {
    return Expanded(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(top: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListView.builder(
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
    );
  }

  Widget _buildDashboardContent() {
    final future = _dashboardFuture;
    if (future == null) {
      return _buildDummyDashboard();
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text("Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text("No data found for this plant.",
                  style: TextStyle(color: kTextSecondaryColor)));
        }

        final data = snapshot.data!;
        final stats = _mapApiDataToStats(data);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: stats.length,
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: dummyStats.length,
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
      {
        "title": "Inverter Energy",
        "value": "N/A",
        "unit": "kWh",
        "icon": Icons.energy_savings_leaf_outlined,
        "color": Colors.green
      },
      {
        "title": "Plant PR",
        "value": "N/A",
        "unit": "%",
        "icon": Icons.show_chart_rounded,
        "color": Colors.blue
      },
      {
        "title": "Daily Export",
        "value": "N/A",
        "unit": "W/m²",
        "icon": Icons.wb_sunny_outlined,
        "color": Colors.purple
      },
      {
        "title": "Peak Power",
        "value": "N/A",
        "unit": "kW",
        "icon": Icons.flash_on_rounded,
        "color": Colors.orange
      },
    ];
  }

  List<Map<String, dynamic>> _mapApiDataToStats(Map<String, dynamic> data) {
    String formatValue(dynamic value, {int precision = 2}) {
      if (value == null) return 'N/A';
      if (value is num) return value.toStringAsFixed(precision);
      return value.toString();
    }

    return [
      {
        "title": "Inverter Energy",
        "value": formatValue(data['totalDailyEnergy']),
        "unit": "kWh",
        "icon": Icons.energy_savings_leaf_outlined,
        "color": Colors.green
      },
      {
        "title": "Plant PR",
        "value": formatValue(data['dayPR']),
        "unit": "%",
        "icon": Icons.show_chart_rounded,
        "color": Colors.blue
      },
      {
        "title": "Daily Export",
        "value": formatValue(data['Peak_POA_Radiation']),
        "unit": "W/m²",
        "icon": Icons.wb_sunny_outlined,
        "color": Colors.purple
      },
      {
        "title": "Peak Power",
        "value": formatValue(data['dcCapacity']),
        "unit": "kW",
        "icon": Icons.flash_on_rounded,
        "color": Colors.orange
      },
    ];
  }
}
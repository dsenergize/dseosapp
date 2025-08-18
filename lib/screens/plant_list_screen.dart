import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/plant_card.dart';
import 'plant_info_screen.dart';

const kBlueColor = Color(0xFF0075B2);

class PlantListScreen extends StatefulWidget {
  const PlantListScreen({super.key});

  @override
  State<PlantListScreen> createState() => _PlantListScreenState();
}

class _PlantListScreenState extends State<PlantListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allPlants = [];
  List<Map<String, dynamic>> _filteredPlants = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchPlants();
    _searchController.addListener(_filterPlants);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPlants);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlants() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final plants = await ApiService.fetchPlants();
      if (mounted) {
        setState(() {
          _allPlants = plants;
          _filteredPlants = plants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _filterPlants() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPlants = _allPlants.where((plant) {
        final plantName = (plant['plantName'] as String?)?.toLowerCase() ?? '';
        return plantName.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlueColor,
      body: RefreshIndicator(
        onRefresh: _fetchPlants,
        color: kBlueColor,
        child: Column(
          children: [
            // Search Bar
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
                  fillColor: Colors.white.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            // Plant List Area
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kBlueColor));
    }

    if (_hasError) {
      return _buildOfflineUI();
    }

    if (_filteredPlants.isEmpty) {
      return const Center(child: Text("No plants found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12.0, 24.0, 12.0, 12.0), // Added top padding
      itemCount: _filteredPlants.length,
      itemBuilder: (context, index) {
        final plant = _filteredPlants[index];
        final String name = plant['plantName'] ?? 'Unnamed Plant';
        final String capacity = plant['dcCapacity']?.toString() ?? '-';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: PlantCard(
            plantName: name,
            capacity: capacity,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlantInfoScreen(plant: plant),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Widget for displaying the offline state
  Widget _buildOfflineUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, color: Colors.grey[400], size: 48),
          const SizedBox(height: 16),
          const Text(
            "You are offline",
            style: TextStyle(color: Colors.black54, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Pull down to refresh",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

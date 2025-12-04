import 'dart:convert';
import 'package:dseos/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/plant_card.dart';
import 'plant_info_screen.dart';
import '../theme.dart';

class PlantListScreen extends StatefulWidget {
  const PlantListScreen({super.key});

  @override
  State<PlantListScreen> createState() => _PlantListScreenState();
}

class _PlantListScreenState extends State<PlantListScreen> {
  late Future<List<Map<String, dynamic>>> _plantsFuture;
  UserModel? _user;
  String _selectedFilter = 'All Plants';
  final List<String> _filters = ['All Plants', 'Rooftop', 'Ground Mount'];

  @override
  void initState() {
    super.initState();
    _plantsFuture = ApiService.fetchPlants();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null && mounted) {
      setState(() {
        _user = UserModel.fromJson(jsonDecode(userData));
      });
    }
  }

  // Helper function to filter plants locally
  List<Map<String, dynamic>> _filterPlants(
      List<Map<String, dynamic>> plants) {
    if (_selectedFilter == 'All Plants') {
      return plants;
    }
    return plants
        .where((plant) =>
    plant['projectType']?.toString().toLowerCase() ==
        _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _plantsFuture = ApiService.fetchPlants();
            });
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _plantsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(
                            child:
                            CircularProgressIndicator(color: kPrimaryColor)),
                      );
                    }
                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                            child: Text("Error: ${snapshot.error}",
                                style: const TextStyle(color: Colors.red))),
                      );
                    }
                    final allPlants = snapshot.data ?? [];
                    final filteredPlants = _filterPlants(allPlants);

                    if (filteredPlants.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(child: Text("No plants found")),
                      );
                    }
                    return SliverGrid(
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final plant = filteredPlants[index];
                          final String name =
                              plant['plantName'] ?? 'Unnamed Plant';
                          final String capacity =
                              plant['dcCapacity']?.toString() ?? '-';
                          return PlantCard(
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
                          );
                        },
                        childCount: filteredPlants.length,
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hey, ${_user?.name ?? ''}",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Welcome back to your dashboard",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(
                    'https://placehold.co/100x100/29B583/FFFFFF?text=${_user?.name.isNotEmpty == true ? _user!.name[0] : ''}'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filters
                  .map((filter) => _buildFilterChip(
                  filter, _selectedFilter == filter))
                  .toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        backgroundColor: isSelected ? kPrimaryColor : Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : kTextColor,
          fontWeight: FontWeight.w600,
        ),
        onPressed: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        side: BorderSide(
            color: isSelected ? kPrimaryColor : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
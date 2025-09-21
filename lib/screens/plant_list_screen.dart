import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _plantsFuture = ApiService.fetchPlants();
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
                        child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
                      );
                    }
                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red))),
                      );
                    }
                    final plants = snapshot.data ?? [];
                    if (plants.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(child: Text("No plants found")),
                      );
                    }
                    return SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final plant = plants[index];
                          final String name = plant['plantName'] ?? 'Unnamed Plant';
                          final String capacity = plant['dcCapacity']?.toString() ?? '-';
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
                        childCount: plants.length,
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
                    "Hey, Alex Smith", // Placeholder name
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Welcome back to your dashboard",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage('https://placehold.co/100x100/29B583/FFFFFF?text=A'), // Placeholder
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Placeholder for filter buttons
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip("All Plants", true),
                _buildFilterChip("Rooftop", false),
                _buildFilterChip("Ground Mount", false),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected ? kPrimaryColor : Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : kTextColor,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: isSelected ? kPrimaryColor : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

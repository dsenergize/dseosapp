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
  late Future<List<Map<String, dynamic>>> _plantsFuture;

  @override
  void initState() {
    super.initState();
    _plantsFuture = ApiService.fetchPlants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar has been REMOVED.
      // The background color is now set to blue for this screen only.
      backgroundColor: kBlueColor,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _plantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }
          final plants = snapshot.data ?? [];
          if (plants.isEmpty) {
            return const Center(child: Text("No plants found", style: TextStyle(color: Colors.white)));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: plants.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
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
            ),
          );
        },
      ),
    );
  }
}

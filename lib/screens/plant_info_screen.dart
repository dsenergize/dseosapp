import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'rms_dashboard_screen.dart';
import 'tickets_screen.dart';
import 'alerts_screen.dart';

const kBlueColor = Color(0xFF0075B2);

class PlantInfoScreen extends StatelessWidget {
  final Map<String, dynamic> plant;
  const PlantInfoScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final plantName = plant['plantName'] ?? 'Unknown';
    final dcCapacity = plant['dcCapacity']?.toString() ?? '---';
    final mountType = plant['projectType'] ?? '---';
    final moduleType = plant['modules']?.toString() ?? '---';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: kBlueColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(plantName, style: const TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Plant Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
            decoration: BoxDecoration(
              color: kBlueColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Sun Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.wb_sunny,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 18),
                // Plant Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plantName,
                        style: GoogleFonts.roboto(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Power: $dcCapacity kW (DC)",
                        style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Mount type: $mountType",
                        style: GoogleFonts.roboto(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Modules: $moduleType",
                        style: GoogleFonts.roboto(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Navigation List Tiles
          _buildInfoTile(
            context,
            title: "RMS Dashboard",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RMSDashboardScreen(
                    plantId: plant['id'] ?? plant['plantId'],
                    plantName: plantName,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          _buildInfoTile(
            context,
            title: "Tickets",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketsScreen(plant: plant),
                ),
              );
            },
          ),
          const Divider(),
          _buildInfoTile(
            context,
            title: "Alerts",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlertsScreen(plant: plant),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper widget for consistent list tile styling
  Widget _buildInfoTile(BuildContext context, {required String title, required VoidCallback onTap}) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }
}

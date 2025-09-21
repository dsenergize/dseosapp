import 'package:flutter/material.dart';
import 'rms_dashboard_screen.dart';
import 'tickets_screen.dart';
import 'alerts_screen.dart';
import '../theme.dart';
import '../widgets/info_card.dart';

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
      appBar: AppBar(
        title: Text(plantName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Plant Summary Card
          _buildSummaryCard(context, plantName),
          const SizedBox(height: 24),
          // Key details grid
          _buildDetailsGrid(dcCapacity, mountType, moduleType),
          const SizedBox(height: 24),

          Text("Dashboards & Reports", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),

          // Navigation List Tiles
          _buildInfoTile(
            context,
            title: "RMS Dashboard",
            subtitle: "View real-time performance",
            icon: Icons.show_chart_rounded,
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
          _buildInfoTile(
            context,
            title: "Tickets",
            subtitle: "Manage maintenance tickets",
            icon: Icons.confirmation_number_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketsScreen(plant: plant),
                ),
              );
            },
          ),
          _buildInfoTile(
            context,
            title: "Alerts",
            subtitle: "Check device and system alerts",
            icon: Icons.notifications_none_outlined,
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

  Widget _buildSummaryCard(BuildContext context, String plantName) {
    return Card(
      color: kPrimaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: kPrimaryColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.wb_sunny_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Plant Details",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plantName,
                    style: Theme.of(context).textTheme.headlineSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsGrid(String dcCapacity, String mountType, String moduleType) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2, // Adjust aspect ratio to give cards more height
      children: [
        InfoCard(
          title: 'DC Capacity',
          value: dcCapacity,
          unit: 'kW',
          icon: Icons.electrical_services_outlined,
          iconBgColor: Colors.purple,
        ),
        InfoCard(
          title: 'Mount Type',
          value: mountType,
          unit: '',
          icon: Icons.layers_outlined,
          iconBgColor: Colors.blue,
        ),
        InfoCard(
          title: 'Modules',
          value: moduleType,
          unit: '',
          icon: Icons.grid_view_outlined,
          iconBgColor: Colors.teal,
        ),
      ],
    );
  }


  // Helper widget for consistent list tile styling
  Widget _buildInfoTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kPrimaryColor),
        ),
        title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
        ),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: kTextSecondaryColor),
        onTap: onTap,
      ),
    );
  }
}


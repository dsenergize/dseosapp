//
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'rms_dashboard_screen.dart';
// import 'tickets_screen.dart';
// import 'alerts_screen.dart';
// import 'plant_level_data_screen.dart';
// import 'inverter_level_data_screen.dart';
// import 'weather_station_data_screen.dart';
// import 'device_status_screen.dart';
// import 'meter_level_data_screen.dart';
// import '../theme.dart';
//
// class PlantInfoScreen extends StatelessWidget {
//   final Map<String, dynamic> plant;
//   const PlantInfoScreen({super.key, required this.plant});
//
//   @override
//   Widget build(BuildContext context) {
//     // Normalize the plant data to ensure a consistent 'id' key is available.
//     final normalizedPlant = Map<String, dynamic>.from(plant);
//     if (normalizedPlant['id'] == null && normalizedPlant['plantId'] != null) {
//       normalizedPlant['id'] = normalizedPlant['plantId']?.toString().trim();
//     }
//
//     final plantName = normalizedPlant['plantName'] ?? 'Unknown';
//     final plantId = normalizedPlant['id']?.toString() ?? '';
//     final dcCapacity = normalizedPlant['dcCapacity']?.toString() ?? '---';
//     final mountType = normalizedPlant['projectType'] ?? '---';
//     final moduleType = normalizedPlant['modules']?.toString() ?? '---';
//
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: kPrimaryColor,
//         elevation: 1,
//         title: Text(plantName),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           // Plant Summary Card
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
//             decoration: BoxDecoration(
//               color: kPrimaryColor,
//               borderRadius: BorderRadius.circular(16),
//               gradient: const LinearGradient(
//                 colors: [kPrimaryColor, Color(0xFF005A8D)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.orange[300],
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Icon(
//                     Icons.wb_sunny,
//                     color: Colors.white,
//                     size: 32,
//                   ),
//                 ),
//                 const SizedBox(width: 18),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         plantName,
//                         style: GoogleFonts.roboto(
//                             color: Colors.white,
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         "Power: $dcCapacity kW (DC)",
//                         style: GoogleFonts.roboto(
//                             color: Colors.white, fontSize: 16),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         "Mount type: $mountType",
//                         style: GoogleFonts.roboto(
//                             color: Colors.white70, fontSize: 14),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         "Modules: $moduleType",
//                         style: GoogleFonts.roboto(
//                             color: Colors.white70, fontSize: 14),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 32),
//           // Navigation List Tiles
//           Card(
//             elevation: 2,
//             shape:
//             RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             child: Column(
//               children: [
//                 _buildInfoTile(
//                   context,
//                   title: "RMS Dashboard",
//                   icon: Icons.show_chart_rounded,
//                   onTap: () {
//                     if (plantId.isEmpty) return;
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => RMSDashboardScreen(
//                           plantId: plantId,
//                           plantName: plantName,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//                 const Divider(height: 1, indent: 16, endIndent: 16),
//                 _buildInfoTile(
//                   context,
//                   title: "Plant Level Data",
//                   icon: Icons.layers_outlined,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => PlantLevelDataScreen(plant: normalizedPlant),
//                       ),
//                     );
//                   },
//                 ),
//                 const Divider(height: 1, indent: 16, endIndent: 16),
//                 _buildInfoTile(
//                   context,
//                   title: "Inverter Level Data",
//                   icon: Icons.solar_power_outlined,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => InverterLevelDataScreen(plant: normalizedPlant),
//                       ),
//                     );
//                   },
//                 ),
//                 const Divider(height: 1, indent: 16, endIndent: 16),
//                 _buildInfoTile(
//                   context,
//                   title: "Meter Data",
//                   icon: Icons.speed_outlined,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => MeterDataScreen(plant: normalizedPlant),
//                       ),
//                     );
//                   },
//                 ),
//                 const Divider(height: 1, indent: 16, endIndent: 16),
//                 _buildInfoTile(
//                   context,
//                   title: "Weather Station Data",
//                   icon: Icons.cloud_outlined,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => WeatherStationDataScreen(plant: normalizedPlant),
//                       ),
//                     );
//                   },
//                 ),
//                 const Divider(height: 1, indent: 16, endIndent: 16),
//                 _buildInfoTile(
//                   context,
//                   title: "Device Status",
//                   icon: Icons.developer_board,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => DeviceStatusScreen(plant: normalizedPlant),
//                       ),
//                     );
//                   },
//                 ),
//                 const Divider(height: 1, indent: 16, endIndent: 16),
//                 _buildInfoTile(
//                   context,
//                   title: "Tickets",
//                   icon: Icons.article_outlined,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => TicketsScreen(plant: normalizedPlant),
//                       ),
//                     );
//                   },
//                 ),
//                 const Divider(height: 1, indent: 16, endIndent: 16),
//                 _buildInfoTile(
//                   context,
//                   title: "Alerts",
//                   icon: Icons.notifications_none_outlined,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => AlertsScreen(plant: normalizedPlant),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Helper widget for consistent list tile styling
//   Widget _buildInfoTile(BuildContext context,
//       {required String title,
//         required IconData icon,
//         required VoidCallback onTap}) {
//     return ListTile(
//       leading: Icon(icon, color: kPrimaryColor),
//       title: Text(
//         title,
//         style: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 16),
//       ),
//       trailing:
//       const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
//       onTap: onTap,
//     );
//   }
// }
//
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'rms_dashboard_screen.dart';
import 'tickets_screen.dart';
import 'alerts_screen.dart';
import 'plant_level_data_screen.dart';
import 'inverter_level_data_screen.dart';
import 'weather_station_data_screen.dart';
import 'device_status_screen.dart';
import 'meter_level_data_screen.dart'; // Corrected import
import '../theme.dart';

class PlantInfoScreen extends StatelessWidget {
  final Map<String, dynamic> plant;
  const PlantInfoScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    // Normalize the plant data to ensure a consistent 'id' key is available.
    final normalizedPlant = Map<String, dynamic>.from(plant);
    if (normalizedPlant['id'] == null && normalizedPlant['plantId'] != null) {
      normalizedPlant['id'] = normalizedPlant['plantId']?.toString().trim();
    }

    final plantName = normalizedPlant['plantName'] ?? 'Unknown';
    final plantId = normalizedPlant['id']?.toString() ?? '';
    final dcCapacity = normalizedPlant['dcCapacity']?.toString() ?? '---';
    final mountType = normalizedPlant['projectType'] ?? '---';
    final moduleType = normalizedPlant['modules']?.toString() ?? '---';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryColor,
        elevation: 1,
        title: Text(plantName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Plant Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [kPrimaryColor, Color(0xFF005A8D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plantName,
                        style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Power: $dcCapacity kW (DC)",
                        style: GoogleFonts.roboto(
                            color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Mount type: $mountType",
                        style: GoogleFonts.roboto(
                            color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Modules: $moduleType",
                        style: GoogleFonts.roboto(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Navigation List Tiles
          Card(
            elevation: 2,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildInfoTile(
                  context,
                  title: "RMS Dashboard",
                  icon: Icons.show_chart_rounded,
                  onTap: () {
                    if (plantId.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RMSDashboardScreen(
                          plantId: plantId,
                          plantName: plantName,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildInfoTile(
                  context,
                  title: "Plant Level Data",
                  icon: Icons.layers_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlantLevelDataScreen(plant: normalizedPlant),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildInfoTile(
                  context,
                  title: "Inverter Level Data",
                  icon: Icons.solar_power_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InverterLevelDataScreen(plant: normalizedPlant),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildInfoTile(
                  context,
                  title: "Meter Data",
                  icon: Icons.speed_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MeterDataScreen(plant: normalizedPlant),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildInfoTile(
                  context,
                  title: "Weather Station Data",
                  icon: Icons.cloud_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WeatherStationDataScreen(plant: normalizedPlant),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildInfoTile(
                  context,
                  title: "Device Status",
                  icon: Icons.developer_board,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeviceStatusScreen(plant: normalizedPlant),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildInfoTile(
                  context,
                  title: "Tickets",
                  icon: Icons.article_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketsScreen(plant: normalizedPlant),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildInfoTile(
                  context,
                  title: "Alerts",
                  icon: Icons.notifications_none_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlertsScreen(plant: normalizedPlant),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for consistent list tile styling
  Widget _buildInfoTile(BuildContext context,
      {required String title,
        required IconData icon,
        required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: kPrimaryColor),
      title: Text(
        title,
        style: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing:
      const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }
}


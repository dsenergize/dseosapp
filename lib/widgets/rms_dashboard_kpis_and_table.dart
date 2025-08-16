// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'info_card.dart';
// import 'rms_dashboard_table.dart';
//
// class RmsDashboardKpisAndTable extends StatelessWidget {
//   final Map<String, dynamic> data;
//
//   const RmsDashboardKpisAndTable({Key? key, required this.data}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     // Helper function to safely parse numbers
//     num? safeParseNum(dynamic value) {
//       if (value is num) return value;
//       if (value is String) return num.tryParse(value);
//       return null;
//     }
//
//     // Safely get values from the data map
//     final totalDailyEnergy = safeParseNum(data['totalDailyEnergy']);
//     final dayPR = safeParseNum(data['dayPR']);
//     final peakPOARadiation = safeParseNum(data['Peak_POA_Radiation']);
//
//     return Column(
//       children: [
//         GridView.count(
//           crossAxisCount: 3,
//           crossAxisSpacing: 10,
//           mainAxisSpacing: 10,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           childAspectRatio: 1.2,
//           children: [
//             InfoCard(
//               title: 'Total Daily Energy',
//               value: totalDailyEnergy,
//               unit: 'kWh',
//               icon: Icons.energy_savings_leaf,
//               iconBgColor: Colors.green,
//             ),
//             InfoCard(
//               title: 'Day PR(%)',
//               value: dayPR != null ? (dayPR * 100).toStringAsFixed(2) : null,
//               unit: '%',
//               icon: Icons.bolt,
//               iconBgColor: Colors.blue,
//             ),
//             InfoCard(
//               title: 'Peak POA Radiation',
//               value: peakPOARadiation,
//               unit: 'W/m²',
//               icon: Icons.wb_sunny,
//               iconBgColor: Colors.orange,
//             ),
//           ],
//         ),
//         const SizedBox(height: 24),
//         RmsDashboardTable(data: data),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'info_card.dart';
import 'rms_dashboard_table.dart';

class RmsDashboardKpisAndTable extends StatelessWidget {
  final Map<String, dynamic> data;

  const RmsDashboardKpisAndTable({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Helper function to safely parse numbers
    num? safeParseNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value);
      return null;
    }

    // Safely get values from the data map
    final totalDailyEnergy = safeParseNum(data['totalDailyEnergy']);
    final dayPR = safeParseNum(data['dayPR']);
    final peakPOARadiation = safeParseNum(data['Peak_POA_Radiation']);

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            InfoCard(
              title: 'Total Daily Energy',
              value: totalDailyEnergy,
              unit: 'kWh',
              icon: Icons.energy_savings_leaf,
              // Added green background color to match screenshot
              iconBgColor: Colors.green,
            ),
            InfoCard(
              title: 'Day PR(%)',
              value: dayPR,
              unit: '%',
              icon: Icons.bolt,
              // Added blue background color to match screenshot
              iconBgColor: Colors.blue,
            ),
            InfoCard(
              title: 'Peak POA Radiation',
              value: peakPOARadiation,
              unit: 'W/m²',
              icon: Icons.wb_sunny,
              // Added orange background color to match screenshot
              iconBgColor: Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 24),
        RmsDashboardTable(data: data),
      ],
    );
  }
}

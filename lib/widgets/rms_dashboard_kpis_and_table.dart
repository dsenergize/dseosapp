import 'package:flutter/material.dart';
import 'info_card.dart';
import 'rms_dashboard_table.dart';

class RmsDashboardKpisAndTable extends StatelessWidget {
  final Map<String, dynamic> data;

  const RmsDashboardKpisAndTable({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Helper function to safely parse and format numbers
    String formatValue(dynamic value, {int precision = 2}) {
      if (value == null) return 'N/A';
      if (value is num) return value.toStringAsFixed(precision);
      return value.toString();
    }

    // Apply formatting factors to the data before passing to widgets
    final formattedData = {
      ...data,
      'dayPR': formatValue(data['dayPR']),
      // THE FIX: Applying the division factor to the temperature
      'avgmaxAmbientTemp': data['avgmaxAmbientTemp'] != null ? (data['avgmaxAmbientTemp'] / 10) : null,
    };


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
              value: formattedData['totalDailyEnergy'],
              unit: 'kWh',
              icon: Icons.energy_savings_leaf,
              iconBgColor: Colors.green,
            ),
            InfoCard(
              title: 'Day PR(%)',
              value: formattedData['dayPR'],
              unit: '%',
              icon: Icons.bolt,
              iconBgColor: Colors.blue,
            ),
            InfoCard(
              title: 'Peak POA Radiation',
              value: formattedData['Peak_POA_Radiation'],
              unit: 'W/m²',
              icon: Icons.wb_sunny,
              iconBgColor: Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Pass the correctly formatted data to the table
        RmsDashboardTable(data: formattedData),
      ],
    );
  }
}

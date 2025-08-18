import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RmsDashboardTable extends StatelessWidget {
  final Map<String, dynamic> data;

  const RmsDashboardTable({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine plant status
    final bool isPlantOn = (data['gtiLive'] ?? 0) > 0;

    // Map of display names to their corresponding API keys
    final Map<String, String> displayKeyMap = {
      'Inverter Energy': 'totalDailyEnergy',
      'Insolation': 'totalIrradiance',
      'Daily Export': 'totalDailyEnergy', // Assuming this is the same as Inverter Energy
      'Daily Import': 'dailyImport', // NOTE: Not available in API, will show N/A
      'Day PR(%)': 'dayPR',
      'Daily Yield': 'dailyYield',
      'DC CUF': 'dcCUF',
      'AC CUF': 'acCUF',
      'Peak Power': 'peakPower', // NOTE: Not available in API, will show N/A
      'Peak Insolation': 'Peak_Insolation',
      'Plant Start Time': 'plantStartTime',
      'Plant Stop Time': 'plantEndTime',
      'Avg. Module Temp': 'avgmaxModuleTemp',
      'Avg. Ambient Temp': 'avgmaxAmbientTemp',
      'GTI Avg': 'gtiAvg',
      'Live GTI': 'gtiLive',
      'Avg. Wind Speed': 'avgWind',
    };

    // Helper function to format the value based on the key
    String formatValue(String key, dynamic value) {
      if (value == null) return '--';
      final num? numericValue = value is num ? value : num.tryParse(value.toString());

      switch (key) {
        case 'Inverter Energy':
        case 'Daily Export':
          return '${numericValue?.toStringAsFixed(2) ?? value} kWh';
        case 'Insolation':
          return '${numericValue != null ? (numericValue / 1000).toStringAsFixed(2) : value} kWh/m²';
        case 'Day PR(%)':
        case 'DC CUF':
        case 'AC CUF':
          return '${numericValue?.toStringAsFixed(2) ?? value} %';
        case 'Peak Power':
          return '${numericValue?.toStringAsFixed(2) ?? value} kW';
        case 'Peak Insolation':
        case 'Live GTI':
          return '${numericValue?.toStringAsFixed(2) ?? value} W/m²';
        case 'Avg. Module Temp':
        case 'Avg. Ambient Temp':
          return '${numericValue?.toStringAsFixed(2) ?? value} °C';
        case 'GTI Avg':
          return '${numericValue?.toStringAsFixed(2) ?? value} kWh/m²';
        case 'Avg. Wind Speed':
          return '${numericValue?.toStringAsFixed(2) ?? value} m/s';
        default:
          return value.toString();
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status', style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey[600])),
                Text(
                  isPlantOn ? 'Plant On' : 'Plant Off',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPlantOn ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Data List
            ...displayKeyMap.entries.map((entry) {
              final displayName = entry.key;
              final apiKey = entry.value;
              final value = data[apiKey];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey[600]),
                    ),
                    Text(
                      formatValue(displayName, value),
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

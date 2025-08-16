import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RmsDashboardTable extends StatelessWidget {
  final Map<String, dynamic> data;

  const RmsDashboardTable({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Map of display names to their corresponding API keys
    final Map<String, String> displayKeyMap = {
      'Plant Name': 'plantName',
      'Date': 'date',
      'DC Capacity': 'dcCapacity',
      'AC Capacity': 'acCapacity',
      'Plant Start Time': 'plantStartTime',
      'Plant Stop Time': 'plantEndTime',
      'Total Daily Energy': 'totalDailyEnergy',
      'Total KWH': 'totalKWH',
      'Lifetime Energy': 'lifetimeEnergy',
      'Daily Yield': 'dailyYield',
      'Total Irradiance': 'totalIrradiance',
      'GTI Live': 'gtiLive',
      'GTI Avg': 'gtiAvg',
      'Peak Insolation': 'Peak_Insolation',
      'Peak POA Radiation': 'Peak_POA_Radiation',
      'Max Module Temp': 'maxModuleTemp',
      'Avg Max Module Temp': 'avgmaxModuleTemp',
      'Max Ambient Temp': 'maxAmbientTemp',
      'Avg Max Ambient Temp': 'avgmaxAmbientTemp',
      'Max Wind': 'maxWind',
      'Avg Wind': 'avgWind',
      'Day PR(%)': 'dayPR',
      'DC CUF': 'dcCUF',
      'AC CUF': 'acCUF',
      'Plant Load Factor': 'plantLoadFactor',
      'Is Today': 'isToday',
      'Inverters': 'inverters',
      'Energy Meters': 'energyMeters',
      'Weather Stations': 'weatherStations',
      'Irradiance Sensors': 'irradianceSensors',
    };

    // Helper function to format the value based on the key
    String formatValue(String key, dynamic value) {
      if (value == null) {
        return 'N/A';
      }
      // Attempt to parse value to a number for formatting
      final num? numericValue = value is num ? value : num.tryParse(value.toString());

      switch (key) {
        case 'Total Daily Energy':
        case 'Total KWH':
        case 'Lifetime Energy':
          return '${numericValue?.toStringAsFixed(2) ?? value} kWh';
        case 'Daily Yield':
          return '${numericValue?.toStringAsFixed(2) ?? value} kWh/m²';
        case 'Day PR(%)':
        case 'DC CUF':
        case 'AC CUF':
        case 'Plant Load Factor':
          return '${numericValue?.toStringAsFixed(2) ?? value} %';
        case 'Total Irradiance':
        case 'Peak Insolation':
        case 'Peak POA Radiation':
          return '${numericValue?.toStringAsFixed(2) ?? value} W/m²';
        case 'Max Module Temp':
        case 'Avg Max Module Temp':
        case 'Max Ambient Temp':
        case 'Avg Max Ambient Temp':
          return '${numericValue?.toStringAsFixed(2) ?? value} °C';
        case 'GTI Avg':
          return '${numericValue?.toStringAsFixed(2) ?? value} kWh/m²';
        case 'Avg Wind':
        case 'Max Wind':
          return '${numericValue?.toStringAsFixed(2) ?? value} m/s';
        default:
          return value.toString();
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: displayKeyMap.entries.map((entry) {
            final displayName = entry.key;
            final apiKey = entry.value;
            final value = data[apiKey];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrapped the label in Expanded to allow it to take up available space
                  // and prevent overflow with long text.
                  Expanded(
                    flex: 2, // Give more space to the label
                    child: Text(
                      displayName,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Wrapped the value in Expanded to allow it to wrap if needed.
                  Expanded(
                    flex: 1, // Give less space to the value
                    child: Text(
                      formatValue(displayName, value),
                      textAlign: TextAlign.end,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

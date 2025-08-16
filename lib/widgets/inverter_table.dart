import 'package:flutter/material.dart';

class InverterTable extends StatelessWidget {
  final List<Map<String, dynamic>> inverterData;

  const InverterTable({
    Key? key,
    required this.inverterData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (inverterData.isEmpty) {
      return const Center(child: Text('No inverter data available.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Inverter ID', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('DC Overloading', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Daily Energy (kWh)', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Daily PR (%)', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: inverterData.map((data) {
          final status = data['status'] ?? 'Unknown';
          Color statusColor = Colors.grey;
          if (status == 'Generating') {
            statusColor = Colors.green;
          } else if (status == 'Communication Failed') {
            statusColor = Colors.red;
          }

          return DataRow(cells: [
            DataCell(Text(data['name'] ?? 'N/A')),
            DataCell(Text(data['dcOverloading']?.toString() ?? 'N/A')),
            DataCell(Text(data['dailyEnergy']?.toString() ?? 'N/A')),
            DataCell(Text(data['dailyPR']?.toString() ?? 'N/A')),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class LineChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const LineChartWidget({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          height: 300,
          child: Center(
            child: Text(
              'No chart data available for this date.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Assuming the data contains 'date' and 'dailyEnergy'
    List<FlSpot> spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value['dailyEnergy'] as num?)?.toDouble() ?? 0);
    }).toList();

    double maxYValue = 0;
    if (data.isNotEmpty) {
      maxYValue = data.map((e) => (e['dailyEnergy'] as num?)?.toDouble() ?? 0).reduce(max) * 1.2;
      if (maxYValue == 0) {
        maxYValue = 100; // Set a default max value if all data is zero
      }
    }

    // Calculate the interval, ensuring it's not zero
    double interval = (maxYValue / 5).floor().toDouble();
    if (interval == 0) {
      interval = 1; // Set a minimum interval of 1 to prevent the crash
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Inverter Energy vs Yield Graph',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Color(0xff37434d),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return const FlLine(
                        color: Color(0xff37434d),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < data.length) {
                            return Text(data[value.toInt()]['date'], style: const TextStyle(color: Color(0xff68737d), fontSize: 10));
                          }
                          return const Text('');
                        },
                        reservedSize: 22,
                        interval: 1,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Color(0xff68737d), fontSize: 10)),
                        reservedSize: 28,
                        interval: interval,
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xff37434d), width: 1),
                  ),
                  minX: 0,
                  maxX: data.length.toDouble() - 1,
                  minY: 0,
                  maxY: maxYValue,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [Colors.cyanAccent, Colors.blue],
                      ),
                      barWidth: 5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.cyan.withOpacity(0.3),
                            Colors.blue.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
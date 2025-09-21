import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../theme.dart'; // Import your theme

class LineChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const LineChartWidget({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: const Text(
            'No chart data available for this date.',
            style: TextStyle(fontSize: 16, color: kTextSecondaryColor),
          ),
        ),
      );
    }

    List<FlSpot> spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value['dailyEnergy'] as num?)?.toDouble() ?? 0);
    }).toList();

    double maxYValue = 0;
    if (spots.isNotEmpty) {
      maxYValue = spots.map((spot) => spot.y).reduce(max) * 1.2;
    }
    if (maxYValue == 0) {
      maxYValue = 100; // Default max if all values are zero
    }

    final interval = (maxYValue / 5).ceilToDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Inverter Energy vs Yield",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval > 0 ? interval : 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).dividerColor,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (data.length / 5).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < data.length) {
                            final dateStr = data[value.toInt()]['date'];
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8.0,
                              child: Text(dateStr ?? '', style: Theme.of(context).textTheme.bodySmall),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: interval > 0 ? interval : 1,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.left);
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [kSecondaryColor, kPrimaryColor],
                      ),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [kSecondaryColor.withOpacity(0.3), kPrimaryColor.withOpacity(0.0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
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


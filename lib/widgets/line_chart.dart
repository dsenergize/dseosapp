import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class LineChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const LineChartWidget({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double totalEnergy = data.fold(
        0.0, (sum, item) => sum + ((item['dailyEnergy'] as num?)?.toDouble() ?? 0));
    final String formattedTotalEnergy =
    NumberFormat.compact().format(totalEnergy);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(formattedTotalEnergy),
            const SizedBox(height: 24),
            if (data.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No chart data available.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      // Ensure interval is never zero
                      horizontalInterval:
                      (_getMaxYValue() / 4).clamp(1, double.infinity),
                      getDrawingHorizontalLine: (value) {
                        return const FlLine(
                          color: Color(0xffe7e8ec),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: _buildTitlesData(),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (data.length - 1).toDouble(),
                    minY: 0,
                    maxY: _getMaxYValue(),
                    lineBarsData: [_buildLineBarData()],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String totalEnergy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inverter Energy',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '$totalEnergy kWh',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.grey),
                onPressed: () {}),
            IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.grey),
                onPressed: () {}),
          ],
        )
      ],
    );
  }

  double _getMaxYValue() {
    if (data.isEmpty) return 100;
    final maxY = data
        .map((e) => (e['dailyEnergy'] as num?)?.toDouble() ?? 0)
        .reduce(max);
    final calculatedMaxY = maxY * 1.25;
    // FIX: Ensure the max value is at least a default value to prevent zero intervals
    return calculatedMaxY > 0 ? calculatedMaxY : 100;
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50,
          interval: _getMaxYValue() / 4,
          getTitlesWidget: (value, meta) {
            return Text(
              NumberFormat.compact().format(value),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: (data.length / 5).ceilToDouble(),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < data.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  data[index]['date'],
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              );
            }
            return const Text('');
          },
        ),
      ),
    );
  }

  LineChartBarData _buildLineBarData() {
    final spots = data.asMap().entries.map((entry) {
      final double yValue =
          (entry.value['dailyEnergy'] as num?)?.toDouble() ?? 0;
      return FlSpot(entry.key.toDouble(), yValue);
    }).toList();

    return LineChartBarData(
      spots: spots,
      isCurved: false,
      gradient: const LinearGradient(
        colors: [Colors.orange, Colors.orangeAccent],
      ),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.3),
            Colors.orangeAccent.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
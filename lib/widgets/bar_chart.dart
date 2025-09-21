import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../theme.dart';

class BarChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const BarChartWidget({Key? key, required this.data}) : super(key: key);

  @override
  State<BarChartWidget> createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget> {
  bool _showPoaData = true;
  bool _showAmbientData = true;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
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

    final List<LineChartBarData> lineBarsData = [];
    double maxPoa = 0;
    double maxAmbientTemp = 0;

    if (_showPoaData) {
      final poaSpots = widget.data.asMap().entries.map((entry) {
        double poaValue = (entry.value['radiation'] as num?)?.toDouble() ?? 0;
        return FlSpot(entry.key.toDouble(), poaValue);
      }).toList();
      if(poaSpots.isNotEmpty) maxPoa = poaSpots.map((s) => s.y).reduce(max);

      lineBarsData.add(
        LineChartBarData(
          spots: poaSpots,
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    if (_showAmbientData) {
      final ambientTempSpots = widget.data.asMap().entries.map((entry) {
        double ambientTempValue = (entry.value['ambientTemp'] as num?)?.toDouble() ?? 0;
        return FlSpot(entry.key.toDouble(), ambientTempValue);
      }).toList();
      if(ambientTempSpots.isNotEmpty) maxAmbientTemp = ambientTempSpots.map((s) => s.y).reduce(max);

      lineBarsData.add(
        LineChartBarData(
          spots: ambientTempSpots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    double maxYValue = max(maxPoa, maxAmbientTemp) * 1.2;
    if (maxYValue == 0) maxYValue = 100;

    final interval = (maxYValue / 5).ceilToDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Live Weather Comparison", style: Theme.of(context).textTheme.titleLarge),
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
                        interval: (widget.data.length / 4).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < widget.data.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8.0,
                              child: Text(widget.data[value.toInt()]['time'], style: Theme.of(context).textTheme.bodySmall),
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
                  minX: 0,
                  maxX: widget.data.isNotEmpty ? widget.data.length.toDouble() - 1 : 1,
                  minY: 0,
                  maxY: maxYValue,
                  lineBarsData: lineBarsData,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  color: Colors.orange,
                  text: 'POA Radiation',
                  isVisible: _showPoaData,
                  onTap: () => setState(() => _showPoaData = !_showPoaData),
                ),
                const SizedBox(width: 20),
                _buildLegendItem(
                  color: Colors.blue,
                  text: 'Ambient Temp',
                  isVisible: _showAmbientData,
                  onTap: () => setState(() => _showAmbientData = !_showAmbientData),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String text,
    required bool isVisible,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isVisible ? color : kTextSecondaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isVisible ? kTextColor : kTextSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


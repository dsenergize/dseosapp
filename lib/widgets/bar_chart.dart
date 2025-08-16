import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

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

    // Create lists of FlSpot objects, one for each data series
    List<FlSpot> poaSpots = widget.data.asMap().entries.map((entry) {
      double poaValue = (entry.value['radiation'] as num?)?.toDouble() ?? 0;
      return FlSpot(entry.key.toDouble(), poaValue);
    }).toList();

    List<FlSpot> ambientTempSpots = widget.data.asMap().entries.map((entry) {
      double ambientTempValue = (entry.value['ambientTemp'] as num?)?.toDouble() ?? 0;
      return FlSpot(entry.key.toDouble(), ambientTempValue);
    }).toList();

    List<LineChartBarData> lineBarsData = [];
    double maxPoa = 0;
    double maxAmbientTemp = 0;

    if (_showPoaData) {
      lineBarsData.add(
        LineChartBarData(
          spots: poaSpots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
      maxPoa = poaSpots.map((s) => s.y).reduce(max);
    }
    if (_showAmbientData) {
      lineBarsData.add(
        LineChartBarData(
          spots: ambientTempSpots,
          isCurved: true,
          color: Colors.red,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
      maxAmbientTemp = ambientTempSpots.map((s) => s.y).reduce(max);
    }

    double maxYValue = max(maxPoa, maxAmbientTemp) * 1.2;
    if (maxYValue == 0) {
      maxYValue = 100;
    }

    double interval = (maxYValue / 5).floor().toDouble();
    if (interval == 0) {
      interval = 1;
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
              'Live Weather Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.5,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      horizontalInterval: interval,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < widget.data.length) {
                              return Text(widget.data[value.toInt()]['time'], style: const TextStyle(color: Color(0xff68737d), fontSize: 10));
                            }
                            return const Text('');
                          },
                          reservedSize: 22,
                          interval: 10,
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
                    maxX: widget.data.length.toDouble() - 1,
                    minY: 0,
                    maxY: maxYValue,
                    lineBarsData: lineBarsData,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  color: Colors.blue,
                  text: 'POA Radiation',
                  isVisible: _showPoaData,
                  onTap: () {
                    setState(() {
                      _showPoaData = !_showPoaData;
                    });
                  },
                ),
                const SizedBox(width: 20),
                _buildLegendItem(
                  color: Colors.red,
                  text: 'Ambient Temp',
                  isVisible: _showAmbientData,
                  onTap: () {
                    setState(() {
                      _showAmbientData = !_showAmbientData;
                    });
                  },
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
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isVisible ? color : color.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isVisible ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

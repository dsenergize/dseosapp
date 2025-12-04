import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (widget.data.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No weather data available.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              Expanded(
                child: BarChart(
                  BarChartData(
                    maxY: _getMaxYValue(),
                    barGroups: _buildBarGroups(),
                    titlesData: _buildTitlesData(),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      // Ensure interval is never zero
                      horizontalInterval:
                      (_getMaxYValue() / 5).clamp(1, double.infinity),
                      getDrawingHorizontalLine: (value) => const FlLine(
                        color: Color(0xffe7e8ec),
                        strokeWidth: 1,
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String label = rodIndex == 0 ? "POA" : "Temp";
                          return BarTooltipItem(
                            '$label\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: (rod.toY - 1).toStringAsFixed(2),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Live Weather Comparison',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    if (widget.data.isEmpty) return 100;
    final maxPoa = widget.data
        .map((d) => (d['radiation'] as num?)?.toDouble() ?? 0)
        .reduce(max);
    final maxTemp = widget.data
        .map((d) => (d['ambientTemp'] as num?)?.toDouble() ?? 0)
        .reduce(max);
    final maxValue = max(maxPoa, maxTemp) * 1.2;
    // FIX: Ensure the max value is at least a default value to prevent zero intervals
    return maxValue > 0 ? maxValue : 100;
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            // Check if the max value is not 0 to avoid division by zero
            final interval =
            _getMaxYValue() > 0 ? (_getMaxYValue() / 5).round() : 20;
            if (value % interval == 0) {
              return Text(
                NumberFormat.compact().format(value),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              );
            }
            return const Text('');
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: (widget.data.length / 5).ceilToDouble(),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < widget.data.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  widget.data[index]['time'],
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

  List<BarChartGroupData> _buildBarGroups() {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final poa = (item['radiation'] as num?)?.toDouble() ?? 0;
      final temp = (item['ambientTemp'] as num?)?.toDouble() ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          if (_showPoaData)
            BarChartRodData(
              toY: poa + 1,
              color: const Color(0xff4376e1),
              width: 7,
              borderRadius: BorderRadius.circular(4),
            ),
          if (_showAmbientData)
            BarChartRodData(
              toY: temp + 1,
              color: Colors.orange, // Changed to orange
              width: 7,
              borderRadius: BorderRadius.circular(4),
            ),
        ],
        showingTooltipIndicators: [],
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(
            color: const Color(0xff4376e1),
            text: 'POA Radiation',
            isVisible: _showPoaData,
            onTap: () => setState(() => _showPoaData = !_showPoaData),
          ),
          const SizedBox(width: 20),
          _buildLegendItem(
            color: Colors.orange, // Changed to orange
            text: 'Ambient Temp',
            isVisible: _showAmbientData,
            onTap: () => setState(() => _showAmbientData = !_showAmbientData),
          ),
        ],
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
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isVisible ? color : color.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isVisible ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
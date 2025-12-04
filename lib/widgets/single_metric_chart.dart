import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import 'dart:math';

enum ChartType { line, bar }

class SingleMetricChart extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> seriesData;
  final Color color;
  final String selectedRange;
  final DateTime selectedDate;
  final ChartType chartType;

  const SingleMetricChart({
    Key? key,
    required this.title,
    required this.seriesData,
    required this.color,
    required this.selectedRange,
    required this.selectedDate,
    required this.chartType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 24, bottom: 12, left: 12),
                child: chartType == ChartType.line
                    ? _buildLineChart()
                    : _buildBarChart(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    double maxValue = 0;
    final spots = seriesData.asMap().entries.map((entry) {
      final index = entry.key;
      final value = (entry.value['value'] as num?)?.toDouble() ?? 0.0;
      if (value > maxValue) maxValue = value;
      return FlSpot(index.toDouble(), value);
    }).toList();

    return LineChart(
      LineChartData(
        maxY: maxValue > 0 ? maxValue * 1.2 : 100,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        titlesData: _buildTitlesData(seriesData),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(
              color: Color(0xffe7e8ec), strokeWidth: 1, dashArray: [3, 4]),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((barSpot) {
                final xIndex = barSpot.x.toInt();
                if (xIndex < 0 || xIndex >= seriesData.length) {
                  return null;
                }
                final label = _getLabelForIndex(xIndex, seriesData);
                final value = barSpot.y;

                return LineTooltipItem(
                  'Date: $label\n',
                  const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '● ',
                      style: TextStyle(color: color),
                    ),
                    TextSpan(
                      text: NumberFormat.compactCurrency(
                        decimalDigits: 2,
                        symbol: '',
                      ).format(value),
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                const FlLine(
                    color: Colors.grey, strokeWidth: 1, dashArray: [4, 4]),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: barData.color ?? kPrimaryColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    double maxValue = 0;
    for (var item in seriesData) {
      final value = (item['value'] as num?)?.toDouble() ?? 0.0;
      if(value > maxValue) maxValue = value;
    }

    final barGroups = seriesData.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final value = (item['value'] as num?)?.toDouble() ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
              toY: value,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.6),
                  color,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              )),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        maxY: maxValue > 0 ? maxValue * 1.2 : 100,
        barGroups: barGroups,
        titlesData: _buildTitlesData(seriesData),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxValue > 0 ? maxValue * 1.2 : 100) / 4,
          getDrawingHorizontalLine: (value) => const FlLine(
              color: Color(0xffe7e8ec), strokeWidth: 1, dashArray: [3, 4]),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = _getLabelForIndex(groupIndex, seriesData);
              final value = rod.toY;
              return BarTooltipItem(
                'Date: $label\n',
                const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '● ',
                    style: TextStyle(color: color),
                  ),
                  TextSpan(
                    text: NumberFormat.compactCurrency(
                      decimalDigits: 2,
                      symbol: '',
                    ).format(value),
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  FlTitlesData _buildTitlesData(List<Map<String, dynamic>> data) {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: max(1, (data.length / 5).ceilToDouble()),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < data.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _getLabelForIndex(index, data),
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

  String _getLabelForIndex(int index, List<Map<String, dynamic>> data) {
    if (index >= data.length) return '';
    final item = data[index];
    final dateString = item['date'] as String?;
    final timeString = item['time'] as String?;


    try {
      switch (selectedRange) {
        case 'Day':
          return timeString ?? '';
        case 'Week':
          if (dateString == null) return '';
          final parts = dateString.split(' ');
          final monthMap = {'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12};
          final month = monthMap[parts[0]];
          final day = int.tryParse(parts[1]);
          if (month != null && day != null) {
            final date = DateTime(selectedDate.year, month, day);
            return DateFormat('d/M').format(date);
          }
          return dateString;
        case 'Month':
        case 'Year':
          if (dateString == null) return '';
          DateTime date;
          if(dateString.contains(" ")){
            date = DateFormat("MMM yyyy").parse(dateString);
          } else {
            date = DateTime.tryParse(dateString) ?? DateTime.now();
          }
          return DateFormat('MMM').format(date);
        default:
          return '';
      }
    } on FormatException {
      return dateString ?? timeString ?? '';
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../theme.dart';
import 'date_selector.dart';

class DataScreenTemplate extends StatefulWidget {
  final Map<String, dynamic> plant;
  final String title;

  final Future<Map<String, dynamic>> Function(DateTime date) fetchDayData;
  final Future<Map<String, dynamic>> Function(DateTime date) fetchDailyReport;
  final Future<Map<String, dynamic>> Function(DateTime date) fetchMonthlyReport;
  final Future<Map<String, dynamic>> Function(DateTime date) fetchYearlyReport;

  final String defaultDataKey;

  const DataScreenTemplate({
    Key? key,
    required this.plant,
    required this.title,
    required this.fetchDayData,
    required this.fetchDailyReport,
    required this.fetchMonthlyReport,
    required this.fetchYearlyReport,
    required this.defaultDataKey,
  }) : super(key: key);

  @override
  State<DataScreenTemplate> createState() => _DataScreenTemplateState();
}

class _DataScreenTemplateState extends State<DataScreenTemplate> {
  late Future<Map<String, dynamic>> _dataFuture;
  String _selectedRange = 'Day';
  DateTime _selectedDate = DateTime.now();

  Set<String> _activeFilters = {};
  List<String> _availableFilters = [];
  bool _isFirstLoad = true;

  final Map<String, Color> _seriesColorMap = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _isFirstLoad = true;
      switch (_selectedRange) {
        case 'Day':
          _dataFuture = widget.fetchDayData(_selectedDate);
          break;
        case 'Week':
          _dataFuture = widget.fetchDailyReport(_selectedDate);
          break;
        case 'Month':
          _dataFuture = widget.fetchMonthlyReport(_selectedDate);
          break;
        case 'Year':
          _dataFuture = widget.fetchYearlyReport(_selectedDate);
          break;
      }
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _fetchData();
  }

  void _onRangeSelected(String range) {
    setState(() {
      _selectedRange = range;
    });
    _fetchData();
  }

  Color _getColorForSeries(String seriesName) {
    if (!_seriesColorMap.containsKey(seriesName)) {
      _seriesColorMap[seriesName] =
      Colors.primaries[Random().nextInt(Colors.primaries.length)];
    }
    return _seriesColorMap[seriesName]!;
  }

  DatePickerModeType _getCurrentPickerMode() {
    switch (_selectedRange) {
      case 'Day':
        return DatePickerModeType.day;
      case 'Week':
        return DatePickerModeType.month;
      case 'Month':
      case 'Year':
        return DatePickerModeType.year;
      default:
        return DatePickerModeType.day;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: kPrimaryColor)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kPrimaryColor),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildTimeRangeSelector()),
                const SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  child: DateSelector(
                    selectedDate: _selectedDate,
                    onDateSelected: _onDateSelected,
                    pickerMode: _getCurrentPickerMode(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: kPrimaryColor));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red)));
                }
                final data = snapshot.data ?? {};
                if (data.isEmpty) {
                  return const Center(child: Text('No data available.'));
                }

                final bool isLineChart =
                    _selectedRange == 'Day' || _selectedRange == 'Week';

                if (isLineChart) {
                  final currentFilters = data.keys.toList();
                  if (_isFirstLoad ||
                      !listEquals(_availableFilters, currentFilters)) {
                    _availableFilters = currentFilters;
                    if (_isFirstLoad) {
                      _activeFilters = _availableFilters.toSet();
                      _isFirstLoad = false;
                    }
                  }
                  // Render the new dashboard layout
                  return _buildDashboardLayout(data);
                } else {
                  // For Month/Year, show the single bar chart as before
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildBarChart(data),
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'Day', label: Text('Day')),
        ButtonSegment(value: 'Week', label: Text('Week')),
        ButtonSegment(value: 'Month', label: Text('Month')),
        ButtonSegment(value: 'Year', label: Text('Year')),
      ],
      selected: {_selectedRange},
      onSelectionChanged: (newSelection) {
        _onRangeSelected(newSelection.first);
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryColor,
        selectedBackgroundColor: kPrimaryColor,
        selectedForegroundColor: Colors.white,
      ),
    );
  }

  // NEW: A horizontal bar of filter chips.
  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0,
        children: _availableFilters.map((filter) {
          final isSelected = _activeFilters.contains(filter);
          final color = _getColorForSeries(filter);
          return FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (bool selected) {
              setState(() {
                if (selected) {
                  _activeFilters.add(filter);
                } else {
                  _activeFilters.remove(filter);
                }
              });
            },
            backgroundColor: Colors.white,
            selectedColor: color.withOpacity(0.1),
            checkmarkColor: color,
            shape: StadiumBorder(side: BorderSide(color: isSelected ? color : Colors.grey.shade300)),
            labelStyle: TextStyle(
              color: isSelected ? color : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }).toList(),
      ),
    );
  }

  // NEW: Main layout for Day/Week view with a filter bar and a list of charts.
  Widget _buildDashboardLayout(Map<String, dynamic> data) {
    final activeKeys = _activeFilters.toList()..sort();
    return Column(
      children: [
        _buildFilterBar(),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: activeKeys.length,
            itemBuilder: (context, index) {
              final key = activeKeys[index];
              final seriesData = (data[key] as List).cast<Map<String, dynamic>>();
              return _buildIndividualLineChart(key, seriesData);
            },
          ),
        ),
      ],
    );
  }

  // NEW: Widget for displaying a single line chart metric in a card.
  Widget _buildIndividualLineChart(String title, List<Map<String, dynamic>> seriesData) {
    final seriesColor = _getColorForSeries(title);
    double maxValue = 0;
    final spots = seriesData.asMap().entries.map((entry) {
      final index = entry.key;
      final value = (entry.value['value'] as num?)?.toDouble() ?? 0.0;
      if (value > maxValue) maxValue = value;
      return FlSpot(index.toDouble(), value);
    }).toList();

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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 24, bottom: 12),
                child: LineChart(
                  LineChartData(
                    maxY: maxValue > 0 ? maxValue * 1.2 : 100,
                    minY: 0,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: seriesColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              seriesColor.withOpacity(0.3),
                              seriesColor.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    titlesData: _buildLineTitlesData(seriesData),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) =>
                      const FlLine(color: Color(0xffe7e8ec), strokeWidth: 1, dashArray: [3, 4]),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> data) {
    final dataList =
        (data[widget.defaultDataKey] as List?)?.cast<Map<String, dynamic>>() ??
            [];
    if (dataList.isEmpty)
      return const Center(child: Text('No data for this period.'));

    final double maxValue = dataList
        .map((e) =>
    (e['value'] as num?)?.toDouble() ??
        (e[widget.defaultDataKey] as num?)?.toDouble() ??
        0)
        .fold(0.0, max) *
        1.2;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: BarChart(
        BarChartData(
          maxY: maxValue > 0 ? maxValue : 100,
          barGroups: _buildBarGroups(dataList),
          titlesData: _buildTitlesData(dataList),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxValue > 0 ? maxValue : 100) / 4,
            getDrawingHorizontalLine: (value) =>
            const FlLine(color: Color(0xffe7e8ec), strokeWidth: 1, dashArray: [3, 4]),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
      List<Map<String, dynamic>> data) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final value = (item['value'] as num?)?.toDouble() ??
          (item[widget.defaultDataKey] as num?)?.toDouble() ??
          0;
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
                  kPrimaryColor.withOpacity(0.6),
                  kPrimaryColor,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              )),
        ],
      );
    }).toList();
  }

  FlTitlesData _buildTitlesData(List<Map<String, dynamic>> data) {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50,
          getTitlesWidget: (value, meta) {
            if (value == meta.max || value == meta.min) {
              return Container();
            }
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
          interval: (data.length / 6).ceilToDouble(),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < data.length) {
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

  FlTitlesData _buildLineTitlesData(List<Map<String, dynamic>> data) {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50,
          getTitlesWidget: (value, meta) {
            if (value == meta.max || value == meta.min) {
              return Container();
            }
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
          interval: (data.length / 6).ceilToDouble(),
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
    final item = data[index];
    final dateString = item['date'] as String?;

    try {
      switch (_selectedRange) {
        case 'Day':
          return item['time'] ?? '';
        case 'Week':
          if (dateString == null) return '';
          final parsableDateString = "$dateString ${_selectedDate.year}";
          final date = DateFormat("MMM d yyyy").parse(parsableDateString);
          return DateFormat('d/M').format(date);
        case 'Month':
          final date =
          dateString != null ? DateTime.tryParse(dateString) : null;
          return date != null ? DateFormat('d').format(date) : '';
        case 'Year':
          final date =
          dateString != null ? DateTime.tryParse(dateString) : null;
          return date != null ? DateFormat('MMM').format(date) : '';
        default:
          return '';
      }
    } on FormatException {
      return dateString ?? '';
    }
  }
}

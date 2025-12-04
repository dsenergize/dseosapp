import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/date_selector.dart';
import '../theme.dart';
import 'dart:math';

enum ChartType { line, bar }

class MeterDataScreen extends StatefulWidget {
  final Map<String, dynamic> plant;
  const MeterDataScreen({super.key, required this.plant});

  @override
  State<MeterDataScreen> createState() => _MeterDataScreenState();
}

class _MeterDataScreenState extends State<MeterDataScreen> {
  // --- STATE MANAGEMENT ---

  String _selectedRange = 'Day';
  DateTime _selectedDate = DateTime.now();
  Future<Map<String, dynamic>>? _dataFetchFuture;

  Map<String, dynamic>? _fullApiResponse;
  List<String> _availableMeters = [];
  String? _selectedMeter;
  List<String> _availableDataFilters = [];
  Set<String> _selectedDataFilters = {};

  final Map<String, Color> _seriesColorMap = {};
  int _colorIndex = 0;
  final List<Color> _modernChartColors = [
    Colors.cyan.shade500, Colors.deepPurple.shade500, Colors.green.shade500,
    Colors.amber.shade700, Colors.pink.shade400, Colors.indigo.shade500,
    Colors.lime.shade600, Colors.blueGrey.shade500,
  ];

  final Map<String, String> _metricDisplayNames = {
    'activePower': 'Active Power',
    'reactivePower': 'Reactive Power',
    'totalApparentPower': 'Apparent Power',
    'lifetimeEnergyExport': 'Lifetime Energy Export',
    'avgLineToLineVoltage': 'Avg L-L Voltage',
    'avgLineToNeutralVoltage': 'Avg L-N Voltage',
    'voltageRPhase': 'Voltage R Phase',
    'voltageYPhase': 'Voltage Y Phase',
    'voltageBPhase': 'Voltage B Phase',
    'voltageRY': 'Voltage RY',
    'voltageBY': 'Voltage YB',
    'voltageRB': 'Voltage BR',
    'currentRPhase': 'Current R Phase',
    'currentYPhase': 'Current Y Phase',
    'currentBPhase': 'Current B Phase',
    'totalLineCurrent': 'Total Line Current',
    'frequency': 'Frequency',
    'powerFactor': 'Power Factor',
    'stat': 'Stat',
  };

  // Maps for scaling factors and units based on API key (lowercase)
  final Map<String, Map<String, double>> _scalingFactors = {
    'Day': {
      'activepower': 1.0,
      'reactivepower': 1.0,
      'apparentpower': 1.0,
      'lifetimeenergyexport': 1.0,
      'avglinetolinevoltage': 0.001,
      'avglinetoneutralvoltage': 0.001,
      'voltagerphase': 0.001,
      'voltageyphase': 0.001,
      'voltagebphase': 0.001,
      'voltagery': 0.001,
      'voltageyb': 0.001,
      'voltagebr': 0.001,
      'currentrphase': 1.0,
      'currentyphase': 1.0,
      'currentbphase': 1.0,
      'totallinecurrent': 1.0,
      'frequency': 0.01,
      'powerfactor': 0.001,
    },
    'Week': {}, 'Month': {}, 'Year': {},
  };

  final Map<String, Map<String, String>> _units = {
    'Day': {
      'activepower': 'kW',
      'reactivepower': 'kVAr',
      'apparentpower': 'kVA',
      'lifetimeenergyexport': 'kWh',
      'avglinetolinevoltage': 'V',
      'avglinetoneutralvoltage': 'V',
      'voltagerphase': 'V',
      'voltageyphase': 'V',
      'voltagebphase': 'V',
      'voltagery': 'V',
      'voltageyb': 'V',
      'voltagebr': 'V',
      'currentrphase': 'A',
      'currentyphase': 'A',
      'currentbphase': 'A',
      'totallinecurrent': 'A',
      'frequency': 'Hz',
      'powerfactor': '',
    },
    'Week': {}, 'Month': {}, 'Year': {},
  };

  @override
  void initState() {
    super.initState();
    _dataFetchFuture = _fetchApiData();
  }

  // --- DATA FLOW ---

  Future<Map<String, dynamic>> _fetchApiData() {
    developer.log("Fetching Meter Data for range: $_selectedRange", name: "MeterScreen.API");
    switch (_selectedRange) {
      case 'Day': return ApiService.getMeterDayData(widget.plant['id'], _selectedDate);
      case 'Week': return ApiService.getMeterDailyReport(widget.plant['id'], _selectedDate);
      case 'Month': return ApiService.getMeterMonthlyReport(widget.plant['id'], _selectedDate);
      case 'Year': return ApiService.getMeterMonthlyReport(widget.plant['id'], _selectedDate);
      default: return Future.value({});
    }
  }

  void _processSnapshotData(Map<String, dynamic> data) {
    developer.log('Processing snapshot data', name: 'MeterScreen.DataFlow');
    _fullApiResponse = data;

    // --- Correctly extract Meters ---
    List<Map<String, dynamic>> metersList = [];
    final rawMeters = _fullApiResponse?['meters'];

    if (rawMeters is List) {
      metersList = rawMeters.cast<Map<String, dynamic>>();
    } else if (rawMeters is Map<String, dynamic>) {
      metersList = rawMeters.values
          .whereType<List>()
          .expand((list) => list)
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    _fullApiResponse!['meters'] = metersList;

    _availableMeters = metersList.map((meter) => meter['meterName'] as String?).where((name) => name != null && name.isNotEmpty).cast<String>().toSet().toList();
    developer.log('Available meters found: $_availableMeters', name: 'MeterScreen.DataFlow');

    for (final meterName in _availableMeters) {
      _getColorForSeries(meterName);
    }

    if (_availableMeters.isNotEmpty && (_selectedMeter == null || !_availableMeters.contains(_selectedMeter))) {
      _selectedMeter = _availableMeters.first;
      developer.log('Auto-selecting first meter: $_selectedMeter', name: 'MeterScreen.DataFlow');
    }

    _updateAvailableMetricFilters();
  }

  void _updateAvailableMetricFilters({ bool meterChanged = false }) {
    if (_selectedMeter == null || _fullApiResponse == null) {
      _availableDataFilters = [];
      _selectedDataFilters = {};
      return;
    }
    developer.log('Updating metric filters for: $_selectedMeter', name: 'MeterScreen.DataFlow');

    final metersList = (_fullApiResponse!['meters'] as List).cast<Map<String, dynamic>>();
    final meterData = metersList.firstWhere((meter) => meter['meterName'] == _selectedMeter, orElse: () => <String, dynamic>{});

    final filters = <String>{};
    for (var key in meterData.keys) {
      if (meterData[key] is List && (meterData[key] as List).isNotEmpty) {
        filters.add(key);
      }
    }
    filters.remove('meterName');
    _availableDataFilters = filters.toList()..sort();
    developer.log('Available metrics for $_selectedMeter: $_availableDataFilters', name: 'MeterScreen.DataFlow');

    if (meterChanged) {
      _selectedDataFilters = _availableDataFilters.isNotEmpty ? {_availableDataFilters.first} : {};
    } else {
      _selectedDataFilters.removeWhere((f) => !_availableDataFilters.contains(f));
      if (_selectedDataFilters.isEmpty && _availableDataFilters.isNotEmpty) {
        _selectedDataFilters = {_availableDataFilters.first};
      }
    }
    developer.log('Selected metrics updated to: $_selectedDataFilters', name: 'MeterScreen.DataFlow');
  }

  void _clearAllState() {
    _fullApiResponse = null;
    _availableMeters = [];
    _selectedMeter = null;
    _availableDataFilters = [];
    _selectedDataFilters = {};
  }

  Color _getColorForSeries(String seriesKey) {
    if (!_seriesColorMap.containsKey(seriesKey)) {
      _seriesColorMap[seriesKey] = _modernChartColors[_colorIndex % _modernChartColors.length];
      _colorIndex++;
    }
    return _seriesColorMap[seriesKey]!;
  }

  double _getScaleFactor(String range, String key) {
    return _scalingFactors[range]?[key.toLowerCase().replaceAll('_', '')] ?? 1.0;
  }

  String _getUnit(String range, String key) {
    return _units[range]?[key.toLowerCase().replaceAll('_', '')] ?? '';
  }

  // --- EVENT HANDLERS ---

  void _onMeterSelected(String? newMeter) {
    if (newMeter != null && newMeter != _selectedMeter) {
      setState(() {
        _selectedMeter = newMeter;
        _updateAvailableMetricFilters(meterChanged: true);
      });
    }
  }

  void _onDataFilterSelectionChanged(String filterKey, bool isSelected) {
    setState(() {
      if (isSelected) _selectedDataFilters.add(filterKey);
      else _selectedDataFilters.remove(filterKey);
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _clearAllState();
      _dataFetchFuture = _fetchApiData();
    });
  }

  void _onRangeSelected(String range) {
    if (range == _selectedRange) return;
    setState(() {
      _selectedRange = range;
      _clearAllState();
      _dataFetchFuture = _fetchApiData();
    });
  }

  Future<void> _showDatePickerPopup() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDatePickerMode: _selectedRange == 'Year' ? DatePickerMode.year : DatePickerMode.day,
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 350.0,
              maxHeight: 480.0,
            ),
            child: child,
          ),
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      _onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Meter Level Data", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kPrimaryColor),
      ),
      body: Column(
        children: [
          _buildControlPanel(),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _dataFetchFuture,
              builder: (context, snapshot) {
                final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                final bool hasError = snapshot.hasError || !snapshot.hasData || (snapshot.data?.isEmpty ?? true);

                if (!isLoading && !hasError && _fullApiResponse == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _processSnapshotData(snapshot.data!);
                      });
                    }
                  });
                }

                if (isLoading || (_fullApiResponse == null && !hasError)) {
                  return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                }

                if (hasError) {
                  return _buildEmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not fetch data',
                      message: 'Please check your connection and try again.'
                  );
                }

                final meterData = (_selectedMeter != null && _fullApiResponse != null && (_fullApiResponse!['meters'] as List).isNotEmpty)
                    ? (_fullApiResponse!['meters'] as List).cast<Map<String, dynamic>>().firstWhere(
                      (meter) => meter['meterName'] == _selectedMeter,
                  orElse: () => {},
                )
                    : null;

                return Column(
                  children: [
                    _buildMetricFilterBar(),
                    Expanded(
                      child: Builder(builder: (context) {
                        if (meterData == null || _selectedDataFilters.isEmpty) {
                          return _buildEmptyState(
                              icon: Icons.analytics_outlined,
                              title: 'No Data to Display',
                              message: 'Select a meter and at least one metric.'
                          );
                        }
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: _selectedDataFilters.map((filterKey) {
                            final seriesData = (meterData[filterKey] as List?)?.cast<Map<String, dynamic>>();
                            if(seriesData == null || seriesData.isEmpty) return const SizedBox.shrink();

                            ChartType chartType = ChartType.line;
                            String keyLower = filterKey.toLowerCase();

                            if (_selectedRange == 'Week' && (keyLower.contains('energy'))) {
                              chartType = ChartType.bar;
                            } else if (_selectedRange == 'Month' && (keyLower.contains('energy'))) {
                              chartType = ChartType.bar;
                            }

                            return _SingleMetricChart(
                              title: _metricDisplayNames[filterKey] ?? filterKey,
                              seriesData: seriesData,
                              color: _getColorForSeries(filterKey),
                              range: _selectedRange,
                              chartType: chartType,
                              scale: _getScaleFactor(_selectedRange, filterKey),
                              unit: _getUnit(_selectedRange, filterKey),
                            );
                          }).toList(),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- BUILD WIDGETS ---

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          _buildTimeRangeSelector(),
          const SizedBox(height: 16),
          _buildDateNavigator(),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Meters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextSecondaryColor)),
          ),
          const SizedBox(height: 8),
          _buildMeterGridSelector(),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    final List<String> ranges = ['Day', 'Week', 'Month', 'Year'];
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ranges.map((range) {
          final isSelected = _selectedRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onRangeSelected(range),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      range,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? kPrimaryColor : kTextSecondaryColor,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 3,
                    width: isSelected ? 60 : 0,
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
          onPressed: () {
            DateTime newDate;
            if (_selectedRange == 'Day') {
              newDate = _selectedDate.subtract(const Duration(days: 1));
            } else if (_selectedRange == 'Week' || _selectedRange == 'Month') {
              newDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
            } else { // Year
              newDate = DateTime(_selectedDate.year - 1, _selectedDate.month, _selectedDate.day);
            }
            _onDateSelected(newDate);
          },
        ),
        GestureDetector(
          onTap: _showDatePickerPopup,
          child: Column(
            children: [
              Text(
                _getDateNavigatorTitle(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_selectedRange != 'Year')
                Text(
                  DateFormat('yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 14, color: kTextSecondaryColor),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: kPrimaryColor),
          onPressed: () {
            DateTime newDate;
            if (_selectedRange == 'Day') {
              newDate = _selectedDate.add(const Duration(days: 1));
            } else if (_selectedRange == 'Week' || _selectedRange == 'Month') {
              newDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
            } else { // Year
              newDate = DateTime(_selectedDate.year + 1, _selectedDate.month, _selectedDate.day);
            }
            _onDateSelected(newDate);
          },
        ),
      ],
    );
  }

  String _getDateNavigatorTitle() {
    switch (_selectedRange) {
      case 'Day':
        return DateFormat('MMMM d').format(_selectedDate);
      case 'Week':
      case 'Month':
        return DateFormat('MMMM').format(_selectedDate);
      case 'Year':
        return DateFormat('yyyy').format(_selectedDate);
      default:
        return '';
    }
  }

  Widget _buildMeterGridSelector() {
    if (_fullApiResponse == null) {
      // Show a placeholder or loader while the initial data is being fetched and processed.
      return const Center(heightFactor: 2, child: Text("Loading Meters...", style: TextStyle(color: kTextSecondaryColor)));
    }
    if (_availableMeters.isEmpty) {
      return const Center(heightFactor: 2, child: Text("No Meters Found", style: TextStyle(color: kTextSecondaryColor)));
    }

    return SizedBox(
      height: 140,
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _availableMeters.map((meterName) {
            final bool isSelected = _selectedMeter == meterName;
            final Color color = _getColorForSeries(meterName);

            return GestureDetector(
              onTap: () => _onMeterSelected(meterName),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  meterName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMetricFilterBar() {
    if (_availableDataFilters.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextSecondaryColor)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8.0,
              children: _availableDataFilters.map((filterKey) {
                final isSelected = _selectedDataFilters.contains(filterKey);
                final color = _getColorForSeries(filterKey);
                return FilterChip(
                  label: Text(_metricDisplayNames[filterKey] ?? filterKey),
                  selected: isSelected,
                  onSelected: (bool val) => _onDataFilterSelectionChanged(filterKey, val),
                  backgroundColor: Colors.white, selectedColor: color.withOpacity(0.1),
                  checkmarkColor: color, shape: StadiumBorder(side: BorderSide(color: isSelected ? color : Colors.grey.shade300)),
                  labelStyle: TextStyle(
                    color: isSelected ? color : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextSecondaryColor)),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(color: kTextSecondaryColor)),
        ],
      ),
    );
  }
}


// A private widget to render a single chart for a given metric.
class _SingleMetricChart extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> seriesData;
  final Color color;
  final String range;
  final ChartType chartType;
  final double scale;
  final String unit;

  const _SingleMetricChart({
    required this.title,
    required this.seriesData,
    required this.color,
    required this.range,
    required this.chartType,
    required this.scale,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0, bottom: 12.0, left: 12.0),
                child: chartType == ChartType.bar ? _buildBarChart(context) : _buildLineChart(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final String xAxisKey = seriesData.isNotEmpty && seriesData.first.containsKey('date') ? 'date' : 'time';
    double maxY = 0;
    final spots = seriesData.asMap().entries.map((entry) {
      final value = ((entry.value['value'] as num?)?.toDouble() ?? 0.0) * scale;
      if (value > maxY) maxY = value;
      return FlSpot(entry.key.toDouble(), value);
    }).toList();

    return LineChart(
      LineChartData(
        maxY: maxY > 0 ? maxY * 1.2 : 10,
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
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xffe7e8ec), strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: _buildTitlesData(xAxisKey),
        lineTouchData: _buildLineTouchData(xAxisKey),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final String xAxisKey = seriesData.isNotEmpty && seriesData.first.containsKey('date') ? 'date' : 'time';
    double maxY = 0;
    final barGroups = seriesData.asMap().entries.map((entry) {
      final value = ((entry.value['value'] as num?)?.toDouble() ?? 0.0) * scale;
      if (value > maxY) maxY = value;
      return BarChartGroupData(x: entry.key, barRods: [
        BarChartRodData(
            toY: value,
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.8),
                color,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4))
        ),
      ]);
    }).toList();

    return BarChart(
      BarChartData(
        maxY: maxY > 0 ? maxY * 1.2 : 10,
        barGroups: barGroups,
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xffe7e8ec), strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: _buildTitlesData(xAxisKey),
        barTouchData: _buildBarTouchData(xAxisKey),
      ),
    );
  }

  FlTitlesData _buildTitlesData(String xAxisKey) {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (value, meta) {
        if (value == meta.max || value == meta.min) return const SizedBox();
        return Text(NumberFormat.compact().format(value), style: const TextStyle(color: kTextSecondaryColor, fontSize: 12));
      })),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: max(1, (seriesData.length / 5).ceilToDouble()),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < seriesData.length) {
              return SideTitleWidget(axisSide: meta.axisSide, space: 8, child: Text(seriesData[index][xAxisKey]?.toString() ?? '', style: const TextStyle(color: kTextSecondaryColor, fontSize: 12)));
            }
            return const Text('');
          },
        ),
      ),
    );
  }

  LineTouchData _buildLineTouchData(String xAxisKey) {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        tooltipRoundedRadius: 8,
        getTooltipColor: (spot) => Colors.black.withOpacity(0.8),
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final index = spot.x.toInt();
            final item = seriesData[index];
            final scaledValue = spot.y;
            final String label = item[xAxisKey]?.toString() ?? '';
            final String displayLabel = 'time-$label';

            return LineTooltipItem(
              '$displayLabel\n',
              const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              children: [
                TextSpan(
                  text: scaledValue.toStringAsFixed(2),
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList();
        },
      ),
    );
  }

  BarTouchData _buildBarTouchData(String xAxisKey) {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        tooltipRoundedRadius: 8,
        getTooltipColor: (group) => Colors.black.withOpacity(0.8),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final item = seriesData[groupIndex];
          final scaledValue = rod.toY;
          final String label = item[xAxisKey]?.toString() ?? '';
          final String displayLabel = 'time-$label';
          return BarTooltipItem(
              '$displayLabel\n',
              const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              children: [
                TextSpan(
                  text: scaledValue.toStringAsFixed(2),
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]
          );
        },
      ),
    );
  }
}


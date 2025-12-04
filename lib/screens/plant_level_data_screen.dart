import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/date_selector.dart';
import '../widgets/single_metric_chart.dart';
import '../theme.dart';
import 'dart:math';

class PlantLevelDataScreen extends StatefulWidget {
  final Map<String, dynamic> plant;
  const PlantLevelDataScreen({super.key, required this.plant});

  @override
  State<PlantLevelDataScreen> createState() => _PlantLevelDataScreenState();
}

class _PlantLevelDataScreenState extends State<PlantLevelDataScreen> {
  late Future<Map<String, dynamic>> _dataFuture;
  String _selectedRange = 'Day';
  DateTime _selectedDate = DateTime.now();
  final Map<String, Color> _seriesColorMap = {};

  Set<String> _activeFilters = {};
  List<String> _availableFilters = [];
  bool _isFirstLoad = true;

  final List<Color> _modernChartColors = [
    Colors.teal.shade300,
    Colors.red.shade300,
    Colors.blueGrey.shade300,
    Colors.lightBlue.shade200,
    Colors.purple.shade200,
    Colors.green.shade300,
    Colors.pink.shade100,
    Colors.amber.shade200,
  ];
  int _colorIndex = 0;


  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _isFirstLoad = true;
      _colorIndex = 0;
      _seriesColorMap.clear();
      switch (_selectedRange) {
        case 'Day':
          _dataFuture = _fetchDayData(_selectedDate);
          break;
        case 'Week':
          _dataFuture = _fetchWeeklyData(_selectedDate);
          break;
        case 'Month':
          _dataFuture = _fetchMonthlyData(_selectedDate);
          break;
        case 'Year':
          _dataFuture = _fetchYearlyData(_selectedDate);
          break;
      }
    });
  }

  Future<Map<String, dynamic>> _fetchDayData(DateTime date) async {
    developer.log(
      'Fetching PLANT DAY data for plant ${widget.plant['id']} on $date',
      name: 'PlantLevelDataScreen',
    );
    final rawData = await ApiService.getPlantDayData(widget.plant['id'], date);
    return Map<String, dynamic>.fromEntries(
      rawData.entries.where((entry) => entry.value is List),
    );
  }

  Future<Map<String, dynamic>> _fetchWeeklyData(DateTime date) async {
    developer.log('Fetching PLANT WEEK data for plant ${widget.plant['id']} on $date', name: 'PlantLevelDataScreen');
    final rawData = await ApiService.getPlantDailyReport(widget.plant['id'], date);
    return Map<String, dynamic>.fromEntries(
      rawData.entries.where((entry) => entry.value is List),
    );
  }

  Future<Map<String, dynamic>> _fetchMonthlyData(DateTime date) async {
    developer.log('Fetching PLANT MONTH data for plant ${widget.plant['id']} on $date', name: 'PlantLevelDataScreen');
    final rawData = await ApiService.getPlantMonthlyReport(widget.plant['id'], date);
    return Map<String, dynamic>.fromEntries(
      rawData.entries.where((entry) => entry.value is List),
    );
  }

  Future<Map<String, dynamic>> _fetchYearlyData(DateTime date) async {
    developer.log('Fetching PLANT YEAR data for plant ${widget.plant['id']} on $date', name: 'PlantLevelDataScreen');
    final rawData = await ApiService.getPlantYearlyReport(widget.plant['id'], date);
    return Map<String, dynamic>.fromEntries(
      rawData.entries.where((entry) => entry.value is List),
    );
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _fetchData();
  }

  void _onRangeSelected(String range) {
    if (_selectedRange == range) return;
    setState(() {
      _selectedRange = range;
    });
    _fetchData();
  }

  Future<void> _showDatePickerPopup() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
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

  Color _getColorForSeries(String seriesName) {
    if (!_seriesColorMap.containsKey(seriesName)) {
      _seriesColorMap[seriesName] = _modernChartColors[_colorIndex % _modernChartColors.length];
      _colorIndex++;
    }
    return _seriesColorMap[seriesName]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Plant Level Data", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kPrimaryColor),
      ),
      body: Column(
        children: [
          _buildControlPanel(),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }
                final data = snapshot.data ?? {};
                if (data.isEmpty) {
                  return const Center(child: Text('No data available.'));
                }

                if (_isFirstLoad) {
                  _availableFilters = data.keys.toList();
                  _activeFilters = _availableFilters.toSet();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _isFirstLoad = false);
                  });
                }

                final activeDataKeys = data.keys.where((key) => _activeFilters.contains(key)).toList();

                return Column(
                  children: [
                    _buildFilterBar(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: activeDataKeys.length,
                        itemBuilder: (context, index) {
                          final key = activeDataKeys[index];
                          final seriesData = (data[key] as List).cast<Map<String, dynamic>>();

                          ChartType chartType;
                          if (_selectedRange == 'Week' || _selectedRange == 'Month' || _selectedRange == 'Year') {
                            if (key.toLowerCase().contains('energy') || key.toLowerCase().contains('export')) {
                              chartType = ChartType.bar;
                            } else {
                              chartType = ChartType.line;
                            }
                          } else {
                            chartType = ChartType.line;
                          }

                          return SingleMetricChart(
                            title: key,
                            seriesData: seriesData,
                            color: _getColorForSeries(key),
                            selectedRange: _selectedRange,
                            selectedDate: _selectedDate,
                            chartType: chartType,
                          );
                        },
                      ),
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

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          _buildTimeRangeSelector(),
          const SizedBox(height: 16),
          _buildDateNavigator(),
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

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16.0, 8, 16.0, 16.0),
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
}


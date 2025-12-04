import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:developer' as developer;
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/date_selector.dart';

// --- COLOR & STATUS PALETTE ---
// Defined here to match the provided React code's color scheme.
const Map<String, Map<String, Color>> statusPalette = {
  'Active': {
    'pieFill': Color(0xFF22c55e), // Generating
    'bg': Color(0xFFDCFCE7),
    'text': Color(0xFF166534),
  },
  'Communication Failed': {
    'pieFill': Color(0xFFef4444),
    'bg': Color(0xFFFEE2E2),
    'text': Color(0xFF991B1B),
  },
  'Sleeping': {
    'pieFill': Color(0xFF64748b),
    'bg': Color(0xFFF1F5F9),
    'text': Color(0xFF334155),
  },
  'Non Operational': {
    'pieFill': Color(0xFFf59e0b),
    'bg': Color(0xFFFEF3C7),
    'text': Color(0xFF92400E),
  },
  'Unknown': {
    'pieFill': Color(0xFFa1a1aa),
    'bg': Color(0xFFE5E7EB),
    'text': Color(0xFF374151),
  },
};


class DeviceStatusScreen extends StatefulWidget {
  final Map<String, dynamic> plant;
  const DeviceStatusScreen({Key? key, required this.plant}) : super(key: key);

  @override
  State<DeviceStatusScreen> createState() => _DeviceStatusScreenState();
}

class _DeviceStatusScreenState extends State<DeviceStatusScreen> {
  Future<Map<String, dynamic>>? _deviceStatusFuture;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _deviceStatusFuture = ApiService.getDeviceStatus(widget.plant['id'], _selectedDate);
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _fetchData();
    });
  }

  // This function transforms the raw API data into a structure the UI can use.
  // It now correctly handles nested maps for inverters.
  Map<String, dynamic> _transformData(Map<String, dynamic> rawData) {
    // Helper to process a finalized list of devices into counts and totals.
    Map<String, dynamic> processDeviceList(List<Map<String, dynamic>> deviceList) {
      final statusCounts = <String, int>{};
      for (var device in deviceList) {
        final status = device['status'] as String? ?? 'Unknown';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
      return {
        'total': deviceList.length,
        'devices': deviceList,
        'statusCounts': statusCounts,
      };
    }

    // --- Correctly extract Inverters ---
    // The API may return inverters as a map of lists, so we flatten it.
    List<Map<String, dynamic>> inverterList = [];
    final rawInverters = rawData['inverters'];
    if (rawInverters is Map<String, dynamic>) {
      inverterList = rawInverters.values
          .where((value) => value is List)
          .expand((list) => (list as List))
          .where((item) => item is Map<String, dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();
    } else if (rawInverters is List) {
      inverterList = rawInverters.cast<Map<String, dynamic>>();
    }

    // --- Correctly extract Meters and Weather Stations ---
    // These are assumed to be direct lists.
    final meterList = (rawData['meters'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final weatherStationList = (rawData['weatherStations'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return {
      'inverters': processDeviceList(inverterList),
      'meters': processDeviceList(meterList),
      'weatherStations': processDeviceList(weatherStationList),
    };
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Device Status', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kPrimaryColor),
      ),
      body: Column(
        children: [
          // Date Selector Card
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: DateSelector(
                selectedDate: _selectedDate,
                onDateSelected: _onDateSelected,
                pickerMode: DatePickerModeType.day,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _deviceStatusFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Could not fetch device status. ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kTextSecondaryColor),
                      ),
                    ),
                  );
                }

                final deviceStatusData = _transformData(snapshot.data!);
                final inverters = deviceStatusData['inverters']!;
                final meters = deviceStatusData['meters']!;
                final weatherStations = deviceStatusData['weatherStations']!;

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    _DeviceStatusCard(
                      title: 'Inverters',
                      total: inverters['total'],
                      devices: inverters['devices'],
                      statusCounts: inverters['statusCounts'],
                    ),
                    const SizedBox(height: 16),
                    _DeviceStatusCard(
                      title: 'Meters',
                      total: meters['total'],
                      devices: meters['devices'],
                      statusCounts: meters['statusCounts'],
                    ),
                    const SizedBox(height: 16),
                    _DeviceStatusCard(
                      title: 'Weather Stations',
                      total: weatherStations['total'],
                      devices: weatherStations['devices'],
                      statusCounts: weatherStations['statusCounts'],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceStatusCard extends StatefulWidget {
  final String title;
  final int total;
  final List<dynamic> devices;
  final Map<String, dynamic> statusCounts;


  const _DeviceStatusCard({
    required this.title,
    required this.total,
    required this.devices,
    required this.statusCounts,
  });

  @override
  State<_DeviceStatusCard> createState() => _DeviceStatusCardState();
}

class _DeviceStatusCardState extends State<_DeviceStatusCard> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${widget.total} Devices', style: const TextStyle(color: kTextSecondaryColor, fontSize: 14)),
                  ],
                ),
                // Status counts
                Row(
                  children: widget.statusCounts.entries.map((entry) {
                    final status = entry.key;
                    final count = entry.value;
                    final colors = statusPalette[status] ?? statusPalette['Unknown']!;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colors['bg'],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(color: colors['text'], fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
            const SizedBox(height: 24),
            // Pie Chart
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sectionsSpace: 4,
                  centerSpaceRadius: 50,
                  startDegreeOffset: -90,
                  sections: _buildChartSections(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (widget.devices.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.devices.map((device) {
                    final status = device['status'] as String? ?? 'Unknown';
                    final colors = statusPalette[status] ?? statusPalette['Unknown']!;
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors['bg'],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        device['name'] ?? 'Unknown Device',
                        style: TextStyle(
                          color: colors['text'],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections() {
    if (widget.total == 0) return [];

    int i = 0;
    return widget.statusCounts.entries.map((entry) {
      final isTouched = (i == touchedIndex);
      final radius = isTouched ? 35.0 : 25.0;
      final status = entry.key;
      final count = entry.value;
      final colors = statusPalette[status] ?? statusPalette['Unknown']!;
      final value = (count / widget.total) * 100;

      String title = '';
      if (isTouched) {
        final percentage = (count / widget.total) * 100;
        title = '$status: $count\n(${percentage.toStringAsFixed(1)}%)';
      }

      i++;

      return PieChartSectionData(
        value: value,
        color: colors['pieFill'],
        radius: radius,
        showTitle: isTouched,
        title: title,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();
  }
}


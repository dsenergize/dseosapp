import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/date_selector.dart';
import '../theme.dart';
import 'dart:math';

class RMSDashboardScreen extends StatefulWidget {
  final String? plantId;
  final String? plantName;

  const RMSDashboardScreen({Key? key, this.plantId, this.plantName}) : super(key: key);

  @override
  State<RMSDashboardScreen> createState() => _RMSDashboardScreenState();
}

class _RMSDashboardScreenState extends State<RMSDashboardScreen> {
  late Future<Map<String, dynamic>> dashboardFuture;
  late Future<List<Map<String, dynamic>>> alertsFuture;
  late Future<Map<String, dynamic>> sevenDayGenFuture;
  late Future<Map<String, dynamic>> powerVsIrradianceFuture;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _assignFutures();
  }

  void _assignFutures() {
    if (widget.plantId == null || widget.plantName == null) {
      dashboardFuture = Future.value({});
      alertsFuture = Future.value([]);
      sevenDayGenFuture = Future.value({});
      powerVsIrradianceFuture = Future.value({});
      developer.log("Plant ID or Plant Name is null. Cannot fetch data.", name: "RMSDashboardScreen");
      return;
    }

    dashboardFuture = ApiService.fetchRmsDashboard(
      plantId: widget.plantId,
      plantName: widget.plantName,
      date: _selectedDate,
    );
    alertsFuture = ApiService.fetchAlerts(
      plantId: widget.plantId,
      plantName: widget.plantName,
      date: _selectedDate,
    );
    sevenDayGenFuture = ApiService.fetchSevenDayGenerationChartData(
      widget.plantId!,
      _selectedDate,
    );
    powerVsIrradianceFuture = ApiService.fetchPowerVsIrradianceChartData(
      widget.plantId!,
      _selectedDate,
    );
  }

  void _fetchDataAndRebuild() {
    setState(() {
      _assignFutures();
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _fetchDataAndRebuild();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.plantName ?? "RMS Dashboard", style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kPrimaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDataAndRebuild,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchDataAndRebuild(),
        color: kPrimaryColor,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Date Selector ---
            Card(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: DateSelector(
                  selectedDate: _selectedDate,
                  onDateSelected: _onDateSelected,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- KPIs and Data Cards ---
            FutureBuilder<Map<String, dynamic>>(
              future: dashboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Could not load dashboard KPIs.'));
                }
                final data = snapshot.data!;
                return Column(
                  children: [
                    _buildKpiGrid(data),
                    const SizedBox(height: 16),
                    _buildInfoCardGroup(
                      title: 'Performance & Export',
                      icon: Icons.show_chart,
                      data: {
                        'Daily Export': {'value': data['totalDailyEnergy'], 'unit': 'kWh'},
                        'Daily Yield': {'value': data['specificYield'], 'unit': ''},
                        'DC CUF': {'value': data['dcCuf'], 'unit': '%'},
                        'AC CUF': {'value': data['acCuf'], 'unit': '%'},
                        'Peak Power': {'value': data['peakPower'], 'unit': 'kW'},
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCardGroup(
                      title: 'Solar Irradiance',
                      icon: Icons.wb_sunny_outlined,
                      data: {
                        'POA Insolation': {'value': data['poaInsolation'], 'unit': 'Wh/m²'},
                        'GHI Average': {'value': data['ghiAverage'], 'unit': 'W/m²'},
                        'Peak Insolation': {'value': data['Peak_POA_Radiation'], 'unit': 'W/m²'},
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCardGroup(
                      title: 'Weather & Impact',
                      icon: Icons.thermostat,
                      data: {
                        'Max Module Temp': {'value': data['maxModuleTemp'], 'unit': '°C'},
                        'Max Ambient Temp': {'value': data['maxAmbientTemp'], 'unit': '°C'},
                        'Avg. Wind Speed': {'value': data['avgWindSpeed'], 'unit': 'm/s'},
                        'Prevented CO2': {'value': data['preventedCo2'], 'unit': 'Tonnes'},
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // --- Inverter Details Table ---
            _buildSectionHeader('Inverter Status'),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: alertsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: kPrimaryColor)));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading inverter status: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Text('No inverter data found.'),
                  ));
                }
                return _InverterStatusSection(alerts: snapshot.data!);
              },
            ),
            const SizedBox(height: 24),

            // --- Smart Alerts Dropdown ---
            _buildSectionHeader('Smart Alerts'),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: alertsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: kPrimaryColor)));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading alerts: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Card(child: ListTile(title: Text('No alerts to display.')));
                }

                final problemAlerts = snapshot.data!.where((a) => a['status'] != 'Generating' && a['status'] != 'Sleeping').toList();

                return Card(
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ExpansionTile(
                    title: Text("View ${problemAlerts.length} Active Alerts"),
                    children: [
                      if (problemAlerts.isEmpty)
                        const ListTile(title: Text('No active alerts.'))
                      else
                        _AlertsList(alerts: problemAlerts)
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // --- Charts ---
            _buildSectionHeader('Last 7 Days Generation'),
            _buildChartSection(sevenDayGenFuture, (data) => _SevenDayGenChart(chartData: data)),
            const SizedBox(height: 24),

            _buildSectionHeader('Live Power vs Irradiance'),
            _buildChartSection(
                powerVsIrradianceFuture,
                    (data) => _PowerVsIrradianceChart(chartData: data)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title){
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildKpiGrid(Map<String, dynamic> data) {
    num? safeParseNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value);
      return null;
    }

    final kpis = [
      {'title': 'Inverters Energy', 'value': safeParseNum(data['totalDailyEnergy']), 'unit': 'kWh', 'icon': Icons.flash_on, 'color': Colors.blue.shade300},
      {'title': 'Live Power', 'value': safeParseNum(data['livePower']), 'unit': 'W', 'icon': Icons.power, 'color': Colors.green.shade300},
      {'title': 'Performance Ratio', 'value': safeParseNum(data['dayPR']), 'unit': '%', 'icon': Icons.show_chart, 'color': Colors.amber.shade300},
      {'title': 'Lifetime Energy', 'value': safeParseNum(data['lifetimeEnergy']), 'unit': 'kWh', 'icon': Icons.storage, 'color': Colors.purple.shade300},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final kpi = kpis[index];
        return _KpiCard(
          title: kpi['title'] as String,
          value: kpi['value'] as num?,
          unit: kpi['unit'] as String,
          icon: kpi['icon'] as IconData,
          color: kpi['color'] as Color,
        );
      },
    );
  }

  Widget _buildInfoCardGroup({required String title, required IconData icon, required Map<String, Map<String, dynamic>> data}) {
    return Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))
              ),
              child: Row(
                children: [
                  Icon(icon, color: kTextSecondaryColor),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: data.entries.map((entry) {
                  num? value = entry.value['value'];
                  String unit = entry.value['unit'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(color: kTextSecondaryColor)),
                        Text(
                            '${value != null ? value.toStringAsFixed(2) : '--'} $unit',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        )
    );
  }

  Widget _buildChartSection(Future future, Widget Function(dynamic data) chartBuilder) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 400,
        child: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading chart data: ${snapshot.error}'));
            }
            if (!snapshot.hasData || (snapshot.data is List && snapshot.data.isEmpty) || (snapshot.data is Map && (snapshot.data as Map).isEmpty)) {
              return const Center(child: Text('No chart data available.'));
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: chartBuilder(snapshot.data!),
            );
          },
        ),
      ),
    );
  }
}

// --- WIDGETS ---

class _KpiCard extends StatelessWidget {
  final String title;
  final num? value;
  final String unit;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.title, this.value, required this.unit, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: color,
              foregroundColor: Colors.white,
              child: Icon(icon, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color.withBlue(max(0, color.blue - 50)).withGreen(max(0, color.green - 50)), fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${value?.toStringAsFixed(2) ?? '--'} $unit',
                  style: TextStyle(
                    color: color.withBlue(max(0, color.blue - 100)).withGreen(max(0, color.green- 100)),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsList extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  const _AlertsList({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: alerts.map((alert) {
        return ListTile(
          leading: Icon(Icons.error_outline, color: Colors.red.shade400),
          title: Text(alert['name'] ?? 'N/A'),
          subtitle: Text(
            alert['status'] ?? 'Unknown',
            style: TextStyle(color: Colors.red.shade700),
          ),
          trailing: Text("N/A", style: TextStyle(color: Colors.grey.shade600)),
        );
      }).toList(),
    );
  }
}

class _InverterStatusSection extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  const _InverterStatusSection({required this.alerts});

  @override
  Widget build(BuildContext context) {

    final statusCounts = <String, int>{};
    for(var alert in alerts){
      final status = alert['status'] ?? 'Unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    final kpis = [
      {'title': 'Generating', 'icon': Icons.flash_on, 'color': Colors.green, 'count': statusCounts['Generating'] ?? 0},
      {'title': 'Under Performance', 'icon': Icons.arrow_downward, 'color': Colors.orange, 'count': statusCounts['Under Performance'] ?? 0},
      {'title': 'Sleeping', 'icon': Icons.nightlight_round, 'color': Colors.grey, 'count': statusCounts['Sleeping'] ?? 0},
      {'title': 'Not Operational', 'icon': Icons.warning_amber_rounded, 'color': Colors.yellow.shade700, 'count': statusCounts['Not Operational'] ?? 0},
      {'title': 'Comm. Failure', 'icon': Icons.signal_wifi_off, 'color': Colors.red, 'count': statusCounts['Communication Failed'] ?? 0},
    ];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8
          ),
          itemCount: kpis.length,
          itemBuilder: (context, index) {
            final kpi = kpis[index];
            return Card(
              elevation: 0,
              color: (kpi['color'] as Color).withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: (kpi['color'] as Color).withOpacity(0.3))
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(kpi['icon'] as IconData, color: kpi['color'] as Color, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    (kpi['count'] as int).toString(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kpi['color'] as Color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kpi['title'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: (kpi['color'] as Color).withOpacity(0.8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            height: 350,
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Inverter Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('C Load (kW)', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('AC Load (kW)', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Daily Energy (kWh)', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Specific Yield', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Efficiency', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: alerts.map((alert) => DataRow(
                      cells: [
                        DataCell(Text(alert['name'] ?? 'N/A')),
                        DataCell(Text(alert['cLoad']?.toString() ?? '-')),
                        DataCell(Text(alert['acLoad']?.toString() ?? '-')),
                        DataCell(Text(alert['dailyEnergy']?.toString() ?? '-')),
                        DataCell(Text(alert['specificYield']?.toString() ?? '-')),
                        DataCell(Text(alert['efficiency']?.toString() ?? '-')),
                        DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: (alert['status'] == 'Communication Failed') ? Colors.red.shade100 : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12)
                              ),
                              child: Text(
                                  alert['status'] ?? 'Unknown',
                                  style: TextStyle(color: (alert['status'] == 'Communication Failed') ? Colors.red.shade800 : Colors.green.shade800, fontWeight: FontWeight.w500)
                              ),
                            )
                        ),
                      ]
                  )).toList(),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}


class _SevenDayGenChart extends StatefulWidget {
  final Map<String, dynamic> chartData;
  const _SevenDayGenChart({required this.chartData});

  @override
  State<_SevenDayGenChart> createState() => _SevenDayGenChartState();
}

class _SevenDayGenChartState extends State<_SevenDayGenChart> {
  late Map<String, bool> _visibleSeries;

  final Map<String, dynamic> _seriesConfig = {
    'deemedGeneration': {'label': 'Deemed Generation', 'unit': 'kWh', 'color': Colors.green, 'isBar': true},
    'totalDailyEnergy': {'label': 'Daily Energy', 'unit': 'kWh', 'color': Colors.lightGreen, 'isBar': true},
    'totalDailyExport': {'label': 'Daily Export', 'unit': 'kWh', 'color': Colors.blue, 'isBar': false},
    'poaInsolation': {'label': 'POA Insolation', 'unit': 'kWh/m²', 'color': Colors.orange, 'isBar': false},
    'prMeter': {'label': 'PR Meters', 'unit': '%', 'color': Colors.purple, 'isBar': false},
  };

  @override
  void initState() {
    super.initState();
    _visibleSeries = {
      for (var item in _seriesConfig.keys) item: true,
    };
  }

  void _showFullScreenChart() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return _FullScreenChart(
        title: "Last 7 Days Generation",
        chartData: widget.chartData,
        seriesConfig: _seriesConfig,
        chartBuilder: (data, visibleSeries) => _buildChartContent(data, visibleSeries),
      );
    }));
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: _showFullScreenChart,
              tooltip: "View in full screen",
            ),
          ],
        ),
        Expanded(child: _buildChartContent(widget.chartData, _visibleSeries)),
        const SizedBox(height: 12),
        _buildLegend(),
      ],
    );
  }

  Widget _buildChartContent(Map<String, dynamic> data, Map<String, bool> visibleSeries) {
    final labels = (data['labels'] as List? ?? []).cast<String>();
    if (labels.isEmpty) return const Center(child: Text("No data for this period."));

    return BarChart(
      BarChartData(
        barGroups: _buildBarGroups(labels, data, visibleSeries),
        barTouchData: _buildBarTouchData(labels),
        titlesData: _buildTitles(labels),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xffe7e8ec), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<String> labels, Map<String, dynamic> data, Map<String, bool> visibleSeries) {
    final barKeys = _seriesConfig.keys.where((key) => _seriesConfig[key]['isBar'] && visibleSeries[key]!).toList();
    final barWidth = 8.0;
    final space = 4.0;

    return List.generate(labels.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: List.generate(barKeys.length, (barIndex) {
          final key = barKeys[barIndex];
          final series = data[key] as List? ?? [];
          return BarChartRodData(
            toY: (series.length > index ? (series[index] as num) : 0).toDouble(),
            color: _seriesConfig[key]['color'],
            width: barWidth,
            borderRadius: BorderRadius.zero,
          );
        }),
        barsSpace: space,
      );
    });
  }

  BarTouchData _buildBarTouchData(List<String> labels) {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.9),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          List<TextSpan> children = [];

          _seriesConfig.forEach((key, config) {
            if (_visibleSeries[key]!) {
              final seriesData = (widget.chartData[key] as List? ?? []).cast<num>();
              if (seriesData.length > groupIndex) {
                children.add(
                    TextSpan(
                        text: '\n${config['label']}: ',
                        style: TextStyle(color: config['color'], fontWeight: FontWeight.bold, fontSize: 12),
                        children: [
                          TextSpan(
                              text: '${seriesData[groupIndex].toStringAsFixed(2)} ${config['unit']}',
                              style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12))
                        ]));
              }
            }
          });

          return BarTooltipItem(
              '${labels[groupIndex]}',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              children: children);
        },
      ),
    );
  }

  FlTitlesData _buildTitles(List<String> labels) {
    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < labels.length && index % (labels.length / 7).ceil() == 0) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 4,
                child: Text(labels[index], style: const TextStyle(fontSize: 10)),
              );
            }
            return const Text('');
          },
        ),
      ),
    );
  }


  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: _seriesConfig.entries.map((entry) {
        final key = entry.key;
        final config = entry.value;
        final isSelected = _visibleSeries[key]!;

        return GestureDetector(
          onTap: () {
            setState(() {
              _visibleSeries[key] = !isSelected;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: config['isBar'] ? 12 : 2,
                color: isSelected ? config['color'] : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                config['label'],
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.black87 : Colors.grey,
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PowerVsIrradianceChart extends StatefulWidget {
  final Map<String, dynamic> chartData;
  const _PowerVsIrradianceChart({required this.chartData});

  @override
  State<_PowerVsIrradianceChart> createState() => _PowerVsIrradianceChartState();
}

class _PowerVsIrradianceChartState extends State<_PowerVsIrradianceChart> {
  late Map<String, bool> _visibleSeries;

  final List<Map<String, dynamic>> _seriesConfig = [
    {'key': 'solarPower', 'label': 'Solar Power', 'unit': 'kW', 'color': Colors.orange, 'scale': 0.001},
    {'key': 'acPower', 'label': 'AC Power', 'unit': 'kW', 'color': Colors.teal, 'scale': 0.001},
    {'key': 'poaRadiation', 'label': 'POA Radiation', 'unit': 'W/m²', 'color': Colors.amber, 'scale': 1.0},
    {'key': 'ambientTemp', 'label': 'Ambient Temp', 'unit': '°C', 'color': Colors.purple, 'scale': 0.1},
  ];

  void _showFullScreenChart() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return _FullScreenChart(
        title: "Live Power vs Irradiance",
        chartData: widget.chartData,
        seriesConfig: _seriesConfig,
        chartBuilder: (data, visibleSeries) => _buildChartContent(data, visibleSeries),
      );
    }));
  }

  @override
  void initState() {
    super.initState();
    _visibleSeries = {
      for (var item in _seriesConfig) item['key']: true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: _showFullScreenChart,
              tooltip: "View in full screen",
            ),
          ],
        ),
        Expanded(child: _buildChartContent(widget.chartData, _visibleSeries)),
        const SizedBox(height: 12),
        _buildLegend(),
      ],
    );
  }

  Widget _buildChartContent(Map<String, dynamic> data, Map<String, bool> visibleSeries) {
    final longestSeries = (_seriesConfig.map((c) => (data[c['key']] as List? ?? [])).toList()
      ..sort((a,b) => b.length.compareTo(a.length)))
        .first.cast<Map<String, dynamic>>();

    if (longestSeries.isEmpty) return const Center(child: Text("No data for this period."));

    return LineChart(
      LineChartData(
        lineBarsData: _buildLineBars(data, visibleSeries),
        titlesData: _buildTitles(longestSeries),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xffe7e8ec), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: _buildLineTouchData(visibleSeries),
      ),
    );
  }

  List<LineChartBarData> _buildLineBars(Map<String, dynamic> data, Map<String, bool> visibleSeries) {
    return _seriesConfig.where((s) => visibleSeries[s['key']] == true).map((sConfig) {
      final dataList = (data[sConfig['key']] as List? ?? []).cast<Map<String,dynamic>>();
      final spots = dataList.asMap().entries.map((entry) {
        final val = entry.value['value'];
        return FlSpot(entry.key.toDouble(), (val is num ? val : 0.0).toDouble() * sConfig['scale']);
      }).toList();

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: sConfig['color'],
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [sConfig['color'].withOpacity(0.3),sConfig['color'].withOpacity(0.0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );
    }).toList();
  }

  LineTouchData _buildLineTouchData(Map<String, bool> visibleSeries) {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.8),
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((touchedSpot) {
            final seriesIndex = touchedSpot.barIndex;
            final visibleSeriesList = _seriesConfig.where((s) => visibleSeries[s['key']] == true).toList();
            if (seriesIndex >= visibleSeriesList.length) return null;

            final config = visibleSeriesList[seriesIndex];
            final unit = config['unit'];

            return LineTooltipItem(
              '${config['label']}: ',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: touchedSpot.y.toStringAsFixed(2),
                  style: TextStyle(color: config['color']),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            );
          }).toList();
        },
      ),
    );
  }

  FlTitlesData _buildTitles(List<Map<String,dynamic>> longestSeries) {
    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: max(1, (longestSeries.length / 6).floorToDouble()),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < longestSeries.length) {
              if (index % max(1, (longestSeries.length / 6).floor()) == 0) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Text(longestSeries[index]['time'] ?? '', style: const TextStyle(fontSize: 10)),
                );
              }
            }
            return const Text('');
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: _seriesConfig.map((config) {
        final key = config['key'];
        final isSelected = _visibleSeries[key]!;

        return GestureDetector(
          onTap: () {
            setState(() {
              _visibleSeries[key] = !isSelected;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 2,
                color: isSelected ? config['color'] : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                config['label'],
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.black87 : Colors.grey,
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _FullScreenChart extends StatefulWidget {
  final String title;
  final Map<String, dynamic> chartData;
  final dynamic seriesConfig;
  final Widget Function(Map<String, dynamic> data, Map<String, bool> visibleSeries) chartBuilder;

  const _FullScreenChart({required this.title, required this.chartData, required this.seriesConfig, required this.chartBuilder});

  @override
  State<_FullScreenChart> createState() => _FullScreenChartState();
}

class _FullScreenChartState extends State<_FullScreenChart> {
  late Map<String, bool> _visibleSeries;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    if (widget.seriesConfig is Map) {
      _visibleSeries = {
        for (var item in (widget.seriesConfig as Map).keys) item: true,
      };
    } else if (widget.seriesConfig is List) {
      _visibleSeries = {
        for (var item in (widget.seriesConfig as List<Map<String,dynamic>>)) item['key']: true,
      };
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(child: widget.chartBuilder(widget.chartData, _visibleSeries)),
              const SizedBox(height: 12),
              _buildLegend(),
            ],
          ),
        )
    );
  }

  Widget _buildLegend() {
    List<Widget> legendItems = [];
    if(widget.seriesConfig is Map) {
      legendItems = (widget.seriesConfig as Map<String,dynamic>).entries.map((entry) {
        final key = entry.key;
        final config = entry.value;
        final isSelected = _visibleSeries[key]!;

        return GestureDetector(
          onTap: () => setState(() => _visibleSeries[key] = !isSelected),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 12, height: config['isBar'] ?? false ? 12 : 2, color: isSelected ? config['color'] : Colors.grey),
              const SizedBox(width: 4),
              Text(config['label'], style: TextStyle(fontSize: 12, color: isSelected ? Colors.black87 : Colors.grey)),
            ],
          ),
        );
      }).toList();
    } else if (widget.seriesConfig is List) {
      legendItems = (widget.seriesConfig as List<Map<String,dynamic>>).map((config) {
        final key = config['key'];
        final isSelected = _visibleSeries[key]!;

        return GestureDetector(
          onTap: () => setState(() => _visibleSeries[key] = !isSelected),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 12, height: 2, color: isSelected ? config['color'] : Colors.grey),
              const SizedBox(width: 4),
              Text(config['label'], style: TextStyle(fontSize: 12, color: isSelected ? Colors.black87 : Colors.grey)),
            ],
          ),
        );
      }).toList();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: legendItems,
    );
  }
}

               
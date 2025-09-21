import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/info_card.dart';
import '../widgets/inverter_table.dart';
import '../widgets/line_chart.dart';
import '../widgets/bar_chart.dart';
import '../widgets/date_selector.dart';
import '../widgets/rms_dashboard_table.dart';
import '../theme.dart';

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
  late Future<List<Map<String, dynamic>>> dailyEnergyFuture;
  late Future<List<Map<String, dynamic>>> poaRadiationFuture;
  late Future<List<Map<String, dynamic>>> ambientTempFuture;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _assignFutures();
  }

  void _assignFutures() {
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
    dailyEnergyFuture = ApiService.fetchDailyEnergy(
      widget.plantId!,
      _selectedDate,
    );
    poaRadiationFuture = ApiService.fetchPoaRadiation(
      widget.plantId!,
      widget.plantName!,
      _selectedDate,
    );
    ambientTempFuture = ApiService.fetchAmbientTemp(
      widget.plantId!,
      widget.plantName!,
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
      appBar: AppBar(
        title: Text(widget.plantName ?? "RMS Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDataAndRebuild,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchDataAndRebuild();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DateSelector(
                  selectedDate: _selectedDate,
                  onDateSelected: _onDateSelected,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: FutureBuilder<Map<String, dynamic>>(
                future: dashboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: kPrimaryColor)));
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  final data = snapshot.data!;
                  return _buildKpiGrid(data);
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Text('Smart Alerts', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: FutureBuilder<List<Map<String, dynamic>>>(
                future: alertsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(child: Center(child: Text('Error loading alerts: ${snapshot.error}', style: const TextStyle(color: Colors.red))));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SliverToBoxAdapter(child: Center(child: Text('No alerts found for this date.')));
                  }
                  final alerts = snapshot.data!;
                  return InverterTable(inverterData: alerts);
                },
              ),
            ),
            _buildChartSection('Inverter Energy vs Yield', dailyEnergyFuture, (data) => LineChartWidget(data: data)),
            _buildChartSection('Live Weather Comparison', poaRadiationFuture, (data) => BarChartWidget(data: data)),

          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid(Map<String, dynamic> data) {

    num? safeParseNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value);
      return null;
    }

    final totalDailyEnergy = safeParseNum(data['totalDailyEnergy']);
    final dayPR = safeParseNum(data['dayPR']);
    final peakPOARadiation = safeParseNum(data['Peak_POA_Radiation']);
    final dcCapacity = safeParseNum(data['dcCapacity']);

    final kpis = [
      {'title': 'Total Daily Energy', 'value': totalDailyEnergy, 'unit': 'kWh', 'icon': Icons.energy_savings_leaf_outlined, 'color': Colors.green},
      {'title': 'Day PR', 'value': dayPR, 'unit': '%', 'icon': Icons.bolt_outlined, 'color': Colors.blue},
      {'title': 'Peak POA Radiation', 'value': peakPOARadiation, 'unit': 'W/m²', 'icon': Icons.wb_sunny_outlined, 'color': Colors.orange},
      {'title': 'DC Capacity', 'value': dcCapacity, 'unit': 'kW', 'icon': Icons.electrical_services_outlined, 'color': Colors.purple},
    ];

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final kpi = kpis[index];
          return InfoCard(
            title: kpi['title'] as String,
            value: kpi['value'],
            unit: kpi['unit'] as String,
            icon: kpi['icon'] as IconData,
            iconBgColor: kpi['color'] as Color,
          );
        },
        childCount: kpis.length,
      ),
    );
  }

  Widget _buildChartSection(String title, Future<List<Map<String, dynamic>>> future, Widget Function(List<Map<String,dynamic>> data) chartBuilder) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading chart data: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No chart data available.'));
                  }
                  return chartBuilder(snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


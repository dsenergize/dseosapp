import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/info_card.dart';
import '../widgets/inverter_table.dart';
import '../widgets/line_chart.dart';
import '../widgets/bar_chart.dart';
import '../widgets/date_selector.dart';
import '../widgets/rms_dashboard_kpis_and_table.dart';

const kBlueColor = Color(0xFF0075B2);

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
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: kBlueColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.plantName != null)
              Text(
                widget.plantName!,
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            Text(
              "RMS Dashboard",
              style: GoogleFonts.roboto(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchDataAndRebuild,
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: () {
              // Implement filter action if needed
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchDataAndRebuild();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: DateSelector(
                      selectedDate: _selectedDate,
                      onDateSelected: _onDateSelected,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                    label: const Text("Edit", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Implement edit functionality
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FutureBuilder<Map<String, dynamic>>(
                future: dashboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kBlueColor));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No dashboard data available.'));
                  }

                  // ===== THE ONLY CHANGE IS HERE =====
                  // Use the snapshot data directly, as ApiService already extracted the inner map.
                  final Map<String, dynamic> data = snapshot.data!;

                  return RmsDashboardKpisAndTable(data: data);
                },
              ),
              const SizedBox(height: 24),
              Text('Smart Alert', style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: alertsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading alerts: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No alerts found for this date.'));
                  }
                  final alerts = snapshot.data!;
                  return InverterTable(inverterData: alerts);
                },
              ),
              const SizedBox(height: 24),
              Text('Inverter Energy vs Yield Graph', style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: dailyEnergyFuture,
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
                    return LineChartWidget(data: snapshot.data!);
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text('Live Weather Comparison', style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: poaRadiationFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading weather data: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No weather data available.'));
                    }
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: ambientTempFuture,
                      builder: (context, ambientSnapshot) {
                        if (ambientSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (ambientSnapshot.hasError) {
                          return Center(child: Text('Error loading ambient temp data: ${ambientSnapshot.error}'));
                        }
                        final poaData = snapshot.data!;
                        final ambientData = ambientSnapshot.data ?? [];

                        final combinedData = poaData.map((poaItem) {
                          final matchingAmbient = ambientData.firstWhere(
                                (ambientItem) => ambientItem['time'] == poaItem['time'],
                            orElse: () => {'ambientTemp': 0.0},
                          );
                          return {
                            'time': poaItem['time'],
                            'radiation': poaItem['poa'],
                            'ambientTemp': matchingAmbient['ambientTemp'],
                          };
                        }).toList();

                        return BarChartWidget(data: combinedData);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

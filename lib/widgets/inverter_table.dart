import 'package:flutter/material.dart';
import 'alert_card.dart';

class InverterTable extends StatelessWidget {
  final List<Map<String, dynamic>> inverterData;

  const InverterTable({
    Key? key,
    required this.inverterData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (inverterData.isEmpty) {
      return const SliverToBoxAdapter(
          child: Center(child: Text('No inverter data available.')));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: AlertCard(alert: inverterData[index]),
          );
        },
        childCount: inverterData.length,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;

  const AlertCard({Key? key, required this.alert}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = alert['name'] ?? 'Unknown Device';
    final String status = alert['status'] ?? 'No Status';

    final bool isFailed = status.toLowerCase().contains('fail');
    final Color statusColor = isFailed ? Colors.red : Colors.green;
    final IconData statusIcon =
    isFailed ? Icons.error_outline : Icons.check_circle_outline;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          status,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
        ),
        trailing: const Text(
          'N/A', // Placeholder as in the screenshot
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
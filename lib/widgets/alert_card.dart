import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

class AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;

  const AlertCard({Key? key, required this.alert}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = alert['name'] ?? 'Unknown Device';
    final String status = alert['status'] ?? 'No Status';
    final String timestampStr = alert['timestamp'] ?? '';
    String formattedTime = 'N/A';

    if (timestampStr.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(timestampStr);
        formattedTime = DateFormat('MMM dd, hh:mm a').format(dateTime);
      } catch (e) {
        // Handle parsing errors silently
      }
    }

    final bool isGenerating = status.toLowerCase() == 'generating';
    final Color statusColor = isGenerating ? Colors.green : Colors.red;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isGenerating ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
            color: statusColor,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          status,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          formattedTime,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

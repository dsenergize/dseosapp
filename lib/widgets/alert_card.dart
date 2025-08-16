import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
        formattedTime = DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
      } catch (e) {
        // Handle potential parsing errors
      }
    }

    final Color statusColor = status.toLowerCase() == 'generating' ? Colors.green : Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Status: $status',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formattedTime,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

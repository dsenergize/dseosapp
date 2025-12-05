import 'package:flutter/material.dart';
import '../theme.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final dynamic value;
  final String unit;
  final IconData icon;
  final Color iconBgColor;

  const InfoCard({
    Key? key,
    required this.title,
    required this.value,
    this.unit = '',
    required this.icon,
    this.iconBgColor = kPrimaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String displayValue;
    if (value == null) {
      displayValue = 'N/A';
    } else if (value is double) {
      displayValue = value.toStringAsFixed(2);
    } else {
      displayValue = value.toString();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconBgColor, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: kTextColor),
                    children: [
                      TextSpan(text: displayValue),
                      TextSpan(
                        text: ' ${displayValue != 'N/A' ? unit : ''}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: kTextSecondaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

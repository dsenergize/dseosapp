import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

class DateSelector extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const DateSelector({
    Key? key,
    this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // New accent color
    const accentColor = Color(0xFF005aa4);

    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: accentColor, // Using the new accent color
                  onPrimary: Colors.white,
                  onSurface: kTextColor,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.calendar_today_outlined, color: accentColor), // Using the new accent color
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedDate != null
                    ? DateFormat('MMMM dd, yyyy').format(selectedDate!)
                    : 'Select a Date',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: kTextSecondaryColor),
          ],
        ),
      ),
    );
  }
}


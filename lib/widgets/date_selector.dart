import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

// Enum to define the picker's behavior and display format.
enum DatePickerModeType { day, month, year }

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DatePickerModeType pickerMode;

  const DateSelector({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    this.pickerMode = DatePickerModeType.day,
  }) : super(key: key);

  // Formats the date display based on the current picker mode.
  String _getFormattedDate() {
    switch (pickerMode) {
      case DatePickerModeType.day:
        return DateFormat('dd/MM/yyyy').format(selectedDate); // e.g., 14/07/2025
      case DatePickerModeType.month:
        return DateFormat('MM/yy').format(selectedDate); // e.g., 07/25
      case DatePickerModeType.year:
        return DateFormat('yyyy').format(selectedDate); // e.g., 2025
    }
  }

  // Shows the appropriate date picker based on the current mode.
  Future<void> _selectDate(BuildContext context) async {
    switch (pickerMode) {
      case DatePickerModeType.day:
        _showDayPicker(context);
        break;
      case DatePickerModeType.month:
        _showMonthPicker(context);
        break;
      case DatePickerModeType.year:
        _showYearPicker(context);
        break;
    }
  }

  // Standard day picker
  Future<void> _showDayPicker(BuildContext context) async {
    const accentColor = Color(0xFF005aa4);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: accentColor,
              onPrimary: Colors.white,
              onSurface: kTextColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }

  // Custom month picker dialog
  Future<void> _showMonthPicker(BuildContext context) async {
    const accentColor = Color(0xFF005aa4);
    DateTime tempDate = selectedDate;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: 300,
                height: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: accentColor,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                tempDate = DateTime(tempDate.year - 1, tempDate.month);
                              });
                            },
                          ),
                          Text(
                            DateFormat.y().format(tempDate),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                tempDate = DateTime(tempDate.year + 1, tempDate.month);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 4,
                        children: List.generate(12, (index) {
                          final month = DateTime(tempDate.year, index + 1);
                          return InkWell(
                            onTap: () {
                              onDateSelected(month);
                              Navigator.of(context).pop();
                            },
                            child: Center(
                              child: Text(DateFormat.MMM().format(month)),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Year-only picker
  Future<void> _showYearPicker(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Year"),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              selectedDate: selectedDate,
              onChanged: (DateTime dateTime) {
                onDateSelected(dateTime);
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF005aa4);

    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.calendar_today_outlined, color: accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getFormattedDate(),
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: kTextSecondaryColor),
          ],
        ),
      ),
    );
  }
}


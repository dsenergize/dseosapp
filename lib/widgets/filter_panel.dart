import 'package:flutter/material.dart';

// A simple utility to format data keys into readable labels.
String _formatFilterName(String key) {
  if (key.isEmpty) return '';
  // Add spaces before capital letters, then capitalize the first letter.
  String spaced = key.replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]'), (match) => ' ${match.group(0)}');
  return spaced[0].toUpperCase() + spaced.substring(1);
}

class FilterPanel extends StatelessWidget {
  final List<String> availableFilters;
  final Set<String> activeFilters;
  final Function(Set<String>) onFilterChanged;
  final Color Function(String) getColorForSeries;

  const FilterPanel({
    Key? key,
    required this.availableFilters,
    required this.activeFilters,
    required this.onFilterChanged,
    required this.getColorForSeries,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (availableFilters.isEmpty) {
      return const SizedBox(width: 0); // Don't show panel if no filters
    }

    return Container(
      width: 150,
      padding: const EdgeInsets.only(left: 12),
      child: ListView.builder(
        itemCount: availableFilters.length,
        itemBuilder: (context, index) {
          final filterKey = availableFilters[index];
          final isChecked = activeFilters.contains(filterKey);
          return CheckboxListTile(
            value: isChecked,
            onChanged: (bool? value) {
              final newFilters = Set<String>.from(activeFilters);
              if (value == true) {
                newFilters.add(filterKey);
              } else {
                newFilters.remove(filterKey);
              }
              onFilterChanged(newFilters);
            },
            title: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: getColorForSeries(filterKey),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatFilterName(filterKey),
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        },
      ),
    );
  }
}

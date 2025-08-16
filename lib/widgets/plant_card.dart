import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlantCard extends StatelessWidget {
  final String plantName;
  final String capacity;
  final VoidCallback onTap;

  const PlantCard({
    Key? key,
    required this.plantName,
    required this.capacity,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack( // Use a Stack to layer the arrow on top
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row for the icon and plant name at the top.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[300], // Reference yellow/orange
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.wb_sunny,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Expanded allows the text to wrap if it's too long.
                      Expanded(
                        child: Text(
                          plantName,
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF0075B2), // Reference blue
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          // softWrap allows the text to wrap to the next line.
                          softWrap: true,
                          maxLines: 2, // Allow up to 2 lines for the name
                        ),
                      ),
                    ],
                  ),
                  const Spacer(), // Pushes the capacity down from the top
                  // Centered Row for capacity.
                  Center(
                    child: Text(
                      'Capacity: $capacity kW',
                      style: GoogleFonts.roboto(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(), // Pushes the capacity up from the bottom
                ],
              ),
            ),
            // Positioned forward arrow at the bottom right corner
            Positioned(
              bottom: 16,
              right: 16,
              child: Icon(
                Icons.arrow_forward, // Bolder arrow icon
                color: Colors.black, // Changed color to black
                size: 20, // Slightly increased size
              ),
            ),
          ],
        ),
      ),
    );
  }
}

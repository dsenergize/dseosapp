import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RmsCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData iconData;
  final Color iconBgColor;

  const RmsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.iconData,
    required this.iconBgColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row for the icon and title at the top.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        iconData,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.roboto(
                          color: const Color(0xFF0075B2),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        softWrap: true,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Centered Row for value and unit.
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.roboto(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                      children: [
                        TextSpan(text: value),
                        TextSpan(
                          text: ' $unit',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          // Positioned forward arrow at the bottom right corner
          Positioned(
            bottom: 16,
            right: 16,
            child: Icon(
              Icons.arrow_forward,
              color: Colors.black,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
//
// const kBlueColor = Color(0xFF0075B2);
// const kYellowColor = Color(0xFFE3A72F);
//
// final appTheme = ThemeData(
//   brightness: Brightness.light,
//   scaffoldBackgroundColor: kBlueColor,
//   primaryColor: kBlueColor,
//   colorScheme: const ColorScheme.light(
//     primary: kBlueColor,
//     secondary: kYellowColor,
//     background: kBlueColor,
//   ),
//   appBarTheme: const AppBarTheme(
//     backgroundColor: kBlueColor,
//     elevation: 0,
//     iconTheme: IconThemeData(color: Colors.white),
//     titleTextStyle: TextStyle(
//       color: Colors.white,
//       fontSize: 20,
//       fontWeight: FontWeight.bold,
//     ),
//   ),
//   bottomNavigationBarTheme: BottomNavigationBarThemeData(
//     backgroundColor: kBlueColor,
//     selectedItemColor: kYellowColor,
//     unselectedItemColor: Colors.white,
//     showUnselectedLabels: true,
//   ),
//   inputDecorationTheme: const InputDecorationTheme(
//     filled: true,
//     fillColor: Colors.white,
//     border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
//     labelStyle: TextStyle(color: Colors.grey),
//   ),
//   textTheme: const TextTheme(
//     bodyMedium: TextStyle(color: Colors.black),
//   ),
// );
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Color Palette ---
const kPrimaryColor = Color(0xFF005aa4); // New Accent Blue
const kSecondaryColor = Color(0xFF16a34a); // Accent Green from image
const kBackgroundColor = Color(0xFFF7F9FB); // Light background
const kCardColor = Colors.white;
const kTextColor = Color(0xFF212121); // Darker text for readability
const kTextSecondaryColor = Color(0xFF757575); // Lighter grey for subtitles
const kOutlineColor = Color(0xFFE0E0E0); // Border color

final appTheme = ThemeData(
  // --- General ---
  brightness: Brightness.light,
  scaffoldBackgroundColor: kBackgroundColor,
  primaryColor: kPrimaryColor,
  fontFamily: GoogleFonts.inter().fontFamily,

  // --- Color Scheme ---
  colorScheme: const ColorScheme.light(
    primary: kPrimaryColor,
    secondary: kSecondaryColor,
    background: kBackgroundColor,
    surface: kCardColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: kTextColor,
    onSurface: kTextColor,
    error: Colors.redAccent,
    onError: Colors.white,
  ),

  // --- Component Themes ---
  appBarTheme: AppBarTheme(
    backgroundColor: kBackgroundColor,
    elevation: 0,
    iconTheme: const IconThemeData(color: kTextColor),
    titleTextStyle: GoogleFonts.inter(
      color: kTextColor,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),

  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: kPrimaryColor,
    unselectedItemColor: kTextSecondaryColor,
    showUnselectedLabels: false,
    showSelectedLabels: false,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedIconTheme: const IconThemeData(size: 28),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: kCardColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    labelStyle: TextStyle(color: kTextSecondaryColor),
  ),

  cardTheme: CardThemeData(
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: .05),
    color: kCardColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),

  chipTheme: ChipThemeData(
    backgroundColor: kCardColor,
    selectedColor: kSecondaryColor,
    labelStyle: GoogleFonts.inter(
      color: kTextSecondaryColor,
      fontWeight: FontWeight.w600,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: kOutlineColor),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  ),

  // --- Text Theme ---
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
        fontSize: 34, fontWeight: FontWeight.bold, color: kTextColor),
    displayMedium: GoogleFonts.inter(
        fontSize: 28, fontWeight: FontWeight.bold, color: kTextColor),
    headlineMedium: GoogleFonts.inter(
        fontSize: 24, fontWeight: FontWeight.bold, color: kTextColor),
    titleLarge: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w600, color: kTextColor),
    titleMedium: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: kTextColor),
    bodyLarge: GoogleFonts.inter(fontSize: 16, color: kTextColor),
    bodyMedium: GoogleFonts.inter(fontSize: 14, color: kTextColor),
    bodySmall: GoogleFonts.inter(fontSize: 12, color: kTextSecondaryColor),
    labelLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
  ),
);

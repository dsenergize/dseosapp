import 'package:flutter/material.dart';

const kBlueColor = Color(0xFF0075B2);
const kYellowColor = Color(0xFFE3A72F);

final appTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: kBlueColor,
  primaryColor: kBlueColor,
  colorScheme: const ColorScheme.light(
    primary: kBlueColor,
    secondary: kYellowColor,
    background: kBlueColor,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kBlueColor,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: kBlueColor,
    selectedItemColor: kYellowColor,
    unselectedItemColor: Colors.white,
    showUnselectedLabels: true,
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
    labelStyle: TextStyle(color: Colors.grey),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.black),
  ),
);

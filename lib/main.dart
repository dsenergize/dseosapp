// import 'package:flutter/material.dart';
// import 'theme.dart';
// import 'screens/splash_screen.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'DS Energize',
//       theme: appTheme,
//       debugShowCheckedModeBanner: false,
//       home: const SplashScreen(),
//     );
//   }
// }


import 'package:flutter/material.dart';
// Make sure this is imported to use ensureInitialized
import 'package:flutter/widgets.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
// TODO: Import any services you are initializing
// import 'services/some_service.dart';

// 1. Make the main function async
Future<void> main() async {
  // 2. Ensure Flutter is ready before running any async code
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Put all your "heavy" startup tasks here
  //    The native splash screen will be shown while this runs.
  //    For example:
  //    await SomeService.initialize();
  //    await DatabaseService.connect();

  // This simulates a 2-second startup task
  await Future.delayed(const Duration(seconds: 2));

  // 4. Run the app AFTER all initialization is complete
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DS Energize',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
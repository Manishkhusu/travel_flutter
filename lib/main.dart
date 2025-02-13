import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

import 'package:flutter_xploverse/feature2/languagetranslator/translatorpg.dart';
import 'package:flutter_xploverse/feature2/splash/splash_screen.dart';
import 'package:flutter_xploverse/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      // Wrap TravelApp with ProviderScope
      child: TravelApp(),
    ),
  );
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key}); // Add the const constructor!
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false, // Add this line to remove the debug banner
      title: 'Travel App',
      theme: ThemeData(
        primaryColor: Colors.black,
        hintColor: Colors.yellow[700],
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          //Added const here
          displayLarge: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const SplashScreen(), //It could be good practice to make this const
    );
  }
}

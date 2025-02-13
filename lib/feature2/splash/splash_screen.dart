import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_xploverse/feature2/presentation/view/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  late AnimationController _textController;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    // Logo Zoom Animation
    _logoController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    );

    // Text Fade-In Animation
    _textController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    // Sequence Animations
    _logoController.forward().then((_) {
      _textController.forward();
    });

    // Navigate to Login Page after delay
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE), // Light Blue Background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _logoAnimation,
              child: const Icon(
                Icons.airplanemode_active, // Travel Icon
                size: 120,
                color: Color(0xFF29ABE2), // Sky Blue Color
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _textAnimation,
              child: const Column(
                children: [
                  Text(
                    'Travel',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF29ABE2), // Sky Blue Color
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Discover Your Journey',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors
                          .black54, // Darker text color for better readability
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

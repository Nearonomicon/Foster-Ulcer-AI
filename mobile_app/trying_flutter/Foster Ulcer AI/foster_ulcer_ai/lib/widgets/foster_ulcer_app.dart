import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:foster_ulcer_ai/widgets/main_navigation_screen.dart';

class FosterUlcerApp extends StatelessWidget {
  const FosterUlcerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foster Ulcer AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          primary: const Color(0xFF0D9488),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

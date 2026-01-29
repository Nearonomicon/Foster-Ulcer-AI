import 'package:flutter/material.dart';

// 🔽 IMPORTANT: package import (อย่าใช้ relative)
import 'package:flutter_application/core/theme/app_theme.dart';
import 'package:flutter_application/features/auth/screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FoasterApp());
}

class FoasterApp extends StatelessWidget {
  const FoasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Foaster',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const LoginScreen(),
    );
  }
}



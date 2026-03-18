import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_application/core/theme/app_theme.dart';
import 'package:flutter_application/features/auth/screens/login_screen.dart';

import 'package:flutter_application/shared/locale_controller.dart';
import 'package:flutter_application/shared/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleController(),
      child: const FoasterApp(),
    ),
  );
}

class FoasterApp extends StatelessWidget {
  const FoasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCtrl = context.watch<LocaleController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Foaster',

      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,

      // ✅ global locale
      locale: localeCtrl.locale,
      supportedLocales: AppLocalizations.supportedLocales,

      // ✅ MUST include Flutter's delegates (แก้ No MaterialLocalizations)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,

        AppLocalizations.delegate,
      ],

      home: const LoginScreen(),
    );
  }
}
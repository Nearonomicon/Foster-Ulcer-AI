import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_application/core/theme/app_theme.dart';
import 'package:flutter_application/features/auth/screens/login_screen.dart';
import 'package:flutter_application/features/auth/screens/notifications_screen.dart';

import 'package:flutter_application/shared/locale_controller.dart';
import 'package:flutter_application/shared/app_localizations.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

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
      navigatorKey: appNavigatorKey,
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

      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Stack(
          children: [
            if (child != null) child,
            Positioned(
              top: 12,
              right: 60,
              child: SafeArea(
                child: _GlobalNotificationButton(isDark: isDark),
              ),
            ),
          ],
        );
      },

      home: const LoginScreen(),
    );
  }
}

class _GlobalNotificationButton extends StatelessWidget {
  const _GlobalNotificationButton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          appNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF111827).withOpacity(0.92)
                : Colors.white.withOpacity(0.94),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.black.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.24 : 0.10),
                blurRadius: 16,
                spreadRadius: -8,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(Icons.notifications_none_rounded, size: 22),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

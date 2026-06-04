import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale.languageCode == locale.languageCode) return;
    _locale = locale;
    notifyListeners();
  }

  void toggle() {
    setLocale(_locale.languageCode == 'en' ? const Locale('my') : const Locale('en'));
  }

  String get code => _locale.languageCode.toUpperCase();
}
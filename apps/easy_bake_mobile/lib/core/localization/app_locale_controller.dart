import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<Locale?> appLocaleNotifier = ValueNotifier<Locale?>(null);

const _appLocaleKey = 'app.locale.languageCode';

Future<void> restoreAppLocaleFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final savedLanguageCode = prefs.getString(_appLocaleKey);

  if (savedLanguageCode == null || savedLanguageCode.isEmpty) {
    appLocaleNotifier.value = null;
    return;
  }

  appLocaleNotifier.value = Locale(savedLanguageCode);
}

Future<void> _persistAppLocale(Locale? locale) async {
  final prefs = await SharedPreferences.getInstance();

  if (locale == null) {
    await prefs.remove(_appLocaleKey);
    return;
  }

  await prefs.setString(_appLocaleKey, locale.languageCode);
}

void setAppLocale(Locale? locale) {
  appLocaleNotifier.value = locale;
  unawaited(_persistAppLocale(locale));
}

void useEnglishLocale() {
  setAppLocale(const Locale('en'));
}

void useHebrewLocale() {
  setAppLocale(const Locale('he'));
}

void clearAppLocale() {
  setAppLocale(null);
}

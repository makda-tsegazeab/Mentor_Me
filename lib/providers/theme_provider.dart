import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;
  String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ThemeProvider({bool initialDarkMode = false})
      : _themeMode = initialDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadForUser(String? userId) async {
    if (userId == null) {
      _userId = null;
      if (_themeMode != ThemeMode.light) {
        _themeMode = ThemeMode.light;
        notifyListeners();
      }
      return;
    }

    if (_userId == userId) return;
    _userId = userId;
    if (_themeMode != ThemeMode.light) {
      _themeMode = ThemeMode.light;
      notifyListeners();
    }

    bool? darkMode;
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data != null && data['darkMode'] is bool) {
        darkMode = data['darkMode'] as bool;
      }
    } catch (_) {}

    if (darkMode == null) {
      final prefs = await SharedPreferences.getInstance();
      darkMode = prefs.getBool('darkMode_$userId');
    }

    _themeMode = (darkMode ?? false) ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!isDarkMode);
  }

  Future<void> setDarkMode(bool dark) async {
    if (_userId == null) {
      _themeMode = ThemeMode.light;
      notifyListeners();
      return;
    }
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode_$_userId', dark);
    try {
      await _firestore.collection('users').doc(_userId).set(
        {'darkMode': dark},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }
}

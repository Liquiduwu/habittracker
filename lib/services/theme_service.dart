import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService with ChangeNotifier {
  final String themeKey = "theme";
  final String colorKey = "color";
  SharedPreferences? _prefs;
  bool _isDarkMode = false;
  Color _primaryColor = Colors.green; // Default color

  static const Map<String, Color> availableColors = {
    'Red': Colors.red,
    'Orange': Colors.orange,
    'Yellow': Colors.amber,
    'Green': Colors.green,
    'Blue': Colors.blue,
    'Violet': Colors.purple,
  };

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;

  ThemeService() {
    loadFromPrefs();
  }

  Future<void> initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> loadFromPrefs() async {
    await initPrefs();
    _isDarkMode = _prefs?.getBool(themeKey) ?? false;
    final colorString = _prefs?.getString(colorKey);
    if (colorString != null) {
      _primaryColor = availableColors[colorString] ?? Colors.green;
    }
    notifyListeners();
  }

  Future<void> saveToPrefs() async {
    await initPrefs();
    await _prefs?.setBool(themeKey, _isDarkMode);
    final colorEntry = availableColors.entries
        .firstWhere((entry) => entry.value == _primaryColor,
            orElse: () => const MapEntry('Green', Colors.green));
    await _prefs?.setString(colorKey, colorEntry.key);
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    saveToPrefs();
    notifyListeners();
  }

  void setColor(String colorName) {
    if (availableColors.containsKey(colorName)) {
      _primaryColor = availableColors[colorName]!;
      saveToPrefs();
      notifyListeners();
    }
  }
} 
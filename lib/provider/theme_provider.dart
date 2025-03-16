import 'package:flutter/material.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  String _currentThemeKey = "light"; // 기본 테마는 라이트
  late ThemeData _currentTheme;

  ThemeProvider() {
    _currentTheme = AppTheme.themeData[_currentThemeKey]!;
    loadThemeFromPrefs();
  }

  ThemeData get currentTheme => _currentTheme;
  String get currentThemeKey => _currentThemeKey;

  // 저장된 테마 불러오기
  Future<void> loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('app_theme');
    if (savedTheme != null && AppTheme.themeData.containsKey(savedTheme)) {
      _currentThemeKey = savedTheme;
      _currentTheme = AppTheme.themeData[savedTheme]!;
      notifyListeners();
    }
  }

  // 테마 변경하기
  Future<void> setTheme(String themeKey) async {
    if (AppTheme.themeData.containsKey(themeKey)) {
      _currentThemeKey = themeKey;
      _currentTheme = AppTheme.themeData[themeKey]!;

      // 테마 저장하기
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme', themeKey);

      notifyListeners();
    }
  }

  // 테마가 어두운지 확인
  bool isDarkMode() {
    return _currentThemeKey == "dark";
  }
}

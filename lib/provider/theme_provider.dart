import 'package:flutter/material.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omninews_flutter/services/auth_service.dart';
import 'dart:convert';

class ThemeProvider extends ChangeNotifier {
  String _currentThemeKey = "light"; // 기본 테마는 라이트
  late ThemeData _currentTheme;
  final AuthService _authService = AuthService();

  ThemeProvider() {
    _currentTheme = AppTheme.themeData[_currentThemeKey]!;
    loadTheme();
  }

  ThemeData get currentTheme => _currentTheme;
  String get currentThemeKey => _currentThemeKey;

  // 통합 테마 로드 함수 - 로컬과 서버 모두 체크
  Future<void> loadTheme() async {
    await loadThemeFromPrefs();
    if (_authService.isLoggedIn) {
      await loadThemeFromServer();
    }
  }

  // 저장된 테마 불러오기 (로컬)
  Future<void> loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('app_theme');
    if (savedTheme != null && AppTheme.themeData.containsKey(savedTheme)) {
      _currentThemeKey = savedTheme;
      _currentTheme = AppTheme.themeData[savedTheme]!;
      notifyListeners();
    }
  }

  // 서버에서 테마 설정 불러오기
  Future<void> loadThemeFromServer() async {
    try {
      // 서버에서 유저 테마 정보 가져오기
      final response = await _authService.apiRequest('GET', '/user/theme');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final serverTheme = data['theme'];

        if (serverTheme != null &&
            AppTheme.themeData.containsKey(serverTheme)) {
          _currentThemeKey = serverTheme;
          _currentTheme = AppTheme.themeData[serverTheme]!;

          // 로컬에도 저장
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_theme', serverTheme);

          notifyListeners();
          debugPrint('서버에서 테마 로드 성공: $serverTheme');
        }
      } else {
        debugPrint('서버에서 테마 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('서버에서 테마 로드 중 오류: $e');
    }
  }

  // 테마 변경하기
  Future<void> setTheme(String themeKey) async {
    if (AppTheme.themeData.containsKey(themeKey)) {
      _currentThemeKey = themeKey;
      _currentTheme = AppTheme.themeData[themeKey]!;

      // 로컬에 테마 저장하기
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme', themeKey);

      // 서버에 테마 저장하기
      await saveThemeToServer(themeKey);

      notifyListeners();
    }
  }

  // 서버에 테마 설정 저장하기
  Future<void> saveThemeToServer(String themeKey) async {
    // 로그인된 경우에만 서버에 저장
    if (!_authService.isLoggedIn) return;

    try {
      final response = await _authService.apiRequest(
        'POST',
        '/user/theme',
        body: {'theme': themeKey},
      );

      if (response.statusCode == 200) {
        debugPrint('서버에 테마 저장 성공: $themeKey');
      } else {
        debugPrint('서버에 테마 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('서버에 테마 저장 중 오류: $e');
    }
  }

  // 테마가 어두운지 확인
  bool isDarkMode() {
    return _currentThemeKey == "dark";
  }

  // 로그인 시 서버에서 테마 정보를 가져와 적용
  Future<void> initializeAfterLogin() async {
    await loadThemeFromServer();
  }
}

// lib/provider/settings_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _settingsKey = 'app_settings';

  AppSettings _settings = AppSettings(); // 기본 설정으로 초기화
  bool _isLoading = true;

  // 설정 및 로딩 상태 getters
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  // 생성자
  SettingsProvider() {
    _loadSettings();
  }

  // 설정 불러오기
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        _settings = AppSettings.fromJsonString(settingsJson);
      }
    } catch (e) {
      debugPrint('설정 불러오기 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 설정 저장하기
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('설정 저장 오류: $e');
    }
  }

  // 콘텐츠 표시 모드 업데이트
  void updateViewMode(ViewMode viewMode) {
    _settings = _settings.copyWith(viewMode: viewMode);
    _saveSettings();
    notifyListeners();
  }

  // 웹 링크 열기 모드 업데이트
  void updateWebOpenMode(WebOpenMode webOpenMode) {
    _settings = _settings.copyWith(webOpenMode: webOpenMode);
    _saveSettings();
    notifyListeners();
  }

  // 알림 설정 업데이트 추가
  void updateNotificationsEnabled(bool enabled) {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    _saveSettings();
    notifyListeners();
  }

  // 앱 설정 초기화
  Future<void> resetSettings() async {
    _settings = AppSettings(); // 기본 설정으로 복원
    await _saveSettings();
    notifyListeners();
  }
}

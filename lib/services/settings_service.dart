import 'dart:convert';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';

  // 설정 저장
  static Future<bool> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  // 설정 불러오기
  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson == null) {
      // 기본 설정 반환
      return AppSettings();
    }

    try {
      final Map<String, dynamic> json = jsonDecode(settingsJson);
      return AppSettings.fromJson(json);
    } catch (e) {
      // 오류 발생 시 기본 설정 반환
      return AppSettings();
    }
  }
}

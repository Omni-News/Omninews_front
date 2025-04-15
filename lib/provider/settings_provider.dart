// lib/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:omninews_test_flutter/models/app_setting.dart';
import 'package:omninews_test_flutter/services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await SettingsService.loadSettings();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateViewMode(ViewMode viewMode) async {
    _settings = _settings.copyWith(viewMode: viewMode);
    await SettingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateWebOpenMode(WebOpenMode webOpenMode) async {
    _settings = _settings.copyWith(webOpenMode: webOpenMode);
    await SettingsService.saveSettings(_settings);
    notifyListeners();
  }
}

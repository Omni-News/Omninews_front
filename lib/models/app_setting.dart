// 기존 코드에 notificationsEnabled 필드만 추가합니다
// lib/models/app_settings.dart에 아래 코드를 추가하세요
import 'dart:convert';

enum ViewMode { textAndImage, textOnly }

enum WebOpenMode { inApp, externalBrowser }

class AppSettings {
  final ViewMode viewMode;
  final WebOpenMode webOpenMode;
  final bool notificationsEnabled; // 알림 설정 추가

  AppSettings({
    this.viewMode = ViewMode.textAndImage,
    this.webOpenMode = WebOpenMode.inApp,
    this.notificationsEnabled = false, // 기본값은 알림 꺼짐
  });

  // JSON 변환 메서드
  Map<String, dynamic> toJson() {
    return {
      'viewMode': viewMode.index,
      'webOpenMode': webOpenMode.index,
      'notificationsEnabled': notificationsEnabled, // 알림 설정 저장
    };
  }

  // JSON에서 모델 생성 메서드
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      viewMode: ViewMode.values[json['viewMode'] ?? 0],
      webOpenMode: WebOpenMode.values[json['webOpenMode'] ?? 0],
      notificationsEnabled: json['notificationsEnabled'] ?? false, // 알림 설정 로드
    );
  }

  static fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return AppSettings.fromJson(json);
  }

  // 설정 변경 메서드 (불변 객체 패턴)
  AppSettings copyWith({
    ViewMode? viewMode,
    WebOpenMode? webOpenMode,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      viewMode: viewMode ?? this.viewMode,
      webOpenMode: webOpenMode ?? this.webOpenMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

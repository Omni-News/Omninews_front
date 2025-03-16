enum ViewMode { textOnly, textAndImage }

enum WebOpenMode { inApp, externalBrowser }

class AppSettings {
  ViewMode viewMode;
  WebOpenMode webOpenMode;

  AppSettings({
    this.viewMode = ViewMode.textAndImage,
    this.webOpenMode = WebOpenMode.inApp,
  });

  // SharedPreferences에서 불러오기 위한 팩토리 메서드
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      viewMode: ViewMode.values[json['viewMode'] ?? 1],
      webOpenMode: WebOpenMode.values[json['webOpenMode'] ?? 0],
    );
  }

  // SharedPreferences에 저장하기 위한 메서드
  Map<String, dynamic> toJson() {
    return {
      'viewMode': viewMode.index,
      'webOpenMode': webOpenMode.index,
    };
  }

  // 복사 메서드
  AppSettings copyWith({
    ViewMode? viewMode,
    WebOpenMode? webOpenMode,
  }) {
    return AppSettings(
      viewMode: viewMode ?? this.viewMode,
      webOpenMode: webOpenMode ?? this.webOpenMode,
    );
  }
}

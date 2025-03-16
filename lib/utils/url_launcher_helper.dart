// lib/utils/url_launcher_helper.dart
import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherHelper {
  static Future<void> openUrl(
      BuildContext context, String url, WebOpenMode mode) async {
    final uri = Uri.parse(url);

    try {
      switch (mode) {
        case WebOpenMode.inApp:
          await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );
          break;

        case WebOpenMode.externalBrowser:
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          break;
      }
    } catch (e) {
      // 오류 처리
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('링크를 열 수 없습니다: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      debugPrint('URL 실행 오류: $e');
    }
  }
}

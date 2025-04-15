import 'package:flutter/material.dart';
import 'package:omninews_test_flutter/models/app_setting.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherHelper {
  static Future<void> openUrl(
      BuildContext context, String url, WebOpenMode mode) async {
    final uri = Uri.parse(url);
    
    // URL 스킴 확인
    final String scheme = uri.scheme.toLowerCase();
    
    // mailto:, tel:, sms: 등 특수 스킴 체크
    final bool isSpecialScheme = scheme == 'mailto' || 
                                scheme == 'tel' || 
                                scheme == 'sms' ||
                                (scheme != 'http' && scheme != 'https');

    try {
      // 특수 스킴인 경우 항상 외부 앱으로 열기
      if (isSpecialScheme) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // 일반 웹 URL은 사용자 설정에 따라 처리
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
      }
    } catch (e) {
      // 오류 처리
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('링크를 열 수 없습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      debugPrint('URL 실행 오류: $e - URL: $url');
    }
  }
}

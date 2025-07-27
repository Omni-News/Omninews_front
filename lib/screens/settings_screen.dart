// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:omninews_flutter/services/auth_service.dart'; // 알림 권한용 추가
import 'package:permission_handler/permission_handler.dart'; // 권한 핸들러 추가

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    if (settingsProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('설정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('설정', style: theme.textTheme.headlineMedium)),
      body: ListView(
        children: [
          _buildSectionHeader(context, '콘텐츠 표시 설정'),
          _buildViewModeSelector(context, settingsProvider),
          const Divider(),
          _buildSectionHeader(context, '웹 링크 설정'),
          _buildWebOpenModeSelector(context, settingsProvider),
          const Divider(),
          // 알림 섹션 추가
          _buildSectionHeader(context, '알림 설정'),
          _buildNotificationSettings(context, settingsProvider),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.secondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildViewModeSelector(
    BuildContext context,
    SettingsProvider provider,
  ) {
    final theme = Theme.of(context);
    final settings = provider.settings;

    return Column(
      children: [
        RadioListTile<ViewMode>(
          title: const Text('텍스트 + 이미지 보기'),
          subtitle: const Text('콘텐츠를 이미지와 함께 표시합니다'),
          value: ViewMode.textAndImage,
          groupValue: settings.viewMode,
          activeColor: theme.primaryColor,
          onChanged: (value) {
            if (value != null) {
              provider.updateViewMode(value);
            }
          },
        ),
        RadioListTile<ViewMode>(
          title: const Text('텍스트만 보기'),
          subtitle: const Text('이미지 없이 텍스트만 표시합니다'),
          value: ViewMode.textOnly,
          groupValue: settings.viewMode,
          activeColor: theme.primaryColor,
          onChanged: (value) {
            if (value != null) {
              provider.updateViewMode(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildWebOpenModeSelector(
    BuildContext context,
    SettingsProvider provider,
  ) {
    final theme = Theme.of(context);
    final settings = provider.settings;

    return Column(
      children: [
        RadioListTile<WebOpenMode>(
          title: const Text('앱 내에서 열기'),
          subtitle: const Text('앱을 벗어나지 않고 웹 콘텐츠를 봅니다'),
          value: WebOpenMode.inApp,
          groupValue: settings.webOpenMode,
          activeColor: theme.primaryColor,
          onChanged: (value) {
            if (value != null) {
              provider.updateWebOpenMode(value);
            }
          },
        ),
        RadioListTile<WebOpenMode>(
          title: const Text('외부 브라우저로 열기'),
          subtitle: const Text('시스템 기본 브라우저를 사용합니다'),
          value: WebOpenMode.externalBrowser,
          groupValue: settings.webOpenMode,
          activeColor: theme.primaryColor,
          onChanged: (value) {
            if (value != null) {
              provider.updateWebOpenMode(value);
            }
          },
        ),
      ],
    );
  }

  // 알림 설정 위젯 추가 (설정 화면으로 이동 기능 추가)
  Widget _buildNotificationSettings(
    BuildContext context,
    SettingsProvider provider,
  ) {
    final theme = Theme.of(context);
    final settings = provider.settings;
    final authService = AuthService();

    return SwitchListTile(
      title: const Text('푸시 알림 받기'),
      subtitle: const Text('구독 채널의 새 소식을 알림으로 받습니다'),
      value: settings.notificationsEnabled,
      activeColor: theme.primaryColor,
      onChanged: (value) async {
        if (value) {
          // 알림 켜기: 권한 요청
          final hasPermission =
              await authService.requestNotificationPermissions();
          if (hasPermission) {
            provider.updateNotificationsEnabled(true);
            _showSnackBar(context, '알림이 활성화되었습니다');
          } else {
            // 권한 거부 시 설정으로 이동할 수 있는 다이얼로그 표시
            _showPermissionDeniedDialog(context);
          }
        } else {
          // 알림 끄기
          final success = await authService.disableNotifications();
          if (success) {
            provider.updateNotificationsEnabled(false);
            _showSnackBar(context, '알림이 비활성화되었습니다');
          }
        }
      },
    );
  }

  // 권한 거부 시 다이얼로그 표시
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('알림 권한 필요'),
            content: const Text(
              '알림을 받으려면 설정에서 알림 권한을 허용해야 합니다.\n\n설정 앱에서 알림 권한을 허용하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // 설정 앱으로 이동
                  openAppSettings();
                },
                child: const Text('설정으로 이동'),
              ),
            ],
          ),
    );
  }

  // 스낵바 표시 헬퍼 메서드
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

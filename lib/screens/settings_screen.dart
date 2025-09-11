import 'dart:io';

import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/screens/login_screen.dart';
import 'package:omninews_flutter/screens/omninews_subscription/omninews_subscription_home.dart';
import 'package:provider/provider.dart';
import 'package:omninews_flutter/services/auth_service.dart'; // 알림 권한용 + 회원탈퇴
import 'package:permission_handler/permission_handler.dart'; // 권한 핸들러
import 'package:url_launcher/url_launcher.dart'; // 스토어 구독 관리 이동
import 'package:omninews_flutter/services/settings_service.dart'; // 로컬 설정 저장/초기화

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

    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        appBar: AppBar(
          title: Text('설정', style: theme.textTheme.headlineMedium),
        ),
        body: ListView(
          children: [
            _buildSectionHeader(context, '콘텐츠 표시 설정'),
            _buildViewModeSelector(context, settingsProvider),
            const Divider(),
            _buildSectionHeader(context, '웹 링크 설정'),
            _buildWebOpenModeSelector(context, settingsProvider),
            const Divider(),
            _buildSectionHeader(context, '알림 설정'),
            _buildNotificationSettings(context, settingsProvider),
            const Divider(),
            _buildSectionHeader(context, '구독 관리'),
            _buildSubscriptionSettings(context),
            const Divider(),
            _buildSectionHeader(context, '계정'),
            _buildAccountDeletionTile(context),
            const SizedBox(height: 16),
          ],
        ),
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

  // 구독 설정 위젯
  Widget _buildSubscriptionSettings(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.card_membership),
          title: const Text('구독 관리'),
          subtitle: const Text('프리미엄 기능 및 구독 상태 확인'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscriptionHomePage(),
              ),
            );
          },
        ),
      ],
    );
  }

  // 회원 탈퇴 타일
  Widget _buildAccountDeletionTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text(
        '회원 탈퇴',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
      subtitle: const Text('계정과 데이터가 삭제됩니다. 스토어 구독(애플/구글)은 별도 해지 필요'),
      onTap: () => _confirmAndDeleteAccount(context),
    );
  }

  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('회원 탈퇴'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '탈퇴 시:\n'
                      '- 앱 내 계정 및 데이터가 삭제됩니다.\n'
                      '- 스토어 구독은 자동 해지되지 않습니다.\n'
                      '  (애플/구글 구독은 각 스토어에서 직접 취소해야 합니다)',
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _openStoreSubscriptionManagement,
                      icon: const Icon(Icons.open_in_new),
                      label: Text(
                        Platform.isIOS ? '애플 구독 관리로 이동' : '구글 구독 관리로 이동',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('탈퇴하기'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmed) return;

    await _performAccountDeletion(context);
  }

  Future<void> _performAccountDeletion(BuildContext context) async {
    final navigatorState = Navigator.of(
      context,
    ); // NavigatorState를 캡처해 콜백에서 재사용
    final scaffold = ScaffoldMessenger.of(context);
    final auth = AuthService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final ok = await auth.deleteAccount();

      // 로딩 닫기
      navigatorState.pop();

      if (!ok) {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('회원 탈퇴 요청에 실패했습니다. 잠시 후 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 로컬 앱 설정 초기화
      await SettingsService.saveSettings(AppSettings());

      scaffold.showSnackBar(
        const SnackBar(
          content: Text('회원 탈퇴가 완료되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );

      // 로그인 화면으로 완전 이동 (스택 초기화)
      await Future.delayed(const Duration(milliseconds: 200));
      navigatorState.pushAndRemoveUntil(
        MaterialPageRoute(
          builder:
              (_) => LoginScreen(
                onLoginSuccess: () {
                  // 로그인 성공 시 홈으로 교체 (앱 라우팅에 맞게 조정)
                  navigatorState.pushReplacementNamed('/');
                },
              ),
        ),
        (route) => false,
      );
    } catch (e) {
      // 로딩 닫기
      navigatorState.pop();
      scaffold.showSnackBar(
        SnackBar(
          content: Text('회원 탈퇴 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openStoreSubscriptionManagement() async {
    final uri =
        Platform.isIOS
            ? Uri.parse('itms-apps://apps.apple.com/account/subscriptions')
            : Uri.parse('https://play.google.com/store/account/subscriptions');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      final fallback =
          Platform.isIOS
              ? Uri.parse('https://apps.apple.com/account/subscriptions')
              : Uri.parse(
                'https://play.google.com/store/account/subscriptions',
              );
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
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

  // 알림 설정 위젯 (설정 화면으로 이동 기능 포함)
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

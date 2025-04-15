// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    if (settingsProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('설정'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
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
      BuildContext context, SettingsProvider provider) {
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
      BuildContext context, SettingsProvider provider) {
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
}

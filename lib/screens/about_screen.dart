import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:omninews_flutter/utils/url_launcher_helper.dart'; // 변경: 사용자 정의 URL 실행 도우미 사용
import 'package:omninews_flutter/models/app_setting.dart'; // 웹 열기 모드를 위한 설정 모델
import 'package:omninews_flutter/theme/app_theme.dart'; // 테마 적용을 위한 앱 테마 임포트
import 'package:provider/provider.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Omni News',
    packageName: 'com.example.omninews_flutter',
    version: '1.0.0',
    buildNumber: '1',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final settings = Provider.of<SettingsProvider>(context).settings; // 설정 가져오기
    final subscribeStyle =
        AppTheme.subscribeViewStyleOf(context); // 구독 화면 스타일 적용

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 앱 로고 및 버전 정보
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.article,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Omni News',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.headlineMedium?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version ${_packageInfo.version} (${_packageInfo.buildNumber})',
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 앱 설명
          _buildSectionTitle(context, '옴니뉴스'),
          const SizedBox(height: 12),
          Text(
            'Omni News는 다양한 뉴스와 RSS 피드를 한 곳에서 쉽게 액세스할 수 있도록 설계된 종합 뉴스 애플리케이션입니다. 다양한 뉴스 피드, 북마크 기능 및 사용자 간 RSS피드 공유 데이터베이스를 통해 양질의 정보 소비 경험을 향상시킵니다.',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 30),

          // 주요 기능
          _buildSectionTitle(context, '주요 기능들'),
          const SizedBox(height: 12),
          _buildFeatureItem(
              context, '다양한 뉴스 소스 구독', 'Subscribe to various news sources'),
          _buildFeatureItem(context, 'RSS 피드 지원', 'Integrated RSS feed reader'),
          _buildFeatureItem(
              context, '북마크 및 즐겨찾기', 'Save articles for later reading'),
          _buildFeatureItem(
              context, '사용자 맞춤 테마', 'Customize your reading experience'),
          _buildFeatureItem(
              context, '뉴스 검색', 'Search for specific news and topics'),

          const SizedBox(height: 30),

          // 기술 스택
          _buildSectionTitle(context, 'Built With'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildTechChip(context, 'Flutter'),
              _buildTechChip(context, 'Dart'),
              _buildTechChip(context, 'Rust'),
              _buildTechChip(context, 'Rocket'),
              _buildTechChip(context, 'Mecab'),
              _buildTechChip(context, 'MySql'),
            ],
          ),

          const SizedBox(height: 30),

          const SizedBox(height: 16),

          const SizedBox(height: 40),

          // 저작권 정보
          Center(
            child: Text(
              '© 2025 Omni News. All rights reserved.',
              style: textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: theme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    String name,
    String username,
    String url,
    IconData icon,
    WebOpenMode webOpenMode, // 웹 열기 모드 추가
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openUrl(url, webOpenMode),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Icon(
                  icon,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    Text(
                      '@$username',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.iconTheme.color?.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechChip(BuildContext context, String label) {
    final theme = Theme.of(context);

    return Chip(
      label: Text(label),
      backgroundColor: theme.primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: theme.primaryColor,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: theme.primaryColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: theme.textTheme.labelLarge?.color,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(
          color: theme.dividerColor,
        ),
      ),
    );
  }

  // URL 실행 함수를 UrlLauncherHelper를 사용하는 방식으로 변경
  void _openUrl(String url, WebOpenMode mode) {
    UrlLauncherHelper.openUrl(context, url, mode);
  }
}

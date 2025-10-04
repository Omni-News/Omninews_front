import 'package:flutter/material.dart';
import 'package:omninews_flutter/utils/url_launcher_helper.dart';
import 'package:provider/provider.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  // FAQ 항목들 (문구 자연스러운 한글로 정리)
  final List<Map<String, String>> _faqItems = [
    {
      'question': 'RSS 피드를 구독하려면 어떻게 하나요?',
      'answer':
          'RSS 탭에서 "+" 버튼을 눌러 RSS 주소를 입력하면 자동으로 피드 정보를 불러옵니다. 검색을 통해 원하는 피드를 찾은 뒤 "구독"을 눌러 바로 추가할 수도 있습니다. 이미 구독 중인 피드에는 "구독 중" 표시가 나타납니다.',
    },
    {
      'question': '기사를 북마크하려면 어떻게 하나요?',
      'answer':
          '각 기사 카드의 북마크 아이콘을 누르면 북마크에 저장됩니다. 기사 상세 화면 상단의 북마크 아이콘으로도 저장할 수 있습니다. 북마크한 기사는 하단 탭의 "북마크"에서 확인할 수 있습니다.',
    },
    {
      'question': '다크 모드로 전환하려면 어떻게 하나요?',
      'answer':
          '사이드 메뉴에서 "테마 선택"을 누르면 테마 선택 다이얼로그가 표시됩니다. 라이트, 다크, 블루, 페이퍼 모드 중에서 선택할 수 있으며, 시스템 테마를 따르도록 설정할 수도 있습니다.',
    },
    {
      'question': '뉴스 카테고리는 어떻게 추가하나요?',
      'answer':
          '뉴스 화면 상단의 "+" 버튼을 누른 뒤, 추가할 키워드나 주제를 입력하세요. 검색 화면에서도 특정 키워드로 검색한 후 "카테고리 추가" 버튼으로 바로 추가할 수 있습니다.',
    },
    {
      'question': '구독 중인 피드는 어떻게 관리하나요?',
      'answer':
          'RSS 탭에서 구독 중인 채널을 선택하면 채널 상세 화면으로 이동합니다. 여기에서 "구독 취소"를 할 수 있으며, 필요한 경우 폴더에 채널을 추가·제거해 정리할 수 있습니다.',
    },
    {
      'question': '최근 읽은 기사는 어디에서 볼 수 있나요?',
      'answer':
          '사이드 메뉴에서 "최근 읽은 글"을 선택하세요. 최근에 읽은 기사를 날짜별로 확인할 수 있으며, 우측 상단의 휴지통 아이콘으로 기록을 삭제할 수 있습니다.',
    },
    {
      'question': '뉴스와 RSS 피드는 무엇이 다른가요?',
      'answer':
          '뉴스는 다양한 소식들을 주제별로 모아 보여주는 기능이고, RSS는 사용자가 선택한 웹사이트나 블로그의 업데이트만 모아보는 기능입니다. 폭넓은 정보 탐색에는 뉴스가, 관심사에 집중한 탐색에는 RSS가 적합합니다.',
    },
    {
      'question': '기사가 올바르게 표시되지 않아요. 어떻게 해야 하나요?',
      'answer':
          '앱이 최신 버전인지 확인하고, 네트워크 상태를 점검해 보세요. 문제가 지속되면 앱을 재시작하거나 해당 피드를 새로고침·재구독해 보시기 바랍니다. "원문 보기"로 웹에서 직접 확인하는 것도 방법입니다.',
    },
    {
      'question': '기사 텍스트 크기를 조절할 수 있나요?',
      'answer':
          '설정의 글자 크기에서 앱 전체 텍스트 크기를 조절할 수 있습니다. 기사 상세 화면에서는 확대/축소 제스처로 해당 기사에 한해 일시적으로 글자 크기를 조절할 수 있습니다.',
    },
    {
      'question': '정렬 방식을 변경할 수 있나요?',
      'answer':
          '목록 상단의 정렬 옵션에서 최신순/인기순/정확순 등 원하는 기준을 선택할 수 있습니다. 사용자 정의 뉴스 카테고리는 정렬 옵션을 저장해 다음에도 유지됩니다.',
    },
    {
      'question': '알림 설정은 어떻게 관리하나요?',
      'answer':
          '설정의 "푸시 알림 받기"에서 전체 알림을 켜거나 끌 수 있습니다. 알림 권한이 꺼져 있으면 안내에 따라 설정 앱에서 권한을 허용해 주세요.',
    },
    {
      'question': '오프라인에서도 볼 수 있나요?',
      'answer':
          '최근 읽은 기사와 북마크한 기사는 연결이 없을 때도 열람 가능한 경우가 많습니다. 최신 콘텐츠가 필요한 경우에는 네트워크 연결 상태에서 새로고침해 주세요.',
    },
  ];

  // 사용 가이드 항목
  final List<Map<String, dynamic>> _userGuides = [
    {
      'title': '시작하기',
      'guides': [
        {
          'step': '앱 둘러보기',
          'description': '하단 탭에서 구독, RSS, 뉴스, 북마크, 검색 기능에 접근할 수 있습니다.',
        },
        {
          'step': '뉴스 탐색',
          'description': '뉴스 탭에서 카테고리별 최신 뉴스를 확인하고, 관심 주제를 추가해 맞춤 피드를 만들어 보세요.',
        },
        {
          'step': 'RSS 구독 시작',
          'description': 'RSS 탭에서 "+" 버튼을 눌러 좋아하는 웹사이트나 블로그의 RSS를 구독하세요.',
        },
      ],
    },
    {
      'title': '개인화 설정',
      'guides': [
        {
          'step': '테마 변경',
          'description':
              '사이드 메뉴에서 "테마 선택"을 눌러 라이트/다크/블루/페이퍼 모드 중 원하는 테마를 적용할 수 있습니다.',
        },
        {
          'step': '카드 레이아웃',
          'description': '설정에서 기사 카드 표시 방식(간단히/상세히)과 이미지 표시 여부를 조정할 수 있습니다.',
        },
        {
          'step': '알림 설정',
          'description': '설정에서 알림을 켜고 끄거나, 권한이 필요한 경우 안내에 따라 권한을 허용해 주세요.',
        },
      ],
    },
    {
      'title': '고급 기능',
      'guides': [
        {'step': '북마크 관리', 'description': '북마크한 기사를 한 곳에서 모아보고 관리할 수 있습니다.'},
        {
          'step': '기사 공유',
          'description': '기사 상세 화면의 공유 아이콘으로 간편히 공유하거나 링크를 복사하세요.',
        },
        {
          'step': '데이터 절약',
          'description': '설정에서 이미지 자동 로딩을 비활성화하거나 Wi‑Fi에서만 다운로드하도록 설정할 수 있습니다.',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('도움말'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 앱 소개 섹션
              _buildSectionTitle(context, '앱 소개'),
              const SizedBox(height: 12),
              _buildIntroductionCard(theme),

              const SizedBox(height: 32),

              // FAQ 섹션
              _buildSectionTitle(context, '자주 묻는 질문 (FAQ)'),
              const SizedBox(height: 12),
              ...List.generate(_faqItems.length, (index) {
                return _buildFaqItem(
                  context,
                  _faqItems[index]['question']!,
                  _faqItems[index]['answer']!,
                );
              }),

              const SizedBox(height: 32),

              // 사용자 가이드 섹션
              _buildSectionTitle(context, '사용자 가이드'),
              const SizedBox(height: 12),
              ...List.generate(_userGuides.length, (guideIndex) {
                final guide = _userGuides[guideIndex];
                return _buildGuideSection(context, guide);
              }),

              const SizedBox(height: 32),

              // 주요 사용법 팁
              _buildSectionTitle(context, '사용 팁'),
              const SizedBox(height: 12),
              _buildTipCard(
                context,
                icon: Icons.touch_app,
                title: '당겨서 새로고침',
                tip: '목록에서 화면을 아래로 당겨 최신 글로 업데이트할 수 있습니다.',
              ),
              _buildTipCard(
                context,
                icon: Icons.format_size,
                title: '카드 모드 설정',
                tip: '설정에서 기사 카드뷰를 간단히/상세히 중 선택해 더 효율적으로 살펴보세요.',
              ),
              _buildTipCard(
                context,
                icon: Icons.watch_later_outlined,
                title: '최근 읽은 글',
                tip: '사이드 메뉴의 "최근 읽은 글"에서 날짜별로 확인하고, 우측 상단에서 기록을 삭제할 수 있습니다.',
              ),
              _buildTipCard(
                context,
                icon: Icons.bookmark_border,
                title: '북마크',
                tip: '관심 기사는 북마크로 모아 한 번에 확인할 수 있습니다.',
              ),
              _buildTipCard(
                context,
                icon: Icons.share,
                title: '기사 공유',
                tip: '기사 상세 화면의 공유 버튼으로 다양한 앱에 손쉽게 공유하세요.',
              ),

              const SizedBox(height: 32),

              // 단축키 섹션 (태블릿/데스크탑)
              _buildSectionTitle(context, '단축키 (태블릿/데스크탑)'),
              const SizedBox(height: 12),
              _buildShortcutsCard(theme),

              const SizedBox(height: 32),

              // 연락처 정보
              _buildSectionTitle(context, '연락처 정보'),
              const SizedBox(height: 12),

              // 이메일 연락처
              _buildContactItem(
                context,
                icon: Icons.email_outlined,
                title: '이메일',
                value: 'kang3171611@naver.com',
                onTap: () {
                  UrlLauncherHelper.openUrl(
                    context,
                    'mailto:kang3171611@naver.com',
                    settings.webOpenMode,
                  );
                },
              ),

              // GitHub 연락처
              _buildContactItem(
                context,
                icon: Icons.code,
                title: 'GitHub',
                value: 'github.com/kang1027',
                onTap: () {
                  UrlLauncherHelper.openUrl(
                    context,
                    'https://github.com/kang1027',
                    settings.webOpenMode,
                  );
                },
              ),

              const SizedBox(height: 20),

              // 앱 버전
              Center(
                child: Text(
                  'OmniNews v1.0.0',
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 앱 소개 카드 - 아이콘을 이미지로 교체
  Widget _buildIntroductionCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 앱 아이콘 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'resources/omninews_icon.png', // 앱 아이콘 이미지 경로
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OmniNews',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      Text(
                        '모든 뉴스와 RSS 피드를 한곳에서',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'OmniNews는 다양한 뉴스 소스와 RSS 피드를 한 곳에서 쉽게 관리하고 읽을 수 있는 올인원 뉴스 앱입니다. 관심 주제의 최신 기사를 자동으로 모아보고, 즐겨찾는 웹사이트의 RSS를 구독하여 맞춤형 뉴스 경험을 즐겨 보세요. 깔끔한 인터페이스와 여러 테마, 편리한 읽기 환경을 제공합니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 사용자 가이드 섹션
  Widget _buildGuideSection(BuildContext context, Map<String, dynamic> guide) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Text(
            guide['title'],
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: theme.cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: List.generate(guide['guides'].length, (index) {
                final stepGuide = guide['guides'][index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.primaryColor.withOpacity(0.2),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    stepGuide['step'],
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      stepGuide['description'],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.8,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // 단축키 카드
  Widget _buildShortcutsCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildShortcutItem(theme, 'R', '새로고침'),
            _buildShortcutItem(theme, 'B', '북마크 추가/제거'),
            _buildShortcutItem(theme, 'S', '검색'),
            _buildShortcutItem(theme, 'H', '홈으로 이동'),
            _buildShortcutItem(theme, 'Esc', '뒤로 가기'),
            _buildShortcutItem(theme, 'Ctrl+F', '페이지 내 검색', isLast: true),
          ],
        ),
      ),
    );
  }

  // 단축키 항목
  Widget _buildShortcutItem(
    ThemeData theme,
    String key,
    String description, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              key,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(description, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  // 섹션 제목 위젯
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

  // FAQ 아이템 위젯
  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Text(
        question,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.textTheme.titleMedium?.color,
        ),
      ),
      iconColor: theme.primaryColor,
      collapsedIconColor: theme.iconTheme.color,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          answer,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // 팁 카드 위젯
  Widget _buildTipCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String tip,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.8,
                      ),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 연락처 아이템 위젯
  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: theme.primaryColor, size: 22),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.textTheme.titleSmall?.color?.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: theme.iconTheme.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

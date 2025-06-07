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
  // FAQ 항목들 확장
  final List<Map<String, String>> _faqItems = [
    {
      'question': 'RSS 피드를 구독하려면 어떻게 해야 하나요?',
      'answer':
          'RSS 화면에서 "+" 버튼을 탭하고 RSS URL을 입력하거나, 검색 기능을 사용하여 원하는 피드를 찾아 구독 버튼을 누르세요.',
    },
    {
      'question': '기사를 북마크하는 방법은 무엇인가요?',
      'answer':
          '각 기사 카드에 있는 북마크 아이콘을 탭하면 북마크에 추가됩니다. 북마크된 기사는 북마크 탭에서 확인할 수 있습니다.',
    },
    {
      'question': '다크 모드로 전환하려면 어떻게 해야 하나요?',
      'answer':
          '사이드 메뉴에서 "Choose Theme"를 탭하여 라이트 모드, 블루 모드, 다크 모드 설정 중에서 선택할 수 있습니다.',
    },
    {
      'question': '뉴스 카테고리는 어떻게 추가하나요?',
      'answer':
          'News 화면에서 "+" 버튼을 탭하고 추가하고 싶은 키워드를 입력하거나, 검색 기능을 사용하여 원하는 뉴스 키워드를 입력하고 "카테고리에 추가+" 버튼을 누르세요.',
    },
    {
      'question': '구독 중인 피드를 관리하려면 어떻게 해야 하나요?',
      'answer':
          '구독 탭에서 구독 중인 모든 피드를 확인할 수 있으며, 각 피드를 길게 누르거나 세부 정보 화면에서 구독 해제할 수 있습니다.',
    },
    {
      'question': '최근 읽은 기사를 확인하는 방법은 무엇인가요?',
      'answer':
          '사이드 메뉴에서 "최근 읽은 글"을 선택하면 최근에 읽은 모든 기사 목록을 날짜별로 정렬하여 볼 수 있습니다. 또한 해당 화면에서 특정 기사를 선택하여 다시 읽을 수 있습니다.',
    },
    {
      'question': '뉴스와 RSS 피드의 차이점은 무엇인가요?',
      'answer':
          '뉴스 기능은 주요 뉴스 사이트의 최신 기사를 키워드별로 모아서 보여줍니다. RSS 피드는 사용자가 직접 구독한 특정 웹사이트나 블로그의 업데이트를 받아볼 수 있는 기능입니다. 뉴스는 다양한 출처에서 수집된 정보이고, RSS는 사용자가 선택한 출처에서만 정보를 받아봅니다.',
    },
    {
      'question': '기사가 올바르게 표시되지 않으면 어떻게 해야 하나요?',
      'answer':
          '앱을 최신 버전으로 업데이트했는지 확인하세요. 또한 인터넷 연결 상태를 확인하고, 필요하다면 앱을 재시작해보세요. 특정 RSS 피드에 문제가 있다면, 해당 피드를 구독 해제했다가 다시 구독해보는 것도 도움이 될 수 있습니다.',
    },
    {
      'question': '기사 텍스트 크기를 조절할 수 있나요?',
      'answer':
          '설정 메뉴에서 "글자 크기" 옵션을 통해 앱 전체 텍스트 크기를 조절할 수 있습니다. 작게, 보통, 크게 등 다양한 옵션 중에서 선택할 수 있습니다.',
    },
    {
      'question': '특정 카테고리나 피드의 정렬 방식을 변경할 수 있나요?',
      'answer':
          '카테고리나 피드 목록 화면에서 상단에 있는 정렬 옵션을 탭하여 최신순, 인기순 등 다양한 정렬 방식을 선택할 수 있습니다.',
    },
  ];

  // 사용 가이드 항목
  final List<Map<String, dynamic>> _userGuides = [
    {
      'title': '시작하기',
      'guides': [
        {
          'step': '홈 화면 탐색',
          'description': '앱을 처음 실행하면 홈 화면에서 추천 뉴스와 구독한 피드를 볼 수 있습니다.',
        },
        {
          'step': '카테고리 선택',
          'description': '상단 탭을 통해 뉴스, RSS, 북마크 등 다양한 섹션으로 이동할 수 있습니다.',
        },
        {
          'step': '검색 기능 활용',
          'description': '검색 아이콘을 탭하여 키워드로 뉴스나 RSS 피드를 검색할 수 있습니다.',
        },
      ],
    },
    {
      'title': '개인화 설정',
      'guides': [
        {
          'step': '테마 변경',
          'description': '사이드 메뉴에서 "Choose Theme"을 선택하여 앱 테마를 변경할 수 있습니다.',
        },
        {
          'step': '뷰 모드 설정',
          'description': '설정에서 텍스트 전용 모드나 이미지 포함 모드를 선택할 수 있습니다.',
        },
        {
          'step': '카드 레이아웃',
          'description': '설정에서 기사 카드의 레이아웃을 조정하여 더 좋은 읽기 경험을 구성할 수 있습니다.',
        },
      ],
    },
    {
      'title': '고급 기능',
      'guides': [
        {'step': '오프라인 모드', 'description': '주요 기사는 오프라인에서도 읽을 수 있도록 캐시됩니다.'},
        {
          'step': 'AI 요약',
          'description': '긴 기사는 AI로 요약되어 핵심 내용을 빠르게 파악할 수 있습니다.',
        },
        {
          'step': '읽기 기록 관리',
          'description': '최근 읽은 글 화면에서 기록을 확인하고 관리할 수 있습니다.',
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
                title: '스와이프 제스처',
                tip:
                    '기사 목록에서 아래로 당기면 새로고침됩니다. 일부 화면에서는 좌우로 스와이프하여 카테고리를 변경할 수 있습니다.',
              ),

              _buildTipCard(
                context,
                icon: Icons.format_size,
                title: '카드 모드 설정',
                tip: '설정 메뉴에서 Rss, News 카드뷰 모드를 조정하여 읽기 환경을 설정할 수 있습니다.',
              ),

              _buildTipCard(
                context,
                icon: Icons.watch_later_outlined,
                title: '최근 읽은 글',
                tip: '사이드 메뉴에서 "Recently Read"를 탭하여 최근에 읽은 기사를 다시 찾을 수 있습니다.',
              ),

              _buildTipCard(
                context,
                icon: Icons.bookmark_border,
                title: '북마크 관리',
                tip:
                    '북마크 탭에서는 카테고리별로 저장한 기사들을 구분하여 볼 수 있으며, 길게 누르면 여러 기사를 한번에 삭제할 수 있습니다.',
              ),

              _buildTipCard(
                context,
                icon: Icons.share,
                title: '기사 공유',
                tip: '기사 상세 화면에서 공유 버튼을 통해 기사 링크를 다른 앱이나 연락처와 공유할 수 있습니다.',
              ),

              const SizedBox(height: 32),

              // 단축키 섹션 (태블릿/데스크탑용)
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
                value: 'github.com/kang1027/omninews',
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
                  'Omni News v1.0.0',
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

  // 앱 소개 카드
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.rss_feed,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Omni News',
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
              'Omni News는 다양한 뉴스 소스와 RSS 피드를 한 곳에서 관리하고 읽을 수 있는 앱입니다. AI 기반 기사 요약 기능, 개인화된 구독 관리, 그리고 사용자 친화적인 인터페이스를 통해 효율적인 정보 소비 경험을 제공합니다.',
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
            _buildShortcutItem(theme, 'B', '북마크에 추가/제거'),
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

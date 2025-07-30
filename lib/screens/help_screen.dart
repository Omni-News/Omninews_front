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
  // FAQ 항목들 확장 및 보완
  final List<Map<String, String>> _faqItems = [
    {
      'question': 'RSS 피드를 구독하려면 어떻게 해야 하나요?',
      'answer':
          'RSS 탭에서 "+" 버튼을 탭하고 RSS URL을 직접 입력하거나, 검색 기능을 사용하여 원하는 피드를 찾을 수 있습니다. URL 입력 시 자동으로 피드 정보를 불러와 구독할 수 있으며, 검색 결과에서는 "구독" 버튼을 눌러 바로 추가할 수 있습니다. 이미 구독 중인 피드는 "구독 중" 표시가 나타납니다.',
    },
    {
      'question': '기사를 북마크하는 방법은 무엇인가요?',
      'answer':
          '각 기사 카드에 있는 북마크 아이콘을 탭하면 북마크에 추가됩니다. 기사 상세 페이지에서도 상단 우측의 북마크 아이콘을 통해 저장할 수 있습니다. 북마크된 모든 기사는 하단 탭의 북마크 메뉴에서 확인하고 관리할 수 있으며, 카테고리별로 분류하여 볼 수 있습니다.',
    },
    {
      'question': '다크 모드로 전환하려면 어떻게 해야 하나요?',
      'answer':
          '사이드 메뉴에서 "Choose Theme"를 탭하면 테마 선택 다이얼로그가 나타납니다. 라이트 모드, 다크 모드, 블루 모드, 페이퍼 모드 중에서 선택할 수 있으며, 선택한 테마는 즉시 적용됩니다. 또한 시스템 테마를 따르도록 설정할 수도 있습니다.',
    },
    {
      'question': '뉴스 카테고리는 어떻게 추가하나요?',
      'answer':
          'News 화면에서 상단의 "+" 버튼을 탭하고 추가하고 싶은 키워드나 주제를 입력하세요. 검색 화면에서도 특정 키워드로 검색한 후 "카테고리에 추가+" 버튼을 통해 추가할 수 있습니다. 추가한 카테고리는 News 탭에서 가로 스크롤로 쉽게 전환하며 볼 수 있습니다.',
    },
    {
      'question': '구독 중인 피드를 관리하려면 어떻게 해야 하나요?',
      'answer':
          '구독 탭에서 구독 중인 모든 피드 목록을 확인할 수 있습니다. 각 피드를 길게 누르면 삭제 또는 수정 옵션이 나타나고, 피드를 탭하면 해당 피드의 상세 페이지로 이동합니다. 상세 페이지에서는 피드 정보 확인과 구독 해제가 가능하며, 알림 설정도 조정할 수 있습니다.',
    },
    {
      'question': '최근 읽은 기사를 확인하는 방법은 무엇인가요?',
      'answer':
          '사이드 메뉴에서 "Recently Read"를 선택하면 최근에 읽은 모든 기사 목록을 시간순으로 정렬하여 볼 수 있습니다. 각 기사에는 읽은 날짜와 시간이 표시되고, 상단에는 검색 필터 기능이 있어 특정 기사를 쉽게 찾을 수 있습니다. 기록을 삭제하려면 기사를 왼쪽으로 스와이프하거나 설정에서 전체 기록을 삭제할 수 있습니다.',
    },
    {
      'question': '뉴스와 RSS 피드의 차이점은 무엇인가요?',
      'answer':
          '뉴스 기능은 다양한 언론사와 소스에서 취합된 최신 기사들을 주제별로 분류하여 보여주는 기능입니다. 반면 RSS 피드는 사용자가 직접 선택한 특정 웹사이트나 블로그의 업데이트만 구독하여 볼 수 있습니다. 뉴스는 더 폭넓은 정보 소비에, RSS는 특정 관심사에 집중된 정보 소비에 적합합니다. 옴니뉴스는 두 기능을 모두 제공하여 사용자가 원하는 방식으로 정보를 접할 수 있게 합니다.',
    },
    {
      'question': '기사가 올바르게 표시되지 않으면 어떻게 해야 하나요?',
      'answer':
          '앱을 최신 버전으로 업데이트했는지 확인하세요. 인터넷 연결 상태를 점검하고, 앱 캐시를 지우거나 앱을 재시작해보세요. 특정 기사나 피드에 문제가 있다면, 해당 피드를 새로고침하거나 구독을 해제했다가 다시 구독해보는 것이 도움이 됩니다. 웹 브라우저로 직접 열기 옵션을 사용하면 원본 사이트에서 직접 콘텐츠를 확인할 수 있습니다.',
    },
    {
      'question': '기사 텍스트 크기를 조절할 수 있나요?',
      'answer':
          '설정 메뉴의 "글자 크기" 옵션에서 앱 전체 텍스트 크기를 조절할 수 있습니다. 작게, 보통, 크게 등 여러 옵션이 제공되며, 변경 시 실시간으로 미리보기를 통해 확인 가능합니다. 또한 기사 상세 페이지에서는 확대/축소 제스처를 통해 해당 기사에 한정하여 글자 크기를 일시적으로 조절할 수도 있습니다.',
    },
    {
      'question': '특정 카테고리나 피드의 정렬 방식을 변경할 수 있나요?',
      'answer':
          '카테고리나 피드 목록 화면 상단의 정렬 옵션을 탭하여 다양한 정렬 기준(최신순, 인기순, 관련성순 등)을 선택할 수 있습니다. RSS 피드의 경우 각 피드별로 정렬 방식을 별도로 설정할 수 있고, 뉴스의 경우 카테고리별로 기본 정렬 방식을 지정할 수 있습니다. 설정 메뉴에서는 앱 전체의 기본 정렬 방식도 변경 가능합니다.',
    },
    {
      'question': '앱에서 알림 설정은 어떻게 관리하나요?',
      'answer':
          '설정 메뉴의 "알림 설정"에서 알림 기능을 켜거나 끌 수 있습니다. 구독 중인 각 피드나 뉴스 카테고리별로 알림을 개별 설정할 수도 있으며, 알림 빈도와 시간대를 지정할 수 있습니다. 중요한 키워드에 대한 알림을 설정하면 해당 키워드가 포함된 새 기사가 등록될 때 알림을 받을 수 있습니다.',
    },
    {
      'question': '옴니뉴스의 오프라인 사용 기능은 어떻게 작동하나요?',
      'answer':
          '옴니뉴스는 최근 읽은 기사와 북마크한 기사를 자동으로 오프라인 저장합니다. 설정에서 "오프라인 모드"를 활성화하면 구독 중인 피드와 주요 뉴스 카테고리를 정기적으로 다운로드하여 인터넷 연결 없이도 읽을 수 있습니다. 데이터 사용량을 제어하기 위해 Wi-Fi에서만 다운로드하도록 설정하거나, 오프라인 저장할 기사 수를 제한할 수 있습니다.',
    },
  ];

  // 사용 가이드 항목
  final List<Map<String, dynamic>> _userGuides = [
    {
      'title': '시작하기',
      'guides': [
        {
          'step': '앱 둘러보기',
          'description':
              '앱을 처음 실행하면 하단 탭에서 구독, RSS, 뉴스, 북마크, 검색 기능에 접근할 수 있습니다.',
        },
        {
          'step': '뉴스 탐색',
          'description':
              '뉴스 탭에서 다양한 카테고리별 최신 뉴스를 한눈에 볼 수 있습니다. 관심 있는 카테고리를 추가하여 맞춤형 뉴스 피드를 만들어보세요.',
        },
        {
          'step': 'RSS 구독 시작',
          'description':
              'RSS 탭에서 "+" 버튼을 탭하여 좋아하는 웹사이트나 블로그의 RSS 피드를 구독할 수 있습니다.',
        },
      ],
    },
    {
      'title': '개인화 설정',
      'guides': [
        {
          'step': '테마 변경',
          'description':
              '사이드 메뉴에서 "Choose Theme"을 선택하여 라이트, 다크, 블루, 페이퍼 모드 중 원하는 테마를 적용할 수 있습니다.',
        },
        {
          'step': '카드 레이아웃 설정',
          'description':
              '설정에서 기사 카드 표시 방식(간단히/상세히)을 변경하고 이미지 표시 여부도 조정할 수 있습니다.',
        },
        {
          'step': '알림 맞춤설정',
          'description':
              '설정에서 알림 수신 여부와 빈도를 조정하고, 중요 키워드나 특정 피드에 대한 알림을 별도로 관리할 수 있습니다.',
        },
      ],
    },
    {
      'title': '고급 기능',
      'guides': [
        {
          'step': '북마크 관리',
          'description':
              '북마크한 기사는 카테고리별로 정리되며, 나중에 찾기 쉽도록 태그를 추가하거나 검색할 수 있습니다.',
        },
        {
          'step': '기사 공유',
          'description':
              '기사 상세 화면에서 공유 아이콘을 탭하여 다른 앱으로 기사를 공유하거나 링크를 복사할 수 있습니다.',
        },
        {
          'step': '데이터 사용 최적화',
          'description':
              '설정에서 이미지 자동 로딩을 비활성화하거나 Wi-Fi에서만 콘텐츠를 다운로드하도록 설정하여 데이터 사용량을 절약할 수 있습니다.',
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
                    '기사 목록에서 아래로 당기면 새로고침됩니다. 기사 카드를 좌우로 스와이프하면 빠르게 북마크하거나 숨길 수 있습니다.',
              ),

              _buildTipCard(
                context,
                icon: Icons.format_size,
                title: '카드 모드 설정',
                tip: '설정 메뉴에서 기사 카드뷰 모드를 간단히/상세히 중 선택하여 더 효율적인 정보 탐색이 가능합니다.',
              ),

              _buildTipCard(
                context,
                icon: Icons.watch_later_outlined,
                title: '최근 읽은 글',
                tip:
                    '사이드 메뉴의 "Recently Read"에서 최근 읽은 기사를 날짜별로 확인하고, 검색 기능으로 과거에 읽었던 특정 기사를 빠르게 찾을 수 있습니다.',
              ),

              _buildTipCard(
                context,
                icon: Icons.bookmark_border,
                title: '북마크 관리',
                tip:
                    '북마크 탭에서 기사를 길게 누르면 다중 선택 모드가 활성화되어 여러 기사를 한 번에 관리할 수 있습니다. 상단의 필터 버튼으로 소스나 날짜별 정렬도 가능합니다.',
              ),

              _buildTipCard(
                context,
                icon: Icons.share,
                title: '기사 공유',
                tip:
                    '기사 상세 화면의 공유 버튼으로 다양한 앱에 기사를 공유하거나, 링크를 복사하여 메모나 다른 앱에 붙여넣을 수 있습니다.',
              ),

              const SizedBox(height: 32),

              // TODO 아니면 지우기
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
                // Material 아이콘 대신 앱 아이콘 이미지 사용
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
              'Omni News는 다양한 뉴스 소스와 RSS 피드를 한 곳에서 쉽게 관리하고 읽을 수 있는 올인원 뉴스 앱입니다. 관심 있는 주제의 최신 기사를 자동으로 수집하고, 좋아하는 웹사이트의 RSS 피드를 구독하여 맞춤형 뉴스 경험을 제공합니다. 깔끔한 인터페이스와 다양한 테마 옵션, 그리고 오프라인 읽기 기능까지 갖춰 언제 어디서나 편리하게 정보를 접할 수 있습니다.',
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

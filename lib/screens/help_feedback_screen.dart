import 'package:flutter/material.dart';
import 'package:omninews_test_flutter/utils/url_launcher_helper.dart';
import 'package:provider/provider.dart';
import 'package:omninews_test_flutter/provider/settings_provider.dart';
import 'package:omninews_test_flutter/services/feedback_service.dart'; // 추가된 서비스 임포트

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _feedbackSubmitted = false;

  // FAQ 항목들
  final List<Map<String, String>> _faqItems = [
    {
      'question': 'RSS 피드를 구독하려면 어떻게 해야 하나요?',
      'answer':
          'RSS 화면에서 "+" 버튼을 탭하고 RSS URL을 입력하거나, 검색 기능을 사용하여 원하는 피드를 찾아 구독 버튼을 누르세요.'
    },
    {
      'question': '기사를 북마크하는 방법은 무엇인가요?',
      'answer':
          '각 기사 카드에 있는 북마크 아이콘을 탭하면 북마크에 추가됩니다. 북마크된 기사는 북마크 탭에서 확인할 수 있습니다.'
    },
    {
      'question': '다크 모드로 전환하려면 어떻게 해야 하나요?',
      'answer':
          '사이드 메뉴에서 "Choose Theme"를 탭하여 라이트 모드, 블루 모드, 다크 모드 설정 중에서 선택할 수 있습니다.'
    },
    {
      'question': '뉴스 카테고리는 어떻게 추가하나요?',
      'answer':
          'News 화면에서 "+" 버튼을 탭하고 추가하고 싶은 키워드를 입력하거나, 검색 기능을 사용하여 원하는 뉴스 키워드를 입력하고 "카테고리에 추가+" 버튼을 누르세요.'
    },
    {
      'question': '구독 중인 피드를 관리하려면 어떻게 해야 하나요?',
      'answer':
          '구독 탭에서 구독 중인 모든 피드를 확인할 수 있으며, 각 피드를 길게 누르거나 세부 정보 화면에서 구독 해제할 수 있습니다.'
    },
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // 피드백 제출 함수 - 서버로 전송
  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 서비스를 통해 피드백 제출
      final success = await FeedbackService.submitFeedback(
        content: _feedbackController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );

      if (mounted) {
        if (success) {
          setState(() {
            _isSubmitting = false;
            _feedbackSubmitted = true;
            _feedbackController.clear();
            _emailController.clear();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('피드백이 성공적으로 제출되었습니다. 감사합니다!'),
              backgroundColor: Theme.of(context).primaryColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          setState(() {
            _isSubmitting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('피드백 제출 중 오류가 발생했습니다. 나중에 다시 시도해주세요.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('도움말 & 피드백'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 도움말 섹션
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

              const SizedBox(height: 32),

              // 피드백 섹션
              _buildSectionTitle(context, '피드백 보내기'),
              const SizedBox(height: 12),

              _feedbackSubmitted
                  ? _buildFeedbackSuccess(theme)
                  : _buildFeedbackForm(theme, textTheme),

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
                  UrlLauncherHelper.openUrl(context,
                      'mailto:kang3171611@naver.com', settings.webOpenMode);
                },
              ),

              // GitHub 연락처
              _buildContactItem(
                context,
                icon: Icons.code,
                title: 'GitHub',
                value: 'github.com/kang1027/omninews',
                onTap: () {
                  UrlLauncherHelper.openUrl(context,
                      'https://github.com/kang1027', settings.webOpenMode);
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
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: theme.primaryColor,
              size: 24,
            ),
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
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
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

  // 피드백 성공 메시지 위젯
  Widget _buildFeedbackSuccess(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: theme.primaryColor,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            '피드백을 보내주셔서 감사합니다!',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '귀하의 소중한 의견은 앱을 개선하는 데 큰 도움이 됩니다.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _feedbackSubmitted = false;
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              foregroundColor: theme.primaryColor,
              side: BorderSide(color: theme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('다른 피드백 작성하기'),
          ),
        ],
      ),
    );
  }

  // 피드백 양식 위젯
  Widget _buildFeedbackForm(ThemeData theme, TextTheme textTheme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '앱 개선을 위한 의견이나 버그 리포트를 보내주세요.',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),

          // 이메일 입력 필드
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: '이메일 (선택사항)',
              hintText: '회신을 원하시면 이메일을 입력하세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor:
                  theme.inputDecorationTheme.fillColor ?? theme.cardColor,
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                // 간단한 이메일 유효성 검사
                final bool isValid =
                    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
                if (!isValid) {
                  return '유효한 이메일 주소를 입력해주세요';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 피드백 내용 입력 필드
          TextFormField(
            controller: _feedbackController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: '피드백',
              hintText: '의견이나 개선사항을 자유롭게 작성해주세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor:
                  theme.inputDecorationTheme.fillColor ?? theme.cardColor,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '피드백 내용을 입력해주세요';
              }
              if (value.trim().length < 10) {
                return '최소 10자 이상 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // 제출 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '피드백 보내기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
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
            Icon(
              icon,
              color: theme.primaryColor,
              size: 22,
            ),
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

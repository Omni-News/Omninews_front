import 'dart:io';
import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/omninews_subscription.dart'; // 구독 모델 필요
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/screens/home_screen.dart';
import 'package:omninews_flutter/screens/omninews_subscription/omninews_subscription_home.dart';
// [✅ 복원] 로컬 구독 서비스 import 복원
import 'package:omninews_flutter/services/omninews_subscription/omninews_subscription_service.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
// [✅ 추가] Provider와 AdManager 임포트
import 'package:provider/provider.dart';
import 'package:omninews_flutter/utils/ad_manager.dart'; // AdManager 경로 (정확히 확인)

class RssAddScreen extends StatefulWidget {
  final Function onChannelAdded;

  const RssAddScreen({super.key, required this.onChannelAdded});

  @override
  State<RssAddScreen> createState() => _RssAddScreenState();
}

class _RssAddScreenState extends State<RssAddScreen>
    with SingleTickerProviderStateMixin {
  // --- Controllers (변경 없음) ---
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _generateUrlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cssChannelLinkController =
      TextEditingController();
  final TextEditingController _cssChannelImageController =
      TextEditingController();
  final TextEditingController _cssChannelTitleController =
      TextEditingController();
  final TextEditingController _cssChannelDescController =
      TextEditingController();
  final TextEditingController _cssChannelLangController = TextEditingController(
    text: "ko-KR",
  );
  final TextEditingController _cssItemTitleController = TextEditingController();
  final TextEditingController _cssItemDescController = TextEditingController();
  final TextEditingController _cssItemLinkController = TextEditingController();
  final TextEditingController _cssItemAuthorController =
      TextEditingController();
  final TextEditingController _cssItemPubDateController =
      TextEditingController();
  final TextEditingController _cssItemImageController = TextEditingController();

  // --- State variables ---
  bool _showCssForm = false;
  bool _isCssGenerating = false;
  bool _isLoading = false;
  bool _isPreviewLoading = false;
  bool _isGenerating = false;
  RssChannel? _previewChannel;
  String? _errorMessage;
  bool _isExistingRss = false;
  bool _isAlreadySubscribed =
      false; // Note: This checks if *this specific channel* is already subscribed
  int? _channelId;
  late TabController _tabController;
  String _selectedPlatform = 'Naver';
  String _searchQuery = '';
  bool _instagramItemsPending = false;
  bool _generatedExisted = false;

  // [✅ 복원] 로컬 구독 상태 변수 복원
  SubscriptionStatus? _subscriptionStatus;
  bool _isLoadingSubscriptionStatus = true;

  // --- Platform Data (변경 없음) ---
  final List<Map<String, dynamic>> _platforms = [
    {
      'id': 'Naver',
      'name': '네이버',
      'icon': Icons.public,
      'color': const Color(0xFF03C75A),
      'keywords': ['네이버', '네', 'naver', 'n'],
    },
    {
      'id': 'Tistory',
      'name': '티스토리',
      'icon': Icons.web,
      'color': const Color(0xFFEA4335),
      'keywords': ['티스토리', '티', 'tistory', 't'],
    },
    {
      'id': 'Medium',
      'name': '미디엄',
      'icon': Icons.article_outlined,
      'color': const Color(0xFF000000),
      'keywords': ['미디엄', '미', 'medium', 'm'],
    },
    {
      'id': 'Instagram',
      'name': '인스타그램',
      'icon': Icons.camera_alt,
      'color': const Color(0xFFE1306C),
      'keywords': ['인스타그램', '인스타', '인', 'instagram', 'insta', 'i'],
    },
    {
      'id': 'Web',
      'name': '기타 웹사이트',
      'icon': Icons.language,
      'color': Colors.blueGrey,
      'keywords': ['기타', '웹', 'web', 'generic', 'any', '임의', 'w', 'g'],
    },
  ];

  List<Map<String, dynamic>> get _filteredPlatforms {
    if (_searchQuery.isEmpty) return _platforms;
    return _platforms.where((p) {
      final keywords = p['keywords'] as List;
      return keywords.any(
        (k) => k.toString().toLowerCase().contains(_searchQuery.toLowerCase()),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // [✅ 복원] 로컬 구독 상태 확인 호출
    _checkSubscriptionStatus();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // --- Dispose controllers ---
    _urlController.dispose();
    _generateUrlController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    _cssChannelLinkController.dispose();
    _cssChannelImageController.dispose();
    _cssChannelTitleController.dispose();
    _cssChannelDescController.dispose();
    _cssChannelLangController.dispose();
    _cssItemTitleController.dispose();
    _cssItemDescController.dispose();
    _cssItemLinkController.dispose();
    _cssItemAuthorController.dispose();
    _cssItemPubDateController.dispose();
    _cssItemImageController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  // [✅ 복원] 로컬 구독 상태 확인 함수 복원
  Future<void> _checkSubscriptionStatus() async {
    setState(() => _isLoadingSubscriptionStatus = true);
    final service = SubscriptionService(); // 로컬 서비스 사용
    final status = await service.checkSubscriptionStatus();
    if (!mounted) return;
    setState(() {
      _subscriptionStatus = status; // 로컬 상태 업데이트
      _isLoadingSubscriptionStatus = false;
    });
  }

  // 구독 페이지 이동 후, 로컬 상태 새로고침
  Future<void> _openSubscriptionAndRefresh() async {
    if (Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('구독 정보는 서버에서 자동으로 관리됩니다.'),
        ),
      );
      return;
    }
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionHomePage()),
    );
    if (changed == true && mounted) {
      // [✅ 복원] 로컬 상태 갱신
      await _checkSubscriptionStatus();
      _showSnackBar('구독이 활성화되었습니다.');
    }
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.scheme.isNotEmpty && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // --- RSS 미리보기, 추가, 구독 관련 로직 (변경 없음) ---
  Future<void> _previewRss() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'URL을 입력해 주세요.';
        _previewChannel = null;
      });
      return;
    }

    setState(() {
      _isPreviewLoading = true;
      _errorMessage = null;
      _previewChannel = null;
      _isExistingRss = false;
      _isAlreadySubscribed = false;
      _channelId = null;
      _instagramItemsPending = false;
      _generatedExisted = false;
    });

    try {
      final preview = await RssService.previewRssFromUrl(url);
      if (preview != null) {
        final exists = await RssService.checkRssExists(url);
        final already = await RssService.isChannelAlreadySubscribed(
          preview.channelRssLink,
        );
        if (!mounted) return;
        setState(() {
          _previewChannel = preview;
          _isExistingRss = exists; // DB 존재 여부 업데이트
          _isAlreadySubscribed = already; // 내가 구독 중인지 업데이트
        });
        if (already) _showSnackBar('이미 구독 중인 RSS 채널입니다.');
      } else {
        if (!mounted) return;
        setState(() => _errorMessage = 'RSS 피드를 불러오지 못했습니다.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isPreviewLoading = false);
      }
    }
  }

  Future<void> _addRssToDb() async {
    if (_previewChannel == null) return;
    final url = _urlController.text.trim();
    setState(() {
      _isLoading = true; // isLoading은 버튼 비활성화용으로 계속 사용
      _errorMessage = null;
    });
    try {
      final id = await RssService.addRssToDb(url);
      if (id != null && id != 0) {
        _channelId = id;
        if (!mounted) return;
        setState(() {
          _isExistingRss = true; // DB에 추가되었으므로 true로 변경
          _isLoading = false;
        });
        _showSnackBar('RSS를 추가했습니다. 이제 구독할 수 있습니다.');
        // 미리보기 상태 업데이트 (이제 '구독하기' 버튼이 보이도록)
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'RSS 추가 중 오류가 발생했습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'RSS 추가 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _subscribeChannel() async {
    if (_previewChannel == null) return;
    setState(() => _isLoading = true); // isLoading은 버튼 비활성화용으로 계속 사용
    try {
      bool success;
      if (_channelId != null) {
        success = await RssService.subscribeChannel(_channelId!);
      } else {
        success = await RssService.subscribeChannelByRssLink(
          _previewChannel!.channelRssLink,
        );
      }
      if (success) {
        widget.onChannelAdded(); // 부모 위젯에 알림
        if (!mounted) return;
        _navigateToRssScreen(); // 홈 화면으로 이동
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = '이미 구독 중인 채널입니다.';
          _isAlreadySubscribed = true; // 상태 업데이트
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '구독 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }
  // --- END: RSS 미리보기, 추가, 구독 관련 로직 ---

  // [✅ 추가] "RSS 추가하기" 버튼에 대한 광고 처리 래퍼
  Future<void> _handleAddRssWithAd() async {
    // 1. 로컬 구독 상태 확인
    if (_subscriptionStatus?.isActive == true) {
      // 구독자는 광고 없이 바로 실행
      await _addRssToDb();
      return;
    }

    // 2. 비구독자인 경우, AdManager 접근
    if (!mounted) return;
    final adManager = Provider.of<AdManager>(context, listen: false);

    await adManager.executeRewardedAction(
      action: _addRssToDb, // 보상 획득 시 실행할 함수
      onAdDismissedWithoutReward: () {
        if (!mounted) return;
        _showSnackBar("광고 시청을 완료해야 RSS를 추가할 수 있습니다.");
      },
      onAdFailed: () {
        if (!mounted) return;
        _showSnackBar("광고를 준비 중입니다. RSS를 바로 추가합니다.");
      },
    );
  }

  // --- 실제 RSS 생성 로직 (변경 없음, 광고 로직 없음) ---
  Future<void> _generateRssByCss() async {
    // [✅ 확인] 광고 로직 없이 직접 실행 (구독 여부는 _buildGenerateTab에서 UI 분기)
    if (_isCssGenerating) return;

    setState(() {
      _isCssGenerating = true;
      _errorMessage = null;
      _previewChannel = null;
      _instagramItemsPending = false;
      _generatedExisted = false;
    });

    // 필수값 체크
    if (_cssChannelLinkController.text.trim().isEmpty ||
        _cssChannelTitleController.text.trim().isEmpty ||
        _cssItemTitleController.text.trim().isEmpty ||
        _cssItemLinkController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = '필수 항목을 모두 입력해 주세요.';
        _isCssGenerating = false;
      });
      return;
    }

    try {
      final body = {
        "channel_link": _cssChannelLinkController.text.trim(),
        "channel_image_link": _cssChannelImageController.text.trim(),
        "channel_title": _cssChannelTitleController.text.trim(),
        "channel_description": _cssChannelDescController.text.trim(),
        "channel_language": _cssChannelLangController.text.trim(),
        "item_title_css": _cssItemTitleController.text.trim(),
        "item_description_css": _cssItemDescController.text.trim(),
        "item_link_css": _cssItemLinkController.text.trim(),
        "item_author_css": _cssItemAuthorController.text.trim(),
        "item_pub_date_css": _cssItemPubDateController.text.trim(),
        "item_image_css": _cssItemImageController.text.trim(),
      };

      final response = await RssService.generateRssByCss(body);

      if (response != null) {
        final existedBefore = RssService.lastGenerateIsExist == true;
        setState(() {
          _previewChannel = response;
          _isExistingRss = true;
          _channelId = response.channelId;
          _generatedExisted = existedBefore;
          _errorMessage = null;
        });
        if (existedBefore) {
          _showSnackBar('이미 존재하는 RSS입니다. 바로 구독할 수 있습니다.');
        } else {
          _showSnackBar('RSS를 성공적으로 생성했습니다. 이제 구독할 수 있습니다.');
        }
      } else {
        setState(
          () => _errorMessage = 'RSS 생성에 실패했습니다. CSS 셀렉터와 채널 정보를 확인해 주세요.',
        );
      }
    } catch (e) {
      setState(() => _errorMessage = '오류가 발생했습니다: $e');
    } finally {
      setState(() => _isCssGenerating = false);
    }
  }

  Future<void> _generateRss() async {
    // [✅ 확인] 광고 로직 없이 직접 실행 (구독 여부는 _buildGenerateTab에서 UI 분기)
    if (_isGenerating) return;

    final url = _generateUrlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'URL을 입력해 주세요.');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _previewChannel = null;
      _instagramItemsPending = false;
      _generatedExisted = false;
    });

    try {
      final platformForApi =
          _selectedPlatform == 'Web' ? 'Default' : _selectedPlatform;
      final generatedChannel = await RssService.generateRss(
        url,
        platformForApi,
      );

      if (generatedChannel != null) {
        final existedBefore = RssService.lastGenerateIsExist == true;

        setState(() {
          _previewChannel = generatedChannel;
          _isExistingRss = true;
          _channelId = generatedChannel.channelId;
          _generatedExisted = existedBefore;
        });

        if (existedBefore) {
          _showSnackBar('이미 존재하는 RSS입니다. 바로 구독할 수 있습니다.');
        } else {
          _showSnackBar('RSS를 성공적으로 생성했습니다. 이제 구독할 수 있습니다.');
        }
      } else {
        setState(() => _errorMessage = 'RSS 생성에 실패했습니다. 주소가 올바른지 확인해 주세요.');
      }
    } catch (e) {
      setState(() => _errorMessage = '오류가 발생했습니다: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }
  // --- END: 실제 RSS 생성 로직 ---

  // --- Navigation & Snackbar (변경 없음) ---
  void _navigateToRssScreen() {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(initialTabIndex: 1),
      ),
    );
    _showSnackBar('RSS 채널을 구독했습니다.');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    // AdManager는 광고 호출을 위해서만 사용 (상태 관찰 불필요 시 listen: false)
    // final adManager = context.read<AdManager>(); // or Provider.of<AdManager>(context, listen: false);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('RSS 추가', style: textTheme.headlineMedium),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.disabledColor,
          indicatorColor: theme.primaryColor,
          tabs: const [Tab(text: 'RSS 추가'), Tab(text: 'RSS 생성')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddExistingTab(
            theme,
            textTheme,
            colorScheme,
          ), // AdManager 전달 제거
          _buildGenerateTab(theme, textTheme, colorScheme), // AdManager 전달 제거
        ],
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildAddExistingTab(
    ThemeData theme,
    TextTheme textTheme,
    ColorScheme colorScheme,
    // AdManager 전달 제거
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RSS 피드 주소 입력',
              style: textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'RSS 주소를 입력한 뒤, 미리보기를 눌러 확인해 주세요.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _buildUrlInputField(theme), // 미리보기 버튼 포함
            if (_errorMessage != null && _tabController.index == 0)
              _buildErrorMessage(colorScheme),
            // 미리보기 결과 및 "RSS 추가/구독" 버튼 표시
            if (_previewChannel != null && _tabController.index == 0)
              _buildPreviewSection(theme, textTheme), // AdManager 전달 제거
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateTab(
    ThemeData theme,
    TextTheme textTheme,
    ColorScheme colorScheme,
    // AdManager 전달 제거
  ) {
    final isWebSelected = _selectedPlatform == "Web";
    // [✅ 복원] 로컬 구독 상태 사용
    final bool isSubscribed = _subscriptionStatus?.isActive == true;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child:
            _isLoadingSubscriptionStatus // [✅ 복원] 로컬 로딩 상태 사용
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPremiumFeatureBanner(theme, textTheme),
                    const SizedBox(height: 20),
                    // [✅ 복원] 로컬 구독 상태(isSubscribed)로 UI 분기
                    if (isSubscribed) ...[
                      // --- 구독자 UI ---
                      _buildPlatformSelectionSection(theme, textTheme),
                      const SizedBox(height: 24),
                      if (isWebSelected && _showCssForm) ...[
                        // --- CSS 폼 ---
                        _buildCssRssForm(
                          theme,
                          textTheme,
                        ), // isSubscribed 전달 제거
                        if (_errorMessage != null && _tabController.index == 1)
                          _buildErrorMessage(colorScheme),
                        if (_previewChannel != null &&
                            _tabController.index == 1)
                          _buildPreviewSection(
                            theme,
                            textTheme,
                          ), // AdManager 전달 제거
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed:
                                () => setState(() {
                                  _showCssForm = false;
                                  _errorMessage = null;
                                }),
                            child: const Text('자동 추출로 돌아가기'),
                          ),
                        ),
                      ] else ...[
                        // --- 일반 URL 입력 폼 ---
                        Text(
                          '사이트 주소 입력',
                          style: textTheme.titleLarge?.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '선택한 플랫폼의 채널 또는 페이지 주소를 입력해 주세요.',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        _buildGenerateUrlInputField(
                          theme,
                        ), // isSubscribed 전달 제거
                        if (_errorMessage != null && _tabController.index == 1)
                          _buildErrorMessage(colorScheme),
                        if (_previewChannel != null &&
                            _tabController.index == 1)
                          _buildPreviewSection(
                            theme,
                            textTheme,
                          ), // AdManager 전달 제거
                        // CSS 폼으로 전환 버튼
                        if (isWebSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed:
                                    _isGenerating
                                        ? null
                                        : () =>
                                            setState(() => _showCssForm = true),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: BorderSide(color: theme.primaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('CSS 요소로 직접 생성하기'),
                              ),
                            ),
                          ),
                      ],
                    ] else ...[
                      // --- 비구독자 UI ---
                      // "RSS 생성" 탭에서는 기능을 바로 보여주지 않고 구독 유도 프롬프트만 표시
                      _buildSubscriptionPrompt(theme, textTheme),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
      ),
    );
  }

  // [✅ 복원] isSubscribed 매개변수 제거, 내부 버튼은 광고 로직 없음
  Widget _buildCssRssForm(ThemeData theme, TextTheme textTheme) {
    InputDecoration cssInputDeco(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );

    // [✅ 복원] 버튼 텍스트/아이콘 고정 (광고 없음)
    const String buttonText = 'CSS 요소로 RSS 생성';
    const IconData buttonIcon = Icons.auto_awesome;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ... (CSS 폼 TextField들은 동일) ...
        Text('채널 정보 입력', style: textTheme.titleLarge?.copyWith(fontSize: 16)),
        const SizedBox(height: 10),
        TextField(
          controller: _cssChannelLinkController,
          decoration: cssInputDeco('채널 사이트 링크 (필수)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cssChannelImageController,
          decoration: cssInputDeco('채널 이미지 링크 (선택)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cssChannelTitleController,
          decoration: cssInputDeco('채널 제목 (필수)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cssChannelDescController,
          decoration: cssInputDeco('채널 설명'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cssChannelLangController,
          decoration: cssInputDeco('채널 언어 (기본: ko-KR)'),
        ),
        const SizedBox(height: 14),
        Text(
          '아이템 CSS 선택자 입력',
          style: textTheme.titleLarge?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _cssItemTitleController,
          decoration: cssInputDeco('아이템 제목 CSS (필수)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cssItemDescController,
          decoration: cssInputDeco('아이템 설명 CSS'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cssItemLinkController,
          decoration: cssInputDeco('아이템 링크 CSS (필수)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cssItemAuthorController,
          decoration: cssInputDeco('아이템 작성자 CSS'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cssItemPubDateController,
          decoration: cssInputDeco('아이템 게시일 CSS'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cssItemImageController,
          decoration: cssInputDeco('아이템 이미지 CSS'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            // Use ElevatedButton.icon
            // [✅ 복원] 광고 로직 없이 _generateRssByCss 직접 호출
            onPressed: _isCssGenerating ? null : _generateRssByCss,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor, // 프리미엄 기능이므로 primaryColor 사용
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              disabledBackgroundColor: theme.primaryColor.withOpacity(0.5),
            ),
            icon:
                _isCssGenerating
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Icon(buttonIcon, size: 18),
            label: Text(
              _isCssGenerating ? '생성 중...' : buttonText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformSelectionSection(ThemeData theme, TextTheme textTheme) {
    // --- (변경 없음) ---
    final platforms = _filteredPlatforms;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '사이트 선택',
            style: textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildSearchField(theme),
        const SizedBox(height: 16),
        platforms.isEmpty
            ? _buildEmptySearchResult(theme)
            : SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: platforms.length,
                itemBuilder: (context, index) {
                  final p = platforms[index];
                  final sel = _selectedPlatform == p['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPlatform = p['id'];
                          _instagramItemsPending = false; // 플랫폼 변경 시 초기화
                          _generatedExisted = false;
                        });
                      },
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: sel ? p['color'] : theme.cardColor,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: sel ? p['color'] : theme.dividerColor,
                                width: 2,
                              ),
                              boxShadow:
                                  sel
                                      ? [
                                        BoxShadow(
                                          color: p['color'].withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                      : [],
                            ),
                            child: Icon(
                              p['icon'],
                              color: sel ? Colors.white : p['color'],
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p['name'],
                            style: TextStyle(
                              color: sel ? theme.primaryColor : theme.hintColor,
                              fontWeight:
                                  sel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      ],
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    // --- (변경 없음) ---
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color:
                  theme.brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '검색',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        theme.brightness == Brightness.dark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color:
                        theme.brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatureBanner(ThemeData theme, TextTheme textTheme) {
    // --- (변경 없음) ---
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withBlue(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            '프리미엄 기능',
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInputField(ThemeData theme) {
    // --- (변경 없음) ---
    return _buildUrlBox(
      theme: theme,
      controller: _urlController,
      hint: 'https://example.com/rss',
      onSubmit: _previewRss,
      buttonLabel: 'RSS 미리보기',
      loading: _isPreviewLoading,
      onPressed: _previewRss,
      mainColor: theme.primaryColor,
    );
  }

  // [✅ 복원] isSubscribed 매개변수 제거, 내부 버튼은 광고 로직 없음
  Widget _buildGenerateUrlInputField(ThemeData theme) {
    // [✅ 복원] 버튼 텍스트/아이콘 고정 (광고 없음)
    const String buttonText = 'RSS 생성하기';
    const IconData buttonIcon = Icons.auto_awesome;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _generateUrlController,
            // ...(TextField 설정 동일)...
            decoration: InputDecoration(
              hintText: _getUrlHintByPlatform(),
              hintStyle: TextStyle(color: theme.hintColor),
              filled: true,
              fillColor: theme.cardColor,
              prefixIcon: Icon(
                Icons.link,
                color: theme.iconTheme.color?.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dividerColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.green, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
            // [✅ 복원] 광고 로직 없이 _generateRss 직접 호출
            onSubmitted: (_) => _generateRss,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              // Use ElevatedButton.icon
              // [✅ 복원] 광고 로직 없이 _generateRss 직접 호출
              onPressed: _isGenerating ? null : _generateRss,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // 생성 버튼 색상
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBackgroundColor: Colors.green.withOpacity(0.5),
              ),
              icon:
                  _isGenerating
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Icon(buttonIcon, size: 20),
              label: Text(
                _isGenerating ? '생성 중...' : buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlBox({
    required ThemeData theme,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onSubmit,
    required VoidCallback onPressed,
    required String buttonLabel,
    required bool loading,
    required Color mainColor,
  }) {
    // --- (변경 없음) ---
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: theme.hintColor),
              filled: true,
              fillColor: theme.cardColor,
              prefixIcon: Icon(
                Icons.link,
                color: theme.iconTheme.color?.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.dividerColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: mainColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBackgroundColor: mainColor.withOpacity(0.5),
              ),
              child:
                  loading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUrlHintByPlatform() {
    // --- (변경 없음) ---
    switch (_selectedPlatform) {
      case 'Naver':
        return 'https://blog.naver.com/사용자명';
      case 'Tistory':
        return 'https://사용자명.tistory.com';
      case 'Medium':
        return 'https://medium.com/@사용자명';
      case 'Instagram':
        return 'https://www.instagram.com/사용자명';
      case 'Web':
        return 'https://example.com/원하는_페이지';
      default:
        return 'https://...';
    }
  }

  Widget _buildEmptySearchResult(ThemeData theme) {
    // --- (변경 없음) ---
    return SizedBox(
      height: 90,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 30, color: theme.disabledColor),
          const SizedBox(height: 8),
          Text(
            '검색 결과가 없습니다',
            style: TextStyle(color: theme.disabledColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPrompt(ThemeData theme, TextTheme textTheme) {
    // --- (변경 없음, 생성 탭에서만 사용됨) ---
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primaryColor.withOpacity(0.1),
            ),
            child: Icon(
              Icons.lock_outline,
              size: 36,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'RSS 생성 기능은 구독자 전용 기능입니다',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'RSS가 제공되지 않는 사이트도 손쉽게 RSS로 만들어 구독할 수 있습니다. 구독을 통해 이 기능을 이용해 보세요.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _openSubscriptionAndRefresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              '구독하고 이용하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ColorScheme colorScheme) {
    // --- (변경 없음) ---
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: colorScheme.error, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [✅ 수정] AdManager 전달 제거
  Widget _buildPreviewSection(ThemeData theme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Row(
          children: [
            Icon(Icons.preview, size: 22, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'RSS 미리보기',
              style: textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_generatedExisted) _buildExistInfoBanner(theme),
        if (_instagramItemsPending) _buildInstagramPendingBanner(theme),
        _buildPreviewCard(theme, textTheme), // AdManager 전달 제거
      ],
    );
  }

  Widget _buildExistInfoBanner(ThemeData theme) {
    // --- (변경 없음) ---
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '이미 존재하는 RSS 채널입니다. 생성 없이 바로 구독할 수 있어요.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstagramPendingBanner(ThemeData theme) {
    // --- (변경 없음) ---
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '인스타그램 채널이 생성되었습니다.\n게시물을 수집 중입니다(약 30~60초 소요). 잠시 후 새로고침하거나 홈에서 확인하세요.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [✅ 수정] AdManager 전달 제거
  Widget _buildPreviewCard(ThemeData theme, TextTheme textTheme) {
    if (_previewChannel == null) return const SizedBox.shrink();
    final rssTheme = AppTheme.rssThemeOf(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (채널 정보 표시 동일) ...
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    rssTheme.channelImageBorderRadius,
                  ),
                  child:
                      _isValidImageUrl(_previewChannel!.channelImageUrl)
                          ? Image.network(
                            _previewChannel!.channelImageUrl!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    _buildDefaultChannelIcon(rssTheme),
                          )
                          : _buildDefaultChannelIcon(rssTheme),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _previewChannel!.channelTitle,
                        style: textTheme.titleLarge?.copyWith(fontSize: 18),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _previewChannel!.channelLink,
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _previewChannel!.channelDescription,
              style: textTheme.bodyMedium?.copyWith(height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Wrap(
              // 정보 칩들
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  label: '언어: ${_previewChannel!.channelLanguage}',
                  icon: Icons.language,
                  theme: theme,
                ),
                _buildInfoChip(
                  label: '랭크: ${_previewChannel!.channelRank}',
                  icon: Icons.star,
                  iconColor: Colors.amber,
                  theme: theme,
                ),
                if (_previewChannel!.rssGenerator != null &&
                    _previewChannel!.rssGenerator != 'None')
                  _buildInfoChip(
                    label: _previewChannel!.rssGenerator!,
                    icon: Icons.settings,
                    theme: theme,
                  ),
                if (_tabController.index == 1) // 생성 탭에서 생성된 경우
                  _buildInfoChip(
                    label: '프리미엄으로 생성',
                    icon: Icons.stars,
                    iconColor: Colors.amber,
                    theme: theme,
                  ),
                if (_instagramItemsPending)
                  _buildInfoChip(
                    label: '수집 중',
                    icon: Icons.downloading,
                    iconColor: theme.colorScheme.primary,
                    theme: theme,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // [✅ 수정] 버튼 빌더 호출 시 AdManager 전달 제거
            _buildSubscriptionButton(theme, rssTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required IconData icon,
    Color? iconColor,
    required ThemeData theme,
  }) {
    // --- (변경 없음) ---
    final chipTheme = theme.chipTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor ?? theme.iconTheme.color?.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(label, style: chipTheme.labelStyle),
        ],
      ),
    );
  }

  // [✅ 수정] AdManager 매개변수 제거, 내부에서 로컬 구독 상태 사용
  Widget _buildSubscriptionButton(ThemeData theme, dynamic rssTheme) {
    if (_isAlreadySubscribed) {
      // --- 이미 구독 중인 채널 버튼 (변경 없음) ---
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text(
            '이미 구독 중인 채널',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.disabledColor.withOpacity(0.2),
            foregroundColor: theme.disabledColor,
            disabledBackgroundColor: theme.disabledColor.withOpacity(0.2),
            disabledForegroundColor: theme.disabledColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    // --- 추가 또는 구독 버튼 ---
    final bool addingNew = !_isExistingRss; // DB에 없는 새로운 RSS인가?
    // [✅ 수정] 로컬 구독 상태 사용
    final bool isSubscribedUser = _subscriptionStatus?.isActive == true;
    final bool isRewardedAdLoaded = AdManager.isRewardedInterstitialAdLoaded;

    // 버튼 텍스트와 아이콘 결정
    String buttonText;
    IconData buttonIcon;
    VoidCallback? onPressedAction;

    if (addingNew) {
      // DB에 없는 RSS 추가 시
      buttonText = isSubscribedUser ? 'RSS 추가하기' : '광고 보고 추가';
      buttonIcon =
          isSubscribedUser ? Icons.add_circle_outline : Icons.ads_click;
      // [✅ 수정] 광고 로드 상태 및 _isLoading 체크
      onPressedAction =
          (_isLoading || (!isSubscribedUser && !isRewardedAdLoaded))
              ? null // 로딩 중이거나, 비구독자인데 광고 로드 안됐으면 비활성화
              : _handleAddRssWithAd;
    } else {
      // DB에 이미 있는 RSS 구독 시
      buttonText = '구독하기';
      buttonIcon = Icons.rss_feed;
      onPressedAction = _isLoading ? null : _subscribeChannel;
    }

    // 버튼 스타일 결정 (색상 등)
    final isGeneratedRssPreview =
        _tabController.index == 1; // 미리보기가 생성 탭에서 온 것인가?
    Color buttonColor =
        addingNew
            ? (isGeneratedRssPreview
                ? theme.primaryColor
                : Colors.green) // 추가 시 색상
            : rssTheme.subscribeButtonActiveBackground; // 구독 시 색상

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressedAction,
        icon:
            (_isLoading ||
                    (addingNew &&
                        !isSubscribedUser &&
                        !isRewardedAdLoaded &&
                        !_isLoading))
                ? const SizedBox(
                  /* Loading or Ad Loading Indicator */
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Icon(buttonIcon, size: 18),
        label: Text(
          // [✅ 수정] 광고 로딩 중일 때 텍스트 변경 (선택적)
          (addingNew && !isSubscribedUser && !isRewardedAdLoaded && !_isLoading)
              ? '광고 로딩 중...'
              : buttonText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor, // 결정된 색상
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBackgroundColor: buttonColor.withOpacity(0.5),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildDefaultChannelIcon(dynamic rssTheme) {
    // --- (변경 없음) ---
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(rssTheme.channelImageBorderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rssTheme.channelImageGradientColors,
        ),
      ),
      child: const Icon(Icons.rss_feed, color: Colors.white, size: 34),
    );
  }
} // End of _RssAddScreenState

import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/omninews_subscription.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/screens/home_screen.dart';
import 'package:omninews_flutter/screens/omninews_subscription/omninews_subscription_home.dart';
import 'package:omninews_flutter/services/omninews_subscription/omninews_subscription_service.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';

class RssAddScreen extends StatefulWidget {
  final Function onChannelAdded;

  const RssAddScreen({super.key, required this.onChannelAdded});

  @override
  State<RssAddScreen> createState() => _RssAddScreenState();
}

class _RssAddScreenState extends State<RssAddScreen>
    with SingleTickerProviderStateMixin {
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

  bool _showCssForm = false;
  bool _isCssGenerating = false;

  bool _isLoading = false;
  bool _isPreviewLoading = false;
  bool _isGenerating = false;

  RssChannel? _previewChannel;
  String? _errorMessage;
  bool _isExistingRss = false;
  bool _isAlreadySubscribed = false;
  int? _channelId;
  late TabController _tabController;
  SubscriptionStatus? _subscriptionStatus;
  String _selectedPlatform = 'Naver';
  bool _isLoadingSubscriptionStatus = true;
  String _searchQuery = '';

  // 인스타그램 생성 후 아이템이 아직 수집 중인지 표시
  bool _instagramItemsPending = false;

  // 방금 generate 응답이 "이미 존재(is_exist=true)" 였는지 표시 (배너/안내용)
  bool _generatedExisted = false;

  // 플랫폼 목록 (Facebook 제거됨)
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
    _checkSubscriptionStatus();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
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

  Future<void> _checkSubscriptionStatus() async {
    setState(() => _isLoadingSubscriptionStatus = true);
    final service = SubscriptionService();
    final status = await service.checkSubscriptionStatus();
    if (!mounted) return;
    setState(() {
      _subscriptionStatus = status;
      _isLoadingSubscriptionStatus = false;
    });
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

  Future<void> _previewRss() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'URL을 입력해주세요';
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
          _isExistingRss = exists;
          _isAlreadySubscribed = already;
        });
        if (already) _showSnackBar('이미 구독 중인 RSS 채널입니다');
      } else {
        if (!mounted) return;
        setState(() => _errorMessage = 'RSS 피드를 불러올 수 없습니다');
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

  Future<void> _generateRssByCss() async {
    if (_isCssGenerating) return;

    setState(() {
      _isCssGenerating = true;
      _errorMessage = null;
      _previewChannel = null;
      _instagramItemsPending = false;
      _generatedExisted = false;
    });

    // 필수값 체크 (예시: 채널링크, 타이틀, 주요 css)
    if (_cssChannelLinkController.text.trim().isEmpty ||
        _cssChannelTitleController.text.trim().isEmpty ||
        _cssItemTitleController.text.trim().isEmpty ||
        _cssItemLinkController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = '필수 항목을 모두 입력해주세요.';
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
          _showSnackBar('RSS가 성공적으로 생성되었습니다. 이제 구독할 수 있습니다.');
        }
      } else {
        setState(
          () => _errorMessage = 'RSS 생성에 실패했습니다. CSS 셀렉터와 채널 정보를 확인하세요.',
        );
      }
    } catch (e) {
      setState(() => _errorMessage = '오류가 발생했습니다: $e');
    } finally {
      setState(() => _isCssGenerating = false);
    }
  }

  Future<void> _addRssToDb() async {
    if (_previewChannel == null) return;
    final url = _urlController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final id = await RssService.addRssToDb(url);
      if (id != null && id != 0) {
        _channelId = id;
        if (!mounted) return;
        setState(() {
          _isExistingRss = true;
          _isLoading = false;
        });
        _showSnackBar('RSS가 성공적으로 추가되었습니다. 이제 구독할 수 있습니다.');
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'RSS 추가 중 오류가 발생했습니다';
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
    setState(() => _isLoading = true);
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
        widget.onChannelAdded();
        if (!mounted) return;
        _navigateToRssScreen();
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = '이미 구독 중인 채널입니다';
          _isAlreadySubscribed = true;
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

  Future<void> _generateRss() async {
    // 이미 로딩 중이면 아무 것도 안 함
    if (_isGenerating) return;

    final url = _generateUrlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'URL을 입력해주세요');
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
          if (_selectedPlatform == 'Instagram') {
            _instagramItemsPending = true;
            _showSnackBar('인스타그램 채널 생성 완료. 게시물 수집 중 (30~60초 후 자동 반영).');
          } else {
            _showSnackBar('RSS가 성공적으로 생성되었습니다. 이제 구독할 수 있습니다.');
          }
        }
      } else {
        setState(() => _errorMessage = 'RSS 생성에 실패했습니다. 유효한 URL인지 확인해주세요.');
      }
    } catch (e) {
      setState(() => _errorMessage = '오류가 발생했습니다: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _navigateToRssScreen() {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(initialTabIndex: 1),
      ),
    );
    _showSnackBar('RSS 채널이 구독되었습니다');
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
          _buildAddExistingTab(theme, textTheme, colorScheme),
          _buildGenerateTab(theme, textTheme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildAddExistingTab(
    ThemeData theme,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RSS 피드 URL 입력',
              style: textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text('RSS 주소를 입력하고 미리보기 버튼을 눌러주세요.', style: textTheme.bodyMedium),
            const SizedBox(height: 24),
            _buildUrlInputField(theme),
            if (_errorMessage != null && _tabController.index == 0)
              _buildErrorMessage(colorScheme),
            if (_previewChannel != null && _tabController.index == 0)
              _buildPreviewSection(theme, textTheme),
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
  ) {
    final isWebSelected = _selectedPlatform == "Web";
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child:
            _isLoadingSubscriptionStatus
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPremiumFeatureBanner(theme, textTheme),
                    const SizedBox(height: 20),
                    if (_subscriptionStatus?.isActive == true) ...[
                      _buildPlatformSelectionSection(theme, textTheme),
                      const SizedBox(height: 24),
                      if (isWebSelected && _showCssForm) ...[
                        _buildCssRssForm(theme, textTheme),
                        if (_errorMessage != null && _tabController.index == 1)
                          _buildErrorMessage(colorScheme),
                        if (_previewChannel != null &&
                            _tabController.index == 1)
                          _buildPreviewSection(theme, textTheme),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _showCssForm = false;
                                _errorMessage = null;
                              });
                            },
                            child: const Text("자동 추출 방식으로 돌아가기"),
                          ),
                        ),
                      ] else ...[
                        Text(
                          '사이트 URL 입력',
                          style: textTheme.titleLarge?.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '선택한 플랫폼의 채널 또는 페이지 URL을 입력해주세요.',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        _buildGenerateUrlInputField(theme),
                        if (_errorMessage != null && _tabController.index == 1)
                          _buildErrorMessage(colorScheme),
                        if (_previewChannel != null &&
                            _tabController.index == 1)
                          _buildPreviewSection(theme, textTheme),
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
                      _buildSubscriptionPrompt(theme, textTheme),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
      ),
    );
  }

  Widget _buildCssRssForm(ThemeData theme, TextTheme textTheme) {
    InputDecoration cssInputDeco(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          child: ElevatedButton(
            onPressed: _isCssGenerating ? null : _generateRssByCss,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                _isCssGenerating
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text('CSS 요소로 RSS 생성하기'),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformSelectionSection(ThemeData theme, TextTheme textTheme) {
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

  Widget _buildGenerateUrlInputField(ThemeData theme) {
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
                borderSide: BorderSide(color: Colors.green, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
            onSubmitted: (_) => _generateRss(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateRss,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBackgroundColor: Colors.green.withOpacity(0.5),
              ),
              child:
                  _isGenerating
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'RSS 생성하기',
                        style: TextStyle(
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
            'RSS가 제공되지 않는 사이트도 손쉽게 RSS로 만들어 구독할 수 있습니다. 구독을 통해 이 기능을 사용해보세요!',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionHomePage(),
                ),
              );
            },
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
        _buildPreviewCard(theme, textTheme),
      ],
    );
  }

  Widget _buildExistInfoBanner(ThemeData theme) {
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
              '인스타그램 채널이 생성되었습니다.\n게시물 아이템을 수집 중입니다 (약 30~60초). 잠시 후 새로고침하거나 홈에서 확인하세요.',
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
                if (_tabController.index == 1)
                  _buildInfoChip(
                    label: '프리미엄 생성',
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

  Widget _buildSubscriptionButton(ThemeData theme, dynamic rssTheme) {
    if (_isAlreadySubscribed) {
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

    final addingNew = !_isExistingRss;
    final isGeneratedRss = _tabController.index == 1;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            _isLoading ? null : (addingNew ? _addRssToDb : _subscribeChannel),
        icon:
            _isLoading
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Icon(
                  addingNew ? Icons.add_circle_outline : Icons.rss_feed,
                  size: 18,
                ),
        label: Text(
          addingNew ? 'RSS 추가하기' : '구독하기',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              addingNew
                  ? (isGeneratedRss ? theme.primaryColor : Colors.green)
                  : rssTheme.subscribeButtonActiveBackground,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBackgroundColor:
              addingNew
                  ? (isGeneratedRss ? theme.primaryColor : Colors.green)
                      .withOpacity(0.5)
                  : theme.primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildDefaultChannelIcon(dynamic rssTheme) {
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
}

import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/omninews_subscription.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/screens/home_screen.dart';
import 'package:omninews_flutter/screens/omninews_subscription/omninews_subscription_home.dart';
import 'package:omninews_flutter/services/omninews_subscription/omninews_subscription_service.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/services/auth_service.dart';
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
  String _selectedPlatform = 'Naver'; // 기본 플랫폼
  bool _isLoadingSubscriptionStatus = true;
  String _searchQuery = '';

  // RSS 생성을 위한 플랫폼 옵션 - 검색 키워드 추가
  final List<Map<String, dynamic>> _platforms = [
    {
      'id': 'Naver',
      'name': '네이버',
      'icon': Icons.public,
      'color': Color(0xFF03C75A),
      'keywords': ['네이버', '네', 'naver', 'n'],
    },
    {
      'id': 'Tistory',
      'name': '티스토리',
      'icon': Icons.web,
      'color': Color(0xFFEA4335),
      'keywords': ['티스토리', '티', 'tistory', 't'],
    },
    {
      'id': 'Medium',
      'name': '미디엄',
      'icon': Icons.article_outlined,
      'color': Color(0xFF000000),
      'keywords': ['미디엄', '미', 'medium', 'm'],
    },
    {
      'id': 'Instagram',
      'name': '인스타그램',
      'icon': Icons.camera_alt,
      'color': Color(0xFFE1306C),
      'keywords': ['인스타그램', '인스타', '인', 'instagram', 'insta', 'i'],
    },
    {
      'id': 'Facebook',
      'name': '페이스북',
      'icon': Icons.facebook,
      'color': Color(0xFF1877F2),
      'keywords': ['페이스북', '페북', '페', 'facebook', 'fb', 'f'],
    },
    // 새 항목: 기타 웹사이트(기본 파이프라인)
    {
      'id': 'Web',
      'name': '기타 웹사이트',
      'icon': Icons.language,
      'color': Colors.blueGrey,
      'keywords': ['기타', '웹', 'web', 'generic', 'any', '임의', 'w', 'g'],
    },
  ];
  // 필터링된 플랫폼 목록
  List<Map<String, dynamic>> get _filteredPlatforms {
    if (_searchQuery.isEmpty) {
      return _platforms;
    }

    return _platforms.where((platform) {
      // 플랫폼의 키워드 목록에서 검색어를 포함하는지 확인
      final keywords = platform['keywords'] as List;
      return keywords.any(
        (keyword) => keyword.toString().toLowerCase().contains(
          _searchQuery.toLowerCase(),
        ),
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
    super.dispose();
  }

  // 검색어 변경 리스너
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  // 구독 상태 확인
  Future<void> _checkSubscriptionStatus() async {
    setState(() {
      _isLoadingSubscriptionStatus = true;
    });

    final omninesSubscriptionService = SubscriptionService();
    final status = await omninesSubscriptionService.checkSubscriptionStatus();

    if (mounted) {
      setState(() {
        _subscriptionStatus = status;
        _isLoadingSubscriptionStatus = false;
      });
    }
  }

  // 유효한 이미지 URL인지 확인
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.scheme.isNotEmpty && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // RSS 미리보기 요청
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
    });

    try {
      // 채널 미리보기 가져오기
      final preview = await RssService.previewRssFromUrl(url);

      if (preview != null) {
        // 서버에 이미 존재하는지 확인
        final exists = await RssService.checkRssExists(url);
        // 이미 구독 중인지 확인
        final alreadySubscribed = await RssService.isChannelAlreadySubscribed(
          preview.channelRssLink,
        );
        debugPrint('미리보기 채널: ${alreadySubscribed}');

        if (mounted) {
          setState(() {
            _previewChannel = preview;
            _isExistingRss = exists;
            _isAlreadySubscribed = alreadySubscribed;
          });

          // 이미 구독 중인 경우 알림 표시
          if (alreadySubscribed) {
            _showSnackBar('이미 구독 중인 RSS 채널입니다');
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'RSS 피드를 불러올 수 없습니다';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '오류가 발생했습니다: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPreviewLoading = false;
        });
      }
    }
  }

  // RSS 서버에 추가 (구독은 하지 않음)
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
        _channelId = id; // 채널 ID 저장

        if (mounted) {
          setState(() {
            _isExistingRss = true; // 이제 DB에 존재함을 표시
            _isLoading = false;
          });

          _showSnackBar('RSS가 성공적으로 추가되었습니다. 이제 구독할 수 있습니다.');
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'RSS 추가 중 오류가 발생했습니다';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'RSS 추가 중 오류가 발생했습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  // 채널 구독 처리
  Future<void> _subscribeChannel() async {
    if (_previewChannel == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;

      // 채널 ID가 있으면 ID로 구독, 없으면 링크로 구독
      if (_channelId != null) {
        success = await RssService.subscribeChannel(_channelId!);
      } else {
        success = await RssService.subscribeChannelByRssLink(
          _previewChannel!.channelRssLink,
        );
      }

      if (success) {
        // 콜백 호출
        widget.onChannelAdded();

        if (mounted) {
          // RSS 화면으로 이동
          _navigateToRssScreen();
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = '이미 구독 중인 채널입니다';
            _isAlreadySubscribed = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '구독 중 오류가 발생했습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  // RSS 생성 요청
  Future<void> _generateRss() async {
    final url = _generateUrlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'URL을 입력해주세요';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _previewChannel = null;
    });

    try {
      // 프리미엄 RSS 생성 API 호출
      final platformForApi =
          _selectedPlatform == 'Web' ? 'Default' : _selectedPlatform;

      final generatedChannel = await RssService.generateRss(
        url,
        platformForApi,
      );

      if (generatedChannel != null) {
        // 생성 성공 시 채널 미리보기 표시
        setState(() {
          _previewChannel = generatedChannel;
          _isExistingRss = true; // 이미 생성되었으므로 true
          _channelId = generatedChannel.channelId;
        });

        _showSnackBar('RSS가 성공적으로 생성되었습니다. 이제 구독할 수 있습니다.');
      } else {
        setState(() {
          _errorMessage = 'RSS 생성에 실패했습니다. 유효한 URL인지 확인해주세요.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '오류가 발생했습니다: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // RSS 화면으로 이동
  void _navigateToRssScreen() {
    // 현재 화면을 스택에서 제거
    Navigator.pop(context);

    // RSS 탭이 있는 홈 화면으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(initialTabIndex: 1),
      ),
    );

    _showSnackBar('RSS 채널이 구독되었습니다');
  }

  // 스낵바 표시 헬퍼 메서드
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
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
          // 기존 RSS 추가 화면
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 안내 텍스트
                  Text(
                    'RSS 피드 URL 입력',
                    style: textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RSS 주소를 입력하고 미리보기 버튼을 눌러주세요.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // URL 입력 필드
                  _buildUrlInputField(theme),

                  // 오류 메시지
                  if (_errorMessage != null && _tabController.index == 0)
                    _buildErrorMessage(colorScheme),

                  // 미리보기 결과
                  if (_previewChannel != null && _tabController.index == 0)
                    _buildPreviewSection(theme, textTheme),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // 새로운 RSS 생성 화면
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child:
                  _isLoadingSubscriptionStatus
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 구독자 전용 표시
                          _buildPremiumFeatureBanner(theme, textTheme),

                          const SizedBox(height: 20),

                          // 구독 중인 경우만 실제 기능 표시
                          if (_subscriptionStatus?.isActive == true) ...[
                            // 플랫폼 선택 섹션
                            _buildPlatformSelectionSection(theme, textTheme),

                            const SizedBox(height: 24),

                            // URL 입력 필드
                            Text(
                              '사이트 URL 입력',
                              style: textTheme.titleLarge?.copyWith(
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '선택한 플랫폼의 채널 또는 페이지 URL을 입력해주세요.',
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            _buildGenerateUrlInputField(theme),

                            // 오류 메시지
                            if (_errorMessage != null &&
                                _tabController.index == 1)
                              _buildErrorMessage(colorScheme),

                            // 미리보기 결과
                            if (_previewChannel != null &&
                                _tabController.index == 1)
                              _buildPreviewSection(theme, textTheme),
                          ] else ...[
                            // 구독자가 아닌 경우 구독 유도 메시지
                            _buildSubscriptionPrompt(theme, textTheme),
                          ],

                          const SizedBox(height: 30),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  // 플랫폼 선택 섹션 (제목 + 검색창 + 플랫폼 목록)
  // 플랫폼 선택 섹션 (제목 + 검색창 + 플랫폼 목록)
  Widget _buildPlatformSelectionSection(ThemeData theme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목 영역
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

        // 검색창 - 더 모던한 느낌
        _buildSearchField(theme),

        const SizedBox(height: 16),

        // 플랫폼 선택기
        _buildPlatformSelector(theme),
      ],
    );
  }

  // 검색 입력 필드
  // 검색 입력 필드 - 모던한 에어로 디자인
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // 클릭 시 포커스 주기
              FocusScope.of(context).requestFocus(FocusNode());
              _searchController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _searchController.text.length,
              );
            },
            highlightColor: theme.splashColor.withOpacity(0.1),
            splashColor: theme.splashColor.withOpacity(0.1),
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
                    decoration: InputDecoration(
                      hintText: '검색',
                      hintStyle: TextStyle(
                        color:
                            theme.brightness == Brightness.dark
                                ? Colors.grey.shade500
                                : Colors.grey.shade500,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
          ),
        ),
      ),
    );
  }

  // 구독자 전용 배너
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
          Icon(Icons.star, color: Colors.white, size: 18),
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

  // URL 입력 필드와 미리보기 버튼
  Widget _buildUrlInputField(ThemeData theme) {
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
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'https://example.com/rss',
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
                borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
            onSubmitted: (_) => _previewRss(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPreviewLoading ? null : _previewRss,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBackgroundColor: theme.primaryColor.withOpacity(0.5),
              ),
              child:
                  _isPreviewLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'RSS 미리보기',
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

  // RSS 생성을 위한 URL 입력 필드
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
                borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
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

  // 플랫폼에 따른 URL 힌트
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
      case 'Facebook':
        return 'https://www.facebook.com/사용자명';
      case 'Web': // 추가
        return 'https://example.com/원하는_페이지';
      default:
        return 'https://...';
    }
  }

  // 플랫폼 선택 위젯
  Widget _buildPlatformSelector(ThemeData theme) {
    final platforms = _filteredPlatforms;

    return platforms.isEmpty
        ? _buildEmptySearchResult(theme)
        : Container(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: platforms.length,
            itemBuilder: (context, index) {
              final platform = platforms[index];
              final isSelected = _selectedPlatform == platform['id'];

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlatform = platform['id'];
                    });
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color:
                              isSelected ? platform['color'] : theme.cardColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color:
                                isSelected
                                    ? platform['color']
                                    : theme.dividerColor,
                            width: 2,
                          ),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: platform['color'].withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                  : [],
                        ),
                        child: Icon(
                          platform['icon'],
                          color: isSelected ? Colors.white : platform['color'],
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        platform['name'],
                        style: TextStyle(
                          color:
                              isSelected ? theme.primaryColor : theme.hintColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
  }

  // 검색 결과가 없을 때 표시할 위젯
  Widget _buildEmptySearchResult(ThemeData theme) {
    return Container(
      height: 90,
      width: double.infinity,
      alignment: Alignment.center,
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

  // 구독 유도 메시지
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
              // 구독 페이지로 이동
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

  // 오류 메시지 표시
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

  // 미리보기 섹션
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
        _buildPreviewCard(theme, textTheme),
      ],
    );
  }

  // 채널 미리보기 카드
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
            // 채널 헤더 (이미지와 제목)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 채널 썸네일
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

                // 채널 정보
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

            // 채널 설명
            Text(
              _previewChannel!.channelDescription,
              style: textTheme.bodyMedium?.copyWith(height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // 태그 정보
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
                // 생성된 RSS인 경우 프리미엄 태그 추가
                if (_tabController.index == 1)
                  _buildInfoChip(
                    label: '프리미엄 생성',
                    icon: Icons.stars,
                    iconColor: Colors.amber,
                    theme: theme,
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // 구독 버튼
            _buildSubscriptionButton(theme, rssTheme),
          ],
        ),
      ),
    );
  }

  // 정보 칩
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

  // 구독 버튼
  Widget _buildSubscriptionButton(ThemeData theme, dynamic rssTheme) {
    // 이미 구독 중인 경우
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

    // RSS 추가 또는 구독 버튼 표시 (DB에 존재하는지에 따라)
    final bool addingNew = !_isExistingRss;
    final bool isGeneratedRss = _tabController.index == 1;

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

  // 기본 채널 아이콘
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

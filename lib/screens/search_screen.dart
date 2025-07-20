import 'dart:async'; // Timer 사용을 위해 추가
import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/services/unified_search_service.dart';
import 'package:omninews_flutter/widgets/news_api_item_card.dart';
import 'package:omninews_flutter/widgets/search_rss_channel_card.dart';
import 'package:omninews_flutter/widgets/search_rss_item_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omninews_flutter/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // 검색창 포커스 관리용
  late TabController _tabController;
  final PageController _pageController = PageController();

  // 검색 결과 상태 관리
  UnifiedSearchResult? _searchResult;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasSearched = false;
  String _sortOption = 'sim';
  String _lastQuery = ''; // 마지막 검색어 저장
  int _currentPage = 1;

  // 스크롤 관련 상태
  bool _isScrolling = false; // 스크롤 중인지 나타내는 플래그
  double _scrollPosition = 0.0; // 스크롤 위치
  double _maxScrollExtent = 1.0; // 최대 스크롤 가능 범위
  Timer? _scrollDisplayTimer; // 스크롤 표시기 타이머

  // 디바운스 타이머
  Timer? _debounceTimer;

  // 디바운스 실행 중인지 확인하는 플래그
  bool _isDebouncing = false;

  // 스크롤 컨트롤러들
  final ScrollController _newsScrollController = ScrollController();
  final ScrollController _rssItemScrollController = ScrollController();
  final ScrollController _channelScrollController = ScrollController();

  // 결과 필터링 - 탭으로 변환
  final List<String> _tabs = ['뉴스', 'RSS 피드', '채널'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });

    // 탭 컨트롤러와 페이지 컨트롤러 연동
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_pageController.hasClients) {
          // 탭 변경 시 페이지 뷰 즉시 업데이트
          _pageController.jumpToPage(_tabController.index);
        }
      }
    });

    // 스크롤 컨트롤러에 리스너 추가
    _newsScrollController.addListener(_handleNewsScroll);
    _rssItemScrollController.addListener(_handleRssItemScroll);
    _channelScrollController.addListener(_handleChannelScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    _pageController.dispose();
    _newsScrollController.dispose();
    _rssItemScrollController.dispose();
    _channelScrollController.dispose();
    _debounceTimer?.cancel();
    _scrollDisplayTimer?.cancel();
    super.dispose();
  }

  // 스크롤 상태 업데이트 함수
  void _updateScrollState(ScrollController controller, bool isScrolling) {
    // 스크롤 타이머 취소
    _scrollDisplayTimer?.cancel();

    setState(() {
      _isScrolling = isScrolling;
      if (isScrolling) {
        _scrollPosition = controller.position.pixels;
        _maxScrollExtent = controller.position.maxScrollExtent;

        // 3초 후에 스크롤 표시기 숨김
        _scrollDisplayTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isScrolling = false;
            });
          }
        });
      }
    });
  }

  // 디바운스 함수: 짧은 시간 내에 여러 번 호출되는 것을 방지
  void _debounce(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    if (_isDebouncing) return;

    _isDebouncing = true;

    // 이전 타이머가 있으면 취소
    _debounceTimer?.cancel();

    // 새 타이머 생성
    _debounceTimer = Timer(duration, () {
      callback();
      _isDebouncing = false;
    });
  }

  void _handleNewsScroll() {
    // 스크롤 상태 업데이트
    _updateScrollState(_newsScrollController, true);

    if (_newsScrollController.position.pixels >=
        _newsScrollController.position.maxScrollExtent - 200) {
      // 디바운스 적용
      _debounce(() {
        print('뉴스 스크롤 끝에 도달, 추가 데이터 로드');
        _loadMoreData(0); // 뉴스 탭
      });
    }
  }

  void _handleRssItemScroll() {
    // 스크롤 상태 업데이트
    _updateScrollState(_rssItemScrollController, true);

    if (_rssItemScrollController.position.pixels >=
        _rssItemScrollController.position.maxScrollExtent - 200) {
      // 디바운스 적용
      _debounce(() {
        print('RSS 피드 스크롤 끝에 도달, 추가 데이터 로드');
        _loadMoreData(1); // RSS 피드 탭
      });
    }
  }

  void _handleChannelScroll() {
    // 스크롤 상태 업데이트
    _updateScrollState(_channelScrollController, true);

    if (_channelScrollController.position.pixels >=
        _channelScrollController.position.maxScrollExtent - 200) {
      // 디바운스 적용
      _debounce(() {
        print('채널 스크롤 끝에 도달, 추가 데이터 로드');
        _loadMoreData(2); // 채널 탭
      });
    }
  }

  // 현재 활성화된 스크롤 컨트롤러 가져오기
  ScrollController? _getActiveScrollController() {
    if (_tabController.index == 0) {
      return _newsScrollController;
    } else if (_tabController.index == 1) {
      return _rssItemScrollController;
    } else if (_tabController.index == 2) {
      return _channelScrollController;
    }
    return null;
  }

  // 스크롤 맨 위로 이동
  void _scrollToTop() {
    final controller = _getActiveScrollController();
    if (controller != null && controller.hasClients) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _loadMoreData(int tabIndex) async {
    // 이미 로딩 중이거나, 결과가 없거나, 다음 페이지가 없으면 무시
    if (_isLoadingMore || _searchResult == null || _lastQuery.isEmpty) {
      print('이미 로딩 중이거나 검색 결과가 없어서 추가 로딩 무시');
      return;
    }

    bool hasNext = false;
    switch (tabIndex) {
      case 0: //TODO  뉴스 탭 - 뉴스는 항상 true로 설정 (나중에 구현)
        hasNext = true;
        print('뉴스 탭 hasNext: $hasNext');
        break;
      case 1: // RSS 피드 탭
        hasNext = _searchResult!.hasNextRssItems;
        print('RSS 피드 탭 hasNext: $hasNext');
        break;
      case 2: // 채널 탭
        hasNext = _searchResult!.hasNextChannels;
        print('채널 탭 hasNext: $hasNext');
        break;
    }

    if (!hasNext) {
      print('더 이상 불러올 데이터가 없음 (hasNext: false)');
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    print('추가 데이터 로딩 시작 - 탭: ${_tabs[tabIndex]}, 페이지: ${_currentPage + 1}');

    try {
      int nextPage = _currentPage + 1;
      print('API 요청: 쿼리=${_lastQuery}, 정렬=${_sortOption}, 페이지=$nextPage');

      final result = await UnifiedSearchService.search(
        _lastQuery,
        sort: _sortOption,
        page: nextPage,
      );

      if (mounted) {
        print(
          'API 응답 받음 - 뉴스: ${result.newsResults.length}, RSS 피드: ${result.rssItemResults.length}, 채널: ${result.rssChannelResults.length}',
        );
        print(
          'hasNextRssItems: ${result.hasNextRssItems}, hasNextChannels: ${result.hasNextChannels}',
        );

        setState(() {
          // 기존 결과와 새 결과 합치기
          List<RssItem> updatedRssItems = _searchResult!.rssItemResults;
          List<RssChannel> updatedChannels = _searchResult!.rssChannelResults;
          List<NewsApi> updatedNews = _searchResult!.newsResults;

          if (tabIndex == 0 && result.newsResults.isNotEmpty) {
            updatedNews = [
              ..._searchResult!.newsResults,
              ...result.newsResults,
            ];
            print('뉴스 결과 업데이트: ${updatedNews.length}개');
          }

          if (tabIndex == 1 && result.rssItemResults.isNotEmpty) {
            updatedRssItems = [
              ..._searchResult!.rssItemResults,
              ...result.rssItemResults,
            ];
            print('RSS 피드 결과 업데이트: ${updatedRssItems.length}개');
          }

          if (tabIndex == 2 && result.rssChannelResults.isNotEmpty) {
            updatedChannels = [
              ..._searchResult!.rssChannelResults,
              ...result.rssChannelResults,
            ];
            print('채널 결과 업데이트: ${updatedChannels.length}개');
          }

          _searchResult = UnifiedSearchResult(
            newsResults: updatedNews,
            rssItemResults: updatedRssItems,
            rssChannelResults: updatedChannels,
            page: nextPage,
            hasNextRssItems: result.hasNextRssItems,
            hasNextChannels: result.hasNextChannels,
          );
          _currentPage = nextPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('추가 데이터 로딩 중 오류 발생: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('추가 결과를 로드하는 중 오류가 발생했습니다'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _search(String query) async {
    if (query.trim().isEmpty) return;

    // 현재 탭 인덱스 저장 (최초 검색이 아닌 경우에만)
    final currentTabIndex =
        _hasSearched && _tabController.length > 0 ? _tabController.index : 0;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _lastQuery = query;
      _searchResult = null;
      _currentPage = 1;
    });

    print('검색 시작: 쿼리=$query, 정렬=$_sortOption, 페이지=1');

    try {
      final result = await UnifiedSearchService.search(
        query,
        sort: _sortOption,
        page: 1,
      );

      if (mounted) {
        print(
          '검색 결과 - 뉴스: ${result.newsResults.length}, RSS 피드: ${result.rssItemResults.length}, 채널: ${result.rssChannelResults.length}',
        );
        print(
          'hasNextRssItems: ${result.hasNextRssItems}, hasNextChannels: ${result.hasNextChannels}',
        );

        setState(() {
          _searchResult = result;
          _isLoading = false;
        });

        // UI가 업데이트된 후에 탭 상태 확인
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _hasResults()) {
            _checkAndUpdateTab(currentTabIndex);
          }
        });
      }
    } catch (e) {
      print('검색 중 오류 발생: $e');
      if (mounted) {
        setState(() {
          _searchResult = UnifiedSearchResult(
            newsResults: [],
            rssItemResults: [],
            rssChannelResults: [],
          );
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('검색 중 오류가 발생했습니다: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // 검색 후 탭 상태 체크 및 업데이트
  void _checkAndUpdateTab(int preferredTabIndex) {
    if (_searchResult == null || !_hasResults()) return;

    try {
      // 먼저 선호하는 탭에 결과가 있는지 확인
      bool hasResultsInPreferredTab = _hasResultsInTab(preferredTabIndex);

      if (hasResultsInPreferredTab) {
        // 선호하는 탭에 결과가 있으면 해당 탭으로 이동
        _tabController.animateTo(preferredTabIndex);

        // PageController를 안전하게 사용
        if (_pageController.hasClients) {
          _pageController.jumpToPage(preferredTabIndex);
        }
      } else {
        // 선호하는 탭에 결과가 없으면 결과가 있는 첫 탭으로 이동
        int newTabIndex = _findFirstTabWithResults();
        if (newTabIndex >= 0) {
          _tabController.animateTo(newTabIndex);

          // PageController를 안전하게 사용
          if (_pageController.hasClients) {
            _pageController.jumpToPage(newTabIndex);
          }
        }
      }
    } catch (e) {
      print('탭 업데이트 중 오류: $e');
      // 오류가 발생해도 앱이 중단되지 않도록 조용히 실패
    }
  }

  // 특정 탭에 결과가 있는지 확인
  bool _hasResultsInTab(int tabIndex) {
    if (_searchResult == null) return false;

    switch (tabIndex) {
      case 0: // 뉴스 탭
        return _searchResult!.newsResults.isNotEmpty;
      case 1: // RSS 피드 탭
        return _searchResult!.rssItemResults.isNotEmpty;
      case 2: // 채널 탭
        return _searchResult!.rssChannelResults.isNotEmpty;
      default:
        return false;
    }
  }

  // 결과가 있는 첫 번째 탭 인덱스 찾기
  int _findFirstTabWithResults() {
    if (_searchResult == null) return -1;

    if (_searchResult!.newsResults.isNotEmpty) {
      return 0; // 뉴스 탭
    } else if (_searchResult!.rssItemResults.isNotEmpty) {
      return 1; // RSS 피드 탭
    } else if (_searchResult!.rssChannelResults.isNotEmpty) {
      return 2; // 채널 탭
    }

    return -1; // 모든 탭에 결과가 없음
  }

  void _handleSearch() {
    final query = _controller.text;
    if (query.isNotEmpty) {
      _search(query);
      FocusScope.of(context).unfocus();
    }
  }

  void _clearSearch() {
    _controller.clear();
    _focusNode.requestFocus();
    setState(() {});
  }

  // 정렬 옵션 변경 시 현재 탭 유지
  void _updateSortOption(String sortOption) {
    if (_sortOption != sortOption) {
      // 현재 탭 인덱스 저장
      final currentTabIndex = _tabController.index;
      print('정렬 옵션 변경: $_sortOption → $sortOption');

      setState(() {
        _sortOption = sortOption;
      });

      if (_hasSearched && _lastQuery.isNotEmpty) {
        // 검색 시 현재 탭 인덱스 전달
        _searchWithCurrentTab(_lastQuery, currentTabIndex);
      }
    }
  }

  // 현재 탭 인덱스와 함께 검색
  void _searchWithCurrentTab(String query, int currentTabIndex) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResult = null;
      _currentPage = 1;
    });

    print('재검색 시작: 쿼리=$query, 정렬=$_sortOption, 페이지=1, 현재탭=$currentTabIndex');

    try {
      final result = await UnifiedSearchService.search(
        query,
        sort: _sortOption,
        page: 1,
      );

      if (mounted) {
        print(
          '재검색 결과 - 뉴스: ${result.newsResults.length}, RSS 피드: ${result.rssItemResults.length}, 채널: ${result.rssChannelResults.length}',
        );
        print(
          'hasNextRssItems: ${result.hasNextRssItems}, hasNextChannels: ${result.hasNextChannels}',
        );

        setState(() {
          _searchResult = result;
          _isLoading = false;
        });

        // UI가 업데이트된 후 탭 상태 확인
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _hasResults()) {
            _checkAndUpdateTab(currentTabIndex);
          }
        });
      }
    } catch (e) {
      print('재검색 중 오류 발생: $e');
      if (mounted) {
        setState(() {
          _searchResult = UnifiedSearchResult(
            newsResults: [],
            rssItemResults: [],
            rssChannelResults: [],
          );
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('검색 중 오류가 발생했습니다: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _addToNewsCategories(String query) async {
    final theme = Theme.of(context);

    bool shouldAdd =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  '카테고리 추가',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.headlineMedium?.color,
                  ),
                ),
                backgroundColor: theme.dialogBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                content: Text(
                  '\'$query\' 검색어를 뉴스 카테고리에 추가하시겠습니까?',
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color?.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('추가'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!shouldAdd) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCategories = prefs.getStringList('user_categories') ?? [];

      if (savedCategories.contains(query)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('\'$query\' 카테고리가 이미 존재합니다'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
        return;
      }

      final newCategories = [...savedCategories, query];
      await prefs.setStringList('user_categories', newCategories);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\'$query\' 카테고리가 추가되었습니다'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.primaryColor,
          ),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
        await prefs.setInt('select_category_index', -1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카테고리 추가 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text('Search Contents', style: textTheme.headlineMedium),
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 검색창
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    // 검색 입력 필드
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: '뉴스, RSS 피드, 채널을 검색하세요...',
                          hintStyle: TextStyle(color: theme.hintColor),
                          prefixIcon: Icon(
                            Icons.search,
                            color: theme.iconTheme.color?.withOpacity(0.6),
                          ),
                          suffixIcon:
                              _controller.text.isNotEmpty
                                  ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: theme.iconTheme.color?.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                    onPressed: _clearSearch,
                                  )
                                  : null,
                          filled: true,
                          fillColor:
                              theme.brightness == Brightness.dark
                                  ? theme.cardColor
                                  : Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: theme.primaryColor,
                              width: 1,
                            ),
                          ),
                        ),
                        style: TextStyle(color: textTheme.bodyLarge?.color),
                        onSubmitted: _search,
                        textInputAction: TextInputAction.search,
                      ),
                    ),

                    // 검색 버튼
                    if (_controller.text.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _handleSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('검색'),
                      ),
                    ],
                  ],
                ),
              ),

              // 검색 결과가 있을 때의 옵션 바
              if (_hasSearched && _searchResult != null && !_isLoading)
                _buildSearchOptionsBar(),

              // 탭 바 추가 (필터 칩 대신 탭바 사용)
              if (_hasSearched &&
                  _searchResult != null &&
                  !_isLoading &&
                  _hasResults())
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.canvasColor,
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor, width: 1),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: theme.primaryColor,
                    unselectedLabelColor: theme.textTheme.bodyLarge?.color
                        ?.withOpacity(0.7),
                    indicatorColor: theme.primaryColor,
                    indicatorWeight: 3,
                    tabs: [
                      _buildTab('뉴스', _searchResult!.newsResults.length),
                      _buildTab('RSS 피드', _searchResult!.rssItemResults.length),
                      _buildTab('채널', _searchResult!.rssChannelResults.length),
                    ],
                    isScrollable: false, // 전체 화면 너비 사용
                  ),
                ),

              // 검색 결과
              Expanded(
                child:
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color: theme.primaryColor,
                          ),
                        )
                        : !_hasSearched
                        ? _buildInitialView()
                        : !_hasResults()
                        ? _buildEmptyResultView()
                        : PageView(
                          controller: _pageController,
                          physics: const ClampingScrollPhysics(),
                          onPageChanged: (index) {
                            if (_tabController.index != index) {
                              _tabController.animateTo(index);
                            }
                          },
                          children: [
                            // 뉴스 페이지
                            _buildNewsResultsList(),

                            // RSS 피드 페이지
                            _buildRssItemResultsList(),

                            // 채널 페이지
                            _buildChannelResultsList(),
                          ],
                        ),
              ),
            ],
          ),

          // 스크롤 표시기 (플로팅)
          if (_isScrolling && _hasResults() && !_isLoading)
            _buildScrollIndicator(),

          // 맨 위로 이동 버튼 (스크롤 위치가 일정 이상일 때만 표시)
          if (_hasResults() && _scrollPosition > 300 && !_isLoading)
            _buildScrollToTopButton(),
        ],
      ),
    );
  }

  // 스크롤 표시기 위젯
  Widget _buildScrollIndicator() {
    final theme = Theme.of(context);

    // 스크롤 위치에 따른 진행률 계산 (0.0 ~ 1.0)
    final progress =
        _maxScrollExtent > 0
            ? (_scrollPosition / _maxScrollExtent).clamp(0.0, 1.0)
            : 0.0;

    return Positioned(
      right: 16,
      bottom: 60,
      child: AnimatedOpacity(
        opacity: _isScrolling ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 스크롤 아이콘
              Icon(Icons.swipe_vertical, size: 14, color: theme.primaryColor),
              const SizedBox(width: 4),
              // 스크롤 진행률
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // 진행률 텍스트
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 맨 위로 스크롤 버튼
  Widget _buildScrollToTopButton() {
    final theme = Theme.of(context);

    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton.small(
        onPressed: _scrollToTop,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        tooltip: '맨 위로',
        child: const Icon(Icons.keyboard_arrow_up, size: 20),
      ),
    );
  }

  // 새로운 탭 위젯 생성
  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          const SizedBox(width: 6),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 뉴스 결과 페이지
  Widget _buildNewsResultsList() {
    final theme = Theme.of(context);
    List<Widget> resultWidgets = [];

    if (_searchResult!.newsResults.isEmpty) {
      return Center(
        child: Text('뉴스 검색 결과가 없습니다', style: TextStyle(color: theme.hintColor)),
      );
    }

    for (var i = 0; i < _searchResult!.newsResults.length; i++) {
      resultWidgets.add(
        NewsApiItemCard(
          news: _searchResult!.newsResults[i],
          onBookmarkChanged: () {
            setState(() {});
          },
        ),
      );

      if (i < _searchResult!.newsResults.length - 1) {
        resultWidgets.add(
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: theme.dividerTheme.color,
          ),
        );
      }
    }

    // 로딩 인디케이터 추가
    if (_isLoadingMore) {
      resultWidgets.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  '추가 결과를 불러오는 중...',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      controller: _newsScrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      children: resultWidgets,
    );
  }

  // RSS 피드 결과 페이지
  Widget _buildRssItemResultsList() {
    final theme = Theme.of(context);
    List<Widget> resultWidgets = [];

    if (_searchResult!.rssItemResults.isEmpty) {
      return Center(
        child: Text(
          'RSS 피드 검색 결과가 없습니다',
          style: TextStyle(color: theme.hintColor),
        ),
      );
    }

    for (var i = 0; i < _searchResult!.rssItemResults.length; i++) {
      resultWidgets.add(
        SearchRssItemCard(
          item: _searchResult!.rssItemResults[i],
          onBookmarkChanged: () {
            setState(() {});
          },
        ),
      );

      if (i < _searchResult!.rssItemResults.length - 1) {
        resultWidgets.add(
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: theme.dividerTheme.color,
          ),
        );
      }
    }

    // 로딩 인디케이터 추가
    if (_isLoadingMore && _searchResult!.hasNextRssItems) {
      resultWidgets.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  '추가 결과를 불러오는 중...',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      controller: _rssItemScrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      children: resultWidgets,
    );
  }

  // 채널 결과 페이지
  Widget _buildChannelResultsList() {
    final theme = Theme.of(context);
    List<Widget> resultWidgets = [];

    if (_searchResult!.rssChannelResults.isEmpty) {
      return Center(
        child: Text('채널 검색 결과가 없습니다', style: TextStyle(color: theme.hintColor)),
      );
    }

    for (var i = 0; i < _searchResult!.rssChannelResults.length; i++) {
      resultWidgets.add(
        SearchRssChannelCard(
          channel: _searchResult!.rssChannelResults[i],
          onSubscriptionChanged: () {
            setState(() {});
          },
        ),
      );

      if (i < _searchResult!.rssChannelResults.length - 1) {
        resultWidgets.add(
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: theme.dividerTheme.color,
          ),
        );
      }
    }

    // 로딩 인디케이터 추가
    if (_isLoadingMore && _searchResult!.hasNextChannels) {
      resultWidgets.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  '추가 결과를 불러오는 중...',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      controller: _channelScrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      children: resultWidgets,
    );
  }

  Widget _buildSearchOptionsBar() {
    final theme = Theme.of(context);
    final hasResults = _hasResults();

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, hasResults ? 4 : 8),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? theme.cardColor.withOpacity(0.4)
                : theme.canvasColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 카테고리 추가 버튼
          InkWell(
            onTap: () => _addToNewsCategories(_lastQuery),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "카테고리 추가",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // 정렬 옵션
          _buildSortOption(
            context: context,
            label: "정확순",
            isSelected: _sortOption == "sim",
            onTap: () => _updateSortOption("sim"),
          ),
          _buildSortOption(
            context: context,
            label: "인기순",
            isSelected: _sortOption == "pop",
            onTap: () => _updateSortOption("pop"),
          ),
          _buildSortOption(
            context: context,
            label: "최신순",
            isSelected: _sortOption == "date",
            onTap: () => _updateSortOption("date"),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialView() {
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: subscribeStyle.emptyIconColor),
          const SizedBox(height: 16),
          Text(
            '검색어를 입력하세요',
            style: TextStyle(
              fontSize: 16,
              color: subscribeStyle.emptyTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '뉴스, RSS 피드, 채널을 모두 검색할 수 있습니다',
            style: TextStyle(fontSize: 14, color: subscribeStyle.hintTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResultView() {
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: subscribeStyle.emptyIconColor,
          ),
          const SizedBox(height: 16),
          Text(
            '\'${_lastQuery}\' 검색 결과가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: subscribeStyle.emptyTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 검색어로 시도해보세요',
            style: TextStyle(fontSize: 14, color: subscribeStyle.hintTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected
                        ? theme.primaryColor
                        : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                letterSpacing: -0.2,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Icon(Icons.check, size: 14, color: theme.primaryColor),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasResults() {
    if (_searchResult == null) return false;

    return _searchResult!.newsResults.isNotEmpty ||
        _searchResult!.rssItemResults.isNotEmpty ||
        _searchResult!.rssChannelResults.isNotEmpty;
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/screens/news_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/services/news_bookmark_service.dart';
import 'package:omninews_flutter/services/news_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:omninews_flutter/utils/ad_manager.dart';
import 'package:provider/provider.dart';

class NewsListView extends StatefulWidget {
  final String category;
  final VoidCallback? onBookmarkChanged;

  const NewsListView({
    super.key,
    required this.category,
    this.onBookmarkChanged,
  });

  @override
  State<NewsListView> createState() => _NewsListViewState();
}

class _NewsListViewState extends State<NewsListView> {
  // --- 상태 변수 (이전과 동일) ---
  final Map<String, bool> _bookmarkStatus = {};
  final Map<String, bool> _loadingStatus = {};
  final List<News> _newsItems = [];
  int _currentPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final Random _random = Random();

  // --- 광고 관련 상태 (변경 없음) ---
  final List<int> _adDataIndices = [];
  static const int _initialAdCount = 1;
  static const int _adsToAddPerPage = 1;
  static const int _adMinIndex = 3;
  final Map<int, NativeAd?> _loadedAds = {};
  final List<NativeAd> _adsToDispose = [];

  // --- 스크롤 네비게이터 상태 (변경 없음) ---
  bool _isScrolling = false;
  double _scrollPosition = 0.0;
  double _maxScrollExtent = 1.0;
  Timer? _scrollDisplayTimer;

  late AdManager _adManager;

  // [✅ 추가] 아이템 평균 높이 추정치 (UI에 맞게 조정 필요)
  static const double _estimatedItemHeight = 120.0;

  @override
  void initState() {
    super.initState();
    _adManager = Provider.of<AdManager>(context, listen: false);
    _fetchInitialNews();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _scrollDisplayTimer?.cancel();
    for (var ad in _adsToDispose) {
      ad.dispose();
    }
    _adsToDispose.clear();
    super.dispose();
  }

  Future<void> _fetchInitialNews() async {
    // ... (데이터 로딩 로직 - 변경 없음) ...
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }
    _adDataIndices.clear();
    _loadedAds.clear();
    for (var ad in _adsToDispose) {
      ad.dispose();
    }
    _adsToDispose.clear();

    try {
      final fetchedNews = await NewsService.fetchNewsPaginated(
        widget.category,
        1,
      );
      if (!mounted) return;

      _newsItems.clear();
      _newsItems.addAll(fetchedNews);
      _currentPage = 1;
      _hasMore = fetchedNews.length >= 20;

      if (_newsItems.isNotEmpty) {
        _generateAdIndices(_newsItems.length, _initialAdCount);
        _requestAdsForCurrentIndices();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error fetching initial news for ${widget.category}: $e');
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.category} 뉴스 로딩 실패'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _scrollListener() {
    _updateScrollState(_scrollController, true); // 스크롤 상태 업데이트 호출
    if (!_isLoadingMore &&
        _hasMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    // ... (더보기 로직 - 변경 없음) ...
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final fetchedNews = await NewsService.fetchNewsPaginated(
        widget.category,
        nextPage,
      );
      if (!mounted) return;

      final startIndex = _newsItems.length;
      final newlyAddedIndices = <int>[];

      _newsItems.addAll(fetchedNews);
      _currentPage = nextPage;
      _hasMore = fetchedNews.length >= 20;

      if (fetchedNews.isNotEmpty) {
        newlyAddedIndices.addAll(
          _generateMoreAdIndices(startIndex, fetchedNews.length),
        );
      }

      setState(() => _isLoadingMore = false);

      if (newlyAddedIndices.isNotEmpty) {
        _requestAdsForCurrentIndices(
          onlyNew: true,
          newDataStartIndex: startIndex,
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error loading more news for ${widget.category}: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _generateAdIndices(int listLength, int count) {
    // ... (광고 인덱스 생성 로직 - 변경 없음) ...
    if (_adDataIndices.isNotEmpty || listLength <= _adMinIndex) return;
    final availableIndices =
        List.generate(
          max(0, listLength - _adMinIndex),
          (i) => i + _adMinIndex,
        ).where((idx) => idx < listLength).toList();
    availableIndices.shuffle(_random);
    int numToAdd = min(count, availableIndices.length);
    for (int i = 0; i < numToAdd; i++) {
      _adDataIndices.add(availableIndices[i]);
    }
    _adDataIndices.sort();
    debugPrint("[${widget.category}] Initial Ad Data indices: $_adDataIndices");
  }

  List<int> _generateMoreAdIndices(int startIndex, int newItemsCount) {
    // ... (추가 광고 인덱스 생성 로직 - 변경 없음) ...
    final newlyAddedDataIndices = <int>[];
    int endIndex = startIndex + newItemsCount - 1;
    int effectiveStartIndex = max(_adMinIndex, startIndex);
    if (effectiveStartIndex > endIndex) return newlyAddedDataIndices;

    final availableDataIndices = List.generate(
      endIndex - effectiveStartIndex + 1,
      (i) => effectiveStartIndex + i,
    );
    availableDataIndices.shuffle(_random);

    int numToAdd = min(_adsToAddPerPage, availableDataIndices.length);
    for (int i = 0; i < numToAdd; i++) {
      int newIndex = availableDataIndices[i];
      _adDataIndices.add(newIndex);
      newlyAddedDataIndices.add(newIndex);
    }
    _adDataIndices.sort();
    debugPrint(
      "[${widget.category}] Added More Ad Data indices (range $startIndex-$endIndex): $newlyAddedDataIndices",
    );
    return newlyAddedDataIndices;
  }

  void _requestAdsForCurrentIndices({
    bool onlyNew = false,
    int newDataStartIndex = 0,
  }) {
    // ... (광고 로드 요청 로직 - 변경 없음) ...
    int currentAdOffset = 0;
    for (int i = 0; i < _adDataIndices.length; i++) {
      int adDataIndex = _adDataIndices[i];
      if (onlyNew && adDataIndex < newDataStartIndex) {
        currentAdOffset++;
        continue;
      }
      int adBuilderIndex = adDataIndex + i;
      _requestAdLoad(adBuilderIndex);
    }
  }

  Future<void> _requestAdLoad(int builderIndex) async {
    // ... (개별 광고 로드 로직 - 변경 없음) ...
    if (_loadedAds.containsKey(builderIndex)) return;
    setState(() {
      _loadedAds[builderIndex] = null;
    });

    try {
      final NativeAd? loadedAd = await _adManager.loadNewNativeAd();
      if (!mounted) {
        loadedAd?.dispose();
        return;
      }
      if (loadedAd != null) {
        _adsToDispose.add(loadedAd);
        if (mounted) {
          setState(() {
            _loadedAds[builderIndex] = loadedAd;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loadedAds[builderIndex] = null;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading ad for builderIndex $builderIndex: $e");
      if (mounted) {
        setState(() {
          _loadedAds[builderIndex] = null;
        });
      }
    }
  }

  // --- 스크롤 네비게이터 관련 ---
  void _updateScrollState(ScrollController controller, bool isScrolling) {
    // ... (스크롤 상태 업데이트 로직 - 변경 없음) ...
    _scrollDisplayTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isScrolling = isScrolling;
      if (isScrolling && controller.hasClients) {
        _scrollPosition = controller.position.pixels;
        _maxScrollExtent =
            controller.position.maxScrollExtent > 0
                ? controller.position.maxScrollExtent
                : 1.0;
        _scrollDisplayTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _isScrolling = false);
          }
        });
      }
    });
  }

  Widget _buildScrollIndicator() {
    final theme = Theme.of(context);

    // [✅ 수정] % 대신 아이템 개수로 표시
    // 현재 보고 있는 아이템 인덱스 추정 (0부터 시작)
    final currentItemIndex = (_scrollPosition / _estimatedItemHeight).floor();
    // 표시할 인덱스 (1부터 시작, 전체 뉴스 개수 초과 방지)
    final displayIndex = min(currentItemIndex + 1, _newsItems.length);
    final totalNewsCount = _newsItems.length; // 전체 뉴스 아이템 개수

    // 스크롤 범위가 0이거나 아이템이 없으면 표시 안 함
    if (_maxScrollExtent <= 0 || totalNewsCount == 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 16,
      bottom: 80,
      child: AnimatedOpacity(
        opacity: _isScrolling ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.9), // 배경 약간 더 불투명하게
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6),
            ], // 그림자 약간 조정
          ),
          child: Text(
            // [✅ 수정] 표시 텍스트 변경
            '$displayIndex / $totalNewsCount',
            style: TextStyle(
              fontSize: 11, // 글자 크기 약간 키움
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyMedium?.color, // 테마 색상 사용
              letterSpacing: 0.5, // 자간 약간 추가
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollToTopButton() {
    // ... (맨 위로 버튼 - 변경 없음) ...
    final theme = Theme.of(context);
    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton.small(
        onPressed: () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        },
        backgroundColor: theme.primaryColor.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: '맨 위로',
        child: const Icon(Icons.keyboard_arrow_up, size: 20),
      ),
    );
  }
  // --- 스크롤 네비게이터 끝 ---

  @override
  Widget build(BuildContext context) {
    // ... (테마, 설정 가져오기 - 변경 없음) ...
    final theme = Theme.of(context);
    final cardStyle = AppTheme.newsCardStyleOf(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);
    final settings = Provider.of<SettingsProvider>(context).settings;
    // _adManager는 initState에서 가져옴

    return RefreshIndicator(
      onRefresh: _fetchInitialNews,
      color: theme.primaryColor,
      child: Stack(
        children: [
          _buildNewsContentList(
            theme,
            cardStyle,
            subscribeStyle,
            settings,
            _adManager,
          ),
          if (!_isLoading) _buildScrollIndicator(), // 로딩 중 아닐 때만 표시
          if (!_isLoading && _scrollPosition > 300)
            _buildScrollToTopButton(), // 로딩 중 아닐 때만 표시
        ],
      ),
    );
  }

  Widget _buildNewsContentList(
    /* ... 인자 ... */
    ThemeData theme,
    NewsCardStyleExtension cardStyle,
    SubscribeViewStyleExtension subscribeStyle,
    AppSettings settings,
    AdManager adManager,
  ) {
    // ... (초기 로딩, 뉴스 없음 UI - 변경 없음) ...
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
      );
    }
    if (_newsItems.isEmpty) {
      return LayoutBuilder(
        builder:
            (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.newspaper,
                        size: 48,
                        color: subscribeStyle.emptyIconColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.category} 뉴스가 없습니다',
                        style: TextStyle(
                          color: subscribeStyle.emptyTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      );
    }

    final bool shouldShowAds = adManager.showAds && _adDataIndices.isNotEmpty;
    // [✅ 수정] 표시될 광고 개수 계산 방식 변경 없음 (_adDataIndices 기준)
    final int numberOfAdsToShow = shouldShowAds ? _adDataIndices.length : 0;

    final int totalItemCount =
        _newsItems.length + numberOfAdsToShow + (_isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: totalItemCount,
      itemBuilder: (context, index) {
        if (_isLoadingMore && index == totalItemCount - 1) {
          // ... 로딩 인디케이터 ...
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: CircularProgressIndicator(
                color: theme.primaryColor,
                strokeWidth: 3,
              ),
            ),
          );
        }

        int adOffset = 0;
        // [✅ 수정] numberOfAdsToShow 기준으로 반복 (변경 없음)
        for (int i = 0; i < numberOfAdsToShow; i++) {
          // 로드해야 할 광고 인덱스가 범위를 벗어나면 중단 (AdManager가 충분히 로드 못했을 경우 대비)
          if (i >= adManager.nativeAds.length &&
              !_loadedAds.containsKey(_adDataIndices[i] + i)) {
            // 이 로직은 동적 로딩에서는 불필요할 수 있음. _loadedAds 기준으로 판단.
          }

          int adDataIndex = _adDataIndices[i];
          int adBuilderIndex = adDataIndex + i;

          if (index == adBuilderIndex) {
            // --- 광고 ---
            final adState = _loadedAds[adBuilderIndex];
            if (adState is NativeAd) {
              return Container(
                /* ... 광고 위젯 ... */
                height: 320,
                margin: cardStyle.cardPadding.copyWith(top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(
                    cardStyle.thumbnailBorderRadius,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: AdWidget(ad: adState),
              );
            } else {
              // 로딩 중 또는 실패 시 Placeholder
              return SizedBox(
                height: 320,
                child: Container(
                  margin: cardStyle.cardPadding.copyWith(top: 8, bottom: 8),
                  alignment: Alignment.center,
                  color: theme.disabledColor.withOpacity(0.1),
                ),
              );
            }
          }
          if (index > adBuilderIndex) {
            adOffset++;
          }
        }

        // --- 뉴스 ---
        final newsIndex = index - adOffset;
        if (newsIndex >= _newsItems.length || newsIndex < 0) {
          debugPrint(
            "Index out of bounds: index=$index, adOffset=$adOffset, newsIndex=$newsIndex, newsItems.length=${_newsItems.length}",
          );
          return const SizedBox.shrink();
        }

        final news = _newsItems[newsIndex];
        final hasImage = news.newsImageLink.isNotEmpty;
        final showImage =
            hasImage && settings.viewMode == ViewMode.textAndImage;

        if (!_bookmarkStatus.containsKey(news.newsLink)) {
          _checkBookmarkStatus(news.newsLink);
        }

        return InkWell(
          /* ... 뉴스 아이템 UI ... */
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewsDetailScreen(news: news),
              ),
            );
          },
          child: Padding(
            padding: cardStyle.cardPadding,
            child:
                settings.viewMode == ViewMode.textOnly
                    ? _buildTextOnlyLayout(news, cardStyle, theme)
                    : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildNewsContentCard(news, cardStyle, theme),
                        ),
                        if (showImage) ...[
                          const SizedBox(width: 12),
                          _buildThumbnail(news.newsImageLink, news.newsLink),
                        ],
                      ],
                    ),
          ),
        );
      },
    );
  }

  // (이하 메서드들은 변경 없음)
  Widget _buildTextOnlyLayout(
    News news,
    NewsCardStyleExtension cardStyle,
    ThemeData theme,
  ) {
    return _buildNewsContentCard(news, cardStyle, theme);
  }

  Widget _buildNewsContentCard(
    News news,
    NewsCardStyleExtension cardStyle,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                news.newsTitle,
                style: cardStyle.titleStyle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon:
                  _loadingStatus[news.newsLink] == true
                      ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.primaryColor,
                        ),
                      )
                      : Icon(
                        _bookmarkStatus[news.newsLink] == true
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color:
                            _bookmarkStatus[news.newsLink] == true
                                ? cardStyle.bookmarkActiveColor
                                : cardStyle.bookmarkInactiveColor,
                        size: 20,
                      ),
              onPressed: () => _toggleBookmark(news),
              tooltip:
                  _bookmarkStatus[news.newsLink] == true ? '북마크 해제' : '북마크',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _truncateDescription(news.newsDescription),
          style: cardStyle.descriptionStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              child: Text(
                news.newsSource,
                style: cardStyle.sourceStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(_formatDate(news.newsPubDate), style: cardStyle.dateStyle),
          ],
        ),
      ],
    );
  }

  Future<void> _checkBookmarkStatus(String newsLink) async {
    if (!mounted) return;
    try {
      final isBookmarked = await NewsBookmarkService.isNewsBookmarked(newsLink);
      if (!mounted) return;
      setState(() {
        _bookmarkStatus[newsLink] = isBookmarked;
      });
    } catch (_) {}
  }

  Future<void> _toggleBookmark(News news) async {
    if (_loadingStatus[news.newsLink] == true) return;
    if (!mounted) return;
    setState(() => _loadingStatus[news.newsLink] = true);
    try {
      bool success;
      if (_bookmarkStatus[news.newsLink] == true) {
        success = await NewsBookmarkService.removeNewsBookmark(news.newsLink);
      } else {
        success = await NewsBookmarkService.addNewsBookmark(news);
      }
      if (!mounted) return;
      if (success) {
        setState(() {
          _bookmarkStatus[news.newsLink] =
              !(_bookmarkStatus[news.newsLink] ?? false);
        });
        widget.onBookmarkChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _bookmarkStatus[news.newsLink] == true
                  ? '북마크에 추가되었습니다'
                  : '북마크에서 제거되었습니다',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('북마크 변경 중 오류 발생'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingStatus[news.newsLink] = false);
      }
    }
  }

  Widget _buildThumbnail(String imageUrl, String newsLink) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 100,
      height: 75,
      child:
          imageUrl.isNotEmpty
              ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color:
                          theme.brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primaryColor,
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color:
                            theme.brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color:
                            theme.brightness == Brightness.dark
                                ? Colors.grey[600]
                                : Colors.grey[400],
                        size: 24,
                      ),
                    );
                  },
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  color:
                      theme.brightness == Brightness.dark
                          ? theme.cardColor.withOpacity(0.35)
                          : theme.cardColor.withOpacity(0.9),
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 20,
                  color: theme.iconTheme.color?.withOpacity(0.5),
                ),
              ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}분 전';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}시간 전';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}일 전';
      } else {
        return DateFormat('MM/dd').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  String _truncateDescription(String description) {
    if (description.length > 100) {
      return '${description.substring(0, 100)}...';
    }
    return description;
  }
} // End of _NewsListViewState

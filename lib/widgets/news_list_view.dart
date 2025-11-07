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
import 'package:omninews_flutter/services/recently_read_service.dart'; // [✅ 추가]
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:omninews_flutter/utils/ad_manager.dart';
import 'package:omninews_flutter/utils/url_launcher_helper.dart'; // [✅ 추가]
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

class _NewsListViewState extends State<NewsListView>
    with AutomaticKeepAliveClientMixin {
  // --- 상태 변수 ---
  final Map<String, bool> _bookmarkStatus = {};
  final Map<String, bool> _loadingStatus = {};
  final List<News> _newsItems = [];
  int _currentPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final Random _random = Random();

  // --- 광고 관련 상태 ---
  final List<int> _adDataIndices = [];
  static const int _initialAdCount = 1;
  static const int _adsToAddPerPage = 1;
  static const int _adMinIndex = 3;
  final Map<int, NativeAd?> _loadedAds = {};
  final List<NativeAd> _adsToDispose = [];

  // --- 스크롤 네비게이터 상태 ---
  final ValueNotifier<bool> _showScrollIndicatorNotifier = ValueNotifier<bool>(
    false,
  );
  Timer? _scrollIndicatorTimer;

  late AdManager _adManager;
  static const double _estimatedItemHeight = 120.0;

  @override
  bool get wantKeepAlive => true;

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
    _scrollIndicatorTimer?.cancel();
    _showScrollIndicatorNotifier.dispose();
    // 광고 해제
    for (var ad in _adsToDispose) {
      ad.dispose();
    }
    _adsToDispose.clear();
    _loadedAds.values.where((ad) => ad != null).forEach((ad) => ad!.dispose());
    _loadedAds.clear();
    super.dispose();
  }

  Future<void> _fetchInitialNews() async {
    if (!_isLoading) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _newsItems.clear();
          _currentPage = 1;
          _hasMore = true;
          _adDataIndices.clear();
          _loadedAds.clear();
          for (var ad in _adsToDispose) {
            ad.dispose();
          }
          _adsToDispose.clear();
          _showScrollIndicatorNotifier.value = false;
        });
      } else {
        _isLoading = true;
      }
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }

    try {
      final fetchedNews = await NewsService.fetchNewsPaginated(
        widget.category,
        1,
      );
      if (!mounted) return;
      final newItems = List<News>.from(fetchedNews);
      final newPage = 1;
      final newHasMore = fetchedNews.length >= 20;
      final newAdIndices = <int>[];
      if (newItems.isNotEmpty) {
        _generateAdIndices(newItems.length, _initialAdCount, newAdIndices);
      }

      setState(() {
        _newsItems.clear();
        _newsItems.addAll(newItems);
        _currentPage = newPage;
        _hasMore = newHasMore;
        _adDataIndices.clear();
        _adDataIndices.addAll(newAdIndices);
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _requestAdsForCurrentIndices();
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('[${widget.category}] Error fetching initial news: $e');
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
    if (_scrollController.hasClients) {
      if (!_showScrollIndicatorNotifier.value) {
        _showScrollIndicatorNotifier.value = true;
      }
      _scrollIndicatorTimer?.cancel();
      _scrollIndicatorTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _showScrollIndicatorNotifier.value = false;
        }
      });
    }

    if (!_isLoadingMore &&
        _hasMore &&
        _scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
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
      final newlyAddedDataIndices = <int>[];
      _newsItems.addAll(fetchedNews);
      _currentPage = nextPage;
      _hasMore = fetchedNews.length >= 20;
      if (fetchedNews.isNotEmpty) {
        newlyAddedDataIndices.addAll(
          _generateMoreAdIndices(startIndex, fetchedNews.length),
        );
      }
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
      if (newlyAddedDataIndices.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _requestAdsForNewIndices(newlyAddedDataIndices);
        });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('[${widget.category}] Error loading more news: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // 광고 인덱스 생성 (초기)
  void _generateAdIndices(int listLength, int count, List<int> targetList) {
    if (listLength <= _adMinIndex) return;
    final availableIndices =
        List.generate(
          max(0, listLength - _adMinIndex),
          (i) => i + _adMinIndex,
        ).where((idx) => idx < listLength).toList();
    availableIndices.shuffle(_random);
    int numToAdd = min(count, availableIndices.length);
    for (int i = 0; i < numToAdd; i++) {
      targetList.add(availableIndices[i]);
    }
    targetList.sort();
    debugPrint(
      "[${widget.category}] Initial Ad Data indices generated: $targetList",
    );
  }

  // 추가 광고 인덱스 생성
  List<int> _generateMoreAdIndices(int startIndex, int newItemsCount) {
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
      if (!_adDataIndices.contains(newIndex)) {
        _adDataIndices.add(newIndex);
        newlyAddedDataIndices.add(newIndex);
      }
    }
    _adDataIndices.sort();
    debugPrint(
      "[${widget.category}] Added More Ad Data indices (range $startIndex-$endIndex): $newlyAddedDataIndices",
    );
    return newlyAddedDataIndices;
  }

  // 전체 광고 로드 요청
  void _requestAdsForCurrentIndices() {
    for (int i = 0; i < _adDataIndices.length; i++) {
      int adDataIndex = _adDataIndices[i];
      int adBuilderIndex = adDataIndex + i;
      _requestAdLoad(adBuilderIndex);
    }
  }

  // 새로 추가된 광고 로드 요청
  void _requestAdsForNewIndices(List<int> newDataIndices) {
    if (newDataIndices.isEmpty) return;
    for (int newDataIndex in newDataIndices) {
      int adOrderIndex = _adDataIndices.indexOf(newDataIndex);
      if (adOrderIndex != -1) {
        int adBuilderIndex = newDataIndex + adOrderIndex;
        _requestAdLoad(adBuilderIndex);
      }
    }
  }

  // 개별 광고 로드 요청
  Future<void> _requestAdLoad(int builderIndex) async {
    if (_loadedAds.containsKey(builderIndex)) return;
    if (!mounted) return;
    if (mounted)
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
      debugPrint(
        "[${widget.category}] Error loading ad for builderIndex $builderIndex: $e",
      );
      if (mounted) {
        setState(() {
          _loadedAds[builderIndex] = null;
        });
      }
    }
  }

  // [✅ 수정] 뉴스 클릭 핸들러 - 주요 카테고리는 설정값에 맞춰 URL 열기
  void _handleNewsItemTap(News news) {
    if (widget.category == "주요") {
      // 주요 카테고리는 최근 읽은 뉴스에 추가하고 설정값에 맞춰 링크 열기
      RecentlyReadService.addNews(news);
      final settings =
          Provider.of<SettingsProvider>(context, listen: false).settings;
      UrlLauncherHelper.openUrl(context, news.newsLink, settings.webOpenMode);
    } else {
      // 다른 카테고리는 상세 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
      );
    }
  }

  // --- 스크롤 네비게이터 관련 ---

  Widget _buildScrollIndicator() {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        if (!_scrollController.hasClients ||
            !_scrollController.position.hasContentDimensions) {
          return const SizedBox.shrink();
        }

        final currentPosition = _scrollController.position.pixels;
        final maxExtent = _scrollController.position.maxScrollExtent;

        if (maxExtent <= 0) return const SizedBox.shrink();

        final currentItemIndex =
            (currentPosition / _estimatedItemHeight).floor();
        final displayIndex = min(currentItemIndex + 1, _newsItems.length);
        final totalNewsCount = _newsItems.length;

        if (totalNewsCount == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6),
            ],
          ),
          child: Text(
            '$displayIndex / $totalNewsCount',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyMedium?.color,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollToTopButton() {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        final showButton =
            _scrollController.hasClients && _scrollController.offset > 300;
        return AnimatedOpacity(
          opacity: showButton ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: !showButton,
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final cardStyle = AppTheme.newsCardStyleOf(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

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

          Positioned(
            right: 16,
            bottom: 80,
            child: ValueListenableBuilder<bool>(
              valueListenable: _showScrollIndicatorNotifier,
              builder: (context, showIndicator, _) {
                return AnimatedOpacity(
                  opacity: showIndicator ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !showIndicator,
                    child: _buildScrollIndicator(),
                  ),
                );
              },
            ),
          ),

          Positioned(right: 16, bottom: 16, child: _buildScrollToTopButton()),
        ],
      ),
    );
  }

  Widget _buildNewsContentList(
    ThemeData theme,
    NewsCardStyleExtension cardStyle,
    SubscribeViewStyleExtension subscribeStyle,
    AppSettings settings,
    AdManager adManager,
  ) {
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
    final int numberOfAdsToShow = shouldShowAds ? _adDataIndices.length : 0;
    final int totalItemCount =
        _newsItems.length + numberOfAdsToShow + (_isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: totalItemCount,
      itemBuilder: (context, index) {
        Widget? itemWidget;
        int adOffset = 0;
        int? adDataIndexIfAd;

        if (shouldShowAds) {
          for (int i = 0; i < numberOfAdsToShow; i++) {
            if (i >= _adDataIndices.length) break;
            int adDataIndex = _adDataIndices[i];
            int adBuilderIndex = adDataIndex + i;
            if (index == adBuilderIndex) {
              adDataIndexIfAd = adDataIndex;
              break;
            }
            if (index > adBuilderIndex) {
              adOffset++;
            }
          }
        }

        // 1. 더보기 로딩
        if (_isLoadingMore && index == totalItemCount - 1) {
          itemWidget = Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: CircularProgressIndicator(
                color: theme.primaryColor,
                strokeWidth: 3,
              ),
            ),
          );
        }
        // 2. 광고
        else if (adDataIndexIfAd != null) {
          int adBuilderIndex = index;
          final adState = _loadedAds[adBuilderIndex];

          if (adState is NativeAd) {
            itemWidget = Container(
              key: ValueKey('ad_${widget.category}_$adBuilderIndex'),
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
            if (!_loadedAds.containsKey(adBuilderIndex)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_loadedAds.containsKey(adBuilderIndex)) {
                  _requestAdLoad(adBuilderIndex);
                }
              });
            }
            itemWidget = SizedBox(
              key: ValueKey(
                'ad_placeholder_${widget.category}_$adBuilderIndex',
              ),
              height: 320,
              child: Container(
                margin: cardStyle.cardPadding.copyWith(top: 8, bottom: 8),
                alignment: Alignment.center,
                color: theme.disabledColor.withOpacity(0.1),
                child:
                    _loadedAds.containsKey(adBuilderIndex)
                        ? CircularProgressIndicator(
                          color: theme.primaryColor,
                          strokeWidth: 2,
                        )
                        : null,
              ),
            );
          }
        }
        // 3. 뉴스
        else {
          final newsIndex = index - adOffset;
          if (newsIndex >= _newsItems.length || newsIndex < 0) {
            itemWidget = const SizedBox.shrink();
          } else {
            final news = _newsItems[newsIndex];
            final hasImage = news.newsImageLink.isNotEmpty;
            final showImage =
                hasImage && settings.viewMode == ViewMode.textAndImage;
            if (!_bookmarkStatus.containsKey(news.newsLink)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _checkBookmarkStatus(news.newsLink);
              });
            }
            // [✅ 수정] onTap 핸들러 변경
            itemWidget = InkWell(
              key: ValueKey('news_${widget.category}_${news.newsLink}'),
              onTap: () => _handleNewsItemTap(news),
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
                              child: _buildNewsContentCard(
                                news,
                                cardStyle,
                                theme,
                              ),
                            ),
                            if (showImage) ...[
                              const SizedBox(width: 12),
                              _buildThumbnail(
                                news.newsImageLink,
                                news.newsLink,
                              ),
                            ],
                          ],
                        ),
              ),
            );
          }
        }
        return KeepAliveWrapper(child: itemWidget);
      },
    );
  }

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
      if (mounted)
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
        if (mounted)
          setState(() {
            _bookmarkStatus[news.newsLink] =
                !(_bookmarkStatus[news.newsLink] ?? false);
          });
        widget.onBookmarkChanged?.call();
        if (mounted)
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
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({Key? key, required this.child}) : super(key: key);
  @override
  KeepAliveWrapperState createState() => KeepAliveWrapperState();
}

class KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
